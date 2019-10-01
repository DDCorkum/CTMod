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
L["CT_BuffMod/TimeFormat/Days Abbreviated"] = "%dd"
L["CT_BuffMod/TimeFormat/Days Digital"] = "%dd, %d:%.2dh"
L["CT_BuffMod/TimeFormat/Days Plural"] = "%d days"
L["CT_BuffMod/TimeFormat/Days Smaller"] = "%d day"
L["CT_BuffMod/TimeFormat/Hour Singular"] = "1 hour"
L["CT_BuffMod/TimeFormat/Hours Abbreviated"] = "%dh"
L["CT_BuffMod/TimeFormat/Hours Digital"] = "%d:%.2dh"
L["CT_BuffMod/TimeFormat/Hours Plural"] = "%d hours"
L["CT_BuffMod/TimeFormat/Hours Smaller"] = "%d hour"
L["CT_BuffMod/TimeFormat/Minute Singular"] = "1 minute"
L["CT_BuffMod/TimeFormat/Minutes Abbreviated"] = "%dm"
L["CT_BuffMod/TimeFormat/Minutes Digital"] = "%d:%.2d"
L["CT_BuffMod/TimeFormat/Minutes Plural"] = "%d minutes"
L["CT_BuffMod/TimeFormat/Minutes Smaller"] = "%d min"
L["CT_BuffMod/TimeFormat/Minutes Two Digits"] = "%.2dm"
L["CT_BuffMod/TimeFormat/Off"] = "Off"
L["CT_BuffMod/TimeFormat/Seconds Abbreviated"] = "%ds"
L["CT_BuffMod/TimeFormat/Seconds Plural"] = "%d seconds"
L["CT_BuffMod/TimeFormat/Seconds Smaller"] = "%d sec"
L["CT_BuffMod/TimeFormat/Seconds Two Digits"] = "%.2ds"
L["CT_BuffMod/WindowTitle"] = "Window %d"
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
L["CT_BuffMod/Options/General/Expiration/ChatMessageCheckbox"] = "Enable chat warning message"
L["CT_BuffMod/Options/General/Expiration/DurationHeading"] = "Buff Duration"
L["CT_BuffMod/Options/General/Expiration/FlashSliderLabel"] = "Flash icon before expiry:"
L["CT_BuffMod/Options/General/Expiration/Heading"] = "Expiration"
L["CT_BuffMod/Options/General/Expiration/PlayerBuffsOnlyCheckbox"] = "Only buffs you can cast"
L["CT_BuffMod/Options/General/Expiration/PlaySoundCheckbox"] = "Play sound when warning appears"
L["CT_BuffMod/Options/General/Expiration/WarningTimeHeading"] = "Show Warning At"
L["CT_BuffMod/Options/General/Heading"] = "General Settings"
L["CT_BuffMod/Options/Tips/Heading"] = "Tips"
L["CT_BuffMod/Options/Tips/Line 1"] = "You can use /ctbuff or /ctbuffmod to open this options window directly."
L["CT_BuffMod/Options/Tips/Line 2"] = "You can set and configure different windows to show the auras. Alt-click left on a window to select it."
L["CT_BuffMod/Options/Tips/Line 3"] = "NOTE: Most options have no effect until you are out of combat."
L["CT_BuffMod/Options/Window/Time Remaining/Duration Format Dropdown"] = "1 hour  -  22 minutes#1 hour  -  22 min#1h  -  22m#1h 11m  -  22m 22s#1:11h  -  22:22"
L["CT_BuffMod/Options/Window/Unit/Heading"] = "Unit"
L["CT_BuffMod/Options/Window/Unit/NonSecureCheckbox"] = "Use non-secure buff buttons"
L["CT_BuffMod/Options/Window/Unit/SecureTooltip/Content"] = [=[|cFFFFAA00Secure buff buttons:
|cFFFFFFFF- Spell buffs can be cancelled |cFFFFFF00any |cFFFFFFFFtime.
|cFFFFFFFF- Weapon buffs can be cancelled |cFFFFFF00any |cFFFFFFFFtime.

|cFFFFAA00Non-secure buff buttons:
|cFFFFFFFF- Spell buffs can be canceled |cFFFF3333outside combat|cFFFFFFFF.
|cFFFFFFFF- Weapon buffs |cFFFF3333cannot |cFFFFFFFFbe cancelled.
|cFFFFFFFF- Additional sorting option: 'non-expiring buffs'
|cFFFFFFFF- Compability mode to resolve addon conflicts]=]
L["CT_BuffMod/Options/Window/Unit/SecureTooltip/Heading"] = "Secure and Non-secure Buttons"
L["CT_BuffMod/Options/Window/Unit/UnitDropdownLabel"] = "Show buffs for:"
L["CT_BuffMod/Options/Window/Unit/UnitDropdownOptions"] = "#Player#Vehicle#Pet#Target#Focus"
L["CT_BuffMod/Options/Window/Unit/VehicleCheckbox"] = "Show vehicle buffs when in a vehicle"
L["CT_BuffMod/Options/WindowControls/AddButton"] = "Add"
L["CT_BuffMod/Options/WindowControls/AddTooltip"] = "Add a new window with default settings."
L["CT_BuffMod/Options/WindowControls/AltClickHint"] = "Alt click to select."
L["CT_BuffMod/Options/WindowControls/CloneButton"] = "Clone"
L["CT_BuffMod/Options/WindowControls/CloneTooltip"] = "Add a new window with settings that duplicate those of the currently selected window."
L["CT_BuffMod/Options/WindowControls/DeleteButton"] = "Delete"
L["CT_BuffMod/Options/WindowControls/DeleteTooltip"] = "|cFFFFFF00Shift-click|r this button to delete the currently selected window."
L["CT_BuffMod/Options/WindowControls/SelectionLabel"] = "Select window:"
L["CT_BuffMod/Options/WindowControls/Tip"] = "Options below this point only affect the selected window."
L["CT_BuffMod/Options/WindowControls/WindowAddedMessage"] = "Window %d added."
L["CT_BuffMod/Options/WindowControls/WindowClonedMessage"] = "Window %d added, copying settings from window %d."
L["CT_BuffMod/Options/WindowControls/WindowDeletedMessage"] = "Window %d deleted."
L["CT_BuffMod/Options/WindowControls/WindowSelectedMessage"] = "Window %d selected."


if (GetLocale() == "frFR") then


L["CT_BuffMod/PRE_EXPIRATION_WARNING"] = "L'aura |cFFFFFFFF%s|r expire dans |cFFFFFFFF%s|r."
L["CT_BuffMod/PRE_EXPIRATION_WARNING_KEYBINDING"] = "L'aura |cFFFFFFFF%s|r expire dans |cFFFFFFFF%s|r.  Appuyer sur |cFFFFFFFF%s|r pour le réappliquer"
L["CT_BuffMod/TimeFormat/Day Singular"] = "1 jour"
L["CT_BuffMod/TimeFormat/Days Abbreviated"] = "%dj"
L["CT_BuffMod/TimeFormat/Days Digital"] = "$dj, %d:%.2dh"
L["CT_BuffMod/TimeFormat/Days Plural"] = "%d jours"
L["CT_BuffMod/TimeFormat/Days Smaller"] = "%d jour"
L["CT_BuffMod/TimeFormat/Hour Singular"] = "1 heure"
L["CT_BuffMod/TimeFormat/Hours Abbreviated"] = "%d heure"
L["CT_BuffMod/TimeFormat/Hours Digital"] = "%d:%.2dh"
L["CT_BuffMod/TimeFormat/Hours Plural"] = "%d heures"
L["CT_BuffMod/TimeFormat/Hours Smaller"] = "%d heure"
L["CT_BuffMod/TimeFormat/Minute Singular"] = "1 minute"
L["CT_BuffMod/TimeFormat/Minutes Abbreviated"] = "%dm"
L["CT_BuffMod/TimeFormat/Minutes Digital"] = "%d:%.2d"
L["CT_BuffMod/TimeFormat/Minutes Plural"] = "%d minutes"
L["CT_BuffMod/TimeFormat/Minutes Smaller"] = "%d min"
L["CT_BuffMod/TimeFormat/Minutes Two Digits"] = "%.2dm"
L["CT_BuffMod/TimeFormat/Off"] = "Fermé"
L["CT_BuffMod/TimeFormat/Seconds Abbreviated"] = "%ds"
L["CT_BuffMod/TimeFormat/Seconds Plural"] = "%d secondes"
L["CT_BuffMod/TimeFormat/Seconds Smaller"] = "%d sec"
L["CT_BuffMod/TimeFormat/Seconds Two Digits"] = "%.2ds"
L["CT_BuffMod/WindowTitle"] = "Fenêtre %d"
L["CT_BuffMod/Options/Blizzard Frames/Hide Buffs"] = "Cacher le cadre défaut des auras"
L["CT_BuffMod/Options/Blizzard Frames/Hide Consolidated"] = "Cacher le cadre défaut des auras consolidés"
L["CT_BuffMod/Options/Blizzard Frames/Hide Enchants"] = "Cacher le cadre défaut des auras d'armes"
L["CT_BuffMod/Options/General/Colors/Aura"] = "Aura générale"
L["CT_BuffMod/Options/General/Colors/Background"] = "Fond de la fenêtre"
L["CT_BuffMod/Options/General/Colors/Buff"] = "Aura utile"
L["CT_BuffMod/Options/General/Colors/Debuff"] = "Aura nocive"
L["CT_BuffMod/Options/General/Colors/Heading"] = "Des couleurs "
L["CT_BuffMod/Options/General/Colors/Weapon"] = "Aura d'arme"
L["CT_BuffMod/Options/General/Expiration/ChatMessageCheckbox"] = "Annoncer les auras avant leurs expirations"
L["CT_BuffMod/Options/General/Expiration/DurationHeading"] = "Duration de l'aura"
L["CT_BuffMod/Options/General/Expiration/FlashSliderLabel"] = [=[Clignoter l'icône 
avant l'expiration :]=]
L["CT_BuffMod/Options/General/Expiration/Heading"] = "L'expiration des auras"
L["CT_BuffMod/Options/General/Expiration/PlayerBuffsOnlyCheckbox"] = "Seulement les auras que vous renouvelez."
L["CT_BuffMod/Options/General/Expiration/PlaySoundCheckbox"] = "Jouer un son avec l'annonce"
L["CT_BuffMod/Options/General/Expiration/WarningTimeHeading"] = "Temps de l'annonce"
L["CT_BuffMod/Options/General/Heading"] = "Options générales"
L["CT_BuffMod/Options/Tips/Heading"] = "Des conseils"
L["CT_BuffMod/Options/Tips/Line 1"] = "Vous pouvez taper /cbuff ou /ctaura pour accéder ces options."
L["CT_BuffMod/Options/Tips/Line 2"] = "Vous pouvez placer et configurer des fenêtres différents pour montrer les auras.  Alt-clic gauche sur une fenêtre pour le sélectionner."
L["CT_BuffMod/Options/Tips/Line 3"] = "Le plupart des options ne fonctionne que hors combat."
L["CT_BuffMod/Options/Window/Time Remaining/Duration Format Dropdown"] = "1 heure  -  22 minutes#1 heure  -  22 min#1h  -  22m#1h 11m  -  22m 22s#1:11h  -  22:22"
L["CT_BuffMod/Options/Window/Unit/Heading"] = "Unité"
L["CT_BuffMod/Options/Window/Unit/NonSecureCheckbox"] = "Utilise des boutons non sécurisé"
L["CT_BuffMod/Options/Window/Unit/SecureTooltip/Content"] = [=[|cFFFFAA00Les boutons sécurisé: 
|cFFFFFFFF- Les sorts utiles peut être annulés |cFFFFFF00n'importe quand|cFFFFFFFF.
|cFFFFFFFF- Les auras d'arme peut être annulés |cFFFFFF00n'importe quand|cFFFFFFFF.

|cFFFFAA00Les boutons non sécurisé: 
|cFFFFFFFF- Les sorts utiles peut être annulés |cFFFFFF00 hors combat|cFFFFFFFF.
|cFFFFFFFF- Les auras d'arme |cFFFF3333ne peut pas |cFFFFFFFFêtre annulés. 
|cFFFFFFFF- Additionnel méthode de trier: 'des auras non éxpirant' 
|cFFFFFFFF- Mode de compatibilité avec autre addons]=]
L["CT_BuffMod/Options/Window/Unit/SecureTooltip/Heading"] = "Les boutons sécurisé et non sécurisé"
L["CT_BuffMod/Options/Window/Unit/UnitDropdownLabel"] = "Montrer les auras de :"
L["CT_BuffMod/Options/Window/Unit/UnitDropdownOptions"] = "#Jouer#Véhicule#Compagnon#Cible#Cible focalisé"
L["CT_BuffMod/Options/Window/Unit/VehicleCheckbox"] = "Changer au véhicule lors de la conduit"
L["CT_BuffMod/Options/WindowControls/AddButton"] = "Ajouter"
L["CT_BuffMod/Options/WindowControls/AddTooltip"] = "Ajouter une fenêtre avec les options defauts."
L["CT_BuffMod/Options/WindowControls/AltClickHint"] = "Alt-clic pour sélectionner"
L["CT_BuffMod/Options/WindowControls/CloneButton"] = "Copier"
L["CT_BuffMod/Options/WindowControls/CloneTooltip"] = "Ajouter une fenêtre qui copie les options de celle-ci."
L["CT_BuffMod/Options/WindowControls/DeleteButton"] = "Supprimer"
L["CT_BuffMod/Options/WindowControls/DeleteTooltip"] = "|cFFFFFF00Maj-clic|r ce bouton pour supprimer la fênetre sélectionnée"
L["CT_BuffMod/Options/WindowControls/SelectionLabel"] = "Sélecter :"
L["CT_BuffMod/Options/WindowControls/Tip"] = "Les options ci-dessous ne contrôlent que la fenêtre sélectionnée"
L["CT_BuffMod/Options/WindowControls/WindowAddedMessage"] = "Fenêtre %d ajoutée."
L["CT_BuffMod/Options/WindowControls/WindowClonedMessage"] = "La fenêtre %d ajoutée, comme un copier de la fenêtre %d."
L["CT_BuffMod/Options/WindowControls/WindowDeletedMessage"] = "La fenêtre %d supprimée."
L["CT_BuffMod/Options/WindowControls/WindowSelectedMessage"] = "Fenêtre %d sélectionnée."



elseif (GetLocale() == "deDE") then


L["CT_BuffMod/PRE_EXPIRATION_WARNING"] = "Der Zauber |cFFFFFFFF%s|r wird in |cFFFFFFFF%s|r ablaufen."
L["CT_BuffMod/PRE_EXPIRATION_WARNING_KEYBINDING"] = "Der Zauber |cFFFFFFFF%s|r wird in |cFFFFFFFF%s|r ablaufen. Drücke außerhalb des Kampfes |cFFFFFFFF%s|r zum Erneuern."
L["CT_BuffMod/TimeFormat/Day Singular"] = "1 Tag"
L["CT_BuffMod/TimeFormat/Days Abbreviated"] = "%dd"
L["CT_BuffMod/TimeFormat/Days Digital"] = "%dd, %d:%.2dh"
L["CT_BuffMod/TimeFormat/Days Plural"] = "%d Tage"
L["CT_BuffMod/TimeFormat/Days Smaller"] = "%d Tag"
L["CT_BuffMod/TimeFormat/Hour Singular"] = "1 Stunde"
L["CT_BuffMod/TimeFormat/Hours Abbreviated"] = "%dh"
L["CT_BuffMod/TimeFormat/Hours Digital"] = "%d:%.2dh"
L["CT_BuffMod/TimeFormat/Hours Plural"] = "%d Stunden"
L["CT_BuffMod/TimeFormat/Hours Smaller"] = "%d Stunde"
L["CT_BuffMod/TimeFormat/Minute Singular"] = "1 Minute"
L["CT_BuffMod/TimeFormat/Minutes Abbreviated"] = "%dm"
L["CT_BuffMod/TimeFormat/Minutes Digital"] = "%d:%.2d"
L["CT_BuffMod/TimeFormat/Minutes Plural"] = "%d Minuten"
L["CT_BuffMod/TimeFormat/Minutes Smaller"] = "%d Min"
L["CT_BuffMod/TimeFormat/Minutes Two Digits"] = "%.2dm"
L["CT_BuffMod/TimeFormat/Off"] = "Aus"
L["CT_BuffMod/TimeFormat/Seconds Abbreviated"] = "%ds"
L["CT_BuffMod/TimeFormat/Seconds Plural"] = "%d Sekunden"
L["CT_BuffMod/TimeFormat/Seconds Smaller"] = "%d Sek"
L["CT_BuffMod/TimeFormat/Seconds Two Digits"] = "%.2ds"
L["CT_BuffMod/Options/Blizzard Frames/Heading"] = "Blizzard Standardfenster"
L["CT_BuffMod/Options/Blizzard Frames/Hide Buffs"] = "Standardfenster der Zauber ausblenden"
L["CT_BuffMod/Options/Blizzard Frames/Hide Consolidated"] = "Standardfenster der zusammengefassten Zauber ausblenden"
L["CT_BuffMod/Options/Blizzard Frames/Hide Enchants"] = "Standardfenster der Waffenzauber ausblenden"
L["CT_BuffMod/Options/General/Colors/Aura"] = "Aura"
L["CT_BuffMod/Options/General/Colors/Background"] = "Fenster Hintergrund"
L["CT_BuffMod/Options/General/Colors/Buff"] = "Stärkungszauber"
L["CT_BuffMod/Options/General/Colors/Debuff"] = "Schwächungszauber"
L["CT_BuffMod/Options/General/Colors/Heading"] = "Farben"
L["CT_BuffMod/Options/General/Colors/Weapon"] = "Waffe"
L["CT_BuffMod/Options/General/Heading"] = "Allgemeine Einstellungen"
L["CT_BuffMod/Options/Tips/Heading"] = "Hinweise"
L["CT_BuffMod/Options/Tips/Line 1"] = "Durch Eingabe von  /ctbuff oder /ctbuffmod wird dieses Optionsfenster direkt geöffnet."
L["CT_BuffMod/Options/Tips/Line 2"] = "Es können verschiedene Fenster zum Anzeigen der Auren eingestellt werden. Alt-Linksklick auf ein Fenster um es auszuwählen."
L["CT_BuffMod/Options/Tips/Line 3"] = "HINWEIS: Viele Optionen werden erst nach Verlassen des Kampfes aktiv."
L["CT_BuffMod/Options/Window/Time Remaining/Duration Format Dropdown"] = "1 Stunde - 22 Minuten#1 Stunde - 22 Min#1h - 22m#1h 11m - 22m 22s#1:11h - 22:22"
L["CT_BuffMod/Options/Window/Unit/Heading"] = "Einheit"
L["CT_BuffMod/Options/Window/Unit/NonSecureCheckbox"] = "Unsichere Zaubersymbole verwenden"
L["CT_BuffMod/Options/Window/Unit/SecureTooltip/Content"] = "|cFFFFAA00Sichere Zaubersymbole: |cFFFFFFFF- Gewirkte Zauber können |cFFFFFF00jederzeit |cFFFFFFFFentfernt werden. |cFFFFFFFF- Waffenzauber können |cFFFFFF00jederzeit |cFFFFFFFFentfernt werden. |cFFFFAA00Unsichere Zaubersymbole: |cFFFFFFFF- Gewirkte Zauber können |cFFFF3333außerhalb des Kampfes |cFFFFFFFFentfernt werden. |cFFFFFFFF- Waffenzauber können |cFFFF3333NICHT |cFFFFFFFFentfernt werden. |cFFFFFFFF- Zusätzliche Sortieroptionen: 'nicht-ablaufende Zauber' |cFFFFFFFF- Kompatibilitätsmodus zum Beheben von Addon Konflikten"
L["CT_BuffMod/Options/Window/Unit/SecureTooltip/Heading"] = "Sichere und unsichere Symbole"
L["CT_BuffMod/Options/Window/Unit/UnitDropdownLabel"] = "Zauber zeigen für:"
L["CT_BuffMod/Options/Window/Unit/UnitDropdownOptions"] = "#Spieler#Fahrzeug#Begleiter#Ziel#Fokus"
L["CT_BuffMod/Options/Window/Unit/VehicleCheckbox"] = "In einem Fahrzeug Fahrzeugzauber anzeigen"


end