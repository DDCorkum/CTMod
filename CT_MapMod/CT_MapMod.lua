
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

--------------------------------------------
-- Upvalues

local abs = abs
local ipairs = ipairs
local math = math
local pairs = pairs
local select = select
local string = string
local strlen = strlen
local strlower = strlower
local strsub = strsub
local strupper = strupper
local tinsert = tinsert
local tonumber = tonumber
local tremove = tremove
local type = type

local CreateFrame = CreateFrame

local DungeonUsesTerrainMap = DungeonUsesTerrainMap
local GetCurrentMapAreaID = GetCurrentMapAreaID
local GetCurrentMapContinent = GetCurrentMapContinent
local GetCurrentMapDungeonLevel = GetCurrentMapDungeonLevel
local GetCurrentMapZone = GetCurrentMapZone
local GetCursorPosition = GetCursorPosition
local GetMapContinents = GetMapContinents
local GetMapInfo = GetMapInfo
local GetMapNameByID = GetMapNameByID
local GetMapZones = GetMapZones
local GetPlayerMapPosition = GetPlayerMapPosition
local GetRealmName = GetRealmName
local IsControlKeyDown = IsControlKeyDown
local PlaySound = PlaySound
local SetMapToCurrentZone = SetMapToCurrentZone
local SetMapZoom = SetMapZoom
local UnitName = UnitName

--------------------------------------------
-- General Mod Code (recode imminent!)

CT_UserMap_Notes = {};  -- Used mapName as key before version 7.3; now uses integer mapID


-- DEPRECIATED -- REQUIRED ONLY TO TRANSITION OLD NOTES TO THE NEW VERSION IN 7.3
CT_UserMap_Zone = {};   -- Necessary only to convert notes from mapName to mapID keys

-- Kalimdor
CT_UserMap_Zone["Ahn'Qiraj: The Fallen Kingdom"] = "772:0";
CT_UserMap_Zone["Ammen Vale"] = "894:0";
CT_UserMap_Zone["Ashenvale"] = "43:0";
CT_UserMap_Zone["Azshara"] = "181:0";
CT_UserMap_Zone["Azuremyst Isle"] = "464:0";
CT_UserMap_Zone["Bloodmyst Isle"] = "476:0";
CT_UserMap_Zone["Camp Narache"] = "890:0";
CT_UserMap_Zone["Darkshore"] = "42:0";
CT_UserMap_Zone["Darnassus"] = "381:0";
CT_UserMap_Zone["Desolace"] = "101:0";
CT_UserMap_Zone["Durotar"] = "4:0";
CT_UserMap_Zone["Dustwallow Marsh"] = "141:0";
CT_UserMap_Zone["Echo Isles"] = "891:0";
CT_UserMap_Zone["Felwood"] = "182:0";
CT_UserMap_Zone["Feralas"] = "121:0";
CT_UserMap_Zone["Molten Front"] = "795:0";
CT_UserMap_Zone["Moonglade"] = "241:0";
CT_UserMap_Zone["Mount Hyjal"] = "606:0";
CT_UserMap_Zone["Mulgore"] = "9:0";
CT_UserMap_Zone["Northern Barrens"] = "11:0";
CT_UserMap_Zone["Orgrimmar"] = "321:0";
CT_UserMap_Zone["Shadowglen"] = "888:0";
CT_UserMap_Zone["Silithus"] = "261:0";
CT_UserMap_Zone["Southern Barrens"] = "607:0";
CT_UserMap_Zone["Stonetalon Mountains"] = "81:0";
CT_UserMap_Zone["Tanaris"] = "161:0";
CT_UserMap_Zone["Teldrassil"] = "41:0";
CT_UserMap_Zone["The Exodar"] = "471:0";
CT_UserMap_Zone["Thousand Needles"] = "61:0";
CT_UserMap_Zone["Thunder Bluff"] = "362:0";
CT_UserMap_Zone["Uldum"] = "720:0";
CT_UserMap_Zone["Un'Goro Crater"] = "201:0";
CT_UserMap_Zone["Valley of Trials"] = "889:0";
CT_UserMap_Zone["Winterspring"] = "281:0";

-- Eastern Kingdoms
CT_UserMap_Zone["Abyssal Depths"] = "614:0";
CT_UserMap_Zone["Arathi Highlands"] = "16:0";
CT_UserMap_Zone["Badlands"] = "17:0";
CT_UserMap_Zone["Blasted Lands"] = "19:0";
CT_UserMap_Zone["Burning Steppes"] = "29:0";
CT_UserMap_Zone["Coldridge Valley"] = "866:0";
CT_UserMap_Zone["Deadwind Pass"] = "32:0";
CT_UserMap_Zone["Deathknell"] = "892:0";
CT_UserMap_Zone["Dun Morogh"] = "27:0";
CT_UserMap_Zone["Duskwood"] = "34:0";
CT_UserMap_Zone["Eastern Plaguelands"] = "23:0";
CT_UserMap_Zone["Elwynn Forest"] = "30:0";
CT_UserMap_Zone["Eversong Woods"] = "462:0";
CT_UserMap_Zone["Ghostlands"] = "463:0";
CT_UserMap_Zone["Gilneas"] = "545:0";
CT_UserMap_Zone["Gilneas City"] = "611:0";
CT_UserMap_Zone["Hillsbrad Foothills"] = "24:0";
CT_UserMap_Zone["Ironforge"] = "341:0";
CT_UserMap_Zone["Isle of Quel'Danas"] = "499:0";
CT_UserMap_Zone["Kelp'thar Forest"] = "610:0";
CT_UserMap_Zone["Loch Modan"] = "35:0";
CT_UserMap_Zone["New Tinkertown"] = "895:0";
CT_UserMap_Zone["Northern Stranglethorn"] = "37:0";
CT_UserMap_Zone["Northshire"] = "864:0";
CT_UserMap_Zone["Redridge Mountains"] = "36:0";
CT_UserMap_Zone["Ruins of Gilneas"] = "684:0";
CT_UserMap_Zone["Ruins of Gilneas City"] = "685:0";
CT_UserMap_Zone["Searing Gorge"] = "28:0";
CT_UserMap_Zone["Shimmering Expanse"] = "615:0";
CT_UserMap_Zone["Silvermoon City"] = "480:0";
CT_UserMap_Zone["Silverpine Forest"] = "21:0";
CT_UserMap_Zone["Stormwind City"] = "301:0";
CT_UserMap_Zone["Stranglethorn Vale"] = "689:0";
CT_UserMap_Zone["Sunstrider Isle"] = "893:0";
CT_UserMap_Zone["Swamp of Sorrows"] = "38:0";
CT_UserMap_Zone["The Cape of Stranglethorn"] = "673:0";
CT_UserMap_Zone["The Hinterlands"] = "26:0";
CT_UserMap_Zone["The Scarlet Enclave"] = "502:0";
CT_UserMap_Zone["Tirisfal Glades"] = "20:0";
CT_UserMap_Zone["Tol Barad"] = "708:0";
CT_UserMap_Zone["Tol Barad Peninsula"] = "709:0";
CT_UserMap_Zone["Twilight Highlands"] = "700:0";
CT_UserMap_Zone["Undercity"] = "382:0";
CT_UserMap_Zone["Vashj'ir"] = "613:0";
CT_UserMap_Zone["Western Plaguelands"] = "22:0";
CT_UserMap_Zone["Westfall"] = "39:0";
CT_UserMap_Zone["Wetlands"] = "40:0";

-- Outland
CT_UserMap_Zone["Blade's Edge Mountains"] = "475:0";
CT_UserMap_Zone["Hellfire Peninsula"] = "465:0";
CT_UserMap_Zone["Nagrand"] = "477:0";
CT_UserMap_Zone["Netherstorm"] = "479:0";
CT_UserMap_Zone["Shadowmoon Valley"] = "473:0";
CT_UserMap_Zone["Shattrath City"] = "481:0";
CT_UserMap_Zone["Terokkar Forest"] = "478:0";
CT_UserMap_Zone["Zangarmarsh"] = "467:0";

-- Northrend
CT_UserMap_Zone["Borean Tundra"] = "486:0";
CT_UserMap_Zone["Crystalsong Forest"] = "510:0";
--CT_UserMap_Zone["Dalaran"] = "504:0";  -- will assume dal is the legion one
CT_UserMap_Zone["Dragonblight"] = "488:0";
CT_UserMap_Zone["Grizzly Hills"] = "490:0";
CT_UserMap_Zone["Howling Fjord"] = "491:0";
CT_UserMap_Zone["Hrothgar's Landing"] = "541:0";
CT_UserMap_Zone["Icecrown"] = "492:0";
CT_UserMap_Zone["Sholazar Basin"] = "493:0";
CT_UserMap_Zone["The Storm Peaks"] = "495:0";
CT_UserMap_Zone["Wintergrasp"] = "501:0";
CT_UserMap_Zone["Zul'Drak"] = "496:0";

-- The Maelstrom
CT_UserMap_Zone["Deepholm"] = "640:0";
CT_UserMap_Zone["Kezan"] = "605:0";
CT_UserMap_Zone["The Lost Isles"] = "544:0";

-- Pandaria
CT_UserMap_Zone["Dread Wastes"] = "858:0";
CT_UserMap_Zone["Isle of Giants"] = "929:0";
CT_UserMap_Zone["Isle of Thunder"] = "928:0";
CT_UserMap_Zone["Krasarang Wilds"] = "857:0";
CT_UserMap_Zone["Kun-Lai Summit"] = "809:0";
CT_UserMap_Zone["Shrine of Seven Stars"] = "905:0";
CT_UserMap_Zone["Shrine of Two Moons"] = "903:0";
CT_UserMap_Zone["The Jade Forest"] = "806:0";
CT_UserMap_Zone["The Veiled Stair"] = "873:0";
CT_UserMap_Zone["The Wandering Isle"] = "808:0";
CT_UserMap_Zone["Timeless Isle"] = "951:0";
CT_UserMap_Zone["Townlong Steppes"] = "810:0";
CT_UserMap_Zone["Vale of Eternal Blossoms"] = "811:0";
CT_UserMap_Zone["Valley of the Four Winds"] = "807:0";

-- Draenor
CT_UserMap_Zone["Ashran"] = "978:0";
CT_UserMap_Zone["Frostfire Ridge"] = "941:0";
CT_UserMap_Zone["Frostwall"] = "976:0";
CT_UserMap_Zone["Gorgrond"] = "949:0";
CT_UserMap_Zone["Lunarfall"] = "971:0";
CT_UserMap_Zone["Nagrand"] = "950:0";
CT_UserMap_Zone["Shadowmoon Valley"] = "947:0";
CT_UserMap_Zone["Spires of Arak"] = "948:0";
CT_UserMap_Zone["Stormshield"] = "1009:0";
CT_UserMap_Zone["Talador"] = "946:0";
CT_UserMap_Zone["Tanaan Jungle"] = "945:0";
CT_UserMap_Zone["Tanaan Jungle - Assault on the Dark Portal"] = "970:0";
CT_UserMap_Zone["Warspear"] = "1011:0";

-- Legion
CT_UserMap_Zone["Aszuna"] = "1015:0";
CT_UserMap_Zone["Highmountain"] = "1024:0";
CT_UserMap_Zone["Stormheim"] = "1017:0";
CT_UserMap_Zone["Suramar"] = "1033:0";
CT_UserMap_Zone["Val'sharah"] = "1018:0";
CT_UserMap_Zone["Antoran Wastes"] = "1171:0";
CT_UserMap_Zone["Krokuun"] = "1135:0";
CT_UserMap_Zone["Dalaran"] = "1014-10";


-- Battlegrounds
CT_UserMap_Zone["Alterac Valley"] = "401:1";
CT_UserMap_Zone["Arathi Basin"] = "461:1";
CT_UserMap_Zone["Deepwind Gorge"] = "935:1";
CT_UserMap_Zone["Eye of the Storm"] = "482:1";
CT_UserMap_Zone["Isle of Conquest"] = "540:1";
CT_UserMap_Zone["Silvershard Mines"] = "860:1";
CT_UserMap_Zone["Strand of the Ancients"] = "512:1";
CT_UserMap_Zone["Temple of Kotmogu"] = "856:1";
CT_UserMap_Zone["The Battle for Gilneas"] = "736:1";
CT_UserMap_Zone["Twin Peaks"] = "626:1";
CT_UserMap_Zone["Warsong Gulch"] = "443:1";

-- Scenarios
CT_UserMap_Zone["A Brewing Storm"] = "878:1";
CT_UserMap_Zone["A Little Patience"] = "912:1";
CT_UserMap_Zone["Arena of Annihilation"] = "899:1";
CT_UserMap_Zone["Assault on Zan'vess"] = "883:1";
CT_UserMap_Zone["Battle on the High Seas"] = "940:1";
CT_UserMap_Zone["Blood in the Snow"] = "939:1";
CT_UserMap_Zone["Brewmoon Festival"] = "884:1";
CT_UserMap_Zone["Celestial Tournament"] = "955:1";
CT_UserMap_Zone["Crypt of Forgotten Kings"] = "900:1";
CT_UserMap_Zone["Dagger in the Dark"] = "914:1";
CT_UserMap_Zone["Dark Heart of Pandaria"] = "937:1";
CT_UserMap_Zone["Domination Point (H)"] = "920:1";
CT_UserMap_Zone["Greenstone Village"] = "880:1";
CT_UserMap_Zone["Lion's Landing (A)"] = "911:1";
CT_UserMap_Zone["Malorne's Nightmare"] = "1086:1";
CT_UserMap_Zone["The Road to Fel"] = "1099:1";
CT_UserMap_Zone["The Secrets of Ragefire"] = "938:1";
CT_UserMap_Zone["Theramore's Fall (A)"] = "906:1";
CT_UserMap_Zone["Theramore's Fall (H)"] = "851:1";
CT_UserMap_Zone["Unga Ingoo"] = "882:1";

-- Classic Dungeons
CT_UserMap_Zone["Blackfathom Deeps"] = "688:1";
CT_UserMap_Zone["Blackrock Depths"] = "704:1";
CT_UserMap_Zone["Blackrock Spire"] = "721:1";
CT_UserMap_Zone["Dire Maul"] = "699:1";
CT_UserMap_Zone["Gnomeregan"] = "691:1";
CT_UserMap_Zone["Maraudon"] = "750:1";
CT_UserMap_Zone["Ragefire Chasm"] = "680:1";
CT_UserMap_Zone["Razorfen Downs"] = "760:1";
CT_UserMap_Zone["Razorfen Kraul"] = "761:1";
CT_UserMap_Zone["Shadowfang Keep"] = "764:1";
CT_UserMap_Zone["Stratholme"] = "765:1";
CT_UserMap_Zone["The Deadmines"] = "756:1";
CT_UserMap_Zone["The Stockade"] = "690:1";
CT_UserMap_Zone["The Temple of Atal'Hakkar"] = "687:1";
CT_UserMap_Zone["Uldaman"] = "692:1";
CT_UserMap_Zone["Wailing Caverns"] = "749:1";
CT_UserMap_Zone["Zul'Farrak"] = "686:1";

-- Classic Raids
CT_UserMap_Zone["Blackwing Lair"] = "755:1";
CT_UserMap_Zone["Molten Core"] = "696:1";
CT_UserMap_Zone["Ruins of Ahn'Qiraj"] = "717:1";
CT_UserMap_Zone["Temple of Ahn'Qiraj"] = "766:1";

-- Burning Crusade Dungeons
CT_UserMap_Zone["Auchenai Crypts"] = "722:1";
CT_UserMap_Zone["Hellfire Ramparts"] = "797:1";
CT_UserMap_Zone["Magisters' Terrace"] = "798:1";
CT_UserMap_Zone["Mana-Tombs"] = "732:1";
CT_UserMap_Zone["Old Hillsbrad Foothills"] = "734:1";
CT_UserMap_Zone["Sethekk Halls"] = "723:1";
CT_UserMap_Zone["Shadow Labyrinth"] = "724:1";
CT_UserMap_Zone["The Arcatraz"] = "731:1";
CT_UserMap_Zone["The Black Morass"] = "733:1";
CT_UserMap_Zone["The Blood Furnace"] = "725:1";
CT_UserMap_Zone["The Botanica"] = "729:1";
CT_UserMap_Zone["The Mechanar"] = "730:1";
CT_UserMap_Zone["The Shattered Halls"] = "710:1";
CT_UserMap_Zone["The Slave Pens"] = "728:1";
CT_UserMap_Zone["The Steamvault"] = "727:1";
CT_UserMap_Zone["The Underbog"] = "726:1";

-- Burning Crusade Raids
CT_UserMap_Zone["Black Temple"] = "796:1";
CT_UserMap_Zone["Gruul's Lair"] = "776:1";
CT_UserMap_Zone["Hyjal Summit"] = "775:1";
CT_UserMap_Zone["Karazhan"] = "799:1";
CT_UserMap_Zone["Magtheridon's Lair"] = "779:1";
CT_UserMap_Zone["Serpentshrine Cavern"] = "780:1";
CT_UserMap_Zone["Sunwell Plateau"] = "789:1";
CT_UserMap_Zone["The Eye"] = "782:1";

-- Wrath Dungeons
CT_UserMap_Zone["Ahn'kahet: The Old Kingdom"] = "522:1";
CT_UserMap_Zone["Azjol-Nerub"] = "533:1";
CT_UserMap_Zone["Drak'Tharon Keep"] = "534:1";
CT_UserMap_Zone["Gundrak"] = "530:1";
CT_UserMap_Zone["Halls of Lightning"] = "525:1";
CT_UserMap_Zone["Halls of Reflection"] = "603:1";
CT_UserMap_Zone["Halls of Stone"] = "526:1";
CT_UserMap_Zone["Pit of Saron"] = "602:1";
CT_UserMap_Zone["The Culling of Stratholme"] = "521:1";
CT_UserMap_Zone["The Forge of Souls"] = "601:1";
CT_UserMap_Zone["The Nexus"] = "520:1";
CT_UserMap_Zone["The Oculus"] = "528:1";
CT_UserMap_Zone["The Violet Hold"] = "536:1";
CT_UserMap_Zone["Trial of the Champion"] = "542:1";
CT_UserMap_Zone["Utgarde Keep"] = "523:1";
CT_UserMap_Zone["Utgarde Pinnacle"] = "524:1";

-- Wrath Raids
CT_UserMap_Zone["Icecrown Citadel"] = "604:1";
CT_UserMap_Zone["Naxxramas"] = "535:1";
CT_UserMap_Zone["Onyxia's Lair"] = "718:1";
CT_UserMap_Zone["The Eye of Eternity"] = "527:1";
CT_UserMap_Zone["The Obsidian Sanctum"] = "531:1";
CT_UserMap_Zone["The Ruby Sanctum"] = "609:1";
CT_UserMap_Zone["Trial of the Crusader"] = "543:1";
CT_UserMap_Zone["Ulduar"] = "529:1";
CT_UserMap_Zone["Vault of Archavon"] = "532:1";

-- Cataclysm Dungeons
CT_UserMap_Zone["Blackrock Caverns"] = "753:1";
CT_UserMap_Zone["End Time"] = "820:1";
CT_UserMap_Zone["Grim Batol"] = "757:1";
CT_UserMap_Zone["Halls of Origination"] = "759:1";
CT_UserMap_Zone["Hour of Twilight"] = "819:1";
CT_UserMap_Zone["Lost City of the Tol'vir"] = "747:1";
CT_UserMap_Zone["The Stonecore"] = "768:1";
CT_UserMap_Zone["The Vortex Pinnacle"] = "769:1";
CT_UserMap_Zone["Throne of the Tides"] = "767:1";
CT_UserMap_Zone["Well of Eternity"] = "816:1";
CT_UserMap_Zone["Zul'Aman"] = "781:1";
CT_UserMap_Zone["Zul'Gurub"] = "793:1";

-- Cataclysm Raids
CT_UserMap_Zone["Baradin Hold"] = "752:1";
CT_UserMap_Zone["Blackwing Descent"] = "754:1";
CT_UserMap_Zone["Dragon Soul"] = "824:1";
CT_UserMap_Zone["Firelands"] = "800:1";
CT_UserMap_Zone["The Bastion of Twilight"] = "758:1";
CT_UserMap_Zone["Throne of the Four Winds"] = "773:1";

-- Pandaria Dungeons
CT_UserMap_Zone["Gate of the Setting Sun"] = "875:1";
CT_UserMap_Zone["Mogu'Shan Palace"] = "885:1";
CT_UserMap_Zone["Scarlet Halls"] = "871:1";
CT_UserMap_Zone["Scarlet Monastery"] = "874:1";
CT_UserMap_Zone["Scholomance"] = "898:1";
CT_UserMap_Zone["Shado-pan Monastery"] = "877:1";
CT_UserMap_Zone["Siege of Niuzao Temple"] = "887:1";
CT_UserMap_Zone["Stormstout Brewery"] = "876:1";
CT_UserMap_Zone["Temple of the Jade Serpent"] = "867:1";

-- Pandaria Raids
CT_UserMap_Zone["Heart of Fear"] = "897:1";
CT_UserMap_Zone["Mogu'shan Vaults"] = "896:1";
CT_UserMap_Zone["Siege of Orgrimmar"] = "953:1";
CT_UserMap_Zone["Terrace of Endless Spring"] = "886:1";
CT_UserMap_Zone["Throne of Thunder"] = "930:1";

-- Draenor Dungeons
CT_UserMap_Zone["Auchindoun"] = "984:1";
CT_UserMap_Zone["Bloodmaul Slag Mines"] = "964:1";
CT_UserMap_Zone["Grimrail Depot"] = "993:1";
CT_UserMap_Zone["Iron Docks"] = "987:1";
CT_UserMap_Zone["Shadowmoon Burial Grounds"] = "969:1";
CT_UserMap_Zone["Skyreach"] = "989:1";
CT_UserMap_Zone["The Everbloom"] = "1008:1";
CT_UserMap_Zone["Upper Blackrock Spire"] = "995:1";

-- Draenor Raids
CT_UserMap_Zone["Highmaul"] = "994:1";
CT_UserMap_Zone["Blackrock Foundry"] = "988:1";
CT_UserMap_Zone["Hellfire Citadel"] = "1026:1";

-- Legion Dungeons
CT_UserMap_Zone["Black Rook Hold"] = "1081:1";
CT_UserMap_Zone["Cathedral of Eternal Night"] = "1146:1";
CT_UserMap_Zone["Court of Stars"] = "1087:1";
CT_UserMap_Zone["Darkheart Thicket"] = "1067:1";
CT_UserMap_Zone["Eye of Azshara"] = "1046:1";
CT_UserMap_Zone["Halls of Valor"] = "1041:1";
CT_UserMap_Zone["Maw of Souls"] = "1042:1";
CT_UserMap_Zone["Neltharion's Lair"] = "1065:1";
CT_UserMap_Zone["Return to Karazhan"] = "1115:1";
CT_UserMap_Zone["The Arcway"] = "1079:1";
CT_UserMap_Zone["Vault of the Wardens"] = "1045:1";
CT_UserMap_Zone["Violet Hold"] = "1066:1";

-- Legion Raids
CT_UserMap_Zone["The Emerald Nightmare"] = "1094:1";
CT_UserMap_Zone["Trial of Valor"] = "1114:1";
CT_UserMap_Zone["The Nighthold"] = "1088:1";
CT_UserMap_Zone["Tomb of Sargeras"] = "1147:1";



CT_MapMod_Options = {};

-- Do not change the order of the items in this table
CT_UserMap_Icons = {
	"GreyNote",
	"BlueShield",
	"RedDot",
	"WhiteCircle",
	"GreenSquare",
	"RedCross",
	"Herb",
	"Ore",
};

-- Do not change the order of the items in this table
-- These are the names of the .tga files in the Resource folder.
CT_UserMap_HerbIcons = {
	"Herb_Bruiseweed", -- 1
	"Herb_ArthasTears", -- 2
	"Herb_BlackLotus", -- 3
	"Herb_Blindweed", -- 4
	"Herb_Briarthorn", -- 5
	"Herb_Dreamfoil", -- 6
	"Herb_Earthroot", -- 7
	"Herb_Fadeleaf", -- 8
	"Herb_Firebloom", -- 9
	"Herb_GhostMushroom", -- 10
	"Herb_GoldenSansam", -- 11
	"Herb_Goldthorn", -- 12
	"Herb_GraveMoss", -- 13
	"Herb_Gromsblood", -- 14
	"Herb_Icecap", -- 15
	"Herb_KhadgarsWhisker", -- 16
	"Herb_Kingsblood", -- 17
	"Herb_Liferoot", -- 18
	"Herb_Mageroyal", -- 19
	"Herb_MountainSilversage", -- 20
	"Herb_Peacebloom", -- 21
	"Herb_Plaguebloom", -- 22
	"Herb_PurpleLotus", -- 23
	"Herb_Silverleaf", -- 24
	"Herb_Stranglekelp", -- 25
	"Herb_Sungrass", -- 26
	"Herb_Swiftthistle", -- 27
	"Herb_WildSteelbloom", -- 28
	"Herb_Wintersbite", -- 29
	"Herb_DreamingGlory", -- 30
	"Herb_Felweed", -- 31
	"Herb_FlameCap", -- 32
	"Herb_ManaThistle", -- 33
	"Herb_Netherbloom", -- 34
	"Herb_NetherdustBush", -- 35
	"Herb_NightmareVine", -- 36
	"Herb_Ragveil", -- 37
	"Herb_Terocone", -- 38
	"Herb_AddersTongue", -- 39
	"Herb_FrostLotus", -- 40
	"Herb_Goldclover", -- 41
	"Herb_Icethorn", -- 42
	"Herb_Lichbloom", -- 43
	"Herb_TalandrasRose", -- 44
	"Herb_TigerLily", -- 45
	"Herb_FrozenHerb", -- 46
	-- Cataclysm
	"Herb_Sorrowmoss",  -- 47 Formerly known as Plaugebloom. Same icon.
	"Herb_DragonsTeeth",  -- 48 Formerly known as Wintersbite. New icon in 4.0.6.
	"Herb_AzsharasVeil", -- 49
	"Herb_Cinderbloom", -- 50
	"Herb_Heartblossom", -- 51
	"Herb_Stormvine", -- 52
	"Herb_TwilightJasmine", -- 53
	"Herb_Whiptail", -- 54
	-- Mists of Pandaria
	"Herb_FoolsCap", -- 55
	"Herb_GoldenLotus", -- 56
	"Herb_GreenTeaLeaf", -- 57
	"Herb_RainPoppy", -- 58
	"Herb_ShaHerb", -- 59
	"Herb_Silkweed", -- 60
	"Herb_SnowLily", -- 61
};

-- Do not change the order of the items in this table
-- These are the names of the .tga files in the Resource folder.
CT_UserMap_OreIcons = {
	"Ore_CopperVein", -- 1
	"Ore_GoldVein", -- 2
	"Ore_IronVein", -- 3
	"Ore_MithrilVein", -- 4
	"Ore_SilverVein", -- 5
	"Ore_ThoriumVein", -- 6
	"Ore_TinVein", -- 7
	"Ore_TruesilverVein", -- 8
	"Ore_AdamantiteVein", -- 9
	"Ore_FelIronVein", -- 10
	"Ore_KhoriumVein", -- 11
	"Ore_CobaltVein", -- 12
	"Ore_SaroniteVein", -- 13
	"Ore_TitaniumVein", -- 14
	-- Cataclysm
	"Ore_Elementium", -- 15
	"Ore_Obsidian", -- 16
	"Ore_Pyrite", -- 17
	-- Mists of Pandaria
	"Ore_GhostIron", -- 18
	"Ore_Kyparite", -- 19
	"Ore_Trillium", -- 20
};

local CT_UserMap_NoteButtons = 0;

local unlockCoord;

---------------------------------------------
-- Miscellaneous

CT_MapMod_Print = ( CT_Print or function(msg, r, g, b) DEFAULT_CHAT_FRAME:AddMessage(msg, r, g,b) end );

local function round(num, dec)
	local mult = 10 ^ (dec or 0);
	if (mult == 0) then
		return 0;
	end
	return math.floor(num * mult + 0.5) / mult;
end

local function CT_MapMod_GetCharKey()
	-- Get the current character's name key (combination of player name and server name).
	local characterKey = UnitName("player") .. "@" .. GetRealmName();

	-- autoGather == (1 or nil) -- No longer used in 4.0100
	-- autoHerbs ==  (true or false) -- Added in 4.0100
	-- autoMinerals  (true or false) -- Added in 4.0100
	-- hideGroups == (table)
	-- receiveNotes == Player can receive notes
	-- mainPos1 == Position of the notes button on the full size map.
	-- mainPos2 == Position of the notes button on the small size map.
	-- countPos1 == Position of the note count text relative to notes button on full size map (1==Left, 2==Top, 3==Right, 4==Bottom).
	-- countPos2 == Position of the note count text relative to notes button on small size map (1==Left, 2==Top, 3==Right, 4==Bottom).
	-- coordPos1 == Position of the coordinates frame on the full size map.
	-- coordPos2 == Position of the coordinates frame on the small size map.
	-- coordHide1 == Hide the coordinates frame on the full size map.
	-- coordHide2 == Hide the coordinates frame on the small size map.
	-- hideMainTooltip == Hide the Notes button tooltip.

	if ( not CT_MapMod_Options[characterKey] ) then
		CT_MapMod_Options[characterKey] = {
			autoHerbs = true,
			autoMinerals = true,
			hideGroups = {},
			-- receiveNotes = nil,
			-- mainPos1 = nil,
			-- mainPos2 = nil,
			-- countPos1 = nil,
			-- countPos2 = nil,
			-- coordPos1 = nil,
			-- coordPos2 = nil,
			-- coordHide1 = nil,
			-- coordHide2 = nil,
			-- hideMainTooltip = nil,
		};
	end

	return UnitName("player") .. "@" .. GetRealmName();
end


-- Completely overhauled.  Returns the mapID of an outdoor zone; or mapID:dungeonLevel of multi-level zones.
local function CT_MapMod_GetMapName()
	local mapID, isContinent = GetCurrentMapAreaID();
	local dungeonLevel, y2, y3, y4, y5 = GetCurrentMapDungeonLevel();
	if (isContinent or not mapID or mapID < 0) then
		return false;
	end
	return mapID .. ":" .. dungeonLevel;
end

local function CT_MapMod_IsDialogShown()
	-- Is a dialog window currently being shown?
	if (CT_MapMod_NoteWindow:IsShown() or CT_MapMod_FilterWindow:IsShown()) then
		return true;
	end
	return false;
end

local function CT_MapMod_GetMapSizeNumber(value)
	local mapSize;
	if (value == "max") then
		return 2;
	end
	if ( WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE ) then
		-- Small size world map
		mapSize = 2;
	else
		-- Full size world map
		mapSize = 1;
	end
	return mapSize;
end

local function CT_MapMod_anchorFrame(ancFrame)
	-- Set the BOTTOMLEFT anchor point of a frame relative to
	-- the BOTTOMLEFT of the appropriate world map frame.
	local relFrame;
	if ( WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE ) then
		-- Small size world map
		relFrame = WorldMapDetailFrame;
	else
		-- Full screen size world map
		relFrame = WorldMapDetailFrame;
	end

	local ancFrameScale, ancFrameBottom, ancFrameLeft;
	ancFrameScale = (ancFrame:GetEffectiveScale() or 1);
	ancFrameBottom = (ancFrame:GetBottom() or 0) * ancFrameScale;
	ancFrameLeft = (ancFrame:GetLeft() or 0) * ancFrameScale;

	local relScale, relBottom, relLeft;
	relScale = (relFrame:GetEffectiveScale() or 1);
	relBottom = (relFrame:GetBottom() or 0) * relScale;
	relLeft = (relFrame:GetLeft() or 0) * relScale;

	local xOffset, yOffset;
	if (ancFrameScale == 0) then
		yOffset = 0;
		xOffset = 0;
	else
		yOffset = (ancFrameBottom - relBottom) / ancFrameScale;
		xOffset = (ancFrameLeft - relLeft) / ancFrameScale;
	end

	ancFrame:ClearAllPoints();
	ancFrame:SetPoint("BOTTOMLEFT", relFrame, "BOTTOMLEFT", xOffset, yOffset);
end

local function CT_MapMod_GetCursorMapPosition()
	local button = WorldMapButton;
	local x, y = GetCursorPosition();
	local scale = button:GetEffectiveScale();
	if (scale == 0) then
		x = 0;
		y = 0;
	else
		x = x / scale;
		y = y / scale;
	end
	local centerX, centerY = button:GetCenter();
	local width = button:GetWidth();
	local height = button:GetHeight();
	local adjustedY, adjustedX;
	if (height == 0) then
		adjustedY = 0;
	else
		adjustedY = (centerY + (height/2) - y) / height;
	end
	if (width == 0) then
		adjustedX = 0;
	else
		adjustedX = (x - (centerX - (width/2))) / width;
	end
	if (adjustedX < 0) then
		adjustedX = 0;
	elseif (adjustedX > 1) then
		adjustedX = 1;
	end
	if (adjustedY < 0) then
		adjustedY = 0;
	elseif (adjustedY > 1) then
		adjustedY = 1;
	end
	return adjustedX, adjustedY;
end

local function CT_MapMod_AdjustPositions()
	-- Adjust position of certain elements based on the size of the world map window.
	CT_MapMod_MainButton_RestorePosition();
	CT_MapMod_MainButton_SetCountPosition();
	CT_MapMod_Coord_RestorePosition();
	CT_MapMod_ShowHideCoord();
end

local function CT_MapMod_FindResourceIcon(oldName, prefix)
	if ( prefix == "Ore_" ) then
		local n, endPoint;
		-- Remove the trailing word and set it to "Vein" (we want it
		-- to match the names of the .tga files in the Resource folder).
		n, n, endPoint = string.find(oldName, "(.+)%sVein$");
		if ( endPoint ) then
			oldName = endPoint .. "Vein";
		else
			n, n, endPoint = string.find(oldName, "(.+)%sDeposit$");
			if ( endPoint ) then
				oldName = endPoint .. "Vein";
			else
				n, n, endPoint = string.find(oldName, "(.+)%sNode$");
				if ( endPoint ) then
					oldName = endPoint .. "Vein";
				end
			end
		end
		-- Remove any "Small " prefix
		n, n, endPoint = string.find(oldName, "^Small%s(.+)");
		if ( endPoint ) then
			oldName = endPoint;
		end
		-- Remove any "Rich " prefix
		n, n, endPoint = string.find(oldName, "^Rich%s(.+)");
		if ( endPoint ) then
			oldName = endPoint;
		end
	end
	-- Strip out everything except alphanumeric characters
	local name = "";
	for i = 1, strlen(oldName), 1 do
		local l = strsub(oldName, i, i);
		if ( string.find(l, "%w") ) then
			name = name .. l;
		end
	end
	-- Determine icon number
	local icons;
	if ( prefix == "Ore_" ) then
		icons = CT_UserMap_OreIcons;
	elseif ( prefix == "Herb_" ) then
		icons = CT_UserMap_HerbIcons;
	else
		return 1;
	end
	for k, v in pairs(icons) do
		if ( v == prefix .. name ) then
			return k;
		end
	end
	return 1;
end

---------------------------------------------
-- Notes

local function CT_MapMod_CanCreateNoteOnPlayer()
	-- Can the user create a note on the player's position?
	local canCreate = false;
	local mapName = CT_MapMod_GetMapName();
	-- If we have a name for the zone and user is not looking at a dialog window...
	if (mapName and not CT_MapMod_IsDialogShown()) then
		-- Only allow if user is looking at the map of the zone they are in.
		local x, y = GetPlayerMapPosition("player");
		if (x and y and not (x == 0 and y == 0)) then
			canCreate = true;
		end
	end
	return canCreate;
end

local function CT_MapMod_CreateNoteButton()
	-- Create a new note button.
	local id = CT_UserMap_NoteButtons + 1;
	local note = CreateFrame("BUTTON", "CT_UserMap_Note" .. id, CT_MapMod_MapButtonFrame, "CT_MapMod_NoteTemplate");
	note:SetID(id);
	CT_UserMap_NoteButtons = id;
end

local function CT_MapMod_HideNotes(first, last)
	-- Hide a range of notes.
	if (not first) then
		first = 1;
	end
	if (not last) then
		last = CT_UserMap_NoteButtons;
	end
	for i = first, last, 1 do
		_G["CT_UserMap_Note" .. i]:Hide();
	end
end

local function CT_MapMod_UpdateMap()
	-- Update the world map.
	local notes, mapName;
	local characterKey;
	local count;

	CT_MapMod_AdjustPositions();

	mapName = CT_MapMod_GetMapName();
	if ( mapName ) then
		notes = CT_UserMap_Notes[mapName];
	end
	if ( not mapName or not notes ) then
		CT_MapMod_HideNotes(1, CT_UserMap_NoteButtons);
		CT_NumNotes:SetText("|c00FFFFFF0|r/|c00FFFFFF0|r");
		return;
	end
	characterKey = CT_MapMod_GetCharKey();

	-- Calculate what notes to show
	count = 1;
	for i, var in pairs(notes) do
		if (
			-- If not hiding this set of notes, and
			not CT_MapMod_Options[characterKey].hideGroups[(CT_MAPMOD_SETS[(var.set or 1)])] and
			(
				-- not filtering the notes, or
				not CT_MapMod_Filter or

				-- we are filtering the notes and the note's name matches the filter pattern, or
				string.find(strlower(var.name), strlower(CT_MapMod_Filter)) or

				-- we are filtering the notes and the note's description matches the filter pattern
				string.find(strlower(var.descript), strlower(CT_MapMod_Filter))
			)
		) then
			local note;
			local IconTexture;

			if ( count > CT_UserMap_NoteButtons ) then
				CT_MapMod_CreateNoteButton();
			end

			note = _G["CT_UserMap_Note" .. count];
			IconTexture = _G["CT_UserMap_Note" .. count .."Icon"];

			if ( var.set == 7 ) then
				-- Herbalism notes.
				-- If icon is 1 and the name is not what the default was, then try correcting the icon.
				if (var.icon == 1 and var.name and string.lower(var.name) ~= "bruiseweed") then
					var.icon = CT_MapMod_FindResourceIcon(var.name, "Herb_")
				end
				if ( CT_UserMap_HerbIcons[var.icon] ) then
					IconTexture:SetTexture("Interface\\AddOns\\CT_MapMod\\Resource\\" .. CT_UserMap_HerbIcons[var.icon]);
				else
					IconTexture:SetTexture("Interface\\AddOns\\CT_MapMod\\Resource\\Herb_Bruiseweed");
				end
			elseif ( var.set == 8 ) then
				-- Mining notes.
				-- If icon is 1 and the name is not what the default was, then try correcting the icon.
				if (var.icon == 1 and var.name and string.lower(var.name) ~= "copper vein") then
					var.icon = CT_MapMod_FindResourceIcon(var.name, "Ore_")
				end
				if ( CT_UserMap_OreIcons[var.icon] ) then
					IconTexture:SetTexture("Interface\\AddOns\\CT_MapMod\\Resource\\" .. CT_UserMap_OreIcons[var.icon]);
				else
					IconTexture:SetTexture("Interface\\AddOns\\CT_MapMod\\Resource\\Ore_CopperVein");
				end
			else
				IconTexture:SetTexture("Interface\\AddOns\\CT_MapMod\\Skin\\" .. CT_UserMap_Icons[var.set]);
			end
			note:SetPoint("CENTER", "WorldMapDetailFrame", "TOPLEFT", var.x * WorldMapButton:GetWidth(), -var.y * WorldMapButton:GetHeight());
			note:Show();

			if ( not var.name ) then
				var.name = "";
			end
			if ( not var.set or not CT_MAPMOD_SETS[var.set] ) then
				var.set = 1;
			end
			if ( not var.descript ) then
				var.descript = "";
			end

			note.name = var.name;
			note.set = CT_MAPMOD_SETS[var.set];
			note.descript = var.descript;
			note.id = i;
			note.x = var.x;
			note.y = var.y;

			count = count + 1;
		end
	end

	-- The number of notes currently displayed on this map / The total number of notes on this map
	CT_NumNotes:SetText("|c00FFFFFF" .. (count - 1) .. "|r/|c00FFFFFF" .. (#notes) .. "|r");

	-- Hide all other notes on this map
	CT_MapMod_HideNotes(count, CT_UserMap_NoteButtons);
end

local function CT_MapMod_ExecuteFilter(filter)
	CT_MapMod_Filter = filter;
	CT_MapMod_UpdateMap();
end

local function CT_MapMod_FindNote(zone, x, y)
	-- Look up note in zone at specified x,y location.
	local notes = CT_UserMap_Notes[zone];
	x = tonumber(x);
	y = tonumber(y);
	if (notes) then
		for num, note in ipairs(notes) do
			if ( abs(note.x - x) <= 0.0000000005 and abs(note.y - y) <= 0.0000000005 ) then
				return num;
			end
		end
	end
	return nil;
end

local function CT_MapMod_AddNote(x, y, zone, text, descript, icon, set)
	-- Add a note to the map (or change existing one at the same x,y location).
	local group;
	if ( tonumber(set) ) then
		group = tonumber(set);
	else
		group = set;
	end

	local notes = CT_UserMap_Notes[zone];
	if ( not notes ) then
		notes = {};
		CT_UserMap_Notes[zone] = notes;
	end

	-- If there is already a note at this x,y location...
	local found = CT_MapMod_FindNote(zone, x, y);
	if (found) then
		-- Update existing note.
		local temp = notes[found];
		temp.name = text;
		temp.descript = descript;
		temp.icon = icon;
		temp.set = group;
		CT_MapMod_UpdateMap();
		return found;
	else
		-- Add new note.
		local temp = { x = x, y = y, name = text, descript = descript, icon = icon, set = group };
		tinsert(notes, temp);
		CT_MapMod_UpdateMap();
		return #notes;
	end
end

local function CT_MapMod_EditNote(id)
	local mapName = CT_MapMod_GetMapName();
	if (mapName) then
		if (not id) then
			local notes = CT_UserMap_Notes[mapName];
			if (notes) then
				id = #(notes);
			else
				id = 0;
			end
		end

		if (id > 0) then
			CT_MapMod_NoteWindow.note = id;
			CT_MapMod_NoteWindow.zone = mapName;
			CT_MapMod_NoteWindow_Show();
		end
	end
end

function CT_MapMod_CreateNote(x, y, note)
	local mapName = CT_MapMod_GetMapName();
	if (mapName and x and y and x > 0 and x < 100 and y > 0 and y < 100) then
		if not note then
			note = "New note"
		end
		local id = CT_MapMod_AddNote(x / 100, y / 100, mapName, note, "", 1, 1);
		CT_MapMod_NoteWindow.note = id;
		CT_MapMod_NoteWindow.zone = mapName;
		CT_MapMod_NoteWindow_Show();
		CT_MapMod_NoteWindow_Accept()
	end

end

local function CT_MapMod_CreateNoteOnCursor()
	-- Create a new note at the cursor position.
	local mapName = CT_MapMod_GetMapName();
	if (mapName) then
		local x, y = CT_MapMod_GetCursorMapPosition();
		local id = CT_MapMod_AddNote(x, y, mapName, "New note at cursor", "", 1, 1);
		CT_MapMod_NoteWindow.note = id;
		CT_MapMod_NoteWindow.zone = mapName;
		CT_MapMod_NoteWindow_Show();
	end
end

local function CT_MapMod_CreateNoteOnPlayer()
	-- Create a new note on the player's position.
	local x, y = GetPlayerMapPosition("player");
	if (not (x == 0 and y == 0)) then
		local mapName = CT_MapMod_GetMapName();
		if (mapName) then
			local id = CT_MapMod_AddNote(x, y, mapName, "New note at player", "", 1, 1);
			CT_MapMod_NoteWindow.note = id;
			CT_MapMod_NoteWindow.zone = mapName;
			CT_MapMod_NoteWindow_Show();
		end
	end
end

function CT_MapMod_OnNoteOver(self)
	-- Mouse is over a note on the map.

	-- Have to do this in order to be able to see our note's tooltip.
	WorldMapPOIFrame.allowBlobTooltip = false;

	-- Display the note's tooltip.
	local x, y = self:GetCenter();
	local parentX, parentY = WorldMapButton:GetCenter();
	if ( x > parentX ) then
		WorldMapTooltip:SetOwner(self, "ANCHOR_LEFT");
	else
		WorldMapTooltip:SetOwner(self, "ANCHOR_RIGHT");
	end
	WorldMapTooltip:ClearLines();
	WorldMapTooltip:AddDoubleLine(self.name, self.set, 0, 1, 0, 0.6, 0.6, 0.6);
	if ( self.descript ) then
		WorldMapTooltip:AddLine(self.descript, nil, nil, nil, 1);
	end
	WorldMapTooltip:AddLine("Right-click to edit.", 0, 0.5, 0.9, 1);
	WorldMapTooltip:Show();
end

function CT_MapMod_OnNoteLeave(self)
	-- Mouse is leaving a note.

	-- Undo what we did in CT_MapMod_OnNoteOver()
	WorldMapPOIFrame.allowBlobTooltip = true;

	-- Hide the note's tooltip.
	WorldMapTooltip:Hide();
end

function CT_MapMod_OnClick(self, btn)
	-- User clicked a note on the map
	if ( btn == "LeftButton" ) then
		return;
	end
	CT_MapMod_EditNote(self.id);
end

---------------------------------------------
-- Note window

function CT_MapMod_NoteWindow_OnLoad(self)
	self.note = -1;
	-- Set names
	CT_MapMod_NoteWindowTitle:SetText(CT_MAPMOD_TEXT_TITLE);
	CT_MapMod_NoteWindowNameText:SetText(CT_MAPMOD_TEXT_NAME);
	CT_MapMod_NoteWindowDescriptText:SetText(CT_MAPMOD_TEXT_DESC);
	CT_MapMod_NoteWindowGroupText:SetText(CT_MAPMOD_TEXT_GROUP);
	CT_MapMod_NoteWindowSendText:SetText(CT_MAPMOD_TEXT_SEND);
	CT_MapMod_NoteWindowOkayButton:SetText(CT_MAPMOD_BUTTON_OKAY);
	CT_MapMod_NoteWindowCancelButton:SetText(CT_MAPMOD_BUTTON_CANCEL);
	CT_MapMod_NoteWindowDeleteButton:SetText(CT_MAPMOD_BUTTON_DELETE);
	CT_MapMod_NoteWindowEditButton:SetText(CT_MAPMOD_BUTTON_EDITGROUPS);
	CT_MapMod_NoteWindowSendButton:SetText(CT_MAPMOD_BUTTON_SEND);
end

local notewindowDropDownInitialized;
function CT_MapMod_NoteWindow_Show()
	CT_MapMod_NoteWindow:SetFrameStrata("DIALOG")
	if (not notewindowDropDownInitialized) then
		-- We're delaying the initialization of the dropdown menus until as late as possible
		-- to make sure that Blizzard has had time to create CompactRaidFrame1.
		-- At this time (2012-08-29), if you create a drop down menu containing 8 or more buttons before
		-- CompactRaidFrame1 gets created, CompactRaidFrame1 will be tainted when it gets created.
		CT_MapMod_NoteWindow_GroupDropDown_OnLoad(CT_MapMod_NoteWindowGroupDropDown);
		notewindowDropDownInitialized = true;
	end
	CT_MapMod_NoteWindow:Show();
end

function CT_MapMod_NoteWindow_OnShow(self)
	-- The note window is being shown.
	CT_MapMod_MapButtonFrame:Hide();
	CT_MapMod_MainButton:Disable();

	local note = CT_UserMap_Notes[self.zone][self.note];

	CT_MapMod_NoteWindowNameEB:SetText(note.name);
	CT_MapMod_NoteWindowNameEB:HighlightText();

	CT_MapMod_NoteWindowDescriptEB:SetText(note.descript);

	CT_MapMod_NoteWindowSendButton:Disable();

	CT_MapMod_NoteWindowSendEB.lastsend = "";
	CT_MapMod_NoteWindowSendEB:SetText("");

	PlaySound(1115);
end

function CT_MapMod_NoteWindow_OnHide(self)
	-- The note window is being hidden.
	CT_MapMod_MapButtonFrame:Show();
	CT_MapMod_MainButton:Enable();

	PlaySound(1115);
end

function CT_MapMod_NoteWindow_Accept()
	-- Accept the note information.
	local name, descript, set, icon;
	local zoneKey, noteKey;
	local note;

	-- Get information from the note window
	zoneKey = CT_MapMod_NoteWindow.zone;
	noteKey = CT_MapMod_NoteWindow.note;

	note = CT_UserMap_Notes[zoneKey][noteKey];

	name = CT_MapMod_NoteWindowNameEB:GetText();
	descript = CT_MapMod_NoteWindowDescriptEB:GetText();

	icon = note.icon;

	if ( L_UIDropDownMenu_GetSelectedName(CT_MapMod_NoteWindowGroupDropDown) ) then
		set = note.set;
	else
		set = L_UIDropDownMenu_GetSelectedID( CT_MapMod_NoteWindowGroupDropDown );
	end

	-- Update the note
	note.name = name;
	note.descript = descript;
	note.set = set;
	note.icon = icon;

	CT_MapMod_NoteWindow:Hide();
	CT_MapMod_UpdateMap();
end

function CT_MapMod_NoteWindow_Cancel()
	-- Cancel the note editing.
	CT_MapMod_NoteWindow:Hide();
end

function CT_MapMod_NoteWindow_Delete()
	-- Delete the note
	local zoneKey = CT_MapMod_NoteWindow.zone;
	local noteKey = CT_MapMod_NoteWindow.note;

	tremove(CT_UserMap_Notes[zoneKey], noteKey);

	CT_MapMod_NoteWindow:Hide();
	CT_MapMod_UpdateMap();
end

function CT_MapMod_NoteWindow_GroupDropDown_OnClick(self)
	-- User clicked on an item in the group menu.
	L_UIDropDownMenu_SetSelectedID(CT_MapMod_NoteWindowGroupDropDown, self:GetID(), 1);
end

function CT_MapMod_NoteWindow_GroupDropDown_OnShow()
	-- The group menu is being displayed (not actually called until note window is being shown).
	local zoneKey = CT_MapMod_NoteWindow.zone;
	local noteKey = CT_MapMod_NoteWindow.note;
	if ( zoneKey and noteKey ) then
		local note = CT_UserMap_Notes[zoneKey][noteKey];
		local set = note.set;
		if ( tonumber(set) and tonumber(set) == set ) then
			L_UIDropDownMenu_SetSelectedName(CT_MapMod_NoteWindowGroupDropDown, CT_MAPMOD_SETS[set], nil);
		else
			L_UIDropDownMenu_SetSelectedName(CT_MapMod_NoteWindowGroupDropDown, set, nil);
		end
		L_UIDropDownMenu_SetText(CT_MapMod_NoteWindowGroupDropDown, CT_MAPMOD_SETS[set]);
	end
end

function CT_MapMod_NoteWindow_GroupDropDown_Initialize(self)
	-- Initialize the group menu.
	for key, val in pairs(CT_MAPMOD_SETS) do
		local info = {};
		info.text = val;
		info.value = val;
		info.owner = self;
		info.func = CT_MapMod_NoteWindow_GroupDropDown_OnClick;
		L_UIDropDownMenu_AddButton(info);
	end
end

function CT_MapMod_NoteWindow_GroupDropDown_OnLoad(self)
	-- The group menu is being loaded.
	L_UIDropDownMenu_Initialize(self, CT_MapMod_NoteWindow_GroupDropDown_Initialize);
	L_UIDropDownMenu_SetWidth(self, 130);
end

---------------------------------------------
-- Filter window

function CT_MapMod_FilterWindow_OnLoad(self)
	-- Set names
	CT_MapMod_FilterWindowTitleText:SetText("Notes Filter");
	CT_MapMod_FilterWindowOkayButton:SetText(CT_MAPMOD_BUTTON_OKAY);
	CT_MapMod_FilterWindowCancelButton:SetText(CT_MAPMOD_BUTTON_CANCEL);
end

function CT_MapMod_FilterWindow_OnShow(self)
	-- The filter window is being shown.
	CT_MapMod_MapButtonFrame:Hide();
	CT_MapMod_MainButton:Disable();

	self:SetFrameStrata("DIALOG")

	local eb = CT_MapMod_FilterWindowFilterEB;
	eb:SetText(CT_MapMod_Filter or "");
	eb:HighlightText();

	PlaySound(1115);
end

function CT_MapMod_FilterWindow_OnHide(self)
	-- The filter window is being hidden.
	CT_MapMod_MapButtonFrame:Show();
	CT_MapMod_MainButton:Enable();

	PlaySound(1115);
end

function CT_MapMod_FilterWindow_Accept()
	-- Accept the filter window information.
	local eb = CT_MapMod_FilterWindowFilterEB;
	CT_MapMod_ExecuteFilter(eb:GetText() or "");
	CT_MapMod_FilterWindow:Hide();
end

function CT_MapMod_FilterWindow_Cancel()
	-- Cancel editing the filter.
	CT_MapMod_FilterWindow:Hide();
end

---------------------------------------------
-- Sending notes

local CT_LastIncMessage = {};
local CT_LastOutMessage = {};

local function CT_MapMod_EnableReceiveNotes(enable)
	local characterKey = CT_MapMod_GetCharKey();
	if (enable) then
		enable = 1;
	else
		enable = nil;
	end
	CT_LastIncMessage.msg = nil;
	CT_LastIncMessage.user = nil;
	CT_MapMod_Options[characterKey].receiveNotes = enable;
end

local function CT_MapMod_ProcessWhisper(self, event, msg, user)
	-- Process incoming whispers.
	-- Return nil to allow the game to continue processing the message (should show up in chat window).
	-- Return true to prevent the message from being processed any further (won't show up in chat window).

	if (not msg) then
		return nil;
	end

	-- Examine the message
	if (strsub(msg, 1, 7) ~= "<CTMod>") then
		return nil;
	end
	local pos1, pos2, xpos, ypos, zone, name, descript, group, icon = string.find(msg, "^<CTMod> New map note received: x=(.+); y=(.+); z=(%d+:%d+); n=(.*); d=(.*); g=(.+); i=(.+);$");

	if (not zone) then
		return nil;
	end
	if (not descript) then
		descript = "Received from " .. user;
	end


	-- If this is the same as the last incoming message we processed...
	if (msg == CT_LastIncMessage.msg and CT_LastIncMessage.user == user) then
		-- Will happen if user has multiple chat frames that trap whispers.
		-- Will happen if user is sent the same whisper twice in a row.
		return true;  -- true == don't show whisper in chat frame
	end

	-- Remember this message for next time.
	CT_LastIncMessage.msg = msg;
	CT_LastIncMessage.user = user;

	-- Add the note and inform the user.
	local characterKey = CT_MapMod_GetCharKey();

	if ( not CT_MapMod_Options[characterKey].receiveNotes ) then
		module:printcolor(1.0, 0.5, 0.0, "<CTMapMod> Blocked incoming map note from " .. user .. ".");
	else
		module:printcolor(1.0, 0.5, 0.0, "<CTMapMod> Map note received from " .. user .. ".");
		if (strsub(zonename, 1, 1) ~= "(") then
			-- Add the note to the map
			CT_MapMod_AddNote(xpos, ypos, zone, name, descript, tonumber(icon), group);
		end
	end
	return true;  -- true == don't show whisper in chat frame
end

-- Add a chat message filter so we can intercept incoming whispers involving CT_MapMod notes.
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", CT_MapMod_ProcessWhisper);

local function CT_MapMod_ProcessOutgoingWhisper(self, event, msg, user)
	-- Process outgoing whispers.
	-- Return nil to allow the game to continue processing the message (should show up in chat window).
	-- Return true to prevent the message from being processed any further (won't show up in chat window).
	if (not msg) then
		return nil;
	end
	-- Examine the message
	if (strsub(msg, 1, 7) ~= "<CTMod>") then
		return nil;
	end
	local pos1, pos2, xpos, ypos, zone = string.find(msg, "^<CTMod> New map note received: x=(.+); y=(.+); z=(%d+:%d+); n=.*; d=.*; g=.+; i=.+;$");
	if (not zone) then
		return nil;
	end

	-- If this is the same as the last outgoing message we processed...
	if (msg == CT_LastOutMessage.msg and CT_LastOutMessage.user == user) then
		-- Will happen if user has multiple chat frames that trap whispers.
		return true;  -- true == don't show whisper in chat frame
	end

	-- Remember this message for next time.
	CT_LastOutMessage.msg = msg;
	CT_LastOutMessage.user = user;

	-- Notify user of sent message.
	module:printcolor(1.0, 0.5, 0.0, "<CTMapMod> Sent map note to " .. user .. ".");
	return true;  -- true == don't show whisper in chat frame
end

-- Add a chat message filter so we can intercept outgoing whispers involving CT_MapMod notes.
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", CT_MapMod_ProcessOutgoingWhisper);

function CT_MapMod_SendNote()
	-- Send a note to a player.
	local name, descript, zone, player;
	local note;
	local group, x, y, icon;

	CT_LastOutMessage.msg = nil;
	CT_LastOutMessage.user = nil;

	name = CT_MapMod_NoteWindowNameEB:GetText();
	descript = CT_MapMod_NoteWindowDescriptEB:GetText();
	zone = CT_MapMod_NoteWindow.zone;
	player = CT_MapMod_NoteWindowSendEB:GetText();

	note = CT_UserMap_Notes[zone][CT_MapMod_NoteWindow.note];

	if ( not CT_MapMod_NoteWindow:IsVisible() or strlen(player) == 0 ) then
		return;
	end

	if ( L_UIDropDownMenu_GetSelectedName(CT_MapMod_NoteWindowGroupDropDown) ) then
		group = note.set;
	else
		group = L_UIDropDownMenu_GetSelectedID(CT_MapMod_NoteWindowGroupDropDown);
	end

	x = note.x;
	y = note.y;
	icon = note.icon;

	SendChatMessage("<CTMod> New map note received: x="..x.."; y="..y.."; z="..zone.."; n="..name.."; d="..descript.."; g="..group .. "; i=" .. icon .. ";", "WHISPER", nil, player);

	CT_MapMod_NoteWindowSendEB.lastsend = player;
	CT_MapMod_NoteWindowSendEB:SetText("");
	CT_MapMod_NoteWindowSendButton:Disable();
end

---------------------------------------------
-- Gathering resources

local function CT_MapMod_EnableAutoGatherNotes(enable, key)
	-- key == "autoHerbs", "autoMinerals"
	local characterKey = CT_MapMod_GetCharKey();
	if (enable) then
		enable = true;
	else
		enable = false;
	end
	CT_MapMod_Options[characterKey][key] = enable;
end


local function CT_MapMod_ParseResource(event, arg1, arg2)
	local characterKey = CT_MapMod_GetCharKey();
	local options = CT_MapMod_Options[characterKey];

	if (
		not options.autoHerbs and
		not options.autoMinerals
	) then
		return;
	end

	local x, y = GetPlayerMapPosition("player");
	if ( x == 0 and y == 0 ) then
		return;
	end

	local name, prefix, node;

	if ( options.autoHerbs and arg1 == "player" and arg2 == "Herb Gathering" ) then
		name = "Herb";
		prefix = "Herb_";
		node = 7;

	elseif ( options.autoMinerals and arg1 == "player" and arg2 == "Mining" ) then
		name = "Ore";
		prefix = "Ore_";
		node = 8;

	end


	if (name) then
		SetMapToCurrentZone();
		local zone = CT_MapMod_GetMapName();
		if (not zone) then
			return;
		end
		if (not CT_UserMap_Notes[zone]) then
			CT_UserMap_Notes[zone] = { }
		end
		for k, v in pairs(CT_UserMap_Notes[zone]) do
			if ( abs(v.x-x) <= 0.01 and abs(v.y-y) <= 0.01 ) then
				-- Two very close nodes, most likely the same node, we don't want to add another note then
				return;
			end
		end
		CT_MapMod_AddNote(x, y, zone, name, "", CT_MapMod_FindResourceIcon(name, prefix), node);
	end
end


---------------------------------------------
-- Group window (not functional)

function CT_MapMod_GroupWindow_Show()
	CT_MapMod_GroupWindow:Show();
end

function CT_MapMod_GroupWindow_Update()
	local numGroups = #(CT_MAPMOD_SETS);
	FauxScrollFrame_Update(CT_MapMod_GroupWindowScrollFrame, numGroups, 6, 16, CT_MapMod_GroupWindowHighlightFrame, 293, 316);

	local i;
	for i = 1, 6, 1 do
		local btn = _G["CT_MapMod_GroupWindowGroup" .. i];
		if ( i <= numGroups ) then
			btn:Show();
			btn:SetText(" " .. CT_MAPMOD_SETS[FauxScrollFrame_GetOffset(CT_MapMod_GroupWindowScrollFrame)+i]);
		else
			btn:Hide();
		end
	end
end

function CT_MapMod_GroupWindow_SetSelection(id)
	local i;
	for i = 1, 6, 1 do
		_G["CT_MapMod_GroupWindowGroup"..i]:UnlockHighlight();
	end

	-- Get xml id
	local xmlid = id - FauxScrollFrame_GetOffset( CT_MapMod_GroupWindowScrollFrame );
	local groupButton = _G["CT_MapMod_GroupWindowGroup"..xmlid];

	-- Set newly selected quest and highlight it
	CT_MapMod_GroupWindow.selectedButtonID = xmlid;
	local scrollFrameOffset = FauxScrollFrame_GetOffset( CT_MapMod_GroupWindowScrollFrame );
	if ( id > scrollFrameOffset and id <= (scrollFrameOffset + 6) and id <= #(CT_MAPMOD_SETS) ) then
		groupButton:LockHighlight();
	end
end

function CT_MapMod_GroupButton_OnClick(self, button)
	if ( button == "LeftButton" ) then
		CT_MapMod_GroupWindow_SetSelection(self:GetID() + FauxScrollFrame_GetOffset(CT_MapMod_GroupWindowScrollFrame))
		CT_MapMod_GroupWindow_Update();
	end
end

---------------------------------------------
-- Player and cursor coordinates

local function CT_MapMod_Coord_Unlock(unlock)
	unlockCoord = unlock;
	CT_MapMod_Coord:EnableMouse(unlockCoord);
end

function CT_MapMod_Coord_OnEnter(self)
	if (not unlockCoord) then
		return;
	end

	local text;

	-- Have to do this in order to be able to see the tooltip if button is positioned over the map.
	WorldMapPOIFrame.allowBlobTooltip = false;

	text = "To move the Coordinates, left-click and drag them. Release the mouse button to stop moving them.";

	WorldMapTooltip:SetOwner(self, "ANCHOR_NONE");
	WorldMapTooltip:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, 0);
	WorldMapTooltip:SetText("Coordinates", nil, nil, nil, nil, 1);
	WorldMapTooltip:AddLine(text, 1, 1, 1, 1);
	WorldMapTooltip:Show();
end

function CT_MapMod_Coord_OnLeave(self)
	-- Undo what we did in CT_MapMod_Coord_OnEnter()
	if (unlockCoord) then
		WorldMapPOIFrame.allowBlobTooltip = true;
		WorldMapTooltip:Hide();
	end
end

local function CT_MapMod_Coord_GetPositionOptionName(mapSize)
	-- Get the name of the option used for the position of the coordinates on the current map size
	if (not mapSize) then
		mapSize = CT_MapMod_GetMapSizeNumber();
	end
	return "coordPos" .. mapSize;
end

local function CT_MapMod_Coord_SavePosition()
	-- Save the position of the coordinates on the current map size.
	local button = CT_MapMod_Coord;
	local characterKey = CT_MapMod_GetCharKey();

	-- Anchor the coordinates frame.
	CT_MapMod_anchorFrame(CT_MapMod_Coord);

	-- Save the anchor point values.
	local anchorPoint, anchorTo, relativePoint, xoffset, yoffset = button:GetPoint(1);
	if (anchorTo) then
		anchorTo = anchorTo:GetName();
	end
	local optName = CT_MapMod_Coord_GetPositionOptionName();
	CT_MapMod_Options[characterKey][optName] = { anchorPoint, anchorTo, relativePoint, xoffset, yoffset };
end

local function CT_MapMod_Coord_StopMoving()
	local self = CT_MapMod_Coord;
	if (self.isMoving) then
		self:StopMovingOrSizing();
		self:SetUserPlaced(false);
		self.isMoving = false;
		CT_MapMod_Coord_SavePosition();
	end
end

function CT_MapMod_Coord_OnMouseDown(self, button)
	if (button == "LeftButton") then
		self:StartMoving();
		self.isMoving = true;
		CT_MapMod_Coord_OnLeave(self);  -- Hide the tooltip while dragging
	end
end

function CT_MapMod_Coord_OnMouseUp(self, button)
	if (button == "LeftButton") then
		if (self.isMoving) then
			CT_MapMod_Coord_StopMoving();
		end
	end
end

local function CT_MapMod_Coord_ResetPosition(clearSaved)
	-- Reset position of the coordinates on the current map size
	local characterKey = CT_MapMod_GetCharKey();
	if ( WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE ) then
		-- Small size world map
		CT_MapMod_Coord:ClearAllPoints();
		CT_MapMod_Coord:SetPoint("TOPLEFT", WorldMapFrame, "TOPLEFT", 95, -5);
	else
		-- Full screen size world map
		CT_MapMod_Coord:ClearAllPoints();
		CT_MapMod_Coord:SetPoint("BOTTOMRIGHT", WorldMapFrame, "BOTTOMRIGHT", -170, 10);
	end
	if (clearSaved) then
		local optName = CT_MapMod_Coord_GetPositionOptionName();
		CT_MapMod_Options[characterKey][optName] = nil;
	end
end

local function CT_MapMod_Coord_ResetPositions()
	-- Reset all positions of the coordinats (1 per map size)
	local characterKey = CT_MapMod_GetCharKey();
	for i = 1, CT_MapMod_GetMapSizeNumber("max") do
		local optName = CT_MapMod_Coord_GetPositionOptionName(i);
		CT_MapMod_Options[characterKey][optName] = nil;
	end
	CT_MapMod_Coord_ResetPosition(false);
end

function CT_MapMod_Coord_RestorePosition()
	-- Restore the position of the coordinates on the current map size.
	local button = CT_MapMod_Coord;
	local characterKey = CT_MapMod_GetCharKey();

	-- Set the frame's position
	local optName = CT_MapMod_Coord_GetPositionOptionName();
	local pos = CT_MapMod_Options[characterKey][optName];
	if (pos) then
		-- Restore to the saved position.
		if pos[2] == "WorldMapPositioningGuide" then
			CT_MapMod_Coord_ResetPositions()
		else
			button:ClearAllPoints();
			button:SetPoint(pos[1], pos[2], pos[3], pos[4], pos[5]);
		end
	else
		-- Restore to default position.
		CT_MapMod_Coord_ResetPosition(false)
	end
end

local function CT_MapMod_Coord_GetHideOptionName(mapSize)
	-- Get the name of the option used for hiding the coordinates on the current map size
	if (not mapSize) then
		mapSize = CT_MapMod_GetMapSizeNumber();
	end
	return "coordHide" .. mapSize;
end

local coordHide;  -- local copy of this size map's hide coordinates option

function CT_MapMod_ShowHideCoord(hide)
	local characterKey = CT_MapMod_GetCharKey();
	local optName = CT_MapMod_Coord_GetHideOptionName();
	if (hide == nil) then
		-- Get current value
		hide = not not (CT_MapMod_Options[characterKey][optName]);
	else
		-- Change current value
		CT_MapMod_Options[characterKey][optName] = hide;
	end
	coordHide = hide;  -- save in local var for use by OnUpdate
	if (hide) then
		CT_MapMod_Coord:Hide();
	else
		CT_MapMod_Coord:Show();
	end
end

function CT_MapMod_MapFrame_OnUpdate()
	local cX, cY = CT_MapMod_GetCursorMapPosition();
	local pX, pY = GetPlayerMapPosition("player");

	if not pX or not pY then
		return
	end

	local dec = 1;

	cX = round(cX * 100, dec);
	cY = round(cY * 100, dec);
	pX = round(pX * 100, dec);
	pY = round(pY * 100, dec);

	if (not coordHide) then
		CT_MapMod_CoordPlayerText:SetFormattedText("Player: |c00FFFFFF%3.1f|r, |c00FFFFFF%3.1f|r", pX, pY);
		if (WorldMapButton:IsMouseOver()) then
			CT_MapMod_CoordCursorText:SetFormattedText("(|c00FFFFFF%3.1f|r, |c00FFFFFF%3.1f|r)", cX, cY);
		else
			CT_MapMod_CoordCursorText:SetText("");
		end
	end
end

function CT_MapMod_MapFrame_OnShow()
end

---------------------------------------------
-- Main button

function CT_MapMod_MainButton_OnShow(self)
	CT_MapMod_MainButton_SetCountPosition();
end

local function CT_MapMod_MainButton_SetHideMainTooltip(hide)
	-- Set the hide main button tooltip option.
	local characterKey = CT_MapMod_GetCharKey();
	CT_MapMod_Options[characterKey]["hideMainTooltip"] = hide;
end

function CT_MapMod_MainButton_OnEnter(self)
	local text;

	local characterKey = CT_MapMod_GetCharKey();
	local hide = not not (CT_MapMod_Options[characterKey]["hideMainTooltip"]);
	if (hide) then
		return;
	end

	-- Have to do this in order to be able to see the tooltip if button is positioned over the map.
	WorldMapPOIFrame.allowBlobTooltip = false;

	local mapName = CT_MapMod_GetMapName();
	if (mapName) then
		text = "To open the menu, left-click the Notes button.";
		if (CT_MapMod_CanCreateNoteOnPlayer()) then
			text = text .. "\n\nTo create a new note at the player, Ctrl left-click the Notes button (or use the menu).";
		end
		text = text .. "\n\nTo create a new note at the cursor, Ctrl left-click an open spot on the map.";
	else
		text = "Left-click the Notes button to open the menu.";
	end
	text = text .. "\n\nTo move the Notes button, shift left-click it. Click the button again to stop moving it.";

	WorldMapTooltip:SetOwner(self, "ANCHOR_NONE");
	WorldMapTooltip:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, 0);
	WorldMapTooltip:SetText("Notes", nil, nil, nil, nil, 1);
	WorldMapTooltip:AddLine(text, 1, 1, 1, 1);
	WorldMapTooltip:Show();
end

function CT_MapMod_MainButton_OnLeave(self)
	-- Undo what we did in CT_MapMod_MainButton_OnEnter()
	WorldMapPOIFrame.allowBlobTooltip = true;

	WorldMapTooltip:Hide();
end

local function CT_MapMod_MainButton_GetPositionOptionName(mapSize)
	-- Get the name of the option used for the position of the note count text on the current map size
	if (not mapSize) then
		mapSize = CT_MapMod_GetMapSizeNumber();
	end
	return "mainPos" .. mapSize;
end

local function CT_MapMod_MainButton_SavePosition()
	-- Save the position of the notes button on the current map size.
	local button = CT_MapMod_MainButton;
	local characterKey = CT_MapMod_GetCharKey();

	-- Anchor the main button.
	CT_MapMod_anchorFrame(CT_MapMod_MainButton);

	-- Save the anchor point values.
	local anchorPoint, anchorTo, relativePoint, xoffset, yoffset = button:GetPoint(1);
	if (anchorTo) then
		anchorTo = anchorTo:GetName();
	end
	local optName = CT_MapMod_MainButton_GetPositionOptionName();
	CT_MapMod_Options[characterKey][optName] = { anchorPoint, anchorTo, relativePoint, xoffset, yoffset };
end

local function CT_MapMod_MainButton_StopMoving()
	local self = CT_MapMod_MainButton;
	if (self.isMoving) then
		self:StopMovingOrSizing();
		self:SetUserPlaced(false);
		self.isMoving = false;
		CT_MapMod_MainButton_SavePosition();
	end
end

function CT_MapMod_MainButton_OnClick(self, button)
	if (self.isMoving) then
		CT_MapMod_MainButton_StopMoving();
		return;
	end
	if (IsControlKeyDown()) then
		if (CT_MapMod_CanCreateNoteOnPlayer()) then
			CT_MapMod_CreateNoteOnPlayer();
		end
	elseif (IsShiftKeyDown()) then
		self:StartMoving();
		self.isMoving = true;
		CT_MapMod_MainButton_OnLeave(self);  -- Hide the tooltip while dragging
	else
		-- Toggle the main menu
		local dropdown = CT_MapMod_MainMenuDropDown;

		local mainmenuDropDownInitialized;
		if (not mainmenuDropDownInitialized) then
			-- We're delaying the initialization of the dropdown menus until the map frame is shown
			-- to make sure that Blizzard has had time to create CompactRaidFrame1.
			-- At this time (2012-08-29), if you create a drop down menu containing 8 or more buttons before
			-- CompactRaidFrame1 gets created, CompactRaidFrame1 will be tainted when it gets created.
			CT_MapMod_MainMenu_DropDown_OnLoad(CT_MapMod_MainMenuDropDown);
			mainmenuDropDownInitialized = true;
		end

		CT_MapMod_MainButton_OnLeave(self);

		local uscale = UIParent:GetEffectiveScale();
		local ucenterX, ucenterY = UIParent:GetCenter();
		ucenterX = ucenterX * uscale;
		ucenterY = ucenterY * uscale;

		local bscale = self:GetEffectiveScale();
		local bcenterX, bcenterY = self:GetCenter();
		bcenterX = bcenterX * bscale;
		bcenterY = bcenterY * bscale;

		if (bcenterY < ucenterY) then
			dropdown.point = "BOTTOM";
			dropdown.relativePoint = "TOP";
		else
			dropdown.point = "TOP";
			dropdown.relativePoint = "BOTTOM";
		end
		if (bcenterX < bcenterY) then
			dropdown.point = dropdown.point .. "LEFT";
			dropdown.relativePoint = dropdown.relativePoint .. "LEFT";
		else
			dropdown.point = dropdown.point .. "RIGHT";
			dropdown.relativePoint = dropdown.relativePoint .. "RIGHT";
		end
		dropdown.relativeTo = CT_MapMod_MainButton;

		dropdown.xOffset = 0;
		dropdown.yOffset = 0;
		L_ToggleDropDownMenu(1, nil, dropdown);
		PlaySound(856);
	end
end

local function CT_MapMod_MainButton_ResetPosition(clearSaved)
	-- Reset position of the notes button on the current map size
	local characterKey = CT_MapMod_GetCharKey();
	if ( WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE ) then
		-- Small size world map
		CT_MapMod_MainButton:ClearAllPoints();
		CT_MapMod_MainButton:SetPoint("RIGHT", WorldMapFrame.BorderFrame.MaximizeMinimizeFrame, "LEFT", 3, 0);
	else
		-- Full screen size world map
		CT_MapMod_MainButton:ClearAllPoints();
		CT_MapMod_MainButton:SetPoint("RIGHT", WorldMapFrame.BorderFrame.MaximizeMinimizeFrame, "LEFT", 3, 0);
	end
	if (clearSaved) then
		local optName = CT_MapMod_MainButton_GetPositionOptionName();
		CT_MapMod_Options[characterKey][optName] = nil;
	end
end

local function CT_MapMod_MainButton_ResetPositions()
	-- Reset all positions of the notes button (1 per map size)
	local characterKey = CT_MapMod_GetCharKey();
	for i = 1, CT_MapMod_GetMapSizeNumber("max") do
		local optName = CT_MapMod_MainButton_GetPositionOptionName(i);
		CT_MapMod_Options[characterKey][optName] = nil;
	end
	CT_MapMod_MainButton_ResetPosition(false);
end

function CT_MapMod_MainButton_RestorePosition()
	-- Restore the position of the notes button on the current map size.
	local button = CT_MapMod_MainButton;
	local characterKey = CT_MapMod_GetCharKey();

	-- Set the frame's position
	local optName = CT_MapMod_MainButton_GetPositionOptionName();
	local pos = CT_MapMod_Options[characterKey][optName];
	if (pos) then
		-- Restore to the saved position.
		if pos[2] == "WorldMapPositioningGuide" then
			CT_MapMod_MainButton_ResetPositions()
		else
			button:ClearAllPoints();
			button:SetPoint(pos[1], pos[2], pos[3], pos[4], pos[5]);
		end
	else
		-- Restore to default position.
		CT_MapMod_MainButton_ResetPosition(false)
	end
end

local function CT_MapMod_MainButton_GetCountPositionOptionName(mapSize)
	-- Get the name of the option used for the position of the note count text on the current map size
	if (not mapSize) then
		mapSize = CT_MapMod_GetMapSizeNumber();
	end
	return "countPos" .. mapSize;
end

function CT_MapMod_MainButton_SetCountPosition(pos)
	-- Change the position of the note count text on the current map size
	local characterKey = CT_MapMod_GetCharKey();
	local optName = CT_MapMod_MainButton_GetCountPositionOptionName();
	if (not pos) then
		-- Get option
		pos = CT_MapMod_Options[characterKey][optName] or 1;
	else
		-- Set option
		CT_MapMod_Options[characterKey][optName] = pos;
	end
	-- 1==Left side of button, 2==Top, 3==Right, 4==Bottom
	CT_NumNotes:ClearAllPoints();
	if (pos == 4) then
		CT_NumNotes:SetPoint("TOP", CT_MapMod_MainButton, "BOTTOM", 0, -3);
	elseif (pos == 3) then
		CT_NumNotes:SetPoint("LEFT", CT_MapMod_MainButton, "RIGHT", 3, 0);
	elseif (pos == 2) then
		CT_NumNotes:SetPoint("BOTTOM", CT_MapMod_MainButton, "TOP", 0, 3);
	else
		CT_NumNotes:SetPoint("RIGHT", CT_MapMod_MainButton, "LEFT", -3, 0);
	end
end

local function CT_MapMod_MainButton_ToggleCountPosition()
	-- Change the position of the note count text on the current map size
	local characterKey = CT_MapMod_GetCharKey();
	local optName = CT_MapMod_MainButton_GetCountPositionOptionName();
	local pos = CT_MapMod_Options[characterKey][optName] or 1;
	pos = pos + 1;
	if (pos > 4) then
		pos = 1;
	end
	CT_MapMod_Options[characterKey][optName] = pos;
	CT_MapMod_MainButton_SetCountPosition();
end

---------------------------------------------
-- Main menu

function CT_MapMod_MainMenu_DropDown_OnClick(self)
	local characterKey = CT_MapMod_GetCharKey();

	if (
		self.value == "autoHerbs" or
		self.value == "autoMinerals"
	) then
		if (CT_MapMod_Options[characterKey][self.value]) then
			CT_MapMod_EnableAutoGatherNotes(false, self.value);
		else
			CT_MapMod_EnableAutoGatherNotes(true, self.value);
		end

	elseif (self.value == "receivenotes") then
		if (CT_MapMod_Options[characterKey].receiveNotes) then
			CT_MapMod_EnableReceiveNotes(nil);
		else
			CT_MapMod_EnableReceiveNotes(1);
		end

	elseif (self.value == "resetposition") then
		-- Reset position of the Notes button on the current map (small or full).
		CT_MapMod_MainButton_ResetPosition(true);

	elseif (self.value == "togglecountpos") then
		CT_MapMod_MainButton_ToggleCountPosition();

	elseif (self.value == "resetcoord") then
		-- Reset position of the coordinates on the current map (small or full).
		CT_MapMod_Coord_ResetPosition(true);

	elseif (self.value == "unlockCoord") then
		CT_MapMod_Coord_Unlock(true);

	elseif (self.value == "lockCoord") then
		CT_MapMod_Coord_Unlock(false);

	elseif (self.value == "hideCoord") then
		local optName = CT_MapMod_Coord_GetHideOptionName();
		if (CT_MapMod_Options[characterKey][optName]) then
			CT_MapMod_ShowHideCoord(false);
		else
			CT_MapMod_ShowHideCoord(1);
		end

	elseif (self.value == "hideMainTooltip") then
		if (CT_MapMod_Options[characterKey].hideMainTooltip) then
			CT_MapMod_MainButton_SetHideMainTooltip(false);
		else
			CT_MapMod_MainButton_SetHideMainTooltip(1);
		end

	elseif (self.value == "setfilter") then
		CT_MapMod_FilterWindow:Show();

	elseif (self.value == "clearfilter") then
		CT_MapMod_ExecuteFilter("");

	elseif (self.value == "playernote") then
		if (CT_MapMod_CanCreateNoteOnPlayer()) then
			CT_MapMod_CreateNoteOnPlayer();
		end

	elseif (self.value == "editlast") then
		CT_MapMod_EditNote();

	else
		-- Show/hide groups
		for key, val in pairs(CT_MAPMOD_SETS) do
			if (val == self.value) then
				local characterKey = CT_MapMod_GetCharKey();
				if ( not CT_MapMod_Options[characterKey].hideGroups ) then
					CT_MapMod_Options[characterKey].hideGroups = { };
				end
				CT_MapMod_Options[characterKey].hideGroups[self.value] = not CT_MapMod_Options[characterKey].hideGroups[self.value];
				CT_MapMod_UpdateMap();
				break;
			end
		end
	end
end

function CT_MapMod_MainMenu_DropDown_Initialize(self, level)

	local info;
	local characterKey = CT_MapMod_GetCharKey();
	local optName;

	if (level == 2 and L_UIDROPDOWNMENU_MENU_VALUE == "menu_button") then

		info = L_UIDropDownMenu_CreateInfo();
		info.text = "Reset position"
		info.value = "resetposition";
		info.notCheckable = 1;
		info.func = CT_MapMod_MainMenu_DropDown_OnClick;
		optName = CT_MapMod_MainButton_GetPositionOptionName();
		if (not CT_MapMod_Options[characterKey]) then
			info.disabled = true;
		elseif (not CT_MapMod_Options[characterKey][optName]) then
			info.disabled = true;
		end
		L_UIDropDownMenu_AddButton(info, level);

		info = L_UIDropDownMenu_CreateInfo();
		info.text = "Hide tooltip"
		info.value = "hideMainTooltip";
		if (CT_MapMod_Options[characterKey] and CT_MapMod_Options[characterKey].hideMainTooltip) then
			info.checked = 1;
		end
		info.keepShownOnClick = 1;
		info.func = CT_MapMod_MainMenu_DropDown_OnClick;
		L_UIDropDownMenu_AddButton(info, level);

		info = L_UIDropDownMenu_CreateInfo();
		info.text = "Change note count position"
		info.value = "togglecountpos";
		info.notCheckable = 1;
		info.func = CT_MapMod_MainMenu_DropDown_OnClick;
		info.keepShownOnClick = 1;
		L_UIDropDownMenu_AddButton(info, level);

		return;

	elseif (level == 2 and L_UIDROPDOWNMENU_MENU_VALUE == "menu_coord") then

		info = L_UIDropDownMenu_CreateInfo();
		if (unlockCoord) then
			info.text = "Lock"
			info.value = "lockCoord";
		else
			info.text = "Unlock"
			info.value = "unlockCoord";
		end
		info.notCheckable = 1;
		info.func = CT_MapMod_MainMenu_DropDown_OnClick;
		L_UIDropDownMenu_AddButton(info, level);

		info = L_UIDropDownMenu_CreateInfo();
		info.text = "Reset position"
		info.value = "resetcoord";
		info.notCheckable = 1;
		info.func = CT_MapMod_MainMenu_DropDown_OnClick;
		optName = CT_MapMod_Coord_GetPositionOptionName();
		if (not CT_MapMod_Options[characterKey]) then
			info.disabled = true;
		elseif (not CT_MapMod_Options[characterKey][optName]) then
			info.disabled = true;
		end
		L_UIDropDownMenu_AddButton(info, level);

		info = L_UIDropDownMenu_CreateInfo();
		info.text = "Hide"
		info.value = "hideCoord";
		optName = CT_MapMod_Coord_GetHideOptionName();
		if (CT_MapMod_Options[characterKey] and CT_MapMod_Options[characterKey][optName]) then
			info.checked = 1;
		end
		info.keepShownOnClick = 1;
		info.func = CT_MapMod_MainMenu_DropDown_OnClick;
		L_UIDropDownMenu_AddButton(info, level);

		return;

	elseif (level == 2 and L_UIDROPDOWNMENU_MENU_VALUE == "auto_add") then

		info = L_UIDropDownMenu_CreateInfo();
		info.text = "Herbs"
		info.value = "autoHerbs";
		if (CT_MapMod_Options[characterKey] and CT_MapMod_Options[characterKey].autoHerbs) then
			info.checked = 1;
		end
		info.keepShownOnClick = 1;
		info.func = CT_MapMod_MainMenu_DropDown_OnClick;
		L_UIDropDownMenu_AddButton(info, level);

		info = L_UIDropDownMenu_CreateInfo();
		info.text = "Minerals"
		info.value = "autoMinerals";
		if (CT_MapMod_Options[characterKey] and CT_MapMod_Options[characterKey].autoMinerals) then
			info.checked = 1;
		end
		info.keepShownOnClick = 1;
		info.func = CT_MapMod_MainMenu_DropDown_OnClick;
		L_UIDropDownMenu_AddButton(info, level);

		return;

	end

	info = L_UIDropDownMenu_CreateInfo();
	info.text = "CT_MapMod";
	info.notCheckable = 1;
	info.justifyH = "CENTER";
	info.isTitle = true;
	L_UIDropDownMenu_AddButton(info);

	info = L_UIDropDownMenu_CreateInfo();
	info.text = "Create note at player"
	info.value = "playernote";
	info.notCheckable = 1;
	info.func = CT_MapMod_MainMenu_DropDown_OnClick;
	if (not CT_MapMod_CanCreateNoteOnPlayer()) then
		info.disabled = true;
	end
	L_UIDropDownMenu_AddButton(info);

	info = L_UIDropDownMenu_CreateInfo();
	info.text = "Edit last note added to this map"
	info.value = "editlast";
	info.notCheckable = 1;
	info.func = CT_MapMod_MainMenu_DropDown_OnClick;
	do
		local id = 0;
		local mapName = CT_MapMod_GetMapName();
		if (mapName) then
			local notes = CT_UserMap_Notes[mapName];
			if (notes) then
				id = #(notes);
			else
				id = 0;
			end
		end
		if (id == 0) then
			info.disabled = true;
		end
	end
	L_UIDropDownMenu_AddButton(info);

	local emptyFilter = ((CT_MapMod_Filter or "") == "");

	info = L_UIDropDownMenu_CreateInfo();
	if (emptyFilter) then
		info.text = "Set filter text"
	else
		info.text = "Edit filter text"
	end
	info.value = "setfilter";
	info.notCheckable = 1;
	info.func = CT_MapMod_MainMenu_DropDown_OnClick;
	L_UIDropDownMenu_AddButton(info);

	info = L_UIDropDownMenu_CreateInfo();
	info.text = "Clear filter text"
	info.value = "clearfilter";
	info.notCheckable = 1;
	info.func = CT_MapMod_MainMenu_DropDown_OnClick;
	if (emptyFilter) then
		info.disabled = true;
	end
	L_UIDropDownMenu_AddButton(info);

	info = L_UIDropDownMenu_CreateInfo();
	info.text = "Options";
	info.notCheckable = 1;
	info.justifyH = "CENTER";
	info.isTitle = true;
	L_UIDropDownMenu_AddButton(info);

	info = L_UIDropDownMenu_CreateInfo();
	info.text = "Notes button"
	info.value = "menu_button";
	info.keepShownOnClick = 1;
	info.notCheckable = 1;
	info.hasArrow = true;
	L_UIDropDownMenu_AddButton(info);

	info = L_UIDropDownMenu_CreateInfo();
	info.text = "Coordinates"
	info.value = "menu_coord";
	info.keepShownOnClick = 1;
	info.notCheckable = 1;
	info.hasArrow = true;
	L_UIDropDownMenu_AddButton(info);

	info = L_UIDropDownMenu_CreateInfo();
	info.text = "Create notes when gathering"
	info.value = "auto_add";
	info.keepShownOnClick = 1;
	info.notCheckable = 1;
	info.hasArrow = true;
	L_UIDropDownMenu_AddButton(info);

	info = L_UIDropDownMenu_CreateInfo();
	info.text = "Receive notes from players"
	info.value = "receivenotes";
	if (CT_MapMod_Options[characterKey] and CT_MapMod_Options[characterKey].receiveNotes) then
		info.checked = 1;
	end
	info.keepShownOnClick = 1;
	info.func = CT_MapMod_MainMenu_DropDown_OnClick;
	L_UIDropDownMenu_AddButton(info);

	info = L_UIDropDownMenu_CreateInfo();
	info.text = "Groups To Show";
	info.notCheckable = 1;
	info.justifyH = "CENTER";
	info.isTitle = true;
	L_UIDropDownMenu_AddButton(info);

	for key, val in pairs(CT_MAPMOD_SETS) do
		info = L_UIDropDownMenu_CreateInfo();
		info.text = val;
		info.value = val;
		if ( CT_MapMod_Options[characterKey] and ( not CT_MapMod_Options[characterKey].hideGroups or not CT_MapMod_Options[characterKey].hideGroups[val] ) ) then
			info.checked = 1;
		end
		info.keepShownOnClick = 1;
		info.func = CT_MapMod_MainMenu_DropDown_OnClick;
		L_UIDropDownMenu_AddButton(info);
	end
end

function CT_MapMod_MainMenu_DropDown_OnLoad(self)
	L_UIDropDownMenu_Initialize(self, CT_MapMod_MainMenu_DropDown_Initialize, "MENU");
	L_UIDropDownMenu_SetWidth(self, 130);

	hooksecurefunc(WorldMapFrame, "Hide", function(this)
		if L_UIDROPDOWNMENU_OPEN_MENU == CT_MapMod_MainMenuDropDown then
			L_ToggleDropDownMenu(1, nil, CT_MapMod_MainMenuDropDown);
		end
	end)
end

---------------------------------------------
-- Convert old notes

local function CT_MapMod_UpdateOldNotes()

	-- TEMPORARY CODE FOR BETA TESTING
	--for key, val in pairs(CT_UserMap_Zone) do
	--	CT_MapMod_AddNote(0.50, 0.50, key, "BETA TEST", "BETA TEST", CT_MapMod_FindResourceIcon("Herb", "Herb_"), 7);
	--end

	-- Converts string-based mapName to integer-based mapID keys.
	-- This was introduced in 7.3, and replaces the very old updating from 4.0

	local temp = {};
	for key, val in pairs(CT_UserMap_Notes) do
		if (type(key) == "string" and type(val) == "table" and not string.find(key,"^%d+%-%d+$")) then
			if (CT_UserMap_Zone[key]) then
				CT_UserMap_Notes[CT_UserMap_Zone[key]] = val;
				CT_UserMap_Notes[key] = nil;
			end
		end
	end


end

---------------------------------------------
-- Event frame

function CT_MapMod_EventFrame_OnEvent(self, event, arg1, arg2)

	if ( event == "UNIT_SPELLCAST_SUCCEEDED" ) then
		CT_MapMod_ParseResource(event, arg1, arg2)

	elseif ( event == "DISPLAY_SIZE_CHANGED" ) then
		CT_MapMod_AdjustPositions();

	elseif ( event == "WORLD_MAP_UPDATE" ) then
		CT_MapMod_UpdateMap();

	elseif (event == "PLAYER_LOGIN") then

		-- Get character key. Will also establish default options table if needed.
		local characterKey = CT_MapMod_GetCharKey();

		-- Get options table for this character
		local options = CT_MapMod_Options[characterKey];

		-- options.autoHerbs will be nil only if user was using CT_MapMod prior to 4.0100
		if (options.autoHerbs == nil) then
			-- Convert existing CT_MapMod user's old autoGather option.
			if (options.autoGather) then
				options.autoHerbs = true;
			else
				options.autoHerbs = false;
			end
		end

		-- options.autoMinerals will be nil only if user was using CT_MapMod prior to 4.0100
		if (options.autoMinerals == nil) then
			-- Convert existing CT_MapMod user's old autoGather option.
			if (options.autoGather) then
				options.autoMinerals = true;
			else
				options.autoMinerals = false;
			end
		end

		CT_MapMod_UpdateOldNotes();

	elseif ( event == "PLAYER_ENTERING_WORLD" ) then
		local characterKey = CT_MapMod_GetCharKey();
		SetMapToCurrentZone();
	end
end

---------------------------------------------
-- WorldMap hooks

local oldProcessMapClick = ProcessMapClick;
function ProcessMapClick(...)
	-- This gets called from WorldMapFrame.lua when user left clicks on the map.
	local mapName = CT_MapMod_GetMapName();
	if ( IsControlKeyDown() and mapName and not CT_MapMod_IsDialogShown() ) then
		-- Create a new note at the cursor position.
		CT_MapMod_CreateNoteOnCursor();
	else
		oldProcessMapClick(...);
	end
end

local function CT_MapMod_WorldMapFrame_OnHide(...)
	CT_MapMod_NoteWindow_Cancel();
	CT_MapMod_FilterWindow:Hide();
	CT_MapMod_MainButton_StopMoving();
	CT_MapMod_Coord_StopMoving();
end
WorldMapFrame:HookScript("OnHide", CT_MapMod_WorldMapFrame_OnHide);
hooksecurefunc("WorldMapFrame_OnHide", CT_MapMod_WorldMapFrame_OnHide);


local function CT_MapMod_WorldMap_ToggleSizeUp()
	CT_MapMod_AdjustPositions();
end
hooksecurefunc("WorldMap_ToggleSizeUp", CT_MapMod_WorldMap_ToggleSizeUp);


local function CT_MapMod_WorldMap_ToggleSizeDown()
	CT_MapMod_AdjustPositions();
end
hooksecurefunc("WorldMap_ToggleSizeDown", CT_MapMod_WorldMap_ToggleSizeDown);


--[[hooksecurefunc("WorldMapFrame_SetOpacity",
	function(opacity)
		local alpha;
		alpha = 0.5 + (1.0 - opacity) * 0.50;
		CT_MapMod_MainButton:SetAlpha(alpha);
		CT_MapMod_Coord:SetAlpha(alpha);
		CT_MapMod_MapButtonFrame:SetAlpha(alpha);
		WorldMapTrackQuest:SetAlpha(alpha);
--		WorldMapQuestShowObjectives:SetAlpha(alpha);
		WorldMapShowDropDown:SetAlpha(alpha);
	end
);]]

--[[hooksecurefunc("WorldMap_OpenToQuest",
	function(...)
		CT_MapMod_UpdateMap();
	end
);]]

hooksecurefunc("WorldMapFrame_ToggleWindowSize",
	function(...)
		CT_MapMod_UpdateMap();
	end
);

--------------------------------------------
-- Options Frame Code

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

		optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#Notes Button");
		optionsAddObject(-10, 3*14, "font#t:0:%y#s:0:%s#l:13:0#r#Click the button below to reset the position of the Notes button and the coordinates on the map window.#" .. textColor2 .. ":l");
		optionsBeginFrame( -10,   30, "button#t:0:%y#s:120:%s#v:UIPanelButtonTemplate#Reset position");
			optionsAddScript("onclick",
				function(self)
					CT_MapMod_MainButton_ResetPositions();
					CT_MapMod_Coord_ResetPositions();
				end
			);
		optionsEndFrame();

		optionsAddScript("onload",
			function(self)
				theOptionsFrame = self;
			end
		);
	optionsEndFrame();

	return "frame#all", optionsGetData();
end

module.update = function(self, optName, value)
	if (optName == "init") then
	else
	end
end
