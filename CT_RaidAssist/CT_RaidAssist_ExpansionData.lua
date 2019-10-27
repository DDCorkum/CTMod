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
		{["name"] = "Purify Disease", ["modifier"] = "nomod", ["disease"] = true, ["gameVersion"] = CT_GAME_VERSION_RETAIL},
		{["name"] = "Purify", ["modifier"] = "nomod", ["magic"] = true, ["disease"] = true, ["gameVersion"] = CT_GAME_VERSION_RETAIL},
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

-- Which debuffs associated with boss encounters are super important and worth putting in the middle of the frame
-- This table is only required when Blizzard's UnitAura() api does not return true for isBossDebuff (12th return value)
-- key: 	spellId
-- value:	0 to always show, or a positive integer to show when the stack count is this number or greater
module.CTRA_Configuration_BossAuras =
{
	-- Classic
	[19702] = 0,		-- Lucifron: Impending Doom
	[19703] = 0,		-- Lucifron: Lucifron's Curse
	[20604] = 0,		-- Lucifron: Dominate Mind
	[19408] = 0,		-- Magmadar: Panic
	[19716] = 0,		-- Gehennas: Gehenna's Curse
	[19658] = 0,		-- Baron Geddon: Ignite Mana
	[20475] = 0,		-- Baron Geddon: Living Bomb
	[19713] = 0,		-- Shazzrah: Shazzrah's Curse
	[13880] = 20,		-- Golemagg the Incinerator: Magma Splash
	[19776] = 0,		-- Sulfuron Harbinger: Shadow Word: Pain
	[20294] = 0,		-- Sulfuron Harbinger: Immolate
	[18431] = 0,		-- Onyxia: Bellowing Roar
	
	-- Battle for Azeroth
	[294711] = 5,		-- Abyssal Commander Sivara: Frost Mark
	[294715] = 5,		-- Abyssal Commander Sivara: Toxic Brand
	[292133] = 0,		-- Blackwater Behemoth: Bioluminescence
	[292138] = 0,		-- Blackwater Behemoth: Radiant Biomass
	[296746] = 0,		-- Radiance of Azshara: Arcane Bomb
	[296725] = 0,		-- Lady Ashvane: Barnacle Bash
	[298242] = 0,		-- Orgozoa: Incubation Fluid
	[298156] = 5,		-- Orgozoa: Desensitizing Sting
	[301829] = 5,		-- Queen's Court: Pashmar's Touch
	[292963] = 0,		-- Za'qul: Dread
	[295173] = 0,		-- Za'qul: Fear Realm
	[295249] = 0,		-- Za'qul: Delirium Realm
	[298014] = 3,		-- Queen Azshara: Cold Blast
	[300743] = 2,		-- Queen Azshara: Void Touched
	[298569] = 1,		-- Queen Azshara: Drained Soul
}


------------------------------------------------
-- CTRA_Configuration_Consumables

-- What consumables might raid leaders be interested in tracking during ready checks?  These will appear in tooltips during ready checks only.
-- key: 	spellId
-- value:	anything that evaluates to true
module.CTRA_Configuration_Consumables =
{
	-- Classic
	[11348] = 1, -- Elixir of Superior Defense
	[11396] = 1, -- Greater Intellect
	[24363] = 1, -- Mageblood Potion
	[11390] = 1, -- Arcane Elixir
	[11406] = 1, -- Elixir of Demonslaying
	[17538] = 1, -- Elixir of the Mongoose
	[17539] = 1, -- Greater Arcane Elixir
 	[11474] = 1, -- Elixir of Shadow Power
 	[26276] = 1, -- Elixir of Greater Firepower
	[17626] = 1, -- Flask of the Titans
	[17627] = 1, -- Flask of Distilled Wisdom 
	[17628] = 1, -- Flask of Supreme Power 
	[17629] = 1, -- Flask of Chromatic Resistance 
	[24368] = 1, -- Major Troll's Blood Potion
	[17649] = 1, -- Greater Arcane Protection Potion
	[17543] = 1, -- Greater Fire Protection Potion
	[17544] = 1, -- Greater Frost Protection Potion
	[17546] = 1, -- Greater Nature Protection Potion
	[17548] = 1, -- Greater Shadow Protection Potion
	[18192] = 1, -- Grilled Squid
	[24799] = 1, -- Smoked Desert Dumplings
	[18194] = 1, -- Nightfin Soup
	[22730] = 1, -- Runn Tum Tuber Suprise
	[25661] = 1, -- Dirge's Kickin Chimaerok Chops
	[18141] = 1, -- Blessed Sunfruit Juice
	[18125] = 1, -- Blessed Sunfruit

	-- Burning Crusade
	[28490] = 1, -- Major Strength
	[28491] = 1, -- Healing Power
	[28493] = 1, -- Major Frost Power
	[28501] = 1, -- Major Firepower
	[28503] = 1, -- Major Shadow Power
	[33720] = 1, -- Onslaught Elixir
	[33721] = 1, -- Spellpower Elixir
	[33726] = 1, -- Elixir of Mastery
	[38954] = 1, -- Fel Strength Elixir
	[45373] = 1, -- Bloodberry
	[54452] = 1, -- Adept's Elixir
	[54494] = 1, -- Major Agility
	[28502] = 1, -- Major Armor
	[28509] = 1, -- Greater Mana Regeneration
	[28514] = 1, -- Empowerment
	[39625] = 1, -- Elixir of Major Fortitude
	[39627] = 1, -- Elixir of Draenic Wisdom
	[39628] = 1, -- Elixir of Ironskin
	[39626] = 1, -- Earthen Elixir
	[28518] = 1, -- Flask of Fortification
	[28519] = 1, -- Flask of Mighty Restoration 
	[28520] = 1, -- Flask of Relentless Assault 
	[28521] = 1, -- Flask of Blinding Light 
	[28540] = 1, -- Flask of Pure Death
	[40567] = 1, -- Unstable Flask of the Bandit
	[40568] = 1, -- Unstable Flask of the Elder
	[40572] = 1, -- Unstable Flask of the Beast
	[40573] = 1, -- Unstable Flask of the Physician
	[40575] = 1, -- Unstable Flask of the Soldier
	[40576] = 1, -- Unstable Flask of the Sorcerer
	[41608] = 1, -- Relentless Assault of Shattrath
	[41609] = 1, -- Fortification of Shattrath
	[41610] = 1, -- Mighty Restoration of Shattrath
	[41611] = 1, -- Supreme Power of Shattrath
	[46837] = 1, -- Pure Death of Shattrath
	[46839] = 1, -- Blinding Light of Shattrath
	
	-- Wrath of the Lich King
	[53747] = 1, -- Elixir of Spirit
	[60347] = 1, -- Elixir of Mighty Thoughts
	[53764] = 1, -- Elixir of Mighty Mageblood
	[53751] = 1, -- Elixir of Mighty Fortitude
	[60343] = 1, -- Elixir of Mighty Defense
	[53763] = 1, -- Elixir of Protection
	[53746] = 1, -- Wrath Elixir
	[53749] = 1, -- Guru's Elixir
	[53748] = 1, -- Elixir of Mighty Strength
	[28497] = 1, -- Elixir of Mighty Agility
	[60346] = 1, -- Elixir of Lightning Speed
	[60344] = 1, -- Elixir of Expertise
	[60341] = 1, -- Elixir of Deadly Strikes
	[60340] = 1, -- Elixir of Accuracy
	[79474] = 1, -- Elixir of the Naga
	[53752] = 1, -- Lesser Flask of Toughness
	[53755] = 1, -- Flask of the Frost Wyrm
	[53758] = 1, -- Flask of Stoneblood
	[54212] = 1, -- Flask of Pure Mojo
	[53760] = 1, -- Flask of Endless Rage
	[62380] = 1, -- Lesser Flask of Resistance
	[67019] = 1, -- Flask of the North	

	-- Cataclysm
	[79480] = 1, -- Elixir of Deep Earth
	[79631] = 1, -- Prismatic Elixir
	[79477] = 1, -- Elixir of the Cobra
	[79481] = 1, -- Elixir of Impossible Accuracy
	[79632] = 1, -- Elixir of Mighty Speed
	[79635] = 1, -- Elixir of the Master
	[79469] = 1, -- Flask of Steelskin
	[79470] = 1, -- Flask of the Draconic Mind
	[79471] = 1, -- Flask of the Winds
	[79472] = 1, -- Flask of Titanic Strength
	[94160] = 1, -- Flask of Flowing Water
	[92729] = 1, -- Flask of Steelskin (guild cauldron)
	[92730] = 1, -- Flask of the Draconic Mind (guild cauldron)
	[92725] = 1, -- Flask of the Winds (guild cauldron)
	[92731] = 1, -- Flask of Titanic Strength (guild cauldron)

	-- Mists of Pandaria
	[105681] = 1, -- Mantid Elixir
	[105687] = 1, -- Elixir of Mirrors
	[105682] = 1, -- Mad Hozen Elixir
	[105683] = 1, -- Elixir of Weaponry
	[105684] = 1, -- Elixir of the Rapids
	[105685] = 1, -- Elixir of Peace
	[105686] = 1, -- Elixir of Perfection
	[105688] = 1, -- Monk's Elixir
	[105689] = 1, -- Flask of Spring Blossoms
	[105691] = 1, -- Flask of the Warm Sun
	[105693] = 1, -- Flask of Falling Leaves
	[105694] = 1, -- Flask of the Earth
	[105696] = 1, -- Flask of Winter's Bite
	[105617] = 1, -- Alchemist's Flask
	[127230] = 1, -- Crystal of Insanity
        
	-- Warlords of Draenor
	[156080] = 1, -- Greater Draenic Strength Flask
	[156084] = 1, -- Greater Draenic Stamina Flask
	[156079] = 1, -- Greater Draenic Intellect Flask
	[156064] = 1, -- Greater Draenic Agility Flask
	[156071] = 1, -- Draenic Strength Flask
	[156077] = 1, -- Draenic Stamina Flask
	[156070] = 1, -- Draenic Intellect Flask
	[156073] = 1, -- Draenic Agility Flask
	[176151] = 1, -- Whispers of Insanity
	
	-- Legion
	[188031] = 1, -- Flask of the Whispered Pact
	[188033] = 1, -- Flask of the Seventh Demon
	[188034] = 1, -- Flask of the Countless Armies
	[188035] = 1, -- Flask of Ten Thousand Scars
	[242551] = 1, -- Repurposed Fel Focuser
	[224001] = 1, -- Defiled Augment Rune
	
	-- Battle for Azeroth
	[251839] = 1, -- Flask of the Undertow
	[251838] = 1, -- Flask of the Vast Horizon
	[251837] = 1, -- Flask of the Endless Fathoms
	[251836] = 1, -- Flask of the Currents
	[298841] = 1, -- Greater Flask of the Undertow
	[298839] = 1, -- Greater Flask of the Vast Horizon
	[298837] = 1, -- Greater Flask of Endless Fathoms
	[298836] = 1, -- Greater Flask of the Currents
	[270058] = 1, -- Battle-Scarred Augment Rune
	[279639] = 1, -- Galley BanqueT
	[279640] = 1, -- Bountiful Captain's Feast
	[288076] = 1, -- Seasoned Steak and Potatoes
	[290743] = 1, -- Boralus Blood Sausage
	[311502] = 1, -- Sanguinated Feast
	[297039] = 1, -- Mech-Dowel's "Big Mech"
	[297034] = 1, -- Baked Port Tato
	[297035] = 1, -- Abyssal-Fried Rissole
	[297037] = 1, -- Bil-Tong
	[297040] = 1, -- Fragrant Kakavia
	[297048] = 1, -- Famine Evaluator And Snack Table
} 