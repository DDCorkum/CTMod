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
-- Modified Stock UI for the Inbox

-- Move the icons 20 to the right of where Blizzard puts them.
do
	MailItem1:SetPoint("TOPLEFT", "InboxFrame", "TOPLEFT", 13 + 20, -70);
	local item;
	for i = 1, INBOXITEMS_TO_DISPLAY, 1 do
		item = _G["MailItem"..i];
		item:SetWidth(280);
		_G["MailItem" .. i .. "ExpireTime"]:SetPoint("TOPRIGHT", item, "TOPRIGHT", 10, -4);
	end
end

-- Some font strings
local fsNumSelected;
local fsInboxCount;
do
	-- Number of selected messages
	fsNumSelected = InboxFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
	fsNumSelected:SetText("");
	fsNumSelected:SetPoint("TOPLEFT", InboxFrame, "TOPLEFT", 65, -48);

	-- Number of messages in the inbox
	fsInboxCount = InboxFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
	fsInboxCount:SetText("");
	fsInboxCount:SetPoint("TOPLEFT", InboxFrame, "TOPLEFT", 65, -8);
end

-- Add the "Mailbox" button
do
	module:getFrame( {
		["button#n:CTMailModMailboxButton#s:90:15#l:tl:222:-11#v:UIPanelButtonTemplate#Mailbox: 51"] = {
			["onload"] = function(self)
				self:SetNormalFontObject("GameFontHighlightSmall");
				self:SetHighlightFontObject("GameFontHighlightSmall");
				self:SetDisabledFontObject("GameFontHighlightSmall");
			end,
			["onclick"] = function(self, arg1)
				if ( arg1 == "LeftButton" ) then
					if (not module.isProcessing) then
						module:closeOpenMail();
						local data = {actionType = "download"};
						module:addMailAction(data, module.actionDownloadMail);
						module:beginIncomingProcessing();
					end
				end
			end,
			["onenter"] = function(self)
				GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 5);
				GameTooltip:SetText(module:getText("MAILBOX_BUTTON_TIP1"));
				GameTooltip:Show();
			end,
			["onleave"] = function(self)
				GameTooltip:Hide();
			end
		},
	}, InboxFrame);

	function module:inboxUpdateMailboxCount()
		-- Update the button that shows the number of items still in the mailbox.
		-- (the number of items that have not been downloaded to the inbox).
		local button = CTMailModMailboxButton;
		if (not module.opt.inboxShowMailbox) then
			button:Hide();
			return;
		else
			button:Show();
		end
		local enable;
		local mailCount, totalCount = GetInboxNumItems();
		if (totalCount) then
			if (totalCount > mailCount) then
				if (not module.maxShownMails) then
					module.maxShownMails = mailCount;  -- Max is currently 50 (Nov 23 2009)
				end
				if (mailCount < module.maxShownMails) then
					enable = true;
				end
			end
			button:SetText(format(module:getText("MAILBOX_COUNT"), totalCount - mailCount));
		else
			button:SetText(format(module:getText("MAILBOX_COUNT"), 0));
		end
		if (button.mailmodEnable ~= nil) then
			enable = button.mailmodEnable;  -- Forced enable/disable
		end
		if (enable) then
			button:Enable();
		else
			button:Disable();
		end
	end

	local function customEvents_MailboxButton(self, event, data)
		local button = CTMailModMailboxButton;
		if (event == "INCOMING_UPDATE") then
			module:inboxUpdateMailboxCount();

		elseif (event == "INCOMING_START") then
			-- Disable everything
			button.mailmodEnable = false;
			button:Disable();

		elseif (event == "INCOMING_STOP") then
			-- Restore everything
			button.mailmodEnable = nil;
			module:inboxUpdateMailboxCount();
		end
	end
	module:regCustomEvent("INCOMING_UPDATE", customEvents_MailboxButton);
	module:regCustomEvent("INCOMING_START", customEvents_MailboxButton);
	module:regCustomEvent("INCOMING_STOP", customEvents_MailboxButton);
end

-- The "Open Selected" and "Return Selected" buttons
do
	module:getFrame( {
		["button#n:CTMailModOpenSelected#s:68:25#l:tl:143:-42#v:UIPanelButtonTemplate#OPEN_SELECTED"] = {
			["onclick"] = function(self, arg1)
				if ( arg1 == "LeftButton" ) then
					if (module.isProcessing) then
						module:cancelProcessing();
					else
						if (module:inboxGetNumSelected() == 0) then
							DEFAULT_CHAT_FRAME:AddMessage(module:getText("NOTHING_SELECTED"));
						else
							module:closeOpenMail();
							module:retrieveSelected();
						end
					end
				end
			end,
			["onenter"] = function(self)
				GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 30, -60);
				GameTooltip:SetText("Open selected messages");
				GameTooltip:Show();
			end,
			["onleave"] = function(self)
				GameTooltip:Hide();
			end
		},
		["button#n:CTMailModReturnSelected#s:68:25#l:tl:212:-42#v:UIPanelButtonTemplate#RETURN_SELECTED"] = {
			["onclick"] = function(self, arg1)
				if ( arg1 == "LeftButton" ) then
					if (module.isProcessing) then
						module:cancelProcessing();
					else
						if (module:inboxGetNumSelected() == 0) then
							DEFAULT_CHAT_FRAME:AddMessage(module:getText("NOTHING_SELECTED"));
						else
							module:closeOpenMail();
							module:returnSelected();
						end
					end
				end
			end,
			["onenter"] = function(self)
				GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 30, -60);
				GameTooltip:SetText("Return selected messages");
				GameTooltip:Show();
			end,
			["onleave"] = function(self)
				GameTooltip:Hide();
			end
		},
	}, InboxFrame);

	local function customEvents_OpenReturn(self, event, data)
		if (event == "INCOMING_START") then
			CTMailModOpenSelected:SetText(module:getText("STOP_SELECTED"));
			CTMailModOpenSelected:Enable();
			CTMailModReturnSelected:SetText(module:getText("STOP_SELECTED"));
			CTMailModReturnSelected:Enable();

		elseif (event == "INCOMING_STOP") then
			-- Restore everything
			CTMailModOpenSelected:SetText(module:getText("OPEN_SELECTED"));
			CTMailModOpenSelected:Enable();
			CTMailModReturnSelected:SetText(module:getText("RETURN_SELECTED"));
			CTMailModReturnSelected:Enable();
		end
	end
	module:regCustomEvent("INCOMING_START", customEvents_OpenReturn);
	module:regCustomEvent("INCOMING_STOP", customEvents_OpenReturn);
end

-- Select All checkbox, mail selection checkboxes, and mail numbers.
local checkboxes = { };
do
	local checkboxTbl;

	-- The Select All checkbox
	module:getFrame( {
		["checkbutton#n:CTMailModSelectAll#s:24:24#l:tl:59:-38#v:OptionsCheckButtonTemplate##1:0.82:0"] = {
			["onclick"] = function(self, arg1)
				if (self:GetChecked()) then
					module:inboxSelectAll();
					PlaySound(856);
				else
					module:inboxUnselectAll();
					PlaySound(857);
				end
				module:inboxUpdateSelection();
			end,
			["onload"] = function(self)
				self.text:SetText(module:getText("SELECT_ALL"));
				self.text:SetPoint("LEFT", self, "RIGHT", 1, 0);
				self:SetHitRectInsets(0, -55, 0, 0);
			end,
			["onenter"] = function(self)
				self.text:SetTextColor(1, 1, 1);
			end,
			["onleave"] = function(self)
				self.text:SetTextColor(1, 0.82, 0);
			end,
		},
	}, InboxFrame);

	local similarSubjects = {
		(gsub(AUCTION_EXPIRED_MAIL_SUBJECT, "%%s", ".*")),  -- "Auction expired: %s";
		(gsub(AUCTION_OUTBID_MAIL_SUBJECT, "%%s", ".*")),  -- "Outbid on %s";
		(gsub(AUCTION_REMOVED_MAIL_SUBJECT, "%%s", ".*")),  -- "Auction cancelled: %s";
		(gsub(AUCTION_SOLD_MAIL_SUBJECT, "%%s", ".*")),  -- "Auction successful: %s";
		(gsub(AUCTION_WON_MAIL_SUBJECT, "%%s", ".*")),  -- "Auction won: %s";
		(gsub(COD_PAYMENT, "%%s", ".*")),  -- "COD Payment: %s";
	};

	-- The message checkboxes
	local function checkboxOnClick(self, button)
		-- User clicked on a message checkbox.
		local offset = (InboxFrame.pageNum - 1) * INBOXITEMS_TO_DISPLAY;
		local mailIndex = offset + self:GetID();
		local mailCount = GetInboxNumItems();
		local status;

		if (mailIndex > mailCount) then
			status = false;
			module:inboxUnselectSingle(mailIndex);
			module.rangeStart = nil;

		elseif (IsAltKeyDown()) then
			-- Alt Left-Click to select all messages with same/similar subject
			-- Alt Right-Click to unselect all messages with same/similar subject
			local subject = select(4, GetInboxHeaderInfo(mailIndex));
			if (not subject) then
				subject = "";
			end
			-- Try to find a pattern
			local pattern;
			for i, v in ipairs(similarSubjects) do
				if (subject:find(v)) then
					pattern = v;
					break;
				end
			end
			local text;
			if (not pattern) then
				-- If there is a quantity at the end of the subject then extract all but the quantity.
				local name = subject:match("^(.*) %(%d*%)$");  -- "Frostweave Cloth (20)"
				-- text == subject without any quantity
				-- pattern == subject with quantity pattern
				if (name) then
					text = name;
				else
					text = subject;
				end
				pattern = "^" .. text .. " %(%d*%)$";
			end
			if (button == "LeftButton") then
				status = true;  -- Select
				if (module.opt.inboxSubjectNew) then
					module:inboxUnselectAll();
				end
			else
				status = false; -- Unselect
			end
			for i = 1, mailCount do
				local found;
				local subject = select(4, GetInboxHeaderInfo(i));
				if (not subject) then
					subject = "";
				end
				if (text) then
					found = (subject == text);
					if (not found) then
						found = subject:find(pattern);
					end
				else
					found = subject:find(pattern);
				end
				if (found) then
					if (status) then
						module:inboxSelectSingle(i);
					else
						module:inboxUnselectSingle(i);
					end
				end
			end
			module.rangeStart = nil;

		elseif (IsControlKeyDown()) then
			-- Ctrl Left-Click to select all messages from this sender.
			-- Ctrl Right-Click to unselect all messages from this sender.
			local sentfrom = select(3, GetInboxHeaderInfo(mailIndex));
			if (not sentfrom) then
				sendfrom = UNKNOWN;
			end
			if (button == "LeftButton") then
				status = true;  -- Select
				if (module.opt.inboxSenderNew) then
					module:inboxUnselectAll();
				end
			else
				status = false; -- Unselect
			end
			for i = 1, mailCount do
				local sender = select(3, GetInboxHeaderInfo(i));
				if (not sender) then
					sender = UNKNOWN;
				end
				if (sentfrom == sender) then
					if (status) then
						module:inboxSelectSingle(i);
					else
						module:inboxUnselectSingle(i);
					end
				end
			end
			module.rangeStart = nil;

		elseif (IsShiftKeyDown() and not module.rangeStart) then
			-- Shift Click the first message in the range.
			-- This should not change the checkbox's state, so
			-- we need to counter the effect of the user's click.
			if (self:GetChecked()) then
				self:SetChecked(false);
			else
				self:SetChecked(true);
			end
			module.rangeStart = mailIndex;

		elseif (IsShiftKeyDown() and module.rangeStart) then
			-- Shift Left-Click the last message in the range to select.
			-- Shift Right-Click the last message in the range to unselect.
			local first, last;
			if (module.rangeStart > mailCount) then
				module.rangeStart = mailCount;
			end
			if (module.rangeStart < mailIndex) then
				first = module.rangeStart;
				last = mailIndex;
			else
				first = mailIndex;
				last = module.rangeStart;
			end
			if (button == "LeftButton") then
				status = true;  -- Select
				if (module.opt.inboxRangeNew) then
					module:inboxUnselectAll();
				end
			else
				status = false; -- Unselect
			end
			for i = first, last do
				if (status) then
					module:inboxSelectSingle(i);
				else
					module:inboxUnselectSingle(i);
				end
			end
			module.rangeStart = nil;
		else
			-- Unmodified click of the checkbox.
			if (self:GetChecked()) then
				status = true;
				module:inboxSelectSingle(mailIndex);
			else
				status = false;
				module:inboxUnselectSingle(mailIndex);
			end
			module.rangeStart = nil;
		end

		if (status) then
			PlaySound(856);
		else
			PlaySound(857);
			module.selectAllMail = false;
		end

		module:inboxUpdateSelection();
	end

	local function checkboxFunc()
		if ( not checkboxTbl ) then
			checkboxTbl = {
				["onload"] = function(self)
					self:RegisterForClicks("LeftButtonUp", "RightButtonUp");
				end,
				["onclick"] = checkboxOnClick,
				["onenter"] = function(self)
					if (module.opt.toolSelectMsg) then
						GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT", 304, 42);
						GameTooltip:SetText(module:getText("SELECT_MESSAGE_TIP1"));
						GameTooltip:AddLine(module:getText("SELECT_MESSAGE_TIP2"), 1, 1, 0.5);
						GameTooltip:Show();
					end
				end,
				["onleave"] = function(self)
					GameTooltip:Hide();
				end
			};
		end
		return "checkbutton#s:24:24#r:l:1:-5#v:UICheckButtonTemplate", checkboxTbl;
	end

	for i = 1, INBOXITEMS_TO_DISPLAY, 1 do
		local mcb, fs;

		-- Create a message checkbox
		mcb = module:getFrame(checkboxFunc, _G["MailItem" .. i], "CT_MailMod_InboxSelect" .. i);
		mcb:SetID(i);
		checkboxes[i] = mcb;
		mcb.text:Hide();
		mcb:Hide();

		-- Create a message number (normal)
		fs = mcb:CreateFontString(nil, "ARTWORK", "ChatFontSmall");
		fs:SetPoint("BOTTOM", mcb, "TOP", 0, 0);
		mcb.textSmall = fs;

		-- Create a message number (when it is the start of a range)
		fs = mcb:CreateFontString(nil, "ARTWORK", "ChatFontNormal");
		fs:SetPoint("BOTTOM", mcb, "TOP", 0, 0);
		mcb.textNormal = fs;
	end

	function module:inboxUpdateSelection()
		-- Update the mail selection checkboxes, the select all checkbox, and the number of items selected.
		local offset = (InboxFrame.pageNum - 1) * INBOXITEMS_TO_DISPLAY;
		local mailCount, totalCount = GetInboxNumItems();
		if (not totalCount) then
			totalCount = mailCount;
		end
		local mailIndex;
		local showMessageNumbers = module.opt.inboxShowNumbers;
		for key, chbox in ipairs(checkboxes) do
			mailIndex = key + offset;
			if (mailIndex > mailCount) then
				-- Hide it
				module.selectedMail[mailIndex] = false;
				chbox:Hide();
			else
				-- Show the line
				if (showMessageNumbers) then
					-- Show message numbers above the mail checkboxes.
					chbox:ClearAllPoints();
					chbox:SetPoint("RIGHT", _G["MailItem" .. key], "LEFT", 1, -6);
					if (module.rangeStart and module.rangeStart == mailIndex) then
						-- Start of a selection range (use a different color and font size)
						chbox.textNormal:SetTextColor(1, 0.82, 0);
						chbox.textNormal:SetText(mailIndex);
						chbox.textSmall:Hide();
						chbox.textNormal:Show();
					else
						-- Not start of a selection range
						chbox.textSmall:SetTextColor(1, 1, 1);
						chbox.textSmall:SetText(mailIndex);
						chbox.textSmall:Show();
						chbox.textNormal:Hide();
					end
				else
					-- Don't show message numbers above the mail checkboxes
					chbox:ClearAllPoints();
					chbox:SetPoint("RIGHT", _G["MailItem" .. key], "LEFT", 1, 0);
					chbox.textSmall:Hide();
					chbox.textNormal:Hide();
				end
				chbox:Show();
			end
			-- Set or clear the check mark in the selection checkbox.
			if (module:inboxIsSelected(mailIndex)) then
				chbox:SetChecked(true);
			else
				chbox:SetChecked(false);
			end
		end
		-- Update the "Select All" checkbox.
		CTMailModSelectAll:SetChecked(module.selectAllMail);
		-- Show the number of mails that are currently selected in the inbox.
		fsNumSelected:SetText(format(module:getText("NUMBER_SELECTED"), module:inboxGetNumSelected()));
	end

	local function customEvents_MailCheckboxes(self, event, data)
		if (event == "INCOMING_UPDATE") then
			module:inboxUpdateSelection();

		elseif (event == "INCOMING_START") then
			-- Disable everything
			CTMailModSelectAll:Disable();
			for key, value in ipairs(checkboxes) do
				value:Disable();
			end

		elseif (event == "INCOMING_STOP") then
			-- Restore everything
			CTMailModSelectAll:Enable();
			for key, value in ipairs(checkboxes) do
				value:Enable();
			end
		end
	end
	module:regCustomEvent("INCOMING_UPDATE", customEvents_MailCheckboxes);
	module:regCustomEvent("INCOMING_START", customEvents_MailCheckboxes);
	module:regCustomEvent("INCOMING_STOP", customEvents_MailCheckboxes);
end

-- Quick action (expiry) buttons
local quickAction = { };
do
	local quickActionTbl;

	local function quickActionFunc()
		if ( not quickActionTbl ) then
			quickActionTbl = {
				["onclick"] = function(self, button)
					local offset = (InboxFrame.pageNum - 1) * INBOXITEMS_TO_DISPLAY;
					local mailIndex = offset + self:GetID();
					local action = self.ctmailmodAction;
					if (action == 1) then
						-- Return the message
						if (not module.isProcessing) then
							module:closeOpenMail();
							module:returnSingle(mailIndex);
						end
					elseif (action == 2) then
						-- Delete the message
						if (not module.isProcessing) then
							module:closeOpenMail();
							module:deleteSingle(mailIndex);
						end
					end
				end,
				["onenter"] = function(self)
					local action = self.ctmailmodAction;
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 16);
					if (action == 1) then
						GameTooltip:SetText(module:getText("QUICK_RETURN_TIP1"));
						GameTooltip:Show();
					elseif (action == 2) then
						GameTooltip:SetText(module:getText("QUICK_DELETE_TIP1"));
						GameTooltip:Show();
					end
				end,
				["onleave"] = function(self)
					GameTooltip:Hide();
				end
			};
		end

		return "button#s:28:28#tr:br:0:0", quickActionTbl;
	end

	for i = 1, INBOXITEMS_TO_DISPLAY, 1 do
		local btn;

		-- Expiry time buttons
		btn = module:getFrame(quickActionFunc, _G["MailItem" .. i .. "ExpireTime"], "CT_MailMod_InboxAction" .. i);
		btn:SetID(i);
		quickAction[i] = btn;
	end

	function module:inboxUpdateQuickAction()
		-- Update the quick action buttons in the inbox frame.
		local offset = (InboxFrame.pageNum - 1) * INBOXITEMS_TO_DISPLAY;
		local mailCount, totalCount = GetInboxNumItems();
		if (not totalCount) then
			totalCount = mailCount;
		end
		local mailIndex;
		local showQuickActions = module.opt.inboxShowExpiry;
		local quick;
		for key, chbox in ipairs(checkboxes) do
			mailIndex = key + offset;
			quick = quickAction[key];
			if (mailIndex > mailCount) then
				-- Hide the line
				quick:Hide();
			else
				-- Show the line
				local mailItem = _G["MailItem" .. key .. "Subject"];
				-- Quick action buttons
				if (showQuickActions) then
					mailItem:SetWidth(220);
					if (InboxItemCanDelete(mailIndex)) then
						-- Show the delete button below the expiry time.
						quick:SetHeight(26);
						quick:SetWidth(26);
						quick:SetPoint("TOPRIGHT", quick:GetParent(), "BOTTOMRIGHT", 3, 3);
						quick:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up");
						quick:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down");
						quick:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight");
						quick:Show();
						quick.ctmailmodAction = 2; -- delete
					else
						-- Show the return button below the expiry time.
						quick:SetHeight(20);
						quick:SetWidth(20);
						quick:SetPoint("TOPRIGHT", quick:GetParent(), "BOTTOMRIGHT", 0, 0);
						quick:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up");
						quick:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down");
						quick:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight");
						quick:Show();
						quick.ctmailmodAction = 1; -- return
					end
				else
					-- Don't show a quick action button below the expiry time
					mailItem:SetWidth(248);
					quick:Hide();
				end
			end
		end
	end

	local function customEvents_QuickAction(self, event, data)
		if (event == "INCOMING_UPDATE") then
			module:inboxUpdateQuickAction();

		elseif (event == "INCOMING_START") then
			-- Disable everything
			for key, value in ipairs(quickAction) do
				value:Disable();
			end

		elseif (event == "INCOMING_STOP") then
			-- Restore everything
			for key, value in ipairs(quickAction) do
				value:Enable();
			end
		end
	end
	module:regCustomEvent("INCOMING_UPDATE", customEvents_QuickAction);
	module:regCustomEvent("INCOMING_START", customEvents_QuickAction);
	module:regCustomEvent("INCOMING_STOP", customEvents_QuickAction);
end

-- Inbox frame update routines
do
	function module:inboxUpdateOther()
		-- Update other items in the inbox frame.
		local offset = (InboxFrame.pageNum - 1) * INBOXITEMS_TO_DISPLAY;
		local mailCount, totalCount = GetInboxNumItems();
		if (not totalCount) then
			totalCount = mailCount;
		end
		local mailIndex;
		local showTwoLineSubjects = module.opt.inboxShowLong;
		for key, chbox in ipairs(checkboxes) do
			mailIndex = key + offset;

			-- Show two-line or one-line subjects.
			local mailItem = _G["MailItem" .. key .. "Subject"];
			if (showTwoLineSubjects) then
				mailItem:SetHeight(36);
			else
				mailItem:SetHeight(18);
			end
		end
		-- Hide Blizzard's "too much" mail text at top of inbox.
		-- In WoW 3.3 they change this from a fontstring into a frame,
		-- but the name of the new frame is the same as the fontstring,
		-- and the name of the variable holding the text is also the same.
		InboxTooMuchMail:Hide();
		if (totalCount > mailCount) then
			-- User has more mail than the game will allow in the inbox.
			-- Display a message in the chat window once per mailbox open
			if (not module.tooMuchMail) then
				module.tooMuchMail = true;
				DEFAULT_CHAT_FRAME:AddMessage(gsub(INBOX_TOO_MUCH_MAIL, "\124n", " "));
			end
		end
		if (module.opt.inboxShowInbox) then
			-- Show the number of items that are in the inbox
			fsInboxCount:SetText(format(module:getText("INBOX_COUNT"), mailCount));
			fsInboxCount:Show();
		else
			fsInboxCount:Hide();
		end
	end

	local function inboxframe_update()
		-- Called after Blizzard's InboxFrame_Update() function.
		module:inboxUpdateOther();
		module:inboxUpdateSelection();
		module:inboxUpdateQuickAction();
		module:inboxUpdateMailboxCount();
	end
	hooksecurefunc("InboxFrame_Update", inboxframe_update);

	module:regCustomEvent("INCOMING_UPDATE", function(self, event)
		module:inboxUpdateOther();
	end);

	local function updatePendingMail()
		if (InboxFrame and InboxFrame:IsVisible()) then
			inboxframe_update();
		end
	end
	module:regEvent("UPDATE_PENDING_MAIL", updatePendingMail);

	function module:calculateInboxPage(mailIndex)
		-- Returns the page number in the inbox that the specified mail index appears on.
		return ceil(mailIndex / INBOXITEMS_TO_DISPLAY);
	end

	function module:gotoInboxPage(page)
		-- Displays the specified inbox page.
		InboxFrame.pageNum = page;
		InboxFrame_Update();
	end

	function module:gotoInboxMailPage(mailIndex)
		-- Displays the inbox page that the specified mail index appears on.
		local page = module:calculateInboxPage(mailIndex);
		module:gotoInboxPage(page);
	end
end

-- Add the mail log button
do
	local btn = CreateFrame("Button", nil, InboxFrame, "UIPanelButtonTemplate");

	btn:SetWidth(50);
	btn:SetHeight(25);
	btn:SetText(module:getText("MAIL_LOG"));
	btn:SetPoint("TOPLEFT", 282, -30);
	btn:SetScript("OnClick", function(...)
		module.toggleMailLog();
	end);
	btn:SetScript("OnEnter", function(...)
		GameTooltip:SetOwner(btn, "ANCHOR_TOPLEFT", 30, -60);
		GameTooltip:SetText("Open the CT_MailMod Log");
		GameTooltip:Show();
	end);
	btn:SetScript("OnLeave", function(...)
		GameTooltip:Hide();
	end);

	function module:updateMailLogButton()
		if (module.opt.hideLogButton) then
			btn:Hide();
		else
			btn:Show();
		end
	end
end

-- Mail icon buttons
do
	-- Blizzard calls InboxFrameItem_OnEnter() from the OnEnter and OnUpdate
	-- scripts.
	--
	-- The only thing Blizzard's code puts in the tooltip is the number of items,
	-- the amount of money, and the cod amount.  If your mouse was to remain over
	-- the mail icon button after shift-clicking it then it would update the
	-- tooltip as items/money was taken.
	--
	-- In our case, we are disabling the mail icon buttons once incoming processing
	-- begins. When the button is disabled the tooltip gets hidden, so calling the
	-- function from the OnUpdate script does us no good at that point.
	--
	-- We are going to disable each mail icon button's OnUpdate script to prevent
	-- it from calling our OnEnter function, since having it call it does nothing
	-- useful for us and uses up some resources.
	do
		local button;
		for i = 1, INBOXITEMS_TO_DISPLAY, 1 do
			button = _G["MailItem" .. i .. "Button"];
			button:SetScript("OnUpdate", function(...) end);
		end
	end

	-- Extra lines for mail icon button tooltip
	local function CT_MailMod_InboxFrameItem_OnEnter(self, ...)
		-- This is a post hook routine for Blizzard's InboxFrameItem_OnEnter
		-- function. Blizzard calls it during the OnEnter and OnUpdate scripts,
		-- however we've disabled the OnUpdate script since it does nothing
		-- useful for us.
		local mailIndex = self.index;
		local mail = module:loadMail(self.index);
		local showMulti = module.opt.toolMultipleItems;
		local gap;

		if (showMulti and mail.numItems > 1) then
			GameTooltip:AddLine(" ");
			for i = 1, ATTACHMENTS_MAX_RECEIVE do
				local name, itemID, itemTexture, count, quality, canUse = GetInboxItem(mailIndex, i);
				if (name) then
					local itemLink = GetInboxItemLink(mailIndex, i);
					if (not itemLink) then
						itemLink = "[" .. name .. "]";
					end
					if (count == 1) then
--						GameTooltip:AddLine(itemLink);
						GameTooltip:AddLine("|T" .. itemTexture .. ":0|t" .. itemLink)
					else
--						GameTooltip:AddLine(itemLink .. " x " .. count);
						GameTooltip:AddLine("|T" .. itemTexture .. ":0|t" .. itemLink .. " x " .. count)
					end
--					-- Note: GameTooltip:AddTexture() only supports 10 textures, so
--					-- if there are more than 10 items attached to the message
--					-- then the 11th, etc will not show a texture in the tooltip.
--					-- This can be overcome by using "|T" .. itemTexture .. ":0|t" in a call to GameTooltip:AddLine().
--					GameTooltip:AddTexture(itemTexture);
				end
			end
		end

		if (mail:canMassOpen()) then
			if (not gap) then
				GameTooltip:AddLine(" ");
				gap = true;
			end
			GameTooltip:AddLine(module:getText("MAIL_OPEN_CLICK"), 1, 1, 0.5);
		end

		if (mail:canMassReturn()) then
			if (not gap) then
				GameTooltip:AddLine(" ");
				gap = true;
			end
			GameTooltip:AddLine(module:getText("MAIL_RETURN_CLICK"), 1, 1, 0.5);
		end

		GameTooltip:Show();
	end
	hooksecurefunc("InboxFrameItem_OnEnter", CT_MailMod_InboxFrameItem_OnEnter);

	local function customEvents_MailIconButtons(self, event, data)
		if (event == "INCOMING_START") then
			-- Disable everything
			for i = 1, INBOXITEMS_TO_DISPLAY do
				_G["MailItem" .. i .. "Button"]:Disable();
			end

		elseif (event == "INCOMING_STOP") then
			-- Restore everything
			for i = 1, INBOXITEMS_TO_DISPLAY do
				_G["MailItem" .. i .. "Button"]:Enable();
			end
		end
	end
	module:regCustomEvent("INCOMING_START", customEvents_MailIconButtons);
	module:regCustomEvent("INCOMING_STOP", customEvents_MailIconButtons);
end

-- Scroll wheel
do
	local wheelHook;

	local function inboxOnMouseWheel(self, direction, ...)
		if (not module.opt.inboxMouseWheel) then
			return;
		end
		if (direction == 1) then
			if (InboxFrame.pageNum > 1) then
				InboxPrevPage();
			end
		else
			local lastPage = ceil(GetInboxNumItems() / INBOXITEMS_TO_DISPLAY);
			if (InboxFrame.pageNum < lastPage) then
				InboxNextPage();
			end
		end
	end

	module:regEvent("MAIL_SHOW", function()
		if (not wheelHook) then
			wheelHook = true;
			MailFrame:EnableMouseWheel(true);
			MailFrame:HookScript("OnMouseWheel", inboxOnMouseWheel);
		end
	end);
end

-- Right click the Prev/Next page buttons
do
	InboxPrevPageButton:ClearAllPoints();
	InboxPrevPageButton:SetPoint("CENTER", InboxFrame, "BOTTOMLEFT", 30, 110);

	InboxNextPageButton:ClearAllPoints();
	InboxNextPageButton:SetPoint("CENTER", InboxFrame, "BOTTOMLEFT", 305, 110);

	InboxNextPageButton:RegisterForClicks("LeftButtonUp", "RightButtonUp");
	InboxPrevPageButton:RegisterForClicks("LeftButtonUp", "RightButtonUp");

	local function inboxNextPage(self, button, ...)
		if (button == "RightButton" or IsShiftKeyDown()) then
			local lastPage = ceil(GetInboxNumItems() / INBOXITEMS_TO_DISPLAY);
			if (lastPage < 1) then
				lastPage = 1;
			end
			InboxFrame.pageNum = lastPage;
			InboxFrame_Update();
		end
	end
	InboxNextPageButton:HookScript("OnClick", inboxNextPage);

	local function inboxPrevPage(self, button, ...)
		if (button == "RightButton" or IsShiftKeyDown()) then
			InboxFrame.pageNum = 1;
			InboxFrame_Update();
		end
	end
	InboxPrevPageButton:HookScript("OnClick", inboxPrevPage);
end

-- Clicking upper left corner stack of mail icon will open CT_MailMod options window.
do
	local frame = CreateFrame("Button", nil, MailFrame);
	frame:SetHeight(58);
	frame:SetWidth(58);
	frame:SetPoint("TOPLEFT", MailFrame, "TOPLEFT", -7, 6);
	frame:Show();
	frame:RegisterForClicks("AnyUp")
	frame:SetScript("OnClick", function(self, button, ...)
		if button == "RightButton" then
			module.toggleMailLog();
		else
			module:showModuleOptions(module.name);
		end
	end);
	frame:SetScript("OnEnter", function(self, ...)
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 5);
		GameTooltip:SetText(module:getText("MAILBOX_OPTIONS_TIP1"), nil, nil, nil, nil, 1);
		GameTooltip:Show();
	end);
	frame:SetScript("OnLeave", function(self, ...)
		GameTooltip:Hide();
	end);
end

function InboxFrame_OnClick(self, index)
	-- This is a replacement for Blizzard's InboxFrame_OnClick function.
	--
	-- New lines of code are surrounded by, or ended with: -- *new*
	-- Modified lines of code are surrounded by, or ended with: -- *mod*
	-- *new*
	if ( IsAltKeyDown() or IsShiftKeyDown() ) then
		-- Retrieve the contents of this mail.
		if (not module.isProcessing) then
			module:closeOpenMail();
			module:retrieveSingle(self.index);
		end
		self:SetChecked(false);
		return;
	elseif ( IsControlKeyDown() ) then
		-- Return this mail.
		if (not module.isProcessing) then
			module:closeOpenMail();
			module:returnSingle(self.index);
		end
		self:SetChecked(false);
		return;
	end

	-- Show/Hide the OpenMailFrame.
	-- *new*
	if ( self:GetChecked() ) then
		InboxFrame.openMailID = index;
		OpenMailFrame.updateButtonPositions = true;
		OpenMail_Update();
		--OpenMailFrame:Show();
		ShowUIPanel(OpenMailFrame);
		OpenMailFrameInset:SetPoint("TOPLEFT", 4, -80);
		PlaySound(829);
		module:initOpenMail(); -- *new*
	else
		InboxFrame.openMailID = 0;
		HideUIPanel(OpenMailFrame);
	end
	InboxFrame_Update();
end

function InboxFrame_OnModifiedClick(self, index)
	-- This is a replacement for Blizzard's InboxFrame_OnModifiedClick function.
	--
	-- New lines of code are surrounded by, or ended with: -- *new*
	-- Modified lines of code are surrounded by, or ended with: -- *mod*
	-- *mod*
--	local _, _, _, _, _, cod = GetInboxHeaderInfo(index);
--	if ( cod <= 0 ) then
--		AutoLootMailItem(index);
--	end
	-- *mod*
	InboxFrame_OnClick(self, index);
end

function InboxGetMoreMail()
	-- This is a replacement for Blizzard's InboxGetMoreMail function
	-- that was added to MailFrame.lua in the WoW 3.3 patch.
	--
	-- In that patch they added a call to InboxGetMoreMail() in a couple
	-- of places: a) When a MAIL_SUCCESS event arrived, b) When the
	-- InboxNextPage() or InboxPrevPage() functions are called.
	--
	-- This replacement function does nothing when called. This prevents
	-- CheckInbox() from getting called at times that we would rather
	-- it not be.
end

-- Send Mail Auto-Complete Filters

local sendmailframe;
local filterdropdown;

function CT_MailMod_UpdateFilterDropDown()
	if (module:getOption("sendmailAutoCompleteUse")) then
		filterdropdown:Show();
	else
		filterdropdown:Hide();
	end

end

do
	sendmailframe = module:getFrame("multidropdown#s:1:40#tl:182:-32#n:CT_MailModDropdown_autoCompleteFilters#o:autoCompleteFilters:1#Online and/or nearby toons#sendmailAutoCompleteOnline#Friends list (including offline)#sendmailAutoCompleteFriends#Guild list (including offline)#sendmailAutoCompleteGuild#Current Group#sendmailAutoCompleteGroup#Recently Interacted#sendmailAutoCompleteInteracted#Own toons on this account#sendmailAutoCompleteAccount",SendMailFrame);
	filterdropdown = select(#(sendmailframe:GetChildren())-1, sendmailframe:GetChildren());
	filterdropdown:SetScript("OnEnter", function(...)
		GameTooltip:SetOwner(filterdropdown, "ANCHOR_TOPLEFT", 35, 10);
		GameTooltip:SetText("Select down-arrow to change filters");
		GameTooltip:Show();
	end);
	filterdropdown:SetScript("OnLeave", function(...)
		GameTooltip:Hide();
	end);
	SendMailNameEditBox:SetScript("OnEnter", function(...)
		if (module:getOption("sendmailAutoCompleteUse")) then
			GameTooltip:SetOwner(filterdropdown, "ANCHOR_TOPLEFT", 35, 10);
			GameTooltip:SetText("Select down-arrow to change filters");
			GameTooltip:Show();
		end
	end);
	SendMailNameEditBox:SetScript("OnLeave", function(...)
		GameTooltip:Hide();
	end);
end


