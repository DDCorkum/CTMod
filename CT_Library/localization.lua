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

lib = _G["CT_Library"]
lib.text = { }
local L = lib.text



-----------------------------------------------
-- enUS (Default) Unlocalized Strings
-- DO NOT INTENT because some strings are multi-line!


L["CT_Library/Introduction"] = [=[Thank you for using CTMod!

You can open this window with /ct or /ctmod

Click below to open options for each module]=]
L["CT_Library/ModListing"] = "Mod Listing:"
L["CT_Library/Help/About/Credits"] = [=[CTMod originated in Vanilla by Cide and TS
Resike and Dahk joined the team in '14 and '17]=]
L["CT_Library/Help/About/Heading"] = "About CTMod"
L["CT_Library/Help/About/Updates"] = "Updates are available at:"
L["CT_Library/Help/Heading"] = "Help"
L["CT_Library/Help/WhatIs/Heading"] = "What is CTMod?"
L["CT_Library/Help/WhatIs/Line1"] = "CTMod contains several modules:"
L["CT_Library/Help/WhatIs/NotInstalled"] = "Not Installed"
L["CT_Library/SettingsImport/Heading"] = "Settings Import"






-----------------------------------------------
-- frFR Localizations
-- DO NOT INDENT because some strings are multiline

if (GetLocale() == "frFR") then

L["CT_Library/Introduction"] = [=[Merci pour utiliser CTMod!

Vous pouvez ouvrir cette fênetre avec /ct

Cliquez ci-dessous pour accéder aux modules]=]
L["CT_Library/ModListing"] = "Les modules :"
L["CT_Library/Help/About/Credits"] = "CTMod continue dupuis « Vanilla » par Cide et TS, 2014 par Resike, et 2017 par Dahk"
L["CT_Library/Help/About/Heading"] = "À propos de nous"
L["CT_Library/Help/About/Updates"] = "Pour mettre à jour :"
L["CT_Library/Help/Heading"] = "Aide"
L["CT_Library/Help/WhatIs/Heading"] = "Qu'est-ce CTMod?"
L["CT_Library/Help/WhatIs/Line1"] = "CTMod contient des modules :"
L["CT_Library/Help/WhatIs/NotInstalled"] = "pas installée"
L["CT_Library/SettingsImport/Heading"] = "Importer les configurations"



elseif (GetLocale() == "deDE") then

L["CT_Library/Help/About/Credits"] = [=[CTMod ist von Cide und TS seit Vanille, 
Resike seit 2014 und Dahk seit 2017]=]
L["CT_Library/Help/About/Heading"] = "Über CTMod"
L["CT_Library/Help/About/Updates"] = "Updates sind verfügbar unter:"



-- add other languages here using elseif statements


end