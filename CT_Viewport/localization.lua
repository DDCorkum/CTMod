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
L["CT_Viewport/Options/Tips/Line4"] = "Set all sides: L, R, T, B"
L["CT_Viewport/Options/Tips/Line5"] = "Alternatively, set custom values below."
L["CT_Viewport/Options/Viewport/Heading"] = "Custom Viewport"
L["CT_Viewport/Options/Viewport/KeepSettingsPattern"] = "Keep Settings?  Reverting in %d sec"
L["CT_Viewport/Options/Viewport/RenderedArea"] = "Rendered Area"


-----------------------------------------------
-- frFR
-- Credits to ddc

if (GetLocale() == "frFR") then

L["CT_Viewport/Options/AspectRatio/DefaultPattern"] = "|cFFCCCCCCRésolution d'écran : |cFFFFFFFF%s"
L["CT_Viewport/Options/AspectRatio/Heading"] = "Le rapport hauteur / largeur"
L["CT_Viewport/Options/AspectRatio/NewPattern"] = "|cFFCCCCCCRésolution personalisée : |cFFFFFFFF%s"
L["CT_Viewport/Options/Tips/Heading"] = "Des conseils"
L["CT_Viewport/Options/Tips/Line1"] = "Tapez /viewport, /ctvp, ou /ctviewport :"
L["CT_Viewport/Options/Tips/Line2"] = "Ouvrir le panneau de configuration"
L["CT_Viewport/Options/Tips/Line3"] = "Réinitialiser au défaut"
L["CT_Viewport/Options/Tips/Line4"] = "Configurer les cotés : g d sup inf"
L["CT_Viewport/Options/Tips/Line5"] = "Alternativement, utilisez l'interface en-dessous."
L["CT_Viewport/Options/Viewport/Heading"] = "L'écran personnalisé"
L["CT_Viewport/Options/Viewport/KeepSettingsPattern"] = "Sauvegarder? Réinitialisant dans %d sec."
L["CT_Viewport/Options/Viewport/RenderedArea"] = "La zone rendue"


-----------------------------------------------
-- zhCN
-- Credits to fredakook

elseif (GetLocale() == "zhCN") then

L["CT_Viewport/Options/AspectRatio/DefaultPattern"] = "|cFFCCCCCC屏幕分辨率: |cFFFFFFFF%s"
L["CT_Viewport/Options/AspectRatio/Heading"] = "屏幕比例"
L["CT_Viewport/Options/AspectRatio/NewPattern"] = "|cFFCCCCCC自定义视窗: |cFFFFFFFF%s"
L["CT_Viewport/Options/Tips/Heading"] = "提示"
L["CT_Viewport/Options/Tips/Line1"] = "输入 /viewport, /ctvp, 或 /ctviewport:"
L["CT_Viewport/Options/Tips/Line2"] = "打开控制面板"
L["CT_Viewport/Options/Tips/Line3"] = "重置所有边"
L["CT_Viewport/Options/Tips/Line4"] = "设置所有边: 左，右，上，下"
L["CT_Viewport/Options/Tips/Line5"] = "或者在下面设置自定义值"
L["CT_Viewport/Options/Viewport/Heading"] = "自定义视窗"
L["CT_Viewport/Options/Viewport/KeepSettingsPattern"] = "保持设置？在%d秒内恢复"
L["CT_Viewport/Options/Viewport/RenderedArea"] = "渲染区域"

end