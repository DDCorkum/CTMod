------------------------------------------------
--                 CT_Library                 --
--                                            --
-- A shared library for all CTMod addons to   --
-- simplify simple, yet time consuming tasks  --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
--                                            --
-- Original credits to Cide and TS (Vanilla)  --
-- Maintained by Resike from 2014 to 2017     --
-- Maintained by Dahk Celes since 2018        --
--                                            --
-- This file localizes the CTMod window and   --
-- submodules installed by CT_Library         --
------------------------------------------------


-- Please see CurseForge.com/Projects/CTMod/Localization to contribute additional translations

local lib = _G["CT_Library"]
lib.text = lib.text or { }
local L = lib.text


-----------------------------------------------
-- enUS (Default) Unlocalized Strings

L["CT_Library/ControlPanelCannotOpen"] = "Cannot open the CT options while in combat"
L["CT_Library/Introduction"] = [=[Thank you for using CTMod!

You can open this window with /ct or /ctmod

Click below to open options for each module]=]
L["CT_Library/ModListing"] = "Mod Listing:"
L["CT_Library/Tooltip/DRAG"] = [=[Left click to drag
Right click to reset]=]
L["CT_Library/Tooltip/RESIZE"] = [=[Left click to resize
Right click to reset]=]
L["CT_Library/Help/About/Credits"] = [=[CTMod originated in Vanilla by Cide and TS
Resike and Dahk joined the team in '14 and '17]=]
L["CT_Library/Help/About/Heading"] = "About CTMod"
L["CT_Library/Help/About/Updates"] = "Updates are available at:"
L["CT_Library/Help/Heading"] = "Help"
L["CT_Library/Help/WhatIs/Heading"] = "What is CTMod?"
L["CT_Library/Help/WhatIs/Line1"] = "CTMod contains several modules:"
L["CT_Library/Help/WhatIs/NotInstalled"] = "not installed"
L["CT_Library/SettingsImport/Heading"] = "Settings Import"
L["CT_Library/SettingsImport/NoAddonsSelected"] = "No addons are selected."


-----------------------------------------------
-- frFR Localizations

if (GetLocale() == "frFR") then

L["CT_Library/ControlPanelCannotOpen"] = "Il faut finir le combat avant d'acceder les options de CTMod"
L["CT_Library/Introduction"] = [=[Merci pour utiliser CTMod!

Vous pouvez ouvrir cette fênetre avec /ct

Cliquez ci-dessous pour accéder aux modules]=]
L["CT_Library/ModListing"] = "Les modules :"
L["CT_Library/Help/About/Credits"] = "CTMod continue dupuis « Vanilla » par Cide et TS, 2014 par Resike, et 2017 par Dahk"
L["CT_Library/Help/About/Heading"] = "À propos de nous"
L["CT_Library/Help/About/Updates"] = "Pour mettre à jour :"
L["CT_Library/Help/Heading"] = "L'aide"
L["CT_Library/Help/WhatIs/Heading"] = "Qu'est-ce CTMod?"
L["CT_Library/Help/WhatIs/Line1"] = "CTMod contient des modules :"
L["CT_Library/Help/WhatIs/NotInstalled"] = "pas installée"
L["CT_Library/SettingsImport/Heading"] = "Importer les configurations"


-----------------------------------------------
-- deDE Localizations

elseif (GetLocale() == "deDE") then

L["CT_Library/Introduction"] = [=[Danke für die Nutzung von CTMod!

Dieses Fenster kann mit /ct oder /ctmod geöffnet werden. Unten klicken um Optionen des jeweiligen Moduls anzuzeigen]=]
L["CT_Library/ModListing"] = "Liste der Module:"
L["CT_Library/Help/About/Credits"] = [=[CTMod ist von Cide und TS seit Vanille, 
Resike seit 2014 und Dahk seit 2017]=]
L["CT_Library/Help/About/Heading"] = "Über CTMod"
L["CT_Library/Help/About/Updates"] = "Updates sind verfügbar unter:"
L["CT_Library/Help/Heading"] = "Hilfe"
L["CT_Library/Help/WhatIs/Heading"] = "Was ist CTMod?"
L["CT_Library/Help/WhatIs/Line1"] = "CTMod beinhaltet verschiedene Module:"
L["CT_Library/Help/WhatIs/NotInstalled"] = "nicht installiert"
L["CT_Library/SettingsImport/Heading"] = "Einstellungen importieren"


-----------------------------------------------
-- esES Localizations

elseif (GetLocale() == "esES") then

L["CT_Library/Help/About/Credits"] = [=[CTMod originado en Vanilla by Cide y TS
Resike y Dahk unieron en '14 y '17]=]
L["CT_Library/Help/About/Heading"] = [=[Acerca CTMod

]=]
L["CT_Library/Help/About/Updates"] = "Actualización en:"


-----------------------------------------------
-- ruRU Localizations

elseif (GetLocale() == "ruRU") then

L["CT_Library/SettingsImport/Heading"] = "Импорт настроек"

end