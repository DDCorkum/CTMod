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
module.text = module.text or { }
local L = module.text

-- enUS (default)

L["CT_MailMod/AutoCompleteFilter/Account"] = "Own toons on this account"
L["CT_MailMod/AutoCompleteFilter/Friends"] = "Friends list (including offline)"
L["CT_MailMod/AutoCompleteFilter/Group"] = "Current Group"
L["CT_MailMod/AutoCompleteFilter/Guild"] = "Guild list (including offline)"
L["CT_MailMod/AutoCompleteFilter/Online"] = "Online and/or nearby toons"
L["CT_MailMod/AutoCompleteFilter/Recent"] = "Recently Interacted"
L["CT_MailMod/DELETE_POPUP1"] = "%d items including %s"
L["CT_MailMod/DELETE_POPUP2"] = "some money and %s"
L["CT_MailMod/DELETE_POPUP3"] = "some money and %d items including %s"
L["CT_MailMod/Inbox/OpenSelectedButton"] = "Open"
L["CT_MailMod/Inbox/OpenSelectedTip"] = "Open selected messages"
L["CT_MailMod/Inbox/ReturnSelectedButton"] = "Return"
L["CT_MailMod/Inbox/ReturnSelectedTip"] = "Return the selected messages"
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
L["CT_MailMod/MAILBOX_DOWNLOAD_MORE_NOW"] = "Download more mail"
L["CT_MailMod/MAILBOX_DOWNLOAD_MORE_SOON"] = [=[Download more mail
in %d seconds]=]
L["CT_MailMod/MAILBOX_OPTIONS_TIP1"] = [=[To access CT_MailMod options and tips, click this button or type /ctmail.
Right click to toggle the mail log window or type /maillog.]=]
L["CT_MailMod/MAILBOX_OVERFLOW_COUNT"] = "Overflow: %d"
L["CT_MailMod/MONEY_DECREASED"] = "Your money decreased by: %s"
L["CT_MailMod/MONEY_INCREASED"] = "Your money increased by: %s"
L["CT_MailMod/NOTHING_SELECTED"] = "No messages are selected."
L["CT_MailMod/NUMBER_SELECTED_PLURAL"] = "%d selected"
L["CT_MailMod/NUMBER_SELECTED_SINGLE"] = "%d selected"
L["CT_MailMod/NUMBER_SELECTED_ZERO"] = "%d selected"
L["CT_MailMod/PROCESSING_CANCELLED"] = "Mailbox processing cancelled."
L["CT_MailMod/QUICK_DELETE_TIP1"] = "Delete the message now"
L["CT_MailMod/QUICK_RETURN_TIP1"] = "Return the message now"
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
L["CT_MailMod/Send/AutoComplete/Heading"] = "Auto-complete settings"
L["CT_MailMod/Send/AutoComplete/Tip"] = "Select down-arrow to change the filters"
L["CT_MailMod/SEND_MAIL_MONEY_SUBJECT_COPPER"] = "%d copper"
L["CT_MailMod/SEND_MAIL_MONEY_SUBJECT_GOLD"] = "%d gold %d silver %d copper"
L["CT_MailMod/SEND_MAIL_MONEY_SUBJECT_SILVER"] = "%d silver %d copper"
L["CT_MailMod/STOP_SELECTED"] = "Cancel"
L["CT_MailMod/Options/Bags/CloseAllCheckButton"] = "Close all bags"
L["CT_MailMod/Options/Bags/CloseLabel"] = "When the mailbox closes:"
L["CT_MailMod/Options/Bags/Heading"] = "Inventory Bags"
L["CT_MailMod/Options/Bags/Line1"] = "Disabling these options may be necessary for compatability with other bag management addons"
L["CT_MailMod/Options/Bags/OpenAllCheckButton"] = "Open all bags"
L["CT_MailMod/Options/Bags/OpenBackpackCheckButton"] = "Open the backpack"
L["CT_MailMod/Options/Bags/OpenLabel"] = "When the mailbox opens:"
L["CT_MailMod/Options/General/BlockTradesCheckButton"] = "Block trades while using the mailbox"
L["CT_MailMod/Options/General/Heading"] = "General Options"
L["CT_MailMod/Options/General/NetIncomeCheckButton"] = "Show net income when the mailbox closes"
L["CT_MailMod/Options/Inbox/Checkboxes/Heading"] = "Message Checkboxes"
L["CT_MailMod/Options/Inbox/Checkboxes/Line1"] = "Mouseover the '?' for additional info"
L["CT_MailMod/Options/Inbox/Checkboxes/RangeNewCheckButton"] = "Clear selection when shift-clicking a range"
L["CT_MailMod/Options/Inbox/Checkboxes/RangeNewTip"] = [=[Choose a range by shift-clicking twice, or remove a range by shift-right-clicking the second time. 
This option clears prior selections when doing so.]=]
L["CT_MailMod/Options/Inbox/Checkboxes/SenderNewCheckButton"] = "Clear selection when ctrl-clicking a sender"
L["CT_MailMod/Options/Inbox/Checkboxes/SenderNewTip"] = [=[Shift-click to choose all messages from the same sender; or shift-right-click to choose all messages from other senders. 
This option clears your prior selections before doing so.]=]
L["CT_MailMod/Options/Inbox/Checkboxes/ShowCheckboxesCheckButton"] = "Show checkboxes and open/close buttons"
L["CT_MailMod/Options/Inbox/Checkboxes/ShowNumbersCheckButton"] = "Show message numbers"
L["CT_MailMod/Options/Inbox/Heading"] = "Inbox"
L["CT_MailMod/Options/Inbox/HideLogCheckButton"] = "|cFFFF9999Hide|r the 'Mail Log' button"
L["CT_MailMod/Options/Inbox/MouseWheelCheckButton"] = "Enable mouse wheel scrolling"
L["CT_MailMod/Options/Inbox/MultipleItemsCheckButton"] = "Show all attachments in message tooltips"
L["CT_MailMod/Options/Inbox/SelectMsgCheckButton"] = "Show tooltip for message checkboxes"
L["CT_MailMod/Options/Inbox/ShowExpiryCheckButton"] = "Show message expiry buttons"
L["CT_MailMod/Options/Inbox/ShowInboxCheckButton"] = "Show number of messages in the inbox"
L["CT_MailMod/Options/Inbox/ShowLongCheckButton"] = "Show long subjects on two lines"
L["CT_MailMod/Options/Inbox/ShowMailboxCheckButton"] = "Show number of messages not in the inbox"
L["CT_MailMod/Options/Tips/Heading"] = "Tips"
L["CT_MailMod/Options/Tips/Line1"] = "You can write /ctmail or /ctmailmod to open this options window directly."


--frFR (credits: ddc)

if (GetLocale() == "frFR") then

L["CT_MailMod/AutoCompleteFilter/Account"] = "Autres toons de cette compte"
L["CT_MailMod/AutoCompleteFilter/Friends"] = "Les amis (incluant ceux qui est hors ligne)"
L["CT_MailMod/AutoCompleteFilter/Group"] = "La groupe actuelle"
L["CT_MailMod/AutoCompleteFilter/Guild"] = "La guilde (incluant ceux qui est hors ligne)"
L["CT_MailMod/AutoCompleteFilter/Online"] = "Ceux qui est en ligne et/ou proche"
L["CT_MailMod/AutoCompleteFilter/Recent"] = "Ceux qui ont parlé récemment"
L["CT_MailMod/DELETE_POPUP1"] = "%d objets incluant %s"
L["CT_MailMod/DELETE_POPUP2"] = "d'argent et %s"
L["CT_MailMod/DELETE_POPUP3"] = "d'argent et %d objets incluant %s"
L["CT_MailMod/Inbox/OpenSelectedButton"] = "Ouvrir"
L["CT_MailMod/Inbox/OpenSelectedTip"] = "Ouvrir les courriers sélectionnés"
L["CT_MailMod/Inbox/ReturnSelectedButton"] = "Renvoyer"
L["CT_MailMod/Inbox/ReturnSelectedTip"] = "Renvoyer les courriers sélectionnés"
L["CT_MailMod/MAIL_DELETE_NO"] = "Pas supprimé."
L["CT_MailMod/MAIL_DELETE_OK"] = "Supprimant le courrier"
L["CT_MailMod/MAIL_DOWNLOAD_BEGIN"] = "Attendant du courrier d'arriver à la boîte de réception"
L["CT_MailMod/MAIL_DOWNLOAD_END"] = "Du courrier a arrivé à la boîte de réception"
L["CT_MailMod/MAIL_OPEN_CLICK"] = "Appuyez sur |c0080A0FFAlt-clic|r pour prendre les contenus."
L["CT_MailMod/MAIL_OPEN_IS_COD"] = "Ce courrier demande d'un paiement à la livraison."
L["CT_MailMod/MAIL_OPEN_IS_GM"] = "Ce courrier est envoyé par Blizzard."
L["CT_MailMod/MAIL_OPEN_NO"] = "Pas ouverte."
L["CT_MailMod/MAIL_OPEN_NO_ITEMS_MONEY"] = "Ce courrier ne contient aucun objet ni argent."
L["CT_MailMod/MAIL_OPEN_OK"] = "Ouvrant le courrier."
L["CT_MailMod/MAIL_RETURN_CLICK"] = "Appuyez sur CTRL-clic pour renvoyer ce courrier."
L["CT_MailMod/MAIL_RETURN_IS_GM"] = "Ce courrier est envoyé par Blizzard."
L["CT_MailMod/MAIL_RETURN_IS_RETURNED"] = "Ce courrier est vous renvoyé."
L["CT_MailMod/MAIL_RETURN_NO"] = "Pas renvoyé."
L["CT_MailMod/MAIL_RETURN_NO_ITEMS_MONEY"] = "Ce courrier ne contient aucun objet ni argent."
L["CT_MailMod/MAIL_RETURN_NO_REPLY"] = "Ce n'est pas possible de répondre ce courrier."
L["CT_MailMod/MAIL_RETURN_NO_SENDER"] = "Ce courrier manque un envoyeur."
L["CT_MailMod/MAIL_RETURN_OK"] = "Renvoyant le courrier."
L["CT_MailMod/MAIL_SEND_OK"] = "Le courrier est envoyé."
L["CT_MailMod/MAIL_TAKE_ITEM_OK"] = "Prenant l'objet."
L["CT_MailMod/MAIL_TAKE_MONEY_OK"] = "Prenant l'argent."
L["CT_MailMod/MAIL_TIMEOUT"] = "L'action a arrêté après le dépassement de délai."
L["CT_MailMod/MAILBOX_BUTTON_TIP1"] = "Obtenir de courrier"
L["CT_MailMod/MAILBOX_DOWNLOAD_MORE_NOW"] = "Recevoir plus de courrier"
L["CT_MailMod/MAILBOX_DOWNLOAD_MORE_SOON"] = [=[Plus de courrier arrive
dans %d seconds]=]
L["CT_MailMod/MAILBOX_OPTIONS_TIP1"] = [=[Cliquez ce bouton, tapez "/ctmail" ou tapez "/ctcourrier" pour accéder les options de CT_MailMod.

Faites un clic-droit ou tapez "/mailog" pour ouvrir le journal de courrier.]=]
L["CT_MailMod/MAILBOX_OVERFLOW_COUNT"] = "Débordement : %d"
L["CT_MailMod/MONEY_DECREASED"] = "Votre argent diminue de : %s"
L["CT_MailMod/MONEY_INCREASED"] = "Votre argent augmente de : %s"
L["CT_MailMod/NOTHING_SELECTED"] = "Aucune courrier sélectionné."
L["CT_MailMod/NUMBER_SELECTED_PLURAL"] = "%d sélectionnés"
L["CT_MailMod/NUMBER_SELECTED_SINGLE"] = "%d sélectionné"
L["CT_MailMod/NUMBER_SELECTED_ZERO"] = "Aucune sélection"
L["CT_MailMod/PROCESSING_CANCELLED"] = "Le traitement des courriers annulé."
L["CT_MailMod/QUICK_DELETE_TIP1"] = "Supprimer ce courrier maintenant"
L["CT_MailMod/QUICK_RETURN_TIP1"] = "Renvoyer ce courrier maintenant"
L["CT_MailMod/SELECT_ALL"] = "Tous"
L["CT_MailMod/SELECT_MESSAGE_TIP1"] = "Mettre à jour la sélection des courriers"
L["CT_MailMod/SELECT_MESSAGE_TIP2"] = [=[|c0080A0FFClic:|r Sélecter un seul courrier

|c0080A0FFAlt-click-gauche:|r Sélectionner tous ayant le même sujet
|c0080A0FFAlt-clic-droite:|r Sélectionner tous ayant un sujet différent

|c0080A0FFCtrl-clic-gauche:|r Sélectionner tous de cet envoyeur
|c0080A0FFCtrl-clic-droite:|r Sélectionner tous d'autres envoyeurs

|c0080A0FFMaj-clic:|r Commencer une gamme
|c0080A0FFMaj-clic-gauche:|r Finir la gamme et sélectionner les courriers
|c0080A0FFMaj-clic-droite:|r Finir la gamme et désélectionner les courriers]=]
L["CT_MailMod/SEND_MAIL_MONEY_SUBJECT_COPPER"] = "%d cuivre"
L["CT_MailMod/SEND_MAIL_MONEY_SUBJECT_GOLD"] = "%d or %d argent %d cuivre"
L["CT_MailMod/SEND_MAIL_MONEY_SUBJECT_SILVER"] = "%d argent %d cuivre"
L["CT_MailMod/STOP_SELECTED"] = "Annuler"
L["CT_MailMod/Options/Bags/CloseAllCheckButton"] = "Fermer tous les sacs"
L["CT_MailMod/Options/Bags/CloseLabel"] = "Quand la boîte ferme :"
L["CT_MailMod/Options/Bags/Heading"] = "Les sacs d'inventaire"
L["CT_MailMod/Options/Bags/Line1"] = "Désactivant ces options peut être nécessaire pour compatabilité aux autres addons de gestion des sacs"
L["CT_MailMod/Options/Bags/OpenAllCheckButton"] = "Ouvrir tous les sacs"
L["CT_MailMod/Options/Bags/OpenBackpackCheckButton"] = "Ouvrir le sac à dos"
L["CT_MailMod/Options/Bags/OpenLabel"] = "Quand la boîte ouvre :"
L["CT_MailMod/Options/General/BlockTradesCheckButton"] = "Bloquer les échanges en lisant le courrier"
L["CT_MailMod/Options/General/Heading"] = "Les options génerales"
L["CT_MailMod/Options/General/NetIncomeCheckButton"] = "Imprimer le revenu net quand le courrier ferme"
L["CT_MailMod/Options/Inbox/Checkboxes/Heading"] = "Les cases à cocher"
L["CT_MailMod/Options/Inbox/Checkboxes/Line1"] = "Passez la souris sur le bouton '?' pour plus d'info"
L["CT_MailMod/Options/Inbox/Checkboxes/RangeNewCheckButton"] = "Réinitialiser avant faire une gamme (Maj)"
L["CT_MailMod/Options/Inbox/Checkboxes/RangeNewTip"] = [=[Choisir une gamme en appuyant Maj-click deux fois, ou réduire une gamme en appuyant Maj-clic-droite la deuxième fois. 
Cet option efface les sélections antérieures.]=]
L["CT_MailMod/Options/Inbox/Checkboxes/SenderNewCheckButton"] = "Réinitialiser avant choisir une éxp. (ctrl)"
L["CT_MailMod/Options/Inbox/Checkboxes/SenderNewTip"] = [=[Choisir chaque courrier du même éxpéditeur (ctrl-clic-gauche), ou des autres éxpéditeurs (ctrl-clic-droite). 
Cet option efface les sélections antérieures.]=]
L["CT_MailMod/Options/Inbox/Checkboxes/ShowCheckboxesCheckButton"] = "Montrer les cases à cocher et boutons d'ouv./fer."
L["CT_MailMod/Options/Inbox/Checkboxes/ShowNumbersCheckButton"] = "Numérer les courriers"
L["CT_MailMod/Options/Inbox/Heading"] = "Boîte de réception"
L["CT_MailMod/Options/Inbox/HideLogCheckButton"] = "|cFFFF9999Cacher|r le bouton 'Log' (journal)"
L["CT_MailMod/Options/Inbox/MouseWheelCheckButton"] = "Activer le défilement de la souris"
L["CT_MailMod/Options/Inbox/MultipleItemsCheckButton"] = "Montrer les attaches dans les info-bulles"
L["CT_MailMod/Options/Inbox/SelectMsgCheckButton"] = "Montrer l'info-bulle des cases à cocher"
L["CT_MailMod/Options/Inbox/ShowExpiryCheckButton"] = "Montrer les boutons d'éxpiration de courrier"
L["CT_MailMod/Options/Inbox/ShowInboxCheckButton"] = "Montrer combien de courrier est arrivé"
L["CT_MailMod/Options/Inbox/ShowLongCheckButton"] = "Diviser des sujets longs en deux lignes"
L["CT_MailMod/Options/Inbox/ShowMailboxCheckButton"] = "Montrer combien de courrier ne peut pas arriver"
L["CT_MailMod/Options/Tips/Heading"] = "Des conseils"
L["CT_MailMod/Options/Tips/Line1"] = "Vous pouvez écrire /ctcourrier or /ctmailmod pour ouvrir ces options."


--deDE (credits: dynaletik)

elseif (GetLocale() == "deDE") then

L["CT_MailMod/AutoCompleteFilter/Account"] = "Eigene Twinks auf diesem Account"
L["CT_MailMod/AutoCompleteFilter/Friends"] = "Kontaktliste (inklusive offline)"
L["CT_MailMod/AutoCompleteFilter/Group"] = "Aktuelle Gruppe"
L["CT_MailMod/AutoCompleteFilter/Guild"] = "Gildenliste (inklusive offline)"
L["CT_MailMod/AutoCompleteFilter/Online"] = "Online und/oder Twinks in der Nähe"
L["CT_MailMod/AutoCompleteFilter/Recent"] = "Zuletzt interagiert"
L["CT_MailMod/DELETE_POPUP1"] = "%d Gegenstände enthalten %s"
L["CT_MailMod/DELETE_POPUP2"] = "etwas Geld und %s"
L["CT_MailMod/DELETE_POPUP3"] = "etwas Geld und %d Gegenstände enthalten %s"
L["CT_MailMod/Inbox/OpenSelectedButton"] = "Öffnen"
L["CT_MailMod/Inbox/OpenSelectedTip"] = "Gewählte Nachrichten öffnen"
L["CT_MailMod/Inbox/ReturnSelectedButton"] = "Zurücksenden"
L["CT_MailMod/Inbox/ReturnSelectedTip"] = "Gewählte Nachrichten zurücksenden"
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
L["CT_MailMod/MAILBOX_OPTIONS_TIP1"] = [=[Klicke diese Schaltfläche oder gebe /ctmail ein, um CTMailMod Optionen oder Hinweise anzuzeigen. 

Rechtsklick oder /maillog eingeben um Protokollfenster ein-/auszublenden.]=]
L["CT_MailMod/MAILBOX_OVERFLOW_COUNT"] = "Überlauf: %d"
L["CT_MailMod/MONEY_DECREASED"] = "Geld verringert um: %s"
L["CT_MailMod/MONEY_INCREASED"] = "Geld erhöht um: %s"
L["CT_MailMod/NOTHING_SELECTED"] = "Es sind keine Briefe ausgewählt."
L["CT_MailMod/NUMBER_SELECTED_PLURAL"] = "%d gewählt"
L["CT_MailMod/NUMBER_SELECTED_SINGLE"] = "%d gewählt"
L["CT_MailMod/NUMBER_SELECTED_ZERO"] = "%d gewählt"
L["CT_MailMod/PROCESSING_CANCELLED"] = "Briefkasten Bearbeitung abgebrochen."
L["CT_MailMod/QUICK_DELETE_TIP1"] = "Brief jetzt löschen"
L["CT_MailMod/QUICK_RETURN_TIP1"] = "Brief jetzt zurücksenden"
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
L["CT_MailMod/Send/AutoComplete/Heading"] = "Auto-Vervollständigung Einstellungen"
L["CT_MailMod/Send/AutoComplete/Tip"] = "Abwärts-Pfeil zum Ändern der Filter wählen"
L["CT_MailMod/SEND_MAIL_MONEY_SUBJECT_COPPER"] = "%d Kupfer"
L["CT_MailMod/SEND_MAIL_MONEY_SUBJECT_GOLD"] = "%d Gold %d Silber %d Kupfer"
L["CT_MailMod/SEND_MAIL_MONEY_SUBJECT_SILVER"] = "%d Silber %d Kupfer"
L["CT_MailMod/STOP_SELECTED"] = "Abbrechen"


end