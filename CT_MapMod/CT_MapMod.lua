
------------------------------------------------
--                 CT_MapMod                  --
--                                            --
-- Simple addon that allows the user to add   --
-- notes and gathered nodes to the world map. --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
--					      --
-- Original credits to Cide and TS            --
-- Maintained by Resike from 2014 to 2017     --
-- Rebuilt by Dahk Celes (ddc) in 2018        --
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

CT_MapMod_Notes = {}; 		-- Persistent storage of the actual pins


local function CT_MapMod_Initialize()		-- called via module.update("init") from CT_Library
	-- configure the hardcoded variables
	module.NoteTypes =
	{
		["User"] =
		{
			{ ["name"] = "Grey Note", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Skin\\GreyNote" }, --1
			{ ["name"] = "Blue Shield", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Skin\\BlueShield" }, --2
			{ ["name"] = "Red Dot", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Skin\\RedDot" }, --3
			{ ["name"] = "White Circle", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Skin\\WhiteCircle" }, --4
			{ ["name"] = "Green Square", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Skin\\GreenSquare" }, --5
			{ ["name"] = "Red Cross", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Skin\\RedCross" }, --6
			{ ["name"] = "Diamond", ["icon"] = "Interface\\RaidFrame\\UI-RaidFrame-Threat" } -- added in 8.0
		},			
		["Herb"] =
		{
			["Classic"] = 
			{
				{ ["name"] = "Bruiseweed", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed", ["id"] = 2453 }, -- 1
				{ ["name"] = "Arthas' Tears", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_ArthasTears" }, -- 2
				{ ["name"] = "Black Lotus", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_BlackLotus", ["id"] = 13468 }, -- 3
				{ ["name"] = "Blindweed", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Blindweed", ["id"] = 8839 }, -- 4
				{ ["name"] = "Briarthorn", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Briarthorn", ["id"] = 2450 }, -- 5
				{ ["name"] = "Dreamfoil", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Dreamfoil", ["id"] = 13463 }, -- 6
				{ ["name"] = "Earthroot", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Earthroot", ["id"] = 2449 }, -- 7
				{ ["name"] = "Fadeleaf", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Fadeleaf", ["id"] = 3818 }, -- 8
				{ ["name"] = "Firebloom", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Firebloom", ["id"] = 4625 }, -- 9
				{ ["name"] = "Ghost Mushroom", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_GhostMushroom", ["id"] = 8845 }, -- 10
				{ ["name"] = "Golden Sansam", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_GoldenSansam", ["id"] = 13464 }, -- 11
				{ ["name"] = "Goldthorn", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Goldthorn", ["id"] = 3821 }, -- 12
				{ ["name"] = "Grave Moss", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_GraveMoss", ["id"] = 3369 }, -- 13
				{ ["name"] = "Gromsblood", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Gromsblood", ["id"] = 8846 }, -- 14
				{ ["name"] = "Icecap", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Icecap", ["id"] = 13467 }, -- 15
				{ ["name"] = "Khadgars Whisker", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_KhadgarsWhisker", ["id"] = 3358 }, -- 16
				{ ["name"] = "Kingsblood", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Kingsblood", ["id"] = 3356 }, -- 17
				{ ["name"] = "Liferoot", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Liferoot", ["id"] = 3357 }, -- 18
				{ ["name"] = "Mageroyal", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Mageroyal", ["id"] = 785 }, -- 19
				{ ["name"] = "Mountain Silversage", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_MountainSilversage", ["id"] = 13465 }, -- 20
				{ ["name"] = "Peacebloom", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Peacebloom", ["id"] = 2447 }, -- 21
				{ ["name"] = "Plaguebloom", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Plaguebloom" }, -- 22
				{ ["name"] = "Purple Lotus", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_PurpleLotus", ["id"] = 8831 }, -- 23
				{ ["name"] = "Silverleaf", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Silverleaf", ["id"] = 765 }, -- 24
				{ ["name"] = "Stranglekelp", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Stranglekelp", ["id"] = 3820 }, -- 25
				{ ["name"] = "Sungrass", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Sungrass", ["id"] = 8838 }, -- 26
				{ ["name"] = "Swiftthistle", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Swiftthistle" }, -- 27
				{ ["name"] = "Wild Steelbloom", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_WildSteelbloom", ["id"] = 3355 }, -- 28
				{ ["name"] = "Wintersbite", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Wintersbite" }, -- 29
				{ ["name"] = "Dreaming Glory", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_DreamingGlory" }, -- 30
			},
			["Early Expansions"] = 
			{
				-- Burning Crusade
				{ ["name"] = "Felweed", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Felweed" },
				{ ["name"] = "Flame Cap", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_FlameCap" },
				{ ["name"] = "Mana Thistle", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_ManaThistle" },
				{ ["name"] = "Netherbloom", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Netherbloom" },
				{ ["name"] = "Netherdust Bush", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_NetherdustBush" },
				{ ["name"] = "Nightmare Vine", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_NightmareVine" },
				{ ["name"] = "Ragveil", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Ragveil" },
				{ ["name"] = "Terocone", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Terocone" },
				-- Wrath of the Lich King
				{ ["name"] = "Adders Tongue", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_AddersTongue" },
				{ ["name"] = "Frost Lotus", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_FrostLotus" },
				{ ["name"] = "Goldclover", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Goldclover" },
				{ ["name"] = "Icethorn", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Icethorn" },
				{ ["name"] = "Lichbloom", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Lichbloom" },
				{ ["name"] = "Talandra's Rose", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_TalandrasRose" },
				{ ["name"] = "Tiger Lily", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_TigerLily" },
				{ ["name"] = "Frozen Herb", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_FrozenHerb" },
				-- Cataclysm
				{ ["name"] = "Cinderbloom", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed" },
				{ ["name"] = "Azshara's Veil", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed" },
				{ ["name"] = "Stormvein", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed" },
				{ ["name"] = "Heartblossom", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed" },
				{ ["name"] = "Whiptail", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed" },
				{ ["name"] = "Twilight Jasmine", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed" },
			},
			["Recent Expansions"] =
			{
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
				{ ["name"] = "Anchor Weed", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_AnchorWeed", ["ignoregather"] = true },  --ignoregather added in 8.1.5.2
				{ ["name"] = "Riverbud", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Riverbud" },
				{ ["name"] = "Sea Stalks", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_SeaStalk" },
				{ ["name"] = "Siren's Sting", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed" },
				{ ["name"] = "Star Moss", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_StarMoss" },
				{ ["name"] = "Winter's Kiss", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_WintersKiss" },
				{ ["name"] = "Zin'anthid", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Zinanthid" },
			},
		},
		["Ore"] =
		{ 
			["Classic"] = 
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
			},
			["Expansions"] = 
			{
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
				{ ["name"] = "Osmenite", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_Elementium" },
			},
		},
	};
	
	-- allows pins to appear at flight masters if there is a corresponding world-map that looks identical
	-- key: GetTaxiMapID() when at a flight master using FlightMapFrame
	-- val: GetMapID() when looking at a continent in the WorldMapFrame
	module.FlightMaps = 
	{
		 [990] = 552, -- Draenor  -- never used, because WoD has the TaxiRouteFrame instead of FlightMapFrame
		[1011] = 875, -- Zandalar
		[1014] = 876, -- Kul Tiras
		[1208] =  13, -- Eastern Kingdoms
		[1209] =  12, -- Kalimdor
		[1384] = 113, -- Northrend
		[1467] = 101, -- Outland
	};

	-- Convert notes from older versions of the addon to the most recent (using function defined near bottom)
	CT_MapMod_ConvertOldNotes();

	-- load the DataProvider which has most of the horsepower
	WorldMapFrame:AddDataProvider(CreateFromMixins(CT_MapMod_DataProviderMixin));
	
	-- flight path map in the retail version only
	if (module:getGameVersion() == CT_GAME_VERSION_RETAIL) then
		if (not FlightMapFrame) then FlightMap_LoadUI(); end
		FlightMapFrame:AddDataProvider(CreateFromMixins(CT_MapMod_DataProviderMixin));
	end
	
	-- add UI elements to the map
	CT_MapMod_AddUIElements();
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
		for key, val in pairs(module.FlightMaps) do   --continent pins will appear in corresponding flight maps
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
			for key, expansion in pairs(module.NoteTypes[self.set]) do
				for j, val in ipairs(expansion) do
					if (val["name"] == self.subset) then
						self.texture:SetTexture(val["icon"]);
					end
				end
			end
		else
			-- presumably self.set == "User"
			for i, val in ipairs(module.NoteTypes[self.set]) do
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
		for key, expansion in pairs(module.NoteTypes[self.set]) do
			for i, type in ipairs(expansion) do
				if (type["name"] == self.subset) then
					icon = type["icon"]
				end
			end
		end
	else
		-- presumably self.set == "User"
		for i, type in ipairs(module.NoteTypes[self.set]) do
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
		UIDropDownMenu_SetText(self.notepanel.herbsubsetdropdown,module.NoteTypes["Herb"]["Classic"][1]["name"]);
		UIDropDownMenu_SetText(self.notepanel.oresubsetdropdown,module.NoteTypes["Ore"]["Classic"][1]["name"]);
	elseif (self.set == "Herb") then
		self.notepanel.usersubsetdropdown:Hide();
		self.notepanel.herbsubsetdropdown:Show();
		self.notepanel.oresubsetdropdown:Hide();
		UIDropDownMenu_SetText(self.notepanel.setdropdown,"Herb");
		UIDropDownMenu_SetText(self.notepanel.usersubsetdropdown,module.NoteTypes["User"][1]["name"]);
		UIDropDownMenu_SetText(self.notepanel.herbsubsetdropdown,self.subset);
		UIDropDownMenu_SetText(self.notepanel.oresubsetdropdown,module.NoteTypes["Ore"]["Classic"][1]["name"]);
	elseif (self.set == "Ore") then
		self.notepanel.usersubsetdropdown:Hide();
		self.notepanel.herbsubsetdropdown:Hide();
		self.notepanel.oresubsetdropdown:Show();
		UIDropDownMenu_SetText(self.notepanel.setdropdown,"Ore");
		UIDropDownMenu_SetText(self.notepanel.usersubsetdropdown,module.NoteTypes["User"][1]["name"]);
		UIDropDownMenu_SetText(self.notepanel.herbsubsetdropdown,module.NoteTypes["Herb"]["Classic"][1]["name"]);
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
					if (set == "User") then subset = UIDropDownMenu_GetText(self:GetParent().usersubsetdropdown); end
					if (set == "Herb") then subset = UIDropDownMenu_GetText(self:GetParent().herbsubsetdropdown); end
					if (set == "Ore") then subset = UIDropDownMenu_GetText(self:GetParent().oresubsetdropdown); end
					if (not subset) then return; end  -- this could happen if the user didn't pick an icon
					for key, val in pairs(module.text) do
						if (subset == val) then subset = key; end  -- Always revert back to enUS before saving to the database
					end
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
				for i, val in ipairs(module.NoteTypes["User"]) do
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
				for key, expansion in pairs(module.NoteTypes["Herb"]) do
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
				for key, expansion in pairs(module.NoteTypes["Ore"]) do
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
		dropdownEntry.func = function(self, arg1, arg2, checked)
			local dropdown = UIDROPDOWNMENU_OPEN_MENU or UIDROPDOWNMENU_INIT_MENU
			dropdown.unapprovedValue = self.value;
			UIDropDownMenu_SetText(dropdown,self.value);
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
		for i, type in ipairs(module.NoteTypes["User"]) do
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
		dropdownEntry.func = function(self, arg1, arg2, checked)
			local dropdown = UIDROPDOWNMENU_OPEN_MENU or UIDROPDOWNMENU_INIT_MENU
			dropdown.unapprovedValue = self.value;
			UIDropDownMenu_SetText(dropdown,self.value);
			local pin = dropdown:GetParent().pin;
			pin.texture:SetHeight(module:getOption("CT_MapMod_HerbNoteSize") or 14);
			pin.texture:SetWidth(module:getOption("CT_MapMod_HerbNoteSize") or 14);
			for key, expansion in pairs(module.NoteTypes["Herb"]) do
				for i, val in ipairs(expansion) do 
					if (val["name"] == self.value) then
						pin.texture:SetTexture(val["icon"]);
					end
				end
			end
		end

		-- properties unique to each option
		if (module:getGameVersion() == CT_GAME_VERSION_RETAIL) then
			for key, expansion in pairs(module.NoteTypes["Herb"]) do
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
			for i, type in ipairs(module.NoteTypes["Herb"]["Classic"]) do
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
		dropdownEntry.func = function(self, arg1, arg2, checked)
			local dropdown = UIDROPDOWNMENU_OPEN_MENU or UIDROPDOWNMENU_INIT_MENU
			dropdown.unapprovedValue = self.value;
			UIDropDownMenu_SetText(dropdown,self.value);
			local pin = dropdown:GetParent().pin;
			pin.texture:SetHeight(module:getOption("CT_MapMod_OreNoteSize") or 14);
			pin.texture:SetWidth(module:getOption("CT_MapMod_OreNoteSize") or 14);
			for key, expansion in pairs(module.NoteTypes["Ore"]) do
				for i, val in ipairs(expansion) do 
					if (val["name"] == self.value) then
						pin.texture:SetTexture(val["icon"]);
					end
				end
			end
		end

		-- properties unique to each option
		if (module:getGameVersion() == CT_GAME_VERSION_RETAIL) then
			for key, expansion in pairs(module.NoteTypes["Ore"]) do
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
			for i, type in ipairs(module.NoteTypes["Ore"]["Classic"]) do
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

function CT_MapMod_AddUIElements()
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
						C_Timer.After(0.01,function() if (WorldMapFrame:GetMapID() ~= mapid) then WorldMapFrame:SetMapID(mapid) end end); --to add pins on the parts of a map in other zones
						WorldMapFrame:RefreshAllDataProviders();
						GameTooltip:Hide();
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
		["frame#n:CT_MapMod_px#s:40:16#bl:b:-140:0"] = { 
				["onload"] = function(self)
					if (module:getGameVersion() == CT_GAME_VERSION_CLASSIC) then
						self:SetFrameStrata("FULLSCREEN_DIALOG");
					end
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
					if (module:getGameVersion() == CT_GAME_VERSION_CLASSIC) then
						self:SetFrameStrata("FULLSCREEN_DIALOG");
					end
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
					if (module:getGameVersion() == CT_GAME_VERSION_CLASSIC) then
						self:SetFrameStrata("FULLSCREEN_DIALOG");
					end
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
					if (module:getGameVersion() == CT_GAME_VERSION_CLASSIC) then
						self:SetFrameStrata("FULLSCREEN_DIALOG");
					end
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
			local oreskills =  { 2575, 2576, 3564, 10248, 29354, 50310, 74517, 102161, 158754, 195122, 265837, 265839, 265841, 265843, 265845, 265847, 265849, 265851, 265854 }
			if ((module:getOption("CT_MapMod_AutoGatherHerbs") or 1) == 1) then
				for i, val in ipairs(herbskills) do
					if (arg4 == val) then
						for key, expansion in pairs(module.NoteTypes["Herb"]) do
							for j, type in ipairs(expansion) do
								if ( ((module.text["CT_MapMod/Herb/" .. type["name"]] or type["name"]) == arg2) and (not type["ignoregather"]) ) then
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
											["name"] = module.text["CT_MapMod/Herb/" .. type["name"]] or arg2,
											["set"] = "Herb",
											["subset"] = type["name"],
											["descript"] = "",
											["datemodified"] = date("%Y%m%d"),
											["version"] = MODULE_VERSION,
										};
										tinsert(CT_MapMod_Notes[mapid],newnote);
									end
									return;
								end
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
						if (GetLocale() == "enUS") then
							if (arg2:sub(1,5) == "Rich " and arg2:len() > 5) then arg2 = arg2:sub(6); end
							if (arg2:sub(-5) == " Vein" and arg2:len() > 5) then arg2 = arg2:sub(1,-6); end
							if (arg2:sub(-8) == " Deposit" and arg2:len() > 8) then arg2 = arg2:sub(1,-9); end
							if (arg2:sub(-5) == " Seam" and arg2:len() > 5) then arg2 = arg2:sub(1,-6); end
						elseif (GetLocale() == "frFR") then
							if (arg2:sub(1,6) == "Riche " and arg2:len() > 7) then arg2 = arg2:sub(7,7):upper() .. arg2:sub(8); end -- changes "Riche filon de thorium" to "Filon de Thorium"
							if (arg2:sub(1,9) == "Filon de " and arg2:len() > 10) then arg2 = arg2:sub(10,10):upper() .. arg2:sub(11); end -- changes "Filon de cuivre" to "Cuivre"
							if (arg2:sub(1,12) == "Gisement de " and arg2:len() > 13) then arg2 = arg2:sub(13,13):upper() .. arg2:sub(14); end -- changes "Gisement de fer" to "Fer"
							if (arg2:sub(1,9) == "Veine de " and arg2:len() > 10) then arg2 = arg2:sub(10,10):upper() .. arg2:sub(11); end -- changes "Veine de gangreschiste" to "Gangreschiste"
							elseif (GetLocale() == "deDE") then
							-- need to add german modifiers
						elseif (GetLocale() == "ruRU") then
							if (arg2:sub(1,8) == "Богатая " and arg2:len() > 9) then arg2 = arg2:sub(9,9):upper() .. arg2:sub(10); end -- changes "Богатая ториевая жила" to "Ториевая жила"
							if (arg2:sub(-5) == " жила" and arg2:len() > 5) then arg2 = arg2:sub(1,-6); end	--changes "Медная жила" to "Медная"
							if (arg2:sub(1,7) == "Залежи " and arg2:len() > 8) then arg2 = arg2:sub(8,8):upper() .. arg2:sub(9); end -- changes "Залежи истинного серебра" to "Истинного серебра"
						end
						for key, expansion in pairs(module.NoteTypes["Ore"]) do
							for j, type in ipairs(expansion) do
								if ( ((module.text["CT_MapMod/Ore/" .. type["name"]] or type["name"]) == arg2) and (not type["ignoregather"]) ) then
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
											["name"] = module.text["CT_MapMod/Ore/" .. type["name"]] or arg2,
											["set"] = "Ore",
											["subset"] = type["name"],
											["descript"] = "",
											["datemodified"] = date("%Y%m%d"),
											["version"] = MODULE_VERSION,
										};
										tinsert(CT_MapMod_Notes[mapid],newnote);
									end
									return;
								end
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
		optionsAddFrame(-5,    28, "slider#tl:24:%y#s:169:15#o:CT_MapMod_UserNoteSize:24##10:26:0.5");
		
		optionsAddObject(-5,   50, "font#t:0:%y#s:0:%s#l:13:0#r#" .. module.text["CT_MapMod/Options/Pins/Gathering/Line 1"] .. "#" .. textColor2 .. ":l"); -- Identify herbalist and mining nodes on the map.
		optionsAddObject(-5,   14, "font#t:0:%y#s:0:%s#l:13:0#r#" .. module.text["CT_MapMod/Options/Pins/Gathering/HerbNoteDisplayLabel"] .. "#" .. textColor1 .. ":l"); -- Show herb nodes
		optionsAddObject(-5,   24, "dropdown#tl:5:%y#s:150:20#o:CT_MapMod_HerbNoteDisplay#n:CT_MapMod_HerbNoteDisplay#" .. module.text["CT_MapMod/Options/Auto"] .. "#" .. module.text["CT_MapMod/Options/Always"] .. "#" .. module.text["CT_MapMod/Options/Disabled"]);
		optionsAddObject(-5,    8, "font#t:0:%y#s:0:%s#l:13:0#r#" .. module.text["CT_MapMod/Options/Pins/Icon Size"] .. "#" .. textColor1 .. ":l");
		optionsAddFrame(-5,    28, "slider#tl:24:%y#s:169:15#o:CT_MapMod_HerbNoteSize:14##10:26:0.5");
		optionsAddObject(-5,   14, "font#t:0:%y#s:0:%s#l:13:0#r#" .. module.text["CT_MapMod/Options/Pins/Gathering/OreNoteDisplayLabel"] .. "#" .. textColor1 .. ":l"); -- Show mining nodes
		optionsAddObject(-5,   24, "dropdown#tl:5:%y#s:150:20#o:CT_MapMod_OreNoteDisplay#n:CT_MapMod_OreNoteDisplay#" .. module.text["CT_MapMod/Options/Auto"] .. "#" .. module.text["CT_MapMod/Options/Always"] .. "#" .. module.text["CT_MapMod/Options/Disabled"]);
		optionsAddObject(-5,    8, "font#t:0:%y#s:0:%s#l:13:0#r#" .. module.text["CT_MapMod/Options/Pins/Icon Size"] .. "#" .. textColor1 .. ":l"); -- Icon size
		optionsAddFrame(-5,    28, "slider#tl:24:%y#s:169:15#o:CT_MapMod_OreNoteSize:14##10:26:0.5");
		
		optionsAddObject(-5,   50, "font#t:0:%y#s:0:%s#l:13:0#r#Reduce pin alpha to see other map features.\n(More alpha = more opaque)#" .. textColor2 .. ":l");
		optionsAddObject(-5,    8, "font#t:0:%y#s:0:%s#l:13:0#r#Alpha when zoomed out#" .. textColor1 .. ":l");
		optionsAddFrame(-5,    28, "slider#tl:24:%y#s:169:15#o:CT_MapMod_AlphaZoomedOut:0.75##0.50:1.00:0.05");
		optionsAddObject(-5,    8, "font#t:0:%y#s:0:%s#l:13:0#r#Alpha when zoomed in#" .. textColor1 .. ":l");
		optionsAddFrame(-5,    28, "slider#tl:24:%y#s:169:15#o:CT_MapMod_AlphaZoomedIn:1.00##0.50:1.00:0.05");
		
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


function CT_MapMod_ConvertOldNotes()

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



