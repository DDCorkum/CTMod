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

-- Please contribute new translations at <https://wow.curseforge.com/projects/ctmod/localization>

local module = CT_RaidAssist
module.text = { };
local L = module.text

-- enUS (other languages follow underneath)

L["CT_RaidAssist/AfterNotReadyFrame/MissedCheck"] = "You might have missed a ready check!"
L["CT_RaidAssist/AfterNotReadyFrame/WasAFK"] = "You were afk, are you back now?"
L["CT_RaidAssist/AfterNotReadyFrame/WasNotReady"] = "Are you ready now?"
L["CT_RaidAssist/PlayerFrame/TooltipFooter"] = "/ctra to move and configure"
L["CT_RaidAssist/Options/GeneralFeatures/ExtendReadyChecksCheckButton"] = "Show extended ready checks"
L["CT_RaidAssist/Options/GeneralFeatures/ExtendReadyChecksTooltip"] = [=[If you miss a /readycheck, 
provide a button to say you returned]=]
L["CT_RaidAssist/Options/GeneralFeatures/Heading"] = "General Features"
L["CT_RaidAssist/Options/GeneralFeatures/Line1"] = "These general features are separate from the custom raid frames."
L["CT_RaidAssist/Spells/Abolish Poison"] = "Abolish Poison"
L["CT_RaidAssist/Spells/Amplify Magic"] = "Amplify Magic"
L["CT_RaidAssist/Spells/Ancestral Spirit"] = "Ancestral Spirit"
L["CT_RaidAssist/Spells/Arcane Brilliance"] = "Arcane Brilliance"
L["CT_RaidAssist/Spells/Arcane Intellect"] = "Arcane Intellect"
L["CT_RaidAssist/Spells/Battle Shout"] = "Battle Shout"
L["CT_RaidAssist/Spells/Cleanse"] = "Cleanse"
L["CT_RaidAssist/Spells/Cleanse Spirit"] = "Cleanse Spirit"
L["CT_RaidAssist/Spells/Cleanse Toxins"] = "Cleanse Toxins"
L["CT_RaidAssist/Spells/Cure Poison"] = "Cure Poison"
L["CT_RaidAssist/Spells/Dampen Magic"] = "Dampen Magic"
L["CT_RaidAssist/Spells/Detox"] = "Detox"
L["CT_RaidAssist/Spells/Dispel Magic"] = "Dispel Magic"
L["CT_RaidAssist/Spells/Nature's Cure"] = "Nature's Cure"
L["CT_RaidAssist/Spells/Power Word: Fortitude"] = "Power Word: Fortitude"
L["CT_RaidAssist/Spells/Prayer of Fortitude"] = "Prayer of Fortitude"
L["CT_RaidAssist/Spells/Purify"] = "Purify"
L["CT_RaidAssist/Spells/Purify Disease"] = "Purify Disease"
L["CT_RaidAssist/Spells/Purify Spirit"] = "Purify Spirit"
L["CT_RaidAssist/Spells/Raise Ally"] = "Raise Ally"
L["CT_RaidAssist/Spells/Rebirth"] = "Rebirth"
L["CT_RaidAssist/Spells/Redemption"] = "Redemption"
L["CT_RaidAssist/Spells/Remove Corruption"] = "Remove Corruption"
L["CT_RaidAssist/Spells/Remove Curse"] = "Remove Curse"
L["CT_RaidAssist/Spells/Remove Lesser Curse"] = "Remove Lesser Curse"
L["CT_RaidAssist/Spells/Resurrection"] = "Resurrection"
L["CT_RaidAssist/Spells/Revival"] = "Revival"
L["CT_RaidAssist/Spells/Revive"] = "Revive"
L["CT_RaidAssist/Spells/Soulstone"] = "Soulstone"
L["CT_RaidAssist/Spells/Trueshot Aura"] = "Trueshot Aura"


-- frFR (Credits: ddc)

if (GetLocale() == "frFR") then

L["CT_RaidAssist/AfterNotReadyFrame/MissedCheck"] = "Vous pourriez manquer un appel; êtes-vous prêt?"
L["CT_RaidAssist/AfterNotReadyFrame/WasAFK"] = "Vous étiez absent.  Revenez-vous?"
L["CT_RaidAssist/AfterNotReadyFrame/WasNotReady"] = "Êtes-vous prêt maintenant?"
L["CT_RaidAssist/Spells/Abolish Poison"] = "Abolir le poison"
L["CT_RaidAssist/Spells/Amplify Magic"] = "Amplification de la magie"
L["CT_RaidAssist/Spells/Arcane Brilliance"] = "Illumination des arcanes"
L["CT_RaidAssist/Spells/Arcane Intellect"] = "Intelligence des Arcanes"
L["CT_RaidAssist/Spells/Battle Shout"] = "Cri de guerre"
L["CT_RaidAssist/Spells/Cleanse"] = "Epuration"
L["CT_RaidAssist/Spells/Dampen Magic"] = "Atténuation de la magie"
L["CT_RaidAssist/Spells/Nature's Cure"] = "Soins naturels"
L["CT_RaidAssist/Spells/Power Word: Fortitude"] = "Mot de pouvoir : Robustesse"
L["CT_RaidAssist/Spells/Remove Corruption"] = "Délivrance de la corruption"
L["CT_RaidAssist/Spells/Remove Curse"] = "Délivrance de la malédiction"
L["CT_RaidAssist/Spells/Remove Lesser Curse"] = "Délivrance de la malédiction mineure"
L["CT_RaidAssist/Spells/Trueshot Aura"] = "Aura de précision"


-- deDE (credits: dynaletik)

elseif (GetLocale() == "deDE") then

L["CT_RaidAssist/AfterNotReadyFrame/MissedCheck"] = "Ggf. hast Du einen Bereitschaftscheck verpasst!"
L["CT_RaidAssist/AfterNotReadyFrame/WasAFK"] = "Du warst AFK, bist Du zurück?"
L["CT_RaidAssist/AfterNotReadyFrame/WasNotReady"] = "Bist Du jetzt bereit?"
L["CT_RaidAssist/PlayerFrame/TooltipFooter"] = "/ctra zum Verschieben und Konfigurieren"
L["CT_RaidAssist/Options/GeneralFeatures/ExtendReadyChecksCheckButton"] = "Erweiterte Bereitschaftschecks anzeigen"
L["CT_RaidAssist/Options/GeneralFeatures/ExtendReadyChecksTooltip"] = "Zeigt nach Verpassen eines Bereitschaftschecks eine Schaltfläche an um mitzuteilen, dass man wieder da ist"
L["CT_RaidAssist/Options/GeneralFeatures/Heading"] = "Allgemeine Funktionen"
L["CT_RaidAssist/Options/GeneralFeatures/Line1"] = "Diese allgemeinen Funktionen sind getrennt von den benutzerdefinierten Schlachtzugsfenstern."
L["CT_RaidAssist/Spells/Abolish Poison"] = "Vergiftung aufheben"
L["CT_RaidAssist/Spells/Amplify Magic"] = "Magie verstärken"
L["CT_RaidAssist/Spells/Ancestral Spirit"] = "Geist der Ahnen"
L["CT_RaidAssist/Spells/Arcane Brilliance"] = "Arkane Brillanz"
L["CT_RaidAssist/Spells/Arcane Intellect"] = "Arkane Intelligenz"
L["CT_RaidAssist/Spells/Battle Shout"] = "Schlachtruf"
L["CT_RaidAssist/Spells/Cleanse"] = "Reinigung des Glaubens"
L["CT_RaidAssist/Spells/Cleanse Spirit"] = "Geist reinigen"
L["CT_RaidAssist/Spells/Cleanse Toxins"] = "Gifte reinigen"
L["CT_RaidAssist/Spells/Cure Poison"] = "Vergiftung heilen"
L["CT_RaidAssist/Spells/Dampen Magic"] = "Magie dämpfen"
L["CT_RaidAssist/Spells/Detox"] = "Entgiftung"
L["CT_RaidAssist/Spells/Dispel Magic"] = "Magiebannung"
L["CT_RaidAssist/Spells/Nature's Cure"] = "Heilung der Natur"
L["CT_RaidAssist/Spells/Power Word: Fortitude"] = "Machtwort: Seelenstärke"
L["CT_RaidAssist/Spells/Prayer of Fortitude"] = "Gebet der Seelenstärke"
L["CT_RaidAssist/Spells/Purify"] = "Läutern"
L["CT_RaidAssist/Spells/Purify Disease"] = "Krankheit läutern"
L["CT_RaidAssist/Spells/Purify Spirit"] = "Geistreinigung"
L["CT_RaidAssist/Spells/Raise Ally"] = "Verbündeten erwecken"
L["CT_RaidAssist/Spells/Rebirth"] = "Wiedergeburt"
L["CT_RaidAssist/Spells/Redemption"] = "Erlösung"
L["CT_RaidAssist/Spells/Remove Corruption"] = "Verderbnis entfernen"
L["CT_RaidAssist/Spells/Remove Curse"] = "Fluch aufheben"
L["CT_RaidAssist/Spells/Remove Lesser Curse"] = "Geringen Fluch aufheben"
L["CT_RaidAssist/Spells/Resurrection"] = "Auferstehung"
L["CT_RaidAssist/Spells/Revival"] = "Wiederbelebung"
L["CT_RaidAssist/Spells/Revive"] = "Wiederbeleben"
L["CT_RaidAssist/Spells/Soulstone"] = "Seelenstein"
L["CT_RaidAssist/Spells/Trueshot Aura"] = "Aura des Volltreffers"


elseif (GetLocale() == "esES") then

L["CT_RaidAssist/Spells/Abolish Poison"] = "Suprimir veneno"
L["CT_RaidAssist/Spells/Amplify Magic"] = "Amplificar magia"
L["CT_RaidAssist/Spells/Arcane Intellect"] = "Intelecto Arcano"
L["CT_RaidAssist/Spells/Cleanse"] = "Purgación"
L["CT_RaidAssist/Spells/Power Word: Fortitude"] = "Palabra de poder: entereza"

elseif (GetLocale() == "ruRU") then

L["CT_RaidAssist/Spells/Abolish Poison"] = "Выведение яда"
L["CT_RaidAssist/Spells/Amplify Magic"] = "Усиление магии"
L["CT_RaidAssist/Spells/Arcane Intellect"] = "Чародейский интеллект"
L["CT_RaidAssist/Spells/Cleanse"] = "Очищение"
L["CT_RaidAssist/Spells/Power Word: Fortitude"] = "Слово силы: Стойкость"

elseif (GetLocale() == "koKR") then

L["CT_RaidAssist/Spells/Arcane Intellect"] = "신비한 지능"
L["CT_RaidAssist/Spells/Cleanse"] = "정화"
L["CT_RaidAssist/Spells/Power Word: Fortitude"] = "신의 권능: 인내"

elseif (GetLocale() == "zhCN") then

L["CT_RaidAssist/Spells/Arcane Intellect"] = "奥术智慧"
L["CT_RaidAssist/Spells/Cleanse"] = "清洁术"

end