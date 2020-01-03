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
local L = module.text;

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

local function optionsAddTooltip(text, anchor, offx, offy, owner)
	module:framesAddScript(optionsFrameList, "onenter", function(obj) module:displayTooltip(obj, text, anchor, offx, offy, owner); end);
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
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:inboxShowLong:true#" .. L["CT_MailMod/Options/Inbox/ShowLongCheckButton"]);
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:inboxShowExpiry:true#" .. L["CT_MailMod/Options/Inbox/ShowExpiryCheckButton"]);
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:inboxShowInbox:true#" .. L["CT_MailMod/Options/Inbox/ShowInboxCheckButton"]);
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:inboxShowMailbox:true#" .. L["CT_MailMod/Options/Inbox/ShowMailboxCheckButton"]);
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:toolMultipleItems:true#" .. L["CT_MailMod/Options/Inbox/MultipleItemsCheckButton"]);
		optionsBeginFrame( 6,   26, "checkbutton#tl:10:%y#o:hideLogButton#" .. L["CT_MailMod/Options/Inbox/HideLogCheckButton"]);
			optionsAddTooltip({"This only hides the button; options further below control logging","While hidden, right-click on the 'globe' or type /maillog#" .. textColor1}, "ANCHOR_BOTTOMRIGHT", 15, -25);
		optionsEndFrame();

		-- Inbox Checkboxes
		optionsAddObject(-10,   17, "font#tl:13:%y#v:GameFontNormal#" .. L["CT_MailMod/Options/Inbox/Checkboxes/Heading"] .. "#" .. textColor3 .. ":l");
		optionsBeginFrame(  17,   17, "button#tl:250:%y#s:40:%s#v:UIPanelButtonTemplate#?");
			optionsAddTooltip({L["CT_MailMod/Options/Inbox/Checkboxes/Heading"],L["CT_MailMod/SELECT_MESSAGE_TIP2"]}, "ANCHOR_RIGHT", 35, 0);
		optionsEndFrame();
		optionsAddObject(  0, 2*13, "font#t:0:%y#s:0:%s#l:13:0#r#" .. L["CT_MailMod/Options/Inbox/Checkboxes/Line1"] .. "#" .. textColor2 .. ":l");
		optionsAddObject(  0,   26, "checkbutton#tl:10:%y#o:showCheckboxes:true#" .. L["CT_MailMod/Options/Inbox/Checkboxes/ShowCheckboxesCheckButton"]);
		optionsBeginFrame( 0, 0, "frame#tl:0:%y#br:tr:0:%b");
			optionsAddObject(  6,   26, "checkbutton#tl:20:%y#o:toolSelectMsg:true#" .. L["CT_MailMod/Options/Inbox/SelectMsgCheckButton"]);
			optionsAddObject(  6,   26, "checkbutton#tl:20:%y#o:inboxShowNumbers:true#" .. L["CT_MailMod/Options/Inbox/Checkboxes/ShowNumbersCheckButton"]);
			optionsBeginFrame( 6,   26, "checkbutton#tl:20:%y#o:inboxSenderNew:true#" .. L["CT_MailMod/Options/Inbox/Checkboxes/SenderNewCheckButton"])
				optionsAddTooltip({L["CT_MailMod/Options/Inbox/Checkboxes/SenderNewCheckButton"],L["CT_MailMod/Options/Inbox/Checkboxes/SenderNewTip"] .. "#" .. textColor1}, "ANCHOR_RIGHT", 35, 0);
			optionsEndFrame();
			optionsBeginFrame( 6,   26, "checkbutton#tl:20:%y#o:inboxRangeNew:true#" .. L["CT_MailMod/Options/Inbox/Checkboxes/RangeNewCheckButton"])
				optionsAddTooltip({L["CT_MailMod/Options/Inbox/Checkboxes/RangeNewCheckButton"],L["CT_MailMod/Options/Inbox/Checkboxes/RangeNewTip"] .. "#" .. textColor1}, "ANCHOR_RIGHT", 35, 0);
			optionsEndFrame();
			optionsAddScript( "onupdate",
				function (frame)
					frame:SetAlpha((module.opt.showCheckboxes and 1) or 0.5);
				end
			);
		optionsEndFrame();
		
		-- Send Mail Options
		optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#" .. L["CT_MailMod/Options/SendMail/Heading"]);
		optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:sendmailAltClickItem#" .. L["CT_MailMod/Options/SendMail/AltClickCheckButton"]);
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:sendmailMoneySubject:true#" .. L["CT_MailMod/Options/SendMail/ReplaceSubjectCheckButton"]);
		optionsBeginFrame(6,   26, "checkbutton#tl:10:%y#o:sendmailAutoCompleteUse#" .. L["CT_MailMod/Options/SendMail/FilterAutoCompleteCheckButton"]);
			optionsAddTooltip({
				L["CT_MailMod/Options/SendMail/FilterAutoCompleteCheckButton"],
				L["CT_MailMod/Options/SendMail/FilterAutoCompleteTip"] .. "#" .. textColor1,
				" - " .. L["CT_MailMod/AutoCompleteFilter/Account"] .. "#" .. textColor2,
				" - " .. L["CT_MailMod/AutoCompleteFilter/Friends"] .. "#" .. textColor2,
				" - " .. L["CT_MailMod/AutoCompleteFilter/Group"] .. "#" .. textColor2,
				" - " .. L["CT_MailMod/AutoCompleteFilter/Guild"] .. "#" .. textColor2,
				" - " .. L["CT_MailMod/AutoCompleteFilter/Online"] .. "#" .. textColor2,
				" - " .. L["CT_MailMod/AutoCompleteFilter/Recent"] .. "#" .. textColor2,				
			}, "CT_ABOVEBELOW", 0, 0, CTCONTROLPANEL);
		optionsEndFrame();

		-- Mail Log Options
		optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#" .. L["CT_MailMod/Options/MailLog/Heading"]);
		optionsBeginFrame(  17,   17, "button#tl:250:%y#s:40:%s#v:UIPanelButtonTemplate#?");
			optionsAddTooltip({L["CT_MailMod/Options/MailLog/Heading"],L["CT_MailMod/Options/MailLog/Tip"] .. "#" .. textColor2}, "ANCHOR_RIGHT", 35, 0);
		optionsEndFrame();
		optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:printLog#" .. L["CT_MailMod/Options/MailLog/PrintCheckButton"]);
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:saveLog:true#" .. L["CT_MailMod/Options/MailLog/SaveCheckButton"]);
		optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:logOpenedMail:true#" .. L["CT_MailMod/Options/MailLog/LogOpennedCheckButton"]);
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:logReturnedMail:true#" .. L["CT_MailMod/Options/MailLog/LogReturnedCheckButton"]);
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:logDeletedMail:true#" .. L["CT_MailMod/Options/MailLog/LogDeletedButton"]);
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:logSentMail:true#" .. L["CT_MailMod/Options/MailLog/LogSentCheckButton"]);

		optionsAddObject(-10,   16, "colorswatch#tl:15:%y#s:16:16#o:logColor:" .. defaultLogColor[1] .. "," .. defaultLogColor[2] .. "," .. defaultLogColor[3] .. "," .. defaultLogColor[4] .. "#true");
		optionsAddObject( 14,   15, "font#tl:40:%y#v:ChatFontNormal#" .. L["CT_MailMod/Options/MailLog/BackgroundLabel"]);

		optionsAddObject(-25,   17, "slider#t:0:%y#o:logWindowScale:1#s:175:%s#" .. L["CT_MailMod/Options/MailLog/ScaleSliderLabel"] .. "#0.20:2:0.01");

		optionsAddObject(-20, 1*13, "font#t:0:%y#s:0:%s#l:13:0#r#" .. L["CT_MailMod/Options/MailLog/Delete/Heading"] .. "#" .. textColor3 .. ":l");
		optionsAddObject(-10,   26, "checkbutton#tl:10:%y#o:resetLog#i:resetLog#" .. L["CT_MailMod/Options/MailLog/Delete/ConfirmationCheckButton"]);
		optionsBeginFrame(  -5,   30, "button#t:0:%y#s:120:%s#v:UIPanelButtonTemplate#i:deleteLogButton#" .. L["CT_MailMod/Options/MailLog/Delete/Button"]);
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
		
		-- Reset Options
		optionsBeginFrame(-20	, 0, "frame#tl:0:%y#br:tr:0:%b");
			optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#" .. L["CT_MailMod/Options/Reset/Heading"]);
			optionsAddObject( -5,   26, "checkbutton#tl:20:%y#o:resetAll#" .. L["CT_MailMod/Options/Reset/ResetAllCheckbox"]);
			optionsBeginFrame(  -5,   30, "button#t:0:%y#s:120:%s#v:UIPanelButtonTemplate#" .. L["CT_MailMod/Options/Reset/ResetButton"]);
				optionsAddScript("onclick", function(self)
					if (module:getOption("resetAll")) then
						local copyOfMailLog = {CT_MailModOptions["mailLog"]}
						CT_MailModOptions = {};
						CT_MailModOptions["mailLog"] = copyOfMailLog[1];
					else
						if (not CT_MailModOptions or not type(CT_MailModOptions) == "table") then
							CT_MailModOptions = {};
						else
							CT_MailModOptions[module:getCharKey()] = nil;
						end
					end
					ConsoleExec("RELOADUI");
				end);
			optionsEndFrame();
			optionsAddObject( -7, 2*15, "font#t:0:%y#s:0:%s#l#r#" .. L["CT_MailMod/Options/Reset/Line 1"] .. "#" .. textColor2);
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
		if (getoption("hideOpenCloseFeature") ~= nil) then
			-- converting to 8.2.5.5
			module:setOption("showCheckboxes", not getoption("hideOpenCloseFeature"), true, false);
			module:setOption("hideOpenCloseFeature", nil, true, false);
		end
		opt.showCheckboxes = getoption("showCheckboxes", true);
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
			
		elseif (optName == "showCheckboxes") then
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


module.externalDropDown_Initialize = function(useLibUIDropDownMenu)		-- useLibUIDropDownMenu used for compatibility with TitanPanel for arith's LibUIDropDownMenu
	info = { };
	info.text = "CT_MailMod";
	info.isTitle = 1;
	info.justifyH = "CENTER";
	info.notCheckable = 1;
	if (useLibUIDropDownMenu == "L_") then
		L_UIDropDownMenu_AddButton(info, L_UIDROPDOWNMENU_MENU_LEVEL); 	-- Compatiblity with TitanPanel for arith's LibUIDropDownMenu
	else
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL);
	end

	info = { };
	info.text = "Open options";
	info.notCheckable = 1;
	info.func = function()
		module:showModuleOptions(module.name);
	end
	if (useLibUIDropDownMenu == "L_") then
		L_UIDropDownMenu_AddButton(info, L_UIDROPDOWNMENU_MENU_LEVEL); 	-- Compatiblity with TitanPanel for arith's LibUIDropDownMenu
	else
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL);
	end
	
	info = { };
	info.text = "Open mail log";
	info.notCheckable = 1;
	info.func = module.showMailLog;
	if (useLibUIDropDownMenu == "L_") then
		L_UIDropDownMenu_AddButton(info, L_UIDROPDOWNMENU_MENU_LEVEL); 	-- Compatiblity with TitanPanel for arith's LibUIDropDownMenu
	else
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL);
	end
end