------------------------------------------------
--                 CT_MailMod                 --
--                                            --
-- Mail several items at once with almost no  --
-- effort at all. Also takes care of opening  --
-- several mail items at once, reducing the   --
-- time spent on maintaining the inbox for    --
-- bank mules and such.                       --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
------------------------------------------------

local _G = getfenv(0);
local module = _G["CT_MailMod"];

--------------------------------------------
-- Localization
module.text = { }
local L = module.text

L["CT_MailMod/DELETE_POPUP1"] = "%d items including %s"
L["CT_MailMod/DELETE_POPUP2"] = "some money and %s"
L["CT_MailMod/DELETE_POPUP3"] = "some money and %d items including %s"
L["CT_MailMod/MAIL_DELETE_NO"] = "Not deleted."
L["CT_MailMod/MAIL_DELETE_OK"] = "Deleting mail."
L["CT_MailMod/MAIL_DOWNLOAD_BEGIN"] = "Waiting for mail to download into the inbox."
L["CT_MailMod/MAIL_DOWNLOAD_END"] = "Mail has downloaded into the inbox."
L["CT_MailMod/MAIL_LOG"] = "Log"
L["CT_MailMod/MAIL_LOOT_ERROR"] = "Item not taken:"
L["CT_MailMod/MAIL_OPEN_CLICK"] = "Press |c0080A0FFAlt-click|r to take the contents."
L["CT_MailMod/MAIL_OPEN_IS_COD"] = "Mail is Cash on Delivery."
L["CT_MailMod/MAIL_OPEN_IS_GM"] = "Mail is from Blizzard."
L["CT_MailMod/MAIL_OPEN_NO"] = "Not opened."
L["CT_MailMod/MAIL_OPEN_NO_ITEMS_MONEY"] = "Mail has no items or money."
L["CT_MailMod/MAIL_OPEN_OK"] = "Opening mail."
L["CT_MailMod/MAIL_RETURN_CLICK"] = "Press |c0080A0FFCtrl-click|r to return the message."
L["CT_MailMod/MAIL_RETURN_IS_GM"] = "Mail is from Blizzard."
L["CT_MailMod/MAIL_RETURN_IS_RETURNED"] = "Mail is returning to you."
L["CT_MailMod/MAIL_RETURN_NO"] = "Not returned."
L["CT_MailMod/MAIL_RETURN_NO_ITEMS_MONEY"] = "Mail has no items or money."
L["CT_MailMod/MAIL_RETURN_NO_REPLY"] = "Mail cannot be replied to."
L["CT_MailMod/MAIL_RETURN_NO_SENDER"] = "Mail has no sender."
L["CT_MailMod/MAIL_RETURN_OK"] = "Returning mail."
L["CT_MailMod/MAIL_SEND_OK"] = "Mail sent."
L["CT_MailMod/MAIL_TAKE_ITEM_OK"] = "Taking attachment."
L["CT_MailMod/MAIL_TAKE_MONEY_OK"] = "Taking money."
L["CT_MailMod/MAIL_TIMEOUT"] = "Action timed out."
L["CT_MailMod/MAILBOX_BUTTON_TIP1"] = "Download mail"
L["CT_MailMod/MAILBOX_OVERFLOW_COUNT"] = "Overflow: %d"
L["CT_MailMod/MAILBOX_DOWNLOAD_MORE_NOW"] = "Download more mail"
L["CT_MailMod/MAILBOX_DOWNLOAD_MORE_SOON"] = [=[Download more mail
in %d seconds]=]
L["CT_MailMod/MAILBOX_OPTIONS_TIP1"] = [=[To access CT_MailMod options and tips, click this button or type /ctmail.
Right click to toggle the mail log window or type /maillog.]=]
L["CT_MailMod/MONEY_DECREASED"] = "Your money decreased by: %s"
L["CT_MailMod/MONEY_INCREASED"] = "Your money increased by: %s"
L["CT_MailMod/NOTHING_SELECTED"] = "No messages are selected."
L["CT_MailMod/NUMBER_SELECTED_PLURAL"] = "%d selected"
L["CT_MailMod/NUMBER_SELECTED_SINGLE"] = "%d selected"
L["CT_MailMod/NUMBER_SELECTED_ZERO"] = "%d selected"
L["CT_MailMod/OPEN_SELECTED"] = "Open"
L["CT_MailMod/PROCESSING_CANCELLED"] = "Mailbox processing cancelled."
L["CT_MailMod/QUICK_DELETE_TIP1"] = "Delete the message now"
L["CT_MailMod/QUICK_RETURN_TIP1"] = "Return the message now"
L["CT_MailMod/RETURN_SELECTED"] = "Return"
L["CT_MailMod/SELECT_ALL"] = "Select All"
L["CT_MailMod/SELECT_MESSAGE_TIP1"] = "Update message selection"
L["CT_MailMod/SELECT_MESSAGE_TIP2"] = [=[
|c0080A0FFClick:|r Select or unselect single

|c0080A0FFAlt Left-click:|r Select similar subjects
|c0080A0FFAlt Right-click:|r Unselect similar subjects

|c0080A0FFCtrl Left-click:|r Select same sender
|c0080A0FFCtrl Right-click:|r Unselect same sender

|c0080A0FFShift click:|r Mark start of range
|c0080A0FFShift Left-click:|r End range and select mail
|c0080A0FFShift Right-click:|r End range and unselect mail]=]
L["CT_MailMod/SEND_MAIL_MONEY_SUBJECT_COPPER"] = "%d copper"
L["CT_MailMod/SEND_MAIL_MONEY_SUBJECT_GOLD"] = "%d gold %d silver %d copper"
L["CT_MailMod/SEND_MAIL_MONEY_SUBJECT_SILVER"] = "%d silver %d copper"
L["CT_MailMod/STOP_SELECTED"] = "Cancel"



if (GetLocale() == "frFR") then

L["CT_MailMod/DELETE_POPUP1"] = "%d objets incluant %s"
L["CT_MailMod/DELETE_POPUP2"] = "d'argent et %s"
L["CT_MailMod/DELETE_POPUP3"] = "d'argent et %d objets incluant %s"
L["CT_MailMod/MAILBOX_DOWNLOAD_MORE_NOW"] = "Recevoir plus de courrier"
L["CT_MailMod/MAILBOX_DOWNLOAD_MORE_SOON"] = [=[Plus de courrier arrive
dans %d seconds]=]
L["CT_MailMod/NUMBER_SELECTED_PLURAL"] = "%d sélectionnés"
L["CT_MailMod/NUMBER_SELECTED_SINGLE"] = "%d sélectionné"
L["CT_MailMod/NUMBER_SELECTED_ZERO"] = "%d sélectionné"
L["CT_MailMod/OPEN_SELECTED"] = "Ouvrir"
L["CT_MailMod/RETURN_SELECTED"] = "Renvoyer"
L["CT_MailMod/SELECT_ALL"] = "Tous"
L["CT_MailMod/SEND_MAIL_MONEY_SUBJECT_COPPER"] = "%d cuivre"
L["CT_MailMod/SEND_MAIL_MONEY_SUBJECT_GOLD"] = "%d or %d argent %d cuivre"
L["CT_MailMod/SEND_MAIL_MONEY_SUBJECT_SILVER"] = "%d argent %d cuivre"
L["CT_MailMod/STOP_SELECTED"] = "Annuler"


elseif (GetLocale() == "deDE") then

L["CT_MailMod/DELETE_POPUP1"] = "%d Gegenstände enthalten %s"
L["CT_MailMod/DELETE_POPUP2"] = "etwas Geld und %s"
L["CT_MailMod/DELETE_POPUP3"] = "etwas Geld und %d Gegenstände enthalten %s"
L["CT_MailMod/MAIL_DELETE_NO"] = "Nicht gelöscht."
L["CT_MailMod/MAIL_DELETE_OK"] = "Lösche Post."
L["CT_MailMod/MAIL_DOWNLOAD_BEGIN"] = "Post wird in Eingang heruntergeladen."
L["CT_MailMod/MAIL_DOWNLOAD_END"] = "Post wurde in Eingang heruntergeladen."
L["CT_MailMod/MAIL_LOG"] = "Protokoll"
L["CT_MailMod/MAIL_LOOT_ERROR"] = "Gegenstand nicht entnommen:"
L["CT_MailMod/MAIL_OPEN_CLICK"] = "Drücke |c0080A0FFAlt-Klick|r um Anhänge zu entnehmen."
L["CT_MailMod/MAIL_OPEN_IS_COD"] = "Post besitzt Nachnahme-Gebühr."
L["CT_MailMod/MAIL_OPEN_IS_GM"] = "Post von Blizzard"
L["CT_MailMod/MAIL_OPEN_NO"] = "Nicht geöffnet"
L["CT_MailMod/MAIL_OPEN_NO_ITEMS_MONEY"] = "Post enthält keine Gegenstände oder Geld."
L["CT_MailMod/MAIL_OPEN_OK"] = "Öffne Post."
L["CT_MailMod/MAIL_RETURN_CLICK"] = "Drücke |c0080A0FFStrg-Klick|r um den Brief zurückzusenden."
L["CT_MailMod/MAIL_RETURN_IS_GM"] = "Post von Blizzard."
L["CT_MailMod/MAIL_RETURN_IS_RETURNED"] = "Post wird zu Dir zurückgesendet."
L["CT_MailMod/MAIL_RETURN_NO"] = "Nicht zurückgesendet."
L["CT_MailMod/MAIL_RETURN_NO_ITEMS_MONEY"] = "Post enthält keine Gegenstände oder Geld."
L["CT_MailMod/MAIL_RETURN_NO_REPLY"] = "Post kann nicht beantwortet werden."
L["CT_MailMod/MAIL_RETURN_NO_SENDER"] = "Post hat keinen Absender."
L["CT_MailMod/MAIL_RETURN_OK"] = "Sende Post zurück."
L["CT_MailMod/MAIL_SEND_OK"] = "Post verschickt."
L["CT_MailMod/MAIL_TAKE_ITEM_OK"] = "Entnehme Anhang."
L["CT_MailMod/MAIL_TAKE_MONEY_OK"] = "Entnehme Geld."
L["CT_MailMod/MAIL_TIMEOUT"] = "Zeitüberschreitung bei Aktion."
L["CT_MailMod/MAILBOX_BUTTON_TIP1"] = "Post herunterladen"
L["CT_MailMod/MAILBOX_DOWNLOAD_MORE_NOW"] = "Weitere Post herunterladen"
L["CT_MailMod/MAILBOX_DOWNLOAD_MORE_SOON"] = "Weitere Post in %d Sekunden herunterladen"
L["CT_MailMod/MAILBOX_OPTIONS_TIP1"] = "Klicke diese Schaltfläche oder gebe /ctmail ein, um CTMailMod Optionen oder Hinweise anzuzeigen. Rechtsklick oder /maillog eingeben um Protokollfenster ein-/auszublenden."
L["CT_MailMod/MAILBOX_OVERFLOW_COUNT"] = "Überlauf: %d"
L["CT_MailMod/MONEY_DECREASED"] = "Geld verringert um: %s"
L["CT_MailMod/MONEY_INCREASED"] = "Geld erhöht um: %s"
L["CT_MailMod/NOTHING_SELECTED"] = "Es sind keine Briefe ausgewählt."
L["CT_MailMod/NUMBER_SELECTED_PLURAL"] = "%d gewählt"
L["CT_MailMod/NUMBER_SELECTED_SINGLE"] = "%d gewählt"
L["CT_MailMod/NUMBER_SELECTED_ZERO"] = "%d gewählt"
L["CT_MailMod/OPEN_SELECTED"] = "Öffnen"
L["CT_MailMod/PROCESSING_CANCELLED"] = "Briefkasten Bearbeitung abgebrochen."
L["CT_MailMod/QUICK_DELETE_TIP1"] = "Brief jetzt löschen"
L["CT_MailMod/QUICK_RETURN_TIP1"] = "Brief jetzt zurücksenden"
L["CT_MailMod/RETURN_SELECTED"] = "Zurücksenden"
L["CT_MailMod/SELECT_ALL"] = "Alle wählen"
L["CT_MailMod/SELECT_MESSAGE_TIP1"] = "Briefwahl aktualisieren"
L["CT_MailMod/SELECT_MESSAGE_TIP2"] = [=[|c0080A0FFKlick:|r Einzeln auswählen oder abwählen
 
 |c0080A0FFAlt Linksklick:|r Gleichen Betreff auswählen
 |c0080A0FFAlt Rechtsklick:|r Gleichen Betreff abwählen
 
 |c0080A0FFStrg Linksklick:|r Gleichen Absender auswählen
 |c0080A0FFStrg Rechtsklick:|r Gleichen Absender abwählen
 
 |c0080A0FFShift Klick:|r Anfang der Auswahl markieren
 |c0080A0FFShift Linksklick:|r Ende der Auswahl markieren und auswählen
 |c0080A0FFShift Rechtsklick:|r Ende der Auswahl markieren und Abwählen]=]
L["CT_MailMod/SEND_MAIL_MONEY_SUBJECT_COPPER"] = "%d Kupfer"
L["CT_MailMod/SEND_MAIL_MONEY_SUBJECT_GOLD"] = "%d Gold %d Silber %d Kupfer"
L["CT_MailMod/SEND_MAIL_MONEY_SUBJECT_SILVER"] = "%d Silber %d Kupfer"
L["CT_MailMod/STOP_SELECTED"] = "Abbrechen"

end