local module = CT_BuffMod;

BINDING_HEADER_CT_BUFFMOD = "CT_BuffMod";
BINDING_NAME_CT_BUFFMOD_RECASTBUFFS = "Recast Buffs";

module:setText("BUFFNAME_CHARGES", "%s (%d charges)");

module.text = { };
local L = module.text;

-- enUS (used as the default in all languages if there is no localized alternative)

L["CT_BuffMod/PRE_EXPIRATION_WARNING"] = "The |cFFFFFFFF%s|r buff will expire in |cFFFFFFFF%s|r."
L["CT_BuffMod/PRE_EXPIRATION_WARNING_KEYBINDING"] = "The |cFFFFFFFF%s|r buff will expire in |cFFFFFFFF%s|r. Press |cFFFFFFFF%s|r while out of combat to recast."
L["CT_BuffMod/TimeFormat/Day Singular"] = "1 day"
L["CT_BuffMod/TimeFormat/Days Plural"] = "%d days"
L["CT_BuffMod/TimeFormat/Hour Singular"] = "1 hour"
L["CT_BuffMod/TimeFormat/Hours Plural"] = "%d hours"
L["CT_BuffMod/TimeFormat/Minute Singular"] = "1 minute"
L["CT_BuffMod/TimeFormat/Minutes Plural"] = "%d minutes"
L["CT_BuffMod/TimeFormat/Seconds Plural"] = "%d seconds"
L["CT_BuffMod/Options/Blizzard Frames/Heading"] = "Blizzard's Default Frames"
L["CT_BuffMod/Options/Blizzard Frames/Hide Buffs"] = "Hide the default buffs frame"
L["CT_BuffMod/Options/Blizzard Frames/Hide Consolidated"] = "Hide the default consolidated buffs frame"
L["CT_BuffMod/Options/Blizzard Frames/Hide Enchants"] = "Hide the default weapon buffs frame"
L["CT_BuffMod/Options/General/Colors/Aura"] = "Aura"
L["CT_BuffMod/Options/General/Colors/Background"] = "Window background"
L["CT_BuffMod/Options/General/Colors/Buff"] = "Buff"
L["CT_BuffMod/Options/General/Colors/Debuff"] = "Debuff"
L["CT_BuffMod/Options/General/Colors/Heading"] = "Colors"
L["CT_BuffMod/Options/General/Colors/Weapon"] = "Weapon"
L["CT_BuffMod/Options/General/Heading"] = "General Settings"
L["CT_BuffMod/Options/Tips/Heading"] = "Tips"
L["CT_BuffMod/Options/Tips/Line 1"] = "You can use /ctbuff or /ctbuffmod to open this options window directly."
L["CT_BuffMod/Options/Tips/Line 2"] = "You can set and configure different windows to show the auras. Alt-click left on a window to select it."
L["CT_BuffMod/Options/Tips/Line 3"] = "NOTE: Most options have no effect until you are out of combat."
L["CT_BuffMod/Options/Window/Time Remaining/Duration Format Dropdown"] = "1 hour  -  22 minutes#1 hour  -  22 min#1h  -  22m#1h 11m  -  22m 22s#1:11h  -  22:22"



-- frFR (missing translations will just use the default enUS one at the top)

if (GetLocale() == "frFR") then

L["CT_BuffMod/PRE_EXPIRATION_WARNING"] = "L'aura |cFFFFFFFF%s|r expire dans |cFFFFFFFF%s|r."
L["CT_BuffMod/PRE_EXPIRATION_WARNING_KEYBINDING"] = "L'aura |cFFFFFFFF%s|r expire dans |cFFFFFFFF%s|r.  Appuyer sur |cFFFFFFFF%s|r pour le réappliquer"
L["CT_BuffMod/TimeFormat/Day Singular"] = "1 jour"
L["CT_BuffMod/TimeFormat/Days Plural"] = "%d jours"
L["CT_BuffMod/TimeFormat/Hour Singular"] = "1 heure"
L["CT_BuffMod/TimeFormat/Hours Plural"] = "%d heures"
L["CT_BuffMod/TimeFormat/Minute Singular"] = "1 minute"
L["CT_BuffMod/TimeFormat/Minutes Plural"] = "%d minutes"
L["CT_BuffMod/TimeFormat/Seconds Plural"] = "%d secondes"
L["CT_BuffMod/Options/Blizzard Frames/Hide Buffs"] = "Cacher le cadre défaut des auras"
L["CT_BuffMod/Options/Blizzard Frames/Hide Consolidated"] = "Cacher le cadre défaut des auras consolidés"
L["CT_BuffMod/Options/Blizzard Frames/Hide Enchants"] = "Cacher le cadre défaut des auras d'armes"
L["CT_BuffMod/Options/General/Colors/Aura"] = "Aura générale"
L["CT_BuffMod/Options/General/Colors/Background"] = "Fond de la fenêtre"
L["CT_BuffMod/Options/General/Colors/Buff"] = "Aura utile"
L["CT_BuffMod/Options/General/Colors/Debuff"] = "Aura nocive"
L["CT_BuffMod/Options/General/Colors/Heading"] = "Des couleurs "
L["CT_BuffMod/Options/General/Colors/Weapon"] = "Aura d'arme"
L["CT_BuffMod/Options/General/Heading"] = "Options générales"
L["CT_BuffMod/Options/Tips/Heading"] = "Des conseils"
L["CT_BuffMod/Options/Tips/Line 1"] = "Vous pouvez taper /cbuff ou /ctaura pour accéder ces options."
L["CT_BuffMod/Options/Tips/Line 2"] = "Vous pouvez placer et configurer des fenêtres différents pour montrer les auras.  Alt-clic gauche sur une fenêtre pour le sélectionner."
L["CT_BuffMod/Options/Tips/Line 3"] = "Le plupart des options ne fonctionne que hors combat."
L["CT_BuffMod/Options/Window/Time Remaining/Duration Format Dropdown"] = "1 heure  -  22 minutes#1 heure  -  22 min#1h  -  22m#1h 11m  -  22m 22s#1:11h  -  22:22"






end
