------------------------------------------------
--            CT_RaidAssist (CTRA)            --
--                                            --
-- Provides features to assist raiders incl.  --
-- customizable raid frames.  CTRA was the    --
-- original raid frame in Vanilla (pre 1.11)  --
-- but has since been re-written completely   --
-- to integrate with the more modern UI.      --
--                                            --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
--					      --
-- Original credits to Cide and TS            --
-- Improved by Dargen circa late Vanilla      --
-- Maintained by Resike from 2014 to 2017     --
-- Rebuilt by Dahk Celes (ddc) in 2019        --
------------------------------------------------

local MODULE_NAME, module = ...;

-- Expansion Configuration Data
-- These tables should be updated every expansion or major patch to reflect new content



------------------------------------------------
-- CTRA_Configuration_Buffs

-- Which buffs could be applied out of combat by right-clicking the player frame?  Buffs listed first take precedence.
-- name: 	name of the spell to be cast 			(mandatory)
-- modifier: 	nomod, mod, mod:shift, mod:ctrl, or mod:alt	(mandatory)
-- gameVersion: if set, this line only applies to classic or retail using CT_GAME_VERSION_CLASSIC or CT_GAME_VERSION_RETAIL constants
module.CTRA_Configuration_Buffs =
{
	["PRIEST"] =
	{
		{["name"] = "Power Word: Fortitude", ["modifier"] = "nomod", },
	},
	["MAGE"] =
	{
		{["name"] = "Arcane Intellect", ["modifier"] = "nomod", } ,
		{["name"] = "Arcane Brilliance", ["modifier"] = "mod:shift", ["gameVersion"] = CT_GAME_VERSION_CLASSIC,},
		{["name"] = "Amplify Magic", ["modifier"] = "mod:ctrl", ["gameVersion"] = CT_GAME_VERSION_CLASSIC,},
		{["name"] = "Dampen Magic", ["modifier"] = "mod:alt", ["gameVersion"] = CT_GAME_VERSION_CLASSIC,},
	},
	["WARRIOR"] =
	{	
		{["name"] = "Battle Shout", ["modifier"] = "nomod",},
	},
	["HUNTER"] =
	{
		{["name"] = "Trueshot Aura", ["modifier"] = "nomod", ["gameVersion"] = CT_GAME_VERSION_CLASSIC,},
	},
	["PALADIN"] = 
	{
		{["name"] = "Blessing of Kings", ["modifier"] = "nomod", ["gameVersion"] = CT_GAME_VERSION_CLASSIC,},
		{["name"] = "Blessing of Wisdom", ["modifier"] = "mod:shift", ["gameVersion"] = CT_GAME_VERSION_CLASSIC,},
		{["name"] = "Blessing of Might", ["modifier"] = "mod:ctrl", ["gameVersion"] = CT_GAME_VERSION_CLASSIC,},
		{["name"] = "Blessing of Salvation", ["modifier"] = "mod:alt", ["gameVersion"] = CT_GAME_VERSION_CLASSIC,},
	}
}


------------------------------------------------
-- CTRA_Configuration_FriendlyRemoves

-- Which debuff removals could be cast in combat by right-clicking the player frame?  Buffs listed first take precedence.
-- name: 	name of the spell to be cast 			(mandatory)
-- modifier: 	nomod, mod, mod:shift, mod:ctrl, or mod:alt	(mandatory)
-- magic: 	if set, the addon should indicate the presence of a removable magic debuff
-- curse, poison, disease: same as for magic
-- spec:	if set, this line only applies when GetInspectSpecialization("player") returns this SpecializationID
-- gameVersion: if set, this line only applies to classic or retail using CT_GAME_VERSION_CLASSIC or CT_GAME_VERSION_RETAIL constants
module.CTRA_Configuration_FriendlyRemoves =												
{			
	["DRUID"] =										
	{											
		{["name"] = "Nature's Cure", ["modifier"] = "nomod", ["magic"] = true, ["curse"] = true, ["poison"] = true, ["gameVersion"] = CT_GAME_VERSION_RETAIL},
		{["name"] = "Remove Corruption", ["modifier"] = "nomod", ["curse"] = true, ["poison"] = true, ["gameVersion"] = CT_GAME_VERSION_RETAIL},
		{["name"] = "Abolish Poison", ["modifier"] = "nomod", ["poison"] = true, ["gameVersion"] = CT_GAME_VERSION_CLASSIC},
		{["name"] = "Cure Poison", ["modifier"] = "nomod", ["poison"] = true, ["gameVersion"] = CT_GAME_VERSION_CLASSIC},  	--  the first available 'nomod' on the list has precedence, so at lvl 26 this stops being used
		{["name"] = "Remove Curse", ["modifier"] = "mod:shift", ["curse"] = true, ["gameVersion"] = CT_GAME_VERSION_CLASSIC},
	},
	["MAGE"] =
	{
		{["name"] = "Remove Curse", ["modifier"] = "nomod", ["curse"] = true},
		{["name"] = "Remove Lesser Curse", ["modifier"] = "nomod", ["curse"] = true},
	},
	["MONK"] =
	{
		{["name"] = "Detox", ["modifier"] = "nomod", ["spec"] = 270, ["magic"] = true, ["poison"] = true, ["disease"] = true},
		{["name"] = "Detox", ["modifier"] = "nomod", ["poison"] = true, ["disease"] = true},	-- this is superceded for mistweavers by the higher one on the list with spec=270
	},
	["PALADIN"] =
	{
		{["name"] = "Cleanse", ["modifier"] = "nomod", ["magic"] = true, ["poison"] = true, ["disease"] = true},	-- exists (in roughly equivalent forms) in both retail and classic
		{["name"] = "Cleanse  Toxins", ["modifier"] = "nomod", ["poison"] = true, ["disease"] = true, ["gameVersion"] = CT_GAME_VERSION_RETAIL},	-- used by specs in retail who don't get the full cleanse
		{["name"] = "Purify", ["modifier"] = "nomod", ["poison"] = true, ["disease"] = true, ["gameVersion"] = CT_GAME_VERSION_CLASSIC},	--at higher levels, replaced by cleanse
	},
	["PRIEST"] = 
	{
		{["name"] = "Purify", ["modifier"] = "nomod", ["magic"] = true, ["disease"] = true, ["gameVersion"] = CT_GAME_VERSION_RETAIL},
		{["name"] = "Purify Disease", ["modifier"] = "nomod", ["disease"] = true, ["gameVersion"] = CT_GAME_VERSION_RETAIL},
		{["name"] = "Cure Disease", ["modifier"] = "mod:shift", ["disease"] = true, ["gameVersion"] = CT_GAME_VERSION_CLASSIC},
		{["name"] = "Dispel Magic", ["modifier"] = "nomod", ["magic"] = true, ["gameVersion"] = CT_GAME_VERSION_CLASSIC},
	},
	["SHAMAN"] =
	{
		{["name"] = "Purify Spirit", ["modifier"] = "nomod", ["magic"] = true, ["curse"] = true},
		{["name"] = "Cleanse Spirit", ["modifier"] = "nomod", ["curse"] = true},
	},
}


------------------------------------------------
-- CTRA_Configuration_RezAbilities

-- Which ressurection spells could be cast by right-clicking the player frame?  Buffs listed first take precedence.
-- name: 	name of the spell to be cast 			(mandatory)
-- modifier: 	nomod, mod, mod:shift, mod:ctrl, or mod:alt	(mandatory)
-- combat: 	if set, this spell may be cast during combat
-- nocombat:	if set, this spell may be cast outside combat
-- gameVersion: if set, this line only applies to classic or retail using CT_GAME_VERSION_CLASSIC or CT_GAME_VERSION_RETAIL constants
module.CTRA_Configuration_RezAbilities =
{
	["DRUID"] =
	{
		{["name"] = "Rebirth", ["modifier"] = "nomod", ["combat"] = true},
		{["name"] = "Revive", ["modifier"] = "nomod", ["nocombat"] = true},
	},
	["DEATHKNIGHT"] =
	{
		{["name"] = "Raise Ally", ["modifier"] = "nomod", ["combat"] = true, ["nocombat"] = true},
	},
	["WARLOCK"] =
	{
		{["name"] = "Soulstone", ["modifier"] = "nomod", ["combat"] = true, ["gameVersion"] = CT_GAME_VERSION_RETAIL},	--TO DO: Make a classic version that uses the soulstone sitting in the bags
	},
	["PALADIN"] =
	{
		{["name"] = "Redemption", ["modifier"] = "nomod", ["nocombat"] = true},
	},	
	["PRIEST"] =
	{
		{["name"] = "Resurrection", ["modifier"] = "nomod", ["nocombat"] = true},
	},	
	["SHAMAN"] =
	{
		{["name"] = "Ancestral Spirit", ["modifier"] = "nomod", ["nocombat"] = true},
	},
}


------------------------------------------------
-- CTRA_Configuration_BossAuras

-- Which auras associated with boss encounters are important enough to emphasize in the middle of each frame?  Buffs listed first take presedence
-- key: 	spellId
-- value:	0 to always show, or a positive integer to show when the stack count is this number or greater
module.CTRA_Configuration_BossAuras =
{
	-- Classic
	[19702] = 0,		-- Molten Core - Lucifron: Impending Doom
	[19703] = 0,		-- Molten Core - Lucifron: Lucifron's Curse
	[20604] = 0,		-- Molten Core - Lucifron: Dominate Mind
	[19408] = 0,		-- Molten Core - Magmadar: Panic
	[19716] = 0,		-- Molten Core - Gehennas: Gehenna's Curse
	[19658] = 0,		-- Molten Core - Baron Geddon: Ignite Mana
	[20475] = 0,		-- Molten Core - Baron Geddon: Living Bomb
	[19713] = 0,		-- Molten Core - Shazzrah: Shazzrah's Curse
	[13880] = 20,		-- Molten Core - Golemagg the Incinerator: Magma Splash
	[19776] = 0,		-- Molten Core - Sulfuron Harbinger: Shadow Word: Pain
	[20294] = 0,		-- Molten Core - Sulfuron Harbinger: Immolater
	[18431] = 0,		-- Onyxia's Lair - Onyxia: Bellowing Roar

	-- Battle for Azeroth
	[240443] = 1,		-- Mythic Plus: Bursting
	[209858] = 20,		-- Mythic Plus: Necrotic
	[240559] = 1,		-- Mythic Plus: Grievous
	[255558] = 0,		-- Atal'Dazar - Priestess Alun'za: Tainted Blood
	[255371] = 0,		-- Atal'Dazar - Rezan: Terrifying Visage
	[255421] = 0,		-- Atal'Dazar - Rezan: Devour
	[265773] = 0,		-- King's Rest - The Golden Serpent: Spit Gold
	[267626] = 0,		-- King's Rest - Mchimba the Embalmer: Dessication
	[271563] = 5,		-- King's Rest - Embalming Fluid (trash)
	[260907] = 0,		-- Waycrest Manor - Heartsbane Triad: Soul Manipulation
	[260741] = 0,		-- Waycrest Manor - Heartsbane Triad: Jagged Nettles
	[268088] = 3,		-- Waycrest Manor - Heartsbane Triad: Aura of Dread
	[261439] = 0,		-- Waycrest Manor - Lord and Lady Waycrest: Virulent Pathogen
	[264560] = 0,		-- Shrine of the Storm - Aqu'sirr: Choking Brine
	[268211] = 0,		-- Shrine of the Storm - Minor Reinforcing Ward (trash)
	[268215] = 0,		-- Shrine of the Storm - Carve Flesh (trash)
	[267818] = 3,		-- Shrine of the Storm - Tidesage Council: Slicing Blast
	[269131] = 0,		-- Shrine of the Storm - Lord Stormsong: Ancient Mindbender
	[268896] = 0,		-- Shrine of the Storm - Lord Stormsong: Mind Rend
	[260685] = 0,		-- Underrot - Elder Leaxa: Taint of G'huun
	[256044] = 1,		-- Tol Dagor - Overseer Korgus: Deadeye
	[258337] = 0,		-- Freehold - Council o' Captains Blackout Barrel
	[265987] = 8,		-- Temple of Sethraliss - Galvazzt: Galvanized
	[294711] = 5,		-- The Eternal Palace - Abyssal Commander Sivara: Frost Mark
	[294715] = 5,		-- The Eternal Palace - Abyssal Commander Sivara: Toxic Brand
	[292133] = 0,		-- The Eternal Palace - Blackwater Behemoth: Bioluminescence
	[292138] = 0,		-- The Eternal Palace - Blackwater Behemoth: Radiant Biomass
	[296746] = 0,		-- The Eternal Palace - Radiance of Azshara: Arcane Bomb
	[296725] = 0,		-- The Eternal Palace - Lady Ashvane: Barnacle Bash
	[298242] = 0,		-- The Eternal Palace - Orgozoa: Incubation Fluid
	[298156] = 5,		-- The Eternal Palace - Orgozoa: Desensitizing Sting
	[301829] = 5,		-- The Eternal Palace - Queen's Court: Pashmar's Touch
	[292963] = 0,		-- The Eternal Palace - Za'qul: Dread
	[295173] = 0,		-- The Eternal Palace - Za'qul: Fear Realm
	[295249] = 0,		-- The Eternal Palace - Za'qul: Delirium Realm
	[298014] = 3,		-- The Eternal Palace - Queen Azshara: Cold Blast
	[300743] = 2,		-- The Eternal Palace - Queen Azshara: Void Touched
	[298569] = 1,		-- The Eternal Palace - Queen Azshara: Drained Soul
	[307056] = 0,		-- Ny'alotha - Wrathion: Burning Madness
	[306015] = 5,		-- Ny'alotha - Wrathion: Searing Armor
	[313250] = 50,		-- Ny'alotha - Wrathion: Creeping Madness
	[307839] = 0,		-- Ny'alotha - Maut: Devoured Abyss
	[307399] = 5,		-- Ny'alotha - Maut: Arcane Wounds
	[314337] = 1,		-- Ny'alotha - Maut: Ancient Curse
}


------------------------------------------------
-- CTRA_Configuration_Consumables

-- What consumables might raid leaders be interested in tracking during ready checks?  These will appear in tooltips during ready checks only.
-- key: 	spellId
-- value:	true, or a numeric itemID to have the name of that item added in parenthesis (such as disambiguating well-fed buffs)
module.CTRA_Configuration_Consumables =
{
	-- Classic
	[11348] = 13445, -- Elixir of Superior Defense
	[11349] = 8951, -- Elixir of Greater Defense
	[24363] = 20007, -- Mageblood Potion
	[24368] = 20004, -- Major Troll's Blood Potion
	[11390] = true, -- Arcane Elixir
	[11406] = true, -- Elixir of Demonslaying
	[17538] = true, -- Elixir of the Mongoose
	[17539] = true, -- Greater Arcane Elixir
 	[11474] = true, -- Elixir of Shadow Power
 	[26276] = true, -- Elixir of Greater Firepower
	[17626] = true, -- Flask of the Titans
	[17627] = true, -- Flask of Distilled Wisdom 
	[17628] = true, -- Flask of Supreme Power 
	[17629] = true, -- Flask of Chromatic Resistance 
	[17649] = true, -- Greater Arcane Protection Potion
	[17543] = true, -- Greater Fire Protection Potion
	[17544] = true, -- Greater Frost Protection Potion
	[17546] = true, -- Greater Nature Protection Potion
	[17548] = true, -- Greater Shadow Protection Potion
	[18192] = 13928, -- Grilled Squid
	[24799] = 20452, -- Smoked Desert Dumplings
	[18194] = 13931, -- Nightfin Soup
	[22730] = 18254, -- Runn Tum Tuber Suprise
	[25661] = 21023, -- Dirge's Kickin Chimaerok Chops
	[18141] = 13813, -- Blessed Sunfruit Juice
	[18125] = 13810, -- Blessed Sunfruit

	-- Burning Crusade
	[28490] = true, -- Major Strength
	[28491] = true, -- Healing Power
	[28493] = true, -- Major Frost Power
	[28501] = true, -- Major Firepower
	[28503] = true, -- Major Shadow Power
	[33720] = true, -- Onslaught Elixir
	[33721] = true, -- Spellpower Elixir
	[33726] = true, -- Elixir of Mastery
	[38954] = true, -- Fel Strength Elixir
	[45373] = true, -- Bloodberry
	[54452] = true, -- Adept's Elixir
	[54494] = true, -- Major Agility
	[28502] = true, -- Major Armor
	[28509] = true, -- Greater Mana Regeneration
	[28514] = true, -- Empowerment
	[39625] = true, -- Elixir of Major Fortitude
	[39627] = true, -- Elixir of Draenic Wisdom
	[39628] = true, -- Elixir of Ironskin
	[39626] = true, -- Earthen Elixir
	[28518] = true, -- Flask of Fortification
	[28519] = true, -- Flask of Mighty Restoration 
	[28520] = true, -- Flask of Relentless Assault 
	[28521] = true, -- Flask of Blinding Light 
	[28540] = true, -- Flask of Pure Death
	[40567] = true, -- Unstable Flask of the Bandit
	[40568] = true, -- Unstable Flask of the Elder
	[40572] = true, -- Unstable Flask of the Beast
	[40573] = true, -- Unstable Flask of the Physician
	[40575] = true, -- Unstable Flask of the Soldier
	[40576] = true, -- Unstable Flask of the Sorcerer
	[41608] = true, -- Relentless Assault of Shattrath
	[41609] = true, -- Fortification of Shattrath
	[41610] = true, -- Mighty Restoration of Shattrath
	[41611] = true, -- Supreme Power of Shattrath
	[46837] = true, -- Pure Death of Shattrath
	[46839] = true, -- Blinding Light of Shattrath
	
	-- Wrath of the Lich King
	[53747] = true, -- Elixir of Spirit
	[60347] = true, -- Elixir of Mighty Thoughts
	[53764] = true, -- Elixir of Mighty Mageblood
	[53751] = true, -- Elixir of Mighty Fortitude
	[60343] = true, -- Elixir of Mighty Defense
	[53763] = true, -- Elixir of Protection
	[53746] = true, -- Wrath Elixir
	[53749] = true, -- Guru's Elixir
	[53748] = true, -- Elixir of Mighty Strength
	[28497] = true, -- Elixir of Mighty Agility
	[60346] = true, -- Elixir of Lightning Speed
	[60344] = true, -- Elixir of Expertise
	[60341] = true, -- Elixir of Deadly Strikes
	[60340] = true, -- Elixir of Accuracy
	[79474] = true, -- Elixir of the Naga
	[53752] = true, -- Lesser Flask of Toughness
	[53755] = true, -- Flask of the Frost Wyrm
	[53758] = true, -- Flask of Stoneblood
	[54212] = true, -- Flask of Pure Mojo
	[53760] = true, -- Flask of Endless Rage
	[62380] = true, -- Lesser Flask of Resistance
	[67019] = true, -- Flask of the North	

	-- Cataclysm
	[79480] = true, -- Elixir of Deep Earth
	[79631] = true, -- Prismatic Elixir
	[79477] = true, -- Elixir of the Cobra
	[79481] = true, -- Elixir of Impossible Accuracy
	[79632] = true, -- Elixir of Mighty Speed
	[79635] = true, -- Elixir of the Master
	[79469] = true, -- Flask of Steelskin
	[79470] = true, -- Flask of the Draconic Mind
	[79471] = true, -- Flask of the Winds
	[79472] = true, -- Flask of Titanic Strength
	[94160] = true, -- Flask of Flowing Water
	[92729] = true, -- Flask of Steelskin (guild cauldron)
	[92730] = true, -- Flask of the Draconic Mind (guild cauldron)
	[92725] = true, -- Flask of the Winds (guild cauldron)
	[92731] = true, -- Flask of Titanic Strength (guild cauldron)

	-- Mists of Pandaria
	[105681] = true, -- Mantid Elixir
	[105687] = true, -- Elixir of Mirrors
	[105682] = true, -- Mad Hozen Elixir
	[105683] = true, -- Elixir of Weaponry
	[105684] = true, -- Elixir of the Rapids
	[105685] = true, -- Elixir of Peace
	[105686] = true, -- Elixir of Perfection
	[105688] = true, -- Monk's Elixir
	[105689] = true, -- Flask of Spring Blossoms
	[105691] = true, -- Flask of the Warm Sun
	[105693] = true, -- Flask of Falling Leaves
	[105694] = true, -- Flask of the Earth
	[105696] = true, -- Flask of Winter's Bite
	[105617] = true, -- Alchemist's Flask
	[127230] = true, -- Crystal of Insanity
        
	-- Warlords of Draenor
	[156080] = true, -- Greater Draenic Strength Flask
	[156084] = true, -- Greater Draenic Stamina Flask
	[156079] = true, -- Greater Draenic Intellect Flask
	[156064] = true, -- Greater Draenic Agility Flask
	[156071] = true, -- Draenic Strength Flask
	[156077] = true, -- Draenic Stamina Flask
	[156070] = true, -- Draenic Intellect Flask
	[156073] = true, -- Draenic Agility Flask
	[176151] = true, -- Whispers of Insanity
	
	-- Legion
	[188031] = true, -- Flask of the Whispered Pact
	[188033] = true, -- Flask of the Seventh Demon
	[188034] = true, -- Flask of the Countless Armies
	[188035] = true, -- Flask of Ten Thousand Scars
	[242551] = true, -- Repurposed Fel Focuser
	[224001] = true, -- Defiled Augment Rune
	
	-- Battle for Azeroth
	[251839] = true, -- Flask of the Undertow
	[251838] = true, -- Flask of the Vast Horizon
	[251837] = true, -- Flask of the Endless Fathoms
	[251836] = true, -- Flask of the Currents
	[298841] = true, -- Greater Flask of the Undertow
	[298839] = true, -- Greater Flask of the Vast Horizon
	[298837] = true, -- Greater Flask of Endless Fathoms
	[298836] = true, -- Greater Flask of the Currents
	[270058] = true, -- Battle-Scarred Augment Rune
	[279639] = true, -- Galley Banquet
	[288076] = true, -- Seasoned Steak and Potatoes
	[257410] = 154882, -- Honey-Glazed Haunches
	[257415] = 154884, -- Swamp Fish 'n Chips
	[257420] = 154888, -- Sailor's Pie
	[257424] = 154886, -- Spiced Snapper
	[290467] = 166804, -- Boralus Blood Sausage (Agi)
	[290468] = 166804, -- Boralus Blood Sausage (Int)
	[290478] = 166804, -- Boralus Blood Sausage (Str)
	[259454] = 156526, -- Bountiful Captain's Feast or Sanguinated Feast (Agi)
	[259455] = 156526, -- Bountiful Captain's Feast or Sanguinated Feast (Int)
	[259456] = 156526, -- Bountiful Captain's Feast or Sanguinated Feast (Str)
	[297039] = 168310, -- Mech-Dowel's "Big Mech"
	[297034] = 168313, -- Baked Port Tato
	[297035] = 168311, -- Abyssal-Fried Rissole
	[297037] = 168314, -- Bil-Tong
	[297040] = 168312, -- Fragrant Kakavia
	[297116] = 168315, -- Famine Evaluator And Snack Table (Agi)
	[297117] = 168315, -- Famine Evaluator And Snack Table (Int)
	[297118] = 168315, -- Famine Evaluator And Snack Table (Str)
} 