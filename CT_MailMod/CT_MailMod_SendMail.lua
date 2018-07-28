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
-- Alt Left Click to add item to Send Mail window

do
	local function CT_MailMod_AddToSendMail(self, button)
		if (button == "LeftButton" and IsAltKeyDown()) then
			if (MailFrame and SendMailFrame and MailFrame:IsShown()) then
				if (
					module.opt.sendmailAltClickItem and
					not CursorHasItem()
				) then
					if (not SendMailFrame:IsVisible()) then
						-- Switch to the send mail frame.
						MailFrameTab_OnClick(nil, 2);
					end
					-- Pickup and add an item to the send mail window.
					local bag, item = self:GetParent():GetID(), self:GetID();
					PickupContainerItem(bag, item);
					ClickSendMailItemButton();
					return true;
				end
			end
		end
		return false;
	end

	local function CT_MailMod_ContainerFrameItemButton_OnModifiedClick(self, button)
		CT_MailMod_AddToSendMail(self, button);
	end

	if (not CT_Core_ContainerFrameItemButton_OnModifiedClick) then
		hooksecurefunc("ContainerFrameItemButton_OnModifiedClick", CT_MailMod_ContainerFrameItemButton_OnModifiedClick);
	else
		CT_Core_ContainerFrameItemButton_OnModifiedClick_Register(CT_MailMod_AddToSendMail);
	end
end



--------------------------------------------
-- Fill in subject with money amount being entered.
do
	local amount3 = module:getText("SEND_MAIL_MONEY_SUBJECT_GOLD");
	local amount2 = module:getText("SEND_MAIL_MONEY_SUBJECT_SILVER");
	local amount1 = module:getText("SEND_MAIL_MONEY_SUBJECT_COPPER");
	local find3 = "^" .. amount3:gsub("%%d", "%%d+") .. "$";
	local find2 = "^" .. amount2:gsub("%%d", "%%d+") .. "$";
	local find1 = "^" .. amount1:gsub("%%d", "%%d+") .. "$";

	hooksecurefunc(SendMailMoney, "onValueChangedFunc", function ()
		if (not module.opt.sendmailMoneySubject) then
			return;
		end
		local gold, silver, copper;
		local subject = SendMailSubjectEditBox:GetText();
		if (subject == "" or subject:find(find3) or subject:find(find2) or subject:find(find3)) then
			copper = MoneyInputFrame_GetCopper(SendMailMoney);
			if (copper == 0) then
				SendMailSubjectEditBox:SetText("");
			else
				SendMailSubjectEditBox:SetText(module:convertMoneyToString(copper));
			end
		end
	end);
end

--------------------------------------------
-- Configure the auto-complete settings for the send to name edit box.

local setAutoComplete;
local function configureSendToNameAutoComplete()
	if (module:getOption("sendmailAutoCompleteUse")) then
		setAutoComplete = true;
		local include = AUTOCOMPLETE_FLAG_NONE;
		local exclude = AUTOCOMPLETE_FLAG_BNET;
		if (module:getOption("sendmailAutoCompleteFriends")) then
			include = bit.bor(include, AUTOCOMPLETE_FLAG_FRIEND);
		end
		if (module:getOption("sendmailAutoCompleteGuild")) then
			include = bit.bor(include, AUTOCOMPLETE_FLAG_IN_GUILD);
		end
		if (module:getOption("sendmailAutoCompleteInteracted")) then
			include = bit.bor(include, AUTOCOMPLETE_FLAG_INTERACTED_WITH);
		end
		if (module:getOption("sendmailAutoCompleteGroup")) then
			include = bit.bor(include, AUTOCOMPLETE_FLAG_IN_GROUP);
		end
		if (module:getOption("sendmailAutoCompleteOnline")) then
			include = bit.bor(include, AUTOCOMPLETE_FLAG_ONLINE);
		end
		if (module:getOption("sendmailAutoCompleteAccount")) then
			include = bit.bor(include, AUTO_COMPLETE_ACCOUNT_CHARACTER);
		end
		AutoCompleteEditBox_SetAutoCompleteSource(SendMailNameEditBox, GetAutoCompleteResults, include, exclude);
	else
		if (setAutoComplete) then
			AutoCompleteEditBox_SetAutoCompleteSource(SendMailNameEditBox, GetAutoCompleteResults, AUTOCOMPLETE_LIST.MAIL.include, AUTOCOMPLETE_LIST.MAIL.exclude);
			setAutoComplete = nil;
		end
	end
	CT_MailMod_UpdateFilterDropDown();
end
module.configureSendToNameAutoComplete = configureSendToNameAutoComplete;

