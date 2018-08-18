CT_RAMENU_HOME = "Thanks for checking out CT_RaidAssist! Below you can find the various options sorted into different sections. If you're using it for the first time, check out the General Options page to get started. More advanced users should take a look through the other options pages to modify the settings to fit your needs.\n\nFor additional commands and information, type |c00FFFFFF/rahelp|r.";
CT_RAMENU_OPTIONSETS = "Option sets allow you to save all aspects of CT_RaidAssist, then change to another set with the click of a button. Group positions, type of sorting, debuff and buff status, which windows are shown, etc. are all saved when an option set is stored. You must save changes after modifying settings in order for them to be saved to that set.";
CT_RAMENU_BOSSMODS = "Boss mods are mods that can assist you in specific encounters.  They help to provide warnings when important events happen, and notifications to help you survive.  Some of the mods have their own set of options, so be sure to modify them to meet your specific needs.";

CT_RAMENU_BUFFSDESCRIPT = "Select the buffs and debuffs you would like to show. A max of 4 buffs can be shown at once. Debuffs will change the color of the window to the color you select.";
CT_RAMENU_BUFFSTOOLTIP = "Use the arrows to move buffs up or down. If more than the limit are shown, the top ones take priority.";
CT_RAMENU_DEBUFFSTOOLTIP = "Use the arrows to move debuffs up or down. If more than the limit are shown, the top ones take priority.";
CT_RAMENU_GENERALDESCRIPT = "Below you will find options to change the way things are displayed. Turning on a Unit's Target will show you the target of players who are set to be Assist Targets. Leaders or promoted can right click a player in the CTRaid window and set them as an Assist Target. Up to 10 people can have their targets displayed at once. Raid leaders and promoted can press the Update Status button to update main tank information for everyone in the raid.";
CT_RAMENU_REPORTDESCRIPT = "Checking a button makes you report health and mana for the person you checked. If you or the person leaves the party, you will stop reporting automatically.";
CT_RAMENU_ADDITIONALEMTOOLTIP = "The Emergency Monitor displays health of up to 5 members in your party or raid with the lowest health percent. You can set the health threshold, where members with more health than the threshold is set to will not be shown.";
CT_RAMENU_MANACONSERVE = "Setting the value to %s will disable checking for that spell.";

BINDING_HEADER_CT_RAIDASSIST = "CT_RaidAssist";
BINDING_NAME_CT_SHOWHIDE = "Show/Hide Raid Windows";
BINDING_NAME_CT_RESMON = "Toggle Resurrection Monitor";
BINDING_NAME_CT_EMERGENCYMONITOR = "Show/Hide Emergency Monitor";
BINDING_NAME_CT_TOGGLEDEBUFFS = "Toggle Buff/Debuff view";
BINDING_NAME_CT_ASSISTMT1 = "Assist MT 1";
BINDING_NAME_CT_ASSISTMT2 = "Assist MT 2";
BINDING_NAME_CT_ASSISTMT3 = "Assist MT 3";
BINDING_NAME_CT_ASSISTMT4 = "Assist MT 4";
BINDING_NAME_CT_ASSISTMT5 = "Assist MT 5";
BINDING_NAME_CT_TARGETMT1 = "Target MT 1's Target's Target";
BINDING_NAME_CT_TARGETMT2 = "Target MT 2's Target's Target";
BINDING_NAME_CT_TARGETMT3 = "Target MT 3's Target's Target";
BINDING_NAME_CT_TARGETMT4 = "Target MT 4's Target's Target";
BINDING_NAME_CT_TARGETMT5 = "Target MT 5's Target's Target";
BINDING_NAME_CT_ASSISTPT1 = "Assist PT 1";
BINDING_NAME_CT_ASSISTPT2 = "Assist PT 2";
BINDING_NAME_CT_ASSISTPT3 = "Assist PT 3";
BINDING_NAME_CT_ASSISTPT4 = "Assist PT 4";
BINDING_NAME_CT_ASSISTPT5 = "Assist PT 5";
BINDING_NAME_CT_TARGETPT1 = "Target PT 1";
BINDING_NAME_CT_TARGETPT2 = "Target PT 2";
BINDING_NAME_CT_TARGETPT3 = "Target PT 3";
BINDING_NAME_CT_TARGETPT4 = "Target PT 4";
BINDING_NAME_CT_TARGETPT5 = "Target PT 5";
BINDING_NAME_CT_TOGGLESORTTYPE = "Toggle Group/Class Sorting";
BINDING_NAME_CT_TARGETEM1 = "Target Emergency Monitor Unit 1";
BINDING_NAME_CT_TARGETEM2 = "Target Emergency Monitor Unit 2";
BINDING_NAME_CT_TARGETEM3 = "Target Emergency Monitor Unit 3";
BINDING_NAME_CT_TARGETEM4 = "Target Emergency Monitor Unit 4";
BINDING_NAME_CT_TARGETEM5 = "Target Emergency Monitor Unit 5";

CT_RAMENU_VISITSITE = "For more information on CT mods, or for suggestions, comments, or questions not answered here, please visit us at http://www.ctmod.net";

-- Classes
CT_RA_CLASS_WARRIOR = "Warrior";
CT_RA_CLASS_ROGUE = "Rogue";
CT_RA_CLASS_HUNTER = "Hunter";
CT_RA_CLASS_MAGE = "Mage";
CT_RA_CLASS_WARLOCK = "Warlock";
CT_RA_CLASS_DRUID = "Druid";
CT_RA_CLASS_PRIEST = "Priest";
CT_RA_CLASS_SHAMAN = "Shaman";
CT_RA_CLASS_PALADIN = "Paladin";
CT_RA_CLASS_DEATHKNIGHT = "Death Knight";
CT_RA_CLASS_MONK = "Monk";
CT_RA_CLASS_DEMONHUNTER = "Demon Hunter";

-- Messages
CT_RA_MESSAGE_AFK = "You are now Away: (.+)";
CT_RA_MESSAGE_DND = "You are now Busy: (.+)";

-- Debuff types
CT_RA_DEBUFFTYPE_MAGIC = "Magic";
CT_RA_DEBUFFTYPE_DISEASE = "Disease";
CT_RA_DEBUFFTYPE_POISON = "Poison";
CT_RA_DEBUFFTYPE_CURSE = "Curse";

-- RAReg/RADur
CT_RA_DURABILITY = "^Durability (%d+) / (%d+)$";
CT_RA_REAGENT_MAGE = "Arcane Powder";
CT_RA_REAGENT_DRUID = "Maple Seed";
CT_RA_REAGENT_SHAMAN = "Ankh";

-- Patterns
CT_RA_PATTERN_HAS_JOINED_RAID = "^([^%s]+) has joined the raid group$";
CT_RA_PATTERN_HAS_LEFT_RAID = "^([^%s]+) has left the raid group$";
CT_RA_PATTERN_TANK_HAS_DIED = "^([^%s]+) dies%.$";
