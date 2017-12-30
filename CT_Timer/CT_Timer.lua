------------------------------------------------
--                  CT_Timer                  --
--                                            --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
------------------------------------------------

--------------------------------------------
-- Initialization

local module = { };
local _G = getfenv(0);

local MODULE_NAME = "CT_Timer";
local MODULE_VERSION = strmatch(GetAddOnMetadata(MODULE_NAME, "version"), "^([%d.]+)");

module.name = MODULE_NAME;
module.version = MODULE_VERSION;
-- module.frame = "CT_TimerFrame";
-- module.external = true;

_G[MODULE_NAME] = module;
CT_Library:registerModule(module);

--------------------------------------------

local opts = {};

-- CT_TimerData
-- .alpha
-- .alphaUpdate
-- .alphaWait
-- .color -- table of colors (3 values)
-- .countfrom -- descriptive text version of .time (eg. "3 minutes")
-- .status -- nil == stopped, 0 == paused, 1 == counting
-- .step -- 1 == count up by 1 second, -1 == count down by 1 second
-- .time -- number of seconds shown on the display

-- Clear old data values if still present
CT_Timer.alpha = nil;
CT_Timer.alphaUpdate = nil;
CT_Timer.alphaWait = nil;
CT_Timer.color = nil;
CT_Timer.countfrom = nil;
CT_Timer.hideBG = nil;
CT_Timer.position = nil;
CT_Timer.show = nil;
CT_Timer.showsecs = nil;
CT_Timer.status = nil;
CT_Timer.step = nil;
CT_Timer.time = nil;

--------------------------------------------

-- Does not get called if the timer is paused or stopped.
-- The function is called with two parameters:

-- First parameter (integer): The time remaining (if counting down)/time elapsed(if counting up), both in seconds.
-- Second parameter (integer): Whether the timer is counting up or down (1 for up, -1 for down).

CT_Timer_CallFunctions = { };
-- Global variable. Add your function to the list to get it called every time the timer counts 1 second (works both counting up and counting down).
-- You can add the function using "tinsert(CT_Timer_CallFunctions, functionName);"

--------------------------------------------

function CT_Timer_OnMouseOver()
	CT_TimerFrameDragClickFrame.step = 0.05;
end

function CT_Timer_OnMouseOut()
	CT_TimerFrameDragClickFrame.step = -0.05;
end

function CT_Timer_Toggle(frame)
	if ( CT_TimerData.status and CT_TimerData.status == 1 ) then
		CT_TimerData.status = 0;
		_G[frame:GetName() .. "Time"]:SetTextColor(1, 0.5, 0);
		CT_TimerData.color = { 1, 0.5, 0 };
	else
		if ( not CT_TimerData.status ) then
			if ( CT_TimerData.time > 0 ) then
				CT_TimerData.countfrom = CT_Timer_GetTimeString(CT_TimerData.time);
				CT_TimerData.step = -1;
			else
				CT_TimerData.step = 1;
			end
		end
		_G[frame:GetName() .. "Time"]:SetTextColor(0, 1, 0);
		CT_TimerData.color = { 0, 1, 0 };
		CT_TimerData.status = 1;
	end
end

function CT_Timer_UpdateTime(self, elapsed)
	if ( opts.hideBG ) then
		CT_TimerData.alphaUpdate = ( CT_TimerData.alphaUpdate or 0 ) + elapsed;
		if ( CT_TimerData.alphaUpdate > 0.05 ) then
			if ( ( not CT_TimerData.alphaWait or CT_TimerData.alphaWait < 1 ) and ( CT_TimerFrameDragClickFrame.step or 0 ) > 0 ) then
				CT_TimerData.alphaWait = ( CT_TimerData.alphaWait or 0 ) + elapsed;
				CT_TimerFrameHeaderTexture:SetAlpha(0);
				CT_TimerFrameScrollDownHour:SetAlpha(0);
				CT_TimerFrameScrollDownMin:SetAlpha(0);
				CT_TimerFrameScrollUpHour:SetAlpha(0);
				CT_TimerFrameScrollUpMin:SetAlpha(0);
			else
				CT_TimerData.alpha = ( CT_TimerData.alpha or 0 ) + ( CT_TimerFrameDragClickFrame.step or 0 );
				if ( CT_TimerData.alpha < 0 ) then
					CT_TimerData.alpha = 0;
					CT_TimerData.alphaWait = nil;
				elseif ( CT_TimerData.alpha > 1 ) then
					CT_TimerData.alpha = 1;
				end
				CT_TimerFrameHeaderTexture:SetAlpha(CT_TimerData.alpha);
				CT_TimerFrameScrollDownHour:SetAlpha(CT_TimerData.alpha);
				CT_TimerFrameScrollDownMin:SetAlpha(CT_TimerData.alpha);
				CT_TimerFrameScrollUpHour:SetAlpha(CT_TimerData.alpha);
				CT_TimerFrameScrollUpMin:SetAlpha(CT_TimerData.alpha);
			end
		end
	else
		CT_TimerData.alpha = nil;
		CT_TimerData.alphaWait = nil;
		CT_TimerData.alphaUpdate = nil;
		CT_TimerFrameHeaderTexture:SetAlpha(1);
		CT_TimerFrameScrollDownHour:SetAlpha(1);
		CT_TimerFrameScrollDownMin:SetAlpha(1);
		CT_TimerFrameScrollUpHour:SetAlpha(1);
		CT_TimerFrameScrollUpMin:SetAlpha(1);
	end
	if ( not CT_TimerData.status or CT_TimerData.status == 0 ) then
		if ( CT_TimerData.color ) then
			CT_TimerFrameTime:SetTextColor(CT_TimerData.color[1], CT_TimerData.color[2], CT_TimerData.color[3]);
		end
		return;
	end
	CT_TimerFrame.update = ( CT_TimerFrame.update or 0 ) + elapsed;
	if ( CT_TimerFrame.update >= 1 ) then
		if ( CT_TimerData.color ) then
			CT_TimerFrameTime:SetTextColor(CT_TimerData.color[1], CT_TimerData.color[2], CT_TimerData.color[3]);
		end
		CT_TimerData.time = CT_TimerData.time + CT_TimerData.step;

		-- Process call list
		for k, v in pairs(CT_Timer_CallFunctions) do
			if ( type(v) == "function" ) then
				v(CT_TimerData.time, CT_TimerData.step);
			end
		end

		if ( CT_TimerData.time == 0 ) then
			DEFAULT_CHAT_FRAME:AddMessage(format(CT_TIMER_FINISHCOUNT, CT_TimerData.countfrom), 1, 0.5, 0);
			PlaySound(3081);
			CT_Timer_Reset();
		else
			CT_Timer_SetTime(CT_TimerData.time, CT_TimerFrame);
		end
		CT_TimerFrame.update = CT_TimerFrame.update - 1;
	end
end

function CT_Timer_Start(seconds)
	CT_TimerData.status = 1;
	if ( seconds ) then
		CT_TimerData.step = -1;
		CT_TimerData.countfrom = CT_Timer_GetTimeString(seconds);
	else
		CT_TimerData.step = 1;
	end
	if ( seconds ) then
		CT_TimerData.time = seconds;
	else
		CT_TimerData.time = 0;
	end
	CT_TimerFrameTime:SetTextColor(0, 1, 0);
	CT_TimerData.color = { 0, 1, 0 };
end

function CT_Timer_Pause(newStatus)
	if ( not newStatus and ( not CT_TimerData.status or CT_TimerData.status == 0 ) ) then
		newStatus = 1;
	elseif ( newStatus and newStatus ~= 0 and newStatus ~= 1 ) then
		newStatus = nil;
	end

	if ( newStatus ) then
		if ( not CT_TimerData.status ) then
			if ( CT_TimerData.time > 0 ) then
				CT_TimerData.countfrom = CT_Timer_GetTimeString(CT_TimerData.time);
				CT_TimerData.step = -1;
			else
				CT_TimerData.step = 1;
			end
		end
		CT_TimerData.status = 1;
		CT_TimerFrameTime:SetTextColor(0, 1, 0);
		CT_TimerData.color = { 0, 1, 0 };
	else
		CT_TimerData.status = 0;
		CT_TimerFrameTime:SetTextColor(1, 0.5, 0);
		CT_TimerData.color = { 1, 0.5, 0 };
	end
end

function CT_Timer_SetTime(num, field)
	if ( not num ) then
		return;
	end

	local hours, mins, secs, temp;

	if ( num >= 3600 ) then
		hours = floor(num / 3600);
		temp = num - (hours*3600);
		mins = floor(temp / 60);
		secs = temp - (mins*60);
	elseif ( num >= 60 ) then
		hours = 0;
		mins = floor(num / 60);
		secs = num - (mins*60);
	else
		hours = 0;
		mins = 0;
		secs = num;
	end
	if ( not opts.showSeconds ) then
		_G[field:GetName() .. "Time"]:SetText(CT_Timer_AddZeros(hours) .. ":" .. CT_Timer_AddZeros(mins));
	else
		_G[field:GetName() .. "Time"]:SetText(CT_Timer_AddZeros(hours) .. ":" .. CT_Timer_AddZeros(mins) .. ":" .. CT_Timer_AddZeros(secs));
	end
	if ( CT_TimerData.time < 60 ) then
		CT_TimerFrameScrollDownMin:Disable();
		CT_TimerFrameScrollDownHour:Disable();
	elseif ( CT_TimerData.time < 3600 ) then
		CT_TimerFrameScrollDownHour:Disable();
		CT_TimerFrameScrollDownMin:Enable();
	else
		CT_TimerFrameScrollDownMin:Enable();
		CT_TimerFrameScrollDownHour:Enable();
	end
end

function CT_Timer_GetTimeString(num)

	local hours, mins, secs;

	if ( num >= 3600 ) then
		hours = floor(num / 3600);
		mins = floor(mod(num, 3600) / 60);
	else
		hours = 0;
		mins = floor(num / 60);
	end

	if ( hours == 0 ) then
		if ( mins == 1 ) then
			return "1 " .. CT_TIMER_MIN;
		else
			return mins .. " " .. CT_TIMER_MINS;
		end
	else
		local str;
		if ( hours == 1 ) then
			str = "1 " .. CT_TIMER_HOUR;
		else
			str = hours .. " " .. CT_TIMER_HOURS;
		end
		if ( mins == 0 ) then
			return str;
		elseif ( mins == 1 ) then
			return str .. " and 1 " .. CT_TIMER_MIN;
		else
			return str .. " and " .. mins .. CT_TIMER_MINS;
		end
	end
end

function CT_Timer_AddZeros(num)
	if ( strlen(num) == 1 ) then
		return "0" .. num;
	elseif ( strlen(num) == 2 ) then
		return num;
	else
		return "--";
	end
end

function CT_Timer_ModTime(self, num)
	CT_TimerData.time = CT_TimerData.time + num;
	if ( CT_TimerData.time < 0 ) then
		CT_TimerData.time = 0;
	end
	CT_Timer_SetTime(CT_TimerData.time, self:GetParent());
end

function CT_Timer_SetTimerTime(num)
	if ( num < 0 ) then
		num = 0;
	end
	CT_TimerData.time = num;
	CT_Timer_SetTime(CT_TimerData.time, CT_TimerFrame);
end

function CT_Timer_Reset()
	CT_TimerFrameTime:SetTextColor(1, 0, 0);
	CT_TimerData.color = { 1, 0, 0 };
	CT_TimerData.status = nil;
	CT_TimerData.time = 0;
	CT_TimerData.countfrom = nil;
	CT_Timer_SetTime(CT_TimerData.time, CT_TimerFrame);
end

--------------------------------------------

SlashCmdList["TIMER"] = function(msg)
	msg = strlower(msg);

	if ( msg == "" ) then
		DEFAULT_CHAT_FRAME:AddMessage("<CTMod> " .. CT_TIMER_HELP[1], 1, 1, 0);
		DEFAULT_CHAT_FRAME:AddMessage("<CTMod> " .. CT_TIMER_HELP[2], 1, 1, 0);
		DEFAULT_CHAT_FRAME:AddMessage("<CTMod> " .. CT_TIMER_HELP[3], 1, 1, 0);
		DEFAULT_CHAT_FRAME:AddMessage("<CTMod> " .. CT_TIMER_HELP[4], 1, 1, 0);
		DEFAULT_CHAT_FRAME:AddMessage("<CTMod> " .. CT_TIMER_HELP[5], 1, 1, 0);
		DEFAULT_CHAT_FRAME:AddMessage("<CTMod> " .. CT_TIMER_HELP[6], 1, 1, 0);
		DEFAULT_CHAT_FRAME:AddMessage("<CTMod> " .. CT_TIMER_HELP[7], 1, 1, 0);
		DEFAULT_CHAT_FRAME:AddMessage("<CTMod> " .. CT_TIMER_HELP[8], 1, 1, 0);
		DEFAULT_CHAT_FRAME:AddMessage("<CTMod> " .. CT_TIMER_HELP[9], 1, 1, 0);
		DEFAULT_CHAT_FRAME:AddMessage("<CTMod> " .. CT_TIMER_HELP[10], 1, 1, 0);

	elseif ( msg == "show" ) then
		DEFAULT_CHAT_FRAME:AddMessage("<CTMod> " .. CT_TIMER_SHOW_ON, 1, 1, 0);
		CT_TimerFrame:Show();
		opts.showTimer = 1;

	elseif ( msg == "hide" ) then
		DEFAULT_CHAT_FRAME:AddMessage("<CTMod> " .. CT_TIMER_SHOW_OFF, 1, 1, 0);
		CT_TimerFrame:Hide();
		opts.showTimer = nil;
		CT_Timer_ShowTimer = 0;

	elseif ( msg == "secs on" ) then
		opts.showSeconds = 1;
		DEFAULT_CHAT_FRAME:AddMessage("<CTMod> " .. CT_TIMER_SHOWSECS_ON, 1, 1, 0);
		CT_Timer_SetTime(CT_TimerData.time, CT_TimerFrame);

	elseif ( msg == "secs off" ) then
		opts.showSeconds = nil;
		DEFAULT_CHAT_FRAME:AddMessage("<CTMod> " .. CT_TIMER_SHOWSECS_OFF, 1, 1, 0);
		CT_Timer_SetTime(CT_TimerData.time, CT_TimerFrame);

	elseif ( msg == "start" ) then
		CT_Timer_Start();

	elseif ( msg == "stop" ) then
		CT_Timer_Pause();

	elseif ( msg == "reset" ) then
		CT_Timer_Reset();

	elseif ( msg == "bg on" ) then
		opts.hideBG = nil;
		CT_TimerData.alphaUpdate = 5; -- Force redraw

	elseif ( msg == "bg off" ) then
		opts.hideBG = 1;
		CT_TimerData.alphaUpdate = 5; -- Force redraw

	elseif ( string.find(msg, "^%d+$") ) then
		local _, _, mins = string.find(msg, "^(%d+)$");
		CT_Timer_Start(tonumber(mins)*60);

	elseif ( string.find(msg, "^%d+:%d+$") ) then
		local _, _, mins, sec = string.find(msg, "^(%d+):(%d+)$");
		CT_Timer_Start(tonumber(mins)*60+tonumber(sec));

	elseif ( msg == "options" ) then
		module:showModuleOptions(module.name);
	else

		SlashCmdList["TIMER"]("");
	end
end

SLASH_TIMER1 = "/timer";
SLASH_TIMER2 = "/tr";

--------------------------------------------

function CT_Timer_SavePosition()
	-- Save the position of the frame.

	-- Save the anchor point values.
	local anchorPoint, anchorTo, relativePoint, xoffset, yoffset = CT_TimerFrame:GetPoint(1);
	if (anchorTo) then
		anchorTo = anchorTo:GetName();
	end

	local pos = { anchorPoint, anchorTo, relativePoint, xoffset, yoffset };
	module:setOption("position", pos, true);
end

function CT_Timer_RestorePosition()
	-- Restore the position of the frame.
	-- If there is no saved position, then center the frame.

	-- Get saved position
	local pos = module:getOption("position");

	-- Set the frame's position
	CT_TimerFrame:ClearAllPoints();
	if (pos) then
		-- Restore to the saved position.
		CT_TimerFrame:SetPoint(pos[1], pos[2], pos[3], pos[4], pos[5]);
	else
		-- Center the frame on screen.
		CT_TimerFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
	end

	-- Save the frame's position
	CT_Timer_SavePosition();
end

function CT_Timer_ResetPosition()
	-- Reset position of the frame to the center of the screen.

	-- Center the frame on screen.
	CT_TimerFrame:ClearAllPoints();
	CT_TimerFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0);

	-- Save the frame's position
	CT_Timer_SavePosition();
end

--------------------------------------------

function CT_TimerFrame_OnLoad(self)
	self:RegisterEvent("PLAYER_LOGIN");
end

function CT_TimerFrame_OnEvent(self, event)
	if ( event == "PLAYER_LOGIN" ) then
		CT_Timer_RestorePosition();
	end
end

--------------------------------------------
-- Options frame

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

module.frame = function()
	local textColor1 = "0.9:0.9:0.9";
	local textColor2 = "0.7:0.7:0.7";
	local textColor3 = "0.9:0.72:0.0";
	local offset;
	local temp;

	optionsInit();

	-- Tips
	optionsBeginFrame(-5, 0, "frame#tl:0:%y#r");
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#Tips");
		optionsAddObject( -2, 2*14, "font#t:0:%y#s:0:%s#l:13:0#r#You can use /cttimer to open this options window directly.#" .. textColor2 .. ":l");
		optionsAddObject( -2, 2*14, "font#t:0:%y#s:0:%s#l:13:0#r#You can use /tr, or /timer, to display a list of commands in the chat window.#" .. textColor2 .. ":l");

	optionsEndFrame();

	-- General Options
	optionsBeginFrame(-20, 0, "frame#tl:0:%y#r");
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#General");

		optionsAddObject( -5,   26, "checkbutton#tl:30:%y#o:showTimer#Show timer");
		optionsAddObject(  6,   26, "checkbutton#tl:30:%y#o:showSeconds#Show seconds");
		optionsAddObject(  6,   26, "checkbutton#tl:30:%y#o:hideBG#Hide background");

		optionsBeginFrame( -5,   30, "button#t:0:%y#s:180:%s#n:CT_Timer_ResetPosition_Button#v:GameMenuButtonTemplate#Reset window position");
			optionsAddScript("onclick",
				function(self)
					CT_Timer_ResetPosition();
				end
			);
		optionsEndFrame();
		optionsAddObject( -5, 2*13, "font#t:0:%y#s:0:%s#l#r#This will place the window at\nthe center of the screen.#" .. textColor2);
	optionsEndFrame();

	optionsBeginFrame(-25, 0, "frame#tl:0:%y#br:tr:0:%b");
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#Reset Options");
		optionsAddObject( -5,   26, "checkbutton#tl:20:%y#o:resetAll#Reset options for all of your characters");
		optionsBeginFrame(  -5,   30, "button#t:0:%y#s:120:%s#v:UIPanelButtonTemplate#Reset options");
			optionsAddScript("onclick", function(self)
				if (module:getOption("resetAll")) then
					CT_TimerOptions = {};
				else
					if (not CT_TimerOptions or not type(CT_TimerOptions) == "table") then
						CT_TimerOptions = {};
					else
						CT_TimerOptions[module:getCharKey()] = nil;
					end
				end
				ConsoleExec("RELOADUI");
			end);
		optionsEndFrame();
		optionsAddObject( -7, 2*15, "font#t:0:%y#s:0:%s#l#r#Note: Resetting the options to their default values will reload your UI.#" .. textColor2);
	optionsEndFrame();

	-- Slash command details
	optionsBeginFrame(-20, 0, "frame#tl:0:%y#br:tr:0:%b");
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#Commands");
		for i, text in ipairs(CT_TIMER_HELP) do
			optionsAddObject( -2, 3*14, "font#t:0:%y#s:0:%s#l:13:0#r#" .. text .. "#" .. textColor2 .. ":l");
		end
	optionsEndFrame();

	return "frame#all", optionsGetData();
end

local function optShowTimer(value)
	opts.showTimer = value;
	if (not value) then
		CT_TimerFrame:Hide();
	else
		CT_TimerFrame:Show();
	end
end

local function optShowSeconds(value)
	opts.showSeconds = value;
	CT_Timer_SetTime(CT_TimerData.time, CT_TimerFrame);
end

local function optHideBG(value)
	opts.hideBG = value;
	CT_TimerData.alphaUpdate = 5; -- Force redraw
end

local function optsInit(value)
	CT_TimerData = module:getOption("timerData");
	if (not CT_TimerData) then
		CT_TimerData = {};
		module:setOption("timerData", CT_TimerData, true);
	end

	optShowTimer( module:getOption("showTimer") );
	optShowSeconds( module:getOption("showSeconds") );
	optHideBG( module:getOption("hideBG") );

	CT_TimerData.step = CT_TimerData.step or 1;
	CT_TimerData.time = CT_TimerData.time or 0;
	-- CT_TimerData.status = nil;
	CT_Timer_SetTime(CT_TimerData.time, CT_TimerFrame);

	CT_TimerData.color = CT_TimerData.color or { 1, 0, 0 };
	CT_TimerFrameTime:SetTextColor(CT_TimerData.color[1], CT_TimerData.color[2], CT_TimerData.color[3]);

	CT_TimerGlobalFrame:Show();
end

module.optionUpdate = function(self, optName, value)
	if (optName == "init") then
		optsInit(value);

	elseif (optName == "showTimer") then
		optShowTimer(value);

	elseif (optName == "showSeconds") then
		optShowSeconds(value);

	elseif (optName == "hideBG") then
		optHideBG(value);
	end
end

-- Function to update an option.
module.update = function(self, optName, value)
	module.optionUpdate(self, optName, value);
end

local function slashCommand(msg)
	module:showModuleOptions(module.name);
end

module:setSlashCmd(slashCommand, "/cttimer");
