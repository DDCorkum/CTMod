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

-- One subtable for each category of pin, posibly further divided into subcategories, and finally subtables describing each type of pin that CT_MapMod uses
-- 	category		String, Required		"User" for custom icons the user places, and "Herb" or "Ore" for herbalism and mining nodes that are usually created automatically
--	subcategory		String				Used only for Herb and Ore categories to divide Classic from other expansions
--	name			String, Required		Non-localized key used to recognize a type of pin
--	icon			Texture, Required		Path to a square texture that will be loaded in its entirity (no tex coords)
--	spawnsRandomly		Boolean				Indicates an herbalism or mining node will randomly spawn in place of another kind
--	id			Number				Not currently used; please disregard
module.pinTypes =
{
	["User"] =
	{
		{ ["name"] = "Grey Note", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Skin\\GreyNote" }, --1
		{ ["name"] = "Blue Shield", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Skin\\BlueShield" }, --2
		{ ["name"] = "Red Dot", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Skin\\RedDot" }, --3
		{ ["name"] = "White Circle", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Skin\\WhiteCircle" }, --4
		{ ["name"] = "Green Square", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Skin\\GreenSquare" }, --5
		{ ["name"] = "Red Cross", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Skin\\RedCross" }, --6
		{ ["name"] = "Diamond", ["icon"] = "Interface\\RaidFrame\\UI-RaidFrame-Threat" }, -- added in 8.0
		module:getGameVersion() >= 9 and { ["name"] = "Waypoint", ["icon"] = "Interface\\Waypoint\\WaypoinMapPinUI", ["texCoord"] = {width = 30, height = 30, left = 0.320312, right = 0.554688, top = 0.515625, bottom = 0.984375} } or nil, -- added in 9.0
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
			{ ["name"] = "Anchor Weed", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_AnchorWeed", ["spawnsRandomly"] = true },
			{ ["name"] = "Riverbud", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Riverbud" },
			{ ["name"] = "Sea Stalks", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_SeaStalk" },
			{ ["name"] = "Siren's Sting", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed" },
			{ ["name"] = "Star Moss", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_StarMoss" },
			{ ["name"] = "Winter's Kiss", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_WintersKiss" },
			{ ["name"] = "Zin'anthid", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Zinanthid" },
			-- Shadowlands
			{ ["name"] = "Death Blossom", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_DeathBlossom", },
			{ ["name"] = "Marrowroot", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed" },
			{ ["name"] = "Rising Glory", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed" },
			{ ["name"] = "Widowbloom", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed" },
			
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
			{ ["name"] = "Platinum", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_Platinum", ["spawnsRandomly"] = true },
			{ ["name"] = "Osmenite", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_Elementium" },
			-- Shadowlands
			{ ["name"] = "Laestrite", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_ElementiumVein" },
			{ ["name"] = "Oxxein", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_CopperVein" },
			{ ["name"] = "Phaedrum", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_CopperVein" },
			{ ["name"] = "Sinvyr", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_CopperVein" },
			{ ["name"] = "Solenium", ["icon"] = "Interface\\AddOns\\CT_MapMod\\Resource\\Ore_GoldVein" },
		},
	},
};


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


------------------------------------------------
-- Gathering Professions

-- Allows detecting interactions with herbalism nodes
-- 	key			Number, Required		SpellID of an herbalism ability used on an herbalism node
--	val			Boolean, Required		Must evaluate to true
module.herbalismSkills =
{
	  [2366] = true,
	  [2368] = true,
	  [3570] = true,
	 [11993] = true,
	 [28695] = true,
	 [50300] = true,
	 [74519] = true,
	[110413] = true,
	[158745] = true,
	[265819] = true,
	[265821] = true,
	[265823] = true,
	[265825] = true,
	[265827] = true,
	[265829] = true,
	[265831] = true,
	[265834] = true,
	[265835] = true,
	[309780] = true,	-- Shadowlands
}

-- Allows detecting interactions with mining nodes
-- 	key			Number, Required		SpellID of a mining ability used on a mining node
--	val			Boolean, Required		Must evaluate to true
module.miningSkills = 
{
	   [186] = true,	-- Mining
	  [2575] = true,	-- Classic Apprentice
	  [2576] = true,	-- Classic Journeyman
	  [3564] = true,	-- Classic Expert
	 [10248] = true,	-- Classic Artisan
	 [29354] = true,	-- Legacy Master (BC)
	 [50310] = true,	-- Legacy Grand Master (WotLK)
	 [74517] = true,	-- Legacy Illustrious Grand Master (Cata)
	[102161] = true,	-- Legacy Zen Master Minder (Pandaria)
	[158754] = true,	-- Legacy Draenor
	[195122] = true,	-- Legacy Broken Isles
	[265837] = true,	-- Artisan
	[265839] = true,	-- Burning Crusade
	[265841] = true,	-- Northrend
	[265843] = true,	-- Cataclysm
	[265845] = true,	-- Pandaria
	[265847] = true,	-- Draenor
	[265849] = true,	-- Legion
	[265851] = true,	-- Kul Tiran
	[265854] = true,	-- Zandalari
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