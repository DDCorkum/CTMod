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

module.text = module.text or { };	-- see localization.lua
L = module.text;

--------------------------------------------

local defaultLogColor = { 0, 0, 0, 0.75 };

--------------------------------------------
-- Options Window

local optionsFrameList;
local function optionsInit()
	optionsFrameList = module:framesInit();
end
local function optionsGetData()
	return module:framesGetData(optionsFrameList);
end
local function optionsAddFrame(offset, size, details, data)
	module:framesAddFrame(optionsFrameList, offset, size, details, data);
end
local function optionsAddObject(offset, size, details)
	module:framesAddObject(optionsFrameList, offset, size, details);
end
local function optionsAddScript(name, func)
	module:framesAddScript(optionsFrameList, name, func);
end
local function optionsBeginFrame(offset, size, details, data)
	module:framesBeginFrame(optionsFrameList, offset, size, details, data);
end
local function optionsEndFrame()
	module:framesEndFrame(optionsFrameList);
end

local optionsFrame;

module.frame = function()
	local textColor1 = "0.9:0.9:0.9";
	local textColor2 = "0.7:0.7:0.7";
	local textColor3 = "0.9:0.72:0.0";

	optionsInit();

	optionsBeginFrame(-5, 0, "frame#tl:0:%y#r");
		-- Tips
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#" .. L["CT_MailMod/Options/Tips/Heading"]);
		optionsAddObject( -2, 2*14, "font#t:0:%y#s:0:%s#l:13:0#r#" .. L["CT_MailMod/Options/Tips/Line1"] .. "#" .. textColor2 .. ":l");

		-- General Options
		optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#" .. L["CT_MailMod/Options/General/Heading"]);
		optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:blockTrades#" .. L["CT_MailMod/Options/General/BlockTradesCheckButton"]);
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:showMoneyChange#" .. L["CT_MailMod/Options/General/NetIncomeCheckButton"]);

		optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#" .. L["CT_MailMod/Options/Bags/Heading"]);
		optionsAddObject( -8, 4*13, "font#t:0:%y#s:0:%s#l:13:0#r#" .. L["CT_MailMod/Options/Bags/Line1"] .. "#" .. textColor2 .. ":l");

		optionsAddObject( -6,   15, "font#tl:15:%y#v:ChatFontNormal#" .. L["CT_MailMod/Options/Bags/OpenLabel"]);
		optionsAddObject( -3,   26, "checkbutton#tl:35:%y#o:openAllBags#i:openAllBags#" .. L["CT_MailMod/Options/Bags/OpenAllCheckButton"]);
		optionsAddObject(  6,   26, "checkbutton#tl:35:%y#o:openBackpack#i:openBackpack#" .. L["CT_MailMod/Options/Bags/OpenBackpackCheckButton"]);
		optionsAddObject(  6,   26, "checkbutton#tl:35:%y#o:openNoBags#i:openNoBags#" .. L["CT_MailMod/Options/Bags/CloseAllCheckButton"]);

		optionsAddObject( -6,   15, "font#tl:15:%y#v:ChatFontNormal#" .. L["CT_MailMod/Options/Bags/CloseLabel"]);
		optionsAddObject( -3,   26, "checkbutton#tl:35:%y#o:closeAllBags#" .. L["CT_MailMod/Options/Bags/CloseAllCheckButton"]);

		-- Inbox Options
		optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#" .. L["CT_MailMod/Options/Inbox/Heading"]);
		optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:inboxMouseWheel:true#" .. L["CT_MailMod/Options/Inbox/MouseWheelCheckButton"]);
		optionsBeginFrame( 6,   26, "checkbutton#tl:10:%y#o:inboxShowNumbers:true#" .. L["CT_MailMod/Options/Inbox/ShowNumbersCheckButton"]);
			optionsAddScript("onenter",
				function(self)
					if (module:getOption("hideOpenCloseFeature")) then
						GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT", 15, -25);
						GameTooltip:SetText("Disabled while checkboxes and open/close buttons hidden");
						GameTooltip:Show();
					end
				end
			);
			optionsAddScript("onleave",
				function(self)
					GameTooltip:Hide();
				end
			);
			optionsAddScript("onupdate",
				function(self)
					if (module:getOption("hideOpenCloseFeature")) then
						--self.text:SetTextColor(0.5, 0.5, 0.5, 1);
						self:SetAlpha(0.5);
					else
						--self.text:SetTextColor(1,1,1,1);
						self:SetAlpha(1);
					end
				end
			);
		optionsEndFrame();
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:inboxShowLong:true#" .. L["CT_MailMod/Options/Inbox/ShowLongCheckButton"]);
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:inboxShowExpiry:true#" .. L["CT_MailMod/Options/Inbox/ShowExpiryCheckButton"]);
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:inboxShowInbox:true#" .. L["CT_MailMod/Options/Inbox/ShowInboxCheckButton"]);
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:inboxShowMailbox:true#" .. L["CT_MailMod/Options/Inbox/ShowMailboxCheckButton"]);
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:toolMultipleItems:true#" .. L["CT_MailMod/Options/Inbox/MultipleItemsCheckButton"]);
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:toolSelectMsg:true#" .. L["CT_MailMod/Options/Inbox/SelectMsgCheckButton"]);
		optionsBeginFrame( 6,   26, "checkbutton#tl:10:%y#o:hideLogButton#" .. L["CT_MailMod/Options/Inbox/HideLogCheckButton"]);
			optionsAddScript("onenter",
				function(self)
					GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT", 15, -25);
					GameTooltip:SetText("This only hides the button; options further below control logging");
					GameTooltip:AddLine("|c999999FFWhile hidden, right-click on the 'globe' or type /maillog");
					GameTooltip:Show();
				end
			);
			optionsAddScript("onleave",
				function(self)
					GameTooltip:Hide();
				end
			);
		optionsEndFrame();
		optionsBeginFrame( 6,   26, "checkbutton#tl:10:%y#o:hideOpenCloseFeature#" .. L["CT_MailMod/Options/Inbox/HideOpenCloseFeatureCheckButton"]);
			optionsAddScript("onenter",
				function(self)
					GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT", 15, -25);
					GameTooltip:SetText("This disables some custom CT features; leaving default UI intact");
					GameTooltip:Show();
				end
			);
			optionsAddScript("onleave",
				function(self)
					GameTooltip:Hide();
				end
			);
		optionsEndFrame();
		optionsAddObject(-10, 1*13, "font#t:0:%y#s:0:%s#l:13:0#r#Tips#" .. textColor3 .. ":l");
		optionsAddObject(-10, 2*13, "font#t:0:%y#s:0:%s#l:13:0#r#Right-click the Prev/Next buttons to jump to the first/last page of the inbox.#" .. textColor1 .. ":l");

		-- Selecting Messages
		optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#Message Selection");
		optionsAddObject(-10, 4*13, "font#t:0:%y#s:0:%s#l:13:0#r#Selecting messages will add them to the selection list.  Unselecting messages will remove them from the selection list.#" .. textColor3 .. ":l");
		optionsAddObject(  0,   26, "checkbutton#tl:10:%y#o:inboxSenderNew:true#Clear selection list before selecting a sender");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:inboxRangeNew:true#Clear selection list before selecting a range");
		optionsAddObject(-10, 1*13, "font#t:0:%y#s:0:%s#l:13:0#r#Tips#" .. textColor3 .. ":l");
		optionsAddObject(-10, 2*13, "font#t:0:%y#s:0:%s#l:13:0#r#To select or unselect a message, click the message's checkbox.#" .. textColor1 .. ":l");
		optionsAddObject( -8, 2*13, "font#t:0:%y#s:0:%s#l:13:0#r#To select messages with similar subjects, Alt left-click the message's checkbox.#" .. textColor2 .. ":l");
		optionsAddObject( -8, 2*13, "font#t:0:%y#s:0:%s#l:13:0#r#To unselect messages with similar subjects, Alt right-click the message's checkbox.#" .. textColor1 .. ":l");
		optionsAddObject( -8, 2*13, "font#t:0:%y#s:0:%s#l:13:0#r#To select all messages from the same sender, Ctrl left-click the message's checkbox.#" .. textColor2 .. ":l");
		optionsAddObject( -8, 3*13, "font#t:0:%y#s:0:%s#l:13:0#r#To unselect all messages from the same sender, Ctrl right-click the message's checkbox.#" .. textColor1 .. ":l");
		optionsAddObject( -8, 3*13, "font#t:0:%y#s:0:%s#l:13:0#r#To select a range of messages, Shift click one message's checkbox and then Shift left-click a second one.#" .. textColor2 .. ":l");
		optionsAddObject( -8, 3*13, "font#t:0:%y#s:0:%s#l:13:0#r#To unselect a range of messages, Shift click one message's checkbox and then Shift right-click a second one.#" .. textColor1 .. ":l");

		-- Send Mail Options
		optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#Send Mail");
		optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:sendmailAltClickItem#Alt left-click adds items to the Send Mail tab");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:sendmailMoneySubject:true#Replace blank subject with money amount");
		optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:sendmailAutoCompleteUse#Filter auto-completion of Send To field");
		optionsAddObject(  6,   40, "font#t:0:%y#s:0:%s#l:13:0#r#Choose filters via the arrow next to Send To field#" .. textColor1 .. ":l");

		-- Mail Log Options
		optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#Mail Log");
		optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:printLog#Print log messages to chat");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:saveLog:true#Save log messages in the mail log");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:logOpenedMail:true#Log opened mail");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:logReturnedMail:true#Log returned mail");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:logDeletedMail:true#Log deleted mail");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:logSentMail:true#Log sent mail");

		optionsAddObject(-10,   16, "colorswatch#tl:15:%y#s:16:16#o:logColor:" .. defaultLogColor[1] .. "," .. defaultLogColor[2] .. "," .. defaultLogColor[3] .. "," .. defaultLogColor[4] .. "#true");
		optionsAddObject( 14,   15, "font#tl:40:%y#v:ChatFontNormal#Background color");

		optionsAddObject(-25,   17, "slider#t:0:%y#o:logWindowScale:1#s:175:%s#Mail Log Scale - <value>#0.20:2:0.01");

		optionsAddObject(-25, 1*13, "font#t:0:%y#s:0:%s#l:13:0#r#Tips#" .. textColor3 .. ":l");
		optionsAddObject(-10, 2*13, "font#t:0:%y#s:0:%s#l:13:0#r#Type /maillog to open the mail log when you are not at a mailbox.#" .. textColor1 .. ":l");
		optionsAddObject(-10, 2*13, "font#t:0:%y#s:0:%s#l:13:0#r#You can adjust the size of the subject column by resizing the mail log window.#" .. textColor1 .. ":l");
		optionsAddObject(-10, 3*13, "font#t:0:%y#s:0:%s#l:13:0#r#The mail log window can be resized by dragging the left or right edges of the window.#" .. textColor1 .. ":l");

		optionsAddObject(-20, 1*13, "font#t:0:%y#s:0:%s#l:13:0#r#Delete Log Entries#" .. textColor3 .. ":l");
		optionsAddObject(-10,   26, "checkbutton#tl:10:%y#o:resetLog#i:resetLog#I want to delete all of the log entries");
		optionsBeginFrame(  -5,   30, "button#t:0:%y#s:120:%s#v:UIPanelButtonTemplate#i:deleteLogButton#Delete log");
			optionsAddScript("onclick",
				function(self)
					if (module:getOption("resetLog")) then
						module:setOption("resetLog", nil, true);
						CT_MailModOptions["mailLog"] = {};
						module:updateMailLog();
					end
				end
			);
		optionsEndFrame();



		optionsAddScript("onload",
			function (self)
				optionsFrame = self;
			end
		);
		optionsAddScript("onshow",
			function(self)
				module:setOption("resetLog", nil, true);
			end
		);
	optionsEndFrame();

	return "frame#all", optionsGetData();
end

local function getoption(name, default)
	local value;
	value = module:getOption(name);
	if (value == nil) then
		return default;
	else
		return value;
	end
end

module.opt = {};

module.update = function(self, optName, value)
	local opt = module.opt;
	if (optName == "init") then
		-- General
		opt.openBackpack = getoption("openBackpack", false);
		opt.openAllBags = getoption("openAllBags", false);
		opt.closeAllBags = getoption("closeAllBags", false);
		opt.blockTrades = getoption("blockTrades", false);
		opt.showMoneyChange = getoption("showMoneyChange", false);

		-- Inbox
		opt.inboxMouseWheel = getoption("inboxMouseWheel", true);
		opt.inboxShowNumbers = getoption("inboxShowNumbers", true);
		opt.inboxShowLong = getoption("inboxShowLong", true);
		opt.inboxShowExpiry = getoption("inboxShowExpiry", true);
		opt.inboxShowInbox = getoption("inboxShowInbox", true);
		opt.inboxShowMailbox = getoption("inboxShowMailbox", true);
		opt.toolMultipleItems = getoption("toolMultipleItems", true);
		opt.toolSelectMsg = getoption("toolSelectMsg", true);

		-- Message selection
		opt.inboxSenderNew = getoption("inboxSenderNew", true);
		opt.inboxRangeNew = getoption("inboxRangeNew", true);

		-- Mail Log
		opt.printLog = getoption("printLog", false);
		opt.saveLog = getoption("saveLog", true);
		opt.logOpenedMail = getoption("logOpenedMail", true);
		opt.logReturnedMail = getoption("logReturnedMail", true);
		opt.logDeletedMail = getoption("logDeletedMail", true);
		opt.logSentMail = getoption("logSentMail", true);
		opt.logWindowScale = getoption("logWindowScale", 1);
		opt.logColor = getoption("logColor", defaultLogColor);
		opt.hideLogButton = getoption("hideLogButton", false);
		module:updateMailLogButton();
		opt.hideOpenCloseFeature = getoption("hideOpenCloseFeature", false);
		module:updateOpenCloseButtons();
		module:updateSelectAllCheckbox();

		module:setOption("resetLog", nil, true);

		-- Send Mail
		opt.sendmailAltClickItem = getoption("sendmailAltClickItem", true);
		opt.sendmailMoneySubject = getoption("sendmailMoneySubject", true);
		module.configureSendToNameAutoComplete();
		local temp = getoption("sendmailAutoCompleteUse", 5);  -- 5 is a non-sensical value, demonstrating the var was never set
		if (temp == 5) then
			module:setOption("sendmailAutoCompleteUse", true, false);
			module:setOption("sendmailAutoCompleteFriends", true, false);
			module:setOption("sendmailAutoCompleteGuild", true, false);
			module:setOption("sendmailAutoCompleteInteracted", true, false);
			module:setOption("sendmailAutoCompleteGroup", true, false);
			module:setOption("sendmailAutoCompleteOnline", true, false);
			module:setOption("sendmailAutoCompleteAccount", true, false);
		end

	-- General options
	else
		opt[optName] = value;

		if (
			optName == "inboxShowNumbers" or
			optName == "inboxShowLong" or
			optName == "inboxShowExpiry" or
			optName == "inboxShowInbox" or
			optName == "inboxShowMailbox"
		) then
			module:raiseCustomEvent("INCOMING_UPDATE");

		elseif (optName == "logWindowScale") then
			module:scaleMailLog();

		elseif (optName == "logColor") then
			module:updateMailLogColor();

		elseif (optName == "hideLogButton") then
			module:updateMailLogButton();
			
		elseif (optName == "hideOpenCloseFeature") then
			module:updateOpenCloseButtons();  -- hide the open/close buttons
			module:updateSelectAllCheckbox(); -- hide the select all checkbox
			module:inboxUpdateSelection();    -- hide any currently open checkboxes

		elseif (optName == "resetLog") then
			if (optionsFrame) then
				if (value) then
					optionsFrame.resetLog:SetChecked(true);
					optionsFrame.deleteLogButton:Enable();
				else
					optionsFrame.resetLog:SetChecked(false);
					optionsFrame.deleteLogButton:Disable();
				end
			end

		elseif (optName == "blockTrades") then
			module.configureBlockTradesMail(value);

		elseif (
			optName == "sendmailAutoCompleteUse" or
			optName == "sendmailAutoCompleteFriends" or
			optName == "sendmailAutoCompleteGuild" or
			optName == "sendmailAutoCompleteInteracted" or
			optName == "sendmailAutoCompleteGroup" or
			optName == "sendmailAutoCompleteOnline" or
			optName == "sendmailAutoCompleteAccount"
		) then
			module.configureSendToNameAutoComplete();

		elseif (optName == "openAllBags") then
			if (value) then
				local value = false;
				opt.openBackpack = value;
				opt.openNoBags = value;
				module:setOption("openBackpack", value, true, false);
				module:setOption("openNoBags", value, true, false);
				if (optionsFrame) then
					optionsFrame.openBackpack:SetChecked(value);
					optionsFrame.openNoBags:SetChecked(value);
				end
			end

		elseif (optName == "openBackpack") then
			if (value) then
				local value = false;
				opt.openAllBags = value;
				opt.openNoBags = value;
				module:setOption("openAllBags", value, true, false);
				module:setOption("openNoBags", value, true, false);
				if (optionsFrame) then
					optionsFrame.openAllBags:SetChecked(value);
					optionsFrame.openNoBags:SetChecked(value);
				end
			end

		elseif (optName == "openNoBags") then
			if (value) then
				local value = false;
				opt.openAllBags = value;
				opt.openBackpack = value;
				module:setOption("openAllBags", value, true, false);
				module:setOption("openBackpack", value, true, false);
				if (optionsFrame) then
					optionsFrame.openAllBags:SetChecked(value);
					optionsFrame.openBackpack:SetChecked(value);
				end
			end

		end
	end
end


module.externalDropDown_Initialize = function()
	info = { };
	info.text = "CT_MailMod";
	info.isTitle = 1;
	info.justifyH = "CENTER";
	info.notCheckable = 1;
	L_UIDropDownMenu_AddButton(info, L_UIDROPDOWNMENU_MENU_LEVEL);

	info = { };
	info.text = "Open options";
	info.notCheckable = 1;
	info.func = function()
		module:showModuleOptions(module.name);
	end
	L_UIDropDownMenu_AddButton(info, L_UIDROPDOWNMENU_MENU_LEVEL);	
	
	info = { };
	info.text = "Open mail log";
	info.notCheckable = 1;
	info.func = module.showMailLog;
	L_UIDropDownMenu_AddButton(info, L_UIDROPDOWNMENU_MENU_LEVEL);	
end