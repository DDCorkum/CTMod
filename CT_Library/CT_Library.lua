------------------------------------------------
--                 CT_Library                 --
--                                            --
-- A shared library for all CTMod addons to   --
-- simplify simple, yet time consuming tasks  --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
--                                            --
-- Original credits to Cide and TS (Vanilla)  --
-- Maintained by Resike from 2014 to 2017     --
-- Maintained by Dahk Celes since 2018        --
--                                            --
-- This file contains the overall CTMod       --
-- structure used by all modules, and several --
-- helper functions to simplify coding        --
------------------------------------------------

-----------------------------------------------
-- Initialization
local LIBRARY_NAME, lib = ...;
local LIBRARY_VERSION = strmatch(GetAddOnMetadata(LIBRARY_NAME, "version"), "^([%d.]+)");

-- Create tables for all the PROTECTED contents and PUBLIC interface of CTMod


local libPublic = {}		-- Public attributes and methods that any AddOn, including CT modules, may access at time by calling _G["CT_Library"] or via the special table module.publicInterface that is created by CT_Library(RegisterModule.module)
				-- By contrast, "lib" contains any Protected attributes and methods that any CT module may access by calling CT_Library:RegisterModule(module) with its own table as a parameter

-- Associate lib and libPublic, so that code written for the protected lib can also access the public libPublic without being aware of the difference
setmetatable(lib, { __index = libPublic });

-- Publicly expose the public interface
_G[LIBRARY_NAME] = libPublic;

-- Private attributes
local modules = {};		-- Contains two references to each installed module: by number and by name.  See lib:iterateModules() and lib:getModule(name)
local movables, frame, eventTable;
local timerRepeatingFuncs, timerFuncs = {}, {};
local numSlashCmds, localizations, tableList;
local defaultDisplayValues = {}
local frameCache;

-- Set the variables used
lib.name = LIBRARY_NAME;
lib.version = LIBRARY_VERSION;

-- see localization.lua
local L;
do
	lib.text = lib.text or { };
	L = lib.text
	local metatable = getmetatable(L) or {}
	metatable.__index = function(table, missingKey)
		return "[Not Found: " .. gsub(missingKey, "CT_Library/", "") .. "]";
	end
	setmetatable(L, metatable);
end

-- End Initialization
-----------------------------------------------


-----------------------------------------------
-- Local Copies

local ChatFrame1 = ChatFrame1;

local bit = bit;
local floor = floor;
local format = format;
local gsub = gsub;
local ipairs = ipairs;
local match = string.match;
local math = math;
local maxn = table.maxn;
local min = min;
local pairs = pairs;
local print = print;
local select = select;
local setmetatable = setmetatable;
local sort = sort;
local string = string;
local strlen = strlen;
local strlower = strlower;
local strmatch = strmatch;
local strsub = strsub;
local strupper = strupper;
local tinsert = tinsert;
local tonumber = tonumber;
local tostring = tostring;
local tremove = tremove;
local type = type;
local unpack = unpack;

-- For spell database
local getNumSpellTabs = GetNumSpellTabs;
local getSpellTabInfo = GetSpellTabInfo;
local getSpellName = GetSpellBookItemName;


-- End Local Copies
-----------------------------------------------

-----------------------------------------------
-- Generic Functions

-- Return's the library's version, as a number with the main version before the decimal and subversions as fractions (usually tenths and thousandths, but not guaranteed)
function libPublic:getLibVersion()
	return LIBRARY_VERSION;
end

local function printText(frame, r, g, b, text)
	frame:AddMessage(text, r, g, b);
end

-- Local function to print text with a given color
local function getPrintText(...)
	local str = "";
	local num = select("#", ...);
	for i = 1, num, 1 do
		str = str .. tostring(select(i, ...)) .. ( (i < num and "  " ) or "" );
	end
	return str;
end

function lib:iterateModules()
	return ipairs(modules);
end

function lib:getModule(name)
	return modules[name]
end

-- Clears a table
local emptyMeta = { };
function lib:clearTable(tbl, clearMeta)
	for key, value in pairs(tbl) do
		tbl[key] = nil;
	end

	if ( clearMeta ) then
		setmetatable(tbl, emptyMeta);
	end
end

-- Returns the game version as a number.  If the arguments are true, appends the major patch in the hundredths and minor patch in ten-thousandths.
do
	-- constants
	CT_GAME_VERSION_CLASSIC = 1;	-- These globals are being phased out, but remain for backwards compatibility.
	CT_GAME_VERSION_RETAIL  = 9;
	
	local version, major, minor = strsplit(".", GetBuildInfo());
	version, major, minor = tonumber(version) or 0, tonumber(major) or 0, tonumber(minor) or 0
	major = version + major/100
	minor = major + minor/10000
	
	function libPublic:getGameVersion(includeMajor, alsoIncludeMinor)
		if (includeMajor) then
			if (includeMinor) then
				return minor;
			else
				return major;
			end
		else
			return version;
		end
	end
end

-- Print a formatted message in yellow to ChatFrame1
function lib:printformat(...)
	printText(ChatFrame1, 1, 1, 0, format(...));
end

-- Print a formatted error message in red to ChatFrame1
function lib:errorformat(...)
	printText(ChatFrame1, 1, 0, 0, format(...));
end

-- Print a message in yellow to ChatFrame1
function lib:print(...)
	printText(ChatFrame1, 1, 1, 0, getPrintText(...));
end

-- Print an error message in red to ChatFrame1
function lib:error(...)
	printText(ChatFrame1, 1, 0, 0, getPrintText(...));
end

-- Print a message in a color of your choice to ChatFrame1
function lib:printcolor(r, g, b, ...)
	printText(ChatFrame1, r, g, b, getPrintText(...));
end

-- Print a formatted message in a color of your choice to ChatFrame1
function lib:printcolorformat(r, g, b, ...)
	printText(ChatFrame1, r, g, b, format(...));
end

-- Displays a tooltip, then hides it when the mouse cursor leaves the object
-- if text is a string, it will simply display the text
-- if text is a table of strings, it will AddLine() each string and optionally set r,g,b,a and wrap by checking for '#' delimiters, or AddDoubleLine() if sufficient content is provided
-- setting anchor to CT_ABOVEBELOW or CT_BESIDE will position the tooltip wherever there is more room on the screen
do
	local lineHeight = { };
	local left, right = { }, { };
	local tooltip = GameTooltip;
	local validLinkTypes =
	{
		-- list of types converted to GameTooltip:SetHyperlink()
		["item"] = true,
		["spell"] = true,
	}
	
	function lib:displayTooltip(obj, text, anchor, offx, offy, owner)
		
		if not obj or not tooltip then return; end

		-- when the mouse leaves this object, make the tooltip go away (using HookScript if possible to avoid overriding any other behaviour)
		if not (obj.ct_displayTooltip_Hooked) then
			obj:HookScript("OnLeave", function()
				tooltip:Hide();
			for i, height in pairs(lineHeight) do
				left[i]:SetScale(1);
				if (right[i]) then right[i]:SetScale(1); end
			end
			wipe(lineHeight);
			end);
			obj.ct_displayTooltip_Hooked = true
		end

		-- anchor the tooltip
		owner = (type(owner) == "string" and _G[owner]) or owner or obj;
		if ( not anchor ) then
			GameTooltip_SetDefaultAnchor(tooltip, owner);
		elseif (anchor == "CT_ABOVEBELOW") then
			if (owner:GetBottom() * owner:GetEffectiveScale() <= (UIParent:GetTop() * UIParent:GetEffectiveScale()) - (owner:GetTop() * owner:GetEffectiveScale())) then
				tooltip:SetOwner(owner, "ANCHOR_TOP", offx or 0, offy or 0);
			else
				tooltip:SetOwner(owner, "ANCHOR_BOTTOM", offx or 0, -(offy or 0));
			end
		elseif (anchor == "CT_BESIDE") then
			if (owner:GetLeft() <= UIParent:GetRight() - owner:GetRight()) then
				tooltip:SetOwner(owner, "ANCHOR_BOTTOMRIGHT", offx or 0, (offy or 0) + owner:GetHeight());
			else
				tooltip:SetOwner(owner, "ANCHOR_BOTTOMLEFT", -(offx or 0), (offy or 0) + owner:GetHeight());
			end
		else
			tooltip:SetOwner(owner, anchor, offx or 0, offy or 0);
		end

		-- generate the tooltip content
		if (type(text) == "string") then
			local p1, p2 = strsplit(":", text);
			if (p1 and p2 and validLinkTypes[p1] and tonumber(p2)) then
				tooltip:SetHyperlink(text);
			else
				tooltip:SetText(text);
			end
		elseif (type(text) == "table") then
			for i, row in ipairs(text) do
				local splitrow = {strsplit("#", row)}
				local leftR,leftG,leftB,rightR,rightG,rightB,alpha,wrap,leftText,rightText;
				for j=1, #splitrow do
					local pieces = {strsplit(":", splitrow[j])}
					local isAllNums = true;
					for k, piece in ipairs(pieces) do
						if (not tonumber(piece) or tonumber(piece) < 0 or tonumber(piece) > 1) then
							isAllNums = false;
						end
					end						
					if (not leftR and #pieces >= 3 and isAllNums) then
						leftR = pieces[1];
						leftG = pieces[2];
						leftB = pieces[3];
						if (pieces[6]) then
							rightR = pieces[4];
							rightG = pieces[5];
							rightB = pieces[6];
						elseif (pieces[4]) then
							alpha = pieces[4];
						end
					elseif (not wrap and #pieces == 1 and pieces[1] == "w") then
						wrap = true;
					elseif (not size and #pieces == 2 and pieces[1] == "s") then
						lineHeight[i] = tonumber(pieces[2]);
					elseif (not leftText) then
						leftText = splitrow[j];
					elseif (not rightText) then
						rightText = splitrow[j];
					end
				end
				if (size) then
					customSize = size;
				end
				if (rightText) then
					GameTooltip:AddDoubleLine(leftText, rightText, leftR, leftG, leftB, rightR, rightG, rightB);
				elseif (leftText) then
					GameTooltip:AddLine(leftText, leftR, leftG, leftB, alpha, wrap);
				end
				customSize = nil;
			end
		end

		-- make the tooltip finally appear!
		tooltip:Show();
		
		for i, height in pairs(lineHeight) do
			left[i] = left[i] or _G["GameTooltipTextLeft" .. i]
			right[i] = right[i] or _G["GameTooltipTextRight" .. i]
			tooltip:SetHeight(tooltip:GetHeight() + (height - 1) * left[i]:GetHeight());
			left[i]:SetScale(height);
			if (right[i] and right[i]:IsVisible()) then
				right[i]:SetScale(height);
				right[i]:SetPoint("RIGHT", left[i], "LEFT", select(4, right[i]:GetPoint(1))/height, 0)
			end
		end
	end
end

-- Display a tooltip using predefined, localized text
function lib:displayPredefinedTooltip(obj, text, ...)
	self:displayTooltip(obj, L["CT_Library/Tooltip/" .. text], ...);
end

-- Hooks fontString:SetText(text) to shrink the text up to 1/3 if it is longer than maxwidth, ignoring scaling and any word-wrap caused by fixed widths or anchor points
-- This function depends on the current font.  It also hooks the SetText() and SetFont() functions to automatically update itself
function lib:blockOverflowText(fontString, maxwidth)
	local fontName, fontHeight, fontFlags = fontString:GetFont();
	fontString.ctOverflowFunc = function(__, text)
		fontString.ctIsResizing = true;
		fontString:SetFont(fontName, fontHeight, fontFlags);
		local width = fontString:GetStringWidth();
		local newHeight = fontHeight;
		while (width >= maxwidth and newHeight * 1.5 > fontHeight) do
			newHeight = newHeight - 0.5;
			fontString:SetFont(fontName, newHeight, fontFlags);
			width = fontString:GetStringWidth();
		end
		fontString.ctIsResizing = false;
	end	
	if (not fontString.ctOverflowFuncHooked) then
		fontString.ctOverflowFuncHooked = true;
		hooksecurefunc(fontString, "SetText", fontString.ctOverflowFunc);
		hooksecurefunc(fontString, "SetFont", function()
			if (not fontString.ctIsResizing) then
				fontName, fontHeight, fontFlags = fontString:GetFont();
				fontString.ctOverflowFunc(fontString, fontString:GetText());
			end
		end);
		fontString.ctOverflowFunc(fontString, fontString:GetText());
	end
end

function lib:unblockOverflowText(fontString)
	if (fontString.ctOverflowFuncHooked) then
		-- direct the hook to a harmless dummy function that does nothing
		fontString.ctOverflowFunc = function() return; end
	end
end

-- Register a slash command
if (not numSlashCmds) then
	numSlashCmds = 0;
	-- In case the player is using an earlier version of CT_Library.lua
	-- that did not preserve the 'numSlashCmds' value, determine the
	-- current value for numSlashCmds.
	local cmd = true;
	while (cmd) do
		local count = numSlashCmds + 1;
		cmd = _G["SLASH_CT_SLASHCMD" .. count .. "1"];
		if (not cmd) then
			break;
		end
		numSlashCmds = count;
	end
end

function lib:setSlashCmd(func, ...)
	-- Add one or more CTMod slash commands.
	-- func == The function to be called when one of the slash command is used.
	-- ... == One or more slash command strings.
	numSlashCmds = numSlashCmds + 1;
	local id = "CT_SLASHCMD" .. numSlashCmds;
	SlashCmdList[id] = func;
	for i = 1, select('#', ...), 1 do
		_G["SLASH_" .. id .. i] = select(i, ...);
	end
end

function lib:updateSlashCmd(func, ...)
	-- Update existing CTMod slash commands, else add slash commands.
	-- Matching is done based on the slash command text, not the function value.
	-- func == The function to be called when one of the slash command is used.
	-- ... == One or more slash command strings.
	local found;
	local count = 1;
	local id = "CT_SLASHCMD" .. count;
	local oldFunc = SlashCmdList[id];
	while (oldFunc) do
		local i = 1;
		local cmd = _G["SLASH_" .. id .. i];
		while (cmd) do
			-- Compare the existing slash command to the ones we're trying to find.
			for k = 1, select('#', ...), 1 do
				if (cmd == select(i, ...)) then
					-- We found one of the slash commands we were looking for.
					-- Assume the rest of them match as well.
					found = true;
					break;
				end
			end
			if (found) then
				break;
			end
			i = i + 1;
			cmd = _G["SLASH_" .. id .. i];
		end
		if (found) then
			-- Delete each of the existing slash commands.
			local i = 1;
			local cmd = _G["SLASH_" .. id .. i];
			while (cmd) do
				_G["SLASH_" .. id .. i] = nil;
				i = i + 1;
				cmd = _G["SLASH_" .. id .. i];
			end
			-- Temporarily change numSlashCmds so that we will overwrite
			-- the existing entry in the list when we call :setSlashCmd().
			local save = numSlashCmds;
			numSlashCmds = count - 1;
			self:setSlashCmd(func, ...);
			numSlashCmds = save;
			break;
		end
		count = count + 1;
		id = "CT_SLASHCMD" .. count;
		oldFunc = SlashCmdList[id];
	end
	if (not found) then
		-- There were no existing slash commands to update,
		-- so just call the normal function to add these ones.
		self:setSlashCmd(func, ...);
	end
end

-- Add localizations for a given text string
local num_locales = 3; -- EN, DE, FR
function lib:setText(key, ...)
	local count = select('#', ...);
	if ( count == 0 ) then
		return;
	end

	if ( not localizations ) then
		localizations = { };
	end

	local retVal = maxn(localizations)+1;
	for i = 1, min(count, num_locales), 1 do
		tinsert(localizations, (select(i, ...)));
	end
	self[key] = retVal;
end

-- Get a localized text string
function lib:getText(key)
	local localeOffset;
	if ( localizations ) then

		key = self[key];
		if ( not key ) then
			return;
		end

		if ( not localeOffset ) then
			local locale = strsub(GetLocale(), 1, 2);
			if ( locale == "en" ) then
				localeOffset = 0;
			elseif ( locale == "de" ) then
				localeOffset = 1;
			elseif ( locale == "fr" ) then
				localeOffset = 2;
			else
				localeOffset = 0;
			end
		end

		local value = localizations[key+localeOffset];
		if ( not value and localeOffset > 0 ) then
			value = localizations[key];
		end
		if ( not value ) then
			value = "";
		end
		return value;
	end
end

-- Get an empty table
if (not tableList) then
	tableList = { };
end
setmetatable(tableList, { __mode = 'v' });

function lib:getTable()
	return tremove(tableList) or { };
end

-- Free a table
function lib:freeTable(tbl)
	if ( tbl ) then
		self:clearTable(tbl, true);
		tinsert(tableList, tbl);
	end
end

-- Copy table
function lib:copyTable(source, dest)
	if (type(dest) ~= "table") then
		dest = {};
	end
	if (type(source) == "table") then
		for k, v in pairs(source) do
			if (type(v) == "table") then
				v = self:copyTable(v, dest[k]);
			end
			dest[k] = v;
		end
	end
	return dest;
end

do
	local separatorPattern4 = "%s%d" .. LARGE_NUMBER_SEPERATOR .. "%03d";
	local separatorPattern7 = "%s%d" .. LARGE_NUMBER_SEPERATOR .. "%03d" .. LARGE_NUMBER_SEPERATOR .. "%03d";
	local capPattern4 = separatorPattern4;
	local capPattern6 = "%s%d" .. FIRST_NUMBER_CAP;
	local capPattern7 = separatorPattern4 .. FIRST_NUMBER_CAP;
	local capPattern9 = "%s%d" .. SECOND_NUMBER_CAP;
	local capPattern10 = separatorPattern4 .. SECOND_NUMBER_CAP;

	-- This abbreviates large numbers by reducing the number of digits
	-- and appending some abbreviation text. The breakup parameter
	-- controls whether or not the number will be broken up using separators.
	--
	-- This is a modified version of AbbreviateLargeNumbers() from UIParent.lua
	-- as of WoW 5.0.4.
	-- This modified version handles negative numbers, adds the breakup parameter,
	-- and is capable of breaking up numbers before adding the abbreviation text.
	-- 
	-- Further changed in 8.3.0.9 for faster performance
	--
	-- Parameters:
	-- value == value to be abbreviated (very large values may not display properly).
	-- breakup == Should the number be broken up using seperators.
	--            nil == yes, true == yes, false == no
	function lib:abbreviateLargeNumbers(value, breakup)
		local negative = "";
		if (value < 0) then
			negative = "-";
			value = -value;
		end
		if (value < 1000) then
			return negative .. value
		elseif (value < 100000 and breakup ~= false) then
			return capPattern4:format(negative, value/1000, value%1000);
		elseif (value < 1000000) then
			return capPattern6:format(negative, value/1000);
		elseif (value < 100000000 and breakup ~= false) then
			return capPattern7:format(negative, value/1000000, value%1000000/1000);
		elseif (value < 1000000000 or breakup == false) then
			return capPattern9:format(negative, value/1000000);
		else
			return capPattern10:format(negative, value/1000000000, value/1000000);
		end
	end


	-- Break up large numbers using separators, and if the number contains
	-- decimals then the returned string will have two decimals.
	--
	-- This is a modified version of BreakUpLargeNumbers() from UIParent.lua
	-- as of WoW 5.0.4.
	-- This modified version handles negative numbers, adds the breakup parameter,
	-- and drops the use of GetCVarBool("breakUpLargeNumbers"). 
	-- 
	-- Further changed in 8.3.0.9 for faster performance
	--
	-- Parameters:
	-- value == value to be abbreviated (very large values may not display properly).
	-- breakup == Should the number be broken up using seperators.
	--            nil == yes, true == yes, false == no
	function lib:breakUpLargeNumbers(value, breakup)
		local negative = "";
		if (value < 0) then
			negative = "-";
			value = -value;
		end

		if ( value < 1000 ) then
			if ( value%1 == 0) then
				-- Return the integer
				return negative .. value;
			else
				-- Return a string with two decimals.
				return negative .. format("%.2f", value);
			end
		elseif (breakup ~= false) then
			-- Use seperators to break the value up, and don't allow any decimals.
			--value = math.floor(value);
			if ( value >= 1000000 ) then
				return separatorPattern7:format(negative, value/1000000, value/1000%1000, value%1000);
			else
				return separatorPattern4:format(negative, value/1000, value%1000);
			end
		else
			-- no separators, but still don't allow any decimals.
			return negative .. math.floor(value);
		end
	end
end

-----------------------------------------------
-- Initializing

local function loadAddon(event, addon)
	if ( modules ) then
		local module = modules[addon];
		if (module) then
			-- Initialize options
			module.options = _G[addon.."Options"];
			
			-- Delete leftovers from settings import
			if ( module.options ) then
				-- previously-used export strings
				module.options["CHAR-Unknown- Import String"] = nil;
				
				-- backup data is only intended to be available after a single /reload
				module.options["CHAR-Unknown- Temporary Backup"] = module.options["CHAR-Unknown- Interim Backup"]
				module.options["CHAR-Unknown- Interim Backup"] = nil;
			end

			-- Run any update function we might have
			if ( module.update ) then
				module:update("init");
			end
		end
	end
end

-----------------------------------------------
-- Actions requiring frames

-- Register events
if ( not frame ) then
	frame = CreateFrame("Frame");
end

function lib:regEvent(event, func)
	event = strupper(event);
	frame:RegisterEvent(event);

	if ( not eventTable ) then
		eventTable = { };
	end

	local oldFunc = eventTable[event];
	if ( not oldFunc ) then
		eventTable[event] = func;
	elseif ( type(oldFunc) == "table" ) then
		tinsert(oldFunc, func);
	else
		eventTable[event] = { oldFunc, func };
	end
end

function lib:unregEvent(event, func)
	if ( not eventTable ) then
		return;
	end

	event = strupper(event);
	local eventFuncs = eventTable[event];
	if ( not eventFuncs ) then
		return;
	end

	if ( type(eventFuncs) == "table" ) then
		for key, value in ipairs(eventFuncs) do
			if ( value == func ) then
				tremove(eventFuncs, key);
				break;
			end
		end
		if ( #eventFuncs == 0 ) then
			frame:UnregisterEvent(event);
		end
	else
		eventTable[event] = nil;
		frame:UnregisterEvent(event);
	end
end

local function eventHandler(self, event, ...)
	local eventFuncs = eventTable[event];
	if ( type(eventFuncs) == "table" ) then
		for key, value in ipairs(eventFuncs) do
			value(event, ...);
		end
	elseif ( eventFuncs ) then
		eventFuncs(event, ...);
	end
end

lib:regEvent("ADDON_LOADED", loadAddon);
frame:SetScript("OnEvent", eventHandler);

-- Schedule timers
 -- Usage:	schedule(time, func) for one-time
 --		schedule(time, true, func) for repeated
function lib:schedule(time, func, repeatFunc)
	if ( not time or not func or ( type(func) ~= "function" and not repeatFunc ) ) then
		return;
	end

	if ( repeatFunc ) then
		if (timerRepeatingFuncs[repeatFunc]) then
			timerRepeatingFuncs[repeatFunc]:Cancel();
		end
		timerRepeatingFuncs[repeatFunc] = C_Timer.NewTicker(time, repeatFunc);
	else
		if (timerFuncs[func]) then
			timerFuncs[func]:Cancel();	--clears the timer if it was already counting
		end
		timerFuncs[func] = C_Timer.NewTimer(time, func);
	end
end

-- Unschedule timers
 -- Usage:	unschedule(func) to cancel a one-time callback
 --		unschedule(func, true) to cancel a repeating function
function lib:unschedule(func, isRepeat)
	if ( not func ) then
		return;
	end

	if ( isRepeat ) then
		if ( timerRepeatingFuncs[func] ) then
			timerRepeatingFuncs[func]:Cancel();
			timerRepeatingFuncs[func] = nil;
		end
	else
		if ( timerFuncs[func] ) then
			timerFuncs[func]:Cancel();
			timerFuncs[func] = nil;
		end
	end
end


-- Check if an encounter is in progress, and return its ID (might not work after a /reload until the next encounter begins)
do

	local inEncounter = nil,
	lib:regEvent("ENCOUNTER_START", function(id)
		inEncounter = id;
	end);
	lib:regEvent("ENCOUNTER_END", function()
		inEncounter = nil;
	end);
	
	function lib:isInEncounter()
		return inEncounter;
	end

end

function lib:unload()
	self:clearTable(self);
end

-- End Generic Functions
-----------------------------------------------

-----------------------------------------------
-- Spell Database

-- Local variables used
local spellRanks, spellIds;

-- Update a tab
local function updateSpellTab(tabIndex)
	local spellName, rankName, rank, oldRank, spellId;
	local _, _, offset, numSpells = getSpellTabInfo(tabIndex);
	for spellIndex = 1, numSpells, 1 do

		spellId = offset + spellIndex;
		spellName, rankName = getSpellName(spellId, "spell");

		_, _, rank = string.find(rankName or "", "(%d+)$");
		oldRank = spellRanks[spellName];
		rank = tonumber(rank);

		-- print("tab=", tabIndex, "off=", offset, "idx=", spellIndex, "name=", spellName, "rname=", rankName, "rold=", oldRank, "rnk=", rank, "sid=", spellId)

		if ( ( not oldRank or ( rank and rank > oldRank ) ) and spellName ) then
			-- Need to update our listing
			spellRanks[spellName] = rank;
			spellIds[spellName] = spellId;
		end

	end
end

-- Update the database
local function updateSpellDatabase(event, arg1, arg2)
	-- print(event, arg1, arg2)
	if ( (not spellRanks) or (event == "PLAYER_TALENT_UPDATE") ) then
		spellRanks = {};
		spellIds = {};
	end
	if ( (event == "LEARNED_SPELL_IN_TAB") and arg2 ) then
		-- arg1 == spell number
		-- arg2 == tab number that spell was added to
		updateSpellTab(arg2);
	else
		for tabIndex = 1, getNumSpellTabs(), 1 do
			updateSpellTab(tabIndex);
		end
	end
end

-- Returns spell id and spell rank (if applicable)
function lib:getSpell(name)
	if ( not spellRanks ) then
		updateSpellDatabase();
	end

	return spellIds[name], spellRanks[name];
end

lib:regEvent("LEARNED_SPELL_IN_TAB", updateSpellDatabase);
if (lib:getGameVersion() >= 8) then
	lib:regEvent("PLAYER_TALENT_UPDATE", updateSpellDatabase);
end

-- End Spell Database
-----------------------------------------------

-----------------------------------------------
-- Module Handling

-- Register a module with the library
local module_meta =
{
	__index = function(module, key)
		return module.publicInterface[key] or lib[key];
	end
}
local module_metaPublic = { __index = libPublic };

local function registerMeta(module)
	-- Creates a public interface used by some CTMod modules to publicly expose only a subset of library functions
	module.publicInterface = module.publicInterface or {};
	setmetatable(module.publicInterface, module_metaPublic);

	-- Set the module's metatable, used by all CTMod modules to access private library functions
	setmetatable(module, module_meta);
	

end

local function registerLocalizationMeta(module)
	-- most modules populate this table using localization.lua
	module.text = module.text or {};
	
	-- gracefully handle errors, in case a localisation is missing
	local meta = getmetatable(module.text) or {};
	meta.__index = function(table, missingKey)
		missingKey = gsub(missingKey, (module.name or "CT_Library") .. "/", "");
		missingKey = gsub(missingKey, "Options/", "O/");
		return "[Error: " .. missingKey .. "]";
	end
	setmetatable(module.text, meta);
end

-- Registers a module having a unique name and an optional index (defaulting to #modules)
local function registerModule(module, position)
	if modules[module.name] then
		-- Module is already registered
		return;
	end
	modules[module.name] = module;
	if ( position ) then
		module.ctposition = position;
		tinsert(modules, position, module);
	else
		tinsert(modules, module);
	end
	registerMeta(module);
	registerLocalizationMeta(module);
	sort(modules, function(a, b)
		if (a.ctposition and not b.ctposition) then
			return true;
		elseif (not a.ctposition and b.ctposition) then
			return false;
		elseif (a.ctposition and b.ctposition) then
			if (a.ctposition == b.ctposition) then
				return a.name < b.name;
			else
				return a.ctposition < b.ctposition;
			end
		else
			return a.name < b.name;
		end
	end);
	defaultDisplayValues[module] = {}
end

-- Integrates the module into the CT Control Panel, and makes the module an extension of CTMod's public interface and protected content by configuring its metatable __index property
-- Furthermore, creates sub-table module.publicInterface that may be used by modules to limit their public exposure
-- 
function libPublic:registerModule(module)
	assert(type(module) == "table", "An AddOn attempted to register itself with CTMod without passing its table");
	assert(type(module.name) == "string", "An unnamed addon attempted to register with CTMod.");
	registerModule(module);
end

-- End Module Handling
-----------------------------------------------

-----------------------------------------------
-- Option Handling

local charKey;
local function getCharKey()
	if ( not charKey ) then
		charKey = "CHAR-"..(UnitName("player") or "Unknown").."-"..(GetRealmName() or "Unknown");
	end
	return charKey;
end
lib.getCharKey = getCharKey;

CT_SKIP_UPDATE_FUNC = false	-- convenience constant so the impact of callUpdate is clearer in other modules

-- Set an option's value on the current profile
function lib:setOption(option, value, callUpdate)
	-- callUpdate
	--	false: Do not call the update function.
	--	true, nil: Call the update function.
	
	if (type(option) == "function") then
		-- some addons overload option so the same object can manipulate different tasks simultaneously
		option = option()
	end
	if (not option) then
		-- either option was nil, or option() returned nil
		return
	end
	if ( self.options == nil ) then
		local optionKey = self.name.."Options"
		self.options = _G[optionKey] or {}
		_G[optionKey] = self.options
	end
	local key = getCharKey();
	self.options[key] = self.options[key] or {}
	self.options[key][option] = value;
	if (callUpdate ~= false) then
		local updateFunc = self.update;
		if ( updateFunc ) then
			updateFunc(self, option, value);
		end
	end
end

-- Reads an option.
function lib:getOption(option)
	if (type(option) == "function") then
		-- some addons overload a frame to have a function
		option = option();
	end
	if (option and self.options) then
		local key = getCharKey();
		if ( self.options[key] ) then
			return self.options[key][option];
		end
	end
end

-- Reads an option, or the 'default' value for display on a frame (NOT INTENDED FOR USE BY ANY MODULES)
function lib:getDisplayValue(option)
	local value = self:getOption(option)
	return value ~= nil and value or defaultDisplayValues[self][option]
end

-- Returns all of a toon's options

local function nextOption(t, key)
	repeat
		key, val = next(t, key)
	until (key == nil or key:find("MOVABLE-") == nil)		-- see nextMovable() below
	return key, val
end

function lib:enumerateOptions()
	local key = getCharKey()
	local options = self.options
	if (options and options[key]) then
		return nextOption, options[key]
	else
		return next, {}
	end
end


-- End Option Handling
-----------------------------------------------

-----------------------------------------------
-- Movable Handling

function lib:registerMovable(id, frame, clamped)
	if ( not movables ) then
		movables = { };
	end

	id = "MOVABLE-"..id;
	movables[id] = frame;
	frame:SetMovable(true);
	frame:SetClampedToScreen(clamped);

	-- See if we have a saved position already...
	local option = self:getOption(id);
	if ( option ) then
		frame:ClearAllPoints();

		local scale = option[6];
		if ( scale ) then
			frame:SetScale(scale);
			frame:SetPoint(option[1], option[2], option[3], option[4] / scale, option[5] / scale);
		else
			frame:SetPoint(option[1], option[2], option[3], option[4], option[5]);
		end
	end
end

function lib:moveMovable(id)
	movables["MOVABLE-"..id]:StartMoving();
end

function lib:stopMovable(id)
	id = "MOVABLE-"..id;
	local frame = movables[id];
	frame:StopMovingOrSizing();
	frame:SetUserPlaced(false); -- Since we're storing the position manually, don't save it in layout-cache

	local pos = self:getOption(id);
	if ( pos ) then
		self:clearTable(pos);

		local a, b, c, d, e = frame:GetPoint(1);
		local scale = frame:GetScale();
		if string.upper(a) == "BOTTOMLEFT" or string.upper(a) == "BOTTOMRIGHT" then
			a = "BOTTOM";
			c = "BOTTOM";
			d = math.floor(frame:GetLeft() + (frame:GetWidth() - UIParent:GetWidth()) / 2 + 0.5) * scale;
			e = math.floor(frame:GetTop() - frame:GetHeight() + 0.5) * scale;
		end

		pos[1], pos[2], pos[3], pos[4], pos[5], pos[6] = a, b, c, d, e, scale;
		if (not InCombatLockdown()) then
			frame:ClearAllPoints();
			frame:SetPoint(a, b, c, d, e);
		end
	else
		local a, b, c, d, e = frame:GetPoint(1);
		local scale = frame:GetScale();
		d, e = d * scale, e * scale;

		pos = { a, b, c, d, e, scale };
		self:setOption(id, pos);
	end

	local rel = pos[2];
	if ( rel ) then
		pos[2] = rel:GetName();
	end
end

function lib:resetMovable(id)
	self:setOption("MOVABLE-"..id, nil);
end

function lib:UnregisterMovable(id)
	movables["MOVABLE-"..id] = nil;
end

local function nextMovable()	-- see nextOption() above
	repeat
		key, val = next(t, key)
	until (key == nil or key:find("MOVABLE-"))
	return key, val
end

function lib:enumerateMovables()
	local key = getCharKey()
	local options = self.options
	if (options and options[key]) then
		return nextMovable, options[key]
	else
		return pairs({})
	end
end

-- End Movable Handling
-----------------------------------------------

-----------------------------------------------
-- Secure Hooks	

-- Executes func() right away if _G[frame] exists, or after _G[trigger] happens for the first time.
function lib:hookWhenFirstLoaded(frame, trigger, func)
	if (_G[frame]) then
		func(self, _G[frame])
	else
		hooksecurefunc(trigger, function()
			func(self, _G[frame])
			func = nop
		end)
	end
end

-- End Secure Hooks
-----------------------------------------------


-----------------------------------------------
-- Frame Misc

function lib:createMultiLineEditBox(name, width, height, parent, bdtype, font)
	-- Create a multi line edit box
	-- Param: bdtype -- nil==No backdrop, 1=Tooltip backdrop, 2==Dialog backdrop
	local frame, scrollFrame, editBox;
	local backdrop;

	if (bdtype == 1) then
		backdrop = {
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true,
			tileSize = 16,
			edgeSize = 16,
			insets = { left = 5, right = 5, top = 5, bottom = 5 },
		};
	elseif (bdtype == 2) then
		backdrop = {
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true,
			tileSize = 32,
			edgeSize = 32,
			insets = { left = 5, right = 5, top = 5, bottom = 5 },
		};
	end


	if (backdrop) then
		frame = CreateFrame("Frame", name, parent, BackdropTemplateMixin and "BackdropTemplate");
		frame:SetBackdrop(backdrop);
		frame:SetBackdropBorderColor(0.4, 0.4, 0.4);
		frame:SetBackdropColor(0, 0, 0);
	else
		frame = CreateFrame("Frame", name, parent);
	end
	
	frame:SetHeight(height);
	frame:SetWidth(width);
	frame:SetPoint("TOPLEFT", parent);
	frame:SetPoint("BOTTOMRIGHT", parent, "TOPLEFT", width, -height);

	frame:EnableMouse(true);
	frame:Hide();

	local sfname;
	if (name) then
		sfname = name .. "ScrollFrame";
	end
	scrollFrame = CreateFrame("ScrollFrame", sfname, frame, "UIPanelScrollFrameTemplate");
	scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 7, -5);
	scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -28, 5);

	width = scrollFrame:GetWidth() - 6;

	local ebname;
	if (name) then
		ebname = name .. "EditBox";
	end

	editBox = CreateFrame("EditBox", ebname, frame);
	editBox:SetWidth(width);
	editBox:SetMultiLine(true);
	editBox:EnableMouse(true);
	editBox:SetAutoFocus(false);
	editBox:SetFontObject(font or ChatFontNormal);

	-- Note:
	--
	-- ScrollingEdit_OnUpdate (in UIPanelTemplates.lua) will cause
	-- an error if the editBox.cursorOffset or editBox.cursorHeight
	-- variables are nil. This can happen if ScrollingEdit_OnTextChanged
	-- gets called before ScrollingEdit_OnCursorChanged.
	--
	-- To avoid this error:
	--    1) Initialize those variables to zero ourself.
	-- or 2) Assign a non-empty string to the editBox. This will
	--       force the OnCursorChanged script to get called
	--       just prior to the OnTextChanged script. As a result,
	--       the ScrollingEdit_OnCursorChanged function will
	--       initialize the variables before they are accessed
	--       by ScrollingEdit_OnUpdate.

	editBox.cursorOffset = 0;
	editBox.cursorHeight = 0;
	editBox:SetText(" ");  -- Assign initial non-empty string.

	editBox:SetScript("OnCursorChanged",
		function(self, x, y, w, h)
			ScrollingEdit_OnCursorChanged(self, x, y-10, w, h);
		end
	);
	editBox:SetScript("OnTextChanged",
		function(self, userInput)
			ScrollingEdit_OnTextChanged(self, scrollFrame);
		end
	);
	editBox:SetScript("OnUpdate",
		function(self, elapsed)
			ScrollingEdit_OnUpdate(self, elapsed, scrollFrame);
		end
	);
	editBox:SetScript("OnEscapePressed",
		function(self)
			self:ClearFocus();
		end
	);
	editBox:SetScript("OnTabPressed",
		function(self)
			self:ClearFocus();
		end
	);

	scrollFrame:SetScrollChild(editBox);
	scrollFrame:Show();
	editBox:Show();

	-- Button that allows clicking anywhere over the scroll frame
	-- to set the focus to the editbox. Without this the player has
	-- to click on a line that has text, which is not obvious when
	-- the editbox is empty.
	local textButton = CreateFrame("Button", nil, frame);
	textButton:ClearAllPoints();
	textButton:SetPoint("TOPLEFT", scrollFrame);
	textButton:SetPoint("BOTTOMRIGHT", scrollFrame);
	textButton:SetScript("OnClick",
		function(self, button)
			self:GetParent().editBox:SetFocus();
		end
	);

	frame.scrollFrame = scrollFrame;
	frame.editBox = editBox;

	return frame;
end



function lib:setRadioButtonTextures(checkbutton)
	-- Makes a check button look like a radio button by changing its textures.
	local tex = "Interface\\Buttons\\UI-RadioButton";

	checkbutton:SetNormalTexture(tex);
	checkbutton:GetNormalTexture():SetTexCoord(0, 0.25, 0, 1);

	checkbutton:SetDisabledTexture(tex);
	checkbutton:GetDisabledTexture():SetTexCoord(0, 0.25, 0, 1);

	checkbutton:SetPushedTexture(tex);
	checkbutton:GetPushedTexture():SetTexCoord(0.25, 0.5, 0, 1);

	checkbutton:SetHighlightTexture(tex);
	checkbutton:GetHighlightTexture():SetTexCoord(0.51, 0.75, 0, 1);
	checkbutton:GetHighlightTexture():SetBlendMode("ADD");

	checkbutton:SetCheckedTexture(tex);
	checkbutton:GetCheckedTexture():SetTexCoord(0.25, 0.5, 0, 1);

	checkbutton:SetDisabledCheckedTexture(tex);
	checkbutton:GetDisabledCheckedTexture():SetTexCoord(0.25, 0.5, 0, 1);
end

-- End Frame Misc
-----------------------------------------------

-----------------------------------------------
-- Compression, hashing and character encoding

do
	-- This section uses LibDeflate by Hauquiain He, for the following:
	--   (a) Adler-32 checksum per RFC 1950; and
	--   (b) Compression and Decompression.

	-- LibDeflate is governed by the zlib license found at the top of <Libs/LibDeflate.lua>
	-- LibDeflate.lua also has an encoding methods which is comparable to other popular addons having other license types, but CTMod implements its own encoding to avoid license conflicts.


	-- Returns four hexadecimal characters representing a Adler32 hash
	function lib:hash(text)
		if (type(text) == "string") then
			return LibStub:GetLibrary("LibDeflate"):Adler32(text)
		end
	end

	-- Compresses a string using LibDeflate's algorithm
	function lib:compress(text)
		if (type(text) == "string") then
			return LibStub:GetLibrary("LibDeflate"):CompressDeflate(text)
		end
	end

	-- Decompresses a string using LibDeflate's algorithm
	function lib:decompress(text)
		if (type(text) == "string") then
			return LibStub:GetLibrary("LibDeflate"):DecompressDeflate(text)
		end
	end

	-- Encodes a string of raw bytes into visible UTF-8 characters with a checksum for easier transmission
	function lib:encode256To64(text)
		
		-- argument validation
		if (type(text) ~= "string" or strlen(text) < 1) then
			return
		end
		
		-- base 256 to 64
		local value = 0
		local bitsAvail = 0
		local encodedParts = lib:getTable()
		for i = 1, text:len() do
			value, bitsAvail = value*256 + text:byte(i), bitsAvail + 8
			while (bitsAvail >= 6) do
				bitsAvail = bitsAvail - 6
				tinsert(encodedParts, string.char(floor(value/2^bitsAvail)+38))
				value = value % 2^bitsAvail
			end
		end
		while (bitsAvail > 0) do
			bitsAvail = bitsAvail - 6
			tinsert(encodedParts, string.char(floor(value/2^bitsAvail)+38))
			value = value % 2^bitsAvail
		end
		
		-- append a checksum and return the rest
		local retVal = table.concat(encodedParts)
		retVal = string.char(lib:hash(retVal)%64+38) .. retVal
		lib:freeTable(encodedParts)
		return retVal
	end

	-- Decodes single-byte, visible UTF-8 characters back to a raw bit stream, but returns nil if the checksum fails
	function lib:decode256From64(text)
		if (type(text) ~= "string" or strlen(text) < 2 or lib:hash(text:sub(2))%64+38 ~= text:byte(1)) then
			return
		end
		
		-- base 64 to 256
		local value = 0
		local bitsAvail = 0
		local decodedParts = lib:getTable()
		for i = 2, text:len() do
			value, bitsAvail = value*64 + text:byte(i) - 38, bitsAvail + 6
			if (bitsAvail >= 8) then
				bitsAvail = bitsAvail - 8
				tinsert(decodedParts, string.char(floor(value/2^bitsAvail)))
				value = value % 2^bitsAvail
			end
		end	

		local retVal = table.concat(decodedParts)
		lib:freeTable(decodedParts)
		return retVal
	end

end

-- End compression, hashing and character encoding
-----------------------------------------------


-----------------------------------------------
-- Table serializing

-- This section uses AceSerializer-3.0 by Nevcairiel et al.
-- Ace3 is protected by the license in <Libs/Ace3/Ace3-License.txt>

function lib:serializeTable(tbl)
	if (type(tbl) == "table") then
		return LibStub:GetLibrary("AceSerializer-3.0"):Serialize(tbl)
	end
end

function lib:deserializeTable(text)
	if (type(text) == "string") then
		local success, tbl = LibStub:GetLibrary("AceSerializer-3.0"):Deserialize(text)
		if (success) then
			return tbl
		end
	end
end

-- End table serializing
-----------------------------------------------


-----------------------------------------------
-- Frame Creation

-- Thanks to Iriel for this iterator code
	local numberSeparator = "#";
	local colonSeparator = ":";
	local commaSeparator = ",";
	local pipeSeparator = "|";

	local numberMatch = "^(.-)"..numberSeparator.."(.*)$";
	local colonMatch = "^(.-)"..colonSeparator.."(.*)$";
	local commaMatch = "^(.-)"..commaSeparator.."(.*)$";
	local pipeMatch = "^(.-)"..pipeSeparator.."(.*)$";

	local function splitNext(re, body)
	    if (body) then
		local pre, post = match(body, re);
		if (pre) then
		    return post, pre;
		end
		return false, body;
	    end
	end
	local function iterator(str, match) return splitNext, match, str; end

-- Takes a string and returns its subcomponents
local function splitString(str, match)
	if ( str and match ) then
		return match:split(str);
	end
	return str;
end

-- Cache for storing str->function maps
if (not frameCache) then
	frameCache = { };
end

-- Short-notion to real-notation point map
local points = {
	tl = "TOPLEFT",
	tr = "TOPRIGHT",
	bl = "BOTTOMLEFT",
	br = "BOTTOMRIGHT",
	l = "LEFT",
	r = "RIGHT",
	t = "TOP",
	b = "BOTTOM",
	mid = "CENTER",
	all = "all" -- for SetAllPoints
};

-- Object Handlers
local objectHandlers = { };

-- Frame
objectHandlers.frame = function(self, parent, name, virtual, option)
	local frame = CreateFrame("Frame", name, parent, virtual)
	return frame
end

-- Collapsible Frame
do
	local function collapse(self)
		local parent = self:GetParent()
		local top, bottom = self:GetTop(), self:GetBottom()
		if (parent and top and bottom and self.movedSiblings == nil) then
			local height = max(top-bottom-20, 0)
			if (self.button) then
				self.button:SetNormalAtlas("UI-QuestTrackerButton-Expand-Section")
				self.button:SetPushedAtlas("UI-QuestTrackerButton-Expand-Section-Pressed")
				self.button.text:Show()
			end
			self.movedSiblings = {}
			if (parent) then
				for i=1, parent:GetNumChildren() do
					local sibling = select(i, parent:GetChildren())
					if (sibling:GetTop() < top and sibling ~= self) then
						sibling:AdjustPointsOffset(0, height)
						tinsert(self.movedSiblings, sibling)
					end
				end
				for i=1, parent:GetNumRegions() do
					local sibling = select(i, parent:GetRegions())
					if (sibling:GetTop() < top) then
						sibling:AdjustPointsOffset(0, height)
						tinsert(self.movedSiblings, sibling)
					end
				end
			end
			self:Hide()
		end
	end

	local function expand(self)
		if (self.movedSiblings) then
			self:Show()
			local parent = self:GetParent()
			local top, bottom = self:GetTop(), self:GetBottom()
			local height = max(top-bottom-20, 0)
			if (self.button) then
				self.button:SetNormalAtlas("UI-QuestTrackerButton-Collapse-Section")
				self.button:SetPushedAtlas("UI-QuestTrackerButton-Collapse-Section-Pressed")
				self.button.text:Hide()
			end
			for __, sibling in ipairs(self.movedSiblings) do
				sibling:AdjustPointsOffset(0, -height)
			end
			self.movedSiblings = nil

		end
	end
	
	local function toggle(self)
		if (self.frame:IsShown()) then
			self.frame:Collapse()
		else
			self.frame:Expand()
		end
	end

	objectHandlers.collapsible = function(self, parent, name, virtual, option, header)
		local frame = CreateFrame("Frame", name, parent, virtual)
		frame.Collapse = collapse
		frame.Expand = expand
		if (header) then
			local title, align = header:match("(.*):([lr])")
			title = title or header
			local button = CreateFrame("Button", name and name .. "Minimize", parent)
			button:SetPoint(align ~= "r" and "TOPLEFT" or "TOPRIGHT", frame)
			button:SetSize(15,15)
			button:SetNormalAtlas("UI-QuestTrackerButton-Collapse-Section")
			button:SetPushedAtlas("UI-QuestTrackerButton-Collapse-Section-Pressed")
			button:SetHighlightAtlas("UI-QuestTrackerButton-Highlight")
			button:SetScript("OnClick", toggle)
			frame.button = button
			button.frame = frame
			button.text = button:CreateFontString(nil, "ARTWORK", "GameFontNormal")
			button.text:SetText(title)
			button.text:SetPoint(align ~= "r" and "LEFT" or "RIGHT", button, align ~= "r" and "RIGHT" or "LEFT", 2, 0)
			button.text:Hide()
		end
		return frame
	end
end

-- Button
objectHandlers.button = function(self, parent, name, virtual, option, text)
	local button = CreateFrame("Button", name, parent, virtual);
	if ( text ) then
		local str = self:getText(text) or _G[text];
		if ( type(str) ~= "string" ) then
			str = text;
		end
		button:SetText(str);
	end
	return button;
end

-- CheckButton
local function checkbuttonOnClick(self)
	local checked = self:GetChecked() or false;
	local option = self.option;

	if ( option ) then
		self.object:setOption(option, checked);
	end
	if ( checked ) then
		PlaySound(856);
	else
		PlaySound(857);
	end
end

objectHandlers.checkbutton = function(self, parent, name, virtual, option, text, data)
	local checkbutton = CreateFrame("CheckButton", name, parent, virtual or "InterfaceOptionsBaseCheckButtonTemplate");

	-- Parse attributes for the FontString
	local r, g, b, justify, maxwidth;
	local a, b, c, d, e = splitString(data, colonSeparator);
	if ( tonumber(a) and tonumber(b) and tonumber(c) ) then
		r, g, b = tonumber(a), tonumber(b), tonumber(c);
		justify, maxwidth = d, tonumber(e);
	else
		justify, maxwidth = a, tonumber(b);
	end

	-- Create FontString
	local textObj = checkbutton:CreateFontString(nil, "ARTWORK", "ChatFontNormal");
	textObj:SetPoint("LEFT", checkbutton, "RIGHT", 4, 0);
	checkbutton.text = textObj;
	
	-- Color
	if ( r and g and b ) then
		textObj:SetTextColor(tonumber(r) or 1, tonumber(g) or 1, tonumber(b) or 1);
	end
	
	-- Justify (not very useful without maxwidth or additional anchor points)
	if ( justify ) then
		local h = match(justify, "[lLrRcC]");
		local v = match(justify, "[tTbBmM]");

		if ( h == "l" ) then
			textObj:SetJustifyH("LEFT");
		elseif ( h == "r" ) then
			textObj:SetJustifyH("RIGHT");
		elseif ( h == "c" ) then
			textObj:SetJustifyH("CENTER");
		end

		if ( v == "t" ) then
			textObj:SetJustifyV("TOP");
		elseif ( v == "b" ) then
			textObj:SetJustifyV("BOTTOM");
		elseif ( v == "m") then
			textObj:SetJustifyV("MIDDLE");
		end
	end

	-- Maximum width (to support localization)
	if (maxwidth and maxwidth > 1) then
		lib:blockOverflowText(textObj, maxwidth);
		textObj:SetWidth(maxwidth);
	end

	-- Text
	if ( text ) then
		local str = _G[text];
		if ( type(str) ~= "string" ) then
			str = text;
		end
		textObj:SetText(str);
	end

	if ( not virtual or not checkbutton:GetScript("OnClick") ) then
		checkbutton:SetScript("OnClick", checkbuttonOnClick);
	end
	checkbutton:SetChecked(self:getDisplayValue(option) or false);

	return checkbutton;
end

-- Backdrop
local dialogBackdrop = {
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	tile = true, tileSize = 32, edgeSize = 32,
	insets = { left = 11, right = 12, top = 12, bottom = 11 }
};
local tooltipBackdrop = {
	bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 4, right = 4, top = 4, bottom = 4 }
};
objectHandlers.backdrop = function(self, parent, name, virtual, option, backdropType, bgColor, borderColor)
	-- 9.0 Shadowlands compatibility
	Mixin(parent, BackdropTemplateMixin or { });
	
	-- Convert short-notation names to the appropriate tables
	if ( backdropType == "dialog" ) then
		parent:SetBackdrop(dialogBackdrop);
	elseif ( backdropType == "tooltip" ) then
		parent:SetBackdrop(tooltipBackdrop);
	end

	-- BG Color
	local r, g, b, a;
	if ( bgColor ) then
		r, g, b, a = splitString(bgColor, colonSeparator);
	end
	parent:SetBackdropColor(tonumber(r) or 0, tonumber(g) or 0, tonumber(b) or 0, tonumber(a) or 0.25);

	-- BG Color
	if ( borderColor ) then
		r, g, b, a = splitString(borderColor, colonSeparator);
		parent:SetBackdropBorderColor(tonumber(r) or 1, tonumber(g) or 1, tonumber(b) or 1, tonumber(a) or 1);
	end
end

-- FontString
-- #r:b:g:just:max where just is the justification and max is the maximum width (strings will shrink to fit within it)
objectHandlers.font = function(self, parent, name, virtual, option, text, data, layer)
	-- Data
	local r, g, b, justify, maxwidth;
	local a, b, c, d, e = splitString(data, colonSeparator);

	-- Parse our attributes
	if ( tonumber(a) and tonumber(b) and tonumber(c) ) then
		r, g, b = tonumber(a), tonumber(b), tonumber(c);
		justify, maxwidth = d, tonumber(e);
	else
		justify, maxwidth = a, tonumber(b);
	end

	-- Create FontString
	local fontString = parent:CreateFontString(name, layer or "ARTWORK", virtual or "GameFontNormal");

	-- Justify
	if ( justify ) then
		local h = match(justify, "[lLrRcC]");
		local v = match(justify, "[tTbBmM]");

		if ( h == "l" ) then
			fontString:SetJustifyH("LEFT");
		elseif ( h == "r" ) then
			fontString:SetJustifyH("RIGHT");
		elseif ( h == "c" ) then
			fontString:SetJustifyH("CENTER");
		end

		if ( v == "t" ) then
			fontString:SetJustifyV("TOP");
		elseif ( v == "b" ) then
			fontString:SetJustifyV("BOTTOM");
		elseif ( v == "m") then
			fontString:SetJustifyV("MIDDLE");
		end
	end

	-- Maximum width (to support localization)
	if (maxwidth and maxwidth > 0) then
		lib:blockOverflowText(fontString, maxwidth);
	end

	-- Color
	if ( r and g and b ) then
		fontString:SetTextColor(tonumber(r) or 1, tonumber(g) or 1, tonumber(b) or 1);
	end

	-- Text
	fontString:SetText(self:getText(text) or _G[text] or text);

	return fontString;
end

-- Texture
objectHandlers.texture = function(self, parent, name, virtual, option, texture, layer)
	-- Texture & Layer
	local r, g, b, a = splitString(texture, colonSeparator);
	local tex = parent:CreateTexture(name, layer or "ARTWORK", virtual);

	-- Color
	if ( r and g and b ) then
		tex:SetColorTexture(tonumber(r) or 1, tonumber(g) or 1, tonumber(b) or 1, tonumber(a) or 1);
	else
		tex:SetTexture(texture);
	end

	return tex;
end

-- Texture
objectHandlers.editbox = function(self, parent, name, virtual, option, font, bdtype, multiline, multilinewidth, multilineheight)
	local frame;
	local backdrop;
	if (multiline) then
		frame = lib:createMultiLineEditBox(name,multilinewidth,multilineheight,parent,bdtype, font);
		if (option) then
			frame.editBox:SetText(self:getDisplayValue(option) or "");
		end
	else
		if (tonumber(bdtype) == 1) then
			backdrop = {
				bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = true,
				tileSize = 16,
				edgeSize = 16,
				insets = { left = 5, right = 5, top = 5, bottom = 5 },
			};
		elseif (tonumber(bdtype) == 2) then
			backdrop = {
				bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
				edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
				tile = true,
				tileSize = 32,
				edgeSize = 32,
				insets = { left = 5, right = 5, top = 5, bottom = 5 },
			};
		end
		if (backdrop) then
			frame = CreateFrame("EditBox", name, parent, virtual, BackdropTemplateMixin and "BackdropTemplate");
			frame:SetBackdrop(backdrop);
			frame:SetBackdropBorderColor(0.4, 0.4, 0.4);
			frame:SetBackdropColor(0, 0, 0);
		else
			frame = CreateFrame("EditBox", name, parent, virtual);
		end
		
		if (font) then
			frame:SetFontObject(font)
		end
		if (option) then
			frame:SetText(self:getDisplayValue(option) or "");
		end
	end
	return frame;
end

-- Option Frame
local optionFrameOnMouseUp = function(self) self:GetParent():StopMovingOrSizing(); end
local optionFrameOnEnter = function(self) lib:displayPredefinedTooltip(self, "DRAG"); end
local optionFrameOnMouseDown = function(self, button)
	if ( button == "LeftButton" ) then
		self:GetParent():StartMoving();
	elseif ( button == "RightButton" ) then
		local parent = self:GetParent();
		parent:ClearAllPoints();
		parent:SetPoint("CENTER", "UIParent", "CENTER");
	end
end

objectHandlers.optionframe = function(self, parent, name, virtual, option, headerName)
	-- MainFrame
	local frame = CreateFrame("Frame", name, parent, virtual);
	frame:SetBackdrop(dialogBackdrop);
	frame:SetMovable(true);
	frame:SetToplevel(true);
	frame:SetFrameStrata("DIALOG");

	-- DragFrame
	local dragFrame = CreateFrame("Button", nil, frame);
	dragFrame:SetWidth(150); dragFrame:SetHeight(32);
	dragFrame:SetPoint("TOP", -12, 12);
	dragFrame:SetScript("OnMouseDown", optionFrameOnMouseDown);
	dragFrame:SetScript("OnMouseUp", optionFrameOnMouseUp);
	dragFrame:SetScript("OnEnter", optionFrameOnEnter);
	dragFrame:SetScript("OnLeave", optionFrameOnLeave);

	-- HeaderTexture
	local headerTexture = frame:CreateTexture(nil, "ARTWORK");
	headerTexture:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header");
	headerTexture:SetWidth(256); headerTexture:SetHeight(64);
	headerTexture:SetPoint("TOP", 0, 12);

	-- HeaderText
	local headerText = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	headerText:SetText(headerName);
	headerText:SetPoint("TOP", headerTexture, 0, -14);

	return frame;
end

-- DropDown
local function dropdownSetWidth(self, width)
	-- Ugly, ugly hack.
	self.SetWidth = self.oldSetWidth;
	UIDropDownMenu_SetWidth(self, width);
	self.SetWidth = dropdownSetWidth;
end

local function dropdownClick(self, arg1, arg2, checked)
	local dropdown;
	local value;
	local option;
	if ( type(UIDROPDOWNMENU_OPEN_MENU) == "string" ) then
		-- Prior to the 3.0.8 patch UIDROPDOWNMEN_OPEN_MENU was a string (name of the object).
		dropdown = _G[UIDROPDOWNMENU_OPEN_MENU];
	else
		-- As of the 3.0.8 patch UIDROPDOWNMEN_OPEN_MENU is an object.
		dropdown = UIDROPDOWNMENU_OPEN_MENU;
	end

	-- 7.0.3
	if not dropdown then
		dropdown = UIDROPDOWNMENU_INIT_MENU
	end
	--print(dropdown:GetName())
	
	if ( dropdown ) then
		
		
		if (arg1) then
			value = not checked;
			option = arg1;
		else
			value = self.value;
			option = dropdown.option;
			UIDropDownMenu_SetSelectedValue(dropdown, value);
		end
		
		if ( option ) then
			dropdown.object:setOption(option, value);
		end
	end
end

-- basic radio-button dropdown without any fancy modifications.  Each arg is text to display
objectHandlers.dropdown = function(self, parent, name, virtual, option, ...)
	local dropdownEntry = { };
	local frame = CreateFrame("Frame", name, parent, virtual or "UIDropDownMenuTemplate");
	frame.oldSetWidth = frame.SetWidth;
	frame.SetWidth = dropdownSetWidth;
	frame.ctDropdownClick = dropdownClick;
	
	-- Handle specializ
	
	-- Make the slider smaller
	local left, right, mid, btn = _G[name.."Left"], _G[name.."Middle"], _G[name.."Right"], _G[name.."Button"];
	local setHeight = left.SetHeight;

	btn:SetPoint("TOPRIGHT", right, "TOPRIGHT", 12, -12);
	setHeight(left, 50);
	setHeight(right, 50);
	setHeight(mid, 50);

	local entries = { ... };
	
	UIDropDownMenu_Initialize(frame, function()
		for i = 1, #entries, 1 do
			dropdownEntry.text = entries[i];
			dropdownEntry.value = i;
			dropdownEntry.checked = nil;
			dropdownEntry.func = dropdownClick;
			UIDropDownMenu_AddButton(dropdownEntry);
		end
	end);
	UIDropDownMenu_SetSelectedValue(frame, self:getDisplayValue(option) or 1);

	UIDropDownMenu_JustifyText(frame, "LEFT");
	return frame;
end

-- variant of a dropdown using checkboxes, that allows selecting more than one at a time.
-- two parameters (separated by #) are display-text and the CT option (similar to o:)
objectHandlers.multidropdown = function(self, parent, name, virtual, option, ...)
	local dropdownEntry = { };
	local frame = CreateFrame("Frame", name, parent, virtual or "UIDropDownMenuTemplate");
	frame.oldSetWidth = frame.SetWidth;
	frame.SetWidth = dropdownSetWidth;
	frame.ctDropdownClick = dropdownClick;
	
	-- Handle specializ
	
	-- Make the slider smaller
	local left, right, mid, btn = _G[name.."Left"], _G[name.."Middle"], _G[name.."Right"], _G[name.."Button"];
	local setHeight = left.SetHeight;

	btn:SetPoint("TOPRIGHT", right, "TOPRIGHT", 12, -12);
	setHeight(left, 50);
	setHeight(right, 50);
	setHeight(mid, 50);

	local entries = { ... };
	
	UIDropDownMenu_Initialize(frame, function()
		for i = 1, #entries, 2 do
			dropdownEntry.text = entries[i];
			dropdownEntry.value = (i+1)/2;
			dropdownEntry.isNotRadio = true;
			dropdownEntry.checked = self:getDisplayValue(entries[i+1]);
			dropdownEntry.func = dropdownClick;
			dropdownEntry.arg1 = entries[i+1];
			UIDropDownMenu_AddButton(dropdownEntry);
		end
	end);
	
	UIDropDownMenu_JustifyText(frame, "LEFT");
	return frame;
end


-- Slider
local function updateSliderText(slider, value)
	slider.title:SetText(gsub(slider.titleText, "<value>", floor( ( value or slider:GetValue() )*100+0.5)/100));
end

local function updateSliderValue(self, value)
	local valueStep = self:GetValueStep()
	value = floor(value / valueStep  + 0.5) * valueStep
	updateSliderText(self, value);

	local option = self.option;
	if ( option ) then
		self.object:setOption(option, value);
	end
end

objectHandlers.slider = function(self, parent, name, virtual, option, text, values)
	local slider = CreateFrame("Slider", name, parent, virtual or "OptionsSliderTemplate");
	local title, low, high = slider.Text, slider.Low, slider.High;
	local titleText, lowText, highText = splitString(text, colonSeparator);
	local minValue, maxValue, step = splitString(values, colonSeparator);

	minValue, maxValue, step = tonumber(minValue), tonumber(maxValue), tonumber(step);
	slider.title, slider.titleText, slider.object, slider.option = title, titleText, self, option;
	low:SetText(lowText or minValue);
	high:SetText(highText or maxValue);

	slider:SetMinMaxValues(minValue, maxValue);
	slider:SetValueStep(step);

	slider:SetValue(self:getDisplayValue(option) or (maxValue-minValue)/2);
	slider:SetScript("OnValueChanged", updateSliderValue);

	updateSliderText(slider);
	return slider;
end

-- Color Swatch
local function colorSwatchCancel()
	local self = ColorPickerFrame.object;
	local r, g, b = self.r or 1, self.g or 1, self.b or 1;
	local a = self.opacity or 1;
	local object, option = self.object, self.option;
	if (type(option) == "function") then
		-- some addons overload 'option' with a custom function to display different windows
		option = option();
	end
	local colors = object:getDisplayValue(option);
	if (colors) then
		colors[1], colors[2], colors[3] = r, g, b;
		colors[4] = a;
	end
	object:setOption(option, colors);
	self.normalTexture:SetVertexColor(r, g, b);
end

local function colorSwatchColor()
	local self = ColorPickerFrame.object;
	local r, g, b = ColorPickerFrame:GetColorRGB();
	local object, option = self.object, self.option;
	if (type(option) == "function") then
		-- some addons overload 'option' with a custom function to display different windows
		option = option();
	end
	local colors = object:getDisplayValue(option);
	if (colors) then
		colors[1], colors[2], colors[3] = r, g, b;
	else
		colors = {r, g, b, 1}
	end
	object:setOption(option, colors);
	self.normalTexture:SetVertexColor(r, g, b);
end

local function colorSwatchOpacity()
	local self = ColorPickerFrame.object;
	local a = OpacitySliderFrame:GetValue();
	local object, option = self.object, self.option;
	if (type(option) == "function") then
		-- some addons overload 'option' with a custom function to display different windows
		option = option();
	end
	local colors = object:getDisplayValue(option) or {self.r, self.g, self.b};
	colors[4] = a;
	object:setOption(option, colors);
end

local function colorSwatchShow(self)
	local r, g, b, a;
	local object, option = self.object, self.option;
	if (type(option) == "function") then
		-- some addons overload 'option' with a custom function to display different windows
		option = option();
	end
	local color = object:getDisplayValue(option);
	if ( color ) then
		r, g, b, a = unpack(color);
	elseif (self:GetNormalTexture()) then
		r, g, b, a = self:GetNormalTexture():GetVertexColor();
	else
		r, g, b, a = 1, 1, 1, 1;
	end

	self.r, self.g, self.b, self.opacity = r, g, b, a or 1;
	self.opacityFunc = colorSwatchOpacity;
	self.swatchFunc = colorSwatchColor;
	self.cancelFunc = colorSwatchCancel;
	self.hasOpacity = self.hasAlpha;

	ColorPickerFrame.object = self;
	UIDropDownMenuButton_OpenColorPicker(self);
	ColorPickerFrame:SetFrameStrata("TOOLTIP");
	ColorPickerFrame:Raise();
end

local function colorSwatchOnClick(self)
	CloseMenus();
	colorSwatchShow(self);
end

local function colorSwatchOnEnter(self)
	self.bg:SetVertexColor(1, 0.82, 0);
end

local function colorSwatchOnLeave(self)
	self.bg:SetVertexColor(1, 1, 1);
end

objectHandlers.colorswatch = function(self, parent, name, virtual, option, alpha)
	local swatch = CreateFrame("Button", name, parent, virtual);
	local bg = swatch:CreateTexture(nil, "BACKGROUND");
	local normalTexture = swatch:CreateTexture(nil, "ARTWORK");

	normalTexture:SetTexture("Interface\\ChatFrame\\ChatFrameColorSwatch");
	normalTexture:SetAllPoints(swatch);
	swatch:SetNormalTexture(normalTexture);
	bg:SetColorTexture(1, 1, 1);
	bg:SetPoint("TOPLEFT", swatch, 1, -1);
	bg:SetPoint("BOTTOMRIGHT", swatch, 0, 1);

	local color = self:getDisplayValue(option);
	if ( color ) then
		normalTexture:SetVertexColor(color[1], color[2], color[3]);
	end

	swatch.bg, swatch.normalTexture = bg, normalTexture;
	swatch.object, swatch.option, swatch.hasAlpha = self, option, alpha;

	swatch:SetScript("OnLeave", colorSwatchOnLeave);
	swatch:SetScript("OnEnter", colorSwatchOnEnter);
	swatch:SetScript("OnClick", colorSwatchOnClick);
	return swatch;
end

-- Set an anchor based on frame and anchor string
local function setAnchor(frame, str)
	local rel, pt, xoff, yoff, relpt = "";
	local tmpVal, found;

	for key, value in iterator(str, colonMatch) do
		-- Offsets
		if ( not yoff ) then
			tmpVal = tonumber(value);
			if ( tmpVal ) then
				if ( xoff ) then
					yoff = tmpVal;
				else
					xoff = tmpVal;
				end
				found = true;
			end
		end

		-- Points
		if ( not found and not relpt ) then
			tmpVal = points[value];
			if ( tmpVal ) then
				if ( not pt ) then
					pt = tmpVal;
				else
					relpt = tmpVal;
				end
				found = true;
			end
		end

		-- Relative object
		if ( not found ) then
			rel = value;
		end
		found = nil;
	end

	if ( not relpt ) then
		relpt = pt;
	end

	local parent = frame:GetParent();
	if ( pt == "all" ) then
		frame:SetAllPoints( ( parent and parent[rel] ) or _G[rel] or parent);
	else
		frame:SetPoint(pt, ( parent and parent[rel] ) or _G[rel] or parent, relpt, xoff, yoff);
	end
end

-- Sets a few predefined attributes; abstracted for easier caching
local function setAttributes(self, parent, frame, identifier, option, global, strata, width, height, movable, clamped, hidden, anch1, anch2, anch3, anch4)

	-- Object
	frame.object = self;

	-- Parent
	frame.parent = parent;

	-- Identifier
	if ( identifier ) then

		if ( parent ) then
			parent[identifier] = frame;
		end

		if ( tonumber(identifier) ) then
			local setID = frame.SetID;
			if ( setID ) then
				setID(frame, identifier);
			end
		end
	end

	-- Option
	frame.option = option;
	frame.global = global;

	-- Strata
	if ( strata ) then
		frame:SetFrameStrata(strata);
	end

	-- Width & Height
	if ( width ) then
		frame:SetWidth(width);
		frame:SetHeight(height);
	end

	-- Movable
	if ( movable ) then
		frame:SetMovable(true);
	end

	-- Clamped
	if ( clamped ) then
		frame:SetClampedToScreen(true);
	end

	-- Hidden
	if ( hidden ) then
		frame:Hide();
	end

	-- Anchors
	if ( anch1 ) then
		frame:ClearAllPoints();
		setAnchor(frame, anch1);
		if ( anch2 ) then
			setAnchor(frame, anch2);
			if ( anch3 ) then
				setAnchor(frame, anch3);
				if ( anch4 ) then
					setAnchor(frame, anch4);
				end
			end
		end
	end
end

-- Converts a string value to proper lua values
local getConversionTable;
local function convertValue(str)
	if ( not str ) then
		return;
	elseif ( str == "true" ) then
		return true;
	elseif ( str == "false" ) then
		return false;
	elseif ( strlen(str) > 0 ) then
		local tmp = tonumber(str);
		if ( not tmp ) then
			return getConversionTable(splitString(str, commaSeparator));
		end
		return tmp;
	else
		return "";
	end
end

-- Takes a bunch of values, converts them and stores them in a table
getConversionTable = function(...) -- local (see declaration above convertValue)
	local num = select('#', ...);
	if ( num > 1 ) then
		local tbl = { };
		for i = 1, num, 1 do
			tinsert(tbl, convertValue(select(i, ...)));
		end
		return tbl;
	end
	return ...;
end

-- General object handler for doing the most basic work
local specialAttributes = { };
local function generalObjectHandler(self, specializedHandler, str, parent, initialValue, overrideName)
	-- See if we have this cached
	if ( frameCache[str] ) then
		return frameCache[str]();
	end

	-- Make sure we don't have any saved attributes from before
	lib:clearTable(specialAttributes);

	-- Parse the things we want first of all
	-- Any object handler can have up to 6 special, object-specific attributes
	local identifier, name, explicitParent, option, defaultValue, strata, width,
		height, movable, clamped, hidden, cache, virtual, localInherit;
	local anch1, anch2, anch3, anch4, specFound;
	local found;
	for key, value in iterator(str, numberMatch) do

		-- Movable
		if ( value == "movable" ) then
			movable = true;
		-- Clamped
		elseif ( value == "clamped" ) then
			clamped = true;
		-- Hidden
		elseif ( value == "hidden" ) then
			hidden = true;
		-- Cache
		elseif ( value == "cache" ) then
			cache = true;
		else
			-- Identifier
			if ( not found and not identifier ) then
				local i, id = splitString(value, colonSeparator);
				if ( i == "i" and id ) then
					identifier = id;
					found = true;
				end
			end

			-- Option
			if ( not found and not option ) then
				local o, opt, def, glb = splitString(value, colonSeparator);
				if ( o == "o" and opt ) then
					option = opt;
					if ( def ) then
						defaultValue = convertValue(def);
					end
					found = true;
				end
			end

			-- Strata
			if ( not found and not strata ) then
				local st, strta = splitString(value, colonSeparator);
				if ( st == "st" and strta ) then
					strata = strta;
					found = true;
				end
			end

			-- Virtual (inherit)
			if ( not found and not virtual ) then
				local v, inherit = splitString(value, colonSeparator);
				if ( v == "v" and inherit ) then
					virtual = inherit;
					found = true;
				end
			end

			-- Local Virtual (inherit from table)
			if ( not found and not localInherit ) then
				local li, inherit = splitString(value, colonSeparator);
				if ( li == "li" and inherit ) then
					localInherit = inherit;
					found = true;
				end
			end

			-- Name
			if ( not found and not name ) then
				local n, frameName = splitString(value, colonSeparator);
				if ( n == "n" and frameName ) then
					name = frameName;
					found = true;
				end
			end

			-- Parent
			if ( not found and not explicitParent ) then
				local p, parentName = splitString(value, colonSeparator);
				if ( p == "p" and parentName ) then
					if ( parentName == "nil" ) then
						explicitParent = "nil";
					else
						explicitParent = _G[parentName];
					end
					found = true;
				end
			end

			-- Width & Height
			if ( not found and not width ) then
				local s, w, h = splitString(value, colonSeparator);
				w, h = tonumber(w), tonumber(h);
				if ( s == "s" and w and h ) then
					width, height = w, h;
					found = true;
				end
			end

			-- Anchors
			if ( not found and not anch4 and not specFound ) then
				local a = splitString(value, colonSeparator) or value;
				if ( points[a] ) then
					if ( not anch1 ) then
						anch1 = value;
					elseif ( not anch2 ) then
						anch2 = value;
					elseif ( not anch3 ) then
						anch3 = value;
					elseif ( not anch4 ) then
						anch4 = value;
					end
					found = true;
				end
			end

			-- Special attributes
			if ( not found ) then
				tinsert(specialAttributes, value);
				specFound = true;
			end
		end
		found = nil;
	end

	-- Make sure we have valid values
	if ( explicitParent == "nil" ) then
		parent = nil;
	else
		parent = explicitParent or parent or UIParent;
	end

	-- Check override name
	if (overrideName or name) then
		name = overrideName or name;
	elseif (identifier and parent and parent ~= UIParent) then
		name = (parent:GetName() or "") .. identifier;
	else
		name = identifier or option;
	end
	
	-- Ensure at least one valid anchor
	anch1 = anch1 or "mid";

	-- Set default value
	if ( option and defaultValue ) then
		defaultDisplayValues[self][option] = defaultValue;
	end

	-- Create our frame
	local frame = specializedHandler(self, parent, name, virtual, option, unpack(specialAttributes));

	-- Grab any local inherits
	if ( localInherit ) then
		lib:getFrame(initialValue[localInherit], frame);
	end

	if ( not frame ) then
		-- Return if we don't have a frame - useful for backdrops etc.
		return;

	elseif ( cache ) then
		-- Cache if requested
		local cacheAttributes = {};
		for k, v in ipairs(specialAttributes) do
			tinsert(cacheAttributes, v);
		end
		local cacheFunc = function()
			local frame = specializedHandler(self, parent, name, virtual, option, unpack(cacheAttributes));
			if ( localInherit ) then
				lib:getFrame(initialValue[localInherit], frame);
			end
			setAttributes(self, parent, frame, identifier, option, global, strata, width, height, movable, clamped, hidden, anch1, anch2, anch3, anch4);
			return frame;
		end
		frameCache[str] = cacheFunc;
	end

	-- Apply our attributes
	setAttributes(self, parent, frame, identifier, option, global, strata, width, height, movable, clamped, hidden, anch1, anch2, anch3, anch4);

	return frame;

end

-- Parse attributes from a string
local function parseStringAttributes(self, str, parent, initialValue, overrideName)
	local objectType, remStr = strmatch(str, numberMatch);
	local handler = objectHandlers[objectType or str];
	if ( handler ) then
		return generalObjectHandler(self, handler, remStr, parent, initialValue, overrideName);
	end
end

local function getFrame(self, value, origParent, initialValue, overrideName)
	local parent = origParent;
	local valueType = type(value);
	if ( valueType == "function" ) then
		-- We have a function; parse its two return values instead
		local key, val = value();
		parent = parseStringAttributes(self, key, parent, val, overrideName);
		if ( parent ) then
			getFrame(self, val, parent, val);
		end
		return parent;
	elseif ( valueType == "table" ) then
		-- We have a table, iterate through it
		local lower;
		for key, value in pairs(value) do
			lower = strlower(key);
			if ( lower == "postclick" or lower == "preclick" or match(key, "^on") ) then
				if ( parent ) then
					parent:SetScript(key, value);
					if ( lower == "onload" ) then
						parent.execOnLoad = true;
					end
				end
			else
				local parent = parent;
				if ( tonumber(key) == nil ) then
					parent = parseStringAttributes(self, key, parent, initialValue, overrideName);
				end
				getFrame(self, value, parent, initialValue);
			end
		end
	elseif ( valueType == "string" ) then
		-- Parse it directly
		local found;
		for key, val in iterator(value, pipeMatch) do
			-- We have more than one value, parse each bit
			found = true;
			parseStringAttributes(self, val, parent, initialValue, overrideName);
		end
		if ( not found ) then
			-- We have only one value, parse it all at once
			parseStringAttributes(self, value, parent, initialValue, overrideName);
		end
		return parent;
	end

	-- Call any OnLoad/OnShow we might have after having recursed through all parents
	if ( parent ) then
		local getScript = parent.GetScript;
		if ( getScript ) then
--			local oldThis = this;
--			this = parent;
			local onLoad = getScript(parent, "OnLoad");
			if ( parent.execOnLoad and type(onLoad) == "function" ) then
				onLoad(parent);
			end

			if ( parent:IsVisible() ) then
				local onShow = getScript(parent, "OnShow");
				if ( type(onShow) == "function" ) then
					onShow(parent);
				end
			end
--			this = oldThis;
		end
		parent.execOnLoad = nil;
	end
	return parent;
end

function lib:getFrame(value, parent, name)
	return getFrame(self, value, parent, value, name);
end

-- Functions for building frames with object details strings.
-- These functions keep track of the yoffsets and the frame sizes.
--
-- These are not required, but they can make it easier for you
-- to reorganize the object details strings in your source code
-- without having to manually recalculate the yoffset values
-- and frame sizes, and then update each detail string.
--
-- By using the following macros, you can have certain values
-- inserted into object details strings:
-- %%s == size of the UI object or frame.
-- %%y == y offset of the top of the UI object or frame.
-- %%b == y offset below the UI object or frame.
--
-- 1) Call lib:framesInit() to get a table that will be passed to each of the other functions.
-- 2) Call the other functions as needed.
-- 3) Call lib:framesGetData() to get the final table of data to use.

function lib:framesInit()
	-- Initialize and return a table used with the other functions below.
	-- This should be the first function to be called.
	local framesList = {};

	-- Dummy frame representing a master frame.
	local frame = {};
	frame.offset = 0;
	frame.size = 0;
	frame.details = "";
	frame.yoffset = 0;
	frame.top = 0;
	frame.data = {};

	tinsert(framesList, frame);

	return framesList;
end

function lib:framesGetData(framesList)
	-- Get the frame data table.
	-- This should be the last function to be called.
	--
	-- framesList == Value returned from lib:framesInit() (required).
	--
	-- The frame.data table contains the data needed to build a set of frames.
	-- Each element's key is a details string used to build a frame.
	-- Each element's value is a table of details strings that will become children of the frame.
	if (#framesList > 1) then
		print(self.name .. ": framesEndFrame missing.");
	end
	local frame = framesList[#framesList];
	return frame.data;
end

function lib:framesAddFrame(framesList, offset, size, details, data)
	-- Begin and end adding a frame.
	self:framesBeginFrame(framesList, offset, size, details, data);
	self:framesEndFrame(framesList);
end

function lib:framesAddObject(framesList, offset, size, details)
	-- Add a UI object to the current frame.
	--
	-- framesList == Value returned from lib:framesInit() (required).
	-- offset == Offset relative to the previous frame or object (can be positive or negative) (required).
	-- size == Size of this object (required).
	-- details == Object details string used to build the object (required).
	local frame = framesList[#framesList];
	local yoffset = frame.yoffset + offset;

	details = gsub(details, "%%y", yoffset);
	details = gsub(details, "%%b", yoffset - size);
	details = gsub(details, "%%s", size);
	tinsert(frame.data, details);

	frame.yoffset = yoffset - size;
end

function lib:framesAddScript(framesList, name, func)
	-- Add a script to the current frame.
	--
	-- framesList == Value returned from lib:framesInit() (required).
	-- name == Script name (for example: "onload") (required).
	-- func == Function to call (required).
	local frame = framesList[#framesList];
	frame.data[name] = func;
end

function lib:framesBeginFrame(framesList, offset, size, details, data)
	-- Begin adding a frame.
	-- Remember to call lib:framesEndFrame() when you are finished adding items to the frame.
	--
	-- framesList == Value returned from lib:framesInit() (required).
	-- offset == Offset relative to the previous frame or object (can be positive or negative) (required).
	-- size == Size of this frame (0 == Size will be calculated during lib:framesEndFrame()) (required).
	-- details == Object details string used to build the frame (required).
	-- data == Table of object details strings that will become the children of the frame (optional).
	local yoffset;
	local prevFrame = framesList[#framesList];
	if (prevFrame) then
		yoffset = prevFrame.yoffset;
	else
		yoffset = 0;
	end
	yoffset = yoffset + offset;

	local frame = {};
	frame.offset = offset;
	frame.size = size;
	frame.details = details;
	frame.yoffset = 0;
	frame.top = yoffset;
	frame.data = data or {};

	tinsert(framesList, frame);
end

function lib:framesEndFrame(framesList)
	-- End adding a frame.
	--
	-- framesList == Value returned from lib:framesInit() (required).
	if (#framesList <= 1) then
		print(self.name .. ": framesEndFrame found with no matching framesBeginFrame.");
		return;
	end
	local frame = tremove(framesList);

	local size = frame.size;
	local top = frame.top;
	local below;
	if (size == 0) then
		below = top + frame.yoffset;
		size = top - below;
	else
		below = top - size;
	end

	local details = frame.details;

	details = gsub(details, "%%y", top);
	details = gsub(details, "%%b", below);
	details = gsub(details, "%%s", size);

	local prevFrame = framesList[#framesList];
	prevFrame.yoffset = below;
	prevFrame.data[details] = frame.data;
end

function lib:framesGetYOffset(framesList)
	local frame = framesList[#framesList];
	return frame.yoffset;
end


-- End Frame Creation
-----------------------------------------------

--------------------------------------------
-- AddOn Conflict Resolution

local addOnConflictResolutions = {}		-- A collection of private functions that other AddOns may trigger to resolve conflict with CTMod
local addOnConflictRequests = {}		-- A list of requests made by other AddOns for CTMod to execute private code to resolve conflict

-- Registers a CT Module's private function to be executed upon request by any AddOn.
-- The function will be called with parameters
function lib:registerConflictResolution(conflict, version, func)
	addOnConflictResolutions[conflict] = addOnConflictResolutions[conflict] or {};
	addOnConflictResolutions[conflict][version] = addOnConflictResolutions[conflict][version] or {};
	tinsert(addOnConflictResolutions[conflict][version], func);
	if (addOnConflictRequests[conflict] and addOnConflictRequests[conflict][version]) then
		func(unpack(addOnConflictRequests[conflict][version]));
	end
end

-- Public method that any AddOn may use to request CTMod to change its behaviour using a private function
-- Even if the private function does not exist, the request will be stored in memory and later applied should the private function be registered
-- Parameters
--	conflict	String, Required		Descriptive name of a particular conflict that needs resolving
--	version		String or Number, Required	Future-proofs this conflict resolution, by allowing for code changes to be called up using a different version parameter
--	...		Any Type, Optional		Anything that should be passed to the private function, such as objects to manipulate or a callback function
function libPublic:requestAddOnConflictResolution(conflict, version, ...)
	assert(type(conflict) == "string", "An AddOn asked CTMod to resolve a conflict, but did not provide a string as the name of the conflict")
	assert(version, "An AddOn asked CTMod to resolve a conflict, but did not provide a version number to ensure future-proofing of this AddOn conflict resolution")
	if (addOnConflictResolutions[conflict] and addOnConflictResolutions[conflict][version]) then
		for __, func in ipairs(addOnConflictResolutions[conflict][version]) do
			func(...);
		end
	end
	addOnConflictRequests[conflict] = addOnConflictRequests[conflict] or {};
	addOnConflictRequests[conflict][version] = {...}
end


-- End AddOn Conflict Resolution
-----------------------------------------------


-----------------------------------------------
-- Control Panel

local controlPanelFrame;
local selectedModule;
local previousModule;
local minWidth, minHeight, maxWidth, maxHeight = 300, 30, 635, 495;

-- Resizes the frame smoothly
local function resizer(self, elapsed)
	if (self.height > minHeight and self.isMinimized) then
		local newHeight = max(self.height + (minHeight-maxHeight)/0.4*elapsed, minHeight);
		self:SetHeight(newHeight);
		self.height = newHeight;
	elseif (self.height < maxHeight and not self.isMinimized) then
		local newHeight = min(self.height + (maxHeight-minHeight)/0.4*elapsed, maxHeight);
		self:SetHeight(newHeight);
		self.height = newHeight;		
	elseif (self.options and self.options:IsShown() and self.width < maxWidth) then
		local newWidth = min(self.width + (maxWidth-minWidth)/0.4*elapsed, maxWidth);
		self:SetWidth(newWidth);
		self.width = newWidth;
	elseif (self.options and self.options:IsShown() and self.alpha < 1 and not self.isMinimized) then
		local newAlpha = min(self.alpha + 5 * elapsed, 1); -- Set to 100% opacity over 0.2 sec
		self.options:SetAlpha(newAlpha);
		self.alpha = newAlpha;
	else
		-- We're done, disable the function
		self:SetScript("OnUpdate", nil);
	end
end

local function selectControlPanelModule(self)
	local parent = self.parent;
	local newModule = self:GetID()-700;  		 --700 is an offset to prevent taint affecting battleground queueing
	PlaySound(1115);

	local module = modules[newModule];
	local optionsFrame = module.frame;
	local isExternal = module.external;

	if ( not module or not optionsFrame ) then
		return;
	end

	if ( not isExternal ) then
		-- Highlight the correct bullet
		self.bullet:SetVertexColor(1, 0, 0);
		local obj, module;
		local num = 700;			--700 is an offset to prevent taint affecting battleground queueing
		for key, value in ipairs(modules) do
			if ( value.frame ) then
				num = num + 1;
				obj = parent[tostring(num)];
				if ( obj ~= self ) then
					if ( value.external ) then
						obj.bullet:SetVertexColor(1, 0.41, 0);
					else
						obj.bullet:SetVertexColor(1, 0.82, 0);
					end
				end
			end
		end
	end

	local frameType = type(optionsFrame);
	local options = controlPanelFrame.options;

	-- Check if this is a function. If so, parse it.
	if ( frameType == "function" ) then
		if ( not isExternal ) then
			optionsFrame = module:getFrame(optionsFrame, options.scrollchild);
			options.scroll:UpdateScrollChildRect();
			module.frame = optionsFrame;
			if ( selectedModule ) then
				optionsFrame:Hide(); -- To call the OnShow/OnHide methods in proper order
			end
		else
			optionsFrame = module:getFrame(optionsFrame, UIParent);
			module.frame = optionsFrame;
		end
	elseif ( frameType == "string" ) then
		optionsFrame = _G[optionsFrame];
	end

	parent = parent.parent;
	local title = module.displayName or module.name;
	if ( not selectedModule ) then
		-- First selection, resize the window smoothly
		if ( not isExternal ) then
			parent.width = 300;
			parent.alpha = 0;
			parent:SetScript("OnUpdate", resizer);

			local options = parent.options;
			options:SetAlpha(0);
			options:Show();
			options.title:SetText(title);
		end
	elseif ( not isExternal ) then
		parent.options.title:SetText(title);
		-- Hide the current frame
		local frame = parent.selectedModuleFrame;
		if ( frame ) then
			frame:Hide();
		end
	end

	optionsFrame:Show();
	if ( not isExternal ) then
		parent.selectedModuleFrame = optionsFrame;
		options.scroll:UpdateScrollChildRect();
		selectedModule = newModule;
		-- Reset options window scrollbar thumb position when user selects a different module.
		if (previousModule ~= selectedModule) then
			local scrollbar = _G[options.scroll:GetName().."ScrollBar"];
			scrollbar:SetValue(0);
			previousModule = selectedModule;
		end
	else
		optionsFrame:Raise();
		controlPanelFrame:Hide();
	end
end

local function controlPanelSkeleton()
	local modListButtonTemplate = {
		"font#i:text#v:ChatFontNormal#l:16:0",
		"font#i:version#l:r:-57:0##0.65:0.65:0.65",
		"texture#i:bullet#l:2:-1#s:7:7#1:1:1",
		["onload"] = function(self)
			self.bullet:SetVertexColor(1, 0.82, 0);
			self:SetFontString(self.text);
		end,
		["onenter"] = function(self)
			local hover = self.parent.hover;
			hover:ClearAllPoints();
			hover:SetPoint("RIGHT", self);
			hover:Show();
		end,
		["onleave"] = function(self)
			self.parent.hover:Hide();
		end,
		["onclick"] = selectControlPanelModule,
	};
	return "frame#st:DIALOG#n:CTCONTROLPANEL#clamped#movable#t:mid:0:400#s:300:495", {
		"backdrop#tooltip#0:0:0:0.80",
		["onshow"] = function(self)
			local module, obj;

			-- Prepare the frame
			local selectedModuleFrame = self.selectedModuleFrame;
			selectedModule = nil;
			
			self:SetWidth(300);
			self.options:Hide();
			self.selectedModuleFrame = nil;

			-- Show/Hide our bullets
			local listing = self.listing;
			local num = 700;		--700 is an offset to prevent taint affecting battleground queueing
			local version;
			for i = 1, #modules, 1 do
				module = modules[i];
				if ( module.frame ) then
					num = num + 1;
					version = module.version;
					obj = listing[tostring(num)];
					obj:SetID(num);
					obj:Show();			
					obj:SetText(module.displayName or module.name);
					
					if ( version and version ~= "" ) then
						obj.version:SetText("|c007F7F7Fv|r"..module.version);
					end
					if ( module.external ) then
						obj.bullet:SetVertexColor(1, 0.41, 0);
					else
						obj.bullet:SetVertexColor(1, 0.82, 0);
					end

					if ( num == 15 ) then
						break;
					end
				end
			end
			for i = num + 1, 715, 1 do
				listing[tostring(i)]:Hide();
			end
			PlaySound(1115);
			eventHandler(lib, "CONTROL_PANEL_VISIBILITY", true);
		end,
		["onhide"] = function(self)
			PlaySound(1115);
			local selectedModuleFrame = self.selectedModuleFrame;
			if ( selectedModuleFrame ) then
				selectedModuleFrame:Hide();
			end
			eventHandler(lib, "CONTROL_PANEL_VISIBILITY");
		end,
		["button#tl:4:-5#br:tr:-4:-25"] = {
			"font#tl#br:bl:296:0#CTMod Control Panel",
			"texture#i:bg#all#1:1:1:0.25#BACKGROUND",
			["button#tr:3:6#s:32:32#"] = {
				["onload"] = function(button)
					button:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up");
					button:SetDisabledTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up");
					button:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down");
					button:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight");
				end,
				["onclick"] = function()
					PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
					CTCONTROLPANEL:Hide();
				end,
			},
			["button#tr:-18:6#s:32:32#n:CTControlPanelMinimizeButton"] = {
				["onload"] = function(button)
					button:SetNormalTexture("Interface\\Buttons\\UI-Panel-SmallerButton-Up");
					button:SetDisabledTexture("Interface\\Buttons\\UI-Panel-SmallerButton-Up");
					button:SetPushedTexture("Interface\\Buttons\\UI-Panel-SmallerButton-Down");
					button:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight");
				end,
				["onclick"] = function(button)
					PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
					lib:toggleMinimizeControlPanel();
				end,
			},
			["onenter"] = function(self)
				lib:displayPredefinedTooltip(self, "DRAG");
				self.bg:SetVertexColor(1, 0.9, 0.5);
			end,
			["onleave"] = function(self)
				self.bg:SetVertexColor(1, 1, 1);
			end,
			["onmousedown"] = function(self, button)
				if ( button == "LeftButton" ) then
					self.parent:StartMoving();
				end
			end,
			["onmouseup"] = function(self, button)
				if ( button == "LeftButton" ) then
					self.parent:StopMovingOrSizing();
				elseif ( button == "RightButton" ) then
					local parent = self.parent;
					parent:ClearAllPoints();
					parent:SetPoint("CENTER", UIParent);
				end
			end,
		},
		["frame#s:300:0#tl:15:-30#b:0:15#i:listing"] = {
			"font#tl:-5:0#s:285:64#" .. L["CT_Library/Introduction"] .. "#t",
			"texture#tl:0:-64#br:tr:-25:-65#1:1:1",
			"font#tl:-3:-69#v:GameFontNormalLarge#" .. L["CT_Library/ModListing"],
			"texture#i:hover#l:5:0#s:290:25#hidden#1:1:1:0.125",
			"texture#i:select#l:5:0#s:290:25#hidden#1:1:1:0.25",
						--700 is an offset to prevent taint affecting battleground queueing
			["button#i:703#hidden#s:263:25#tl:17:-85"] = modListButtonTemplate,	
			["button#i:704#hidden#s:263:25#tl:17:-110"] = modListButtonTemplate,
			["button#i:705#hidden#s:263:25#tl:17:-135"] = modListButtonTemplate,
			["button#i:706#hidden#s:263:25#tl:17:-160"] = modListButtonTemplate,
			["button#i:707#hidden#s:263:25#tl:17:-185"] = modListButtonTemplate,
			["button#i:708#hidden#s:263:25#tl:17:-210"] = modListButtonTemplate,
			["button#i:709#hidden#s:263:25#tl:17:-235"] = modListButtonTemplate,
			["button#i:710#hidden#s:263:25#tl:17:-260"] = modListButtonTemplate,
			["button#i:711#hidden#s:263:25#tl:17:-285"] = modListButtonTemplate,
			["button#i:712#hidden#s:263:25#tl:17:-310"] = modListButtonTemplate,
			["button#i:713#hidden#s:263:25#tl:17:-335"] = modListButtonTemplate,
			["button#i:714#hidden#s:263:25#tl:17:-360"] = modListButtonTemplate,
			["button#i:715#hidden#s:263:25#tl:17:-385"] = modListButtonTemplate,
			["button#i:701#hidden#s:263:25#tl:17:-410"] = modListButtonTemplate, -- Settings Import, 701
			["button#i:702#hidden#s:263:25#tl:17:-435"] = modListButtonTemplate, -- Help, 702
		},
		["frame#s:315:0#tr:-15:-30#b:t:15:-480#i:options#hidden"] = {
			["onload"] = function(self)
				local child = CreateFrame("Frame", nil, self);
				child:SetPoint("TOPLEFT", self);
				child:SetWidth(300);
				child:SetHeight(450);
				self.scrollchild = child;

				local scroll = CreateFrame("ScrollFrame", "CT_LibraryOptionsScrollFrame", self, "UIPanelScrollFrameTemplate");
				scroll:SetPoint("TOPLEFT", self, 0, 4);
				scroll:SetPoint("BOTTOMRIGHT", self, -12, -10);
				scroll:SetScrollChild(child);
				self.scroll = scroll;

				local tex = scroll:CreateTexture(scroll:GetName() .. "Track", "BACKGROUND");
				tex:SetColorTexture(0, 0, 0, 0.3);
				tex:ClearAllPoints();
				tex:SetPoint("TOPLEFT", _G[scroll:GetName().."ScrollBar"], -1, 17);
				tex:SetPoint("BOTTOMRIGHT", _G[scroll:GetName().."ScrollBar"], 0, -17);
			end,
			"texture#tl:-5:0#br:bl:-4:0#1:1:1",
			"font#t:0:20#i:title",
		},
	};
end

local function maximizeControlPanel()
	controlPanelFrame.isMinimized = nil;
	controlPanelFrame:SetScript("OnUpdate", resizer);
	CTControlPanelMinimizeButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-SmallerButton-Up");
	CTControlPanelMinimizeButton:SetDisabledTexture("Interface\\Buttons\\UI-Panel-SmallerButton-Up");
	CTControlPanelMinimizeButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-SmallerButton-Down");
	CT_LibraryOptionsScrollFrameScrollBar:Show();
	CTCONTROLPANELlisting:Show();
	CT_LibraryOptionsScrollFrame:SetScale(1);
	CT_LibraryOptionsScrollFrame:SetAlpha(1);
end

local function minimizeControlPanel()
	controlPanelFrame.isMinimized = true;
	controlPanelFrame:SetScript("OnUpdate", resizer);
	controlPanelFrame:SetClipsChildren(true);
	CTControlPanelMinimizeButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-BiggerButton-Up");
	CTControlPanelMinimizeButton:SetDisabledTexture("Interface\\Buttons\\UI-Panel-BiggerButton-Up");
	CTControlPanelMinimizeButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-BiggerButton-Down");
	CT_LibraryOptionsScrollFrameScrollBar:Hide();
	CTCONTROLPANELlisting:Hide();
	CT_LibraryOptionsScrollFrame:SetScale(0.00001);
	CT_LibraryOptionsScrollFrame:SetAlpha(0);
end

local function displayControlPanel()
	if ( not controlPanelFrame ) then
		controlPanelFrame = lib:getFrame(controlPanelSkeleton);
		tinsert(UISpecialFrames, controlPanelFrame:GetName());
		controlPanelFrame.height = maxHeight;	-- tracking variables used by resizer()
		controlPanelFrame.width = minWidth;
		controlPanelFrame.alpha = 0;
	end
	maximizeControlPanel();
	controlPanelFrame:Show();
end

function libPublic:showControlPanel(show)
	if ( show == "toggle" ) then
		if ( controlPanelFrame and controlPanelFrame:IsVisible() ) then
			show = false;
		end
	end

	if ( show ~= false ) then
		displayControlPanel();
	elseif ( controlPanelFrame) then 
		controlPanelFrame:Hide();
	end
end

function libPublic:toggleMinimizeControlPanel()
	if (controlPanelFrame) then
		if (controlPanelFrame.isMinimized) then
			maximizeControlPanel();
		else
			minimizeControlPanel();
		end
	end
end

-- Show the CTMod control panel options for the specified addon name.
-- if useCustomFunction is true then an attempt will be made to open a module's custom options function instead
function libPublic:showModuleOptions(useCustomFunction)
	self:showControlPanel(true);
	if (not lib:IsControlPanelShown()) then	-- this might happen if the panel is forced off during combat
		return;
	end
	local listing = CTCONTROLPANEL.listing;
	local button;
	local num = 700;			--700 is an offset to prevent taint affecting battleground queueing

	-- First scans modules to find the right one
	-- If the module has a custom function, activates it if appropriate
	-- Otherwise, identifies the "button" that a user would normally click to open the module's options
	-- Then shows the control panel and simulates a click on that button
	
	if (useCustomFunction and self.customOpenFunction) then
		self:showControlPanel(false)
		self:customOpenFunction()
	else
		for i, v in ipairs(modules) do
			if (v.frame) then
				num = num + 1;
				if (self == v) then
					button = listing[tostring(num)];
					break;
				end
			end
		end

		if (button) then
			-- Click the addon's button to open the options
			button:Click();
		end
	end
end

function libPublic:IsControlPanelShown()
	return controlPanelFrame and controlPanelFrame:IsVisible()
end

function libPublic:IsModuleOptionTabSelected()
	return controlPanelFrame and controlPanelFrame.IsVisible() and selectedModule == self
end

-- We don't want multiple copies of the control panel slash commands
-- when we have multiple versions of CT_Library.
-- We need to search for and replace the existing slash commands from
-- earlier versions of CT_Library, with the ones for this version of
-- CT_Library.
-- If there were no existing slash commands that match, then these
-- new ones will get added.
lib:updateSlashCmd(displayControlPanel, "/ct", "/ctmod");

-- End Control Panel
-----------------------------------------------


-----------------------------------------------
-- Settings Import (1)

-- Initialization
local module = { };
module.name = "Settings Import"; -- this is changed to a localized string during the button's onLoad
module.version = "";
-- Register as module 1 only, since this will code will get executed once per different
-- version of CT_Library. We don't want multiple copies showing up in the
-- control panel.
registerModule(module, 1);

module:regEvent("PLAYER_LOGIN", function() module.displayName = "|cFFFFFFCC" .. L["CT_Library/SettingsImport/Heading"]; end);

local optionsFrame, addonsFrame, checkAllButton, fromChar;

-- Dropdown Handling
local importDropdownEntry, importFlaggedCharacters;
local importRealm, importSetPlayer;
local importRealm2;
local importPlayerCount;

local function populateAddonsList(char)
	local importButton, num, obj, options;
	local deleteButton;
	local numAddons;
	importButton = optionsFrame.importButton;
	deleteButton = optionsFrame.deleteButton;
	num = 0;
	for key, value in ipairs(modules) do
		if ( value ~= module ) then
			options = value.options;
			if ( options and options[char] ) then
				num = num + 1;
				obj = addonsFrame[tostring(num)];
				obj:Show();
				obj:SetChecked(false);
				obj.text:SetText(value.name);
			end
		end
	end

	numAddons = num;
	num = num + 1;

	-- Position action frame
	obj = optionsFrame.actions;
	obj:ClearAllPoints();
	obj:SetPoint("TOPLEFT", optionsFrame, "TOPLEFT", 0, -180 + (-20 * num));
	obj:SetWidth(300)
	obj:SetHeight(150)
	--obj:SetPoint("RIGHT", optionsFrame);
	obj:Show()

	-- Hide unused addon objects
	while ( true ) do
		obj = addonsFrame[tostring(num)];
		if ( not obj ) then
			break;
		end

		obj:Hide();
		num = num + 1;
	end

	fromChar = char;
	addonsFrame:Show();
	
	-- It is not permissible to import from yourself to yourself
	local actions = optionsFrame.actions;
	module:setOption("canImport", nil);
	module:setOption("canDelete", nil);
	module:setOption("canExport", nil);
	actions.confirmImport:SetChecked(false);
	actions.confirmDelete:SetChecked(false);
	actions.confirmExport:SetChecked(false);
	if (char == getCharKey()) then
		actions.confirmImport:Hide();
		actions.importNote:Hide();
		actions.importButton:Hide();
		actions.confirmExport:Show();
		actions.exportNote:Show();
		actions.exportButton:Show();
		actions.deleteNote:SetText(L["CT_Library/SettingsImport/Actions/DeleteSelfNote"]);
	else
		actions.confirmImport:Show();
		actions.importNote:Show();
		actions.importButton:Show();
		actions.confirmExport:Hide();
		actions.exportNote:Hide();
		actions.exportButton:Hide();
		actions.deleteNote:SetText(L["CT_Library/SettingsImport/Actions/DeleteOtherNote"]);
	end
	
	checkAllButton:SetChecked(false);

	return numAddons;
end

local function populateCharDropdownInit()
	local players = {};
	local name, realm, options;

	if ( not importDropdownEntry ) then
		importDropdownEntry = { };
		importFlaggedCharacters = { };
	else
		lib:clearTable(importDropdownEntry);
		lib:clearTable(importFlaggedCharacters);
	end

	for key, value in ipairs(modules) do
		options = value.options;
		if ( options ) then
			for k, v in pairs(options) do
				if ( not importFlaggedCharacters[k] ) then
					name, realm = k:match("^CHAR%-([^-]+)%-(.+)$");
					if ( name and realm and realm == importRealm ) then
						importFlaggedCharacters[k] = true;
						tinsert(players, k);
					end
				end
			end
		end
	end
	sort(players);

	importPlayerCount = 0;

	for key, value in ipairs(players) do
		name, realm = value:match("^CHAR%-([^-]+)%-(.+)$");
		if ( name and realm ) then
			if (value == getCharKey()) then
				importDropdownEntry.text = "|cffffff00" .. name;
			else
				importDropdownEntry.text = name;
			end
			importDropdownEntry.value = value;
			importDropdownEntry.checked = nil;
			importDropdownEntry.func = dropdownClick;
			UIDropDownMenu_AddButton(importDropdownEntry);

			importPlayerCount = importPlayerCount + 1;
		end
	end

	if (importSetPlayer) then
		if (importRealm) then
			local value = players[1];
			UIDropDownMenu_SetSelectedValue(CT_LibraryDropdown1, value);
			populateAddonsList(value);
		end
	end

	if (importPlayerCount == 0) then
		CT_LibraryDropdown1:Hide();
		CT_LibraryDropdown1Label:SetText("No characters found.");
	else
		CT_LibraryDropdown1:Show();
		CT_LibraryDropdown1Label:SetText("Character:");
	end
end

local function populateCharDropdown()
	UIDropDownMenu_Initialize(CT_LibraryDropdown1, populateCharDropdownInit);
end

local function populateServerDropdownInit()
	local servers = {};
	local serversort = {};
	local name, realm, options;
	local clipboardPanel;

	if ( not importDropdownEntry ) then
		importDropdownEntry = { };
		importFlaggedCharacters = { };
	else
		lib:clearTable(importDropdownEntry);
		lib:clearTable(importFlaggedCharacters);
	end

	for key, value in ipairs(modules) do
		options = value.options;
		if ( options ) then
			for k, v in pairs(options) do
				if ( not importFlaggedCharacters[k] ) then
					name, realm = k:match("^CHAR%-([^-]+)%-(.+)$");
					if ( name ) then
						importFlaggedCharacters[k] = true;
						if (not servers[realm]) then
							servers[realm] = 1;
						else
							servers[realm] = servers[realm] + 1;
						end
					end
				end
			end
		end
	end
	for k, v in pairs(servers) do
		tinsert(serversort, k);
	end
	sort(serversort);

	for key, value in ipairs(serversort) do
		importDropdownEntry.text = value .. " (" .. servers[value] .. ")";
		importDropdownEntry.value = value;
		importDropdownEntry.checked = nil;
		importDropdownEntry.func = dropdownClick;
		UIDropDownMenu_AddButton(importDropdownEntry);
	end

	importPlayerCount = 0;

	if (not importRealm) then
		local value = serversort[1];
		if (importRealm2) then
			value = importRealm2;
		end
		UIDropDownMenu_SetSelectedValue(CT_LibraryDropdown0, value);
		module:update("char", value);
		-- CT_LibraryDropdown1Label:Hide();
		-- CT_LibraryDropdown1:Hide();
	end

	if (#serversort == 0) then
		CT_LibraryDropdown0:Hide();
		CT_LibraryDropdown0Label:SetText("No servers found.");
	else
		CT_LibraryDropdown0:Show();
		CT_LibraryDropdown0Label:SetText("Server:");
	end
end

local function populateServerDropdown()
	UIDropDownMenu_Initialize(CT_LibraryDropdown0, populateServerDropdownInit);
end

local function hideAddonsList()
	local num, obj, options;

	optionsFrame.actions:Hide();

	num = 1;
	while ( true ) do
		obj = addonsFrame[tostring(num)];
		if ( not obj ) then
			break;
		end

		obj:Hide();
		num = num + 1;
	end
	addonsFrame:Hide();
end

local function addonIsChecked(name)
	local num, obj;
	num = 1;
	while ( true ) do
		obj = addonsFrame[tostring(num)];
		if ( not obj or not obj:IsVisible() ) then
			return false;
		end

		if ( obj.text:GetText() == name ) then
			return obj:GetChecked();
		end
		num = num + 1;
	end
end

local function clearUserSettings(key, addon)
	local options = addon.options[key];
	if ( options ) then
		lib:clearTable(options);
	end
end

local function import()
	if ( fromChar and not InCombatLockdown() ) then
		if (not module:getOption("canImport")) then
			return;
		end
		local charKey = getCharKey();
		local options, success;
		local fromOptions;

		for modnum, addon in ipairs(modules) do
			options = addon.options;
			if ( options and addon ~= module ) then
				fromOptions = options[fromChar];
				if ( fromOptions and addonIsChecked(addon.name) and module:getOption("canImport") ) then
					options["CHAR-Unknown- Interim Backup"] = fromChar ~= "CHAR-Unknown- Temporary Backup" and options[charKey] or nil
					options[charKey] = {};
					lib:copyTable(fromOptions, options[charKey]);
					success = true;
				end
			end
		end

		module:setOption("canImport", nil);

		if ( success ) then
			C_UI.Reload();
		else
			print(L["CT_Library/SettingsImport/NoAddonsSelected"]);
		end
	end
end

local function delete()
	if ( fromChar and not InCombatLockdown()) then
		if (not module:getOption("canDelete")) then
			return;
		end
		local options, success;
		local fromOptions;

		for modnum, addon in ipairs(modules) do
			options = addon.options;
			if ( options and addon ~= module ) then
				fromOptions = options[fromChar];
				if ( fromOptions and addonIsChecked(addon.name) and module:getOption("canDelete") ) then
					if (fromChar == getCharKey()) then
						options["CHAR-Unknown- Interim Backup"] = fromOptions;
					end
					options[fromChar] = nil;
					success = true;
				end
			end
		end

		module:setOption("canDelete", nil);

		if ( success ) then
			if (fromChar == getCharKey()) then
				C_UI.Reload();
			end
			local count;
			count = populateAddonsList(fromChar);
			if (count == 0) then
				-- No addons left for the character.
				importRealm = nil;
				importRealm2 = UIDropDownMenu_GetSelectedValue(CT_LibraryDropdown0);
				populateServerDropdown();
				importRealm2 = nil;
				if (importPlayerCount == 0) then
					-- No players with options left on the server.
					importRealm = nil;
					populateServerDropdown();
				end
			end
		else
			print(L["CT_Library/SettingsImport/NoAddonsSelected"]);
		end
	end
end

local function closeClipboardPanel()
	clipboardPanel:Hide()
	clipboardPanel.editBox:SetText("");
end

local function validateClipboard()
	local text = clipboardPanel.editBox:GetText();
	if (strlen(text) < 2) then
		clipboardPanel.warning:SetText("");
		clipboardPanel.acceptButton:Disable();
	elseif (lib:hash(text:sub(2))%64+38 ~= text:byte(1)) then
		clipboardPanel.warning:SetText(L["CT_Library/SettingsImport/Clipboard/ChecksumAlert"])
		clipboardPanel.warning:SetTextColor(0.9, 0.4, 0.4);
		clipboardPanel.acceptButton:Disable();
	else
		text = lib:decode256From64(text);
		text = lib:decompress(text);
		local importTable = lib:deserializeTable(text);
		if (importTable) then
			local warn, found;
			if (importTable.exportGameVersion ~= lib:getGameVersion(true)) then
				warn = true;
				clipboardPanel.warning:SetText(L["CT_Library/SettingsImport/Clipboard/GameVersionWarning"]);
				clipboardPanel.warning:SetTextColor(0.7, 0.7, 0.3);
			end
			for key, val in pairs(importTable) do
				local module = lib:getModule(key)
				if (module) then
					found = true;
					if (module.version ~= val.exportVersion and warn == nil) then
						warn = true;
						clipboardPanel.warning:SetText(L["CT_Library/SettingsImport/Clipboard/AddOnVersionWarning"]);
						clipboardPanel.warning:SetTextColor(0.7, 0.7, 0.3);
						
					end
				elseif (key ~= "exportGameVersion" and warn == nil) then
					warn = true;
					clipboardPanel.warning:SetText(L["CT_Library/SettingsImport/Clipboard/AddOnMissingWarning"]);
					clipboardPanel.warning:SetTextColor(0.7, 0.7, 0.3);
				end
			end
			if (found) then
				if (warn == nil) then
					clipboardPanel.warning:SetText(L["CT_Library/SettingsImport/Clipboard/StringValidMessage"]);
					clipboardPanel.warning:SetTextColor(0.4, 0.9, 0.4);
				end
				clipboardPanel.acceptButton:Enable();
				return importTable;
			else
				clipboardPanel.warning:SetText(L["CT_Library/SettingsImport/Clipboard/NoAddOnsAlert"]);
				clipboardPanel.warning:SetTextColor(0.9, 0.4, 0.4);
				clipboardPanel.acceptButton:Disable();
			end
		else
			clipboardPanel.warning:SetText(L["CT_Library/SettingsImport/Clipboard/FailureAlert"]);
			clipboardPanel.warning:SetTextColor(0.9, 0.4, 0.4);
			clipboardPanel.acceptButton:Disable();
		end
	end
end

local function copyFromClipboard()
	local importTable = validateClipboard();	-- returns nil if there is any reason to anticipate failure
	if (importTable) then
		for __, module in ipairs(modules) do
			if (module.options and module.name) then
				if (importTable[module.name]) then
					module.options["CHAR-Unknown- Import String"] = {};
					lib:copyTable(importTable[module.name], module.options["CHAR-Unknown- Import String"]);
				else
					module.options["CHAR-Unknown- Import String"] = nil
				end
			end
		end
		importRealm = " Import String";
		module:setOption("char", "CHAR-Unknown- Import String");
		UIDropDownMenu_SetText(CT_LibraryDropdown0, " Import String (1)");
		UIDropDownMenu_SetText(CT_LibraryDropdown1, "Unknown");
		closeClipboardPanel();
	end
end

local function openClipboardPanel(text)
	if (not clipboardPanel) then
		clipboardPanel = CreateFrame("Frame", nil, CTCONTROLPANEL, "UIPanelDialogTemplate");
		clipboardPanel:SetFrameLevel("10");
		clipboardPanel:SetSize(400, 200);
		clipboardPanel:SetPoint("CENTER", UIParent);
		clipboardPanel:EnableMouse(true);
		
		clipboardPanel.label = clipboardPanel:CreateFontString(nil, "ARTWORK", "ChatFontNormal");
		clipboardPanel.label:SetPoint("TOP", 0, -40);
		
		clipboardPanel.warning = clipboardPanel:CreateFontString(nil, "ARTWORK", "ChatFontNormal");
		clipboardPanel.warning:SetPoint("BOTTOM", 0, 60);
		
		clipboardPanel.acceptButton = CreateFrame("Button", nil, clipboardPanel, "UIPanelButtonTemplate");
		clipboardPanel.acceptButton:SetText(CONTINUE);  -- GlobalStrings.lua
		clipboardPanel.acceptButton:SetSize(120, 30);
		clipboardPanel.acceptButton:SetPoint("BOTTOMRIGHT", clipboardPanel, "BOTTOM", -27, 20);
		clipboardPanel.acceptButton:HookScript("OnClick", copyFromClipboard);
		clipboardPanel.acceptButton:HookScript("OnEnter", function()
			lib:displayTooltip(clipboardPanel.acceptButton, {CONTINUE, L["CT_Library/SettingsImport/Clipboard/AcceptTip"]}, "CT_ABOVEBELOW", 0, 0, clipboardPanel);
		end);
		
		clipboardPanel.cancelButton = CreateFrame("Button", nil, clipboardPanel, "UIPanelButtonTemplate");
		clipboardPanel.cancelButton:SetText(CANCEL);  -- GlobalStrings.lua
		clipboardPanel.cancelButton:SetSize(120, 30);
		clipboardPanel.cancelButton:SetPoint("BOTTOMLEFT", clipboardPanel, "BOTTOM", 27, 20);
		clipboardPanel.cancelButton:HookScript("OnClick", closeClipboardPanel);
		
		clipboardPanel.editBox = CreateFrame("EditBox", nil, clipboardPanel, "InputBoxTemplate");
		clipboardPanel.editBox:SetSize(300, 50);
		clipboardPanel.editBox:SetPoint("CENTER");
		clipboardPanel.editBox:SetScript("OnEscapePressed", closeClipboardPanel);
		clipboardPanel.editBox:SetScript("OnHide", closeClipboardPanel);
		-- OnTextChanged and OnEnterPressed are set dynamically
		
	end
	clipboardPanel:Show();
	actions.confirmImport:SetChecked(false);
	actions.confirmDelete:SetChecked(false);
	actions.confirmExport:SetChecked(false);
	module:setOption("canImport", nil);
	module:setOption("canDelete", nil);
	module:setOption("canExport", nil);
	if (type(text) == "string") then
		clipboardPanel.editBox:SetScript("OnTextChanged", nil);
		clipboardPanel.editBox:SetScript("OnEnterPressed", closeClipboardPanel);
		clipboardPanel.editBox:SetText(text);
		clipboardPanel.acceptButton:Hide();
		clipboardPanel.warning:Hide();
		clipboardPanel.label:SetText("Copy the entire string below.|n|cffffff00Warning: it might be possible to identify you from your settings.");
		clipboardPanel.cancelButton:SetText("Close");
		
	else
		clipboardPanel.editBox:SetScript("OnTextChanged", validateClipboard);
		clipboardPanel.editBox:SetScript("OnEnterPressed", copyFromClipboard );
		clipboardPanel.editBox:SetText("");
		clipboardPanel.acceptButton:Show();
		clipboardPanel.warning:Show();
		clipboardPanel.label:SetText("Paste the entire string below.|n|cffffff00This is a beta feature; use at own risk.");
		clipboardPanel.cancelButton:SetText("Cancel");
	end
end

local function export(self)
	-- STEP 1: Serialize each 
	if ( fromChar ) then
		if (not module:getOption("canExport")) then
			return;
		end
	
		local options, success;
		local exportOptions = {["exportGameVersion"] = lib:getGameVersion(true)};
		local fromOptions;

		for modnum, addon in ipairs(modules) do
			if ( addon ~= module and addon.options and addon.name and addon.version) then
				fromOptions = addon.options[fromChar];
				if ( fromOptions and addonIsChecked(addon.name) and module:getOption("canExport") ) then
					exportOptions[addon.name] = {["exportVersion"] = addon.version}
					lib:copyTable(fromOptions, exportOptions[addon.name])
					success = true;
				end
			end
		end

		module:setOption("canExport", nil);

		if ( not success ) then
			print(L["CT_Library/SettingsImport/NoAddonsSelected"]);
			return;
		end

		local text = lib:serializeTable(exportOptions);
		text = lib:compress(text);
		text = lib:encode256To64(text);
		
		if (text) then
			openClipboardPanel(text)
		else
			print("Sorry, something has gone wrong.")
		end
	end
end

module.update = function(self, type, value)
	if ( type == "char" and value ) then
		local name, realm = value:match("^CHAR%-([^-]+)%-(.+)$");
		if (name and realm) then
			self:setOption("char", nil);
			populateAddonsList(value);
		else
			-- Server drop down
			importRealm = value;
			hideAddonsList();
			self:setOption("char", nil);
			-- Re initialize character pull down so it only has players from selected server.
			importSetPlayer = 1;
			populateCharDropdown();
			importSetPlayer = nil;
			CT_LibraryDropdown1Label:Show();
			CT_LibraryDropdown1:Show();
		end
	elseif (type == "canDelete") then
		local actions = optionsFrame.actions;
		if (value) then
			actions.deleteButton:Enable();
			actions.confirmImport:SetChecked(false);
			actions.confirmExport:SetChecked(false);
			module:setOption("canImport", nil);
			module:setOption("canExport", nil);
		else
			actions.deleteButton:Disable();
		end
		actions.confirmDelete:SetChecked(value);
	elseif (type == "canImport") then
		local actions = optionsFrame.actions;
		if (value) then
			actions.importButton:Enable();
			actions.confirmDelete:SetChecked(false);
			actions.confirmExport:SetChecked(false);
			module:setOption("canDelete", nil);
			module:setOption("canExport", nil);
		else
			actions.importButton:Disable();
		end
		actions.confirmImport:SetChecked(value);
	elseif (type == "canExport") then
		local actions = optionsFrame.actions;
		if (value) then
			actions.exportButton:Enable()
			actions.confirmImport:SetChecked(false);
			actions.confirmDelete:SetChecked(false);
			module:setOption("canImport", nil);
			module:setOption("canDelete", nil);
		else
			actions.exportButton:Disable();
		end
	end
end

module.frame = function()
	local addonsTable = { };
	local optionsTable = {
		"font#tl:5:-5#v:GameFontNormalLarge#" .. L["CT_Library/SettingsImport/Profiles/Heading"],
	
		"font#tl:20:-30#v:GameFontNormal#" .. L["CT_Library/SettingsImport/Profiles/InternalSubHeading"],
		"font#tl:40:-50#n:CT_LibraryDropdown0Label#v:ChatFontNormal#" .. L["CT_Library/SettingsImport/Profiles/InternalServerLabel"],
		"dropdown#s:155:20#tl:100:-51#o:char#n:CT_LibraryDropdown0#i:serverDropdown",

		"font#tl:40:-75#n:CT_LibraryDropdown1Label#v:ChatFontNormal#" .. L["CT_Library/SettingsImport/Profiles/InternalCharacterLabel"],
		"dropdown#s:155:20#tl:100:-76#o:char#n:CT_LibraryDropdown1#i:charDropdown",

		"font#tl:20:-100#v:GameFontNormal#" .. L["CT_Library/SettingsImport/Profiles/ExternalSubHeading"],
		["button#t:0:-120#s:150:20#v:UIPanelButtonTemplate#" .. L["CT_Library/SettingsImport/Profiles/ExternalButton"]] = {
			["onclick"] = openClipboardPanel,
			["onenter"] = function(button)
				lib:displayTooltip(button, {L["CT_Library/SettingsImport/Profiles/ExternalButton"],L["CT_Library/SettingsImport/Profiles/ExternalButtonTip"] .. "#0.9:0.9:0.9"},"CT_ABOVEBELOW", 0, 0, CTCONTROLPANEL);
			end,
		},

		["onload"] = function(self)
			optionsFrame, addonsFrame = self, self.addons;

			populateServerDropdown();
			populateCharDropdown();

			module:setOption("canImport", nil);
			module:setOption("canDelete", nil);
			module:setOption("canExport", nil);
		end,

		["checkbutton#tl:24:-170#s:18:18#i:checkAllButton#Select all"] = {
			["onclick"] = function(button)
				local num = 1
				while (addonsFrame[tostring(num)]) do
					if (addonsFrame[tostring(num)]:IsShown()) then
						addonsFrame[tostring(num)]:SetChecked(button:GetChecked())
					end
					num = num + 1
				end
			end,
			["onload"] = function(button)
				checkAllButton = button;
				button:SetAlpha(0.75);
				button.text:SetFontObject(GameFontNormalSmall)
			end,
		},
		
		["frame#tl:0:-150#r#i:addons#hidden"] = addonsTable,

		["frame#i:actions#hidden"] = {
			"font#tl:5:0#i:title#v:GameFontNormalLarge#" .. L["CT_Library/SettingsImport/Actions/Heading"],

			"checkbutton#tl:20:-25#i:confirmImport#s:25:25#o:canImport#I want to IMPORT the selected settings.",
			"font#t:0:-45#i:importNote#s:0:20#l#r#" .. L["CT_Library/SettingsImport/Actions/ImportNote"] .. "#0.5:0.5:0.5",
			["button#t:0:-65#s:155:30#i:importButton#v:UIPanelButtonTemplate#Import Settings"] = {
				["onclick"] = import,
				["onenter"] = function(self)
					self:GetParent().importNote:SetTextColor(0.7, 0.7, 0.3);
				end,
				["onleave"] = function(self)
					self:GetParent().importNote:SetTextColor(0.5, 0.5, 0.5);
				end,
			},
			

			"checkbutton#tl:20:-105#i:confirmDelete#s:25:25#o:canDelete#I want to DELETE the selected settings.",
			"font#t:0:-125#i:deleteNote#s:0:20#l#r##0.5:0.5:0.5",
			["button#t:0:-145#s:155:30#i:deleteButton#v:UIPanelButtonTemplate#Delete Settings"] = {
				["onclick"] = delete,
				["onenter"] = function(self)
					self:GetParent().deleteNote:SetTextColor(0.9, 0.4, 0.4);
				end,
				["onleave"] = function(self)
					self:GetParent().deleteNote:SetTextColor(0.5, 0.5, 0.5);
				end,
			},
			
			
			"checkbutton#tl:20:-25#i:confirmExport#s:25:25#o:canExport#I want to EXPORT the selected settings.#hidden",
			"font#t:0:-45#i:exportNote#s:0:20#l#r#" .. L["CT_Library/SettingsImport/Actions/ExportNote"] .. "#0.5:0.5:0.5#hidden",
			["button#t:0:-65#s:155:30#i:exportButton#v:UIPanelButtonTemplate#Generate String#hidden"] = {
				["onclick"] = export,
				["onenter"] = function(self)
					self:GetParent().exportNote:SetTextColor(0.7, 0.7, 0.3);
				end,
				["onleave"] = function(self)
					self:GetParent().exportNote:SetTextColor(0.5, 0.5, 0.5);
				end,
			},
			
		},
	};

	-- Fill in our addons table
	tinsert(addonsTable, "font#tl:5:0#v:GameFontNormalLarge#" .. L["CT_Library/SettingsImport/AddOns/Heading"]);
	
	-- Populate with addons
	local num = 0;
	for key, value in ipairs(modules) do
		if ( value ~= module and value.options ) then
			num = num + 1;
			tinsert(addonsTable, "checkbutton#i:"..num.."#tl:20:-"..((num+1)  * 20));
		end
	end

	return "frame#all", optionsTable;
end


-----------------------------------------------
-- Help (2)

-- Initialization
local module = { };
module.name = "Help";
module.version = LIBRARY_VERSION;
-- Register as module 2 only, since this will code will get executed once per different
-- version of CT_Library. We don't want multiple copies showing up in the
-- control panel.
registerModule(module, 2);

module:regEvent("PLAYER_LOGIN", function() module.displayName = "|cFFFFFFCC" .. L["CT_Library/Help/Heading"]; end);

local helpFrameList;
local function helpInit()
	optionsFrameList = module:framesInit();
end
local function helpGetData()
	return module:framesGetData(optionsFrameList);
end
local function helpAddFrame(offset, size, details, data)
	module:framesAddFrame(optionsFrameList, offset, size, details, data);
end
local function helpAddObject(offset, size, details)
	module:framesAddObject(optionsFrameList, offset, size, details);
end
local function helpAddScript(name, func)
	module:framesAddScript(optionsFrameList, name, func);
end
local function helpBeginFrame(offset, size, details, data)
	module:framesBeginFrame(optionsFrameList, offset, size, details, data);
end
local function helpEndFrame()
	module:framesEndFrame(optionsFrameList);
end

module.frame = function()
	local textColor0 = "1.0:1.0:1.0";
	local textColor1 = "0.9:0.9:0.9";
	local textColor2 = "0.7:0.7:0.7";
	local textColor3 = "1.0:0.4:0.4";
	
	helpInit();
	
	-- About CTMod
	helpBeginFrame(-5, 0, "frame#tl:0:%y#r");
		
		helpAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#" .. L["CT_Library/Help/About/Heading"]); -- About CTMod
		
		helpAddObject( -5, 2*14, "font#tl:10:%y#s:0:%s#l:13:0#r#" .. L["CT_Library/Help/About/Credits"] .. "#" .. textColor1 .. ":l");  -- Two lines giving credits to Cide, TS, Resike and Dahk
		
		helpAddObject(-15,   14, "font#tl:10:%y#s:0:%s#l:13:0#r#" .. L["CT_Library/Help/About/Updates"] .. "#" .. textColor1 .. ":l");  -- "Updates are available at:"
		helpAddObject( -5,   14, "font#tl:30:%y#s:0:%s#l:13:0#CurseForge.com/WoW/Addons/CTMod# " .. textColor0 .. ":l:280");
		helpAddObject( -5,   14, "font#tl:30:%y#s:0:%s#l:13:0#GitHub.com/DDCorkum/CTMod# " .. textColor0 .. ":l:280");
		helpAddObject( -5,   14, "font#tl:30:%y#s:0:%s#l:13:0#WoWInterface.com/downloads/info3826-CTMod.html# " .. textColor0 .. ":l:280");
		
	
	helpEndFrame();
	
	-- What is CTMod?
	helpBeginFrame(-20, 0, "frame#tl:0:%y#br:tr:0:%b");
		local sNotInstalled = L["CT_Library/Help/WhatIs/NotInstalled"];
		helpAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#" .. L["CT_Library/Help/WhatIs/Heading"]); -- What is CTMod?
		
		helpAddObject( -5,   14, "font#tl:10:%y#s:0:%s#r#" .. L["CT_Library/Help/WhatIs/Line1"] .. "#" .. textColor1 .. ":l"); -- CTMod contains several modules
		if (CT_BarMod and CT_BottomBar) then
			helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#BarMod (/ctbar) and BottomBar (/ctbb)#" .. textColor0 .. ":l");
			helpAddObject(  5, 5*14, "font#tl:30:%y#s:0:%s#r#Changes the appearance of action bars and other UI elements.  Open BarMod to move numbered bars, and open BottomBar to move everything else.#" .. textColor2 .. ":l");
		elseif (CT_BarMod) then
			helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#BarMod (/ctbar)#" .. textColor0 .. ":l");
			helpAddObject(  5, 3*14, "font#tl:30:%y#s:0:%s#r#Changes the appearance of action bars.  Open BarMod to move the numbered bars.#" .. textColor2 .. ":l");
			helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#BottomBar (" .. sNotInstalled .. ")#" .. textColor3 .. ":l");
			helpAddObject(  5, 3*14, "font#tl:30:%y#s:0:%s#r#Changes the appearance of other UI elements like the Pet, Menu and Bag bars.#" .. textColor2 .. ":l");
		elseif (CT_BottomBar) then
			helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#BarMod (" .. sNotInstalled .. ")#" .. textColor3 .. ":l");
			helpAddObject(  5, 3*14, "font#tl:30:%y#s:0:%s#r#Changes the appearance of numbered appearance bars.#" .. textColor2 .. ":l");
			helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#BottomBar (/ctbb)#" .. textColor0 .. ":l");
			helpAddObject(  5, 3*14, "font#tl:30:%y#s:0:%s#r#Changes the appearance of other UI elements.  Open BarMod to move the Pet, Menu and Bag bars#" .. textColor2 .. ":l");
		else
			helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#BarMod and BottomBar (" .. sNotInstalled .. ")#" .. textColor3 .. ":l");
			helpAddObject(  5, 3*14, "font#tl:30:%y#s:0:%s#r#Changes the appearance of action bars and other UI elements like the Pet, Menu and Bag bars#" .. textColor2 .. ":l");		
		end
		if (CT_BuffMod) then
			helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#BuffMod (/ctbuff)#" .. textColor0 .. ":l");
			helpAddObject(  5, 3*14, "font#tl:30:%y#s:0:%s#r#Changes the appearance of buffs, debuffs and auras#" .. textColor2 .. ":l");
		else
			helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#BuffMod (" .. sNotInstalled .. ")#" .. textColor3 .. ":l");
			helpAddObject(  5, 3*14, "font#tl:30:%y#s:0:%s#r#Changes the appearance of buffs, debuffs and auras#" .. textColor2 .. ":l");		
		end
		if (CT_Core) then
			helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#Core (/ctcore)#" .. textColor0 .. ":l");
			helpAddObject(  5, 3*14, "font#tl:30:%y#s:0:%s#r#Packages several light-weight modifications to the game#" .. textColor2 .. ":l");
		else
			helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#Core (" .. sNotInstalled .. ")#" .. textColor3 .. ":l");
			helpAddObject(  5, 3*14, "font#tl:30:%y#s:0:%s#r#Packages several light-weight modifications to the game#" .. textColor2 .. ":l");
		end
		if (CT_ExpenseHistory) then
			helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#ExpenseHistory (/cteh)#" .. textColor0 .. ":l");
			helpAddObject(  5, 3*14, "font#tl:30:%y#s:0:%s#r#Tracks for how much you spend on repairs, flights, etc.#" .. textColor2 .. ":l");
		else
			helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#ExpenseHistory (" .. sNotInstalled .. ")#" .. textColor3 .. ":l");
			helpAddObject(  5, 3*14, "font#tl:30:%y#s:0:%s#r#Tracks for how much you spend on repairs, flights, etc.#" .. textColor2 .. ":l");
		end
		if (CT_MailMod) then
			helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#MailMod (/ctmail)#" .. textColor0 .. ":l");
			helpAddObject(  5, 3*14, "font#tl:30:%y#s:0:%s#r#Adds logging and other features to the in-game mailbox#" .. textColor2 .. ":l");
		else
			helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#MailMod (" .. sNotInstalled .. ")#" .. textColor3 .. ":l");
			helpAddObject(  5, 3*14, "font#tl:30:%y#s:0:%s#r#Adds logging and other features to the in-game mailbox#" .. textColor2 .. ":l");
		end
		
		if (CT_MapMod) then
			helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#MapMod (/ctmap)#" .. textColor0 .. ":l");
			helpAddObject(  5, 3*14, "font#tl:30:%y#s:0:%s#r#Adds pins to the world map for hightlighting points of interest#" .. textColor2 .. ":l");
		else
			helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#MapMod (" .. sNotInstalled .. ")#" .. textColor3 .. ":l");
			helpAddObject(  5, 3*14, "font#tl:30:%y#s:0:%s#r#Adds pins to the world map for hightlighting points of interest#" .. textColor2 .. ":l");
		end
		if (CT_PartyBuffs and CT_UnitFrames) then
			helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#PartyBuffs (/ctparty) and UnitFrames (/ctuf)#" .. textColor0 .. ":l");
			helpAddObject(  5, 3*14, "font#tl:30:%y#s:0:%s#r#Changes the appearance of self, party, focus and assist frames#" .. textColor2 .. ":l");
		elseif (CT_PartyBuffs) then
			helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#PartyBuffs (/ctparty)#" .. textColor0 .. ":l");
			helpAddObject(  5, 3*14, "font#tl:30:%y#s:0:%s#r#Adds buffs to party member frames#" .. textColor2 .. ":l");
			helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#UnitFrames (" .. sNotInstalled .. ")#" .. textColor3 .. ":l");
			helpAddObject(  5, 3*14, "font#tl:30:%y#s:0:%s#r#Changes the appearance of self, focus and assist frames#" .. textColor2 .. ":l");
		elseif (CT_UnitFrames) then
			helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#PartyBuffs (" .. sNotInstalled .. ")#" .. textColor3 .. ":l");
			helpAddObject(  5, 3*14, "font#tl:30:%y#s:0:%s#r#Adds buffs to party member frames#" .. textColor2 .. ":l");
			helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#UnitFrames (/uf)#" .. textColor0 .. ":l");
			helpAddObject(  5, 3*14, "font#tl:30:%y#s:0:%s#r#Changes the appearance of self, focus and assist frames#" .. textColor2 .. ":l");
		else
			helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#PartyBuffs (" .. sNotInstalled .. ")#" .. textColor3 .. ":l");
			helpAddObject(  5, 3*14, "font#tl:30:%y#s:0:%s#r#Adds buffs to party member frames#" .. textColor2 .. ":l");
			helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#UnitFrames (" .. sNotInstalled .. ")#" .. textColor3 .. ":l");
			helpAddObject(  5, 3*14, "font#tl:30:%y#s:0:%s#r#Changes the appearance of self, focus and assist frames#" .. textColor2 .. ":l");
		end
		if (CT_RaidAssist) then
			helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#RaidAssist (/ctra)#" .. textColor0 .. ":l");
			helpAddObject(  5, 5*14, "font#tl:30:%y#s:0:%s#r#Custom raid frames, merging the Vanilla (pre-1.11) experience with modern features.  Type /ctra and drag the yellow box to move frames around.#" .. textColor2 .. ":l");				
		else
			helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#RaidAssist (" .. sNotInstalled .. ")#" .. textColor3 .. ":l");
			helpAddObject(  5, 3*14, "font#tl:30:%y#s:0:%s#r#Custom raid frames, merging the Vanilla (pre-1.11) experience with modern features.#" .. textColor2 .. ":l");
		end
		if (CT_Viewport) then
			helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#Viewport (/ctvp)#" .. textColor0 .. ":l");
			helpAddObject(  5, 3*14, "font#tl:30:%y#s:0:%s#r#Changes the size of the screen viewport where the world is rendered.#" .. textColor2 .. ":l");				
		else
			helpAddObject(-10,   14, "font#tl:30:%y#s:0:%s#r#Viewport (" .. sNotInstalled .. ")#" .. textColor3 .. ":l");
			helpAddObject(  5, 3*14, "font#tl:30:%y#s:0:%s#r#Changes the size of the screen viewport where the world is rendered.#" .. textColor2 .. ":l");
		end		
	
	helpEndFrame();
	
	return "frame#all", helpGetData();
end