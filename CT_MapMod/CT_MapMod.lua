------------------------------------------------
--                 CT_MapMod                  --
--                                            --
-- Simple addon that allows the user to add   --
-- notes and gathered nodes to the world map. --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
--					      --
-- Original credits to Cide and TS (Vanilla)  --
-- Maintained by Resike from 2014 to 2017     --
-- Rebuilt by Dahk Celes (DDCorkum) in 2018   --
------------------------------------------------

--------------------------------------------
-- Initialization

local module = select(2, ...);
local _G = getfenv(0);

local MODULE_NAME = "CT_MapMod";
local MODULE_VERSION = strmatch(GetAddOnMetadata(MODULE_NAME, "version"), "^([%d.]+)");

module.name = MODULE_NAME;
module.version = MODULE_VERSION;

CT_Library:registerModule(module);
_G[MODULE_NAME] = module.publicInterface;
local public = module.publicInterface; -- shorthand


function module:Initialize()				-- called via module.update("init") from CT_Library

	-- Convert notes from older versions of the addon to the most recent (using function defined near bottom)
	module:ConvertOldNotes();

	-- load the DataProvider which has most of the horsepower
	WorldMapFrame:AddDataProvider(CreateFromMixins(CT_MapMod_DataProviderMixin));
	
	-- load an additional DataProvider to the FlightMapFrame in retail, so pins can appear on the continent flight map
	if (module:getGameVersion() == CT_GAME_VERSION_RETAIL) then
		if (not FlightMapFrame) then FlightMap_LoadUI(); end
		FlightMapFrame:AddDataProvider(CreateFromMixins(CT_MapMod_DataProviderMixin));
	end
	
	-- add UI elements to the WorldMapFrame
	module:AddUIElements();
end

--------------------------------------------
-- Saved Variable: CT_MapMod_Notes
-- Persistant storage of the actual pins, and a collection of public and private methods to manipulate the data

CT_MapMod_Notes = {}; 		-- Account-wide saved variable containing all of the information about pins

-- Inserts a new pin on a map; however, if an identical pin exists then it will simple refresh the existing one to prevent duplicates
function module:InsertPin(mapid, x, y, name, set, subset, descript)
	CT_MapMod_Notes[mapid] = CT_MapMod_Notes[mapid] or {}
	for i, note in ipairs(CT_MapMod_Notes[mapid]) do
		if (note.x == x and note.y == y and note.name == name and note.set == set and note.subset == subset and note.descript == descript) then
			note.datemodified = date("%Y%m%d");
			note.version = MODULE_VERSION;
			return;
		end
	end
	tinsert(CT_MapMod_Notes[mapid], {
		["x"] = x,
		["y"] = y,
		["name"] = name,
		["set"] = set,
		["subset"] = subset,
		["descript"] = descript,
		["datemodified"] = date("%Y%m%d"),
		["version"] = MODULE_VERSION
	});
end

-- Deletes a pin from the i'th position on mapid, taking the very last remaining one and inserting it into the current position rather than shifting all the other notes down by one
-- (This is an alternative to using tremove in the middle of a big table, for performance reasons only)
function module:DeletePin(mapid, i)
	if (CT_MapMod_Notes[mapid] and CT_MapMod_Notes[mapid][i]) then
		if (i == #CT_MapMod_Notes[mapid]) then
			tremove(CT_MapMod_Notes[mapid], i);
		else
			local lastNoteInStack = tremove(CT_MapMod_Notes[mapid], #CT_MapMod_Notes[mapid]);
			CT_MapMod_Notes[mapid] = lastNoteInStack;
		end
	end
end

-- Inserts a new herb node on the map, but subject to rules imposed by CT_MapMod to prevent duplication
-- Parameters:
--	mapid		Number, Required	Corresponding to a uiMapID upon which the pin should appear
--	x, y		Numbers, Required	Absolute coordinates on the map between 0 and 1
--	herb		String, Required	Localized or non-localized name of the herbalism node or kind of herb (silently fails if it is a string that simply isn't recognized)
--	descript	String			Optional text to include (defaults to nil)
--	name		String			Optional name for the pin (defaults to a localized version of the herb)
function public:InsertHerb(mapid, x, y, herb, descript, name)
	assert(type(mapid) == "number", "An AddOn is creating a CT_MapMod pin without identifying a valid map")
	assert(type(x) == "number" and type(y) == "number" and x >= 0 and y >= 0 and x <= 1 and y <= 1, "An AddOn is creating a CT_MapMod pin without specifying valid cordinates");
	assert(type(herb) == "string", "An AddOn is creating a CT_MapMod herbalism pin without identifying a kind of herbalism node")
	if (type(descript) ~= "string") then
		descript = nil
	end
	if (type(name) ~= "string") then
		name = nil;
	end
	for __, expansion in pairs(module.pinTypes["Herb"]) do
		for __, kind in ipairs(expansion) do
			if (module.text["CT_MapMod/Herb/" .. kind.name] == herb) then
				herb = kind.name
			end
			if (kind.name == herb) then
				if (kind.spawnsRandomly and not module:getOption("CT_MapMod_IncludeRandomSpawns")) then
					-- this is an herb that appears randomly throughout the zone in place of others, such as Anchor's Weed
					return;
				end
				CT_MapMod_Notes[mapid] = CT_MapMod_Notes[mapid] or { };
				for __, note in ipairs(CT_MapMod_Notes[mapid]) do
					if ((note["name"] == herb) and (math.sqrt((note["x"]-x)^2+(note["y"]-y)^2)<.02)) then
						--two herbs of the same kind not far apart
						return;
					elseif ((note["set"] == "Herb") and (math.sqrt((note["x"]-x)^2+(note["y"]-y)^2)<.01)) then
						--two herbs of different kinds very close together
						if (module:getOption("CT_MapMod_OverwriteGathering")) then
							note["x"] = x;
							note["y"] = y;
							if (note["descript"] == "") then
								note["descript"] = "Nearby: " .. module.text["CT_MapMod/Herb/" .. note["subset"]];
							elseif (note["descript"]:sub(1,8) == "Nearby: " and not note["descript"]:find(module.text["CT_MapMod/Herb/" .. note["subset"]],9)) then
								note["descript"] = note["descript"] .. ", " .. module.text["CT_MapMod/Herb/" .. note["subset"]];
							end
							note["name"] = module.text["CT_MapMod/Herb/" .. herb];
							note["subset"] = herb;
							note["datemodified"] = date("%Y%m%d");
							note["version"] = MODULE_VERSION
						else
							-- leave the existing note, but add details in the description
							if (note["descript"] == "") then
								note["descript"] = "Nearby: " .. module.text["CT_MapMod/Herb/" .. herb];
							elseif (note["descript"]:sub(1,8) == "Nearby: " and not note["descript"]:find(module.text["CT_MapMod/Herb/" .. herb],9)) then
								note["descript"] = note["descript"] .. ", " .. module.text["CT_MapMod/Herb/" .. herb];
							end											
						end
						return;
					elseif (math.sqrt((note["x"]-x)^2+(note["y"]-y)^2)<.005) then 		--two notes of completely different kinds EXTREMELY close together
						return;
					end
				end
				if (not name) then
					name = module.text["CT_MapMod/Herb/" .. herb];
				end
				-- this point will not have been reached if the earlier rules were triggered, causing the function to return early
				module:InsertPin(mapid, x, y, name, "Herb", herb, descript);
				return; -- breaks the for loops
			end
		end
	end
end

-- Inserts a new ore node on the map, but subject to rules imposed by CT_MapMod to prevent duplication
-- Parameters:
--	mapid		Number, Required	Corresponding to a uiMapID upon which the pin should appear
--	x, y		Numbers, Required	Absolute coordinates on the map between 0 and 1
--	ore		String			Localized or non-localized name of the mining node or kind of ore (silently fails if it is a string that simply isn't recognized)
--	descript	String			Optional text to include (defaults to nil)
--	name		String			Optional name for the pin (defaults to a localized version of the ore)
function public:InsertOre(mapid, x, y, ore, descript, name)
	assert(type(mapid) == "number", "An AddOn is creating a CT_MapMod pin without identifying a valid map")
	assert(type(x) == "number" and type(y) == "number" and x >= 0 and y >= 0 and x <= 1 and y <= 1, "An AddOn is creating a CT_MapMod pin without specifying valid cordinates");
	assert(type(herb) == "string", "An AddOn is creating a CT_MapMod mining pin without identifying a kind of mining node")
	if (type(descript) ~= "string") then
		descript = nil
	end
	if (type(name) ~= "string") then
		name = nil;
	end
	-- Convert from the name of a node to a type of ore (using rules for each localization)
	if (GetLocale() == "enUS" or GetLocale() == "enGB") then
		if (ore:sub(1,5) == "Rich " and ore:len() > 5) then ore = ore:sub(6); end -- changes "Rich Thorium Vein" to "Thorium Vein"
		if (ore:sub(1,5) == "Small " and ore:len() > 6) then ore = ore:sub(7); end -- changes "Small Thorium Vein" to "Thorium Vein"
		if (ore:sub(-5) == " Vein" and ore:len() > 5) then ore = ore:sub(1,-6); end -- changes "Copper Vein" to "Copper"
		if (ore:sub(-8) == " Deposit" and ore:len() > 8) then ore = ore:sub(1,-9); end -- changes "Iron Deposit" to "Iron"
		if (ore:sub(-5) == " Seam" and ore:len() > 5) then ore = ore:sub(1,-6); end -- changes "Monelite Seam" to "Monelite"
	elseif (GetLocale() == "frFR") then
		if (ore:sub(1,6) == "Riche " and ore:len() > 7) then ore = ore:sub(7,7):upper() .. ore:sub(8); end -- changes "Riche filon de thorium" to "Filon de Thorium"
		if (ore:sub(1,6) == "Petit " and ore:len() > 7) then ore = ore:sub(7,7):upper() .. ore:sub(8); end -- changes "Petit filon de thorium" to "Filon de Thorium"
		if (ore:sub(1,9) == "Filon de " and ore:len() > 10) then ore = ore:sub(10,10):upper() .. ore:sub(11); end -- changes "Filon de cuivre" to "Cuivre"
		if (ore:sub(1,12) == "Gisement de " and ore:len() > 13) then ore = ore:sub(13,13):upper() .. ore:sub(14); end -- changes "Gisement de fer" to "Fer"
		if (ore:sub(1,9) == "Veine de " and ore:len() > 10) then ore = ore:sub(10,10):upper() .. ore:sub(11); end -- changes "Veine de gangreschiste" to "Gangreschiste"
	elseif (GetLocale() == "deDE") then
		if (ore:sub(1,9) == "Reiches " and ore:len() > 9) then ore = ore:sub(10); end  -- changes "Reiches Thoriumvorkommen" to "Thoriumvorkommen"
		if (ore:sub(1,9) == "Kleines " and ore:len() > 9) then ore = ore:sub(10); end  -- changes "Kleines Thoriumvorkommen" to "Thoriumvorkommen"
		if (ore:sub(-9) == "vorkommen" and ore:len() > 9) then ore = ore:sub(1, -10); end -- changes "Kupfervorkommen" to "Kupfer"
		if (ore:sub(-4) == "flöz" and ore:len() > 9) then ore = ore:sub(1, -5); end -- changes "Monelitflöz" to Monelit"
	elseif (GetLocale() == "esES" or GetLocale() == "esMX") then
		if (ore:sub(-9) == " enriquecido" and ore:len() > 12) then ore = ore:sub(1, -13); end -- changes "Filón de torio enriquecido" to "Filón de torio"
		if (ore:sub(1,9) == "Filón de " and ore:len() > 10) then ore = ore:sub(10,10):upper() .. ore:sub(11); end -- changes "Filón de cobre" to "Cobre"
		if (ore:sub(1,17) == "Filón pequeño de " and ore:len() > 17) then ore = ore:sub(17,17):upper() .. ore:sub(18); end -- changes "Filón pequeño de torio" to "Torio"
		if (ore:sub(1,9) == "Depósito de " and ore:len() > 13) then ore = ore:sub(13,13):upper() .. ore:sub(14); end -- changes "Depósito de hierro" to "Hierro"
		if (ore:sub(1,9) == "Depósito rico en" and ore:len() > 17) then ore = ore:sub(17,17):upper() .. ore:sub(18); end -- changes "Depósito rico en verahierro" to "Verahierro"
		if (ore:sub(1,9) == "Veta de " and ore:len() > 9) then ore = ore:sub(9,9):upper() .. ore:sub(10); end -- changes "Veta de monalita" to "Monalita"
	elseif (GetLocale() == "ptBR") then
		if (ore:sub(-10) == " Abundante" and ore:len() > 10) then ore = ore:sub(1,-11); end -- changes "Veio de Tório Abundante" to "Veio de Tório"
		if (ore:sub(-8) == " Escasso" and ore:len() > 8) then ore = ore:sub(1,-9); end -- changes "Veio de Tório Escasso" to "Veio de Tório"
		if (ore:sub(1,5) == "Veio de " and ore:len() > 8) then ore = ore:sub(9); end -- changes "Veio de Cobre" to "Cobre"
		if (ore:sub(1,5) == "Depósito de " and ore:len() > 12) then ore = ore:sub(13); end -- changes "Depósito de Ferro" to "Ferro"
		if (ore:sub(1,5) == "Jazida de " and ore:len() > 10) then ore = ore:sub(11); end -- changes "Jazida de Monelita" to "Monelita"
	elseif (GetLocale() == "ruRU") then
		if (ore:sub(1,8) == "Богатая " and ore:len() > 9) then ore = ore:sub(9,9):upper() .. ore:sub(10); end -- changes "Богатая ториевая жила" to "Ториевая жила"
		if (ore:sub(1,8) == "Малая " and ore:len() > 7) then ore = ore:sub(7,7):upper() .. ore:sub(7); end -- changes "Малая ториевая жила" to "Ториевая жила"
		if (ore:sub(-5) == " жила" and ore:len() > 5) then ore = ore:sub(1,-6); end	--changes "Медная жила" to "Медная"
		if (ore:sub(1,7) == "Залежи " and ore:len() > 8) then ore = ore:sub(8,8):upper() .. ore:sub(9); end -- changes "Залежи истинного серебра" to "Истинного серебра"
	end

	-- Now process the mining node
	for __, expansion in pairs(module.pinTypes["Ore"]) do
		for __, kind in ipairs(expansion) do
			if (module.text["CT_MapMod/Ore/" .. kind.name] == ore) then
				ore = kind.name
			end
			if (kind.name == ore) then
				if (kind.spawnsRandomly and not module:getOption("CT_MapMod_IncludeRandomSpawns")) then
					-- this is an herb that appears randomly throughout the zone in place of others, such as Anchor's Weed
					return;
				end
				CT_MapMod_Notes[mapid] = CT_MapMod_Notes[mapid] or { };
				for __, note in ipairs(CT_MapMod_Notes[mapid]) do
					if ((note["name"] == ore) and (math.sqrt((note["x"]-x)^2+(note["y"]-y)^2)<.02)) then 
						--two veins of the same kind not far apart
						return;
					elseif ((note["set"] == "Ore") and (math.sqrt((note["x"]-x)^2+(note["y"]-y)^2)<.01)) then
						--two veins of different kinds very close together
						if (module:getOption("CT_MapMod_OverwriteGathering")) then
							-- overwrite the existing note
							note["x"] = x;
							note["y"] = y;
							if (note["descript"] == "") then
								note["descript"] = "Nearby: " .. module.text["CT_MapMod/Ore/" .. note["subset"]];
							elseif (note["descript"]:sub(1,8) == "Nearby: " and not note["descript"]:find(module.text["CT_MapMod/Ore/" .. note["subset"]],9)) then
								note["descript"] = note["descript"] .. ", " .. module.text["CT_MapMod/Ore/" .. note["subset"]];
							end
							note["name"] = module.text["CT_MapMod/Ore/" .. ore];
							note["subset"] = ore;
						else
							-- leave the existing note, but add details in the description
							if (note["descript"] == "") then
								note["descript"] = "Nearby: " .. (module.text["CT_MapMod/Ore/" .. ore]);
							elseif (note["descript"]:sub(1,8) == "Also nearby: " and not note["descript"]:find(module.text["CT_MapMod/Ore/" .. ore],9)) then
								note["descript"] = note["descript"] .. ", " .. module.text["CT_MapMod/Ore/" .. ore];
							end
						end
						note["datemodified"] = date("%Y%m%d");
						note["version"] = MODULE_VERSION
						return;
					elseif (math.sqrt((note["x"]-x)^2+(note["y"]-y)^2)<.005) then
						--two notes of completely different kinds EXTREMELY close together
						return;
					end
				end
				if (not name) then
					name = module.text["CT_MapMod/Ore/" .. ore];
				end
				-- this point will not have been reached if the earlier rules were triggered, causing the function to return early
				module:InsertPin(mapid, x, y, name, "Ore", ore, descript);
				return; -- breaks the for loops
			end
		end
	end
end

--------------------------------------------
-- DataProvider
-- Manages the adding, updating, and removing of data like icons, blobs or text to the map canvas

CT_MapMod_DataProviderMixin = CreateFromMixins(MapCanvasDataProviderMixin);
 
function CT_MapMod_DataProviderMixin:RemoveAllData()
	self:GetMap():RemoveAllPinsByTemplate("CT_MapMod_PinTemplate");
end
 
function CT_MapMod_DataProviderMixin:RefreshAllData(fromOnShow)
	-- Clear the map
	self:RemoveAllData();
	module.PinHasFocus = nil;  --rather than calling this for each pin, just call it once when all pins are gone.
	
	-- determine if the player is an herbalist or miner, for automatic showing of those kinds of notes
	if (module:getGameVersion() == CT_GAME_VERSION_RETAIL) then
		local prof1, prof2 = GetProfessions();
		local name, icon, skillLevel, maxSkillLevel, numAbilities, spellOffset, skillLine, skillModifier, specializationIndex, specializationOffset;
		if (prof1) then 
			name, icon, skillLevel, maxSkillLevel, numAbilities, spellOffset, skillLine, skillModifier, specializationIndex, specializationOffset = GetProfessionInfo(prof1)
			if (icon == 136246) then 
				module.isHerbalist = true;
			elseif (icon == 134708) then 
				module.isMiner = true; 
			end
		end
		if (prof2) then 
			name, icon, skillLevel, maxSkillLevel, numAbilities, spellOffset, skillLine, skillModifier, specializationIndex, specializationOffset = GetProfessionInfo(prof2)
			if (icon == 136246) then 
				module.isHerbalist = true;
			elseif (icon == 134708) then 
				module.isMiner = true;
			end
		end
	elseif (module:getGameVersion() == CT_GAME_VERSION_CLASSIC) then		
		local tabName, tabTexture, tabOffset, numEntries = GetSpellTabInfo(1);
		for i=tabOffset + 1, tabOffset + numEntries, 1 do
			local spellName, spellSubName = GetSpellBookItemName(i, BOOKTYPE_SPELL)
		 	if (spellName == module.text["CT_MapMod/Map/ClassicHerbalist"]) then
		 		module.isHerbalist = true;
		 	elseif (spellName == module.text["CT_MapMod/Map/ClassicMiner"]) then
		 		module.isMiner = true;
		 	end
		end
	end

	-- Fetch and push the pins to be used for this map
	local mapid = self:GetMap():GetMapID();
	if ( (mapid) and ((module:getOption("CT_MapMod_ShowOnFlightMaps") or 1) == 1) ) then
		for key, val in pairs(module.flightMaps) do   --continent pins will appear in corresponding flight maps
			if (mapid == key) then
				mapid = val;
			end
		end
	end
	if (mapid and CT_MapMod_Notes[mapid]) then
		for i, info in ipairs(CT_MapMod_Notes[mapid]) do
			if (
				-- if user is set to always (the default)
				( (info["set"] == "User") and ((module:getOption("CT_MapMod_UserNoteDisplay") or 1) == 1) ) or

				-- if herb is set to always, or if herb is set to auto (the default) and the toon is an herbalist
				( (info["set"] == "Herb") and ((module:getOption("CT_MapMod_HerbNoteDisplay") or 1) == 1) and (module.isHerbalist) ) or
				( (info["set"] == "Herb") and ((module:getOption("CT_MapMod_HerbNoteDisplay") or 1) == 2) ) or

				-- if ore is set to always, or if ore is set to auto (the default) and the toon is a miner
				( (info["set"] == "Ore") and ((module:getOption("CT_MapMod_OreNoteDisplay") or 1) == 1) and (module.isMiner) ) or
				( (info["set"] == "Ore") and ((module:getOption("CT_MapMod_OreNoteDisplay") or 1) == 2) )
			) then
				self:GetMap():AcquirePin("CT_MapMod_PinTemplate", mapid, i, info["x"], info["y"], info["name"], info["descript"], info["set"], info["subset"], info["datemodified"], info["version"]);
			end
		end
	end
end
 
--------------------------------------------
-- PinMixin
-- Pins that may be added to the map canvas, like icons, blobs or text

CT_MapMod_PinMixin = CreateFromMixins(MapCanvasPinMixin);

function CT_MapMod_PinMixin:OnLoad()
	-- Override in your mixin, called when this pin is created
	
	-- Create the basic properties of the pin itself
	self:SetWidth(15);
	self:SetHeight(15);
	self.texture = self:CreateTexture(nil,"ARTWORK");
	
	-- Normally the notepanel would be created here, but instead it is deferred until the first onclick event
	-- Otherwise, there could be a performance hit from creating notepanel skeletons that are never actually needed or used
end
 
function CT_MapMod_PinMixin:OnAcquired(...) -- the arguments here are anything that are passed into AcquirePin after the pinTemplate
	-- Override in your mixin, called when this pin is being acquired by a data provider but before its added to the map
	self.mapid, self.i, self.x, self.y, self.name, self.descript, self.set, self.subset, self.datemodified, self.version = ...;
	
	-- Set basic properties for the pin itself
	self:SetPosition(self.x, self.y);
	self.texture:SetTexture("Interface\\RaidFrame\\UI-RaidFrame-Threat"); -- this is a catch-all to ensure every object has an icon, but it should be overridden below
	if (self.set and self.subset) then
		if (self.set == "Herb" or self.set == "Ore") then
			-- The herb and ore lists are long, so they are subdivided between classic and expansions
			for key, expansion in pairs(module.pinTypes[self.set]) do
				for j, val in ipairs(expansion) do
					if (val["name"] == self.subset) then
						self.texture:SetTexture(val["icon"]);
					end
				end
			end
		else
			-- presumably self.set == "User"
			for i, val in ipairs(module.pinTypes[self.set]) do
				if (val["name"] == self.subset) then
					self.texture:SetTexture(val["icon"]);
				end
			end
		end
	end
	if (self.set == "User") then
		self:SetHeight(module:getOption("CT_MapMod_UserNoteSize") or 24);
		self:SetWidth(module:getOption("CT_MapMod_UserNoteSize") or 24);
	elseif (self.set == "Herb") then
		self:SetHeight(module:getOption("CT_MapMod_HerbNoteSize") or 14);
		self:SetWidth(module:getOption("CT_MapMod_HerbNoteSize") or 14);
	else
		self:SetHeight(module:getOption("CT_MapMod_OreNoteSize") or 14);
		self:SetWidth(module:getOption("CT_MapMod_OreNoteSize") or 14);
	end
	self.texture:SetAllPoints();
	self:Show();
	
	-- update properties for the notepanel, if it exists.
	-- the notepanel doesn't exist until a pin has been clicked on at least once, to avoid hogging memory and CPU wastefully.
	if (self.notepanel) then
		self:UpdateNotePanel();
	end
	
	-- create the ability to move the pin around
	self.isBeingDragged = nil;
	self:RegisterForDrag("RightButton");
	self:HookScript("OnDragStart", function()
		if (module.PinHasFocus) then return; end
		self.isBeingDragged = true;
		self:HookScript("OnUpdate",
			function()
				if (self.isBeingDragged) then
					local x,y = self:GetMap():GetNormalizedCursorPosition();
					if (x and y) then
						self:SetPosition(x,y);
					end
				end
			end
		);
	end);
	self:HookScript("OnDragStop", function()
		if (not self.isBeingDragged) then return; end
		self.isBeingDragged = nil;
		local x,y = self:GetMap():GetNormalizedCursorPosition();
		if (x and y) then
			CT_MapMod_Notes[self.mapid][self.i] ["x"] = x;
			CT_MapMod_Notes[self.mapid][self.i] ["y"] = y;
			self.x = x;
			self.y = y;
			self:SetPosition(x,y);
		end
	end);
	
end
 
function CT_MapMod_PinMixin:OnReleased()
	-- Override in your mixin, called when this pin is being released by a data provider and is no longer on the map
	if (self.isShowingTip) then
		GameTooltip:Hide();
		self.isShowingTip = nil;
	end
	if (self.notepanel) then self.notepanel:Hide(); end
	self:Hide();
	
end
 
function CT_MapMod_PinMixin:OnClick(button)
	-- Override in your mixin, called when this pin is clicked

	-- create the notepanel if it hasn't been done already.   This is deferred from onload
	if (not self.notepanel) then
		self:CreateNotePanel();  -- happens only once
		self:UpdateNotePanel();  -- happens every time the pin is acquired
	end


	if (module.PinHasFocus) then return; end

	if (IsShiftKeyDown()) then
		module.PinHasFocus = self;
		self.notepanel:Show();
	end

end

function CT_MapMod_PinMixin:OnMouseEnter()
	local icon = "";
	if (self.set == "Herb" or self.set == "Ore") then
		for key, expansion in pairs(module.pinTypes[self.set]) do
			for i, type in ipairs(expansion) do
				if (type["name"] == self.subset) then
					icon = type["icon"]
				end
			end
		end
	else
		-- presumably self.set == "User"
		for i, type in ipairs(module.pinTypes[self.set]) do
			if (type["name"] == self.subset) then
				icon = type["icon"]
			end
		end	
	end
	if ( self.x > 0.5 ) then
		GameTooltip:SetOwner(self, "ANCHOR_LEFT");
	else
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	end
	GameTooltip:ClearLines();
	GameTooltip:AddDoubleLine("|T"..icon..":20|t " .. self.name, self.set, 0, 1, 0, 0.6, 0.6, 0.6);
	if ( self.descript ) then
		GameTooltip:AddLine(self.descript, nil, nil, nil, 1);
	end
	if (not module.PinHasFocus) then  -- clicking on pins won't do anything while the edit box is open for this or another pin
		if (self.datemodified and self.version) then
			GameTooltip:AddDoubleLine(module.text["CT_MapMod/Pin/Shift-Click to Edit"], self.datemodified .. " (" .. self.version .. ")", 0.00, 0.50, 0.90, 0.45, 0.45, 0.45);
		else	
			GameTooltip:AddLine(module.text["CT_MapMod/Map/Shift-Click to Drag"], 0, 0.5, 0.9, 1);
		end
		GameTooltip:AddDoubleLine(module.text["CT_MapMod/Pin/Right-Click to Drag"], self.mapid, 0.00, 0.50, 0.90, 0.05, 0.05, 0.05 );
	else
		if (self.datemodified and self.version) then
			GameTooltip:AddDoubleLine(" ", self.datemodified .. " (" .. self.version .. ")", 0.00, 0.50, 0.90, 0.45, 0.45, 0.45);
		end
	end
	GameTooltip:Show();
end
 
function CT_MapMod_PinMixin:OnMouseLeave()
	-- Override in your mixin, called when the mouse leaves this pin
	GameTooltip:Hide();
end	
 
function CT_MapMod_PinMixin:ApplyFrameLevel()
	if (self.set == "User") then
		self:SetFrameLevel (2099)
	else
		self:SetFrameLevel(2012);  -- herbalism and mining nodes don't cover over the flypoints
	end
end

function CT_MapMod_PinMixin:ApplyCurrentScale()
	local scale;
	local startScale = 0.80;
	local endScale = 1.60;
	local scaleFactor = 1;
	if ((module:getGameVersion() == CT_GAME_VERSION_CLASSIC) or (WorldMapFrame:IsMaximized())) then
		-- This is WoW Classic, or this is WoW Retail and the window is maximized
		scale = 1.5 / self:GetMap():GetCanvasScale() * Lerp(startScale, endScale, Saturate(scaleFactor * self:GetMap():GetCanvasZoomPercent()))
	else
		scale = 1.0 / self:GetMap():GetCanvasScale() * Lerp(startScale, endScale, Saturate(scaleFactor * self:GetMap():GetCanvasZoomPercent()))
	end
	if scale then
		if not self:IsIgnoringGlobalPinScale() then
			scale = scale * self:GetMap():GetGlobalPinScale();
		end
		self:SetScale(scale);
		self:ApplyCurrentPosition();
	end
end

function CT_MapMod_PinMixin:ApplyCurrentAlpha()
	if ((module:getGameVersion() == CT_GAME_VERSION_CLASSIC) or (WorldMapFrame:IsMaximized())) then
		self:SetAlpha(Lerp( 0.3 + 0.7*((module:getOption("CT_MapMod_AlphaZoomedOut")) or 0.75), module:getOption("CT_MapMod_AlphaZoomedIn") or 1.00, Saturate(1.00 * self:GetMap():GetCanvasZoomPercent())));
	else
		self:SetAlpha(Lerp( 0.0 + 1.0*((module:getOption("CT_MapMod_AlphaZoomedOut")) or 0.75), module:getOption("CT_MapMod_AlphaZoomedIn") or 1.00, Saturate(1.00 * self:GetMap():GetCanvasZoomPercent())));
	end  	
end

-- This function is called the first time the pin is clicked on, and also every subsequent time the pin is acquired
function  CT_MapMod_PinMixin:UpdateNotePanel()
	self.notepanel:ClearAllPoints();
	if (self.x <= 0.5) then	
		if (self.y <= 0.5) then
			self.notepanel:SetPoint("TOPLEFT",self,"BOTTOMRIGHT",30,0);
		else
			self.notepanel:SetPoint("BOTTOMLEFT",self,"TOPRIGHT",30,0);
		end
	else
		if (self.y <= 0.5) then
			self.notepanel:SetPoint("TOPRIGHT",self,"BOTTOMLEFT",30,0);
		else
			self.notepanel:SetPoint("BOTTOMRIGHT",self,"TOPLEFT",30,0);
		end	
	end
	self.notepanel.namefield:SetText(self.name);
	self.notepanel.descriptfield:SetText(self.descript);
	self.notepanel.xfield:SetText(math.floor(1000*self.x)/10);
	self.notepanel.yfield:SetText(math.floor(1000*self.y)/10);

	if (self.set == "User") then
		self.notepanel.usersubsetdropdown:Show();
		self.notepanel.herbsubsetdropdown:Hide();
		self.notepanel.oresubsetdropdown:Hide();
		UIDropDownMenu_SetText(self.notepanel.setdropdown,"User");
		UIDropDownMenu_SetText(self.notepanel.usersubsetdropdown,self.subset);
		UIDropDownMenu_SetText(self.notepanel.herbsubsetdropdown,module.pinTypes["Herb"]["Classic"][1]["name"]);
		UIDropDownMenu_SetText(self.notepanel.oresubsetdropdown,module.pinTypes["Ore"]["Classic"][1]["name"]);
	elseif (self.set == "Herb") then
		self.notepanel.usersubsetdropdown:Hide();
		self.notepanel.herbsubsetdropdown:Show();
		self.notepanel.oresubsetdropdown:Hide();
		UIDropDownMenu_SetText(self.notepanel.setdropdown,"Herb");
		UIDropDownMenu_SetText(self.notepanel.usersubsetdropdown,module.pinTypes["User"][1]["name"]);
		UIDropDownMenu_SetText(self.notepanel.herbsubsetdropdown,self.subset);
		UIDropDownMenu_SetText(self.notepanel.oresubsetdropdown,module.pinTypes["Ore"]["Classic"][1]["name"]);
	elseif (self.set == "Ore") then
		self.notepanel.usersubsetdropdown:Hide();
		self.notepanel.herbsubsetdropdown:Hide();
		self.notepanel.oresubsetdropdown:Show();
		UIDropDownMenu_SetText(self.notepanel.setdropdown,"Ore");
		UIDropDownMenu_SetText(self.notepanel.usersubsetdropdown,module.pinTypes["User"][1]["name"]);
		UIDropDownMenu_SetText(self.notepanel.herbsubsetdropdown,module.pinTypes["Herb"]["Classic"][1]["name"]);
		UIDropDownMenu_SetText(self.notepanel.oresubsetdropdown,self.subset);

	end
	UIDropDownMenu_SetText(self.notepanel.setdropdown,self.set);
end

-- This function is called the first time the pin is ever clicked.
-- In principal it is meant to happen when the pin is loaded for the first time, but if there are many pins then it could slow performance
-- Delaying until a pin is clicked on makes the performance hit negligible, by avoiding making a whole bunch of never-needed frames
function CT_MapMod_PinMixin:CreateNotePanel()
	if (self.notepanel) then return; end  --this shoud NEVER happen.  CreateNotePanel() is only supposed to happen once per pin!
	-- Create the note panel that is associated to this pin	
	self.notepanel = CreateFrame("FRAME",nil,self:GetMap().BorderFrame,"CT_MapMod_NoteTemplate");
	self.notepanel:SetScale(1.2);
	if (module:getGameVersion() == CT_GAME_VERSION_CLASSIC) then
		self.notepanel:SetFrameStrata("FULLSCREEN_DIALOG");
	end
	self.notepanel.pin = self;
	local textColor0 = "1.0:1.0:1.0";
	local textColor1 = "0.9:0.9:0.9";
	local textColor2 = "0.7:0.7:0.7";
	local textColor3 = "0.9:0.72:0.0";
	module:getFrame (
		{	["button#s:80:25#br:b:-42:16#v:GameMenuButtonTemplate#" .. module.text["CT_MapMod/Pin/Okay"]] = {
				["onclick"] = function(self, arg1)
					local pin = self:GetParent().pin;
					local set = UIDropDownMenu_GetText(self:GetParent().setdropdown);
					local subset;
					if (set == "User") then
						subset = self:GetParent().usersubsetdropdown.unapprovedValue;
					elseif (set == "Herb") then
						subset = self:GetParent().herbsubsetdropdown.unapprovedValue;
					elseif (set == "Ore") then
						subset = self:GetParent().oresubsetdropdown.unapprovedValue;
					end
					if (not subset) then return; end  -- this could happen if the user didn't pick an icon
					CT_MapMod_Notes[pin.mapid][pin.i] = {
						["x"] = pin.x,
						["y"] = pin.y,
						["name"] = self:GetParent().namefield:GetText() or pin.name,
						["set"] = set,
						["subset"] = subset,
						["descript"] = self:GetParent().descriptfield:GetText() or pin.descript,
						["datemodified"] = date("%Y%m%d"),
						["version"] = MODULE_VERSION,
					}
					self:GetParent():Hide();
					module.PinHasFocus = nil;
					-- calling onAcquired will update tooltips and anything else that wasn't already changed
					pin:OnAcquired(pin.mapid, pin.i, pin.x, pin.y, self:GetParent().namefield:GetText() or pin.name, self:GetParent().descriptfield:GetText() or pin.descript, set, subset, date("%Y%m%d"), MODULE_VERSION );
				end,
			},
			["button#s:80:25#b:b:0:16#v:GameMenuButtonTemplate#" .. module.text["CT_MapMod/Pin/Cancel"]] = {
				["onclick"] = function(self, arg1)
					local pin = self:GetParent().pin;
					self:GetParent():Hide();
					module.PinHasFocus = nil;
					UIDropDownMenu_SetText(pin.notepanel.setdropdown,pin.set);
					-- calling OnAcquired will reset everything user-visible to their original conditions
					pin:OnAcquired(pin.mapid, pin.i, pin.x, pin.y, pin.name, pin.descript, pin.set, pin.subset, pin.datemodified, pin.version);
				end,
			},
			["button#s:80:25#bl:b:42:16#v:GameMenuButtonTemplate#" .. module.text["CT_MapMod/Pin/Delete"]] = {
				["onclick"] = function(self, arg1)
					local pin = self:GetParent().pin;
					tremove(CT_MapMod_Notes[pin.mapid],pin.i);
					self:GetParent():Hide();
					pin:Hide();
					module.PinHasFocus = nil;
					pin:GetMap():RefreshAll();
				end,
			},
			["font#l:tr:-100:-20#x#" .. textColor2 .. ":l"] = { },
			["editbox#l:tr:-85:-20#s:30:18#v:CT_MapMod_EditBoxTemplate"] = { 
				["onload"] = function(self)
					self:GetParent().xfield = self;
					self:SetAutoFocus(false);
					self:SetBackdropColor(1,1,1,0);
					self:HookScript("OnEditFocusGained", function(self)
						self:ClearFocus();
					end);
				end,
			},
			["font#l:tr:-55:-20#y#" .. textColor2 .. ":l"] = { },
			["editbox#l:tr:-40:-20#s:30:18#v:CT_MapMod_EditBoxTemplate"] = { 
				["onload"] = function(self)
					self:GetParent().yfield = self;
					self:SetAutoFocus(false);
					self:SetBackdropColor(1,1,1,0);
					self:HookScript("OnEditFocusGained", function(self)
						self:ClearFocus();
					end);
				end,
			},
			["font#l:tl:15:-30#" .. module.text["CT_MapMod/Pin/Name"] .. "#" .. textColor2 .. ":l"] = { },
			["editbox#l:tl:55:-30#s:100:18#v:CT_MapMod_EditBoxTemplate"] = { 
				["onload"] = function(self)
					self:GetParent().namefield = self;
					self:SetAutoFocus(false);
					self:HookScript("OnEscapePressed", function(self)
						self:ClearFocus();
					end);
					self:HookScript("OnEnterPressed", function(self)
						self:ClearFocus();
					end);
				end,
			},	
			["font#l:tl:15:-60#" .. module.text["CT_MapMod/Pin/Type"] .. "#" .. textColor2 .. ":l"] = { },
			["font#l:t:0:-60#" .. module.text["CT_MapMod/Pin/Icon"] .. "#" .. textColor2 .. ":l"] = { },
			["font#l:tl:15:-90#" .. module.text["CT_MapMod/Pin/Description"] .. "#" .. textColor2 .. ":l"] = { },
			["editbox#l:tl:20:-110#s:290:18#v:CT_MapMod_EditBoxTemplate"] = { 
				["onload"] = function(self)
					self:GetParent().descriptfield = self;
					self:SetAutoFocus(false);
					self:HookScript("OnEscapePressed", function(self)
						self:ClearFocus();
					end);
					self:HookScript("OnEnterPressed", function(self)
						self:ClearFocus();
					end);
				end,
			},
		},
		self.notepanel
	);
	self.notepanel.setdropdown = CreateFrame("Frame", nil, self.notepanel, "UIDropDownMenuTemplate");
	--self.notepanel.setdropdown = L_Create_UIDropDownMenu(nil or "", self.notepanel);
	self.notepanel.usersubsetdropdown = CreateFrame("Frame", nil, self.notepanel, "UIDropDownMenuTemplate");
	--self.notepanel.usersubsetdropdown = L_Create_UIDropDownMenu(nil or "", self.notepanel);
	self.notepanel.herbsubsetdropdown = CreateFrame("Frame", nil, self.notepanel, "UIDropDownMenuTemplate");
	--self.notepanel.herbsubsetdropdown = L_Create_UIDropDownMenu(nil or "", self.notepanel);
	self.notepanel.oresubsetdropdown = CreateFrame("Frame", nil, self.notepanel, "UIDropDownMenuTemplate");
	--self.notepanel.oresubsetdropdown = L_Create_UIDropDownMenu(nil or "", self.notepanel);
	


	self.notepanel.setdropdown:SetPoint("LEFT",self.notepanel,"TOPLEFT",35,-60);
	UIDropDownMenu_SetWidth(self.notepanel.setdropdown, 90);

	self.notepanel.usersubsetdropdown:SetPoint("LEFT",self.notepanel,"TOP",30,-60);
	UIDropDownMenu_SetWidth(self.notepanel.usersubsetdropdown, 90);

	self.notepanel.herbsubsetdropdown:SetPoint("LEFT",self.notepanel,"TOP",30,-60);
	UIDropDownMenu_SetWidth(self.notepanel.herbsubsetdropdown, 90);

	self.notepanel.oresubsetdropdown:SetPoint("LEFT",self.notepanel,"TOP",30,-60);
	UIDropDownMenu_SetWidth(self.notepanel.oresubsetdropdown, 90);

	UIDropDownMenu_Initialize(self.notepanel.setdropdown, function()
		local dropdownEntry = { };

		-- properties common to all
		dropdownEntry.func = function(self)
			local dropdown = UIDROPDOWNMENU_OPEN_MENU or UIDROPDOWNMENU_INIT_MENU;
			local notepanel = dropdown:GetParent();
			local pin = notepanel.pin;
			dropdown.unapprovedValue = self.value;
			if (self.value == "User") then
				notepanel.usersubsetdropdown:Show();
				notepanel.herbsubsetdropdown:Hide();
				notepanel.oresubsetdropdown:Hide();
				pin:SetHeight(module:getOption("CT_MapMod_UserNoteSize") or 24);
				pin:SetWidth(module:getOption("CT_MapMod_UserNoteSize") or 24);
				for i, val in ipairs(module.pinTypes["User"]) do
					if (val["name"] == UIDropDownMenu_GetText(notepanel.usersubsetdropdown)) then
						pin.texture:SetTexture(val["icon"]);
					end
				end
			elseif (self.value == "Herb") then
				notepanel.usersubsetdropdown:Hide();
				notepanel.herbsubsetdropdown:Show();
				notepanel.oresubsetdropdown:Hide();
				pin:SetHeight(module:getOption("CT_MapMod_HerbNoteSize") or 14);
				pin:SetWidth(module:getOption("CT_MapMod_HerbNoteSize") or 14);
				for key, expansion in pairs(module.pinTypes["Herb"]) do
					-- herbs are divided into expansions, because there are so many
					for i, val in ipairs(expansion) do
						if (val["name"] == UIDropDownMenu_GetText(notepanel.herbsubsetdropdown)) then
							pin.texture:SetTexture(val["icon"]);
						end
					end
				end
			else
				notepanel.usersubsetdropdown:Hide();
				notepanel.herbsubsetdropdown:Hide();
				notepanel.oresubsetdropdown:Show();
				pin:SetHeight(module:getOption("CT_MapMod_OreNoteSize") or 14);
				pin:SetWidth(module:getOption("CT_MapMod_OreNoteSize") or 14);
				for key, expansion in pairs(module.pinTypes["Ore"]) do
					-- ore are divided into expansions, because there are so many
					for i, val in ipairs(expansion) do
						if (val["name"] == UIDropDownMenu_GetText(notepanel.oresubsetdropdown)) then
							pin.texture:SetTexture(val["icon"]);
						end
					end
				end
			end
			UIDropDownMenu_SetText(dropdown,self.value);
		end

		-- user
		dropdownEntry.value = "User";
		dropdownEntry.text = module.text["User-Selected Icon"] or "User-Selected Icon";
		dropdownEntry.checked = nil;
		if ((self.notepanel.setdropdown.unapprovedValue or self.set) == "User") then dropdownEntry.checked = true; end
		UIDropDownMenu_AddButton(dropdownEntry);

		-- herb
		dropdownEntry.value = "Herb";
		dropdownEntry.text = module.text["Herbalism Node"] or "Herbablism Node";
		dropdownEntry.checked = nil;
		if ((self.notepanel.setdropdown.unapprovedValue or self.set) == "Herb") then dropdownEntry.checked = true; end
		UIDropDownMenu_AddButton(dropdownEntry);

		-- ore
		dropdownEntry.value = "Ore";
		dropdownEntry.text = module.text["Mining Ore Node"] or "Mining Ore Node";
		dropdownEntry.checked = nil;
		if ((self.notepanel.setdropdown.unapprovedValue or self.set) == "Ore") then dropdownEntry.checked = true; end
		UIDropDownMenu_AddButton(dropdownEntry);
	end);
	UIDropDownMenu_JustifyText(self.notepanel.setdropdown, "LEFT");

	UIDropDownMenu_Initialize(self.notepanel.usersubsetdropdown, function(frame, level, menuList)
		local dropdownEntry = { };

		-- properties common to all
		dropdownEntry.func = function(entry, arg1, arg2, checked)
			local dropdown = self.notepanel.usersubsetdropdown
			dropdown.unapprovedValue = entry.value;
			UIDropDownMenu_SetText(dropdown,module.text["CT_MapMod/User/" .. entry.value] or entry.value);
			local pin = dropdown:GetParent().pin;
			pin.texture:SetHeight(module:getOption("CT_MapMod_UserNoteSize") or 24);
			pin.texture:SetWidth(module:getOption("CT_MapMod_UserNoteSize") or 24);
			for i, val in ipairs(module.pinTypes["User"]) do
				if (val["name"] == entry.value) then
					pin.texture:SetTexture(val["icon"]);
				end
			end
		end

		-- properties unique to each option
		for i, type in ipairs(module.pinTypes["User"]) do
			dropdownEntry.text = module.text["CT_MapMod/User/" .. type["name"]] or type["name"];
			dropdownEntry.value = type["name"];
			dropdownEntry.icon = type["icon"];
			if (dropdownEntry.value == (self.notepanel.usersubsetdropdown.unapprovedValue or self.subset)) then
				dropdownEntry.checked = true;
			elseif (not self.notepanel.usersubsetdropdown.unapprovedValue and self.set ~= "User" and i == 1) then
				dropdownEntry.checked = true;
			else
				dropdownEntry.checked = false;
			end
			UIDropDownMenu_AddButton(dropdownEntry);
		end
	end);
	UIDropDownMenu_JustifyText(self.notepanel.usersubsetdropdown, "LEFT");

	UIDropDownMenu_Initialize(self.notepanel.herbsubsetdropdown, function(frame, level, menuList)
		local dropdownEntry = { };

		-- properties common to all
		dropdownEntry.func = function(entry, arg1, arg2, checked)
			local dropdown = self.notepanel.herbsubsetdropdown
			dropdown.unapprovedValue = entry.value;
			UIDropDownMenu_SetText(dropdown,module.text["CT_MapMod/Herb/" .. entry.value] or entry.value);
			local pin = dropdown:GetParent().pin;
			pin.texture:SetHeight(module:getOption("CT_MapMod_HerbNoteSize") or 14);
			pin.texture:SetWidth(module:getOption("CT_MapMod_HerbNoteSize") or 14);
			for key, expansion in pairs(module.pinTypes["Herb"]) do
				for i, val in ipairs(expansion) do 
					if (val["name"] == entry.value) then
						pin.texture:SetTexture(val["icon"]);
					end
				end
			end
		end

		-- properties unique to each option
		if (module:getGameVersion() == CT_GAME_VERSION_RETAIL) then
			for key, expansion in pairs(module.pinTypes["Herb"]) do
				if (level == 1) then
					dropdownEntry.text = key;
					dropdownEntry.hasArrow = true;
					dropdownEntry.value = nil;
					dropdownEntry.icon = nil;
					dropdownEntry.menuList = key;
					UIDropDownMenu_AddButton(dropdownEntry);
				elseif (key == menuList) then
					for i, type in ipairs(expansion) do
						dropdownEntry.text = module.text["CT_MapMod/Herb/" .. type["name"]] or type["name"];
						dropdownEntry.value = type["name"];
						dropdownEntry.icon = type["icon"];
						dropdownEntry.hasArrow = nil;
						dropdownEntry.menuList = nil;
						if (dropdownEntry.value == (self.notepanel.herbsubsetdropdown.unapprovedValue or self.subset)) then
							dropdownEntry.checked = true;
						elseif (not self.notepanel.herbsubsetdropdown.unapprovedValue and self.set ~= "Herb" and i == 1 and key == "Classic") then
							dropdownEntry.checked = true;
						else
							dropdownEntry.checked = false;
						end
						UIDropDownMenu_AddButton(dropdownEntry,2);
					end
				end
			end
		elseif (module:getGameVersion() == CT_GAME_VERSION_CLASSIC) then
			for i, type in ipairs(module.pinTypes["Herb"]["Classic"]) do
				dropdownEntry.text = module.text["CT_MapMod/Herb/" .. type["name"]] or type["name"];
				dropdownEntry.value = type["name"];
				dropdownEntry.icon = type["icon"];
				dropdownEntry.hasArrow = nil;
				dropdownEntry.menuList = nil;
				if (dropdownEntry.value == (self.notepanel.herbsubsetdropdown.unapprovedValue or self.subset)) then
					dropdownEntry.checked = true;
				elseif (not self.notepanel.herbsubsetdropdown.unapprovedValue and self.set ~= "Herb" and i == 1) then
					dropdownEntry.checked = true;
				else
					dropdownEntry.checked = false;
				end
				UIDropDownMenu_AddButton(dropdownEntry);
			end
		end
	end);
	UIDropDownMenu_JustifyText(self.notepanel.herbsubsetdropdown, "LEFT");

	UIDropDownMenu_Initialize(self.notepanel.oresubsetdropdown, function(frame, level, menuList)
		local dropdownEntry = { };

		-- properties common to all
		dropdownEntry.func = function(entry, arg1, arg2, checked)
			local dropdown = self.notepanel.oresubsetdropdown
			dropdown.unapprovedValue = entry.value;
			UIDropDownMenu_SetText(dropdown,module.text["CT_MapMod/Ore/" .. entry.value] or entry.value);
			local pin = dropdown:GetParent().pin;
			pin.texture:SetHeight(module:getOption("CT_MapMod_OreNoteSize") or 14);
			pin.texture:SetWidth(module:getOption("CT_MapMod_OreNoteSize") or 14);
			for key, expansion in pairs(module.pinTypes["Ore"]) do
				for i, val in ipairs(expansion) do 
					if (val["name"] == entry.value) then
						pin.texture:SetTexture(val["icon"]);
					end
				end
			end
		end

		-- properties unique to each option
		if (module:getGameVersion() == CT_GAME_VERSION_RETAIL) then
			for key, expansion in pairs(module.pinTypes["Ore"]) do
				if (level == 1) then
					dropdownEntry.text = key;
					dropdownEntry.hasArrow = true;
					dropdownEntry.value = nil;
					dropdownEntry.icon = nil;
					dropdownEntry.menuList = key;
					UIDropDownMenu_AddButton(dropdownEntry);
				elseif (key == menuList) then
					for i, type in ipairs(expansion) do
						dropdownEntry.text = module.text["CT_MapMod/Ore/" .. type["name"]] or type["name"];
						dropdownEntry.value = type["name"];
						dropdownEntry.icon = type["icon"];
						dropdownEntry.hasArrow = nil;
						dropdownEntry.menuList = nil;
						if (dropdownEntry.value == (self.notepanel.oresubsetdropdown.unapprovedValue or self.subset)) then
							dropdownEntry.checked = true;
						elseif (not self.notepanel.oresubsetdropdown.unapprovedValue and self.set ~= "Ore" and i == 1 and key == "Classic") then
							dropdownEntry.checked = true;
						else
							dropdownEntry.checked = false;
						end
						UIDropDownMenu_AddButton(dropdownEntry,2);
					end
				end
			end
		elseif (module:getGameVersion() == CT_GAME_VERSION_CLASSIC) then
			for i, type in ipairs(module.pinTypes["Ore"]["Classic"]) do
				dropdownEntry.text = module.text["CT_MapMod/Ore/" .. type["name"]] or type["name"];
				dropdownEntry.value = type["name"];
				dropdownEntry.icon = type["icon"];
				dropdownEntry.hasArrow = nil;
				dropdownEntry.menuList = nil;
				if (dropdownEntry.value == (self.notepanel.oresubsetdropdown.unapprovedValue or self.subset)) then
					dropdownEntry.checked = true;
				elseif (not self.notepanel.oresubsetdropdown.unapprovedValue and self.set ~= "Ore" and i == 1) then
					dropdownEntry.checked = true;
				else
					dropdownEntry.checked = false;
				end
				UIDropDownMenu_AddButton(dropdownEntry);
			end
		end
	end);
	UIDropDownMenu_JustifyText(self.notepanel.oresubsetdropdown, "LEFT");

end


--------------------------------------------
-- UI elements added to the world map title bar

function module:AddUIElements()
	local newpinmousestart = nil;
	module:getFrame	(
		{
			["button#n:CT_MapMod_WhereAmIButton#s:100:20#b:b:0:3#v:UIPanelButtonTemplate#" .. module.text["CT_MapMod/Map/Where am I?"]] = {
				["onload"] = function (self)
					self:HookScript("OnShow",function()
						if (module:getGameVersion() == CT_GAME_VERSION_CLASSIC) then
							self:SetFrameStrata("FULLSCREEN_DIALOG");
						end
						self:ClearAllPoints();
						local option = module:getOption("CT_MapMod_MapResetButtonPlacement") or 1;
						if (option == 1) then
							self:SetPoint("BOTTOM",WorldMapFrame.ScrollContainer,"BOTTOM",0,3);
						elseif (option == 2) then
							self:SetPoint("TOP",WorldMapFrame.ScrollContainer,"TOP",0,-1);
						else
							self:SetPoint("TOPLEFT",WorldMapFrame.ScrollContainer,"TOPLEFT",3,3);
						end
					end);
				end,
				["onclick"] = function(self, arg1)
					WorldMapFrame:SetMapID(C_Map.GetBestMapForUnit("player"));
				end,
				["onenter"] = function(self)
					GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 30, 15);
					GameTooltip:SetText("CT: " .. module.text["CT_MapMod/Map/Reset the map"]);
					GameTooltip:Show();
				end,
				["onleave"] = function(self)
					GameTooltip:Hide();
				end
			},
			["button#n:CT_MapMod_CreateNoteButton#s:75:16#tr:tr:-125:-3#v:UIPanelButtonTemplate#" .. module.text["CT_MapMod/Map/New Pin"]] = {
				["onload"] = function(self)
					if (module:getGameVersion() == CT_GAME_VERSION_CLASSIC) then
						self:HookScript("OnShow", function()	
							self:SetFrameStrata("FULLSCREEN_DIALOG");
						end);
					end
					WorldMapFrame:AddCanvasClickHandler(function(canvas, button)
						if (not module.isCreatingNote) then return; end
						module.isCreatingNote = nil;
						GameTooltip:Hide();
						if (InCombatLockdown()) then return; end
						local mapid = WorldMapFrame:GetMapID();
						local x,y = WorldMapFrame:GetNormalizedCursorPosition();
						if (mapid and x and y and x>=0 and y>=0 and x<=1 and y<=1 and (x~=0 or y~=0)) then
							module:InsertPin(mapid, x, y, "New Note", "User", "Grey Note", "New note at cursor");
							C_Timer.After(0.01,function() if (WorldMapFrame:GetMapID() ~= mapid) then WorldMapFrame:SetMapID(mapid) end end); --to add pins on the parts of a map in other zones
							WorldMapFrame:RefreshAllDataProviders();
						end
					end);
					self:RegisterForDrag("RightButton");
					self:HookScript("OnDragStart", function()
						if (not module.isCreatingNote) then
							newpinmousestart = GetCursorPosition(); --only interested in the X coord
							local value = module:getOption("CT_MapMod_CreateNoteButtonX") or -125;
							if ((module:getGameVersion() == CT_GAME_VERSION_CLASSIC) or (WorldMapFrame:IsMaximized())) then
								if (value < 75 - WorldMapFrame:GetWidth()) then module:setOption("CT_MapMod_CreateNoteButtonX", 75 - WorldMapFrame:GetWidth(), true, true); end
							elseif (WorldMapFrame.SidePanelToggle.OpenButton:IsShown()) then
								if (value < -535) then module:setOption("CT_MapMod_CreateNoteButtonX", -535, true, true); end
							else
								if (value < -820) then module:setOption("CT_MapMod_CreateNoteButtonX", -820, true, true); end
							end
							GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 30, -60);
							GameTooltip:SetText("|cFF999999Drag to set distance from TOP RIGHT corner");
							GameTooltip:Show();
						end  
					end);
					self:HookScript("OnDragStop", function()
						if (not newpinmousestart) then return; end
						local value = module:getOption("CT_MapMod_CreateNoteButtonX") or -125;
						value = value + (GetCursorPosition() - newpinmousestart);
						if (value > -125) then value = -125; end
						if ((module:getGameVersion() == CT_GAME_VERSION_CLASSIC) or (WorldMapFrame:IsMaximized())) then
							if (value < 75 - WorldMapFrame:GetWidth()) then value = 75 - WorldMapFrame:GetWidth(); end
						elseif (WorldMapFrame.SidePanelToggle.OpenButton:IsShown()) then
							if (value < -535) then value = -535; end
						else
							if (value < -820) then value = -820; end
						end
						module:setOption("CT_MapMod_CreateNoteButtonX", value, true, true)
						newpinmousestart = nil;
						GameTooltip:Hide();
						self:Disable();
						self:Enable();
					end);
					local duration = 0;
					self:HookScript("OnUpdate", function(newself, elapsed)
						duration = duration + elapsed;
						if (duration < .1) then return; end
						duration = 0;
						if (module.isCreatingNote) then
							GameTooltip:SetOwner(newself);
							GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 30, -60);
							GameTooltip:SetText(module.text["CT_MapMod/Map/Click on the map where you want the pin"]);
							GameTooltip:Show();
						end
						local value = module:getOption("CT_MapMod_CreateNoteButtonX") or -125;
						if (newpinmousestart) then
							-- Currently dragging the frame
							value = value + (GetCursorPosition() - newpinmousestart);
							if (value > -125) then value = -125; end
							if ((module:getGameVersion() == CT_GAME_VERSION_CLASSIC) or (WorldMapFrame:IsMaximized())) then
								if (value < 75 - WorldMapFrame:GetWidth()) then value = 75 - WorldMapFrame:GetWidth(); end
							elseif (WorldMapFrame.SidePanelToggle.OpenButton:IsShown()) then
								if (value < -535) then value = -535; end
							else
								if (value < -820) then value = -820; end
							end
						elseif (module:getGameVersion() == CT_GAME_VERSION_RETAIL and not WorldMapFrame:IsMaximized() and WorldMapFrame.SidePanelToggle.OpenButton:IsShown()) then
							-- Minimized without quest frame
							if (value < -225 and value > -350) then value = -225; end
							if (value < -350 and value > -477) then value = -477; end
							if (value < -535) then value = -535; end
						elseif (module:getGameVersion() == CT_GAME_VERSION_RETAIL and not WorldMapFrame:IsMaximized() and WorldMapFrame.SidePanelToggle.CloseButton:IsShown()) then
							-- Minimized with quest frame
							if (value < -370 and value > -495) then value = -370; end
							if (value < -495 and value > -622) then value = -622; end
							if (value < -820) then value = -820; end
						else
							-- Maximized (or WoW Classic)
							if (value < 75 - WorldMapFrame:GetWidth()) then value = 75 - WorldMapFrame:GetWidth(); end
							if (value < -(WorldMapFrame:GetWidth()/2)+90 and value > -(WorldMapFrame:GetWidth()/2)) then value = -(WorldMapFrame:GetWidth()/2)+90; end
							if (value < -(WorldMapFrame:GetWidth()/2) and value > -(WorldMapFrame:GetWidth()/2)-90) then value = -(WorldMapFrame:GetWidth()/2)-90; end
						end
						self:ClearAllPoints();
						self:SetPoint("TOPRIGHT",WorldMapFrame.BorderFrame,"TOPRIGHT",value,-3)
					end);
					self:HookScript("OnHide",function()
						if (module.isCreatingNote) then
							GameTooltip:Hide();
							module.isCreatingNote = nil;
						end
					end);
				end,
				["onclick"] = function(self, arg1)
					if ( arg1 == "LeftButton" ) then
						if (module.isEditingNote or module.isCreatingNote or newpinmousestart) then
							return;
						else
							module.isCreatingNote = true;
							GameTooltip:SetText("Click on the map where you want the pin");
						end
					end
				end,
				["onenter"] = function(self)
					if (not module.isCreatingNote and not newpinmousestart) then 
						GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 30, -60);
						GameTooltip:SetText(module.text["CT_MapMod/Map/Add a new pin to the map"]);
						GameTooltip:AddLine(module.text["CT_MapMod/Map/Right-Click to Drag"], .5, .5, .5);
						GameTooltip:Show();
					end
				end,
				["onleave"] = function(self)
					if (not module.isCreatingNote and not newpinmousestart) then GameTooltip:Hide(); end
				end,
			},
		["button#n:CT_MapMod_OptionsButton#s:75:16#tr:tr:-50:-3#v:UIPanelButtonTemplate#Options"] = {
				["onclick"] = function(self, arg1)
					module:showModuleOptions(module.name);
				end,
				["onenter"] = function(self)
					if (not module.isCreatingNote and not newpinmousestart) then
						GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 30, -60);
						GameTooltip:SetText("CT Map Options  (/ctmap)");
						GameTooltip:AddLine(module.text["CT_MapMod/Map/Right-Click to Drag"], .5, .5, .5);
						GameTooltip:Show();
					end
				end,
				["onleave"] = function(self)
					if (not module.isCreatingNote and not newpinmousestart) then
						GameTooltip:Hide();
					end
				end,
				["onload"] = function(self)
					if (module:getGameVersion() == CT_GAME_VERSION_CLASSIC) then
						self:HookScript("OnShow", function()	
							self:SetFrameStrata("FULLSCREEN_DIALOG");
						end);
					end
					self:RegisterForDrag("RightButton");
					local positionset = nil;
					self:HookScript("OnShow", function()
						-- deferring the positioning to guarantee the object it anchors to is loaded
						if (not positionset) then
							self:ClearAllPoints();
							self:SetPoint("LEFT",CT_MapMod_CreateNoteButton,"RIGHT",0,0);
							positionset = true;
						end
					end);
					self:HookScript("OnDragStart", function()
						if (not module.isCreatingNote) then
							newpinmousestart = GetCursorPosition(); --only interested in the X coord
							local value = module:getOption("CT_MapMod_CreateNoteButtonX") or -125;
							if ((module:getGameVersion() == CT_GAME_VERSION_CLASSIC) or (WorldMapFrame:IsMaximized())) then
								if (value < 75 - WorldMapFrame:GetWidth()) then module:setOption("CT_MapMod_CreateNoteButtonX", 75 - WorldMapFrame:GetWidth(), true, true); end
							elseif (WorldMapFrame.SidePanelToggle.OpenButton:IsShown()) then
								if (value < -535) then module:setOption("CT_MapMod_CreateNoteButtonX", -535, true, true); end
							else
								if (value < -820) then module:setOption("CT_MapMod_CreateNoteButtonX", -820, true, true); end
							end
							GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 30, -60);
							GameTooltip:SetText("|cFF999999Drag to set distance from TOP RIGHT corner");
							GameTooltip:Show();
						end  
					end);
					self:HookScript("OnDragStop", function()
						if (not newpinmousestart) then return; end
						local value = module:getOption("CT_MapMod_CreateNoteButtonX") or -125;
						value = value + (GetCursorPosition() - newpinmousestart);
						if (value > -125) then value = -125; end
						if ((module:getGameVersion() == CT_GAME_VERSION_CLASSIC) or (WorldMapFrame:IsMaximized())) then
							if (value < 75 - WorldMapFrame:GetWidth()) then value = 75 - WorldMapFrame:GetWidth(); end
						elseif (WorldMapFrame.SidePanelToggle.OpenButton:IsShown()) then
							if (value < -535) then value = -535; end
						else
							if (value < -820) then value = -820; end
						end
						module:setOption("CT_MapMod_CreateNoteButtonX", value, true, true)
						newpinmousestart = nil;
						GameTooltip:Hide();
						self:Disable();
						self:Enable();
					end);
				end
			},
		["frame#n:CT_MapMod_pxy#s:80:16#b:b:-100:0"] = { 
				["onload"] = function(self)
					if (module:getGameVersion() == CT_GAME_VERSION_CLASSIC) then
						self:SetFrameStrata("FULLSCREEN_DIALOG");
					end
					module.pxy = self
					self.text = self:CreateFontString(nil,"ARTWORK","ChatFontNormal");
				end,
				["onenter"] = function(self)
					GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 30, 15);
					local playerposition = C_Map.GetPlayerMapPosition(WorldMapFrame:GetMapID(),"player");
					if (playerposition) then
						GameTooltip:SetText("CT: Player Coords");
					else
						GameTooltip:SetText("Player coords not available here");
					end
					GameTooltip:Show();
				end,
				["onleave"] = function(self)
					GameTooltip:Hide();
				end
			},
		["frame#n:CT_MapMod_cxy#s:80:16#b:b:100:0"] =  { 
				["onload"] = function(self)
					if (module:getGameVersion() == CT_GAME_VERSION_CLASSIC) then
						self:SetFrameStrata("FULLSCREEN_DIALOG");
					end
					module.cxy = self
					self.text = self:CreateFontString(nil,"ARTWORK","ChatFontNormal");
				end,
				["onenter"] = function(self)
					GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 30, 15);
					GameTooltip:SetText("CT: Cursor Coords");
					GameTooltip:Show();
				end,
				["onleave"] = function(self)
					GameTooltip:Hide();
				end
			},
		},
		WorldMapFrame.BorderFrame
	);
			
	local timesinceupdate = 0;
	WorldMapFrame.ScrollContainer:HookScript("OnUpdate", function(self, elapsed)
		timesinceupdate = timesinceupdate + elapsed;
		if (timesinceupdate < .25) then return; end
		timesinceupdate = 0;
		local mapid = WorldMapFrame:GetMapID();
		if (mapid) then
			local playerposition = C_Map.GetPlayerMapPosition(mapid,"player");
			if (playerposition) then
				local px, py = playerposition:GetXY();
				px = math.floor(px*1000)/10;
				py = math.floor(py*1000)/10;
				module.pxy.text:SetText(format("P: %.1f, %.1f", px, py));
			else
				module.pxy.text:SetText("-");
			end
			if (mapid == C_Map.GetBestMapForUnit("player")) then
				module.pxy.text:SetTextColor(1,1,1,1);
				if ((module:getOption("CT_MapMod_ShowMapResetButton") or 1) == 1) then
					_G["CT_MapMod_WhereAmIButton"]:Hide();
				end			
			else
				module.pxy.text:SetTextColor(1,1,1,.3);			
				if ((module:getOption("CT_MapMod_ShowMapResetButton") or 1) == 1) then
					_G["CT_MapMod_WhereAmIButton"]:Show();
				end				
			end
		end	
		local cx, cy = WorldMapFrame:GetNormalizedCursorPosition();
		if (cx and cy) then
			if (cx > 0 and cx < 1 and cy > 0 and cy < 1) then
				module.cxy.text:SetTextColor(1,1,1,1);
			else
				module.cxy.text:SetTextColor(1,1,1,.3);			
			end
			cx = math.floor(cx*1000)/10;
			cx = math.max(math.min(cx,100),0);
			cy = math.floor(cy*1000)/10;
			cy = math.max(math.min(cy,100),0);				
			module.cxy.text:SetText(format("C: %.1f, %.1f", cx, cy));
		end
	end);
end


--------------------------------------------
-- Auto-Gathering

do	
	-- Outside combat, monitor the player's actions to detect herbalism and mining
	local frame = CreateFrame("Frame")
	frame:RegisterEvent("UNIT_SPELLCAST_SENT");
	frame:RegisterEvent("PLAYER_REGEN_DISABLED");
	frame:RegisterEvent("PLAYER_REGEN_ENABLED");
	frame:SetScript("OnEvent", function(self, event, arg1, arg2, arg3, arg4)
		if (event == "UNIT_SPELLCAST_SENT" and arg1 == "player") then
			
			-- Stop quickly when we don't want to be doing this
			if (InCombatLockdown() or IsInInstance()) then return; end

			-- Where are we?  (If the answer isn't clear, also stop quickly)
			local mapid = C_Map.GetBestMapForUnit("player");
			if (not mapid) then return; end					-- could be nil when the player isn't on any real map
			local position = C_Map.GetPlayerMapPosition(mapid,"player");
			if not (position) then return; end				-- could be nil in places like the Warlords of Draenor garrison
			local x,y = position:GetXY();
			if (not x or not y or (x == 0 and y == 0)) then return; end	-- could be nil or 0 in dungeons and raids to prevent cheating

			-- Herbalism and Mining
			if (module.herbalismSkills[arg4] and (module:getOption("CT_MapMod_AutoGatherHerbs") or 1) == 1) then
				module:InsertHerb(mapid, x, y, arg2);
			elseif (module.miningSkills[arg4] and (module:getOption("CT_MapMod_AutoGatherOre") or 1) == 1) then
				module:InsertOre(mapid, x, y, arg2);
			end
			
		elseif (event == "PLAYER_REGEN_DISABLED") then
			-- Improve performance by not even looking for herbs/mining during combat
			frame:UnregisterEvent("UNIT_SPELLCAST_SENT");
		elseif (event == "PLAYER_REGEN_ENABLED") then
			-- Restore searching for herbs/mining out of combat
			frame:RegisterEvent("UNIT_SPELLCAST_SENT");
		end
	end);
end


--------------------------------------------
-- Options handling

module.update = function(self, optName, value)
	if (optName == "init") then		
		module:Initialize();  -- handles things that arn't related to options
		module.pxy:ClearAllPoints();
		module.cxy:ClearAllPoints();
		local position = module:getOption("CT_MapMod_ShowPlayerCoordsOnMap") or 2;
		if (position == 1) then
			module.pxy:SetPoint("TOP",WorldMapFrame.BorderFrame,"TOP",-105,-3);
		elseif (position == 2) then
			module.pxy:SetPoint("BOTTOM",WorldMapFrame.ScrollContainer,"BOTTOM",-100,3);
		else
			module.pxy:Hide();
		end
		module.pxy.text:SetAllPoints();
		position = module:getOption("CT_MapMod_ShowCursorCoordsOnMap") or 2;
		if (position == 1) then
			module.cxy:SetPoint("TOP",WorldMapFrame.BorderFrame,"TOP",95,-3);
		elseif (position == 2) then
			module.cxy:SetPoint("BOTTOM",WorldMapFrame.ScrollContainer,"BOTTOM",100,3);
		else
			module.cxy:Hide();
		end		
		module.cxy.text:SetAllPoints();

		CT_MapMod_CreateNoteButton:ClearAllPoints();
		CT_MapMod_CreateNoteButton:SetPoint("TOPRIGHT",WorldMapFrame.BorderFrame,"TOPRIGHT",module:getOption("CT_MapMod_CreateNoteButtonX") or -125,-3)
		
		local showmapresetbutton = module:getOption("CT_MapMod_ShowMapResetButton") or 1;
		if (showmapresetbutton == 3) then _G["CT_MapMod_WhereAmIButton"]:Hide(); end
		
	elseif (optName == "CT_MapMod_ShowPlayerCoordsOnMap") then
		if (not module.pxy) then return; end
		module.pxy:ClearAllPoints();
		if (value == 1) then
			module.pxy:Show();
			module.pxy:SetPoint("TOP",WorldMapFrame.BorderFrame,"TOP",-105,-3);
		elseif (value == 2) then
			module.pxy:Show();
			module.pxy:SetPoint("BOTTOM",WorldMapFrame.ScrollContainer,"BOTTOM",-100,3);	
		else
			module.pxy:Hide();
		end
		module.pxy.text:SetAllPoints();
	elseif (optName == "CT_MapMod_ShowCursorCoordsOnMap") then
		if (not module.cxy) then return; end
		module.cxy:ClearAllPoints();
		if (value == 1) then
			module.cxy:Show();
			module.cxy:SetPoint("TOP",WorldMapFrame.BorderFrame,"TOP",65,-3);
		elseif (value == 2) then
			module.cxy:Show();
			module.cxy:SetPoint("BOTTOM",WorldMapFrame.ScrollContainer,"BOTTOM",100,3);		
		else
			module.cxy:Hide();
		end
		module.cxy.text:SetAllPoints();
	elseif (optName == "CT_MapMod_ShowMapResetButton") then
		if (not _G["CT_MapMod_WhereAmIButton"]) then return; end
		if (value == 2) then _G["CT_MapMod_WhereAmIButton"]:Show();
		elseif (value == 3) then _G["CT_MapMod_WhereAmIButton"]:Hide(); end
	elseif (optName == "CT_MapMod_MapResetButtonPlacement") then
		if (not _G["CT_MapMod_WhereAmIButton"]) then return; end
		_G["CT_MapMod_WhereAmIButton"]:ClearAllPoints();
		if (value == 1) then
			_G["CT_MapMod_WhereAmIButton"]:SetPoint("BOTTOM",WorldMapFrame.ScrollContainer,"BOTTOM",0,3);
		elseif (value == 2) then
			_G["CT_MapMod_WhereAmIButton"]:SetPoint("TOP",WorldMapFrame.ScrollContainer,"TOP",0,-1);
		else
			_G["CT_MapMod_WhereAmIButton"]:SetPoint("TOPLEFT",WorldMapFrame.ScrollContainer,"TOPLEFT",3,3);
		end
	elseif (optName == "CT_MapMod_UserNoteSize"
		or optName == "CT_MapMod_HerbNoteSize"
		or optName == "CT_MapMod_OreNoteSize"
		or optName == "CT_MapMod_UserNoteDisplay"
		or optName == "CT_MapMod_HerbNoteDisplay"
		or optName == "CT_MapMod_OreNoteDisplay"
		or optName == "CT_MapMod_AlphaZoomedOut"
		or optName == "CT_MapMod_AlphaZoomedIn"
		or optName == "CT_MapMod_ShowOnFlightMaps"
	) then
		WorldMapFrame:RefreshAllDataProviders();
		CloseTaxiMap();
	end
end


--------------------------------------------
-- /ctmap options frame

-- Slash command
local function slashCommand(msg)
	module:showModuleOptions(module.name);
end

module:setSlashCmd(slashCommand, "/ctmapmod", "/ctmap", "/mapmod", "/ctcarte", "/ctkarte");
-- Original: /ctmapmod, /ctmap, /mapmod
-- frFR: /ctcarte
-- deDE: /ctkarte

local theOptionsFrame;

local optionsFrameList;
local function optionsInit()
	optionsFrameList = module:framesInit();
end
local function optionsGetData()
	return module:framesGetData(optionsFrameList);
end
local function optionsAddFrame(offset, size, details, data)
	module:framesAddFrame(optionsFrameList, offset, size, details, data);
end
local function optionsAddObject(offset, size, details)
	module:framesAddObject(optionsFrameList, offset, size, details);
end
local function optionsAddScript(name, func)
	module:framesAddScript(optionsFrameList, name, func);
end

local function optionsAddTooltip(text)
	module:framesAddScript(optionsFrameList, "onenter", function(obj) module:displayTooltip(obj, text, "CT_ABOVEBELOW", 0, 0, CTCONTROLPANEL); end);
end

local function optionsBeginFrame(offset, size, details, data)
	module:framesBeginFrame(optionsFrameList, offset, size, details, data);
end
local function optionsEndFrame()
	module:framesEndFrame(optionsFrameList);
end

-- Options frame
module.frame = function()
	local textColor0 = "1.0:1.0:1.0";
	local textColor1 = "0.9:0.9:0.9";
	local textColor2 = "0.7:0.7:0.7";
	local textColor3 = "0.9:0.72:0.0";
	local xoffset, yoffset;

	optionsInit();

	optionsBeginFrame(-5, 0, "frame#tl:0:%y#r");
		-- Tips
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#" .. module.text["CT_MapMod/Options/Tips/Heading"]); -- Tips
		optionsAddObject( -2, 3*14, "font#t:0:%y#s:0:%s#l:13:0#r#" .. module.text["CT_MapMod/Options/Tips/Line 1"] .. "#" .. textColor2 .. ":l"); --You can use /ctmap, /ctmapmod, or /mapmod to open this options window directly.
		optionsAddObject( -5, 3*14, "font#t:0:%y#s:0:%s#l:13:0#r#" .. module.text["CT_MapMod/Options/Tips/Line 2"] .. "#" .. textColor2 .. ":l"); --Add pins to the world map using the 'new note' button at the top corner of the map!
		
		
		--Add Features to World Map
		optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#" .. module.text["CT_MapMod/Options/Add Features/Heading"]); -- Add Features to World Map
		
		optionsAddObject(-5,   50, "font#t:0:%y#s:0:%s#l:13:0#r#" .. module.text["CT_MapMod/Options/Add Features/Coordinates/Line 1"] .. "#" .. textColor2 .. ":l"); --Coordinates show where you are on the map, and where your mouse cursor is
		optionsAddObject(-5,   14, "font#t:0:%y#s:0:%s#l:13:0#r#" .. module.text["CT_MapMod/Options/Add Features/Coordinates/ShowPlayerCoordsOnMapLabel"] .. "#" .. textColor1 .. ":l"); -- Show player coordinates
		optionsAddObject(-5,   24, "dropdown#tl:5:%y#s:150:20#o:CT_MapMod_ShowPlayerCoordsOnMap:2#n:CT_MapMod_ShowPlayerCoordsOnMap#" .. module.text["CT_MapMod/Options/At Top"] .. "#" .. module.text["CT_MapMod/Options/At Bottom"] .. "#" .. module.text["CT_MapMod/Options/Disabled"]);
		optionsAddObject(-5,   14, "font#t:0:%y#s:0:%s#l:13:0#r#" .. module.text["CT_MapMod/Options/Add Features/Coordinates/ShowCursorCoordsOnMapLabel"] .. "#" .. textColor1 .. ":l"); -- Show cursor coordinates
		optionsAddObject(-5,   24, "dropdown#tl:5:%y#s:150:20#o:CT_MapMod_ShowCursorCoordsOnMap:2#n:CT_MapMod_ShowCursorCoordsOnMap#" .. module.text["CT_MapMod/Options/At Top"] .. "#" .. module.text["CT_MapMod/Options/At Bottom"] .. "#" .. module.text["CT_MapMod/Options/Disabled"]);
		
		optionsAddObject(-5,   50, "font#t:0:%y#s:0:%s#l:13:0#r#" .. module.text["CT_MapMod/Options/Add Features/WhereAmI/Line 1"] .. "#" .. textColor2 .. ":l"); -- The 'Where am I?' button resets the map to your location.
		optionsAddObject(-5,   14, "font#t:0:%y#s:0:%s#l:13:0#r#" .. module.text["CT_MapMod/Options/Add Features/WhereAmI/ShowMapResetButtonLabel"] .. "#" .. textColor1 .. ":l"); -- Show 'Where am I' button
		optionsAddObject(-5,   24, "dropdown#tl:5:%y#s:150:20#o:CT_MapMod_ShowMapResetButton#n:CT_MapMod_ShowMapResetButton#" .. module.text["CT_MapMod/Options/Auto"] .. "#" .. module.text["CT_MapMod/Options/Always"] .. "#" .. module.text["CT_MapMod/Options/Disabled"]);
		optionsBeginFrame(-5,   24, "dropdown#tl:5:%y#s:150:20#o:CT_MapMod_MapResetButtonPlacement#n:CT_MapMod_MapResetButtonPlacement#" .. module.text["CT_MapMod/Options/At Bottom"] .. "#" .. module.text["CT_MapMod/Options/At Top"] .. "#" .. module.text["CT_MapMod/Options/At Top Left"]);
			optionsAddScript("onupdate",	
				function(self)
					if (module:getOption("CT_MapMod_ShowMapResetButton") == 3) then
						UIDropDownMenu_DisableDropDown(CT_MapMod_MapResetButtonPlacement);
					else
						UIDropDownMenu_EnableDropDown(CT_MapMod_MapResetButtonPlacement);
					end
				end
			);
		optionsEndFrame();
		
		--Create and Display Pins
		optionsAddObject(-20,  17, "font#tl:5:%y#v:GameFontNormalLarge#" .. module.text["CT_MapMod/Options/Pins/Heading"]); -- Create and Display Pins
		
		optionsAddObject(-5,   50, "font#t:0:%y#s:0:%s#l:13:0#r#" .. module.text["CT_MapMod/Options/Pins/User/Line 1"] .. "#" .. textColor2 .. ":l"); -- Identify points of interest on the map with custom icons
		optionsAddObject(-5,   14, "font#t:0:%y#s:0:%s#l:13:0#r#" .. module.text["CT_MapMod/Options/Pins/User/UserNoteDisplayLabel"] .. "#" .. textColor1 .. ":l"); -- Show custom user notes
		optionsAddObject(-5,   24, "dropdown#tl:5:%y#s:150:20#o:CT_MapMod_UserNoteDisplay#n:CT_MapMod_UserNoteDisplay#" .. module.text["CT_MapMod/Options/Always"] .. "#" .. module.text["CT_MapMod/Options/Disabled"]);
		optionsAddObject(-5,    8, "font#t:0:%y#s:0:%s#l:13:0#r#" .. module.text["CT_MapMod/Options/Pins/Icon Size"] .. "#" .. textColor1 .. ":l"); -- Icon size
		optionsAddFrame( -5,   28, "slider#tl:24:%y#s:169:15#o:CT_MapMod_UserNoteSize:24##10:26:0.5");
		
		optionsAddObject(-5,   50, "font#t:0:%y#s:0:%s#l:13:0#r#" .. module.text["CT_MapMod/Options/Pins/Gathering/Line 1"] .. "#" .. textColor2 .. ":l"); -- Identify herbalist and mining nodes on the map.
		optionsAddObject(-5,   14, "font#t:0:%y#s:0:%s#l:13:0#r#" .. module.text["CT_MapMod/Options/Pins/Gathering/HerbNoteDisplayLabel"] .. "#" .. textColor1 .. ":l"); -- Show herb nodes
		optionsAddObject(-5,   24, "dropdown#tl:5:%y#s:150:20#o:CT_MapMod_HerbNoteDisplay#n:CT_MapMod_HerbNoteDisplay#" .. module.text["CT_MapMod/Options/Auto"] .. "#" .. module.text["CT_MapMod/Options/Always"] .. "#" .. module.text["CT_MapMod/Options/Disabled"]);
		optionsAddObject(-5,    8, "font#t:0:%y#s:0:%s#l:13:0#r#" .. module.text["CT_MapMod/Options/Pins/Icon Size"] .. "#" .. textColor1 .. ":l");
		optionsAddFrame( -5,   28, "slider#tl:24:%y#s:169:15#o:CT_MapMod_HerbNoteSize:14##10:26:0.5");
		optionsAddObject(-5,   14, "font#t:0:%y#s:0:%s#l:13:0#r#" .. module.text["CT_MapMod/Options/Pins/Gathering/OreNoteDisplayLabel"] .. "#" .. textColor1 .. ":l"); -- Show mining nodes
		optionsAddObject(-5,   24, "dropdown#tl:5:%y#s:150:20#o:CT_MapMod_OreNoteDisplay#n:CT_MapMod_OreNoteDisplay#" .. module.text["CT_MapMod/Options/Auto"] .. "#" .. module.text["CT_MapMod/Options/Always"] .. "#" .. module.text["CT_MapMod/Options/Disabled"]);
		optionsAddObject(-5,    8, "font#t:0:%y#s:0:%s#l:13:0#r#" .. module.text["CT_MapMod/Options/Pins/Icon Size"] .. "#" .. textColor1 .. ":l"); -- Icon size
		optionsAddFrame( -5,   28, "slider#tl:24:%y#s:169:15#o:CT_MapMod_OreNoteSize:14##10:26:0.5");
		optionsBeginFrame(-5,  26, "checkbutton#tl:10:%y#o:CT_MapMod_IncludeRandomSpawns#" .. module.text["CT_MapMod/Options/Pins/IncludeRandomSpawnsCheckButton"]); -- Include randomly-spawning rare nodes
			optionsAddTooltip({module.text["CT_MapMod/Options/Pins/IncludeRandomSpawnsCheckButton"], module.text["CT_MapMod/Options/Pins/IncludeRandomSpawnsTip"]});
		optionsEndFrame();
		optionsBeginFrame(-5,  26, "checkbutton#tl:10:%y#o:CT_MapMod_OverwriteGathering#" .. module.text["CT_MapMod/Options/Pins/OverwriteGatheringCheckButton"]); -- Include randomly-spawning rare nodes
			optionsAddTooltip({module.text["CT_MapMod/Options/Pins/OverwriteGatheringCheckButton"], module.text["CT_MapMod/Options/Pins/OverwriteGatheringTip"]});
		optionsEndFrame();
		optionsAddObject(-5,   50, "font#t:0:%y#s:0:%s#l:13:0#r#Reduce pin alpha to see other map features.\n(More alpha = more opaque)#" .. textColor2 .. ":l");
		optionsAddObject(-5,    8, "font#t:0:%y#s:0:%s#l:13:0#r#Alpha when zoomed out#" .. textColor1 .. ":l");
		optionsAddFrame( -5,   28, "slider#tl:24:%y#s:169:15#o:CT_MapMod_AlphaZoomedOut:0.75##0.50:1.00:0.05");
		optionsAddObject(-5,    8, "font#t:0:%y#s:0:%s#l:13:0#r#Alpha when zoomed in#" .. textColor1 .. ":l");
		optionsAddFrame( -5,   28, "slider#tl:24:%y#s:169:15#o:CT_MapMod_AlphaZoomedIn:1.00##0.50:1.00:0.05");
		
		if (module:getGameVersion() == CT_GAME_VERSION_RETAIL) then
			optionsAddObject(-5,   50, "font#t:0:%y#s:0:%s#l:13:0#r#Pins added to continents (via the World Map) \nmay also appear at flight masters.#" .. textColor2 .. ":l");
			optionsAddObject(-5,   14, "font#t:0:%y#s:0:%s#l:13:0#r#Also show pins on flight maps#" .. textColor1 .. ":l");
			optionsAddObject(-5,   24, "dropdown#tl:5:%y#s:150:20#o:CT_MapMod_ShowOnFlightMaps#n:CT_MapMod_ShowOnFlightMaps#" .. module.text["CT_MapMod/Options/Always"] .. "#" .. module.text["CT_MapMod/Options/Disabled"]);
		end
		
		-- Reset Options
		optionsBeginFrame(-20, 0, "frame#tl:0:%y#br:tr:0:%b");
			optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#" .. module.text["CT_MapMod/Options/Reset/Heading"]); -- Reset Options
			optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:CT_MapMod_resetAll#" .. module.text["CT_MapMod/Options/Reset/ResetAllCheckbox"]); -- Reset options for all of your characters
			optionsBeginFrame(   0,   30, "button#t:0:%y#s:120:%s#v:UIPanelButtonTemplate#" .. module.text["CT_MapMod/Options/Reset/ResetButton"]);  -- Reset options
				optionsAddScript("onclick",
					function(self)
						if (module:getOption("CT_MapMod_resetAll")) then
							CT_MapModOptions = {};
							ConsoleExec("RELOADUI");
						else
							-- eventually this should be replaced with code that wipes the variables completely away, to be truly "default"
							module:setOption("CT_MapMod_CreateNoteButtonX",-125,true,false);
							module:setOption("CT_MapMod_ShowPlayerCoordsOnMap",2,true,false);
							module:setOption("CT_MapMod_ShowCursorCoordsOnMap",2,true,false);
							module:setOption("CT_MapMod_AlphaZoomedOut",0.75,true,false);
							module:setOption("CT_MapMod_AlphaZoomedIn",1.00,true,false);
							module:setOption("CT_MapMod_UserNoteSize",24,true,false);
							module:setOption("CT_MapMod_HerbNoteSize",14,true,false);
							module:setOption("CT_MapMod_OreNoteSize",14,true,false);
							module:setOption("CT_MapMod_UserNoteDisplay",1,true,false);
							module:setOption("CT_MapMod_HerbNoteDisplay",1,true,false);
							module:setOption("CT_MapMod_OreNoteDisplay",1,true,false);
							module:setOption("CT_MapMod_ShowOnFlightMaps",1,true,false);
							
							ConsoleExec("RELOADUI");
						end
					end
				);
			optionsEndFrame();
		optionsEndFrame();
		optionsAddObject(  0, 3*13, "font#t:0:%y#s:0:%s#l#r#" .. module.text["CT_MapMod/Options/Reset/Line 1"] .. "#" .. textColor2); --Note: This will reset the options to default and then reload your UI.
		
	optionsEndFrame();

	return "frame#all", optionsGetData();
end



--------------------------------------------
-- Converting notes from older addon versions into the latest one


function module:ConvertOldNotes()

	-- Correcting mis-labelled herbs and removing anchor's weed
	for mapid, notetable in pairs(CT_MapMod_Notes) do
		for i, note in ipairs(notetable) do
			if (note["set"] == "Herb" and note["subset"] == "Sea Stalk") then note["subset"] = "Sea Stalks"; end		-- 8.0.1.4 to 8.0.1.5
			if (note["set"] == "Herb" and note["subset"] == "Siren's Song") then note["subset"] = "Siren's Sting"; end	-- 8.0.1.4 to 8.0.1.5
			if (note["set"] == "Herb" and note["subset"] == "Talandras Rose") then note["subset"] = "Talandra's Rose"; end   -- 8.1.5.2 to 8.1.5.3
			if (note["set"] == "Herb" and note["subset"] == "Arthas Tears") then note["subset"] = "Arthas' Tears"; end       -- 8.1.5.2 to 8.1.5.3
			if (note["set"] == "Herb" and note["subset"] == "Anchor Weed" and note["name"] == "Anchor Weed" and note["descript"] == "") then
				--removing anchor weed from pre-8.1.5.2, when "ignoregather" was added
				-- but leaving in place if the user created or edited the note manually
				if (note["version"] == "8.0.0.0" or
					note["version"] == "8.0.5.0" or --mislabel of 8.0.1.5 during beta test
					note["version"] == "8.0.1.1" or 
					note["version"] == "8.0.1.2" or 
					note["version"] == "8.0.1.3" or 
					note["version"] == "8.0.1.4" or 
					note["version"] == "8.0.1.5" or
					note["version"] == "8.0.1.6" or
					note["version"] == "8.0.1.7" or
					note["version"] == "8.0.1.8" or
					note["version"] == "8.1.0.0" or
					note["version"] == "8.1.0.1" or
					note["version"] == "8.1.0.2" or
					note["version"] == "8.1.0.3" or
					note["version"] == "8.1.5.1"
				) then
					tremove(notetable,i);
				end
			
			end
		end
	end
end



