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
-- Utility Functions

function module:getTimeFromOffset(dayOffset)
	local seconds = math.floor(dayOffset*(24*3600)+0.5);
	local tbl = date("*t");
	tbl.sec = tbl.sec + seconds;
	return time(tbl);
end

function module:getPlayerName(name)
	name = name or UnitName("player");
	return ("%s @ %s"):format(name, GetRealmName());
end

function module:filterName(str)
	local name, realm = str:match("^(.-) @ (.+)$");
	if ( realm == GetRealmName() ) then
		return name;
	else
		return str;
	end
end

--------------------------------------------
-- Custom Events

do
	local events = { };
	
	function module:regCustomEvent(event, func)
		local tbl = events[event] or { };
		tinsert(tbl, func);
		events[event] = tbl;
	end
	
	function module:raiseCustomEvent(event, ...)
		local tbl = events[event];
		if ( tbl ) then
			for key, value in ipairs(tbl) do
				value(module, event, ...);
			end
		end
	end
end

--------------------------------------------
-- Block trades when mailbox is open

do
	local blockOption;
	local blockOriginal;
	local blockcvar = "blockTrades";

	local function restoreBlockState()
		-- Restore blocking to its original state, which could be disabled or enabled.
		if (blockOriginal) then
			SetCVar(blockcvar, blockOriginal);
			blockOriginal = nil;
		end
	end

	local function enableBlockState()
		-- Change blocking state to enabled.
		if (blockOriginal == nil) then
			-- Save the original blocking state before we change it.
			blockOriginal = GetCVar(blockcvar);
		end
		-- Blocking is now enabled.
		SetCVar(blockcvar, "1");
	end

	-- If leaving the world, or the window is being closed, then restore
	-- blocking to its original state.
	module:regEvent("PLAYER_LEAVING_WORLD", restoreBlockState);
	module:regEvent("MAIL_CLOSED", restoreBlockState);

	-- If the mailbox frame has just opened, and the user wants to block while
	-- at the mailbox, then start blocking.
	module:regEvent("MAIL_SHOW", function()
		if (blockOption) then
			enableBlockState();
		end
	end);

	-- Configure blocking option.
	module.configureBlockTradesMail = function(block)
		blockOption = block; -- Save the option's value in a local variable
		if (blockOption) then
			-- User wants to block trades while at this window.
			-- If the frame is currently shown, then start blocking.
			if ( (MailFrame and MailFrame:IsShown()) ) then
				enableBlockState();
			end
		else
			-- User does not want to block trades while at this window.
			-- If we are currently blocking trades (ie. if we have the original
			-- blocking state saved), then restore to the original blocking state.
			if (blockOriginal) then
				restoreBlockState();
			end
		end
	end
end

--------------------------------------------
-- Open/close bags

do
	-- Blizzard's code in MailFrame.lua...
	--   The backpack opens when the mail frame is shown.
	--   Clicking the mail frame's upper right close button does not close the backpack.
	--   Pressing ESC to close the mail frame does close the backpack.

	local function mailboxOpened()
		local openAllBags = module.opt.openAllBags;
		local openBackpack = module.opt.openBackpack;
		local openNoBags = module.opt.openNoBags;
		
		if (openAllBags or openBackpack or openNoBags) then
			-- First, close all bags.
			-- This also ensures that no bags are open when we call OpenAllBags()
			-- since that function will do nothing if at least one bag is already open.
			CloseAllBags();
			if (openBackpack) then
				-- Open just the backpack
				OpenBackpack();
			elseif (openAllBags) then
				-- Open all the bags
				OpenAllBags();
			end
		end
	end

	local function mailboxClosed()
		if (module.opt.closeAllBags) then
			-- Close all bags.
			CloseAllBags();
		end
	end

	module:regEvent("MAIL_SHOW", mailboxOpened);
	module:regEvent("MAIL_CLOSED", mailboxClosed);
end

--------------------------------------------
-- Convert money into a string.

function module:convertMoneyToString(copper)
	local amount3 = module.text["CT_MailMod/SEND_MAIL_MONEY_SUBJECT_GOLD"];
	local amount2 = module.text["CT_MailMod/SEND_MAIL_MONEY_SUBJECT_SILVER"];
	local amount1 = module.text["CT_MailMod/SEND_MAIL_MONEY_SUBJECT_COPPER"];
	local gold, silver, mult;
	if (copper < 0) then
		copper = -copper;
		mult = -1;
	else
		mult = 1;
	end
	gold = floor(copper / 10000);
	copper = copper - gold * 10000;
	silver = floor(copper / 100);
	copper = copper - silver * 100;
	if (gold > 0) then
		return amount3:format(mult * gold, mult * silver, mult * copper);
	elseif (silver > 0) then
		return amount2:format(mult * silver, mult * copper);
	else
		return amount1:format(mult * copper);
	end
end
