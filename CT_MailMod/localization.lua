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

-- Generic
module:setText("NUMBER_SELECTED", "%d selected");
module:setText("INBOX_COUNT", "Inbox: %d");
module:setText("MAILBOX_COUNT", "Mailbox: %d");
module:setText("MAILBOX_BUTTON_TIP1", "Download mail");

module:setText("SELECT_ALL", "Select All");
module:setText("MAIL_LOG", "Log");

module:setText("NOTHING_SELECTED", "No messages are selected.");
module:setText("OPEN_SELECTED", "Open");
module:setText("RETURN_SELECTED", "Return");
module:setText("STOP_SELECTED", "Cancel");
module:setText("PROCESSING_CANCELLED", "Mailbox processing cancelled.");

module:setText("SELECT_MESSAGE_TIP1", "Update message selection");
module:setText("SELECT_MESSAGE_TIP2",
	   "\n|c0080A0FFClick:|r Select or unselect single\n\n"
	.. "|c0080A0FFAlt Left-click:|r Select similar subjects\n"
	.. "|c0080A0FFAlt Right-click:|r Unselect similar subjects\n\n"
	.. "|c0080A0FFCtrl Left-click:|r Select same sender\n"
	.. "|c0080A0FFCtrl Right-click:|r Unselect same sender\n\n"
	.. "|c0080A0FFShift click:|r Mark start of range\n"
	.. "|c0080A0FFShift Left-click:|r End range and select mail\n"
	.. "|c0080A0FFShift Right-click:|r End range and unselect mail"
);

module:setText("QUICK_RETURN_TIP1", "Return the message now");
module:setText("QUICK_DELETE_TIP1", "Delete the message now");

module:setText("MAIL_OPEN_CLICK", "Press |c0080A0FFAlt-click|r to take the contents.");
module:setText("MAIL_RETURN_CLICK", "Press |c0080A0FFCtrl-click|r to return the message.");

module:setText("MONEY_INCREASED", "Your money increased by: %s");
module:setText("MONEY_DECREASED", "Your money decreased by: %s");

module:setText("MAIL_DOWNLOAD_BEGIN", "Waiting for mail to download into the inbox.");
module:setText("MAIL_DOWNLOAD_END", "Mail has downloaded into the inbox.");

module:setText("MAILBOX_OPTIONS_TIP1", "To access CT_MailMod options and tips, click this button or type /ctmail.\nRight click to toggle the mail log window or type /maillog.");

-- Send Mail
module:setText("SEND_MAIL_MONEY_SUBJECT_GOLD", "%d gold %d silver %d copper");
module:setText("SEND_MAIL_MONEY_SUBJECT_SILVER", "%d silver %d copper");
module:setText("SEND_MAIL_MONEY_SUBJECT_COPPER", "%d copper");

-- Mass Mailing
module:setText("MASS_MAILING", "Mass Mailing");
module:setText("MASS_MAILING_INFO", "You may send as many items as you want to a single person. " ..
			   "Drag and drop an item to the green box below, or Alt Right-click an item in your inventory.");
module:setText("MASS_MAILING_ITEMS", "Items");
module:setText("MASS_MAILING_DROP_ITEMS", "Drop items here to add to mail.");
module:setText("MASS_MAILING_DROP_HERE", "Drop the item here to add it to the mail.");
module:setText("MASS_MAILING_CLICK_REMOVE", "Click to remove item from mail.");
module:setText("MASS_MAILING_POSTAGE", "Postage:");
module:setText("MASS_MAILING_SEND", "Send");
module:setText("MASS_MAILING_CANCEL", "Cancel");

-- Log messages
module:setText("MAIL_LOOT_ERROR", "Item not taken:");
module:setText("MAIL_TIMEOUT", "Action timed out.");

module:setText("MAIL_OPEN_OK",             "Opening mail.");
module:setText("MAIL_OPEN_NO",             "Not opened.");
module:setText("MAIL_OPEN_IS_COD",         "Mail is Cash on Delivery.");
module:setText("MAIL_OPEN_IS_GM",          "Mail is from Blizzard.");
module:setText("MAIL_OPEN_NO_ITEMS_MONEY", "Mail has no items or money.");

module:setText("MAIL_RETURN_OK",             "Returning mail.");
module:setText("MAIL_RETURN_NO",             "Not returned.");
module:setText("MAIL_RETURN_NO_SENDER",      "Mail has no sender.");
module:setText("MAIL_RETURN_IS_RETURNED",    "Mail is returning to you.");
module:setText("MAIL_RETURN_IS_GM",          "Mail is from Blizzard.");
module:setText("MAIL_RETURN_NO_ITEMS_MONEY", "Mail has no items or money.");
module:setText("MAIL_RETURN_NO_REPLY",       "Mail cannot be replied to.");

module:setText("MAIL_DELETE_OK", "Deleting mail.");
module:setText("MAIL_DELETE_NO", "Not deleted.");

module:setText("MAIL_TAKE_ITEM_OK",  "Taking attachment.");

module:setText("MAIL_TAKE_MONEY_OK", "Taking money.");

module:setText("MAIL_SEND_OK", "Mail sent.");

-- "Deleting this may will also destroy "
--   <number> items including <item>
--   some money and <item>
--   some money and <number> items including <item>
module:setText("DELETE_POPUP1", "%d items including %s");
module:setText("DELETE_POPUP2", "some money and %s");
module:setText("DELETE_POPUP3", "some money and %d items including %s");
