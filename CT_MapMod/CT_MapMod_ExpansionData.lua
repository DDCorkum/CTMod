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

local module = select(2, ...);

-- Expansion Configuration Data
-- These tables should be updated every expansion or major patch to reflect new content




------------------------------------------------
-- Pins


-- Non-localized name of every valid user, herb and ore pin; the latter two subcategorized by how recently they were added to the game.
-- Value	String		Non-localized name as it is saved in the .wtf files.
module.pinTypes =
{
	["User"] =
	{
		"Grey Note",
		"Blue Shield",
		"Red Dot",
		"White Circle",
		"Green Square",
		"Red Cross",
		"Diamond", -- added in 8.0
		WaypointLocationDataProviderMixin and "Waypoint", -- added in 9.0
	},			
	["Herb"] =
	{
		["Classic"] = 
		{
			"Bruiseweed", "Arthas' Tears", "Black Lotus", "Blindweed", "Briarthorn",
			"Dreamfoil", "Earthroot", "Fadeleaf", "Firebloom", "Ghost Mushroom",
			"Golden Sansam", "Goldthorn", "Grave Moss", "Gromsblood", "Icecap",
			"Khadgars Whisker", "Kingsblood", "Liferoot", "Mageroyal", "Mountain Silversage",
			"Peacebloom", "Plaguebloom", "Purple Lotus", "Silverleaf", "Stranglekelp",
			"Sungrass", "Swiftthistle", "Wild Steelbloom", "Wintersbite", "Dreaming Glory",
		},
		["Early Expansions"] = 
		{
			-- BC, Wrath, Cata, MoP
			"Felweed", "Flame Cap", "Mana Thistle", "Netherbloom", "Netherdust Bush", "Nightmare Vine", "Ragveil", "Terocone",
			"Adders Tongue", "Frost Lotus", "Goldclover", "Icethorn", "Lichbloom", "Talandra's Rose", "Tiger Lily",	"Frozen Herb",
			"Cinderbloom", "Azshara's Veil", "Stormvein", "Heartblossom", "Whiptail", "Twilight Jasmine",
			"Green Tea Leaf", "Rain Poppy", "Silkweed", "Snow Lily", "Fool's Cap", "Sha-Touched Herb", "Golden Lotus",
		},
		["Recent Expansions"] =
		{
			-- WoD, Legion, BFA, SL
			"Fireweed", "Gorgrond Flytrap", "Frostweed", "Nagrand Arrowbloom", "Starflower", "Talador Orchid", "Withered Herb",
			"Aethril", "Astral Glory", "Dreamleaf", "Fel-Encrusted Herb", "Fjarnskaggl", "Foxflower", "Starlight Rose",
			"Akunda's Bite", "Anchor Weed", "Riverbud", "Sea Stalks", "Siren's Sting", "Star Moss", "Winter's Kiss", "Zin'anthid",
			"Death Blossom", "Marrowroot", "Rising Glory", "Vigil's Torch", "Widowbloom", "Nightshade",
		},
	},
	["Ore"] =
	{ 
		["Classic"] = 
		{
			"Copper", "Gold", "Iron", "Mithril", "Silver",
			"Thorium", "Tin", "Truesilver", "Adamantite",
		},
		["Early Expansions"] = 
		{
			-- BC, Wrath, Cata, MoP
			"Fel Iron", "Khorium",
			"Cobalt", "Saronite", "Titanium",
			"Elementium", "Obsidian", "Pyrite",
			"Ghost Iron", "Kyparite", "Trillium",
		},
		["Recent Expansions"] = 
		{
			-- WoD, Legion, BFA, SL
			"Blackrock", "True Iron",
			"Leystone", "Felslate",
			"Monelite", "Storm Silver", "Platinum", "Osmenite",
			"Laestrite", "Oxxein", "Phaedrum", "Sinvyr", "Solenium", "Elethium"
		},
	},
};

-- Path to the texture used for each type of pin, or a table containing the path, dimensions and tex coords.
-- Key		String		Non-localized name as it appears in module.pinTypes
-- Value	String		Path to the in-game or custom AddOn texture using assuming default TexCoord(0, 1, 0, 1)
--		or Table	Table with .path, .width, .height, .left, .right, .top and .bottom to use with tooltips, tex coords, etc.
module.pinIcons = 
{
	-- User --
	["Grey Note"] = "Interface\\AddOns\\CT_MapMod\\Skin\\GreyNote",
	["Blue Shield"] = "Interface\\AddOns\\CT_MapMod\\Skin\\BlueShield",
	["Red Dot"] = "Interface\\AddOns\\CT_MapMod\\Skin\\RedDot",
	["White Circle"] = "Interface\\AddOns\\CT_MapMod\\Skin\\WhiteCircle",
	["Green Square"] = "Interface\\AddOns\\CT_MapMod\\Skin\\GreenSquare",
	["Red Cross"] = "Interface\\AddOns\\CT_MapMod\\Skin\\RedCross",
	["Diamond"] = "Interface\\RaidFrame\\UI-RaidFrame-Threat",
	["Waypoint"] =
	{
		path = "Interface\\Waypoint\\WaypoinMapPinUI",
		width = 30,
		height = 30,
		left = 0.320312,
		right = 0.554688,
		top = 0.515625,
		bottom = 0.984375
	},
	
	-- Herbs --
	
	-- Classic
	["Bruiseweed"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed",
	["Arthas' Tears"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_ArthasTears",
	["Black Lotus"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_BlackLotus",
	["Blindweed"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Blindweed",
	["Briarthorn"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Briarthorn",
	["Dreamfoil"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Dreamfoil",
	["Earthroot"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Earthroot",
	["Fadeleaf"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Fadeleaf",
	["Firebloom"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Firebloom",
	["Ghost Mushroom"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_GhostMushroom",
	["Golden Sansam"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_GoldenSansam",
	["Goldthorn"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Goldthorn",
	["Grave Moss"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_GraveMoss",
	["Gromsblood"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Gromsblood",
	["Icecap"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Icecap",
	["Khadgars Whisker"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_KhadgarsWhisker",
	["Kingsblood"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Kingsblood",
	["Liferoot"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Liferoot",
	["Mageroyal"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Mageroyal",
	["Mountain Silversage"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_MountainSilversage",
	["Peacebloom"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Peacebloom",
	["Plaguebloom"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Plaguebloom",
	["Purple Lotus"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_PurpleLotus",
	["Silverleaf"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Silverleaf",
	["Stranglekelp"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Stranglekelp",
	["Sungrass"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Sungrass",
	["Swiftthistle"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Swiftthistle",
	["Wild Steelbloom"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_WildSteelbloom",
	["Wintersbite"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Wintersbite",
	["Dreaming Glory"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_DreamingGlory",
	
	-- Burning Crusade
	["Felweed"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Felweed",
	["Flame Cap"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_FlameCap",
	["Mana Thistle"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_ManaThistle",
	["Netherbloom"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Netherbloom",
	["Netherdust Bush"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_NetherdustBush",
	["Nightmare Vine"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_NightmareVine",
	["Ragveil"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Ragveil",
	["Terocone"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Terocone",
	
	-- Wrath of the Lich King
	["Adders Tongue"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_AddersTongue",
	["Frost Lotus"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_FrostLotus",
	["Goldclover"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Goldclover",
	["Icethorn"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Icethorn",
	["Lichbloom"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Lichbloom",
	["Talandra's Rose"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_TalandrasRose",
	["Tiger Lily"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_TigerLily",
	["Frozen Herb"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_FrozenHerb",
	
	-- Cataclysm
	["Cinderbloom"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed",
	["Azshara's Veil"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed",
	["Stormvein"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed",
	["Heartblossom"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed",
	["Whiptail"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed",
	["Twilight Jasmine"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed",
	
	-- Mists of Pandaria
	["Green Tea Leaf"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed",
	["Rain Poppy"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed",
	["Silkweed"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed",
	["Snow Lily"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed",
	["Fool's Cap"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed",
	["Sha-Touched Herb"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed",
	["Golden Lotus"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed",	
	["Fireweed"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Fireweed",
	["Gorgrond Flytrap"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_GorgrondFlytrap",
	["Frostweed"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Frostweed",
	["Nagrand Arrowbloom"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_NagrandArrowbloom",
	["Starflower"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Starflower",
	["Talador Orchid"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_TaladorOrchid",
	["Withered Herb"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_FrozenHerb",
	
	-- Legion
	["Aethril"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed",
	["Astral Glory"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed",
	["Dreamleaf"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed",
	["Fel-Encrusted Herb"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed",
	["Fjarnskaggl"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed",
	["Foxflower"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed",
	["Starlight Rose"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_StarlightRose",
	
	-- Battle for Azeroth
	["Akunda's Bite"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_AkundasBite",
	["Anchor Weed"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_AnchorWeed",
	["Riverbud"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Riverbud",
	["Sea Stalks"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_SeaStalk",
	["Siren's Sting"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed",
	["Star Moss"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_StarMoss",
	["Winter's Kiss"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_WintersKiss",
	["Zin'anthid"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Zinanthid",
	
	-- Shadowlands
	["Death Blossom"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_DeathBlossom",
	["Marrowroot"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Marrowroot",
	["Rising Glory"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_RisingGlory",
	["Vigil's Torch"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_VigilsTorch",
	["Widowbloom"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Widowbloom",	
	["Nightshade"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Nightshade",
	
	-- Ore --
	
	-- Classic
	["Copper"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_CopperVein",
	["Gold"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_GoldVein",
	["Iron"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_IronVein",
	["Mithril"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_MithrilVein",
	["Silver"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_SilverVein",
	["Thorium"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_ThoriumVein",
	["Tin"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_TinVein",
	["Truesilver"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_TruesilverVein",
	["Adamantite"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_AdamantiteVein",
	
	-- Burning Crusade
	["Fel Iron"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_FelIronVein",
	["Khorium"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_KhoriumVein",
	
	-- Wrath of the Lich King
	["Cobalt"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_CobaltVein",
	["Saronite"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_SaroniteVein",
	["Titanium"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_TitaniumVein",
	
	-- Cataclysm
	["Elementium"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_Elementium",
	["Obsidian"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_Obsidian",
	["Pyrite"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_Pyrite",
	
	-- Mists of Pandaria
	["Ghost Iron"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_GhostIron",
	["Kyparite"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_Kyparite" ,
	["Trillium"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_Trillium",
	
	-- Warlords of Draenor
	["Blackrock"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_CopperVein",
	["True Iron"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_CopperVein",
	
	-- Legion
	["Leystone"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_Leystone",
	["Felslate"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_Felslate",
	
	-- Battle for Azeroth
	["Monelite"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_CopperVein",
	["Storm Silver"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_StormSilver",
	["Platinum"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_Platinum",
	["Osmenite"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_Elementium",
	
	-- Shadowlands
	["Laestrite"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_Laestrite",
	["Oxxein"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_Oxxein",
	["Phaedrum"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_Phaedrum",
	["Sinvyr"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_Sinvyr",
	["Solenium"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_Solenium",
	["Elethium"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_Elethium",
}
setmetatable(module.pinIcons, {__index = function() return "Interface\\RaidFrame\\UI-RaidFrame-Threat" end})

-- Herbs and ore that spawn randomly in place of other nodes, so do not create any pins.
-- Key		string		Non-localized name as it appears in module.pinTypes
-- Value	boolean		True if the herbalism or mining node occurs randomly and is therefore not worth marking on the map.
--		or function	If the value is a function, it will be called and the return will be checked as a boolean
module.randomSpawns =
{
	-- Battle for Azeroth
	["Anchor Weed"] = true,
	["Platinum"] = true,
	
	-- Shadowlands
	["Nightshade"] = function() return C_Map.GetBestMapForUnit("player") ~= 1543; end,
	["Elethium"] = function() return C_Map.GetBestMapForUnit("player") ~= 1543; end,
}


------------------------------------------------
-- Flight Maps

-- Allows pins to appear at flight masters if there is a corresponding world-map that looks identical
-- 	key			Number, Required		GetTaxiMapID() when at a flight master using FlightMapFrame
--	val			Number, Required		GetMapID() when looking at a continent in the WorldMapFrame
module.flightMaps = 
{
	 [990] = 552, -- Draenor  -- never used, because WoD has the TaxiRouteFrame instead of FlightMapFrame
	[1011] = 875, -- Zandalar
	[1014] = 876, -- Kul Tiras
	[1208] =  13, -- Eastern Kingdoms
	[1209] =  12, -- Kalimdor
	[1384] = 113, -- Northrend
	[1467] = 101, -- Outland
	[1647] = 1550, -- Shadowlands 
};


-- Classic Flight Path x/y scaling and offsets
-- 	key			Number, Required		GetTaxiMapID() when at a flight master using FlightMapFrame
--	val			Table, Required			xOff and yOff are added to the x/y coords, and everything is multiplied by xScale/yScale
module.classicFlightMapSizes = 
{
	[1414] = { xOff = -0.15, xScale = 1.52, yOff = -0.09, yScale = 1.09 },	-- Classic Kalimdor
	[1415] = { xOff = -0.166, xScale = 1.5, yOff = -0, yScale = 1 },	-- Classic Eastern Kingdoms
	[1945] = { xOff = -0.166, xScale = 1.52, yOff = 0.071, yScale = 0.92 },		-- The Burning Crusade Classic
	
};


-- Data points to omit from the taxi map
-- 	key			Number, Required		TaxiNodeID
module.ignoreClassicTaxiNodes = 
{
	[103] = true,
	[104] = true,
	[105] = true,
	[106] = true,
	[107] = true,
	[108] = true,
	[109] = true,
	[110] = true,
	
};


------------------------------------------------
-- Gathering Professions

-- Allows detecting interactions with herbalism nodes
-- 	key			Number, Required		SpellID of an herbalism ability used on an herbalism node
--	val			String, Required		Must evaluate to "Herb" or "Ore"
module.gatheringSkills =
{
	-- Herbalism
	  [2366] = "Herb",
	  [2368] = "Herb",
	  [3570] = "Herb",
	 [11993] = "Herb",
	 [28695] = "Herb",
	 [50300] = "Herb",
	 [74519] = "Herb",
	[110413] = "Herb",
	[158745] = "Herb",
	[265819] = "Herb",
	[265821] = "Herb",
	[265823] = "Herb",
	[265825] = "Herb",
	[265827] = "Herb",
	[265829] = "Herb",
	[265831] = "Herb",
	[265834] = "Herb",
	[265835] = "Herb",
	[309780] = "Herb",	-- Shadowlands

	-- Mining
	   [186] = "Ore",
	  [2575] = "Ore",	-- Classic Apprentice
	  [2576] = "Ore",	-- Classic Journeyman
	  [3564] = "Ore",	-- Classic Expert
	 [10248] = "Ore",	-- Classic Artisan
	 [29354] = "Ore",	-- Legacy Master (BC)
	 [50310] = "Ore",	-- Legacy Grand Master (WotLK)
	 [74517] = "Ore",	-- Legacy Illustrious Grand Master (Cata)
	[102161] = "Ore",	-- Legacy Zen Master Minder (Pandaria)
	[158754] = "Ore",	-- Legacy Draenor
	[195122] = "Ore",	-- Legacy Broken Isles
	[265837] = "Ore",	-- Artisan
	[265839] = "Ore",	-- Burning Crusade
	[265841] = "Ore",	-- Northrend
	[265843] = "Ore",	-- Cataclysm
	[265845] = "Ore",	-- Pandaria
	[265847] = "Ore",	-- Draenor
	[265849] = "Ore",	-- Legion
	[265851] = "Ore",	-- Kul Tiran
	[265854] = "Ore",	-- Zandalari
	[309835] = "Ore",	-- Shadowlands
}


------------------------------------------------
-- Localization

if (module:getGameVersion() == CT_GAME_VERSION_CLASSIC) then
	local findOre = Spell:CreateFromSpellID(2580);
	findOre:ContinueOnSpellLoad(
		function() 
			module.text = module.text or {};
			module.text["CT_MapMod/Map/ClassicMiner"] = GetSpellInfo(2580);
		end
	);
	local findHerbs = Spell:CreateFromSpellID(2383);
	findHerbs:ContinueOnSpellLoad(
		function() 
			module.text = module.text or {};
			module.text["CT_MapMod/Map/ClassicHerbalist"] = GetSpellInfo(2383);
		end
	);
end