------------------------------------------------
--                CT_Viewport                 --
--                                            --
-- Allows you to customize the rendered game  --
-- area, resulting in an overall more         --
-- customizable and usable  user interface.   --
--                                            --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
--					      --
-- Original credits to Cide and TS            --
-- Maintained by Resike from 2014 to 2017     --
-- Maintained by Dahk Celes (ddc) since 2018  --
------------------------------------------------

-- Please contribute new translations at <https://www.curseforge.com/wow/addons/ctmod/localization>

local MODULE_NAME, module = ...;
module.text = module.text or { };
local L = module.text;

-- enUS (other languages follow underneath)

L["CT_Viewport/Options/AspectRatio/DefaultPattern"] = "|cFFCCCCCCScreen resolution: |cFFFFFFFF%s"
L["CT_Viewport/Options/AspectRatio/Heading"] = "Aspect Ratio"
L["CT_Viewport/Options/AspectRatio/NewPattern"] = "|cFFCCCCCCCustom viewport: |cFFFFFFFF%s"
L["CT_Viewport/Options/Tips/Heading"] = "Tips"
L["CT_Viewport/Options/Tips/Line1"] = "Type /viewport, /ctvp, or /ctviewport:"
L["CT_Viewport/Options/Tips/Line2"] = "Open the control panel"
L["CT_Viewport/Options/Tips/Line3"] = "Reset all sides"
L["CT_Viewport/Options/Tips/Line4"] = "Set all sides: L, B, T, B"
L["CT_Viewport/Options/Tips/Line5"] = "Alternatively, set custom values below."
L["CT_Viewport/Options/Viewport/Heading"] = "Custom Viewport"
L["CT_Viewport/Options/Viewport/KeepSettingsPattern"] = "Keep Settings?  Reverting in %d sec"
L["CT_Viewport/Options/Viewport/RenderedArea"] = "Rendered Area"