
------------------------------------------------
--                 CT_MapMod                  --
--                                            --
-- Simple addon that allows the user to add   --
-- notes and gathered nodes to the world map. --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
------------------------------------------------

--------------------------------------------
-- Initialization

local module = { };
local _G = getfenv(0);

local MODULE_NAME = "CT_MapMod";
local MODULE_VERSION = strmatch(GetAddOnMetadata(MODULE_NAME, "version"), "^([%d.]+)");

module.name = MODULE_NAME;
module.version = MODULE_VERSION;

_G[MODULE_NAME] = module;
CT_Library:registerModule(module);

CT_MapMod_Notes = {}; 		-- Beginning in 8.0.1.4, this is where all notes are stored
CT_UserMap_Notes = {};  	-- Legacy variable holding map notes prior to 8.0.1.4

local CT_MapMod_OldZones = { }; -- defined at bottom of script
local CT_MapMod_OldNames = { }; -- defined at bottom of script

local function CT_MapMod_Initialize()		-- called via module.update("init") from CT_Library
	-- configure the hardcoded variables
	module.NoteTypes =
	{
		["User"] = 		-- previously this was set = 1 through 6.
		{
			{ ["name"] = "Grey Note", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Skin\\GreyNote" }, --1
			{ ["name"] = "Blue Shield", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Skin\\BlueShield" }, --2
			{ ["name"] = "Red Dot", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Skin\\RedDot" }, --3
			{ ["name"] = "White Circle", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Skin\\WhiteCircle" }, --4
			{ ["name"] = "Green Square", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Skin\\GreenSquare" }, --5
			{ ["name"] = "Red Cross", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Skin\\RedCross" }, --6
			-- 7 was for herb, but that's removed now
			-- 8 was for ore, but that's removed now
			{ ["name"] = "Diamond", ["icon"] = "Interface\\RaidFrame\\UI-RaidFrame-Threat" } -- added in 8.0
		},			
		["Herb"] =  		-- previously this was set = 7
		{
			{ ["name"] = "Bruiseweed", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed" }, -- 1
			{ ["name"] = "Arthas Tears", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_ArthasTears" }, -- 2
			{ ["name"] = "Black Lotus", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_BlackLotus" }, -- 3
			{ ["name"] = "Blindweed", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Blindweed" }, -- 4
			{ ["name"] = "Briarthorn", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Briarthorn" }, -- 5
			{ ["name"] = "Dreamfoil", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Dreamfoil" }, -- 6
			{ ["name"] = "Earthroot", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Earthroot" }, -- 7
			{ ["name"] = "Fadeleaf", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Fadeleaf" }, -- 8
			{ ["name"] = "Firebloom", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Firebloom" }, -- 9
			{ ["name"] = "Ghost Mushroom", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_GhostMushroom" }, -- 10
			{ ["name"] = "Golden Sansam", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_GoldenSansam" }, -- 11
			{ ["name"] = "Goldthorn", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Goldthorn" }, -- 12
			{ ["name"] = "Grave Moss", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_GraveMoss" }, -- 13
			{ ["name"] = "Gromsblood", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Gromsblood" }, -- 14
			{ ["name"] = "Icecap", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Icecap" }, -- 15
			{ ["name"] = "Khadgars Whisker", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_KhadgarsWhisker" }, -- 16
			{ ["name"] = "Kingsblood", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Kingsblood" }, -- 17
			{ ["name"] = "Liferoot", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Liferoot" }, -- 18
			{ ["name"] = "Mageroyal", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Mageroyal" }, -- 19
			{ ["name"] = "Mountain Silversage", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_MountainSilversage" }, -- 20
			{ ["name"] = "Peacebloom", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Peacebloom" }, -- 21
			{ ["name"] = "Plaguebloom", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Plaguebloom" }, -- 22
			{ ["name"] = "Purple Lotus", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_PurpleLotus" }, -- 23
			{ ["name"] = "Silverleaf", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Silverleaf" }, -- 24
			{ ["name"] = "Stranglekelp", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Stranglekelp" }, -- 25
			{ ["name"] = "Sungrass", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Sungrass" }, -- 26
			{ ["name"] = "Swiftthistle", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Swiftthistle" }, -- 27
			{ ["name"] = "Wild Steelbloom", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_WildSteelbloom" }, -- 28
			{ ["name"] = "Wintersbite", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Wintersbite" }, -- 29
			{ ["name"] = "Dreaming Glory", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_DreamingGlory" }, -- 30
			-- Burning Crusade
			{ ["name"] = "Felweed", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Felweed" }, -- 31
			{ ["name"] = "Flame Cap", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_FlameCap" }, -- 32
			{ ["name"] = "Mana Thistle", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_ManaThistle" }, -- 33
			{ ["name"] = "Netherbloom", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Netherbloom" }, -- 34
			{ ["name"] = "Netherdust Bush", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_NetherdustBush" }, -- 35
			{ ["name"] = "Nightmare Vine", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_NightmareVine" }, -- 36
			{ ["name"] = "Ragveil", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Ragveil" }, -- 37
			{ ["name"] = "Terocone", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Terocone" }, -- 38
			-- Wrath of the Lich King
			{ ["name"] = "Adders Tongue", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_AddersTongue" }, -- 39
			{ ["name"] = "Frost Lotus", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_FrostLotus" }, -- 40
			{ ["name"] = "Goldclover", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Goldclover" }, -- 41
			{ ["name"] = "Icethorn", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Icethorn" }, -- 42
			{ ["name"] = "Lichbloom", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Lichbloom" }, -- 43
			{ ["name"] = "Talandras Rose", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_TalandrasRose" }, -- 44
			{ ["name"] = "Tiger Lily", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_TigerLily" }, -- 45
			{ ["name"] = "Frozen Herb", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_FrozenHerb" }, -- 46
			-- Cataclysm
			{ ["name"] = "Cinderbloom", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed" },
			{ ["name"] = "Azshara's Veil", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed" },
			{ ["name"] = "Stormvein", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed" },
			{ ["name"] = "Heartblossom", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed" },
			{ ["name"] = "Whiptail", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed" },
			{ ["name"] = "Twilight Jasmine", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed" },
			-- Mists of Pandaria
			{ ["name"] = "Green Tea Leaf", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed" },
			{ ["name"] = "Rain Poppy", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed" },
			{ ["name"] = "Silkweed", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed" },
			{ ["name"] = "Snow Lily", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed" },
			{ ["name"] = "Fool's Cap", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed" },
			{ ["name"] = "Sha-Touched Herb", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed" },
			{ ["name"] = "Golden Lotus", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed" },
			-- Warlords of Draenor
			{ ["name"] = "Fireweed", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Fireweed" },
			{ ["name"] = "Gorgrond Flytrap", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_GorgrondFlytrap" },
			{ ["name"] = "Frostweed", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Frostweed" },
			{ ["name"] = "Nagrand Arrowbloom", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_NagrandArrowbloom" },
			{ ["name"] = "Starflower", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Starflower" },
			{ ["name"] = "Talador Orchid", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_TaladorOrchid" },
			{ ["name"] = "Withered Herb", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_FrozenHerb" },
			-- Legion
			{ ["name"] = "Aethril", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed" },
			{ ["name"] = "Astral Glory", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed" },
			{ ["name"] = "Dreamleaf", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed" },
			{ ["name"] = "Fel-Encrusted Herb", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed" },
			{ ["name"] = "Fjarnskaggl", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed" },
			{ ["name"] = "Foxflower", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed" },
			{ ["name"] = "Starlight Rose", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_StarlightRose" },
			-- Battle for Azeroth
			{ ["name"] = "Akunda's Bite", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_AkundasBite" },
			{ ["name"] = "Anchor Weed", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_AnchorWeed" },
			{ ["name"] = "Riverbud", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Riverbud" },
			{ ["name"] = "Sea Stalks", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_SeaStalk" },
			{ ["name"] = "Siren's Sting", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed" },
			{ ["name"] = "Star Moss", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_StarMoss" },
			{ ["name"] = "Winter's Kiss", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_WintersKiss" },
		},
		["Ore"] =     -- previously this was set = 8
		{ 
			{ ["name"] = "Copper", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_CopperVein" }, --1
			{ ["name"] = "Gold", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_GoldVein" }, --2
			{ ["name"] = "Iron", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_IronVein" }, --3
			{ ["name"] = "Mithril", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_MithrilVein" }, --4
			{ ["name"] = "Silver", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_SilverVein" }, --5
			{ ["name"] = "Thorium", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_ThoriumVein" }, --6
			{ ["name"] = "Tin", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_TinVein" }, --7
			{ ["name"] = "Truesilver", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_TruesilverVein" }, --8
			{ ["name"] = "Adamantite", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_AdamantiteVein" }, --9
			-- Burning Crusade
			{ ["name"] = "Fel Iron", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_FelIronVein" }, --10
			{ ["name"] = "Khorium", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_KhoriumVein" }, --11
			-- Wrath of the Lich King
			{ ["name"] = "Cobalt", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_CobaltVein" }, --12
			{ ["name"] = "Saronite", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_SaroniteVein" }, --13
			{ ["name"] = "Titanium", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_TitaniumVein" }, --14
			-- Cataclysm
			{ ["name"] = "Elementium", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_Elementium" }, -- 15
			{ ["name"] = "Obsidian", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_Obsidian" }, -- 16
			{ ["name"] = "Pyrite", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_Pyrite" }, -- 17
			-- Mists of Pandaria
			{ ["name"] = "Ghost Iron", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_GhostIron" }, -- 18
			{ ["name"] = "Kyparite", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_Kyparite" }, -- 19
			{ ["name"] = "Trillium", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_Trillium" }, -- 20
			-- Warlords of Draenor
			{ ["name"] = "Blackrock", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_CopperVein" },
			{ ["name"] = "True Iron", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_CopperVein" },
			-- Legion
			{ ["name"] = "Leystone", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_Leystone" },
			{ ["name"] = "Felslate", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_Felslate" },
			-- Battle for Azeroth
			{ ["name"] = "Monelite", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_CopperVein" },
			{ ["name"] = "Storm Silver", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_StormSilver" },
		}
	};

	-- convert saved notes from the old (pre-BFA) format into the new one  (this should be deleted once its clear that all users have switched to a new version)
	for mapname, notecollection in pairs(CT_UserMap_Notes) do
		if (CT_MapMod_OldZones[mapname]) then
			local newmap = 0 + CT_MapMod_OldZones[mapname];
			if not newmap then print(mapname); end
			-- for now, just copy the data.  (proper processing still in development)
			for i, note in pairs(notecollection) do
				local set = nil;
				if (note["set"] == 7) then
					set = "Herb";
					subset = module.NoteTypes["Herb"][note["icon"]]["name"];
				elseif (note["set"] == 8) then
					set = "Ore";
					subset = module.NoteTypes["Ore"][note["icon"]]["name"];
				else
					set = "User";
					subset = module.NoteTypes["User"][note["set"]]["name"];
				end
				local newnote =
				{
					["x"] = note["x"],
					["y"] = note["y"],
					["name"] = note["name"],
					["set"] = set,
					["subset"] = subset,
					["descript"] = note["descript"],
					["datemodified"] = "20180716",
					["version"] = "7.3.2.0",
				};
				if (not CT_MapMod_Notes[newmap]) then
					CT_MapMod_Notes[newmap] = { }; 
				end					
				tinsert(CT_MapMod_Notes[newmap],newnote);
			end
		end
	end
	wipe(CT_UserMap_Notes);
	
	-- update saved notes from more recent versions (8.0.1.4 onwards) to the current format, as required
	for mapid, notetable in pairs(CT_MapMod_Notes) do
		for i, note in ipairs(notetable) do
			if (note["set"] == "Herb" and note["subset"] == "Sea Stalk") then note["subset"] = "Sea Stalks"; end		-- 8.0.1.4 to 8.0.1.5
			if (note["set"] == "Herb" and note["subset"] == "Siren's Song") then note["subset"] = "Siren's Sting"; end	-- 8.0.1.4 to 8.0.1.5
			-- add here any future changes to the NoteTypes tables
		end
		--add here any future changes to mapid
	end

	-- load the DataProvider which has most of the horsepower
	WorldMapFrame:AddDataProvider(CreateFromMixins(CT_MapMod_DataProviderMixin));
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
	
	-- determine what types of notes to show
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

	-- Fetch and push the pins to be used for this map
	local mapid = self:GetMap():GetMapID();
	if (mapid and CT_MapMod_Notes[mapid]) then
		for i, info in ipairs(CT_MapMod_Notes[mapid]) do
			if (
				-- if user is set to always (the default)
				( (info["set"] == "User") and ((module:getOption("CT_MapMod_UserNoteDisplay") or 1) == 1) ) or
				
				-- if herb is set to always, or if herb is set to auto (the default) and the toon is an herbalist
				( (info["set"] == "Herb") and ((module:getOption("CT_MapMod_HerbNoteDisplay") or 1) == 1) and (module.isHerbalist) ) or
				( (info["set"] == "Herb") and ((module:getOption("CT_MapMod_HerbNoteDisplay") or 1) == 2) ) or
				
				-- if ore is set to always, or if ore is set to auto (the default) and the toon is a miner
				( (info["set"] == "Ore") and ((module:getOption("CT_MapMod_HerbNoteDisplay") or 1) == 1) and (module.isMiner) ) or
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
	if (self.set and self.subset) then
		for i, val in ipairs(module.NoteTypes[self.set]) do
			if (val["name"] == self.subset) then
				self.texture:SetTexture(val["icon"]);
			end
		end
	else
		self.texture:SetTexture("Interface\\RaidFrame\\UI-RaidFrame-Threat");
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
	for i, type in ipairs(module.NoteTypes[self.set]) do
		if (type["name"] == self.subset) then
			icon = type["icon"]
		end
	end
	if ( self.x > 0.5 ) then
		WorldMapTooltip:SetOwner(self, "ANCHOR_LEFT");
	else
		WorldMapTooltip:SetOwner(self, "ANCHOR_RIGHT");
	end
	WorldMapTooltip:ClearLines();
	WorldMapTooltip:AddDoubleLine("|T"..icon..":20|t " .. self.name, self.set, 0, 1, 0, 0.6, 0.6, 0.6);
	if ( self.descript ) then
		WorldMapTooltip:AddLine(self.descript, nil, nil, nil, 1);
	end
	if (not module.PinHasFocus) then  -- clicking on pins won't do anything while the edit box is open for this or another pin
		if (self.datemodified and self.version) then
			WorldMapTooltip:AddDoubleLine("Shift-Click to Edit", self.datemodified .. " (" .. self.version .. ")", 0.00, 0.50, 0.90, 0.45, 0.45, 0.45);
		else	
			WorldMapTooltip:AddLine("Shift-Click to Edit", 0, 0.5, 0.9, 1);
		end
	else
		if (self.datemodified and self.version) then
			WorldMapTooltip:AddDoubleLine(" ", self.datemodified .. " (" .. self.version .. ")", 0.00, 0.50, 0.90, 0.45, 0.45, 0.45);
		end
	end
	WorldMapTooltip:Show();
end
 
function CT_MapMod_PinMixin:OnMouseLeave()
	-- Override in your mixin, called when the mouse leaves this pin
	WorldMapTooltip:Hide();
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
	if (WorldMapFrame:IsMaximized()) then
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
	if (WorldMapFrame:IsMaximized()) then
		self:SetAlpha(Lerp( 0.3 + 0.7*((module:getOption("CT_MapMod_AlphaAmount")) or 0.75), 1.00, Saturate(1.00 * self:GetMap():GetCanvasZoomPercent())));
	else
		self:SetAlpha(Lerp( 0.0 + 1.0*((module:getOption("CT_MapMod_AlphaAmount")) or 0.75), 1.00, Saturate(1.00 * self:GetMap():GetCanvasZoomPercent())));
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
		L_UIDropDownMenu_SetText(self.notepanel.setdropdown,"User");
		L_UIDropDownMenu_SetText(self.notepanel.usersubsetdropdown,self.subset);
		L_UIDropDownMenu_SetText(self.notepanel.herbsubsetdropdown,module.NoteTypes["Herb"][1]["name"]);
		L_UIDropDownMenu_SetText(self.notepanel.oresubsetdropdown,module.NoteTypes["Ore"][1]["name"]);
	elseif (self.set == "Herb") then
		self.notepanel.usersubsetdropdown:Hide();
		self.notepanel.herbsubsetdropdown:Show();
		self.notepanel.oresubsetdropdown:Hide();
		L_UIDropDownMenu_SetText(self.notepanel.setdropdown,"Herb");
		L_UIDropDownMenu_SetText(self.notepanel.usersubsetdropdown,module.NoteTypes["User"][1]["name"]);
		L_UIDropDownMenu_SetText(self.notepanel.herbsubsetdropdown,self.subset);
		L_UIDropDownMenu_SetText(self.notepanel.oresubsetdropdown,module.NoteTypes["Ore"][1]["name"]);
	elseif (self.set == "Ore") then
		self.notepanel.usersubsetdropdown:Hide();
		self.notepanel.herbsubsetdropdown:Hide();
		self.notepanel.oresubsetdropdown:Show();
		L_UIDropDownMenu_SetText(self.notepanel.setdropdown,"Ore");
		L_UIDropDownMenu_SetText(self.notepanel.usersubsetdropdown,module.NoteTypes["User"][1]["name"]);
		L_UIDropDownMenu_SetText(self.notepanel.herbsubsetdropdown,module.NoteTypes["Herb"][1]["name"]);
		L_UIDropDownMenu_SetText(self.notepanel.oresubsetdropdown,self.subset);

	end
	L_UIDropDownMenu_SetText(self.notepanel.setdropdown,self.set);
end

-- This function is called the first time the pin is ever clicked.
-- In principal it is meant to happen when the pin is loaded for the first time, but if there are many pins then it could slow performance
-- Delaying until a pin is clicked on makes the performance hit negligible, by avoiding making a whole bunch of never-needed frames
function CT_MapMod_PinMixin:CreateNotePanel()
	if (self.notepanel) then return; end  --this shoud NEVER happen.  CreateNotePanel() is only supposed to happen once per pin!
	-- Create the note panel that is associated to this pin	
	self.notepanel = CreateFrame("FRAME",nil,WorldMapFrame.BorderFrame,"CT_MapMod_NoteTemplate");
	self.notepanel:SetScale(1.2);
	self.notepanel.pin = self;
	local textColor0 = "1.0:1.0:1.0";
	local textColor1 = "0.9:0.9:0.9";
	local textColor2 = "0.7:0.7:0.7";
	local textColor3 = "0.9:0.72:0.0";
	module:getFrame (
		{	["button#s:80:25#br:b:-42:16#v:GameMenuButtonTemplate#Okay"] = {
				["onclick"] = function(self, arg1)
					local pin = self:GetParent().pin;
					local set = L_UIDropDownMenu_GetText(self:GetParent().setdropdown);
					local subset;
					if (set == "User") then subset = L_UIDropDownMenu_GetText(self:GetParent().usersubsetdropdown); end
					if (set == "Herb") then subset = L_UIDropDownMenu_GetText(self:GetParent().herbsubsetdropdown); end
					if (set == "Ore") then subset = L_UIDropDownMenu_GetText(self:GetParent().oresubsetdropdown); end
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
			["button#s:80:25#b:b:0:16#v:GameMenuButtonTemplate#Cancel"] = {
				["onclick"] = function(self, arg1)
					local pin = self:GetParent().pin;
					self:GetParent():Hide();
					module.PinHasFocus = nil;
					L_UIDropDownMenu_SetText(pin.notepanel.setdropdown,pin.set);
					-- calling OnAcquired will reset everything user-visible to their original conditions
					pin:OnAcquired(pin.mapid, pin.i, pin.x, pin.y, pin.name, pin.descript, pin.set, pin.subset, pin.datemodified, pin.version);
				end,
			},
			["button#s:80:25#bl:b:42:16#v:GameMenuButtonTemplate#Delete"] = {
				["onclick"] = function(self, arg1)
					local pin = self:GetParent().pin;
					tremove(CT_MapMod_Notes[pin.mapid],pin.i);
					self:GetParent():Hide();
					pin:Hide();
					module.PinHasFocus = nil;
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
			["font#l:tl:15:-30#Name#" .. textColor2 .. ":l"] = { },
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
			["font#l:tl:15:-60#Type#" .. textColor2 .. ":l"] = { },
			["font#l:t:0:-60#Icon#" .. textColor2 .. ":l"] = { },
			["font#l:tl:15:-90#Description#" .. textColor2 .. ":l"] = { },
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
	self.notepanel.setdropdown = CreateFrame("Frame", nil, self.notepanel, "L_UIDropDownMenuTemplate");
	self.notepanel.usersubsetdropdown = CreateFrame("Frame", nil, self.notepanel, "L_UIDropDownMenuTemplate");
	self.notepanel.herbsubsetdropdown = CreateFrame("Frame", nil, self.notepanel, "L_UIDropDownMenuTemplate");
	self.notepanel.oresubsetdropdown = CreateFrame("Frame", nil, self.notepanel, "L_UIDropDownMenuTemplate");

	self.notepanel.setdropdown:SetPoint("LEFT",self.notepanel,"TOPLEFT",35,-60);
	L_UIDropDownMenu_SetWidth(self.notepanel.setdropdown, 90);

	self.notepanel.usersubsetdropdown:SetPoint("LEFT",self.notepanel,"TOP",30,-60);
	L_UIDropDownMenu_SetWidth(self.notepanel.usersubsetdropdown, 90);

	self.notepanel.herbsubsetdropdown:SetPoint("LEFT",self.notepanel,"TOP",30,-60);
	L_UIDropDownMenu_SetWidth(self.notepanel.herbsubsetdropdown, 90);

	self.notepanel.oresubsetdropdown:SetPoint("LEFT",self.notepanel,"TOP",30,-60);
	L_UIDropDownMenu_SetWidth(self.notepanel.oresubsetdropdown, 90);

	L_UIDropDownMenu_Initialize(self.notepanel.setdropdown, function()
		local dropdownEntry = { };

		-- properties common to all
		dropdownEntry.func = function(self)
			local dropdown = L_UIDROPDOWNMENU_OPEN_MENU or L_UIDROPDOWNMENU_INIT_MENU;
			local notepanel = dropdown:GetParent();
			local pin = notepanel.pin;
			dropdown.unapprovedValue = self.value;
			if (self.value == "User") then
				notepanel.usersubsetdropdown:Show();
				notepanel.herbsubsetdropdown:Hide();
				notepanel.oresubsetdropdown:Hide();
				pin:SetHeight(module:getOption("CT_MapMod_UserNoteSize") or 24);
				pin:SetWidth(module:getOption("CT_MapMod_UserNoteSize") or 24);
				for i, val in ipairs(module.NoteTypes["User"]) do
					if (val["name"] == L_UIDropDownMenu_GetText(notepanel.usersubsetdropdown)) then
						pin.texture:SetTexture(val["icon"]);
					end
				end
			elseif (self.value == "Herb") then
				notepanel.usersubsetdropdown:Hide();
				notepanel.herbsubsetdropdown:Show();
				notepanel.oresubsetdropdown:Hide();
				pin:SetHeight(module:getOption("CT_MapMod_HerbNoteSize") or 14);
				pin:SetWidth(module:getOption("CT_MapMod_HerbNoteSize") or 14);
				for i, val in ipairs(module.NoteTypes["Herb"]) do
					if (val["name"] == L_UIDropDownMenu_GetText(notepanel.herbsubsetdropdown)) then
						pin.texture:SetTexture(val["icon"]);
					end
				end
			else
				notepanel.usersubsetdropdown:Hide();
				notepanel.herbsubsetdropdown:Hide();
				notepanel.oresubsetdropdown:Show();
				pin:SetHeight(module:getOption("CT_MapMod_OreNoteSize") or 14);
				pin:SetWidth(module:getOption("CT_MapMod_OreNoteSize") or 14);
				for i, val in ipairs(module.NoteTypes["Ore"]) do
					if (val["name"] == L_UIDropDownMenu_GetText(notepanel.oresubsetdropdown)) then
						pin.texture:SetTexture(val["icon"]);
					end
				end
			end
			L_UIDropDownMenu_SetText(dropdown,self.value);
		end

		-- user
		dropdownEntry.value = "User";
		dropdownEntry.text = "User-Selected Icon";
		dropdownEntry.checked = nil;
		if ((self.notepanel.setdropdown.unapprovedValue or self.set) == "User") then dropdownEntry.checked = true; end
		L_UIDropDownMenu_AddButton(dropdownEntry);

		-- herb
		dropdownEntry.value = "Herb";
		dropdownEntry.text = "Herbablism Node";
		dropdownEntry.checked = nil;
		if ((self.notepanel.setdropdown.unapprovedValue or self.set) == "Herb") then dropdownEntry.checked = true; end
		L_UIDropDownMenu_AddButton(dropdownEntry);

		-- ore
		dropdownEntry.checked = nil;
		if ((self.notepanel.setdropdown.unapprovedValue or self.set) == "Ore") then dropdownEntry.checked = true; end
		dropdownEntry.value = "Ore";
		dropdownEntry.text = "Mining Ore Node";
		L_UIDropDownMenu_AddButton(dropdownEntry);
	end);
	L_UIDropDownMenu_JustifyText(self.notepanel.setdropdown, "LEFT");

	L_UIDropDownMenu_Initialize(self.notepanel.usersubsetdropdown, function()
		local dropdownEntry = { };

		-- properties common to all
		dropdownEntry.func = function(self, arg1, arg2, checked)
			local dropdown = L_UIDROPDOWNMENU_OPEN_MENU or L_UIDROPDOWNMENU_INIT_MENU
			dropdown.unapprovedValue = self.value;
			L_UIDropDownMenu_SetText(dropdown,self.value);
			local pin = dropdown:GetParent().pin;
			pin.texture:SetHeight(module:getOption("CT_MapMod_UserNoteSize") or 24);
			pin.texture:SetWidth(module:getOption("CT_MapMod_UserNoteSize") or 24);
			for i, val in ipairs(module.NoteTypes["User"]) do
				if (val["name"] == self.value) then
					pin.texture:SetTexture(val["icon"]);
				end
			end
		end

		-- properties unique to each option
		for i = 1, #module.NoteTypes["User"], 1 do
			dropdownEntry.text = module.NoteTypes["User"][i]["name"];
			dropdownEntry.value = module.NoteTypes["User"][i]["name"];
			dropdownEntry.icon = module.NoteTypes["User"][i]["icon"];
			if (dropdownEntry.value == (self.notepanel.usersubsetdropdown.unapprovedValue or self.subset)) then
				dropdownEntry.checked = true;
			elseif (not self.notepanel.usersubsetdropdown.unapprovedValue and self.set ~= "User" and i == 1) then
				dropdownEntry.checked = true;
			else
				dropdownEntry.checked = false;
			end
			L_UIDropDownMenu_AddButton(dropdownEntry);
		end
	end);
	L_UIDropDownMenu_JustifyText(self.notepanel.usersubsetdropdown, "LEFT");

	L_UIDropDownMenu_Initialize(self.notepanel.herbsubsetdropdown, function()
		local dropdownEntry = { };

		-- properties common to all
		dropdownEntry.func = function(self, arg1, arg2, checked)
			local dropdown = L_UIDROPDOWNMENU_OPEN_MENU or L_UIDROPDOWNMENU_INIT_MENU
			dropdown.unapprovedValue = self.value;
			L_UIDropDownMenu_SetText(dropdown,self.value);
			local pin = dropdown:GetParent().pin;
			pin.texture:SetHeight(module:getOption("CT_MapMod_HerbNoteSize") or 14);
			pin.texture:SetWidth(module:getOption("CT_MapMod_HerbNoteSize") or 14);
			for i, val in ipairs(module.NoteTypes["Herb"]) do
				if (val["name"] == self.value) then
					pin.texture:SetTexture(val["icon"]);
				end
			end
		end

		-- properties unique to each option
		for i = 1, #module.NoteTypes["Herb"], 1 do
			dropdownEntry.text = module.NoteTypes["Herb"][i]["name"];
			dropdownEntry.value = module.NoteTypes["Herb"][i]["name"];
			dropdownEntry.icon = module.NoteTypes["Herb"][i]["icon"];
			if (dropdownEntry.value == (self.notepanel.herbsubsetdropdown.unapprovedValue or self.subset)) then
				dropdownEntry.checked = true;
			elseif (not self.notepanel.herbsubsetdropdown.unapprovedValue and self.set ~= "Herb" and i == 1) then
				dropdownEntry.checked = true;
			else
				dropdownEntry.checked = false;
			end
			L_UIDropDownMenu_AddButton(dropdownEntry);
		end
	end);
	L_UIDropDownMenu_JustifyText(self.notepanel.herbsubsetdropdown, "LEFT");

	L_UIDropDownMenu_Initialize(self.notepanel.oresubsetdropdown, function()
		local dropdownEntry = { };

		-- properties common to all
		dropdownEntry.func = function(self, arg1, arg2, checked)
			local dropdown = L_UIDROPDOWNMENU_OPEN_MENU or L_UIDROPDOWNMENU_INIT_MENU
			dropdown.unapprovedValue = self.value;
			L_UIDropDownMenu_SetText(dropdown,self.value);
			local pin = dropdown:GetParent().pin;
			pin.texture:SetHeight(module:getOption("CT_MapMod_OreNoteSize") or 14);
			pin.texture:SetWidth(module:getOption("CT_MapMod_OreNoteSize") or 14);
			for i, val in ipairs(module.NoteTypes["Ore"]) do
				if (val["name"] == self.value) then
					pin.texture:SetTexture(val["icon"]);
				end
			end
		end

		-- properties unique to each option
		for i = 1, #module.NoteTypes["Ore"], 1 do
			dropdownEntry.text = module.NoteTypes["Ore"][i]["name"];
			dropdownEntry.value = module.NoteTypes["Ore"][i]["name"];
			dropdownEntry.icon = module.NoteTypes["Ore"][i]["icon"];
			if (dropdownEntry.value == (self.notepanel.oresubsetdropdown.unapprovedValue or self.subset)) then
				dropdownEntry.checked = true;
			elseif (not self.notepanel.oresubsetdropdown.unapprovedValue and self.set ~= "Ore" and i == 1) then
				dropdownEntry.checked = true;
			else
				dropdownEntry.checked = false;
			end
			L_UIDropDownMenu_AddButton(dropdownEntry);
		end
	end);
	L_UIDropDownMenu_JustifyText(self.notepanel.oresubsetdropdown, "LEFT");

end


--------------------------------------------
-- UI elements added to the world map title bar

do
	local newpinmousestart = nil;
	module:getFrame	(
		{
			["button#n:CT_MapMod_WhereAmIButton#s:100:20#b:b:0:3#v:UIPanelButtonTemplate#Where am I?"] = {
				["onload"] = function (self)
					self:ClearAllPoints();
					self:SetPoint("BOTTOM",WorldMapFrame.ScrollContainer,"BOTTOM",0,3);
				end,
				["onclick"] = function(self, arg1)
					WorldMapFrame:SetMapID(C_Map.GetBestMapForUnit("player"));
				end,
				["onenter"] = function(self)
					GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 30, 15);
					GameTooltip:SetText("CT: Reset the map");
					GameTooltip:Show();
				end,
				["onleave"] = function(self)
					GameTooltip:Hide();
				end
			},
			["button#n:CT_MapMod_CreateNoteButton#s:75:16#tr:tr:-125:-3#v:UIPanelButtonTemplate#New Pin"] =	{
				["onload"] = function(self)
					WorldMapFrame:AddCanvasClickHandler(function(canvas, button)
						if (not module.isCreatingNote) then return; end
						module.isCreatingNote = nil;
						if (InCombatLockdown()) then return; end
						local mapid = WorldMapFrame:GetMapID();
						local x,y = WorldMapFrame:GetNormalizedCursorPosition();
						if (not mapid or not x or not y) then return; end
						local newnote = {
							["x"] = x,
							["y"] = y,
							["name"] = "New Note",
							["set"] = "User",
							["subset"] = "Grey Note",
							["descript"] = "New note at cursor",
							["datemodified"] = date("%Y%m%d"),
							["version"] = MODULE_VERSION,
						}
						if (not CT_MapMod_Notes[mapid]) then CT_MapMod_Notes[mapid] = { }; end
						tinsert(CT_MapMod_Notes[mapid],newnote);
						WorldMapFrame:RefreshAllDataProviders();
						GameTooltip:Hide();
					end);
					self:RegisterForDrag("RightButton");
					self:HookScript("OnDragStart", function()
						if (not module.isCreatingNote) then
							newpinmousestart = GetCursorPosition(); --only interested in the X coord
							local value = module:getOption("CT_MapMod_CreateNoteButtonX") or -125;
							if (WorldMapFrame:IsMaximized()) then
								if (value < -1625) then module:setOption("CT_MapMod_CreateNoteButtonX", -1625, true, true); end
							elseif (WorldMapFrame.SidePanelToggle.OpenButton:IsShown()) then
								if (value < -535) then module:setOption("CT_MapMod_CreateNoteButtonX", -535, true, true); end
							else
								if (value < -820) then module:setOption("CT_MapMod_CreateNoteButtonX", -820, true, true); end
							end
							GameTooltip:SetText("|cFF999999Drag to set distance from RIGHT edge of map|r");
						end  
					end);
					self:HookScript("OnDragStop", function()
						if (not newpinmousestart) then return; end
						local value = module:getOption("CT_MapMod_CreateNoteButtonX") or -125;
						value = value + (GetCursorPosition() - newpinmousestart);
						if (value > -125) then value = -125; end
						if (WorldMapFrame:IsMaximized()) then
							if (value < -1625) then value = -1625; end
						elseif (WorldMapFrame.SidePanelToggle.OpenButton:IsShown()) then
							if (value < -535) then value = -535; end
						else
							if (value < -820) then value = -820; end
						end
						module:setOption("CT_MapMod_CreateNoteButtonX", value, true, true)
						newpinmousestart = nil;
						GameTooltip:Hide();
					end);
					local duration = 0;
					self:HookScript("OnUpdate", function(newself, elapsed)
						duration = duration + elapsed;
						if (duration < .1) then return; end
						duration = 0;
						local value = module:getOption("CT_MapMod_CreateNoteButtonX") or -125;
						if (newpinmousestart) then
							-- Currently dragging the frame
							value = value + (GetCursorPosition() - newpinmousestart);
							if (value > -125) then value = -125; end
							if (WorldMapFrame:IsMaximized()) then
								if (value < -1625) then value = -1625; end
							elseif (WorldMapFrame.SidePanelToggle.OpenButton:IsShown()) then
								if (value < -535) then value = -535; end
							else
								if (value < -820) then value = -820; end
							end
						elseif (not WorldMapFrame:IsMaximized() and WorldMapFrame.SidePanelToggle.OpenButton:IsShown()) then
							-- Minimized without quest frame
							if (value < -225 and value > -350) then value = -225; end
							if (value < -350 and value > -477) then value = -477; end
							if (value < -535) then value = -535; end
						elseif (not WorldMapFrame:IsMaximized() and WorldMapFrame.SidePanelToggle.CloseButton:IsShown()) then
							-- Minimized with quest frame
							if (value < -370 and value > -495) then value = -370; end
							if (value < -495 and value > -620) then value = -620; end
							if (value < -820) then value = -820; end
						else
							-- Maximized
							if (value < -760 and value > -850) then value = -760; end
							if (value < -850 and value > -940) then value = -940; end
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
							GameTooltip:SetText("CT: Click on the map!");
						end
					end
				end,
				["onenter"] = function(self)
					if (not module.isCreatingNote and not newpinmousestart) then 
						GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 30, -60);
						GameTooltip:SetText("CT: Add a new pin to the map|n|cFF999999(Right-Click to Drag)|r");
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
						GameTooltip:SetText("/ctmap|n|cFF999999(Right-Click to Drag)|r");
						GameTooltip:Show();
					end
				end,
				["onleave"] = function(self)
					if (not module.isCreatingNote and not newpinmousestart) then
						GameTooltip:Hide();
					end
				end,
				["onload"] = function(self)
					self:ClearAllPoints();
					self:SetPoint("LEFT",CT_MapMod_CreateNoteButton,"RIGHT",0,0);
					self:RegisterForDrag("RightButton");
					self:HookScript("OnDragStart", function()
						if (not module.isCreatingNote) then
							newpinmousestart = GetCursorPosition(); --only interested in the X coord
							local value = module:getOption("CT_MapMod_CreateNoteButtonX") or -125;
							if (WorldMapFrame:IsMaximized()) then
								if (value < -1625) then module:setOption("CT_MapMod_CreateNoteButtonX", -1625, true, true); end
							elseif (WorldMapFrame.SidePanelToggle.OpenButton:IsShown()) then
								if (value < -535) then module:setOption("CT_MapMod_CreateNoteButtonX", -535, true, true); end
							else
								if (value < -820) then module:setOption("CT_MapMod_CreateNoteButtonX", -820, true, true); end
							end
							GameTooltip:SetText("|cFF999999Drag to set distance from RIGHT edge of map|r");
						end  
					end);
					self:HookScript("OnDragStop", function()
						if (not newpinmousestart) then return; end
						local value = module:getOption("CT_MapMod_CreateNoteButtonX") or -125;
						value = value + (GetCursorPosition() - newpinmousestart);
						if (value > -125) then value = -125; end
						if (WorldMapFrame:IsMaximized()) then
							if (value < -1625) then value = -1625; end
						elseif (WorldMapFrame.SidePanelToggle.OpenButton:IsShown()) then
							if (value < -535) then value = -535; end
						else
							if (value < -820) then value = -820; end
						end
						module:setOption("CT_MapMod_CreateNoteButtonX", value, true, true)
						newpinmousestart = nil;
						GameTooltip:Hide();
					end);
				end
			},
		["frame#n:CT_MapMod_px#s:40:16#bl:b:-140:0"] = { 
				["onload"] = function(self)
					module.px = self
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
		["frame#n:CT_MapMod_py#s:40:16#bl:b:-100:0"] =  { 
				["onload"] = function(self)
					module.py = self
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
		["frame#n:CT_MapMod_cx#s:40:16#bl:b:70:0"] =  { 
				["onload"] = function(self)
					module.cx = self
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
		["frame#n:CT_MapMod_cy#s:40:16#bl:b:110:0"] =  { 
				["onload"] = function(self)
					module.cy = self
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
				module.px.text:SetText("x:" .. px);
				module.py.text:SetText("y:" .. py);
			else
				module.px.text:SetText("x: -");
				module.py.text:SetText("y: -");
			end
			if (mapid == C_Map.GetBestMapForUnit("player")) then
				module.px.text:SetTextColor(1,1,1,1);
				module.py.text:SetTextColor(1,1,1,1);
				if ((module:getOption("CT_MapMod_ShowMapResetButton") or 1) == 1) then
					_G["CT_MapMod_WhereAmIButton"]:Hide();
				end			
			else
				module.px.text:SetTextColor(1,1,1,.3);			
				module.py.text:SetTextColor(1,1,1,.3);
				if ((module:getOption("CT_MapMod_ShowMapResetButton") or 1) == 1) then
					_G["CT_MapMod_WhereAmIButton"]:Show();
				end				
			end
		end	
		local cx, cy = WorldMapFrame:GetNormalizedCursorPosition();
		if (cx and cy) then
			if (cx > 0 and cx < 1 and cy > 0 and cy < 1) then
				module.cx.text:SetTextColor(1,1,1,1);
				module.cy.text:SetTextColor(1,1,1,1);
			else
				module.cx.text:SetTextColor(1,1,1,.3);			
				module.cy.text:SetTextColor(1,1,1,.3);
			end
			cx = math.floor(cx*1000)/10;
			cx = math.max(math.min(cx,100),0);
			cy = math.floor(cy*1000)/10;
			cy = math.max(math.min(cy,100),0);				
			module.cx.text:SetText("x:" .. cx);
			module.cy.text:SetText("y:" .. cy);
			
		end
	end);
end


--------------------------------------------
-- Auto-Gathering

do
	local frame = CreateFrame("Frame")
	frame:RegisterEvent("UNIT_SPELLCAST_SENT")
	frame:SetScript("OnEvent", function(self, event, arg1, arg2, arg3, arg4)
		if (event == "UNIT_SPELLCAST_SENT" and arg1 == "player") then
			if (InCombatLockdown() or IsInInstance()) then return; end
			local mapid = C_Map.GetBestMapForUnit("player");
			if (not mapid) then return; end
			local x,y = C_Map.GetPlayerMapPosition(mapid,"player"):GetXY();
			if (not x or not y or (x == 0 and y == 0)) then return; end
			local herbskills = { 2366, 2368, 3570, 11993, 28695, 50300, 74519, 110413, 158745, 265819, 265821, 265823, 265825, 265827, 265829, 265831, 265834, 265835 }
			local oreskills = { 2575, 2576, 3564, 10248, 29354, 50310, 74517, 102161, 158754, 195122, 265837, 265839, 265841, 265843, 265845, 265847, 265849, 265851, 265854 }
			if ((module:getOption("CT_MapMod_AutoGatherHerbs") or 1) == 1) then
				for i, val in ipairs(herbskills) do
					if (arg4 == val) then
						for j, type in ipairs(module.NoteTypes["Herb"]) do
							if type["name"] == arg2 then
								local istooclose = nil;
								if (not CT_MapMod_Notes[mapid]) then CT_MapMod_Notes[mapid] = { }; end
								for k, note in ipairs(CT_MapMod_Notes[mapid]) do
									if ((note["name"] == arg2) and (math.sqrt((note["x"]-x)^2+(note["y"]-y)^2)<.02)) then   --two herbs of the same kind not far apart
										istooclose = true;
									end
									if ((note["set"] == "Herb") and (math.sqrt((note["x"]-x)^2+(note["y"]-y)^2)<.01)) then 	--two herbs of different kinds very close together
										istooclose = true;
									end
									if (math.sqrt((note["x"]-x)^2+(note["y"]-y)^2)<.005) then 		--two notes of completely different kinds EXTREMELY close together
										istooclose = true;
									end
								end
								if (not istooclose) then
									local newnote = {
										["x"] = x,
										["y"] = y,
										["name"] = arg2,
										["set"] = "Herb",
										["subset"] = arg2,
										["descript"] = "",
										["datemodified"] = date("%Y%m%d"),
										["version"] = MODULE_VERSION,
				m					};
									tinsert(CT_MapMod_Notes[mapid],newnote);
								end
								return;
							end
						end
						return;
					end
				end
			end
			if ((module:getOption("CT_MapMod_AutoGatherOre") or 1) == 1) then
				for i, val in ipairs(oreskills) do
					if (arg4 == val) then
						-- Gets rid of modifiers, to determine the type of ore
						if (arg2:sub(1,5) == "Rich ") then arg2 = arg2:sub(6); end
						if (arg2:sub(-5) == " Vein") then arg2 = arg2:sub(1,-6); end
						if (arg2:sub(-8) == " Deposit") then arg2 = arg2:sub(1,-9); end
						if (arg2:sub(-5) == " Seam") then arg2 = arg2:sub(1,-6); end
						for j, type in ipairs(module.NoteTypes["Ore"]) do
							if type["name"] == arg2 then
								local istooclose = nil;
								if (not CT_MapMod_Notes[mapid]) then CT_MapMod_Notes[mapid] = { }; end
								for k, note in ipairs(CT_MapMod_Notes[mapid]) do
									if ((note["name"] == arg2) and (math.sqrt((note["x"]-x)^2+(note["y"]-y)^2)<.02)) then   --two veins of the same kind not far apart
										istooclose = true;
									end
									if ((note["set"] == "Ore") and (math.sqrt((note["x"]-x)^2+(note["y"]-y)^2)<.01)) then 	--two veins of different kinds very close together
										istooclose = true;
									end
									if (math.sqrt((note["x"]-x)^2+(note["y"]-y)^2)<.005) then 		--two notes of completely different kinds EXTREMELY close together
										istooclose = true;
									end
								end
								if (not istooclose) then
									local newnote = {
										["x"] = x,
										["y"] = y,
										["name"] = arg2,
										["set"] = "Ore",
										["subset"] = arg2,
										["descript"] = "",
										["datemodified"] = date("%Y%m%d"),
										["version"] = MODULE_VERSION,
									};
									tinsert(CT_MapMod_Notes[mapid],newnote);
								end
								return;
							end
						end
						return;
					end
				end
			end
		end
	end);
end


--------------------------------------------
-- Options handling

module.update = function(self, optName, value)
	if (optName == "init") then		
		CT_MapMod_Initialize();  -- handles things that arn't related to options
		module.px:ClearAllPoints();
		module.py:ClearAllPoints();
		module.cx:ClearAllPoints();
		module.cy:ClearAllPoints();
		local position = module:getOption("CT_MapMod_ShowPlayerCoordsOnMap") or 2;
		if (position == 1) then
			module.px:SetPoint("TOPLEFT",WorldMapFrame.BorderFrame,"TOP",-145,-3);
			module.py:SetPoint("TOPLEFT",WorldMapFrame.BorderFrame,"TOP",-105,-3);
		elseif (position == 2) then
			module.px:SetPoint("BOTTOMLEFT",WorldMapFrame.ScrollContainer,"BOTTOM",-140,3);
			module.py:SetPoint("BOTTOMLEFT",WorldMapFrame.ScrollContainer,"BOTTOM",-100,3);
		else
			module.px:Hide();
			module.py:Hide();
		end
		module.px.text:SetAllPoints();
		module.py.text:SetAllPoints();
		position = module:getOption("CT_MapMod_ShowCursorCoordsOnMap") or 2;
		if (position == 1) then
			module.cx:SetPoint("TOPLEFT",WorldMapFrame.BorderFrame,"TOP",65,-3);
			module.cy:SetPoint("TOPLEFT",WorldMapFrame.BorderFrame,"TOP",105,-3);
		elseif (position == 2) then
			module.cx:SetPoint("BOTTOMLEFT",WorldMapFrame.ScrollContainer,"BOTTOM",70,3);
			module.cy:SetPoint("BOTTOMLEFT",WorldMapFrame.ScrollContainer,"BOTTOM",110,3);
		else
			module.cx:Hide();
			module.cy:Hide();
		end		
		module.cx.text:SetAllPoints();
		module.cy.text:SetAllPoints();

		CT_MapMod_CreateNoteButton:ClearAllPoints();
		CT_MapMod_CreateNoteButton:SetPoint("TOPRIGHT",WorldMapFrame.BorderFrame,"TOPRIGHT",module:getOption("CT_MapMod_CreateNoteButtonX") or -125,-3)
		
		local showmapresetbutton = module:getOption("CT_MapMod_ShowMapResetButton") or 1;
		if (showmapresetbutton == 3) then _G["CT_MapMod_WhereAmIButton"]:Hide(); end
		
	elseif (optName == "CT_MapMod_ShowPlayerCoordsOnMap") then
		if (not module.px or not module.py) then return; end
		module.px:ClearAllPoints();
		module.py:ClearAllPoints();
		if (value == 1) then
			module.px:Show();
			module.py:Show();
			module.px:SetPoint("TOPLEFT",WorldMapFrame.BorderFrame,"TOP",-145,-3);
			module.py:SetPoint("TOPLEFT",WorldMapFrame.BorderFrame,"TOP",-105,-3);
		elseif (value == 2) then
			module.px:Show();
			module.py:Show();
			module.px:SetPoint("BOTTOMLEFT",WorldMapFrame.ScrollContainer,"BOTTOM",-140,3);
			module.py:SetPoint("BOTTOMLEFT",WorldMapFrame.ScrollContainer,"BOTTOM",-100,3);		
		else
			module.px:Hide();
			module.py:Hide();
		end
		module.px.text:SetAllPoints();
		module.py.text:SetAllPoints();
	elseif (optName == "CT_MapMod_ShowCursorCoordsOnMap") then
		if (not module.cx or not module.cy) then return; end

		if (value == 1) then
			module.cx:Show();
			module.cy:Show();
			module.cx:ClearAllPoints();
			module.cy:ClearAllPoints();
			module.cx:SetPoint("TOPLEFT",WorldMapFrame.BorderFrame,"TOP",65,-3);
			module.cy:SetPoint("TOPLEFT",WorldMapFrame.BorderFrame,"TOP",105,-3);
		elseif (value == 2) then
			module.cx:Show();
			module.cy:Show();
			module.cx:ClearAllPoints();
			module.cy:ClearAllPoints();
			module.cx:SetPoint("BOTTOMLEFT",WorldMapFrame.ScrollContainer,"BOTTOM",60,3);
			module.cy:SetPoint("BOTTOMLEFT",WorldMapFrame.ScrollContainer,"BOTTOM",100,3);		
		else
			module.cx:Hide();
			module.cy:Hide();
		end
		module.cx.text:SetAllPoints();
		module.cy.text:SetAllPoints();
	elseif (optName == "CT_MapMod_ShowMapResetButton") then
		if (not _G["CT_MapMod_WhereAmIButton"]) then return; end
		if (value == 2) then _G["CT_MapMod_WhereAmIButton"]:Show(); end
		if (value == 3) then _G["CT_MapMod_WhereAmIButton"]:Hide(); end
	elseif (optName == "CT_MapMod_UserNoteSize"
		or optName == "CT_MapMod_HerbNoteSize"
		or optName == "CT_MapMod_OreNoteSize"
		or optName == "CT_MapMod_UserNoteDisplay"
		or optName == "CT_MapMod_HerbNoteDisplay"
		or optName == "CT_MapMod_OreNoteDisplay"
		or optName == "CT_MapMod_AlphaAmount"
	) then
		WorldMapFrame:RefreshAllDataProviders();
	end
end


--------------------------------------------
-- /ctmap options frame

-- Slash command
local function slashCommand(msg)
	module:showModuleOptions(module.name);
end

module:setSlashCmd(slashCommand, "/ctmapmod", "/ctmap", "/mapmod");


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
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#Tips");
		optionsAddObject( -2, 3*14, "font#t:0:%y#s:0:%s#l:13:0#r#You can use /ctmap, /ctmapmod, or /mapmod to open this options window directly.#" .. textColor2 .. ":l");
		optionsAddObject( -5, 3*14, "font#t:0:%y#s:0:%s#l:13:0#r#To access most of the options for CT_MapMod, open the game's World Map and click on the 'Notes' button.#" .. textColor2 .. ":l");
		
		
		optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#Add Features to World Map");
		
		optionsAddObject(-5,   50, "font#t:0:%y#s:0:%s#l:13:0#r#Coordinates show where you are on the map, and where your mouse cursor is#" .. textColor2 .. ":l");
		optionsAddObject(-5,   14, "font#t:0:%y#s:0:%s#l:13:0#r#Show player coordinates#" .. textColor1 .. ":l");
		optionsAddObject(-5,   24, "dropdown#tl:5:%y#s:150:20#o:CT_MapMod_ShowPlayerCoordsOnMap:2#n:CT_MapMod_ShowPlayerCoordsOnMap#At Top#At Bottom#Disabled");
		optionsAddObject(-5,   14, "font#t:0:%y#s:0:%s#l:13:0#r#Show cursor coordinates#" .. textColor1 .. ":l");
		optionsAddObject(-5,   24, "dropdown#tl:5:%y#s:150:20#o:CT_MapMod_ShowCursorCoordsOnMap:2#n:CT_MapMod_ShowCursorCoordsOnMap#At Top#At Bottom#Disabled");
		
		optionsAddObject(-10,  50, "font#t:0:%y#s:0:%s#l:13:0#r#The \"where am I?\" button resets the map to your current zone.  Auto: show when map on wrong zone#" .. textColor2 .. ":l");
		optionsAddObject(-5,   14, "font#t:0:%y#s:0:%s#l:13:0#r#Show map reset button#" .. textColor1 .. ":l");
		optionsAddObject(-5,   24, "dropdown#tl:5:%y#s:150:20#o:CT_MapMod_ShowMapResetButton#n:CT_MapMod_ShowMapResetButton#Auto#Always#Disabled");
		
		
		optionsAddObject(-20,  17, "font#tl:5:%y#v:GameFontNormalLarge#Create and Display Pins");
		
		optionsAddObject(-5,   50, "font#t:0:%y#s:0:%s#l:13:0#r#Identify points of interest on the map with custom icons#" .. textColor2 .. ":l");
		optionsAddObject(-5,   14, "font#t:0:%y#s:0:%s#l:13:0#r#Show custom user notes#" .. textColor1 .. ":l");
		optionsAddObject(-5,   24, "dropdown#tl:5:%y#s:150:20#o:CT_MapMod_UserNoteDisplay#n:CT_MapMod_UserNoteDisplay#Always#Disabled");
		optionsAddObject(-5,    8, "font#t:0:%y#s:0:%s#l:13:0#r#Custom note size#" .. textColor1 .. ":l");
		optionsAddFrame(-5,    28, "slider#tl:24:%y#s:169:15#o:CT_MapMod_UserNoteSize:24##10:26:0.5");
		
		optionsAddObject(-5,   50, "font#t:0:%y#s:0:%s#l:13:0#r#Identify herbalism and mining nodes.\nAuto: show if toon has the profession#" .. textColor2 .. ":l");
		optionsAddObject(-5,   14, "font#t:0:%y#s:0:%s#l:13:0#r#Show herbalism notes#" .. textColor1 .. ":l");
		optionsAddObject(-5,   24, "dropdown#tl:5:%y#s:150:20#o:CT_MapMod_HerbNoteDisplay#n:CT_MapMod_HerbNoteDisplay#Auto#Always#Disabled");
		optionsAddObject(-5,    8, "font#t:0:%y#s:0:%s#l:13:0#r#Herbalism note size#" .. textColor1 .. ":l");
		optionsAddFrame(-5,    28, "slider#tl:24:%y#s:169:15#o:CT_MapMod_HerbNoteSize:14##10:26:0.5");
		optionsAddObject(-5,   14, "font#t:0:%y#s:0:%s#l:13:0#r#Show mining notes#" .. textColor1 .. ":l");
		optionsAddObject(-5,   24, "dropdown#tl:5:%y#s:150:20#o:CT_MapMod_OreNoteDisplay#n:CT_MapMod_OreNoteDisplay#Auto#Always#Disabled");
		optionsAddObject(-5,    8, "font#t:0:%y#s:0:%s#l:13:0#r#Mining note size#" .. textColor1 .. ":l");
		optionsAddFrame(-5,    28, "slider#tl:24:%y#s:169:15#o:CT_MapMod_OreNoteSize:14##10:26:0.5");
		
		optionsAddObject(-5,   50, "font#t:0:%y#s:0:%s#l:13:0#r#Reduce pin alpha to see other map features.\nAlpha is always 100% when zoomed in\nMore alpha = more opaque#" .. textColor2 .. ":l");
		optionsAddObject(-5,    8, "font#t:0:%y#s:0:%s#l:13:0#r#Alpha when zoomed out#" .. textColor1 .. ":l");
		optionsAddFrame(-5,    28, "slider#tl:24:%y#s:169:15#o:CT_MapMod_AlphaAmount:0.75##0.50:1.00:0.05");
		
		
		-- Reset Options
		optionsBeginFrame(-20, 0, "frame#tl:0:%y#br:tr:0:%b");
			optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#Reset Options");
			optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:CT_MapMod_resetAll#Reset options for all of your characters");
			optionsBeginFrame(   0,   30, "button#t:0:%y#s:120:%s#v:UIPanelButtonTemplate#Reset options");
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
							module:setOption("CT_MapMod_AlphaAmount",0.75,true,false);
							module:setOption("CT_MapMod_UserNoteSize",24,true,false);
							module:setOption("CT_MapMod_HerbNoteSize",14,true,false);
							module:setOption("CT_MapMod_OreNoteSize",14,true,false);
							module:setOption("CT_MapMod_UserNoteDisplay",1,true,false);
							module:setOption("CT_MapMod_HerbNoteDisplay",1,true,false);
							module:setOption("CT_MapMod_OreNoteDisplay",1,true,false);
							ConsoleExec("RELOADUI");
						end
					end
				);
			optionsEndFrame();
		optionsEndFrame();
		optionsAddObject(  0, 3*13, "font#t:0:%y#s:0:%s#l#r#Note: This will reset the options to default and then reload your UI.#" .. textColor2);
		
	optionsEndFrame();

	return "frame#all", optionsGetData();
end



--------------------------------------------
-- Legacy properties to convert from older note formats



-- This variable should be deleted some time in the future when it is certain that ALL users have upgraded to the newest version.
CT_MapMod_OldZones = {
	["4:0"]= 1, ["4:8"]= 2, ["4:10"]= 3, ["4:11"]= 4, ["4:12"]= 5, ["4:19"]= 6, ["9:0"]= 7, ["9:6"]= 8, ["9:7"]= 9,
	["11:0"]= 10, ["11:20"]= 11, ["13:0"]= 12, ["14:0"]= 13, ["16:0"]= 14, ["17:0"]= 15, ["17:18"]= 16, ["19:0"]= 17, ["20:0"]= 18, ["20:13"]= 19,
	["20:25"]= 20, ["21:0"]= 21, ["22:0"]= 22, ["23:0"]= 23, ["23:20"]= 24, ["24:0"]= 25, ["26:0"]= 26, ["27:0"]= 27, ["27:6"]= 28, ["27:7"]= 29,
	["27:10"]= 30, ["27:11"]= 31, ["28:0"]= 32, ["28:14"]= 33, ["28:15"]= 34, ["28:16"]= 35, ["29:0"]= 36, ["30:0"]= 37, ["30:1"]= 38, ["30:2"]= 39,
	["30:19"]= 40, ["30:21"]= 41, ["32:0"]= 42, ["32:22"]= 43, ["32:23"]= 44, ["32:24"]= 45, ["32:27"]= 46, ["34:0"]= 47, ["35:0"]= 48, ["36:0"]= 49,
	["37:0"]= 50, ["38:0"]= 51, ["39:0"]= 52, ["39:4"]= 53, ["39:5"]= 54, ["39:17"]= 55, ["40:0"]= 56, ["41:0"]= 57, ["41:2"]= 58, ["41:3"]= 59,
	["41:4"]= 60, ["41:5"]= 61, ["42:0"]= 62, ["43:0"]= 63, ["61:0"]= 64, ["81:0"]= 65, ["101:0"]= 66, ["101:21"]= 67, ["101:22"]= 68, ["121:0"]= 69,
	["141:0"]= 70, ["161:0"]= 71, ["161:15"]= 72, ["161:16"]= 73, ["161:17"]= 74, ["161:18"]= 75, ["181:0"]= 76, ["182:0"]= 77, ["201:0"]= 78, ["201:14"]= 79,
	["241:0"]= 80, ["261:0"]= 81, ["261:13"]= 82, ["281:0"]= 83, ["301:0"]= 84, ["321:0"]= 85, ["321:1"]= 86, ["341:0"]= 87, ["362:0"]= 88, ["381:0"]= 89,
	["382:0"]= 90, ["401:0"]= 91, ["443:0"]= 92, ["461:0"]= 93, ["462:0"]= 94, ["463:0"]= 95, ["463:1"]= 96, ["464:0"]= 97, ["464:2"]= 98, ["464:3"]= 99,
	["465:0"]= 100, ["466:0"]= 101, ["467:0"]= 102, ["471:0"]= 103, ["473:0"]= 104, ["475:0"]= 105, ["476:0"]= 106, ["477:0"]= 107, ["478:0"]= 108, ["479:0"]= 109, ["480:0"]= 110,
	["481:0"]= 111, ["482:0"]= 112, ["485:0"]= 113, ["486:0"]= 114, ["488:0"]= 115, ["490:0"]= 116, ["491:0"]= 117, ["492:0"]= 118, ["493:0"]= 119,
	["495:0"]= 120, ["496:0"]= 121, ["499:0"]= 122, ["501:0"]= 123, ["502:0"]= 124, ["504:1"]= 125, ["504:2"]= 126, ["510:0"]= 127, ["512:0"]= 128, ["520:1"]= 129,
	["521:0"]= 130, ["521:1"]= 131, ["522:1"]= 132, ["523:1"]= 133, ["523:2"]= 134, ["523:3"]= 135, ["524:1"]= 136, ["524:2"]= 137, ["525:1"]= 138, ["525:2"]= 139,
	["526:1"]= 140, ["527:1"]= 141, ["528:0"]= 142, ["528:1"]= 143, ["528:2"]= 144, ["528:3"]= 145, ["528:4"]= 146, ["529:0"]= 147, ["529:1"]= 148, ["529:2"]= 149,
	["529:3"]= 150, ["529:4"]= 151, ["529:5"]= 152, ["530:0"]= 153, ["530:1"]= 154, ["531:0"]= 155, ["532:1"]= 156, ["533:1"]= 157, ["533:2"]= 158, ["533:3"]= 159,
	["534:1"]= 160, ["534:2"]= 161, ["535:1"]= 162, ["535:2"]= 163, ["535:3"]= 164, ["535:4"]= 165, ["535:5"]= 166, ["535:6"]= 167, ["536:1"]= 168, ["540:0"]= 169,
	["541:0"]= 170, ["542:1"]= 171, ["543:1"]= 172, ["543:2"]= 173, ["544:0"]= 174, ["544:1"]= 175, ["544:2"]= 176, ["544:3"]= 177, ["544:4"]= 178, ["545:0"]= 179,
	["545:1"]= 180, ["545:2"]= 181, ["545:3"]= 182, ["601:1"]= 183, ["602:0"]= 184, ["603:1"]= 185, ["604:1"]= 186, ["604:2"]= 187, ["604:3"]= 188, ["604:4"]= 189,
	["604:5"]= 190, ["604:6"]= 191, ["604:7"]= 192, ["604:8"]= 193, ["605:0"]= 194, ["605:5"]= 195, ["605:6"]= 196, ["605:7"]= 197, ["606:0"]= 198, ["607:0"]= 199,
	["609:0"]= 200, ["610:0"]= 201, ["611:0"]= 202, ["613:0"]= 203, ["614:0"]= 204, ["615:0"]= 205, ["626:0"]= 206, ["640:0"]= 207, ["640:1"]= 208, ["640:2"]= 209,
	["673:0"]= 210, ["680:1"]= 213, ["684:0"]= 217, ["685:0"]= 218, ["686:0"]= 219,
	["687:1"]= 220, ["688:1"]= 221, ["688:2"]= 222, ["688:3"]= 223, ["689:0"]= 224, ["690:1"]= 225, ["691:1"]= 226, ["691:2"]= 227, ["691:3"]= 228, ["691:4"]= 229,
	["692:1"]= 230, ["692:2"]= 231, ["696:1"]= 232, ["697:0"]= 233, ["699:0"]= 234, ["699:1"]= 235, ["699:2"]= 236, ["699:3"]= 237, ["699:4"]= 238, ["699:5"]= 239,
	["699:6"]= 240, ["700:0"]= 241, ["704:1"]= 242, ["704:2"]= 243, ["708:0"]= 244, ["709:0"]= 245, ["710:1"]= 246, ["717:0"]= 247, ["718:1"]= 248, ["720:0"]= 249,
	["721:1"]= 250, ["721:2"]= 251, ["721:3"]= 252, ["721:4"]= 253, ["721:5"]= 254, ["721:6"]= 255, ["722:1"]= 256, ["722:2"]= 257, ["723:1"]= 258, ["723:2"]= 259,
	["724:1"]= 260, ["725:1"]= 261, ["726:1"]= 262, ["727:1"]= 263, ["727:2"]= 264, ["728:1"]= 265, ["729:1"]= 266, ["730:1"]= 267, ["730:2"]= 268, ["731:1"]= 269,
	["731:2"]= 270, ["731:3"]= 271, ["732:1"]= 272, ["733:0"]= 273, ["734:0"]= 274, ["736:0"]= 275, ["737:0"]= 276, ["747:0"]= 277, ["749:1"]= 279, ["750:1"]= 280,
	["750:2"]= 281, ["752:1"]= 282, ["753:1"]= 283, ["753:2"]= 284, ["754:1"]= 285, ["754:2"]= 286, ["755:1"]= 287, ["755:2"]= 288, ["755:3"]= 289, ["755:4"]= 290,
	["756:1"]= 291, ["756:2"]= 292, ["757:1"]= 293, ["758:1"]= 294, ["758:2"]= 295, ["758:3"]= 296, ["759:1"]= 297, ["759:2"]= 298, ["759:3"]= 299, ["760:1"]= 300,
	["761:1"]= 301, ["762:1"]= 302, ["762:2"]= 303, ["762:3"]= 304, ["762:4"]= 305, ["763:1"]= 306, ["763:2"]= 307, ["763:3"]= 308, ["763:4"]= 309,
	["764:1"]= 310, ["764:2"]= 311, ["764:3"]= 312, ["764:4"]= 313, ["764:5"]= 314, ["764:6"]= 315, ["764:7"]= 316, ["765:1"]= 317, ["765:2"]= 318, ["766:1"]= 319,
	["766:2"]= 320, ["766:3"]= 321, ["767:1"]= 322, ["767:2"]= 323, ["768:1"]= 324, ["769:1"]= 325, ["772:0"]= 327, ["773:1"]= 328, ["775:0"]= 329,
	["776:1"]= 330, ["779:1"]= 331, ["780:1"]= 332, ["781:0"]= 333, ["782:1"]= 334, ["789:0"]= 335, ["789:1"]= 336, ["793:0"]= 337, ["795:0"]= 338, ["796:0"]= 339,
	["796:1"]= 340, ["796:2"]= 341, ["796:3"]= 342, ["796:4"]= 343, ["796:5"]= 344, ["796:6"]= 345, ["796:7"]= 346, ["797:1"]= 347, ["798:1"]= 348, ["798:2"]= 349,
	["799:1"]= 350, ["799:2"]= 351, ["799:3"]= 352, ["799:4"]= 353, ["799:5"]= 354, ["799:6"]= 355, ["799:7"]= 356, ["799:8"]= 357, ["799:9"]= 358, ["799:10"]= 359,
	["799:11"]= 360, ["799:12"]= 361, ["799:13"]= 362, ["799:14"]= 363, ["799:15"]= 364, ["799:16"]= 365, ["799:17"]= 366, ["800:0"]= 367, ["800:1"]= 368, ["800:2"]= 369,
	["803:1"]= 370, ["806:0"]= 371, ["806:6"]= 372, ["806:7"]= 373, ["806:15"]= 374, ["806:16"]= 375, ["807:0"]= 376, ["807:14"]= 377, ["808:0"]= 378, ["809:0"]= 379,
	["809:8"]= 380, ["809:9"]= 381, ["809:10"]= 382, ["809:11"]= 383, ["809:12"]= 384, ["809:17"]= 385, ["809:20"]= 386, ["809:21"]= 387, ["810:0"]= 388, ["810:13"]= 389,
	["811:0"]= 390, ["811:1"]= 391, ["811:2"]= 392, ["811:3"]= 393, ["811:4"]= 394, ["811:18"]= 395, ["811:19"]= 396, ["813:0"]= 397, ["816:0"]= 398, ["819:0"]= 399,
	["819:1"]= 400, ["820:0"]= 401, ["820:1"]= 402, ["820:2"]= 403, ["820:3"]= 404, ["820:4"]= 405, ["820:5"]= 406, ["823:0"]= 407, ["823:1"]= 408, ["824:0"]= 409,
	["824:1"]= 410, ["824:2"]= 411, ["824:3"]= 412, ["824:4"]= 413, ["824:5"]= 414, ["824:6"]= 415, ["851:0"]= 416, ["856:0"]= 417, ["857:0"]= 418, ["857:1"]= 419,
	["857:2"]= 420, ["857:3"]= 421, ["858:0"]= 422, ["860:1"]= 423, ["862:0"]= 424, ["864:0"]= 425, ["864:3"]= 426, ["866:0"]= 427, ["866:9"]= 428, ["867:1"]= 429,
	["867:2"]= 430, ["871:1"]= 431, ["871:2"]= 432, ["873:0"]= 433, ["873:5"]= 434, ["874:1"]= 435, ["874:2"]= 436, ["875:1"]= 437, ["875:2"]= 438, ["876:1"]= 439,
	["876:2"]= 440, ["876:3"]= 441, ["876:4"]= 442, ["877:0"]= 443, ["877:1"]= 444, ["877:2"]= 445, ["877:3"]= 446, ["878:0"]= 447, ["880:0"]= 448, ["881:0"]= 449,
	["882:0"]= 450, ["883:0"]= 451, ["884:0"]= 452, ["885:1"]= 453, ["885:2"]= 454, ["885:3"]= 455, ["886:0"]= 456, ["887:0"]= 457, ["887:1"]= 458, ["887:2"]= 459,
	["888:0"]= 460, ["889:0"]= 461, ["890:0"]= 462, ["891:0"]= 463, ["891:9"]= 464, ["892:0"]= 465, ["892:12"]= 466, ["893:0"]= 467, ["894:0"]= 468, ["895:0"]= 469,
	["895:8"]= 470, ["896:1"]= 471, ["896:2"]= 472, ["896:3"]= 473, ["897:1"]= 474, ["897:2"]= 475, ["898:1"]= 476, ["898:2"]= 477, ["898:3"]= 478, ["898:4"]= 479,
	["899:1"]= 480, ["900:1"]= 481, ["900:2"]= 482, ["906:0"]= 483, ["911:0"]= 486, ["912:0"]= 487, ["914:0"]= 488, ["914:1"]= 489, ["919:0"]= 490, ["919:1"]= 491,
	["919:2"]= 492, ["919:3"]= 493, ["919:4"]= 494, ["919:5"]= 495, ["919:6"]= 496, ["919:7"]= 497, ["920:0"]= 498, ["922:1"]= 499,
	["922:2"]= 500, ["924:1"]= 501, ["924:2"]= 502, ["925:1"]= 503, ["928:0"]= 504, ["928:1"]= 505, ["928:2"]= 506, ["929:0"]= 507, ["930:1"]= 508, ["930:2"]= 509,
	["930:3"]= 510, ["930:4"]= 511, ["930:5"]= 512, ["930:6"]= 513, ["930:7"]= 514, ["930:8"]= 515, ["933:0"]= 516, ["933:1"]= 517, ["934:1"]= 518, ["935:0"]= 519,
	["937:0"]= 520, ["937:1"]= 521, ["938:1"]= 522, ["939:0"]= 523, ["940:0"]= 524, ["941:0"]= 525, ["941:1"]= 526, ["941:2"]= 527, ["941:3"]= 528, ["941:4"]= 529,
	["941:6"]= 530, ["941:7"]= 531, ["941:8"]= 532, ["941:9"]= 533, ["945:0"]= 534, ["946:0"]= 535, ["946:13"]= 536, ["946:14"]= 537, ["946:30"]= 538, ["947:0"]= 539,
	["947:15"]= 540, ["947:22"]= 541, ["948:0"]= 542, ["949:0"]= 543, ["949:16"]= 544, ["949:17"]= 545, ["949:18"]= 546, ["949:19"]= 547, ["949:20"]= 548, ["949:21"]= 549,
	["950:0"]= 550, ["950:10"]= 551, ["950:11"]= 552, ["950:12"]= 553, ["951:0"]= 554, ["951:22"]= 555, ["953:0"]= 556, ["953:1"]= 557, ["953:2"]= 558, ["953:3"]= 559,
	["953:4"]= 560, ["953:5"]= 561, ["953:6"]= 562, ["953:7"]= 563, ["953:8"]= 564, ["953:9"]= 565, ["953:10"]= 566, ["953:11"]= 567, ["953:12"]= 568, ["953:13"]= 569,
	["953:14"]= 570, ["955:0"]= 571, ["962:0"]= 572, ["964:1"]= 573, ["969:1"]= 574, ["969:2"]= 575, ["969:3"]= 576, ["970:0"]= 577, ["970:1"]= 578, ["971:23"]= 579,
	["971:24"]= 580, ["971:25"]= 581, ["973:0"]= 582, ["976:26"]= 585, ["976:27"]= 586, ["976:28"]= 587, ["978:0"]= 588, ["978:29"]= 589,
	["980:0"]= 590, ["983:0"]= 592, ["984:1"]= 593, ["986:0"]= 594, ["987:1"]= 595, ["988:1"]= 596, ["988:2"]= 597, ["988:3"]= 598, ["988:4"]= 599,
	["988:5"]= 600, ["989:1"]= 601, ["989:2"]= 602, ["993:1"]= 606, ["993:2"]= 607, ["993:3"]= 608, ["993:4"]= 609,
	["994:0"]= 610, ["994:1"]= 611, ["994:2"]= 612, ["994:3"]= 613, ["994:4"]= 614, ["994:5"]= 615, ["995:1"]= 616, ["995:2"]= 617, ["995:3"]= 618, ["1007:0"]= 619,
	["1008:0"]= 620, ["1008:1"]= 621, ["1009:0"]= 622, ["1010:0"]= 623, ["1011:0"]= 624, ["1014:0"]= 625, ["1014:4"]= 626, ["1014:10"]= 627, ["1014:11"]= 628, ["1014:12"]= 629,
	["1015:0"]= 630, ["1015:17"]= 631, ["1015:18"]= 632, ["1015:19"]= 633, ["1017:0"]= 634, ["1017:1"]= 635, ["1017:9"]= 636, ["1017:25"]= 637, ["1017:26"]= 638, ["1017:27"]= 639,
	["1017:28"]= 640, ["1018:0"]= 641, ["1018:13"]= 642, ["1018:14"]= 643, ["1018:15"]= 644, ["1020:0"]= 645, ["1021:0"]= 646, ["1021:1"]= 647, ["1021:2"]= 648, ["1022:0"]= 649,
	["1024:0"]= 650, ["1024:5"]= 651, ["1024:6"]= 652, ["1024:8"]= 653, ["1024:16"]= 654, ["1024:20"]= 655, ["1024:21"]= 656, ["1024:29"]= 657, ["1024:30"]= 658, ["1024:31"]= 659,
	["1024:40"]= 660, ["1026:0"]= 661, ["1026:1"]= 662, ["1026:2"]= 663, ["1026:3"]= 664, ["1026:4"]= 665, ["1026:5"]= 666, ["1026:6"]= 667, ["1026:7"]= 668, ["1026:8"]= 669,
	["1026:9"]= 670, ["1027:0"]= 671, ["1028:0"]= 672, ["1028:1"]= 673, ["1028:2"]= 674, ["1028:3"]= 675, ["1031:0"]= 676, ["1032:1"]= 677, ["1032:2"]= 678, ["1032:3"]= 679,
	["1033:0"]= 680, ["1033:22"]= 681, ["1033:23"]= 682, ["1033:24"]= 683, ["1033:32"]= 684, ["1033:33"]= 685, ["1033:34"]= 686, ["1033:35"]= 687, ["1033:36"]= 688, ["1033:37"]= 689,
	["1033:38"]= 690, ["1033:39"]= 691, ["1033:41"]= 692, ["1033:42"]= 693, ["1034:0"]= 694, ["1035:1"]= 695, ["1037:0"]= 696, ["1038:0"]= 697, ["1039:1"]= 698, ["1039:2"]= 699,
	["1039:3"]= 700, ["1039:4"]= 701, ["1040:1"]= 702, ["1041:0"]= 703, ["1041:1"]= 704, ["1041:2"]= 705, ["1042:0"]= 706, ["1042:1"]= 707, ["1042:2"]= 708, ["1044:0"]= 709,
	["1045:1"]= 710, ["1045:2"]= 711, ["1045:3"]= 712, ["1046:0"]= 713, ["1047:0"]= 714, ["1048:0"]= 715, ["1049:1"]= 716, ["1050:0"]= 717, ["1051:0"]= 718, ["1052:0"]= 719,
	["1052:1"]= 720, ["1052:2"]= 721, ["1054:1"]= 723, ["1056:0"]= 725, ["1057:0"]= 726, ["1059:0"]= 728, ["1060:1"]= 729,
	["1065:0"]= 731, ["1066:1"]= 732, ["1067:0"]= 733, ["1068:1"]= 734, ["1068:2"]= 735, ["1069:1"]= 736, ["1070:1"]= 737, ["1071:0"]= 738, ["1072:0"]= 739,
	["1073:1"]= 740, ["1073:2"]= 741, ["1075:1"]= 742, ["1075:2"]= 743, ["1076:1"]= 744, ["1076:2"]= 745, ["1076:3"]= 746, ["1077:0"]= 747, ["1078:0"]= 748, ["1079:1"]= 749,
	["1080:0"]= 750, ["1081:1"]= 751, ["1081:2"]= 752, ["1081:3"]= 753, ["1081:4"]= 754, ["1081:5"]= 755, ["1081:6"]= 756, ["1082:0"]= 757, ["1084:0"]= 758, ["1085:1"]= 759,
	["1086:0"]= 760, ["1087:0"]= 761, ["1087:1"]= 762, ["1087:2"]= 763, ["1088:1"]= 764, ["1088:2"]= 765, ["1088:3"]= 766, ["1088:4"]= 767, ["1088:5"]= 768, ["1088:6"]= 769,
	["1088:7"]= 770, ["1088:8"]= 771, ["1088:9"]= 772, ["1090:0"]= 773, ["1090:1"]= 774, ["1091:0"]= 775, ["1092:0"]= 776, ["1094:1"]= 777, ["1094:2"]= 778, ["1094:3"]= 779, 
	["1094:4"]= 780, ["1094:5"]= 781, ["1094:6"]= 782, ["1094:7"]= 783, ["1094:8"]= 784, ["1094:9"]= 785, ["1094:10"]= 786, ["1094:11"]= 787, ["1094:12"]= 788, ["1094:13"]= 789,
	["1096:0"]= 790, ["1097:1"]= 791, ["1097:2"]= 792, ["1099:0"]= 793, ["1100:1"]= 794, ["1100:2"]= 795, ["1100:3"]= 796, ["1100:4"]= 797, ["1102:1"]= 798, ["1104:0"]= 799,
	["1104:1"]= 800, ["1104:2"]= 801, ["1104:3"]= 802, ["1104:4"]= 803, ["1105:1"]= 804, ["1105:2"]= 805, ["1114:0"]= 806, ["1114:1"]= 807, ["1114:2"]= 808, ["1115:1"]= 809,
	["1115:2"]= 810, ["1115:3"]= 811, ["1115:4"]= 812, ["1115:5"]= 813, ["1115:6"]= 814, ["1115:7"]= 815, ["1115:8"]= 816, ["1115:9"]= 817, ["1115:10"]= 818, ["1115:11"]= 819,
	["1115:12"]= 820, ["1115:13"]= 821, ["1115:14"]= 822, ["1116:0"]= 823, ["1126:0"]= 824, ["1127:1"]= 825, ["1129:1"]= 826, ["1130:1"]= 827, ["1131:1"]= 828, ["1132:1"]= 829,
	["1135:0"]= 830, ["1135:1"]= 831, ["1135:2"]= 832, ["1135:7"]= 833, ["1136:0"]= 834, ["1137:1"]= 835, ["1137:2"]= 836, ["1139:0"]= 837, ["1140:0"]= 838, ["1142:1"]= 839,
	["1143:1"]= 840, ["1143:2"]= 841, ["1143:3"]= 842, ["1144:0"]= 843, ["1145:0"]= 844, ["1146:1"]= 845, ["1146:2"]= 846, ["1146:3"]= 847, ["1146:4"]= 848, ["1146:5"]= 849,
	["1147:1"]= 850, ["1147:2"]= 851, ["1147:3"]= 852, ["1147:4"]= 853, ["1147:5"]= 854, ["1147:6"]= 855, ["1147:7"]= 856, ["1148:1"]= 857, ["1149:0"]= 858, ["1150:0"]= 859,
	["1151:0"]= 860, ["1152:0"]= 861, ["1153:0"]= 862, ["1154:0"]= 863, ["1155:0"]= 864, ["1156:1"]= 865, ["1156:2"]= 866, ["1157:1"]= 867, ["1158:1"]= 868, ["1159:1"]= 869,
	["1159:2"]= 870, ["1160:0"]= 871, ["1161:0"]= 872, ["1161:1"]= 873, ["1161:2"]= 874, ["1162:0"]= 875, ["1163:0"]= 876, ["1164:0"]= 877, ["1165:0"]= 878, ["1165:1"]= 879, 
	["1165:2"]= 880, ["1166:1"]= 881, ["1170:0"]= 882, ["1170:3"]= 883, ["1170:4"]= 884, ["1171:0"]= 885, ["1171:5"]= 886, ["1171:6"]= 887, ["1172:1"]= 888, ["1173:1"]= 889,
	["1173:2"]= 890, ["1174:0"]= 891, ["1174:1"]= 892, ["1174:2"]= 893, ["1174:3"]= 894, ["1175:0"]= 895, ["1176:0"]= 896, ["1177:0"]= 897, ["1177:1"]= 898, ["1177:2"]= 899,
	["1177:3"]= 900, ["1177:4"]= 901, ["1177:5"]= 902, ["1178:0"]= 903, ["1183:0"]= 904, ["1184:0"]= 905, ["1185:0"]= 906, ["1186:0"]= 907, ["1187:0"]= 908, ["1188:0"]= 909, 
	["1188:1"]= 910, ["1188:2"]= 911, ["1188:3"]= 912, ["1188:4"]= 913, ["1188:5"]= 914, ["1188:6"]= 915, ["1188:7"]= 916, ["1188:8"]= 917, ["1188:9"]= 918, ["1188:10"]= 919,
	["1188:11"]= 920, ["1190:0"]= 921, ["1191:0"]= 922, ["1192:0"]= 923, ["1193:0"]= 924, ["1194:0"]= 925, ["1195:0"]= 926, ["1196:0"]= 927, ["1197:0"]= 928, ["1198:0"]= 929,
	["1199:0"]= 930, ["1200:0"]= 931, ["1201:0"]= 932, ["1202:0"]= 933, ["1204:1"]= 934, ["1204:2"]= 935, ["1205:0"]= 936, ["1210:0"]= 938, ["1211:0"]= 939,
	["1212:1"]= 940, ["1212:2"]= 941, ["1213:0"]= 942, ["1214:0"]= 943,
	["1215:0"]= 971, ["1216:0"]= 972, ["1217:1"]= 973, ["1219:0"]= 974, ["1219:1"]= 975, ["1219:2"]= 976, ["1219:3"]= 977, ["1219:4"]= 978, ["1219:5"]= 979,
	["1219:6"]= 980, ["1220:0"]= 981, ["1184:0"]= 994, ["382:0"]= 998,
}