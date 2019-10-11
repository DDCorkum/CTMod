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
module.text = module.text or { };
local L = module.text

-- enUS (other languages follow underneath)

L["CT_RaidAssist/AfterNotReadyFrame/MissedCheck"] = "You might have missed a ready check!"
L["CT_RaidAssist/AfterNotReadyFrame/WasAFK"] = "You were afk, are you back now?"
L["CT_RaidAssist/AfterNotReadyFrame/WasNotReady"] = "Are you ready now?"
L["CT_RaidAssist/PlayerFrame/TooltipFooter"] = "/ctra to move and configure"
L["CT_RaidAssist/WindowTitle"] = "Window %d"
L["CT_RaidAssist/Options/GeneralFeatures/ExtendReadyChecksCheckButton"] = "Extend missed ready checks"
L["CT_RaidAssist/Options/GeneralFeatures/ExtendReadyChecksTooltip"] = [=[Provides a button to announce returning
after missing a /readycheck]=]
L["CT_RaidAssist/Options/GeneralFeatures/Heading"] = "General Features"
L["CT_RaidAssist/Options/GeneralFeatures/Line1"] = "These general features are separate from the custom raid frames."
L["CT_RaidAssist/Options/Window/Groups/ClassHeader"] = "Classes"
L["CT_RaidAssist/Options/Window/Groups/GroupHeader"] = "Groups"
L["CT_RaidAssist/Options/Window/Groups/GroupTooltipContent"] = [=[0.9:0.9:0.9#|cFFFFFF99During a raid: |r
- self-explanatory

|cFFFFFF99Outside of raiding: |r
- Gp 1 is you and your party]=]
L["CT_RaidAssist/Options/Window/Groups/GroupTooltipHeader"] = "Groups 1 to 8"
L["CT_RaidAssist/Options/Window/Groups/Header"] = "Group and Class Selections"
L["CT_RaidAssist/Options/Window/Groups/Line1"] = "Which groups, roles or classes should this window show?"
L["CT_RaidAssist/Options/Window/Groups/RoleHeader"] = "Roles"
L["CT_RaidAssist/Options/Window/Layout/Heading"] = "Layout"
L["CT_RaidAssist/Options/Window/Layout/OrientationDropdown"] = "#New |cFFFFFF00column|r for each group#New |cFFFFFF00row|r for each group#Merge raid to a |cFFFFFF00single column|r (subject to wrapping)#Merge raid to a |cFFFFFF00single row|r (subject to wrapping)"
L["CT_RaidAssist/Options/Window/Layout/OrientationLabel"] = "Use rows or columns?"
L["CT_RaidAssist/Options/Window/Layout/Tip"] = [=[The raid frames will expand/shrink into
rows and columns using these settings]=]
L["CT_RaidAssist/Options/Window/Layout/WrapLabel"] = "Large rows/cols:"
L["CT_RaidAssist/Options/Window/Layout/WrapSlider"] = "Wrap after <value>"
L["CT_RaidAssist/Options/Window/Layout/WrapTooltipContent"] = [=[0.9:0.9:0.9#Starts a new row or column when it is too long

|cFFFFFF99Example:|r 
- Set earlier checkboxes to show all eight groups
- Set earlier dropdown to 'Merge raid to a single row'
- Set this slider to wrap after 10 players
- Now a 40-man raid appears as four rows of 10]=]
L["CT_RaidAssist/Options/Window/Layout/WrapTooltipHeader"] = "Wrapping large rows/columns:"
L["CT_RaidAssist/Options/WindowControls/AddButton"] = "Add"
L["CT_RaidAssist/Options/WindowControls/AddTooltip"] = "Add a new window with default settings."
L["CT_RaidAssist/Options/WindowControls/CloneButton"] = "Clone"
L["CT_RaidAssist/Options/WindowControls/CloneTooltip"] = "Add a new window with settings that duplicate those of the currently selected window."
L["CT_RaidAssist/Options/WindowControls/DeleteButton"] = "Delete"
L["CT_RaidAssist/Options/WindowControls/DeleteTooltip"] = "|cFFFFFF00Shift-click|r this button to delete the currently selected window."
L["CT_RaidAssist/Options/WindowControls/Heading"] = "Windows"
L["CT_RaidAssist/Options/WindowControls/Line1"] = "Each window has its own appearance, configurable below."
L["CT_RaidAssist/Options/WindowControls/SelectionLabel"] = "Select window:"
L["CT_RaidAssist/Options/WindowControls/WindowAddedMessage"] = "Window %d added."
L["CT_RaidAssist/Options/WindowControls/WindowClonedMessage"] = "Window %d added, copying settings from window %d."
L["CT_RaidAssist/Options/WindowControls/WindowDeletedMessage"] = "Window %d deleted."
L["CT_RaidAssist/Options/WindowControls/WindowSelectedMessage"] = "Window %d selected."
L["CT_RaidAssist/Spells/Abolish Poison"] = "Abolish Poison"
L["CT_RaidAssist/Spells/Amplify Magic"] = "Amplify Magic"
L["CT_RaidAssist/Spells/Ancestral Spirit"] = "Ancestral Spirit"
L["CT_RaidAssist/Spells/Arcane Brilliance"] = "Arcane Brilliance"
L["CT_RaidAssist/Spells/Arcane Intellect"] = "Arcane Intellect"
L["CT_RaidAssist/Spells/Battle Shout"] = "Battle Shout"
L["CT_RaidAssist/Spells/Blessing of Kings"] = "Blessing of Kings"
L["CT_RaidAssist/Spells/Blessing of Might"] = "Blessing of Might"
L["CT_RaidAssist/Spells/Blessing of Wisdom"] = "Blessing of Wisdom"
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
L["CT_RaidAssist/WindowTitle"] = "Fenêtre %d"
L["CT_RaidAssist/Options/WindowControls/AddButton"] = "Ajouter"
L["CT_RaidAssist/Options/WindowControls/AddTooltip"] = "Ajouter une fenêtre avec les options defauts."
L["CT_RaidAssist/Options/WindowControls/CloneButton"] = "Copier"
L["CT_RaidAssist/Options/WindowControls/CloneTooltip"] = "Ajouter une fenêtre qui copie les options de celle-ci."
L["CT_RaidAssist/Options/WindowControls/DeleteButton"] = "Supprimer"
L["CT_RaidAssist/Options/WindowControls/DeleteTooltip"] = "|cFFFFFF00Maj-clic|r ce bouton pour supprimer la fênetre sélectionnée"
L["CT_RaidAssist/Options/WindowControls/Heading"] = "Des fenêtres"
L["CT_RaidAssist/Options/WindowControls/SelectionLabel"] = "Sélectionner :"
L["CT_RaidAssist/Options/WindowControls/WindowAddedMessage"] = "La fenêtre %d ajoutée."
L["CT_RaidAssist/Options/WindowControls/WindowClonedMessage"] = "La fenêtre %d ajoutée, comme un copier de la fenêtre %d."
L["CT_RaidAssist/Options/WindowControls/WindowDeletedMessage"] = "La fenêtre %d supprimée."
L["CT_RaidAssist/Options/WindowControls/WindowSelectedMessage"] = "La fenêtre %d sélectionnée."
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


-- deDE (Credits: dynaletik)

elseif (GetLocale() == "deDE") then

L["CT_RaidAssist/AfterNotReadyFrame/MissedCheck"] = "Ggf. hast Du einen Bereitschaftscheck verpasst!"
L["CT_RaidAssist/AfterNotReadyFrame/WasAFK"] = "Du warst AFK, bist Du zurück?"
L["CT_RaidAssist/AfterNotReadyFrame/WasNotReady"] = "Bist Du jetzt bereit?"
L["CT_RaidAssist/PlayerFrame/TooltipFooter"] = "/ctra zum Verschieben und Konfigurieren"
L["CT_RaidAssist/WindowTitle"] = "Fenster %d"
L["CT_RaidAssist/Options/GeneralFeatures/ExtendReadyChecksCheckButton"] = "Erweiterte Bereitschaftschecks anzeigen"
L["CT_RaidAssist/Options/GeneralFeatures/ExtendReadyChecksTooltip"] = "Zeigt nach Verpassen eines Bereitschaftschecks eine Schaltfläche an um mitzuteilen, dass man wieder da ist"
L["CT_RaidAssist/Options/GeneralFeatures/Heading"] = "Allgemeine Funktionen"
L["CT_RaidAssist/Options/GeneralFeatures/Line1"] = "Diese allgemeinen Funktionen sind getrennt von den benutzerdefinierten Schlachtzugsfenstern."
L["CT_RaidAssist/Options/WindowControls/AddButton"] = "Hinzufügen"
L["CT_RaidAssist/Options/WindowControls/AddTooltip"] = "Neues Fenster mit Standardeinstellungen hinzufügen."
L["CT_RaidAssist/Options/WindowControls/CloneButton"] = "Duplizieren"
L["CT_RaidAssist/Options/WindowControls/CloneTooltip"] = "Erstellt ein neues Fenster mit den Einstellungen des derzeit ausgewählten Fensters."
L["CT_RaidAssist/Options/WindowControls/DeleteButton"] = "Löschen"
L["CT_RaidAssist/Options/WindowControls/DeleteTooltip"] = "|cFFFFFF00Shift-Klick|r auf diese Schaltfläche um das derzeit gewählte Fenster zu entfernen."
L["CT_RaidAssist/Options/WindowControls/Heading"] = "Fenster"
L["CT_RaidAssist/Options/WindowControls/SelectionLabel"] = "Fenster wählen:"
L["CT_RaidAssist/Options/WindowControls/WindowAddedMessage"] = "Fenster %d hinzugefügt."
L["CT_RaidAssist/Options/WindowControls/WindowClonedMessage"] = "Fenster %d mit Einstellungen von Fenster %d hinzugefügt."
L["CT_RaidAssist/Options/WindowControls/WindowDeletedMessage"] = "Fenster %d entfernt."
L["CT_RaidAssist/Options/WindowControls/WindowSelectedMessage"] = "Fenster %d ausgewählt."
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