------------------------------------------------
--               CT_BottomBar                 --
--                                            --
-- Breaks up the main menu bar into pieces,   --
-- allowing you to hide and move the pieces   --
-- independently of each other.               --
--                                            --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
--                                            --
-- Original credits to Cide and TS (Vanilla)  --
-- Maintained by Resike from 2014 to 2017     --
-- Maintained by Dahk Celes since 2018        --
--                                            --
-- This file localizes the CT_BB options      --
------------------------------------------------


-- Please see CurseForge.com/Projects/CTMod/Localization to contribute additional translations

local module = _G["CT_BottomBar"]
module.text = module.text or { }
local L = module.text


-----------------------------------------------
-- enUS (Default) Unlocalized Strings

L["CT_BottomBar/Options/ActionBarPage"] = "Arrows Page-Up/Down"
L["CT_BottomBar/Options/BagsBar"] = "Bags Bar"
L["CT_BottomBar/Options/ClassBar"] = "Class Bar"
L["CT_BottomBar/Options/ClassicKeyRingButton"] = "Key Ring Button"
L["CT_BottomBar/Options/ClassicPerformanceBar"] = "Performance Bar"
L["CT_BottomBar/Options/ExpBar"] = "Experience Bar"
L["CT_BottomBar/Options/FlightBar"] = "Stop Flying Button"
L["CT_BottomBar/Options/FPSBar"] = "FPS Indicator (CTRL-R)"
L["CT_BottomBar/Options/General/BackgroundTextures/Heading"] = "Background Textures"
L["CT_BottomBar/Options/General/BackgroundTextures/HideActionBarCheckButton"] = "Hide the action bar textures"
L["CT_BottomBar/Options/General/BackgroundTextures/HideGryphonsCheckButton"] = "Hide the gryphons/lions"
L["CT_BottomBar/Options/General/BackgroundTextures/HideMenuAndBagsCheckButton"] = "Hide the menu and bags textures"
L["CT_BottomBar/Options/General/BackgroundTextures/Line1"] = "Control the grey backgrounds behind the default UI bar positions"
L["CT_BottomBar/Options/General/BackgroundTextures/ShowLionsCheckButton"] = "Show lions instead of gryphons"
L["CT_BottomBar/Options/General/Heading"] = "Important General Options"
L["CT_BottomBar/Options/MovableBars/Activate"] = "Activate"
L["CT_BottomBar/Options/MovableBars/Hide"] = "Hide"
L["CT_BottomBar/Options/MenuBar"] = "Menu Bar"
L["CT_BottomBar/Options/PetBar"] = "Pet Bar"
L["CT_BottomBar/Options/RepBar"] = "Reputation Bar"
L["CT_BottomBar/Options/StanceBar"] = "Stance Bar"
L["CT_BottomBar/Options/StatusBar"] = "Status Bar (XP & Rep)"
L["CT_BottomBar/Options/TalkingHead"] = "Quest Dialogue"


-----------------------------------------------
-- frFR (credit: ddc)

if (GetLocale() == "frFR") then

L["CT_BottomBar/Options/ActionBarPage"] = "Les flèches haut/bas"
L["CT_BottomBar/Options/BagsBar"] = "Les sacs"
L["CT_BottomBar/Options/ClassBar"] = "La classe"
L["CT_BottomBar/Options/ClassicKeyRingButton"] = "Le trousseau de clés"
L["CT_BottomBar/Options/ClassicPerformanceBar"] = "La performance"
L["CT_BottomBar/Options/ExpBar"] = "L'expérience"
L["CT_BottomBar/Options/FlightBar"] = "Le bouton d'arrêt-vol"
L["CT_BottomBar/Options/FPSBar"] = "Les images/seconde (CTRL-R)"
L["CT_BottomBar/Options/MovableBars/Activate"] = "Activer"
L["CT_BottomBar/Options/MovableBars/Hide"] = "Cacher"
L["CT_BottomBar/Options/MenuBar"] = "Le menu"
L["CT_BottomBar/Options/PetBar"] = "L'animal de compangnie"
L["CT_BottomBar/Options/RepBar"] = "La réputation"
L["CT_BottomBar/Options/StanceBar"] = "La position"
L["CT_BottomBar/Options/StatusBar"] = "Les statuts (PX & rép)"
L["CT_BottomBar/Options/TalkingHead"] = "Le discours de quête"

end