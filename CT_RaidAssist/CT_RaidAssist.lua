local UnitName = CT_RA_UnitName;
local GetNumRaidMembers = CT_RA_GetNumRaidMembers;
local GetNumPartyMembers = CT_RA_GetNumPartyMembers;

-- Locally bound frame cache
local frameCache = CT_RA_Cache;

-- Variables
CT_RA_Squelch = 0;
CT_RA_Comm_MessageQueue = { };
CT_RA_Level = 0;
CT_RA_Stats = {
	{
		{ }
	}
};
CT_RA_PTargets = { };
CT_RA_BuffsToCure = { };
CT_RA_BuffsToRecast = { };
CT_RA_RaidParticipant = nil; -- Used to see what player participated in the raid on this account
CT_RA_MaxDebuffs = 2;  -- min 1, max 2

CT_RA_Auras = {
	["buffs"] = { },
	["debuffs"] = { }
};
CT_RA_LastSend = nil;
CT_RA_ClassPositions = {
	[CT_RA_CLASS_WARRIOR] = 1,
	[CT_RA_CLASS_DRUID] = 2,
	[CT_RA_CLASS_MAGE] = 3,
	[CT_RA_CLASS_WARLOCK] = 4,
	[CT_RA_CLASS_ROGUE] = 5,
	[CT_RA_CLASS_HUNTER] = 6,
	[CT_RA_CLASS_PRIEST] = 7,
	[CT_RA_CLASS_PALADIN] = 8,
	[CT_RA_CLASS_SHAMAN] = 9,
	[CT_RA_CLASS_DEATHKNIGHT] = 10,
	[CT_RA_CLASS_MONK] = 11,
	[CT_RA_CLASS_DEMONHUNTER] = 12,
};
CT_RA_ClassIndices = {
	"WARRIOR",
	"DRUID",
	"MAGE",
	"WARLOCK",
	"ROGUE",
	"HUNTER",
	"PRIEST",
	"PALADIN",
	"SHAMAN",
	"DEATHKNIGHT",
	"MONK",
	"DEMONHUNTER",
};
CT_RA_ClassSorted = {};
for k, v in pairs(CT_RA_ClassPositions) do
	tinsert(CT_RA_ClassSorted, k);
end
sort(CT_RA_ClassSorted);

-- Used for healing range detection
local CT_RA_RangeSpell;
local classRangeSpells = {
	[CT_RA_CLASS_DRUID_EN] = CT_RA_RANGE_DRUID,
	[CT_RA_CLASS_PRIEST_EN] = CT_RA_RANGE_PRIEST,
	[CT_RA_CLASS_PALADIN_EN] = CT_RA_RANGE_PALADIN,
	[CT_RA_CLASS_SHAMAN_EN] = CT_RA_RANGE_SHAMAN,
	[CT_RA_CLASS_MONK_EN] = CT_RA_RANGE_MONK,
};

CT_RA_Emergency_RaidHealth = { };
CT_RA_Emergency_Units = { };

CT_RA_UnitIDFrameMap = { };
CT_RA_LastSent = { };
CT_RA_BuffTimeLeft = { };
CT_RA_ResFrame_Options = { };
CT_RA_MainTanks = { };
CT_RA_CurrPlayerName = "";

CT_RA_NumRaidMembers = 0;

function CT_RA_ClassUsesMana(class)
	-- Returns true if specified class uses mana.
	return not (class == CT_RA_CLASS_WARRIOR or class == CT_RA_CLASS_ROGUE or class == CT_RA_CLASS_DEATHKNIGHT or class == CT_RA_CLASS_HUNTER or class == CT_RA_CLASS_DEMONHUNTER);
end

function CT_RA_HideClassManaBar(class)
	-- Returns true if the specified class' mana bar should be hidden.
	local tempOptions = CT_RAMenu_Options["temp"];
	local classUsesMana = CT_RA_ClassUsesMana(class);
	return (
		( not classUsesMana and tempOptions["HideRP"] ) or
		(     classUsesMana and tempOptions["HideMP"] )
	);
end

function CT_RA_GetSortOptions(sortby)
	local tempOptions = CT_RAMenu_Options["temp"];
	if (not sortby) then
		sortby = tempOptions["SORTTYPE"];
		if (not sortby) then
			sortby = "group";
		end
	end
	if (not tempOptions["persort"]) then
		tempOptions["persort"] = {};
	end
	if (not tempOptions["persort"][sortby]) then
		tempOptions["persort"][sortby] = {};
	end
	return tempOptions["persort"][sortby];
end

function CT_RA_UpdateGroupOptions()
	local tempOptions = CT_RAMenu_Options["temp"];
	local sortOptions;

	local numGroups = 0;
	local numClasses = 0;

	-- Update the checkboxes related to which groups to show.
	sortOptions = CT_RA_GetSortOptions("group");
	for i = 1, NUM_RAID_GROUPS, 1 do
		_G["CT_RAOptions2GroupCB" .. i]:SetChecked(nil);
	end
	if ( sortOptions["ShowGroups"] ) then
		for k, v in pairs(sortOptions["ShowGroups"]) do
			numGroups = numGroups + 1;
			_G["CT_RAOptions2GroupCB" .. k]:SetChecked(1);
		end
		if ( numGroups == NUM_RAID_GROUPS ) then
			CT_RACheckAllGroups:SetChecked(1);
		else
			CT_RACheckAllGroups:SetChecked(nil);
		end
	else
		CT_RACheckAllGroups:SetChecked(nil);
	end

	-- Update the checkboxes related to which classes to show.
	sortOptions = CT_RA_GetSortOptions("class");
	for i = 1, CT_RA_MaxGroups, 1 do
		_G["CT_RAOptions2ClassCB" .. i]:SetChecked(nil);
	end
	if ( sortOptions["ShowGroups"] ) then
		for k, v in pairs(sortOptions["ShowGroups"]) do
			numClasses = numClasses + 1;
			_G["CT_RAOptions2ClassCB" .. k]:SetChecked(1);
		end
		if ( numClasses == CT_RA_MaxGroups ) then
			CT_RACheckAllClasses:SetChecked(1);
		else
			CT_RACheckAllClasses:SetChecked(nil);
		end
	else
		CT_RACheckAllClasses:SetChecked(nil);
	end

	if (numGroups == NUM_RAID_GROUPS and numClasses == CT_RA_MaxGroups) then
		CT_RACheckAllGroupsAndClasses:SetChecked(1);
	else
		CT_RACheckAllGroupsAndClasses:SetChecked(nil);
	end
end

function CT_RA_SaveSortOptions_ShowHideWindows()
	-- Save current "ShowGroups" and "HiddenGroups" values.
	local tempOptions = CT_RAMenu_Options["temp"];
	local sortOptions;
	sortOptions = CT_RA_GetSortOptions();
	sortOptions["ShowGroups"] = tempOptions["ShowGroups"];
	sortOptions["HiddenGroups"] = tempOptions["HiddenGroups"];
end

function CT_RA_LoadSortOptions_ShowHideWindows()
	-- Load current "ShowGroups" and "HiddenGroups" values.
	local tempOptions = CT_RAMenu_Options["temp"];
	local sortOptions;
	sortOptions = CT_RA_GetSortOptions();
	tempOptions["ShowGroups"] = sortOptions["ShowGroups"];
	tempOptions["HiddenGroups"] = sortOptions["HiddenGroups"];
	if (not tempOptions["ShowGroups"]) then
		tempOptions["ShowGroups"] = {};
		CT_RA_SaveSortOptions_ShowHideWindows();
	end
end

function CT_RA_UnhideWindows()
	-- Unhide the groups the user has selected.
	local tempOptions = CT_RAMenu_Options["temp"];

	-- If nothing is hidden then return.
	if ( not tempOptions["HiddenGroups"]) then
		return;
	end

	-- Unhide the groups
	tempOptions["ShowGroups"] = tempOptions["HiddenGroups"];
	tempOptions["HiddenGroups"] = nil;
	CT_RA_SaveSortOptions_ShowHideWindows();

	CT_RA_UpdateGroupOptions();
	CT_RA_UpdateRaidGroup(0);
	CT_RA_UpdateRaidFrames();
	CT_RAMenu_UpdateOptionSets();
end

function CT_RA_HideWindows()
	-- Hide the groups the user has selected.
	local tempOptions = CT_RAMenu_Options["temp"];

	-- If groups are already hidden then return.
	if ( tempOptions["HiddenGroups"] ) then
		return;
	end

	-- Save the currently shown groups and then hide them by not showing any.
	tempOptions["HiddenGroups"] = tempOptions["ShowGroups"];
	tempOptions["ShowGroups"] = { };
	CT_RA_SaveSortOptions_ShowHideWindows();

	CT_RA_UpdateGroupOptions();
	CT_RA_UpdateRaidGroup(0);
	CT_RA_UpdateRaidFrames();
	CT_RAMenu_UpdateOptionSets();
end

function CT_RA_ShowHideWindows()
	-- Toggle between showing and hiding the selected groups.
	local tempOptions = CT_RAMenu_Options["temp"];
	if ( tempOptions["HiddenGroups"] ) then
		-- Unhide the groups
		CT_RA_UnhideWindows();
	else
		-- Hide the groups
		CT_RA_HideWindows();
	end
end

function CT_RA_SetGroup(num, show)
	-- Show a group (show == 1), or stop showing a group (show == nil).
	local tempOptions = CT_RAMenu_Options["temp"];
	local sortOptions = CT_RA_GetSortOptions("group");
	if (not sortOptions["ShowGroups"]) then
		sortOptions["ShowGroups"] = {};
	end
	if (not sortOptions["HiddenGroups"]) then
		sortOptions["HiddenGroups"] = {};
	end
	if (show) then
		sortOptions["ShowGroups"][num] = 1;
		sortOptions["HiddenGroups"][num] = nil
	else
		sortOptions["HiddenGroups"][num] = 1;
		sortOptions["ShowGroups"][num] = nil;
	end
	CT_RA_LoadSortOptions_ShowHideWindows();
end

function CT_RA_SetClass(num, show)
	-- Show a class (show == 1), or stop showing a class (show == nil).
	local tempOptions = CT_RAMenu_Options["temp"];
	local sortOptions = CT_RA_GetSortOptions("class");
	if (not sortOptions["ShowGroups"]) then
		sortOptions["ShowGroups"] = {};
	end
	if (not sortOptions["HiddenGroups"]) then
		sortOptions["HiddenGroups"] = {};
	end
	if (show) then
		sortOptions["ShowGroups"][num] = 1;
		sortOptions["HiddenGroups"][num] = nil
	else
		sortOptions["HiddenGroups"][num] = 1;
		sortOptions["ShowGroups"][num] = nil;
	end
	CT_RA_LoadSortOptions_ShowHideWindows();
end

function CT_RA_CheckAllGroups(show, noUpdate)
	-- Show all groups (show == 1), or don't show any groups (show == nil).
	for i = 1, NUM_RAID_GROUPS, 1 do
		CT_RA_SetGroup(i, show);
	end
	if (noUpdate) then
		return;
	end
	CT_RA_UpdateGroupOptions();
	CT_RA_UpdateRaidGroup(0);
	CT_RA_UpdateRaidFrames();
	CT_RAMenu_UpdateOptionSets();
end

function CT_RA_CheckAllClasses(show, noUpdate)
	-- Show all classes (show == 1), or don't show any classes (show == nil).
	for i = 1, CT_RA_MaxGroups, 1 do
		CT_RA_SetClass(i, show);
	end
	if (noUpdate) then
		return;
	end
	CT_RA_UpdateGroupOptions();
	CT_RA_UpdateRaidGroup(0);
	CT_RA_UpdateRaidFrames();
	CT_RAMenu_UpdateOptionSets();
end

function CT_RA_CheckAllGroupsAndClasses(show)
	CT_RA_CheckAllGroups(show, 1);
	CT_RA_CheckAllClasses(show, nil);
end

function CT_RA_ParseEvent(self, event, arg1, arg2, arg3, arg4, arg5, arg6, ...)
	local nick, sMsg, msg;
	if ( event == "CHAT_MSG_ADDON" ) then
		nick, sMsg = arg4, arg2;
	else
		nick, sMsg = arg2, arg1;
	end
	local numRaidMembers = GetNumRaidMembers();
	local name, rank, subgroup, level, class, fileName, zone, online, isDead, raidid, frame;
	for i = 1, numRaidMembers, 1 do
		if ( UnitName("raid" .. i) == nick ) then
			raidid = i;
			name, rank, subgroup, level, class, fileName, zone, online, isDead = GetRaidRosterInfo(i);
			frame = CT_RA_UnitIDFrameMap["raid"..i];
			break;
		end
	end

	local playerName = UnitName("player");
	local unitStats = CT_RA_Stats[nick];

	if ( name and not unitStats ) then
		CT_RA_Stats[nick] = {
			["Buffs"] = { },
			["Debuffs"] = { },
			["Position"] = { }
		};
		unitStats = CT_RA_Stats[nick];
	end

	if ( ( event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER" ) and type(sMsg) == "string" ) then
		if ( raidid ) then
			-- We have a valid unit
			msg = gsub(sMsg, "%%", "%%%%");

			if ( unitStats and raidid ) then
				if ( arg6 and not unitStats[arg6]  and ( arg6 == "AFK" or arg6 == "DND" ) ) then
					unitStats[arg6] = { 1, 0 };
					CT_RA_UpdateUnitDead(frame);
				elseif ( arg2 == name and ( not arg6 or arg6 == "" ) and ( unitStats["DND"] or unitStats["AFK"] ) ) then
					unitStats["DND"] = nil;
					unitStats["AFK"] = nil;
					CT_RA_UpdateUnitDead(frame);
				end
			end
			if ( rank and rank < 1 and CT_RA_Squelch and CT_RA_Squelch > 0 ) then
				if ( CT_RA_Level >= 1 and CT_RA_IsSendingWithVersion(1.468) ) then
					SendChatMessage("<CTRaid> Quiet mode is enabled in the raid. Please be quiet. " .. floor(CT_RA_Squelch) .. " seconds remaining.", "WHISPER", nil, name);
				end
				return;
			end

			if ( rank and rank >= 1 and string.find(sMsg, "<CTRaid> Disbanding raid on request by (.+)") ) then
				LeaveParty();
				return;
			end
			if ( rank >= 1 ) then
				if ( name ~= playerName and sMsg == "<CTRaid> Quiet mode is over." ) then
					if ( CT_RA_Squelch > 0 ) then
						CT_RA_Squelch = 0;
						CT_RA_Print("<CTRaid> Quiet mode has been disabled by " .. name .. ".", 1, 0.5, 0);
					end
				elseif ( name ~= playerName and sMsg == "<CTRaid> Quiet mode, no talking." ) then
					if ( CT_RA_Squelch == 0 ) then
						CT_RA_Squelch = 5*60;
						CT_RA_Print("<CTRaid> Quiet Mode has been enabled by " .. name .. ".", 1, 0.5, 0);
					end
				end
				return;
			end
		end
	elseif ( event == "CHAT_MSG_WHISPER" and type(sMsg) == "string" ) then
		local tempOptions = CT_RAMenu_Options["temp"];
		if ( tempOptions["KeyWord"] and strlower(sMsg) == strlower(tempOptions["KeyWord"]) ) then
			local temp = arg2;
			if ( numRaidMembers == MAX_RAID_MEMBERS or ( GetNumPartyMembers() == 4 and numRaidMembers == 0 ) ) then
				CT_RA_Print("<CTRaid> Player '|c00FFFFFF" .. temp .. "|r' requested invite, group is currently full.", 1, 0.5, 0);
				SendChatMessage("<CTRaid> The group is currently full.", "WHISPER", nil, temp);
			else
				CT_RA_Print("<CTRaid> Invited '|c00FFFFFF" .. temp .. "|r' by Keyword Inviting.", 1, 0.5, 0);
				InviteUnit(temp);
				CT_RA_UpdateFrame.lastInvite = 1;
				CT_RA_UpdateFrame.inviteName = temp;
			end
		else
			local _, _, secRem = string.find(sMsg, "<CTRaid> Quiet mode is enabled in the raid%. Please be quiet%. (%d+) seconds remaining%.");
			if ( secRem and CT_RA_Squelch == 0 ) then
				if ( rank >= 1 ) then
					CT_RA_Squelch = tonumber(secRem);
					CT_RA_Print("<CTRaid> Quiet Mode has been enabled for " .. secRem .. " seconds by " .. name .. ".", 1, 0.5, 0);
				end
			end
		end
	elseif ( event == "CHAT_MSG_WHISPER_INFORM" ) then
		if ( arg1 == "<CTRaid> You are already grouped." ) then
			CT_RA_Print("<CTRaid> Informed '|c00FFFFFF" .. arg2 .. "|r' that he or she is already grouped.", 1, 0.5, 0);
		end
	elseif ( event == "CHAT_MSG_COMBAT_FRIENDLY_DEATH" ) then
		if ( not CT_RAMenu_Options["temp"]["HideTankNotifications"] ) then
			local _, _, name = string.find(sMsg, CT_RA_PATTERN_TANK_HAS_DIED);
			if ( name ) then
				for k, v in pairs(CT_RA_MainTanks) do
					if ( v == name ) then
						CT_RA_WarningFrame:AddMessage("TANK " .. name .. " HAS DIED!", 1, 0, 0, 1, UIERRORS_HOLD_TIME);
						PlaySoundFile("Sound\\interface\\igQuestFailed.wav");
						break;
					end
				end
			end
		end
	elseif ( strsub(event, 1, 15) == "CHAT_MSG_SYSTEM" and type(sMsg) == "string" ) then
		local useless, useless, plr = string.find(sMsg, CT_RA_PATTERN_HAS_LEFT_RAID);
		if ( CT_RA_RaidParticipant and plr and plr ~= CT_RA_RaidParticipant ) then
			CT_RA_CurrPositions[plr] = nil;
			CT_RA_Stats[plr] = nil;
			for k, v in pairs(CT_RA_MainTanks) do
				if ( v == plr ) then
					CT_RA_MainTanks[k] = nil;
					CT_RATarget.MainTanks[k] = nil;
					break;
				end
			end
		elseif ( string.find(sMsg, CT_RA_PATTERN_HAS_JOINED_RAID) ) then
			if ( CT_RA_Level >= 2 ) then
				local useless, useless, plr = string.find(sMsg, CT_RA_PATTERN_HAS_JOINED_RAID);
				if ( plr and CT_RATab_AutoPromotions[plr] ) then
					PromoteToAssistant(plr);
					CT_RA_Print("<CTRaid> Auto-Promoted |c00FFFFFF" .. plr .. "|r.", 1, 0.5, 0);
				end
			end
		elseif ( string.find(sMsg, CT_RA_MESSAGE_AFK) or sMsg == MARKED_AFK ) then
			local _, _, msg = string.find(sMsg, CT_RA_MESSAGE_AFK);
			if ( msg and msg ~= DEFAULT_AFK_MESSAGE ) then
				if ( strlen(msg) > 20 ) then
					msg = strsub(msg, 1, 20) .. "...";
				end
				CT_RA_AddMessage("AFK " .. msg);
			else
				CT_RA_AddMessage("AFK");
			end
		elseif ( string.find(sMsg, CT_RA_MESSAGE_DND) ) then
			local _, _, msg = string.find(sMsg, CT_RA_MESSAGE_DND);
			if ( msg and msg ~= DEFAULT_DND_MESSAGE ) then
				if ( strlen(msg) > 20 ) then
					msg = strsub(msg, 1, 20) .. "...";
				end
				CT_RA_AddMessage("DND " .. msg);
			else
				CT_RA_AddMessage("DND");
			end
		elseif ( sMsg == CLEARED_AFK ) then
			CT_RA_AddMessage("UNAFK");
		elseif ( sMsg == CLEARED_DND ) then
			CT_RA_AddMessage("UNDND");
		end

	elseif ( event == "CHAT_MSG_ADDON" and arg1 == "CTRA" and arg3 == "RAID" ) then
		if ( raidid ) then
			-- Unit is in raid
			if ( arg6 and not unitStats[arg6] and ( arg6 == "AFK" or arg6 == "DND" ) ) then
				unitStats[arg6] = { 1, 0 };
				CT_RA_UpdateUnitDead(frame);
			elseif ( ( not arg6 or arg6 == "" ) and ( unitStats["DND"] or unitStats["AFK"] ) ) then
				unitStats["DND"] = nil;
				unitStats["AFK"] = nil;
				CT_RA_UpdateUnitDead(frame);
			end
			if ( not sMsg ) then
				return;
			end
			local msg = sMsg;
			if ( strsub(msg, strlen(msg)-7) == " ...hic!") then
				msg = strsub(msg, 1, strlen(msg)-8);
			end
			local tempUpdate, message;
			if ( string.find(msg, "#") ) then
				local arr = CT_RA_Split(msg, "#");
				for k, v in pairs(arr) do
					tempUpdate, message = CT_RA_ParseMessage(name, v);
					if ( message ) then
						CT_RA_Print(message, 1, 0.5, 0);
					end
					if ( tempUpdate ) then
						for k, v in pairs(tempUpdate) do
							tinsert(update, v);
						end
					end
				end
			else
				tempUpdate, message = CT_RA_ParseMessage(name, msg);
				if ( message ) then
					CT_RA_Print(message, 1, 0.5, 0);
				end
				if ( tempUpdate ) then
					for k, v in pairs(tempUpdate) do
						tinsert(update, v);
					end
				end
			end
			if ( type(update) == "table" ) then
				for k, v in pairs(update) do
					if ( type(v) == "number" ) then
						CT_RA_UpdateUnitStatus(CT_RA_UnitIDFrameMap["raid"..v]);
					else
						for i = 1, GetNumRaidMembers(), 1 do
							local uName = UnitName("raid" .. i);
							if ( uName and uName == v ) then
								CT_RA_UpdateUnitStatus(CT_RA_UnitIDFrameMap["raid"..i]);
								break;
							end
						end
					end
				end
			end
		end
	elseif ( event == "CHAT_MSG_PARTY" ) then
		if ( raidid ) then
			if ( arg6 and not unitStats[arg6] and ( arg6 == "AFK" or arg6 == "DND" ) ) then
				unitStats[arg6] = { 1, 0 };
				CT_RA_UpdateUnitDead(frame);
			elseif ( ( not arg6 or arg6 == "" ) and ( unitStats["DND"] or unitStats["AFK"] ) ) then
				unitStats["DND"] = nil;
				unitStats["AFK"] = nil;
				CT_RA_UpdateUnitDead(frame);
			end
		end
	end
end

-- Previously tainted ChatFrame_OnEvent() but now changed to use ChatFrame_AddMessageEventFilter();
function CT_RA_RaidChatFilter(self, event, ...)
	local arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11 = ...;
	local rank = arg2;
	if ( event and arg1 and arg2 and type(event) == "string" and type(arg1) == "string" and type(arg2) == "string" ) then
		local tempOptions = CT_RAMenu_Options["temp"];
		local name, rank;
		for i = 1, GetNumRaidMembers(), 1 do
			name, rank = GetRaidRosterInfo(i);
			if ( name == arg2 ) then
				if ( rank and rank < 1 and CT_RA_Squelch > 0 ) then
					return true;
				end
				break;
			end
		end
		if ( not rank ) then
			rank = 0;
		end
		if ( rank >= 1 and ( arg1 == "<CTRaid> Quiet mode, no talking." or arg1 == "<CTRaid> Quiet mode is over." ) ) then
			return true;
		end
		local useless, useless, chan = string.find(gsub(arg1, "%%", "%%%%"), "^<CTMod> This is an automatic message sent by CT_RaidAssist. Channel changed to: (.+)$");
		if ( chan ) then
			return true;
		end
		if ( rank == 2 and ( not tempOptions["leaderColor"] or tempOptions["leaderColor"].enabled ) ) then
			CT_RA_oldAddMessage = self.AddMessage;
			self.AddMessage = CT_RA_newAddMessage;
			CT_RA_oldChatFrame_OnEvent(self, event, ...);
			self.AddMessage = CT_RA_oldAddMessage;
			return true;
		end
	elseif ( event and arg1 and type(event) == "string" and type(arg1) == "string" and event == "CHAT_MSG_WHISPER" ) then
		local tempOptions = CT_RAMenu_Options["temp"];
		if (
			( tempOptions["KeyWord"] and strlower(arg1) == strlower(tempOptions["KeyWord"]) ) or
			arg1 == "<CTRaid> Quiet mode is enabled in the raid. Please be quiet."
		) then
			return true;
		end
	end
	return false;
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", CT_RA_RaidChatFilter);

function CT_RA_newAddMessage(obj, msg, r, g, b)
	local tempOptions = CT_RAMenu_Options["temp"];
	local newR, newG, newB = 1, 1, 0;
	if ( tempOptions["leaderColor"] ) then
		newR, newG, newB = tempOptions["leaderColor"].r, tempOptions["leaderColor"].g, tempOptions["leaderColor"].b;
	end
	return CT_RA_oldAddMessage(obj, string.gsub(msg, "(|Hplayer:.-|h%[)([%w]+)(%])", "%1|c00" .. CT_RA_RGBToHex(newR, newG, newB) .. "%2|r%3"), r, g, b);
end

function CT_RA_ParseMessage(nick, msg)
	local tempOptions = CT_RAMenu_Options["temp"];
	local useless, val1, val2, val3, val4, frame, raidid, rank, update;
	local numRaidMembers = GetNumRaidMembers();
	local playerName = UnitName("player");

	for i = 1, numRaidMembers, 1 do
		if ( UnitName("raid" .. i) == nick ) then
			raidid = i;
			useless, rank = GetRaidRosterInfo(i);
			frame = CT_RA_UnitIDFrameMap["raid"..i];
			break;
		end
	end

	if ( not raidid ) then
		return;
	end

	local unitStats = CT_RA_Stats[nick];
	if ( not unitStats ) then
		if ( not update ) then
			update = { };
		end
		CT_RA_Stats[nick] = {
			["Buffs"] = { },
			["Debuffs"] = { },
			["Position"] = { }
		};
		unitStats = CT_RA_Stats[nick];
		tinsert(update, raidid);
	end
	unitStats["Reporting"] = 1;

	-- Check buff renewal
	useless, useless, val1, val2, val3 = string.find(msg, "^RN ([^%s]+) ([^%s]+) ([^%s]+)$"); -- timeleft(1), id(2), num(3)
	val1 = tonumber(val1);
	val2 = tonumber(val2);
	val3 = tonumber(val3);
	if ( val1 and val2 and val3 ) then
		-- Buffs
		local buff, name, icon;
		for k, v in pairs(tempOptions["BuffTable"]) do
			if ( val2 == v["index"] ) then
				buff = v;
				break;
			end
		end
		if ( not buff and val2 == -1 ) then
			name = CT_RA_BUFF_FEIGN_DEATH;
			icon = CT_RA_ICON_FEIGN_DEATH;

		elseif ( not buff ) then
			return update;

		else
			local spellData = CT_RA_BuffSpellData[val2];
			if (not spellData) then
				spellData = next(CT_RA_BuffSpellData);
			end
			name = spellData["name"];
			icon = spellData["icon"];
		end
		if ( not name ) then
			return update;
		end
		if ( not icon ) then
			return update;
		end
		unitStats["Buffs"][name] = { icon, val1 };
		return update;
	end

	-- Check status requests
	if ( msg == "SR" ) then
		if ( unitStats ) then
			unitStats["Buffs"] = { ["n"] = 0 };
			unitStats["Debuffs"] = { ["n"] = 0 };
		end
		CT_RA_ScanPartyAuras("raid" .. raidid);
		CT_RA_UpdateFrame.scheduleUpdate = 4;
		CT_RA_UpdateFrame.scheduleMTUpdate = 4;
		return update;
	end

	if ( strsub(msg, 1, 2) == "S " ) then
		if ( frame ) then
			for str in string.gmatch(msg, " B [^%s]+ [^%s]+ [^#]+ #") do
				useless, useless, val1, val3, val2 = string.find(str, "B ([^%s]+) ([^%s]+) (.+) #");
				if ( val1 and val2 and val3 ) then
					unitStats["Buffs"][val2] = { val1, tonumber(val3) };
					CT_RA_UpdateUnitBuffs(unitStats["Buffs"], frame, nick);
				end
			end
		end
		return update;
	end

	if ( strsub(msg, 1, 3) == "MS " ) then
		if ( rank >= 1 ) then
			if ( tempOptions["PlayRSSound"] ) then
				PlaySoundFile("Sound\\Doodad\\BellTollNightElf.wav");
			end
			CT_RAMessageFrame:AddMessage(nick .. ": " .. strsub(msg, 3), tempOptions["DefaultAlertColor"].r, tempOptions["DefaultAlertColor"].g, tempOptions["DefaultAlertColor"].b, 1.0, UIERRORS_HOLD_TIME);
		end
		return update;
	end

	useless, useless, val1 = string.find(msg, "^V ([%d%.]+)$");
	if ( tonumber(val1) ) then
		unitStats["Version"] = tonumber(val1);
		return update;
	end


	if ( strsub(msg, 1, 4) == "SET " ) then
		local useless, useless, num, name = string.find(msg, "^SET (%d+) (.+)$");
		if ( name ) then
			if ( rank >= 1 ) then
				num = tonumber(num);
				for k, v in pairs(CT_RA_MainTanks) do
					if ( v == name ) then
						CT_RA_MainTanks[k] = nil;
						CT_RATarget.MainTanks[k] = nil;
					end
				end
				local mtID = 0;
				for i = 1, numRaidMembers, 1 do
					if ( UnitName("raid" .. i) == name ) then
						mtID = i;
						break;
					end
				end
				CT_RA_MainTanks[num] = name;
				CT_RATarget.MainTanks[num] = { mtID, name };
				CT_RATarget_UpdateInfoBox();
				CT_RATarget_UpdateStats();
				CT_RAOptions_UpdateMTs();
				CT_RA_UpdateRaidFrameData();
				CT_RA_UpdateMTs(true);
			end
		end
		return update;
	end

	if ( strsub(msg, 1, 2) == "R " ) then
		local useless, useless, name = string.find(msg, "^R (.+)$");
		if ( name ) then
			for k, v in pairs(CT_RA_MainTanks) do
				if ( v == name ) then
					for i = 1, GetNumRaidMembers(), 1 do
						local user, rank, subgroup, level, class, fileName, zone, online, isDead = GetRaidRosterInfo(i);
						if ( rank >= 1 and user == nick ) then
							CT_RA_MainTanks[k] = nil;
							CT_RATarget.MainTanks[k] = nil;
							CT_RA_UpdateRaidFrameData();
							CT_RA_UpdateMTs(true);
							CT_RAOptions_UpdateMTs();
							return update;
						end
					end
				end
			end
		end
		return update;
	end

	if ( msg == "DB" ) then
		if ( rank >= 1 ) then
			CT_RA_Print("<CTRaid> Disbanding raid on request by '|c00FFFFFF" .. nick .. "|r'.", 1, 0.5, 0);
			LeaveParty();
		end
		return update;
	end

	if ( msg == "RESSED" ) then
		unitStats["Ressed"] = 1;
		CT_RA_UpdateUnitDead(frame);
		return update;
	end

	if ( msg == "NORESSED" ) then
		unitStats["Ressed"] = nil;
		CT_RA_UpdateUnitDead(frame);
		return update;
	end

	if ( msg == "CANRES" ) then
		unitStats["Ressed"] = 2;
		CT_RA_UpdateUnitDead(frame);
		return update;
	end

	if ( strsub(msg, 1, 3) == "RES" ) then
		if ( msg == "RESNO" ) then
			CT_RA_Ressers[nick] = nil;
		else
			local _, _, player = string.find(msg, "^RES (.+)$");
			if ( player ) then
				CT_RA_Ressers[nick] = player;
			end
		end
		CT_RA_UpdateResFrame();
		return update;
	end
	-- Check ready

	if ( msg == "CHECKREADY" ) then
		if ( rank >= 1 ) then
			CT_RA_CheckReady_Person = nick;
			if ( nick ~= playerName ) then
				PlaySoundFile("Sound\\interface\\levelup2.wav");
				CT_RA_ReadyFrame:Show();
			end
		end
		return update;
	elseif ( ( msg == "READY" or msg == "NOTREADY" ) and CT_RA_CheckReady_Person == playerName ) then
		if ( msg == "READY" ) then
			unitStats["notready"] = nil;
		else
			unitStats["notready"] = 2;
		end
		local all_ready = true;
		local nobody_ready = true;
		for k, v in pairs(CT_RA_Stats) do
			if ( v["notready"] ) then
				all_ready = false;
				if ( v["notready"] == 1 ) then
					nobody_ready = false;
				end
			end
		end
		if ( all_ready ) then
			CT_RA_Print("<CTRaid> Everybody is ready.", 1, 1, 0);
		elseif ( not all_ready and nobody_ready ) then
			CT_RA_UpdateFrame.readyTimer = 0.1;
		end
		CT_RA_UpdateUnitDead(frame);
		return update;
	end

	-- Check Rly
	if ( msg == "CHECKRLY" ) then
		if ( rank >= 1 ) then
			CT_RA_CheckRly_Person = nick;
			if ( nick ~= UnitName("player") ) then
				PlaySoundFile("Sound\\interface\\levelup2.wav");
				CT_RA_RlyFrame:Show();
			end
		end
		return update;
	elseif ( ( msg == "YARLY" or msg == "NORLY" ) and CT_RA_CheckRly_Person == playerName ) then
		if ( msg == "YARLY" ) then
			unitStats["rly"] = nil;
		else
			unitStats["rly"] = 1;
		end
		local all_ready = true;
		local nobody_ready = true;
		for k, v in pairs(CT_RA_Stats) do
			if ( v["rly"] ) then
				all_ready = false;
				if ( v["rly"] == 1 ) then
					nobody_ready = false;
				end
			end
		end
		if ( all_ready ) then
			CT_RA_Print("<CTRaid> Ya rly.", 1, 1, 0);
		elseif ( not all_ready and nobody_ready ) then
			CT_RA_UpdateFrame.rlyTimer = 0.1;
		end
		CT_RA_UpdateUnitDead(frame);
		return update;
	end

	-- Check AFK

	if ( msg == "AFK" ) then
		unitStats["AFK"] = { 1, 0 };
		CT_RA_UpdateUnitDead(frame);
		return update;
	elseif ( msg == "UNAFK" ) then
		unitStats["AFK"] = nil;
		CT_RA_UpdateUnitDead(frame);
		return update;
	elseif ( msg == "DND" ) then
		unitStats["DND"] = { 1, 0 };
		CT_RA_UpdateUnitDead(frame);
		return update;
	elseif ( msg == "UNDND" ) then
		unitStats["DND"] = nil;
		CT_RA_UpdateUnitDead(frame);
		return update;
	elseif ( strsub(msg, 1, 3) == "AFK" ) then
		-- With reason
		unitStats["AFK"] = { strsub(msg, 5), 0 };
		CT_RA_UpdateUnitDead(frame);
		return update;
	elseif ( strsub(msg, 1, 3) == "DND" ) then
		-- With reason
		unitStats["DND"] = { strsub(msg, 5), 0 };
		CT_RA_UpdateUnitDead(frame);
		return update;
	end

	-- Check duration
	if ( msg == "DURC" ) then
		if ( rank == 0 ) then
			return;
		end
		local currDur, maxDur, brokenItems = CT_RADurability_GetDurability();
		CT_RA_AddMessage("DUR " .. currDur .. " " .. maxDur .. " " .. brokenItems .. " " .. nick);
		return update;
	elseif ( string.find(msg, "^DUR ") ) then
		local _, _, currDur, maxDur, brokenItems, callPerson = string.find(msg, "^DUR (%d+) (%d+) (%d+) ([^%s]+)$");
		if ( currDur and maxDur and brokenItems and callPerson == playerName ) then
			currDur, maxDur = tonumber(currDur), tonumber(maxDur);
			local name, rank, subgroup, level, class, fileName, zone, online, isDead = GetRaidRosterInfo(raidid);
			local perc;
			if (maxDur == 0) then
				perc = 0;
			else
				perc = floor((currDur/maxDur)*100+0.5);
			end
			CT_RADurability_Add(nick, "|c00FFFFFF" .. perc .. "%|r (|c00FFFFFF" .. brokenItems .. " broken items|r)", fileName, perc);
		end
		return update;
	end

	-- Check resists (Thanks Sudo!)
	if ( msg == "RSTC" ) then
		if ( rank == 0 ) then
			return update;
		end
		if ( tempOptions["DisableQuery"] ) then
			CT_RA_AddMessage("RST -1 " .. nick);
		else
			local resistStr = "";
			for i = 2, 6, 1 do
				local _, res, _, _ = UnitResistance("player", i);
				resistStr = resistStr .. " " .. res;
			end
			CT_RA_AddMessage("RST" .. resistStr ..  " " .. nick);
		end
		return update;
	elseif ( string.find(msg, "^RST ") ) then
		local name, rank, subgroup, level, class, fileName, zone, online, isDead = GetRaidRosterInfo(raidid);
		local _, _, plrName = string.find(msg, "^RST %-1 ([^%s]+)$");
		if ( plrName and plrName == playerName ) then
			CT_RADurability_Add(nick, "|c00FFFFFFDisabled Queries|r", fileName, -1, -1, -1, -1, -1);
		else
			local _, _, FR, NR, FRR, SR, AR, callPerson = string.find(msg, "^RST (%d+) (%d+) (%d+) (%d+) (%d+) ([^%s]+)$");
			if ( FR and callPerson == playerName ) then
				CT_RADurability_Add(nick, "", fileName, tonumber(FR), tonumber(NR), tonumber(FRR), tonumber(SR), tonumber(AR) );
			end
		end
		return update;
	end

	-- Check reagents
	if ( msg == "REAC" ) then
		if ( rank == 0 ) then
			return update;
		end
		local numItems = CT_RAReagents_GetReagents();
		if ( numItems and numItems >= 0 ) then
			CT_RA_AddMessage("REA " .. numItems .. " " .. nick);
		end
		return update;
	elseif ( string.find(msg, "^REA ") ) then
		local _, _, numItems, callPerson = string.find(msg, "^REA ([^%s]+) ([^%s]+)$");
		if ( numItems and callPerson and callPerson == playerName ) then
			local classes = {
				[CT_RA_CLASS_MAGE_EN] = CT_RA_REAGENT_MAGE,
				[CT_RA_CLASS_DRUID_EN] = CT_RA_REAGENT_DRUID,
				[CT_RA_CLASS_SHAMAN_EN] = CT_RA_REAGENT_SHAMAN,
			};
			local reg;
			local _, classEN = UnitClass("raid" .. raidid);
			if (classEN) then
				reg = classes[classEN];
			end
			if (not reg) then
				reg = UNKNOWN or "Unknown";
			end
			local name, rank, subgroup, level, class, fileName, zone, online, isDead = GetRaidRosterInfo(raidid);
			if ( numItems ~= "1" ) then
				CT_RADurability_Add(nick, "|c00FFFFFF" .. numItems .. "|r " .. reg .. "s", fileName, numItems);
			else
				CT_RADurability_Add(nick, "|c00FFFFFF" .. numItems .. "|r " .. reg, fileName, numItems );
			end
		end
		return update;
	end

	-- Check items
	if ( string.find(msg, "^ITMC ") ) then
		local _, _, itemName = string.find(msg, "^ITMC (.+)$");
		if ( itemName ) then
			if ( rank == 0 ) then
				return;
			end
			if ( tempOptions["DisableQuery"] ) then
				CT_RA_AddMessage("ITM " .. -1 .. " " .. itemName .. " " .. nick);
			else
				local numItems = CT_RAItem_GetItems(itemName);
				if ( numItems and numItems > 0 ) then
					CT_RA_AddMessage("ITM " .. numItems .. " " .. itemName .. " " .. nick);
				end
			end
		end
		return update;
	elseif ( string.find(msg, "^ITM ") ) then
		local _, _, numItems, itemName, callPerson = string.find(msg, "^ITM ([-%d]+) (.+) ([^%s]+)$");
		if ( numItems and itemName and callPerson and callPerson == UnitName("player") ) then
			local name, rank, subgroup, level, class, fileName, zone, online, isDead = GetRaidRosterInfo(raidid);
			if ( numItems == "-1" ) then
				CT_RADurability_Add(nick, "|c00FFFFFFDisabled Queries|r", fileName, "0", class);
			elseif ( numItems ~= "1" ) then
				CT_RADurability_Add(nick, "|c00FFFFFF" .. numItems .. "|r " .. itemName .. "s", fileName, numItems);
			else
				CT_RADurability_Add(nick, "|c00FFFFFF" .. numItems .. "|r " .. itemName, fileName, numItems);
			end
		end
		return update;
	end

	-- Check cooldowns
	if ( string.find(msg, "^CD %d+ %d+$") ) then
		local _, _, num, cooldown = string.find(msg, "^CD (%d+) (%d+)$");
		if ( num == "1" ) then
			unitStats["Rebirth"] = tonumber(cooldown)*60;
		elseif ( num == "2" ) then
			unitStats["Reincarnation"] = tonumber(cooldown)*60;
		elseif ( num == "3" ) then
			unitStats["Soulstone"] = tonumber(cooldown)*60;
		elseif ( num == "4" ) then
			unitStats["Raise Ally"] = tonumber(cooldown)*60;
		end
		return update;
	end

	-- Assist requests
	if ( string.find(msg, "^ASSISTME (.+)$") ) then
		if ( rank >= 1 ) then
			local _, _, name = string.find(msg, "^ASSISTME (.+)$");
			if ( name and name == playerName ) then
				CT_RATarget.assistPerson = { nick, 20 };
				ShowUIPanel(CT_RA_AssistFrame);
			end
		end
		return update;
	elseif ( string.find(msg, "^STOPASSIST (.+)$") ) then
		if ( rank >= 1 ) then
			local _, _, name = string.find(msg, "^STOPASSIST (.+)$");
			if ( name and name == playerName ) then
				HideUIPanel(CT_RA_AssistFrame);
			end
		end
		return update;
	end

	-- Vote
	local _, _, question = string.find(msg, "^VOTE (.+)$");
	if ( question ) then
		if ( rank >= 1 ) then
			CT_RA_VotePerson = { nick, 0, 0, question };
			if ( nick ~= playerName ) then
				PlaySoundFile("Sound\\interface\\levelup2.wav");
				CT_RA_VoteFrame.question = question;
				CT_RA_VoteFrame:Show();
			end
		end
		return update;
	elseif ( ( msg == "VOTEYES" or msg == "VOTENO" ) and CT_RA_VotePerson and CT_RA_VotePerson[1] == playerName ) then
		if ( msg == "VOTEYES" ) then
			CT_RA_VotePerson[2] = CT_RA_VotePerson[2] + 1;
		elseif ( msg == "VOTENO" ) then
			CT_RA_VotePerson[3] = CT_RA_VotePerson[3] + 1;
		end
		return update;
	end

	return update;
end

function CT_RA_UpdateBindings()
	local bindKey;
	for i = 1, 5, 1 do
		bindKey = GetBindingKey("CT_ASSISTMT"..i);
		if ( bindKey ) then
			SetOverrideBindingClick(CT_RAFrame, false, bindKey, "CT_RAMTGroupUnitButton"..i);
		end
		bindKey = GetBindingKey("CT_TARGETMT"..i);
		if ( bindKey ) then
			SetOverrideBindingClick(CT_RAFrame, false, bindKey, "CT_RAMTTGroupUnitButton"..i);
		end
		bindKey = GetBindingKey("CT_ASSISTPT"..i);
		if ( bindKey ) then
			SetOverrideBindingClick(CT_RAFrame, false, bindKey, "CT_RAPTTGroupUnitButton"..i);
		end
		bindKey = GetBindingKey("CT_TARGETPT"..i);
		if ( bindKey ) then
			SetOverrideBindingClick(CT_RAFrame, false, bindKey, "CT_RAPTGroupUnitButton"..i);
		end
	end
end

-- Send messages
function CT_RA_AddMessage(msg)
	tinsert(CT_RA_Comm_MessageQueue, msg);
end

function CT_RA_SendMessage(msg, logged)
	-- must be in a raid group, and not a battlegroup or arena instance
	if ( not IsInRaid()) then return; end
	local _, iType = IsInInstance();
	if ((iType == "pvp") or (iType == "arena")) then return; end
	
	-- logged parameter added in WoW 8.0, defaults to nil (ie: false)
	if (logged) then
		C_ChatInfo.SendAddonMessageLogged("CTRA", msg, "RAID");
	else
		C_ChatInfo.SendAddonMessage("CTRA", msg, "RAID");
	end
end

function CT_RA_OnEvent(self, event, arg1, arg2, ...)
	if ( event == "PLAYER_LEAVING_WORLD" ) then
		CT_RAFrame.disableEvents = true;
		return;
	elseif ( event == "PLAYER_LOGIN" ) then
		CT_RA_RangeSpell = CT_RA_GetRangeSpell();
		CT_RAMenu_UpdateWindowPositions();
	elseif ( CT_RAFrame.disableEvents and event ~= "PLAYER_ENTERING_WORLD" ) then
		return;
	elseif ( event == "PLAYER_ENTERING_WORLD" or event == "GROUP_ROSTER_UPDATE" ) then
		CT_RAFrame.disableEvents = nil;
		local numRaidMembers = GetNumRaidMembers();
		local playerName = UnitName("player");
		local tempOptions = CT_RAMenu_Options["temp"];
		if ( event == "GROUP_ROSTER_UPDATE" ) then
			if ( numRaidMembers == 0 ) then
				CT_RA_MainTanks = { };
				CT_RA_PTargets = { };
				CT_RATarget.MainTanks = { };
				CT_RA_Stats = { };
				CT_RA_ButtonIndexes = { };
				CT_RA_Emergency_UpdateHealth();
				CT_RA_UpdateMTs();
				CT_RA_UpdatePTs();
				CT_RAMetersFrame:Hide();
				CT_RA_UpdateRaidFrameOptions();
			elseif ( CT_RA_NumRaidMembers == 0 and numRaidMembers > 0 ) then
				CT_RA_UpdateFrame.SS = 10;
				if ( CT_RA_UpdateFrame.time ) then
					CT_RA_UpdateFrame.time = nil;
				end
				if ( not CT_RA_HasJoinedRaid ) then
					CT_RA_Print("<CTRaid> First raid detected. Thanks for using CT_RaidAssist!", 1, 0.5, 0);
				end
				CT_RA_PartyMembers = { };
				CT_RA_HasJoinedRaid = 1;
				if ( CT_RA_Squelch > 0 ) then
					CT_RA_Print("<CTRaid> Quiet Mode has been automatically disabled (joined raid).", 1, 0.5, 0);
					CT_RA_Squelch = 0;
				end
			end
			CT_RA_CheckGroups();
		else
			C_ChatInfo.RegisterAddonMessagePrefix("CTRA");
			CT_RA_UpdateRaidFrameOptions();
		end

		if ( numRaidMembers > 0 ) then
			if ( tempOptions["StatusMeters"] and tempOptions["StatusMeters"]["Show"] ) then
				CT_RAMetersFrame:Show();
			else
				CT_RAMetersFrame:Hide();
			end
			CT_RA_UpdateResFrame();
--			if ( tempOptions["ShowMonitor"] ) then
--				CT_RA_ResFrame:Show();
--			else
--				CT_RA_ResFrame:Hide();
--			end
		else
			CT_RA_ResFrame:Hide();
			CT_RAMetersFrame:Hide();
		end

		CT_RAOptions_Update();

		if ( CT_RA_NumRaidMembers ~= numRaidMembers ) then
			for i = 1, numRaidMembers, 1 do
				local uId = "raid" .. i;
				local uName = UnitName(uId);
				if ( uName and CT_RA_Stats[uName] ) then
					CT_RA_Stats[uName]["Debuffs"].n = 0;
				end
				CT_RA_ScanPartyAuras(uId);
			end
			CT_RA_UpdateRaidGroup(0);
			if ( CT_RA_NumRaidMembers == 0 and CT_RA_Level >= 2 ) then
				local lootid = ( CT_RATab_DefaultLootMethod or -1 );
				if ( lootid == 1 ) then
					SetLootMethod("freeforall");
				elseif ( lootid == 2 ) then
					SetLootMethod("roundrobin");
				elseif ( lootid == 3 ) then
					SetLootMethod("master", playerName);
				elseif ( lootid == 4 ) then
					SetLootMethod("group");
				elseif ( lootid == 5 ) then
					SetLootMethod("needbeforegreed");
				end
				for i = 1, numRaidMembers, 1 do
					local name, rank = GetRaidRosterInfo(i);
					if ( name ~= playerName and rank < 1 and CT_RATab_AutoPromotions[name] ) then
						PromoteToAssistant(name);
						CT_RA_Print("<CTRaid> Auto-Promoted |c00FFFFFF" .. name .. "|r.", 1, 0.5, 0);
					end
				end
			end
		else
			CT_RA_UpdateRaidGroup(3);
		end
		CT_RA_NumRaidMembers = numRaidMembers;
		CT_RA_UpdateRaidFrames();
		CT_RA_Emergency_UpdateHealth();

		-- Check if someone left
		local update;
		for key, value in pairs(CT_RA_MainTanks) do
			if ( not CT_RA_Stats[value] ) then
				CT_RA_MainTanks[key] = nil;
				update = true;
			end
		end
		for key, value in pairs(CT_RA_PTargets) do
			if ( not CT_RA_Stats[value] ) then
				CT_RA_PTargets[key] = nil;
				update = true;
			end
		end
		if ( update ) then
			CT_RA_UpdateRaidFrameData();
		end

		if ( event == "PLAYER_ENTERING_WORLD" ) then
			if ( CT_RA_RaidParticipant ) then
				if ( CT_RA_RaidParticipant ~= playerName ) then
					CT_RA_Stats = { { } };
					CT_RA_MainTanks = { };
					CT_RA_PTargets = { };
					CT_RATarget.MainTanks = { };
					CT_RA_ButtonIndexes = { };
				end
			end
			CT_RA_RaidParticipant = playerName;
		end
	elseif ( event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" ) then
		if not arg1 then
			return
		end
		local _, _, id = string.find(arg1, "^raid(%d+)$");
		if ( id ) then
			local frame = CT_RA_UnitIDFrameMap["raid"..id];
			local name, hCurr, hMax = UnitName(arg1), UnitHealth(arg1), UnitHealthMax(arg1);
			local hpp;
			if (hMax == 0) then
				hpp = 0;
			else
				hpp = ( hCurr or 1 ) / ( hMax or 1 );
			end
			local stats = CT_RA_Stats[name];
			if ( name and frame ) then
				if ( not stats ) then
					CT_RA_Stats[name] = {
						["Buffs"] = { },
						["Debuffs"] = { },
						["Position"] = { }
					};
					stats = CT_RA_Stats[name];
				end
				if ( UnitIsDead(arg1) or UnitIsGhost(arg1) ) then
					CT_RA_ScanPartyAuras(arg1);
					if ( not stats["Dead"] ) then
						stats["Dead"] = 1;
					end
					CT_RA_UpdateUnitDead(frame);
				elseif ( stats["Dead"] ) then
					if ( hCurr > 0 and not UnitIsGhost(arg1) ) then
						stats["Dead"] = nil;
					end
					CT_RA_UpdateUnitDead(frame);
				else
					stats["Dead"] = nil;
					if ( not frame.hpp or frame.hpp ~= floor(hpp*100) ) then
						CT_RA_UpdateUnitHealth(frame);
					end
				end
				if ( CT_RA_Emergency_Units[name] or ( not CT_RA_EmergencyFrame.maxPercent or hpp < CT_RA_EmergencyFrame.maxPercent ) ) then
					CT_RA_Emergency_UpdateHealth();
				end
			end
		elseif ( ( GetNumRaidMembers() == 0 and ( arg1 == "player" or string.find(arg1, "^party%d+$") ) ) ) then
			if ( CT_RA_Emergency_Units[UnitName(arg1)] or ( not CT_RA_EmergencyFrame.maxPercent or ( hpp and hpp < CT_RA_EmergencyFrame.maxPercent ) ) ) then
				CT_RA_Emergency_UpdateHealth();
			end
		end
		return;
	elseif ( event == "UNIT_AURA" and GetNumRaidMembers() > 0 ) then
		if ( string.find(arg1, "^raid%d+$") ) then
			CT_RA_ScanPartyAuras(arg1);
		end
	elseif ( event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" ) then
		if (arg2 == "MANA" or arg2 == "RAGE" or arg2 == "ENERGY") then
			local _, _, id = string.find(arg1, "^raid(%d+)$");
			if ( id ) then
				CT_RA_UpdateUnitMana(CT_RA_UnitIDFrameMap["raid"..id]);
			end
			return;
		end
	elseif ( event == "UNIT_SPELLCAST_SUCCEEDED" ) then
		if ( arg1 == "player" ) then
			if ( arg2 == CT_RA_REZ_REBIRTH ) then
				CT_RA_AddMessage("CD 1 10");
			elseif ( arg2 == CT_RA_BUFF_SOULSTONE_RESURRECTION ) then
				CT_RA_AddMessage("CD 3 10");
			elseif ( arg2 == CT_RA_REZ_RAISE_ALLY ) then
				CT_RA_AddMessage("CD 4 10");
			end
		end
	elseif ( event == "PLAYER_TARGET_CHANGED" ) then
		CT_RA_UpdateResFrame();
	elseif ( event == "UPDATE_BINDINGS" ) then
		CT_RA_UpdateBindings();
	elseif ( event == "RAID_TARGET_UPDATE" ) then
		CT_RA_UpdateAllRaidTargetIcons();
	end
end

--[[	-- HasSoulstone() no longer appears to be a valid instruction.
	CT_RA_oldUseSoulstone = UseSoulstone;
	function CT_RA_newUseSoulstone()
		local text = HasSoulstone();
		if ( text and text == CT_RA_REZ_REINCARNATION ) then  -- Shaman
			CT_RA_AddMessage("CD 2 30");
		end
		CT_RA_oldUseSoulstone();
	end
	UseSoulstone = CT_RA_newUseSoulstone;
--]]

-----------------------------------------------------
--                  Update Functions               --
-----------------------------------------------------

function CT_RA_GetRangeSpell()
	-- Determine which spell to use with the IsSpellInRange() function.
	-- Returns spell name, or nil.
	local _, classEN = UnitClass("player");
	return classRangeSpells[classEN];
end

function CT_RA_UnitInRange(unit)
	-- Returns 1 if unit is in range.
	-- Anything else is out of range or invalid.
	local inRange, checkedRange;
	if (CT_RA_RangeSpell) then
		inRange = IsSpellInRange(CT_RA_RangeSpell, unit); -- 1==In range, 0==Not in range, nil==Invalid
	end
	if (not inRange) then
		-- inRange == true if in range, false if not.
		-- checkedRange ==
		--	true if range could be checked,
		--	false if range could not be checked for some reason (invalid unit id, enemy, etc)
		inRange, checkedRange = UnitInRange(unit);
		if (not checkedRange) then
			inRange = 1;
		else
			if (inRange) then
				inRange = 1;
			else
				inRange = nil;
			end
		end
	end
	return inRange;
end

function CT_RA_UnitAlpha(raidid, percent)
	local tempOptions = CT_RAMenu_Options["temp"];
	local defaultAlpha = tempOptions.DefaultAlpha;
	local alpha;
	if (not tempOptions.AlphaRange) then
		if (not defaultAlpha) then
			defaultAlpha = 1;
		end
		if (defaultAlpha < 1) then
			-- Frame alpha is used to indicate how hurt the unit is (at full health the frame has a low alpha value).
			if (percent) then
				alpha = math.max(math.min(defaultAlpha+(1-(percent/100))*(1-defaultAlpha), 1), defaultAlpha);
			else
				alpha = defaultAlpha;
			end
		else
			-- Frame alpha is not being used.
			alpha = 1;
		end
	else
		if (not defaultAlpha) then
			defaultAlpha = 0.35;
		end
		if (defaultAlpha < 1) then
			-- Frame alpha is used to indicate if unit is out of range.
			if ( raidid and UnitExists(raidid) and strlen(UnitName(raidid) or "") > 0 ) then
				if (CT_RA_UnitInRange(raidid) == 1) then
					alpha = 1;
				else
					if (UnitPlayerOrPetInRaid(raidid)) then
						alpha = defaultAlpha;
					else
						alpha = 1;
					end
				end
			else
				alpha = defaultAlpha;
			end
		else
			-- Frame alpha is not being used.
			alpha = 1;
		end
	end
	return alpha;
end

function CT_RA_UpdateRange()
	-- Update range status of raid members (excluding MTs and PTs)
	if (not CT_RAMenu_Options["temp"]["AlphaRange"]) then
		return;
	end
	local numRaidMembers = GetNumRaidMembers();
	for i=1, numRaidMembers do
		local raidid = "raid" .. i;
		local frame = CT_RA_UnitIDFrameMap[raidid];
		if (frame) then
			frame:SetAlpha(CT_RA_UnitAlpha(raidid, nil));
		end
	end
end

-- Update health
function CT_RA_UpdateUnitHealth(frame)
	local tempOptions = CT_RAMenu_Options["temp"];
	if ( not frame or not tempOptions["ShowGroups"][frame.frameParent.id] ) then
		return;
	end
	local id = "raid" .. frame.id;
	local maxHealth = UnitHealthMax(id);
	local percent;
	if (maxHealth == 0) then
		percent = 0;
	else
		percent = floor(UnitHealth(id) / maxHealth * 100);
	end
	local name = UnitName(id);
	frame.hpp = percent;
	local updateDead = frame.status;
	local alpha;
	if ( percent and percent > 0 ) then
		-- Commonly used values
		alpha = CT_RA_UnitAlpha(id, percent);

		local showHP = tempOptions["ShowHP"];
		local memberHeight = tempOptions["MemberHeight"];
		local framePercent = frame.Percent;
		local frameHPBar = frame.HPBar;
		local stats = CT_RA_Stats[name];

		if ( stats and stats["Ressed"] ) then
			stats["Ressed"] = nil;
			updateDead = 1;
		end
		if ( percent > 100 ) then
			percent = 100;
		end
		frameHPBar:SetValue(percent);
		if ( showHP and showHP == 1 and maxHealth and memberHeight == 40 ) then
			if (maxHealth == 0) then
				framePercent:SetText(0 .. "/" .. maxHealth);
			else
				local health = floor(percent/100*maxHealth);
				local mxHealth = maxHealth;
				if (health >= 1000000) then
					health = floor(health / 1000000) .. (SECOND_NUMBER_CAP or " M");
				elseif (health >= 10000) then
					health = floor(health / 1000) .. (FIRST_NUMBER_CAP or " K");
				end
				if (mxHealth >= 1000000) then
					mxHealth = floor(mxHealth / 1000000) .. (SECOND_NUMBER_CAP or " M");
				elseif (mxHealth >= 10000) then
					mxHealth = floor(mxHealth / 1000) .. (FIRST_NUMBER_CAP or " K");
				end
				framePercent:SetText(health .. "/" .. mxHealth);
			end
		elseif ( showHP and showHP == 2 and memberHeight == 40 ) then
			framePercent:SetText(percent .. "%");
		elseif ( showHP and showHP == 3 and memberHeight == 40 ) then
			if ( maxHealth ) then
				local diff;
				if (maxHealth == 0) then
					diff = 0;
				else
					diff = floor(percent/100*maxHealth)-maxHealth;
				end
				if (diff <= -1000000) then
					diff = floor(diff / 1000000) .. (SECOND_NUMBER_CAP or " M");
				-- elseif (diff <= -10000) then
				-- 	diff = floor(diff / 1000) .. (FIRST_NUMBER_CAP or " K");
				elseif ( diff == 0 ) then
					diff = "";
				end
				framePercent:SetText(diff);
			else
				framePercent:SetText(percent-100 .. "%");
			end
		else
			framePercent:Hide();
		end
		local hppercent = percent/100;
		local r, g;
		if ( hppercent > 0.5 and hppercent <= 1) then
			g = 1;
			r = (1.0 - hppercent) * 2;
		elseif ( hppercent >= 0 and hppercent <= 0.5 ) then
			r = 1.0;
			g = hppercent * 2;
		else
			r = 0;
			g = 1;
		end
		frameHPBar:SetStatusBarColor(r, g, 0);
		frame.HPBG:SetVertexColor(r, g, 0, tempOptions["BGOpacity"]);
	end
	local isDead;
	if ( updateDead ) then
		CT_RA_UpdateUnitDead(frame, 1);
	end
	if (not alpha) then
		alpha = CT_RA_UnitAlpha(id, nil);
	end
	frame:SetAlpha(alpha);
end

-- Update status

function CT_RA_UpdateUnitStatus(frame)
	local tempOptions = CT_RAMenu_Options["temp"];
	if (not frame or not frame.frameParent or not frame.frameParent.id ) then
		return;
	end
	if ( not tempOptions["ShowGroups"][frame.frameParent.id] ) then
		return;
	end
	local frameName = frame.name;
	local id = frame.id;

	if ( not id ) then
		return;
	end

	local width, height, scale = CT_RA_GetFrameData(id);
	local name, rank, subgroup, level, class, fileName, zone, online, isDead = GetRaidRosterInfo(id);

	if ( tempOptions["HideBorder"] ) then
		if ( height == 28 ) then
			frame.BuffButton1:SetPoint("TOPRIGHT", frameName, "TOPRIGHT", -5, -5);
			frame.DebuffButton1:SetPoint("TOPRIGHT", frameName, "TOPRIGHT", -5, -5);
		else
			frame.BuffButton1:SetPoint("TOPRIGHT", frameName, "TOPRIGHT", -5, -3);
			frame.DebuffButton1:SetPoint("TOPRIGHT", frameName, "TOPRIGHT", -5, -3);
		end
		frame:SetBackdropBorderColor(1, 1, 1, 0);

		frame.Percent:SetPoint("TOP", frameName, "TOP", 2, -16);
		frame.HPBar:SetPoint("TOPLEFT", frameName, "TOPLEFT", 10, -19);
		frame.HPBG:SetPoint("TOPLEFT", frameName, "TOPLEFT", 10, -19);
	else
		frame:SetBackdropBorderColor(1, 1, 1, 1);
		frame.BuffButton1:SetPoint("TOPRIGHT", frameName, "TOPRIGHT", -5, -5);
		frame.DebuffButton1:SetPoint("TOPRIGHT", frameName, "TOPRIGHT", -5, -5);
		frame.HPBar:SetPoint("TOPLEFT", frameName, "TOPLEFT", 10, -22);
		frame.HPBG:SetPoint("TOPLEFT",frameName, "TOPLEFT", 10, -22);
		frame.Percent:SetPoint("TOP", frameName, "TOP", 2, -18);
	end
	if ( height == 32 or height == 29 or height == 28 or height == 25 ) then
		frame.HPBar:Hide();
		frame.HPBG:Hide();
		frame.Percent:Hide();
	else
		frame.HPBar:Show();
		frame.HPBG:Show();
	end

	local stats = CT_RA_Stats[name];
	frame.Name:SetText(name);
	CT_RA_UpdateUnitDead(frame);
	if ( stats ) then
		CT_RA_UpdateUnitBuffs(stats["Buffs"], frame, name);
	end
	if ( online ) then
		CT_RA_UpdateUnitHealth(frame, 1);
		CT_RA_UpdateUnitMana(frame);
		if ( stats ) then
			CT_RA_UpdateUnitBuffs(stats["Buffs"], frame, name);
		end
	end
end

function CT_RA_CanShowInfo(id)
	local tempOptions = CT_RAMenu_Options["temp"];
	local stats = CT_RA_Stats[UnitName(id)];
	local showHP, hasFD, isRessed, isNotReady, showAFK, isDead;
	local hp = tempOptions["ShowHP"];

	showHP = ( hp and hp <= 3 );
	hasFD = ( stats and stats["FD"] );
	isRessed = ( stats and stats["Ressed"] );
	isNotReady = ( stats and stats["notready"] );
	showAFK = ( tempOptions["ShowAFK"] and stats and stats["AFK"] );
	isDead = ( ( stats and stats["Dead"] ) or UnitIsDead(id) or UnitIsGhost(id) );
	if ( showHP and not hasFD and not isRessed and not isNotReady and not showAFK and not isDead ) then
		return true;
	else
		return nil;
	end
end
-- Update mana
function CT_RA_UpdateUnitMana(frame)
	local tempOptions = CT_RAMenu_Options["temp"];
	if ( not frame or not tempOptions["ShowGroups"][frame.frameParent.id] ) then
		return;
	end
	local id = "raid" .. frame.id;
	local percent;
	if ( UnitExists(id) ) then
		if (UnitPowerMax(id) == 0) then
			percent = 0;
		else
			percent = floor(UnitPower(id) / UnitPowerMax(id) * 100);
		end
	end
	frame.MPBar:SetValue(percent);
end

-- Update buffs
function CT_RA_UpdateUnitBuffs(buffs, frame, nick)
	local tempOptions = CT_RAMenu_Options["temp"];
	if ( not frame or not tempOptions["ShowGroups"][frame.frameParent.id] ) then
		return;
	end
	local num = 1;
	if ( buffs ) then
		if ( not tempOptions["ShowDebuffs"] or tempOptions["ShowBuffsDebuffed"] ) then
			for key, val in ipairs(tempOptions["BuffTable"]) do
				local spellData = CT_RA_BuffSpellData[ (val["index"]) ];
				if (not spellData) then
					spellData = next(CT_RA_BuffSpellData);
				end
				local name, texName;
				if ( buffs[ (spellData["name"]) ] ) then
					name = spellData["name"];
					texName = spellData["icon"];
				end
				if ( name and texName ) then
					if ( num <= 4 and val["show"] ~= -1 ) then -- Change 4 to number of buffs
						local button = frame["BuffButton"..num];
						frameCache[button].Icon:SetTexture(texName);
						button.name = name;
						button.owner = nick;
						button.texture = texName;
						button:Show();
						num = num + 1;
					end
				end
			end
		end
	end
	for i = num, 4, 1 do -- Change 4 to number of buffs
		frame["BuffButton"..i]:Hide();
	end
	local stats = CT_RA_Stats[nick];
	if ( stats ) then
		CT_RA_UpdateUnitDebuffs(stats["Debuffs"], frame);
	end
end

function CT_RA_UpdateUnitDead(frame, didUpdateHealth)
	local tempOptions = CT_RAMenu_Options["temp"];
	if ( not frame or not tempOptions["ShowGroups"][frame.frameParent.id] ) then
		return;
	end
	local raidid = "raid" .. frame.id;
	local name, rank, subgroup, level, class, fileName, zone, online, dead = GetRaidRosterInfo(frame.id);
	local color = RAID_CLASS_COLORS[fileName];
	if ( color ) then
		frame.Name:SetTextColor(color.r, color.g, color.b);
	end
	local stats, isFD, isDead = CT_RA_Stats[name], false, false;
	if ( UnitIsGhost(raidid) or UnitIsDead(raidid) ) then
		isFD = CT_RA_CheckFD(name, raidid)
		if ( isFD == 0 ) then
			isDead = 1;
			-- Scan buffs&debuffs on death
			CT_RA_ScanPartyAuras(raidid);
		end
	end
	CT_RA_UpdateRaidTargetIcon(frame, raidid);
	local height = tempOptions["MemberHeight"];
	if ( CT_RA_HideClassManaBar(class) ) then
		height = height - 4;
	end
	local alpha;
	if ( not online ) then
		for i = 1, 4, 1 do
			if ( i <= CT_RA_MaxDebuffs ) then
				frame["DebuffButton"..i]:Hide();
			end
			frame["BuffButton"..i]:Hide();
		end
		frame:SetBackdropColor(0.3, 0.3, 0.3, 1);
		if (not InCombatLockdown()) then
			if ( tempOptions["HideBorder"] ) then
				frame:SetHeight(37);
			else
				frame:SetHeight(40);
			end
		end
		if ( name ) then
			if ( not stats ) then
				CT_RA_Stats[name] = {
					["Buffs"] = { },
					["Debuffs"] = { },
					["Position"] = { },
				};
				stats = CT_RA_Stats[name];
			end
			if ( not stats["Offline"] ) then
				stats["Offline"] = 1;
			end
		end
		frame.status = "offline";
		frame.Status:SetText("OFFLINE");
		frame.Status:Show();
		frame.HPBar:Hide();
		frame.HPBG:Hide();
		frame.Percent:Hide();
		frame.MPBar:Hide();
		frame.MPBG:Hide();
		frame:SetAlpha(CT_RA_UnitAlpha(raidid, nil));
		return;
	elseif ( stats and stats["notready"] ) then
		frame.Status:Show();
		if (not InCombatLockdown()) then
			if ( tempOptions["HideBorder"] ) then
				frame:SetHeight(37);
			else
				frame:SetHeight(40);
			end
		end

		if ( stats["notready"] == 1 ) then
			frame.status = "noreply";
			frame.Status:SetText("No Reply");
			frame:SetBackdropColor(0.45, 0.45, 0.45, 1);
		else
			frame.status = "notready";
			frame.Status:SetText("Not Ready");
			frame:SetBackdropColor(0.8, 0.45, 0.45, 1);
		end

		frame.HPBar:Hide();
		frame.HPBG:Hide();
		frame.Percent:Hide();
		frame.MPBar:Hide();
		frame.MPBG:Hide();
	elseif ( isFD == 1 ) then
		frame.status = "feigndeath";
		frame.Status:Show();
		frame.Status:SetText("Feign Death");
		frame:SetBackdropColor(0.3, 0.3, 0.3, 1);
		if (not InCombatLockdown()) then
			if ( tempOptions["HideBorder"] and CT_RA_HideClassManaBar(class) ) then
				frame:SetHeight(height+3);
			end
		end
		frame.HPBar:Hide();
		frame.HPBG:Hide();
		frame.Percent:Hide();
		frame.MPBar:Hide();
		frame.MPBG:Hide();
	elseif ( isFD == 2 ) then
		frame.status = "spiritofredemption";
		frame.Status:Show();
		frame.Status:SetText("SoR");
		frame:SetBackdropColor(0.3, 0.3, 0.3, 1);
		if (not InCombatLockdown()) then
			if ( tempOptions["HideBorder"] and CT_RA_HideClassManaBar(class) ) then
				frame:SetHeight(height+3);
			end
		end
		frame.HPBar:Hide();
		frame.HPBG:Hide();
		frame.Percent:Hide();
		frame.MPBar:Hide();
		frame.MPBG:Hide();
	elseif ( stats and stats["Ressed"] ) then
		frame.status = "resurrected";
		frame.Status:Show();
		frame:SetBackdropColor(0.3, 0.3, 0.3, 1);
		if (not InCombatLockdown()) then
			if ( tempOptions["HideBorder"] ) then
				frame:SetHeight(37);
			else
				frame:SetHeight(40);
			end
		end
		if ( stats["Ressed"] == 1 ) then
			frame.Status:SetText("Resurrected");
		elseif ( stats["Ressed"] == 2 ) then
			frame.Status:SetText("SS Available");
		end
		frame.HPBar:Hide();
		frame.HPBG:Hide();
		frame.Percent:Hide();
		frame.MPBar:Hide();
		frame.MPBG:Hide();
	elseif ( isDead ) then
		frame.status = "dead";
		for i = 1, 4, 1 do
			if ( i <= CT_RA_MaxDebuffs ) then
				frame["DebuffButton"..i]:Hide();
			end
			frame["BuffButton"..i]:Hide();
		end
		frame.Status:Show();
		frame:SetBackdropColor(0.3, 0.3, 0.3, 1);
		if (not InCombatLockdown()) then
			if ( tempOptions["HideBorder"] ) then
				frame:SetHeight(37);
			else
				frame:SetHeight(40);
			end
		end
		frame.Status:SetText("DEAD");
		frame.HPBar:Hide();
		frame.HPBG:Hide();

		frame.Percent:Hide();
		frame.MPBar:Hide();
		frame.MPBG:Hide();
	elseif ( stats and stats["AFK"] and tempOptions["ShowAFK"] ) then
		frame.status = "afk";
		frame.Status:Show();
		frame:SetBackdropColor(0.3, 0.3, 0.3, 1);
		if (not InCombatLockdown()) then
			if ( tempOptions["HideBorder"] ) then
				frame:SetHeight(37);
			else
				frame:SetHeight(40);
			end
		end
		frame.Status:SetText("AFK");
		frame.HPBar:Hide();
		frame.HPBG:Hide();
		frame.Percent:Hide();
		frame.MPBar:Hide();
		frame.MPBG:Hide();
	else
		if ( frame.status and not didUpdateHealth ) then
			CT_RA_UpdateUnitHealth(frame);
		end
		local canShowInfo = CT_RA_CanShowInfo("raid"..frame.id);
		frame.status = nil;
		frame:SetBackdropColor(tempOptions["DefaultColor"].r, tempOptions["DefaultColor"].g, tempOptions["DefaultColor"].b, tempOptions["DefaultColor"].a);
		if ( tempOptions["MemberHeight"] == 40 ) then
			frame.HPBar:Show();
			frame.HPBG:Show();
			if ( canShowInfo ) then
				frame.Percent:Show();
			else
				frame.Percent:Hide();
			end
		end
		if (not InCombatLockdown()) then
			if ( tempOptions["HideBorder"] ) then
				frame:SetHeight(height-3);
			else
				frame:SetHeight(height);
			end
		end
		local manaType = UnitPowerType(raidid);
		local manaTbl = PowerBarColor[manaType];
		frame.MPBar:SetStatusBarColor(manaTbl.r, manaTbl.g, manaTbl.b);
		frame.MPBG:SetVertexColor(manaTbl.r, manaTbl.g, manaTbl.b, (tempOptions["BGOpacity"] or 0.4));
		frame.Status:Hide();
		if ( not CT_RA_HideClassManaBar(class) ) then
			frame.MPBar:Show();
			frame.MPBG:Show();
			if ( canShowInfo ) then
				frame.Percent:Show();
			else
				frame.Percent:Hide();
			end
		else
			frame.MPBar:Hide();
			frame.MPBG:Hide();
		end

		if ( stats ) then
			local debuffs = stats.Debuffs;
			local numDebuffs = debuffs.n;
			if ( numDebuffs and numDebuffs > 0 ) then
				CT_RA_UpdateUnitDebuffs(debuffs, frame);
			end
		end
	end
	if ( stats ) then
		stats["Offline"] = nil;
	end
	if (not alpha) then
		alpha = CT_RA_UnitAlpha(raidid, nil);
	end
	frame:SetAlpha(alpha);
end

-- Update debuffs
function CT_RA_UpdateUnitDebuffs(debuffs, frame)
	local tempOptions = CT_RAMenu_Options["temp"];
	if ( not frame or not tempOptions["ShowGroups"][frame.frameParent.id] ) then
		return;
	end
	local num = 1;
	if ( tempOptions["ShowBuffsDebuffed"] ) then
		num = CT_RA_MaxDebuffs;
	end
	local name, rank, subgroup, level, class, fileName, zone, online, isDead = GetRaidRosterInfo(frame.id);
	local stats, setbg = CT_RA_Stats[name], 0;
	if ( name and stats and online and not UnitIsGhost("raid" .. frame.id) and ( not UnitIsDead("raid" .. frame.id) or stats["FD"] ) ) then
		if ( not frame.status ) then
			local defaultColors = tempOptions["DefaultColor"];
			frame:SetBackdropColor(defaultColors.r, defaultColors.g, defaultColors.b, defaultColors.a);
		end
		if ( debuffs ) then
			for key, val in ipairs(tempOptions["DebuffColors"]) do
				for k, v in pairs(debuffs) do
					if ( k ~= "n" ) then
						local en, de, fr;
						if ( type(val["type"]) == "table" ) then
							en = val["type"]["en"];
							de = val["type"]["de"];
							fr = val["type"]["fr"];
						else
							en = val["type"];
						end
						if ( ( ( en and en == v[1] ) or ( de and de == v[1] ) or ( fr and fr == v[1] ) ) and val["id"] ~= -1 ) then
							if ( tempOptions["ShowBuffsDebuffed"] and num >= 1 ) then
								local button = frame["DebuffButton"..num];
								frameCache[button].Icon:SetTexture("Interface\\Icons\\" ..v[3]);
								button.name = k;
								button.owner = name;
								button.texture = v[3];
								button:Show();
								num = num - 1;
							elseif ( not tempOptions["ShowBuffsDebuffed"] and tempOptions["ShowDebuffs"] and num <= CT_RA_MaxDebuffs ) then
								local button = frame["DebuffButton"..num];
								frameCache[button].Icon:SetTexture("Interface\\Icons\\" ..v[3]);
								button.name = k;
								button.owner = name;
								button.texture = v[3];
								button:Show();
								num = num + 1;
							end
							if ( setbg == 0 and not frame.status ) then
								frame:SetBackdropColor(val.r, val.g, val.b, val.a);
								setbg = 1;
							end
						end
					end
				end
			end
		end
		if ( tempOptions["ShowBuffsDebuffed"] ) then
			if ( num < 1 ) then
				for i = 1, 4, 1 do
					frame["BuffButton"..i]:Hide();
				end
			end
			for i = num, 1, -1 do
				frame["DebuffButton"..i]:Hide();
			end
		else
			for i = num, CT_RA_MaxDebuffs, 1 do
				frame["DebuffButton"..i]:Hide();
			end
		end
	end
end

function CT_RA_UpdateAllRaidTargetIcons()
	-- -----
	-- Update all raid target icons.
	-- -----
	-- ShowRaidIcon
	-- Update raid target icons on raid member frames.
	local numRaidMembers = GetNumRaidMembers();
	for i=1, numRaidMembers do
		local raidid = "raid" .. i;
		local frame = CT_RA_UnitIDFrameMap[raidid];
		if (frame) then
			CT_RA_UpdateRaidTargetIcon(frame, raidid);
		end
	end
	-- Update raid target icons on MT targets and MT target targets.
	if ( CT_RA_MainTanks ) then
		CT_RA_UpdateMTs(true);
	end
	-- Update raid target icons on PTs and PT targets
	if ( CT_RA_PTargets ) then
		CT_RA_UpdatePTs(true);
	end
end

function CT_RA_UpdateRaidTargetIcon(frame, raidid)
	-- -----
	-- Update a single frame's raid target icon.
	-- -----
	local tempOptions = CT_RAMenu_Options["temp"];

	local icon = _G[frame:GetName() .. "Icon"];
	local info, index;

	if (UnitExists(raidid) and tempOptions["ShowRaidIcon"]) then
		index = GetRaidTargetIndex(raidid);
		if (index) then
			info = UnitPopupButtons["RAID_TARGET_" .. index];
		end
	end

	if (info) then
		icon:SetTexture(info.icon);
		if (info.tCoordLeft) then
			icon:SetTexCoord(info.tCoordLeft, info.tCoordRight, info.tCoordTop, info.tCoordBottom);
		end
		icon:Show();
	else
		icon:Hide();
	end
end

-- Get info

function CT_RA_UpdateMT(raidid, mtid, frame, val)
	local tempOptions = CT_RAMenu_Options["temp"];
	local frameName = frame.name;
	local mtwidth, ptwidth, height = CT_RA_GetMTFrameData();
	local alpha;

	if (not InCombatLockdown()) then
		frame:SetWidth(mtwidth);
		frame:SetHeight(height);
	end
	if ( tempOptions["ShowMTTT"] and not UnitIsUnit(mtid, raidid.."target") and
	     not UnitIsPlayer(raidid) and UnitExists(raidid.."target") and not tempOptions["HideColorChange"] ) then
	     	frame:SetBackdropColor(1, 0, 0, 0.5);
	else
		local defaultColors = tempOptions.DefaultColor;
		frame:SetBackdropColor(defaultColors.r, defaultColors.g, defaultColors.b, defaultColors.a);
	end
	if ( tempOptions["HideBorder"] ) then
		frame:SetBackdropBorderColor(1, 1, 1, 0);
		frame.HPBar:SetPoint("TOPLEFT", frameName, "TOPLEFT", 10, -19);
		frame.HPBG:SetPoint("TOPLEFT", frameName, "TOPLEFT", 10, -19);
		frame.Percent:SetPoint("TOP", frameName, "TOPLEFT", 47, -16);
	else
		frame:SetBackdropBorderColor(1, 1, 1, 1);
		frame.HPBar:SetPoint("TOPLEFT", frameName, "TOPLEFT", 10, -22);
		frame.HPBG:SetPoint("TOPLEFT", frameName, "TOPLEFT", 10, -22);
		frame.Percent:SetPoint("TOP", frameName, "TOPLEFT", 47, -18);
	end
	if ( raidid and UnitExists(raidid) and strlen(UnitName(raidid) or "") > 0 ) then
		local health, healthmax, mana, manamax = UnitHealth(raidid), UnitHealthMax(raidid), UnitPower(raidid), UnitPowerMax(raidid);
		frame.Name:SetHeight(15);
		frame.Status:Hide();
		frame.HPBar:Show();
		frame.HPBG:Show();
		frame.MPBar:Show();
		frame.MPBG:Show();
		frame.Name:Show();
		local manaType = UnitPowerType(raidid);
		if ( ( manaType == 0 and not tempOptions["HideMP"] ) or ( manaType > 0 and not tempOptions["HideRP"] and UnitIsPlayer(raidid) ) ) then
			local manaTbl = PowerBarColor[manaType];
			frame.MPBar:SetStatusBarColor(manaTbl.r, manaTbl.g, manaTbl.b);
			frame.MPBG:SetVertexColor(manaTbl.r, manaTbl.g, manaTbl.b, tempOptions["BGOpacity"]);
			frame.MPBar:SetMinMaxValues(0, manamax);
			frame.MPBar:SetValue(mana);
		else
			frame.MPBar:Hide();
			frame.MPBG:Hide();
		end
		if ( not UnitIsConnected(raidid) ) then
			frame.HPBar:Hide();
			frame.HPBG:Hide();
			frame.Percent:Hide();
			frame.MPBar:Hide();
			frame.MPBG:Hide();
			frame.Status:Show();
			frame.Status:SetText("OFFLINE");
		elseif ( UnitIsDead(raidid) or UnitIsGhost(raidid) ) then
			frame.HPBar:Hide();
			frame.HPBG:Hide();
			frame.Percent:Hide();
			frame.MPBar:Hide();
			frame.MPBG:Hide();
			frame.Status:Show();
			local isFD = CT_RA_CheckFD(UnitName(raidid), raidid);
			if ( isFD == 1 ) then
				frame.Status:SetText("Feign Death");
			elseif ( isFD == 2 ) then
				frame.Status:SetText("SoR");
			else
				frame.Status:SetText("DEAD");
			end
		elseif ( health and healthmax and not UnitIsDead(raidid) and not UnitIsGhost(raidid) ) then
			if ( tempOptions["ShowHP"] and tempOptions["ShowHP"] <= 4 ) then
				frame.Percent:Show();
			else
				frame.Percent:Hide();
			end

			frame.HPBar:SetMinMaxValues(0, healthmax);
			frame.HPBar:SetValue(health);

			local percent;
			if (healthmax == 0) then
				percent = 0;
			else
				percent = health/healthmax;
			end
			frame.Percent:SetText(floor(percent*100+0.5) .. "%");
			if ( percent >= 0 and percent <= 1 ) then
				local r, g;
				if ( percent > 0.5 ) then
					g = 1;
					r = (1.0 - percent) * 2;
				else
					r = 1;
					g = percent * 2;
				end
				frame.HPBar:SetStatusBarColor(r, g, 0);
				frame.HPBG:SetVertexColor(r, g, 0, tempOptions["BGOpacity"]);
			end
			alpha = CT_RA_UnitAlpha(raidid, percent*100);

		elseif ( UnitIsDead(raidid) or UnitIsGhost(raidid) ) then
			frame.HPBar:Hide();
			frame.HPBG:Hide();
			frame.Percent:Hide();
			frame.MPBar:Hide();
			frame.MPBG:Hide();
			frame.Status:Show();
			frame.Status:SetText("DEAD");
		else
			frame.HPBar:Hide();
			frame.HPBG:Hide();
		end
		frame.Name:SetText(UnitName(raidid));
		if ( UnitCanAttack("player", raidid) ) then
			frame.Name:SetTextColor(1, 0.5, 0);
		else
			frame.Name:SetTextColor(0.5, 1, 0);
		end
		frame.unitName = UnitName(raidid);
	else
		frame.Percent:Hide();
		frame.HPBar:Hide();
		frame.HPBG:Hide();
		frame.MPBar:Hide();
		frame.MPBG:Hide();
		frame.Status:Hide();
		frame.Name:SetText(val .. "'s Target");
		frame.Name:SetHeight(30);
		frame.Name:SetTextColor(1, 0.82, 0);
	end
	if (not alpha) then
		alpha = CT_RA_UnitAlpha(raidid, nil);
	end
	frame:SetAlpha(alpha);
	CT_RA_UpdateRaidTargetIcon(frame, raidid);
end

function CT_RA_UpdateMTs(forceUpdate)
	local tempOptions = CT_RAMenu_Options["temp"];
	local alphaRange = tempOptions.AlphaRange;
	local CT_RA_MainTanks = CT_RA_MainTanks;
	local num = 1;
	local frame = CT_RAMTGroup:GetAttribute("child1");
	while (frame and frame:IsShown()) do
		local val;
		local raidid = frame:GetAttribute("unit");  -- unit id of tank
		if (raidid) then
			val = UnitName(raidid);
		end
		if (val) then
			local frameParent = frame.frameParent;
			local raidid = frame.unit;  -- unit id of tank target
			if ( raidid ) then
				local mtid = raidid:match("^(%a+%d+)");
				local name, hppercent, mppercent;
				name = UnitName(raidid);
				if (UnitHealthMax(raidid) == 0) then
					hppercent = 0;
				else
					hppercent = UnitHealth(raidid) / UnitHealthMax(raidid);
				end
				if (UnitPowerMax(raidid) == 0) then
					mppercent = 0;
				else
					mppercent = UnitPower(raidid) / UnitPowerMax(raidid);
				end
				if ( forceUpdate or name ~= ( frame.unitName or "" ) or hppercent ~= ( frame.hppercent or -1 ) or mppercent ~= ( frame.mppercent or -1 ) or not UnitIsConnected(raidid) ) then
					if ( not UnitIsConnected(raidid) ) then
						frame.unitName = nil;
						frame.hppercent = nil;
						frame.mppercent = nil;
					else
						frame.unitName = name;
						frame.hppercent = hppercent;
						frame.mppercent = mppercent;
					end
					CT_RA_UpdateMT(raidid, mtid, frame, val);
				elseif (alphaRange) then
					frame:SetAlpha(CT_RA_UnitAlpha(raidid, nil));
				end
			end
		end
		num = num + 1;
		frame = CT_RAMTGroup:GetAttribute("child" .. num);
	end
	CT_RA_UpdateMTTTs(forceUpdate);
end

function CT_RA_UpdatePT(raidid, frame, val)
	local tempOptions = CT_RAMenu_Options["temp"];
	local frameName = frame.name;
	local mtwidth, ptwidth, height = CT_RA_GetMTFrameData();
	local alpha;

	if (not InCombatLockdown()) then
		frame:SetWidth(mtwidth);
		frame:SetHeight(height);
	end
	frame:SetBackdropColor(tempOptions["DefaultColor"]["r"], tempOptions["DefaultColor"]["g"], tempOptions["DefaultColor"]["b"], tempOptions["DefaultColor"]["a"]);

	if ( tempOptions["HideBorder"] ) then
		frame.Percent:SetPoint("TOP", frameName, "TOPLEFT", 47, -16);
		frame:SetBackdropBorderColor(1, 1, 1, 0);
		frame.HPBar:SetPoint("TOPLEFT", frameName, "TOPLEFT", 10, -19);
		frame.HPBG:SetPoint("TOPLEFT", frameName, "TOPLEFT", 10, -19);
	else
		frame:SetBackdropBorderColor(1, 1, 1, 1);
		frame.HPBar:SetPoint("TOPLEFT", frameName, "TOPLEFT", 10, -22);
		frame.HPBG:SetPoint("TOPLEFT", frameName, "TOPLEFT", 10, -22);
		frame.Percent:SetPoint("TOP", frameName, "TOPLEFT", 47, -18);
	end
	if ( raidid and UnitExists(raidid) and strlen(UnitName(raidid) or "") > 0 ) then
		local health, healthmax, mana, manamax = UnitHealth(raidid), UnitHealthMax(raidid), UnitPower(raidid), UnitPowerMax(raidid);
		frame.Name:SetHeight(15);
		frame.Status:Hide();
		frame.HPBar:Show();
		frame.HPBG:Show();
		frame.MPBar:Show();
		frame.MPBG:Show();
		frame.Name:Show();
		local manaType = UnitPowerType(raidid);
		if ( ( manaType == 0 and not tempOptions["HideMP"] ) or ( manaType > 0 and not tempOptions["HideRP"] and UnitIsPlayer(raidid) ) ) then
			local manaTbl = PowerBarColor[manaType];
			_G[frame:GetName() .. "MPBar"]:SetStatusBarColor(manaTbl.r, manaTbl.g, manaTbl.b);
			_G[frame:GetName() .. "MPBG"]:SetVertexColor(manaTbl.r, manaTbl.g, manaTbl.b, tempOptions["BGOpacity"]);
			frame.MPBar:SetMinMaxValues(0, manamax);
			frame.MPBar:SetValue(mana);
		else
			frame.MPBar:Hide();
			frame.MPBG:Hide();
		end
		if ( not UnitIsConnected(raidid) ) then
			frame.HPBar:Hide();
			frame.HPBG:Hide();
			frame.Percent:Hide();
			frame.MPBar:Hide();
			frame.MPBG:Hide();
			frame.Status:Show();
			frame.Status:SetText("OFFLINE");
		elseif ( UnitIsDead(raidid) or UnitIsGhost(raidid) ) then
			frame.HPBar:Hide();
			frame.HPBG:Hide();
			frame.Percent:Hide();
			frame.MPBar:Hide();
			frame.MPBG:Hide();
			frame.Status:Show();
			local isFD = CT_RA_CheckFD(UnitName(raidid), raidid);
			if ( isFD == 1 ) then
				frame.Status:SetText("Feign Death");
			elseif ( isFD == 2 ) then
				frame.Status:SetText("SoR");
			else
				frame.Status:SetText("DEAD");
			end
		elseif ( health and healthmax ) then
			if ( tempOptions["ShowHP"] and tempOptions["ShowHP"] <= 4 ) then
				frame.Percent:Show();
			else
				frame.Percent:Hide();
			end

			frame.HPBar:SetMinMaxValues(0, healthmax);
			frame.HPBar:SetValue(health);

			local percent;
			if (healthmax == 0) then
				percent = 0;
			else
				percent = health/healthmax;
			end
			frame.Percent:SetText(floor(percent*100+0.5) .. "%");
			if ( percent >= 0 and percent <= 1 ) then
				local r, g;
				if ( percent > 0.5 ) then
					g = 1;
					r = (1.0 - percent) * 2;
				else
					r = 1;
					g = percent * 2;
				end
				frame.HPBar:SetStatusBarColor(r, g, 0);
				frame.HPBG:SetVertexColor(r, g, 0, tempOptions["BGOpacity"]);
			end
			alpha = CT_RA_UnitAlpha(raidid, percent*100);
		else
			frame.HPBar:Hide();
			frame.HPBG:Hide();
		end
		frame.Name:SetText(UnitName(raidid));
		frame.Name:SetTextColor(0.5, 1, 0);
		frame.unitName = UnitName(raidid);
	else
		frame.Percent:Hide();
		frame.HPBar:Hide();
		frame.HPBG:Hide();
		frame.MPBar:Hide();
		frame.MPBG:Hide();
		frame.Status:Hide();
		frame.Name:SetText(val);
		frame.Name:SetHeight(30);
		frame.Name:SetTextColor(1, 0.82, 0);
	end
	if (not alpha) then
		alpha = CT_RA_UnitAlpha(raidid, nil);
	end
	frame:SetAlpha(alpha);
	CT_RA_UpdateRaidTargetIcon(frame, raidid);
end

function CT_RA_UpdatePTs(forceUpdate)
	local tempOptions = CT_RAMenu_Options["temp"];
	if ( CT_RA_PTargets ) then
		local alphaRange = tempOptions.AlphaRange;
		local num = 1;
		local frame = CT_RAPTGroup:GetAttribute("child1");
		while (frame and frame:IsShown()) do
			local val;
			local raidid = frame:GetAttribute("unit");  -- unit id of player
			if (raidid) then
				val = UnitName(raidid);
				if ( val ) then
					local name, hppercent, mppercent;
					name = UnitName(raidid);
					if (UnitHealthMax(raidid) == 0) then
						hppercent = 0;
					else
						hppercent = UnitHealth(raidid) / UnitHealthMax(raidid);
					end
					if (UnitPowerMax(raidid) == 0) then
						mppercent = 0;
					else
						mppercent = UnitPower(raidid) / UnitPowerMax(raidid);
					end
					if ( forceUpdate or name ~= ( frame.unitName or "" ) or hppercent ~= ( frame.hppercent or -1 ) or mppercent ~= ( frame.mppercent or -1 ) or not UnitIsConnected(raidid) ) then
						if ( not UnitIsConnected(raidid) ) then
							frame.unitName = nil;
							frame.hppercent = nil;
							frame.mppercent = nil;
						else
							frame.unitName = name;
							frame.hppercent = hppercent;
							frame.mppercent = mppercent;
						end
						CT_RA_UpdatePT(raidid, frame, val);
					elseif (alphaRange) then
						frame:SetAlpha(CT_RA_UnitAlpha(raidid, nil));
					end
				end
			end
			num = num + 1;
			frame = CT_RAPTGroup:GetAttribute("child" .. num);
		end
	end
	CT_RA_UpdatePTTs(forceUpdate);
end

function CT_RA_UpdatePTT(raidid, frame, val)
	local tempOptions = CT_RAMenu_Options["temp"];
	local frameName = frame.name;
	local mtwidth, ptwidth, height = CT_RA_GetMTFrameData();
	local alpha;

	if (not InCombatLockdown()) then
		frame:SetWidth(mtwidth);
		frame:SetHeight(height);
	end
	frame:SetBackdropColor(tempOptions["DefaultColor"]["r"], tempOptions["DefaultColor"]["g"], tempOptions["DefaultColor"]["b"], tempOptions["DefaultColor"]["a"]);
	if ( tempOptions["HideBorder"] ) then
		frame.Percent:SetPoint("TOP", frameName, "TOPLEFT", 47, -16);
		frame:SetBackdropBorderColor(1, 1, 1, 0);
		frame.HPBar:SetPoint("TOPLEFT", frameName, "TOPLEFT", 10, -19);
		frame.HPBG:SetPoint("TOPLEFT", frameName, "TOPLEFT", 10, -19);
	else
		frame:SetBackdropBorderColor(1, 1, 1, 1);
		frame.HPBar:SetPoint("TOPLEFT", frameName, "TOPLEFT", 10, -22);
		frame.HPBG:SetPoint("TOPLEFT", frameName, "TOPLEFT", 10, -22);
		frame.Percent:SetPoint("TOP", frameName, "TOPLEFT", 47, -18);
	end
	if ( raidid and UnitExists(raidid) and strlen(UnitName(raidid) or "") > 0 ) then
		local health, healthmax, mana, manamax = UnitHealth(raidid), UnitHealthMax(raidid), UnitPower(raidid), UnitPowerMax(raidid);
		frame.Name:SetHeight(15);
		frame.Status:Hide();
		frame.HPBar:Show();
		frame.HPBG:Show();
		frame.MPBar:Show();
		frame.MPBG:Show();
		frame.Name:Show();
		local manaType = UnitPowerType(raidid);
		if ( ( manaType == 0 and not tempOptions["HideMP"] ) or ( manaType > 0 and not tempOptions["HideRP"] and UnitIsPlayer(raidid) ) ) then
			local manaTbl = PowerBarColor[manaType];
			frame.MPBar:SetStatusBarColor(manaTbl.r, manaTbl.g, manaTbl.b);
			frame.MPBG:SetVertexColor(manaTbl.r, manaTbl.g, manaTbl.b, tempOptions["BGOpacity"]);
			frame.MPBar:SetMinMaxValues(0, manamax);
			frame.MPBar:SetValue(mana);
		else
			frame.MPBar:Hide();
			frame.MPBG:Hide();
		end
		if ( not UnitIsConnected(raidid) ) then
			frame.HPBar:Hide();
			frame.HPBG:Hide();
			frame.Percent:Hide();
			frame.MPBar:Hide();
			frame.MPBG:Hide();
			frame.Status:Show();
			frame.Status:SetText("OFFLINE");
		elseif ( UnitIsDead(raidid) or UnitIsGhost(raidid) ) then
			frame.HPBar:Hide();
			frame.HPBG:Hide();
			frame.Percent:Hide();
			frame.MPBar:Hide();
			frame.MPBG:Hide();
			frame.Status:Show();
			local isFD = CT_RA_CheckFD(UnitName(raidid), raidid);
			if ( isFD == 1 ) then
				frame.Status:SetText("Feign Death");
			elseif ( isFD == 2 ) then
				frame.Status:SetText("SoR");
			else
				frame.Status:SetText("DEAD");
			end
		elseif ( health and healthmax ) then
			if ( tempOptions["ShowHP"] and tempOptions["ShowHP"] <= 4 ) then
				frame.Percent:Show();
			else
				frame.Percent:Hide();
			end

			frame.HPBar:SetMinMaxValues(0, healthmax);
			frame.HPBar:SetValue(health);

			local percent;
			if (healthmax == 0) then
				percent = 0;
			else
				percent = health/healthmax;
			end
			frame.Percent:SetText(floor(percent*100+0.5) .. "%");
			if ( percent >= 0 and percent <= 1 ) then
				local r, g;
				if ( percent > 0.5 ) then
					g = 1;
					r = (1.0 - percent) * 2;
				else
					r = 1;
					g = percent * 2;
				end
				frame.HPBar:SetStatusBarColor(r, g, 0);
				frame.HPBG:SetVertexColor(r, g, 0, tempOptions["BGOpacity"]);
			end
			alpha = CT_RA_UnitAlpha(raidid, percent*100);
		else
			frame.HPBar:Hide();
			frame.HPBG:Hide();
		end
		frame.Name:SetText(UnitName(raidid));
		if ( UnitCanAttack("player", raidid) ) then
			frame.Name:SetTextColor(1, 0.5, 0);
		else
			frame.Name:SetTextColor(0.5, 1, 0);
		end
		frame.unitName = UnitName(raidid);
	else
		frame.Percent:Hide();
		frame.HPBar:Hide();
		frame.HPBG:Hide();
		frame.MPBar:Hide();
		frame.MPBG:Hide();
		frame.Status:Hide();
		frame.Name:SetText("<No Target>");
		frame.Name:SetHeight(30);
		frame.Name:SetTextColor(1, 0.82, 0);
	end
	if (not alpha) then
		alpha = CT_RA_UnitAlpha(raidid, nil);
	end
	frame:SetAlpha(alpha);
	CT_RA_UpdateRaidTargetIcon(frame, raidid);
end

function CT_RA_UpdatePTTs(forceUpdate)
	local tempOptions = CT_RAMenu_Options["temp"];
	if ( tempOptions["ShowPTT"] ) then
		local alphaRange = tempOptions.AlphaRange;
		local num = 1;
		local frame = CT_RAPTTGroup:GetAttribute("child1");
		while (frame and frame:IsShown()) do
			local val;
			local raidid = frame:GetAttribute("unit"); -- unit id of person
			if (raidid) then
				val = UnitName(raidid);
			end
			if (val) then
				local raidid = frame.unit;  -- unit id of person's target
				if ( raidid ) then
					local name, hppercent, mppercent;
					name = UnitName(raidid);
					if (UnitHealthMax(raidid) == 0) then
						hppercent = 0;
					else
						hppercent = UnitHealth(raidid) / UnitHealthMax(raidid);
					end
					if (UnitPowerMax(raidid) == 0) then
						mppercent = 0;
					else
						mppercent = UnitPower(raidid) / UnitPowerMax(raidid);
					end
					if ( forceUpdate or name ~= ( frame.unitName or "" ) or hppercent ~= ( frame.hppercent or -1 ) or mppercent ~= ( frame.mppercent or -1 ) or not UnitIsConnected(raidid) ) then
						if ( not UnitIsConnected(raidid) ) then
							frame.unitName = nil;
							frame.hppercent = nil;
							frame.mppercent = nil;
						else
							frame.unitName = name;
							frame.hppercent = hppercent;
							frame.mppercent = mppercent;
						end
						CT_RA_UpdatePTT(raidid, frame, val);
					elseif (alphaRange) then
						frame:SetAlpha(CT_RA_UnitAlpha(raidid, nil));
					end
				end
			end
			num = num + 1;
			frame = CT_RAPTTGroup:GetAttribute("child" .. num);
		end
	end
end

function CT_RA_UpdateMTTT(raidid, mtid, frame, val)
	local tempOptions = CT_RAMenu_Options["temp"];
	local frameName = frame.name;
	local mtwidth, ptwidth, height = CT_RA_GetMTFrameData();
	local alpha;

	if (not InCombatLockdown()) then
		frame:SetWidth(mtwidth);
		frame:SetHeight(height);
	end
	if ( UnitExists(raidid.."target") and not UnitIsUnit(mtid, raidid) and
	     not UnitIsPlayer(raidid.."target") and not tempOptions["HideColorChange"] ) then
		frame:SetBackdropColor(1, 0, 0, 0.5);
	else
		local defaultColors = tempOptions.DefaultColor;
		frame:SetBackdropColor(defaultColors.r, defaultColors.g, defaultColors.b, defaultColors.a);
	end
	if ( tempOptions["HideBorder"] ) then
		frame.Percent:SetPoint("TOP", frameName, "TOPLEFT", 47, -16);
		frame:SetBackdropBorderColor(1, 1, 1, 0);
		frame.HPBar:SetPoint("TOPLEFT", frameName, "TOPLEFT", 10, -19);
		frame.HPBG:SetPoint("TOPLEFT", frameName, "TOPLEFT", 10, -19);
	else
		frame:SetBackdropBorderColor(1, 1, 1, 1);
		frame.HPBar:SetPoint("TOPLEFT", frameName, "TOPLEFT", 10, -22);
		frame.HPBG:SetPoint("TOPLEFT", frameName, "TOPLEFT", 10, -22);
		frame.Percent:SetPoint("TOP", frameName, "TOPLEFT", 47, -18);
	end
	if ( raidid and UnitExists(raidid) and strlen(UnitName(raidid) or "") > 0 ) then
		local health, healthmax, mana, manamax = UnitHealth(raidid), UnitHealthMax(raidid), UnitPower(raidid), UnitPowerMax(raidid);
		frame.Name:SetHeight(15);
		frame.Status:Hide();
		frame.HPBar:Show();
		frame.HPBG:Show();
		frame.MPBar:Show();
		frame.MPBG:Show();
		frame.Name:Show();
		local manaType = UnitPowerType(raidid);
		if ( ( manaType == 0 and not tempOptions["HideMP"] ) or ( manaType > 0 and not tempOptions["HideRP"] and UnitIsPlayer(raidid) ) ) then
			local manaTbl = PowerBarColor[manaType];
			frame.MPBar:SetStatusBarColor(manaTbl.r, manaTbl.g, manaTbl.b);
			frame.MPBG:SetVertexColor(manaTbl.r, manaTbl.g, manaTbl.b, tempOptions["BGOpacity"]);
			frame.MPBar:SetMinMaxValues(0, manamax);
			frame.MPBar:SetValue(mana);
		else
			frame.MPBar:Hide();
			frame.MPBG:Hide();
		end
		if ( not UnitIsConnected(raidid) ) then
			frame.HPBar:Hide();
			frame.HPBG:Hide();
			frame.Percent:Hide();
			frame.MPBar:Hide();
			frame.MPBG:Hide();
			frame.Status:Show();
			frame.Status:SetText("OFFLINE");
		elseif ( UnitIsDead(raidid) or UnitIsGhost(raidid) ) then
			frame.HPBar:Hide();
			frame.HPBG:Hide();
			frame.Percent:Hide();
			frame.MPBar:Hide();
			frame.MPBG:Hide();
			frame.Status:Show();
			local isFD = CT_RA_CheckFD(UnitName(raidid), raidid);
			if ( isFD == 1 ) then
				frame.Status:SetText("Feign Death");
			elseif ( isFD == 2 ) then
				frame.Status:SetText("SoR");
			else
				frame.Status:SetText("DEAD");
			end
		elseif ( health and healthmax ) then
			if ( tempOptions["ShowHP"] and tempOptions["ShowHP"] <= 4 ) then
				frame.Percent:Show();
			else
				frame.Percent:Hide();
			end

			frame.HPBar:SetMinMaxValues(0, healthmax);
			frame.HPBar:SetValue(health);

			local percent;
			if (healthmax == 0) then
				percent = 0;
			else
				percent = health/healthmax;
			end
			frame.Percent:SetText(floor(percent*100+0.5) .. "%");
			if ( percent >= 0 and percent <= 1 ) then
				local r, g;
				if ( percent > 0.5 ) then
					g = 1;
					r = (1.0 - percent) * 2;
				else
					r = 1;
					g = percent * 2;
				end
				frame.HPBar:SetStatusBarColor(r, g, 0);
				frame.HPBG:SetVertexColor(r, g, 0, tempOptions["BGOpacity"]);
			end
			alpha = CT_RA_UnitAlpha(raidid, percent*100);
		else
			frame.HPBar:Hide();
			frame.HPBG:Hide();
		end
		frame.Name:SetText(UnitName(raidid));
		if ( UnitCanAttack("player", raidid) ) then
			frame.Name:SetTextColor(1, 0.5, 0);
		else
			frame.Name:SetTextColor(0.5, 1, 0);
		end
		frame.unitName = UnitName(raidid);
	else
		frame.Percent:Hide();
		frame.HPBar:Hide();
		frame.HPBG:Hide();
		frame.MPBar:Hide();
		frame.MPBG:Hide();
		frame.Status:Hide();
		frame.Name:SetText("<No Target>");
		frame.Name:SetHeight(30);
		frame.Name:SetTextColor(1, 0.82, 0);
	end
	if (not alpha) then
		alpha = CT_RA_UnitAlpha(raidid, nil);
	end
	frame:SetAlpha(alpha);
	CT_RA_UpdateRaidTargetIcon(frame, raidid);
end

function CT_RA_UpdateMTTTs(forceUpdate)
	local tempOptions = CT_RAMenu_Options["temp"];
	if ( not tempOptions["ShowMTTT"] ) then
		return;
	end
	local alphaRange = tempOptions.AlphaRange;
	local CT_RA_MainTanks = CT_RA_MainTanks;
	local num = 1;
	local frame = CT_RAMTTGroup:GetAttribute("child1");
	while (frame and frame:IsShown()) do
		local val;
		local raidid = frame:GetAttribute("unit");  -- unit id of tank
		if (raidid) then
			val = UnitName(raidid);
		end
		if (val) then
			local raidid = frame.unit;  -- unit id of tank target target
			if ( raidid ) then
				local mtid = raidid:match("^(%a+%d+)");
				local name, hppercent, mppercent;
				name = UnitName(raidid);
				if (UnitHealthMax(raidid) == 0) then
					hppercent = 0;
				else
					hppercent = UnitHealth(raidid) / UnitHealthMax(raidid);
				end
				if (UnitPowerMax(raidid) == 0) then
					mppercent = 0;
				else
					mppercent = UnitPower(raidid) / UnitPowerMax(raidid);
				end
				if ( forceUpdate or name ~= ( frame.unitName or "" ) or hppercent ~= ( frame.hppercent or -1 ) or mppercent ~= ( frame.mppercent or -1 ) or not UnitIsConnected(raidid) ) then
					if ( not UnitIsConnected(raidid) ) then
						frame.unitName = nil;
						frame.hppercent = nil;
						frame.mppercent = nil;
					else
						frame.unitName = name;
						frame.hppercent = hppercent;
						frame.mppercent = mppercent;
					end
					if ( name == UnitName("player") and not UnitIsPlayer(mtid .. "target") ) then
						local isMT;
						for k, v in pairs(CT_RA_MainTanks) do
							if ( v == UnitName("player") ) then
								isMT = 1;
								break;
							end
						end
						if ( not isMT and not CT_RA_UpdateFrame.hasAggroAlert and tempOptions["AggroNotifier"] ) then
							CT_RA_UpdateFrame.hasAggroAlert = 15;
							CT_RA_WarningFrame:AddMessage("AGGRO FROM " .. UnitName(mtid .. "target") .. "!", 1, 0, 0, 1, UIERRORS_HOLD_TIME);
							if ( tempOptions["AggroNotifierSound"] ) then
								PlaySoundFile("Sound\\Spells\\PVPFlagTakenHorde.wav");
							end
						end
					end
					CT_RA_UpdateMTTT(raidid, mtid, frame, val);
				elseif (alphaRange) then
					frame:SetAlpha(CT_RA_UnitAlpha(raidid, nil));
				end
			end
		end
		num = num + 1;
		frame = CT_RAMTTGroup:GetAttribute("child" .. num);
	end
end

function CT_RA_UpdateGroupVisibility(num, noStatusUpdate)
	local tempOptions = CT_RAMenu_Options["temp"];
	local group = _G["CT_RAGroup" .. num];
	local drag = _G["CT_RAGroupDrag" .. num];
	if (not InCombatLockdown()) then
		if ( not tempOptions["ShowGroups"] or not tempOptions["ShowGroups"][num] or not group.hasMembers ) then
			drag:Hide();
			frameCache[group].GroupName:Hide();
		elseif ( group.hasMembers ) then
			if ( tempOptions["LockGroups"] ) then
				drag:Hide();
			else
				drag:Show();
			end
			if ( tempOptions["HideNames"] ) then
				frameCache[group].GroupName:Hide();
			else
				frameCache[group].GroupName:Show();
			end
		end
	end

	local frame = group:GetAttribute("child1");
	local i = 1;
	while ( frame ) do
		if ( not noStatusUpdate and tempOptions["ShowGroups"] and tempOptions["ShowGroups"][num] ) then
			CT_RA_UpdateUnitStatus(frame);
		end

		i = i + 1;
		frame = group:GetAttribute("child" .. i);
	end
end

function CT_RA_UpdateVisibility(noStatusUpdate)
	for i = 1, CT_RA_MaxGroups, 1 do
		CT_RA_UpdateGroupVisibility(i, noStatusUpdate);
	end
	if ( CT_RA_MainTanks ) then
		CT_RA_UpdateMTs();
	end
	if ( CT_RA_PTargets ) then
		CT_RA_UpdatePTs();
	end
end

local function CT_RA_preparePreCreate(frame)
--	frame.initPre = true;
	if (not frame.initPre) then
		frame.initPre = true;

		local shown = frame:IsShown();
		local startingIndex = frame:GetAttribute("startingIndex");
		frame:Hide();
		frame:Show();

		local num = 0;
		local temp = frame:GetAttribute("child1");
		while (temp) do
			num = num + 1;
			temp = frame:GetAttribute("child" .. num + 1);
		end
		local qty = 5 - num;
		if (qty > 0) then
			frame:Hide();
			frame:SetAttribute("startingIndex", -(qty - 1));
			frame:Show();
			frame:SetAttribute("startingIndex", startingIndex);
		end
		if (shown) then
			frame:Show();
		else
			frame:Hide();
		end
	end
end

local function prepareFrame(frame, dragFrame, template, initFunction, title, splitView, useModifier, isPT)
	local tempOptions = CT_RAMenu_Options["temp"];
	local numRaidMembers = CT_RA_NumRaidMembers;

	local showReversed = tempOptions["ShowReversed"];
	local showHorizontal = splitView == nil and tempOptions["ShowHorizontal"];
	local hideBorder = tempOptions["HideBorder"];
	local removeSpace = hideBorder and tempOptions["HideSpace"];

	if ( not frame.init ) then
		frame.isPT = isPT;
		frame:SetAttribute("template", template);
		frame.GroupName = frameCache[frame].GroupName;
		frame.id = frame:GetID();
		frame.name = frame:GetName();
		frame.frameParent = frame:GetParent();
		frame.GroupName:ClearAllPoints();
		frame.GroupName:SetPoint("CENTER", dragFrame);
		frame.useModifier = useModifier;
		if ( title ) then
			frame.GroupName:SetText(title);
		end
		frame.init = true;
	end

	-- Clear all points for each of the child frames.
	-- Not doing so causes a problem when switching between
	-- horizontal and vertical orientation. We may end up
	-- with multiple points on each frame because the secure
	-- code (configureChildren in SecureGroupHeaders.lua)
	-- does not clear all points before it sets them.
	local num = 0;
	local temp = frame:GetAttribute("child1");
	while (temp) do
		temp:ClearAllPoints();
		num = num + 1;
		temp = frame:GetAttribute("child" .. num + 1);
	end

	-- Change this attribute each time in case something has changed.
	frame:SetAttribute("initialConfigFunction", initFunction(frame) );

	local splitOffset = ( hideBorder and 5 ) or 0;

	if ( showReversed ) then
		if ( showHorizontal ) then
			frame:SetAttribute("point", "RIGHT");
			CT_RA_LinkDrag(frame, dragFrame, "BOTTOMLEFT", "BOTTOMLEFT", 5, 14);
		elseif ( splitView == -1 ) then
			frame:SetAttribute("point", "BOTTOM");
			CT_RA_LinkDrag(frame, dragFrame, "BOTTOMRIGHT", "BOTTOM", splitOffset, 14);
		elseif ( splitView == 1 ) then
			frame:SetAttribute("point", "BOTTOM");
			CT_RA_LinkDrag(frame, dragFrame, "BOTTOMLEFT", "BOTTOM", -splitOffset, 14);
		else
			frame:SetAttribute("point", "BOTTOM");
			CT_RA_LinkDrag(frame, dragFrame, "BOTTOM", "BOTTOM", 0, 14);
		end
	else
		frame:SetAttribute("sortDir", "ASC");
		if ( showHorizontal ) then
			frame:SetAttribute("point", "RIGHT");
			CT_RA_LinkDrag(frame, dragFrame, "TOPLEFT", "TOPLEFT", 5, -14);
		elseif ( splitView == -1 ) then
			frame:SetAttribute("point", "TOP");
			CT_RA_LinkDrag(frame, dragFrame, "TOPRIGHT", "TOP", splitOffset, -14);
		elseif ( splitView == 1 ) then
			frame:SetAttribute("point", "TOP");
			CT_RA_LinkDrag(frame, dragFrame, "TOPLEFT", "TOP", -splitOffset, -14);
		else
			frame:SetAttribute("point", "TOP");
			CT_RA_LinkDrag(frame, dragFrame, "TOP", "TOP", 0, -14);
		end
	end

	if ( removeSpace ) then
		if ( showHorizontal ) then
			frame:SetAttribute("xOffset", 10);
			frame:SetAttribute("yOffset", 0);
		else
			frame:SetAttribute("xOffset", 0);
			frame:SetAttribute("yOffset", ( showReversed and -10 ) or 10);
		end
	else
		frame:SetAttribute("xOffset", 0);
		frame:SetAttribute("yOffset", 0);
	end
end

local function CT_RA_prepareGroups()
	-- Prepare normal groups.
	if (InCombatLockdown()) then
		return;
	end

	local tempOptions = CT_RAMenu_Options["temp"];
	local showGroups = tempOptions["ShowGroups"];
	local subSortByName = tempOptions["SubSortByName"];
	local sorting = tempOptions["SORTTYPE"];
	local frame;

	for i = 1, CT_RA_MaxGroups, 1 do
		frame = _G["CT_RAGroup"..i];

	        local oldIgnore = frame:GetAttribute("_ignore");
	        frame:SetAttribute("_ignore", "attributeChanges");

		prepareFrame(frame, _G["CT_RAGroupDrag"..i], "CT_RAGroupMemberTemplate", CT_RA_SetupFrame)
		frame:SetAttribute("groupFilter", (sorting=="class" and CT_RA_ClassIndices[i] ) or i);
		if ( subSortByName ) then
			frame:SetAttribute("sortMethod", "NAME");
		else
			frame:SetAttribute("sortMethod", "INDEX");
		end

	        frame:SetAttribute("_ignore", oldIgnore);
	        frame:SetAttribute("_update", frame:GetAttribute("_update"));

		CT_RA_preparePreCreate(frame);
	end
end

local function CT_RA_prepareMTs()
	-- Prepare Main Tank Target and Main Tank Target's Target frames.
	if (InCombatLockdown()) then
		return;
	end

	local tempOptions = CT_RAMenu_Options["temp"];
	local showMTT = tempOptions["ShowMTTT"] or false;
	local sortMTs = tempOptions["SortMTs"];
	local frame, list, num, obj;

	-- Build comma separated list of Main Tank names
	list = "";
	num = 0;
	if ( not tempOptions["HideMTs"] ) then
		for i = 1, 10, 1 do
			obj = CT_RA_MainTanks[i];
			if ( obj ) then
				list = list .. obj .. ",";
				num = num + 1;
				if ( num == tempOptions["ShowNumMTs"] ) then
					break;
				end
			end
		end
		list = strsub(list, 0, -2);
	end

	-- Main Tanks
	frame = CT_RAMTGroup;

        local oldIgnore = frame:GetAttribute("_ignore");
        frame:SetAttribute("_ignore", "attributeChanges");

	prepareFrame(frame, CT_RAMTGroupDrag, "CT_RAMTMemberTemplate", CT_RA_SetupMTFrame, "MT Targets", showMTT and -1, "target");
	if (sortMTs) then
		frame:SetAttribute("sortMethod", "NAME");
	else
		frame:SetAttribute("sortMethod", "NAMELIST");
	end
	frame:SetAttribute("nameList", list);

        frame:SetAttribute("_ignore", oldIgnore);
        frame:SetAttribute("_update", frame:GetAttribute("_update"));

	CT_RA_preparePreCreate(frame);

	-- Main Tank Target's Target
	if ( showMTT ) then
		frame = CT_RAMTTGroup;

	        local oldIgnore = frame:GetAttribute("_ignore");
        	frame:SetAttribute("_ignore", "attributeChanges");

		prepareFrame(frame, CT_RAMTGroupDrag, "CT_RAMTMemberTemplate", CT_RA_SetupMTFrame, nil, 1, "targettarget");
		if (sortMTs) then
			frame:SetAttribute("sortMethod", "NAME");
		else
			frame:SetAttribute("sortMethod", "NAMELIST");
		end
		frame:SetAttribute("nameList", list);

	        frame:SetAttribute("_ignore", oldIgnore);
        	frame:SetAttribute("_update", frame:GetAttribute("_update"));

		CT_RA_preparePreCreate(frame);
	end
end

local function CT_RA_preparePTs()
	-- Player Tanks and Player Tanks' Targets
	if (InCombatLockdown()) then
		return;
	end

	local tempOptions = CT_RAMenu_Options["temp"];
	local showPTT = tempOptions["ShowPTT"] or false;
	local sortPTs = tempOptions["SortPTs"];
	local frame, list, num, obj;

	-- Build comma separated list of Player Tank names
	list = "";
	num = 0;
	for i = 1, 10, 1 do
		obj = CT_RA_PTargets[i];
		if ( obj ) then
			list = list .. obj .. ",";
			num = num + 1;
		end
	end
	list = strsub(list, 0, -2);

	-- Player Tanks
	frame = CT_RAPTGroup;

        local oldIgnore = frame:GetAttribute("_ignore");
        frame:SetAttribute("_ignore", "attributeChanges");

	prepareFrame(frame, CT_RAPTGroupDrag, "CT_RAMTMemberTemplate", CT_RA_SetupMTFrame, "PTargets", showPTT and -1, nil, true);
	if (sortPTs) then
		frame:SetAttribute("sortMethod", "NAME");
	else
		frame:SetAttribute("sortMethod", "NAMELIST");
	end
	frame:SetAttribute("nameList", list);

        frame:SetAttribute("_ignore", oldIgnore);
        frame:SetAttribute("_update", frame:GetAttribute("_update"));

	CT_RA_preparePreCreate(frame);

	-- Player Tanks' Targets
	if ( showPTT ) then
		frame = CT_RAPTTGroup;

	        local oldIgnore = frame:GetAttribute("_ignore");
        	frame:SetAttribute("_ignore", "attributeChanges");

		prepareFrame(frame, CT_RAPTGroupDrag, "CT_RAMTMemberTemplate", CT_RA_SetupMTFrame, nil, 1, "target", true);
		if (sortPTs) then
			frame:SetAttribute("sortMethod", "NAME");
		else
			frame:SetAttribute("sortMethod", "NAMELIST");
		end
		frame:SetAttribute("nameList", list);

	        frame:SetAttribute("_ignore", oldIgnore);
        	frame:SetAttribute("_update", frame:GetAttribute("_update"));

		CT_RA_preparePreCreate(frame);
	end
end

function CT_RA_UpdateRaidFrames()
	if (InCombatLockdown()) then
		return;
	end

	local tempOptions = CT_RAMenu_Options["temp"];
	local numRaidMembers = CT_RA_NumRaidMembers;

	local showGroups = tempOptions["ShowGroups"];
	local lockGroups = tempOptions["LockGroups"];
	local hideNames = tempOptions["HideNames"];

	-- Normal groups
	for i = 1, CT_RA_MaxGroups, 1 do
		if ( numRaidMembers > 0 and showGroups and showGroups[i] ) then
			_G["CT_RAGroup"..i]:Show();
		else
			_G["CT_RAGroup"..i]:Hide();
		end
	end

	-- Main Tanks
	if ( not tempOptions["HideMTs"] and numRaidMembers > 0 and next(CT_RA_MainTanks) ) then
		CT_RAMTGroup:Show();
		if ( hideNames ) then
			CT_RAMTGroup.GroupName:Hide();
		else
			CT_RAMTGroup.GroupName:Show();
		end
		if ( lockGroups ) then
			CT_RAMTGroupDrag:Hide();
		else
			CT_RAMTGroupDrag:Show();
		end
	else
		CT_RAMTGroup:Hide();
		CT_RAMTGroupDrag:Hide();
		CT_RAMTGroup.GroupName:Hide();
	end

	-- Main Tank Target's Target
	if ( numRaidMembers > 0 and tempOptions["ShowMTTT"] ) then
		if ( next(CT_RA_MainTanks) ) then
			CT_RAMTTGroup:Show();
		else
			CT_RAMTTGroup:Hide();
		end
	else
		CT_RAMTTGroup:Hide();
	end

	-- Player Targets
	if ( numRaidMembers > 0 and next(CT_RA_PTargets) ) then
		CT_RAPTGroup:Show();
		if ( hideNames ) then
			CT_RAPTGroup.GroupName:Hide();
		else
			CT_RAPTGroup.GroupName:Show();
		end
		if ( lockGroups ) then
			CT_RAPTGroupDrag:Hide();
		else
			CT_RAPTGroupDrag:Show();
		end
	else
		CT_RAPTGroup:Hide();
		CT_RAPTGroupDrag:Hide();
	end

	-- Player Target's Target
	if ( numRaidMembers > 0 and tempOptions["ShowPTT"] ) then
		if ( next(CT_RA_PTargets) ) then
			CT_RAPTTGroup:Show();
		else
			CT_RAPTTGroup:Hide();
		end
	else
		CT_RAPTTGroup:Hide();
	end
end

function CT_RA_UpdateRaidFrameData()
	if (InCombatLockdown()) then
		return;
	end

	-- Main Tank Targets and Main Tank Targets' Targets
	CT_RA_prepareMTs();

	-- Player Tanks and Player Tanks' Targets
	CT_RA_preparePTs();

	CT_RA_UpdateRaidFrames();
end

function CT_RA_UpdateRaidFrameOptions()
	if (InCombatLockdown()) then
		return;
	end

	-- Normal groups
	CT_RA_prepareGroups();

	-- Main Tank Targets and Main Tank Targets' Targets
	CT_RA_prepareMTs();

	-- Player Tanks and Player Tanks' Targets
	CT_RA_preparePTs();

	CT_RAPTGroup.GroupName:ClearAllPoints();
	CT_RAPTGroup.GroupName:SetPoint("CENTER", CT_RAPTGroupDrag);

	CT_RA_UpdateRaidFrames();
end

function CT_RA_GetFrameData(id)
	local tempOptions = CT_RAMenu_Options["temp"];
	local width, height, scale = 90, tempOptions["MemberHeight"], tempOptions["WindowScaling"];
	local name, rank, subgroup, level, class, fileName, zone, online, isDead = GetRaidRosterInfo(id);

	if ( CT_RA_HideClassManaBar(class) ) then
		height = height - 4;
	end

	if ( tempOptions["HideBorder"] ) then
		if ( not online ) then height = 37; else height = height - 3; end
	else
		if ( not online ) then height = 40; end
	end

	return width, height, scale;
end

function CT_RA_GetMTFrameData()
	local tempOptions = CT_RAMenu_Options["temp"];
	if ( tempOptions["HideBorder"] ) then
		return 90, 90, 36;
	else
		return 90, 90, 40;
	end
end

function CT_RA_SetupFrame(frame)
	-- Create configuration code snippet for initial configuration of buttons in this frame.
	local configCode;
	local width, height, scale = CT_RA_GetFrameData(-1);
	configCode = [=[self:SetWidth(]=] .. width .. [=[); ]=]
		.. [=[self:SetHeight(]=] .. height .. [=[); ]=];
	if ( CT_RAMenu_Options.temp.SubSortByName ) then
		configCode = configCode .. [=[self:SetAttribute("sortMethod", "NAME"); ]=];
	else
		configCode = configCode .. [=[self:SetAttribute("sortMethod", "INDEX"); ]=];
	end
	return configCode;
end

function CT_RA_SetupMTFrame(frame)
	-- Create configuration code snippet for initial configuration of buttons in this frame.
	local configCode, width;
	local mtwidth, ptwidth, height = CT_RA_GetMTFrameData();
	if ( frame.isPT ) then
		width = ptwidth;
	else
		width = mtwidth;
	end
	configCode = [=[self:SetWidth(]=] .. width .. [=[); ]=]
		.. [=[self:SetHeight(]=] .. height .. [=[); ]=];
	if ( frame.useModifier ) then
		configCode = configCode .. [=[self:SetAttribute("unitsuffix", "]=] .. frame.useModifier .. [=["); ]=];
	end
	return configCode;
end

function CT_RA_UpdateRaidGroup(updateType)
	local tempOptions = CT_RAMenu_Options["temp"];
	local sortType = tempOptions["SORTTYPE"];
	if ( sortType == "group" ) then
		CT_RA_SortByGroup();
	elseif ( sortType == "class" ) then
		CT_RA_SortByClass();
	end
	local numRaidMembers = GetNumRaidMembers();
	local name, rank, subgroup, level, class, fileName, zone, online, isDead;

	for i=1, MAX_RAID_MEMBERS do
		if ( i <= numRaidMembers ) then
			local unitid = "raid" .. i;
			name, rank, subgroup, level, class, fileName, zone, online, isDead = GetRaidRosterInfo(i);
			if ( UnitIsDead(unitid) or UnitIsGhost(unitid) ) then
				isDead = 1;
			end
			-- Set Rank
			if ( name == UnitName("player") ) then
				if ( rank >= 2 and CT_RA_Level and CT_RA_Level < 2 ) then
					-- Check if we have to auto-promote people
					for j = 1, numRaidMembers, 1 do
						local pName, pRank = GetRaidRosterInfo(j);
						if ( pRank < 1 and pName and CT_RATab_AutoPromotions and CT_RATab_AutoPromotions[pName] ) then
							PromoteToAssistant(pName);
							CT_RA_Print("<CTRaid> Auto-Promoted |c00FFFFFF" .. pName .. "|r.", 1, 0.5, 0);
						end
					end
				end
				CT_RA_Level = rank;
			end
			local button = CT_RA_UnitIDFrameMap["raid"..i];
			if ( button ) then
				local group = button.frameParent;
				if ( group ) then
					if ( tempOptions["ShowGroups"] and tempOptions["ShowGroups"][group.id] ) then
						button.Name:SetText(name);
						button.unitName = name;
						if ( button.update or updateType == 0 ) then
							CT_RA_UpdateUnitStatus(button);
						else
							CT_RA_UpdateUnitDead(button);
							local stats = CT_RA_Stats[name];
							if ( updateType == 2 and stats ) then
								CT_RA_UpdateUnitBuffs(stats["Buffs"], button, name);
							end
						end
						button.update = nil;
					end
				end
			end
		end
	end
	CT_RA_UpdateVisibility(1);
end

function CT_RA_MemberFrame_OnEnter(self)
	local tempOptions = CT_RAMenu_Options["temp"];
	if ( SpellIsTargeting() ) then
		SetCursor("CAST_CURSOR");
	end
	local parent = self.frameParent;
	local id = self.id;
	if ( strsub(self.name, 1, 12) == "CT_RAMTGroup" ) then
		local name;
		if ( CT_RA_MainTanks[id] ) then
			name = CT_RA_MainTanks[id];
		end
		for i = 1, GetNumRaidMembers(), 1 do
			local memberName = GetRaidRosterInfo(i);
			if ( name == memberName ) then
				id = i;
				break;
			end
		end
	elseif ( strsub(self.name, 1, 12) == "CT_RAPTGroup" ) then
		local name;
		if ( CT_RA_PTargets[id] ) then
			name = CT_RA_PTargets[id];
		end
		for i = 1, GetNumRaidMembers(), 1 do
			local memberName = GetRaidRosterInfo(i);
			if ( name == memberName ) then
				id = i;
				break;
			end
		end
	end
	local unitid = "raid"..id;
	if ( SpellIsTargeting() and not SpellCanTargetUnit(unitid) ) then
		SetCursor("CAST_ERROR_CURSOR");
	end
	if ( tempOptions["HideTooltip"] ) then
		return;
	end
	local xp = "LEFT";
	local yp = "BOTTOM";
	local xthis, ythis = self:GetCenter();
	local xui, yui = UIParent:GetCenter();
	if ( xthis < xui ) then
		xp = "RIGHT";
	end
	if ( ythis < yui ) then
		yp = "TOP";
	end
	GameTooltip:SetOwner(self, "ANCHOR_" .. yp .. xp);
	local name, rank, subgroup, level, class, fileName, zone, online, isDead = GetRaidRosterInfo(id);
	local stats = CT_RA_Stats[name];
	local version = stats;
	if ( version ) then
		version = version["Version"];
	end
	if ( name == UnitName("player") ) then
		zone = GetRealZoneText();
		version = CT_RA_VersionNumber;
	end
	local color = RAID_CLASS_COLORS[fileName];
	if ( not color ) then
		color = { ["r"] = 1, ["g"] = 1, ["b"] = 1 };
	end
	GameTooltip:AddDoubleLine(name, level, color.r, color.g, color.b, 1, 1, 1);
	if ( UnitRace(unitid) and class ) then
		GameTooltip:AddLine(UnitRace(unitid) .. " " .. class, 1, 1, 1);
	end
	GameTooltip:AddLine(zone, 1, 1, 1);

	if ( not version ) then
		if ( not stats or not stats["Reporting"] ) then
			GameTooltip:AddLine("No CTRA Found", 0.7, 0.7, 0.7);
		else
			GameTooltip:AddLine("CTRA <1.077", 1, 1, 1);
		end
	else
		GameTooltip:AddLine("CTRA " .. version, 1, 1, 1);
	end

	if ( stats and stats["AFK"] ) then
		if ( type(stats["AFK"][1]) == "string" ) then
			GameTooltip:AddLine("AFK: " .. stats["AFK"][1]);
		end
		GameTooltip:AddLine("AFK for " .. CT_RA_FormatTime(stats["AFK"][2]));
	elseif ( CT_RA_Stats[name] and stats["DND"] ) then
		if ( type(stats["DND"][1]) == "string" ) then
			GameTooltip:AddLine("DND: " .. stats["DND"][1]);
		end
		GameTooltip:AddLine("DND for " .. CT_RA_FormatTime(stats["DND"][2]));
	end
	if ( stats and stats["Offline"] ) then
		GameTooltip:AddLine("Offline for " .. CT_RA_FormatTime(stats["Offline"]));
	elseif ( stats and stats["FD"] ) then
		if ( stats["FD"] < 360 ) then
			GameTooltip:AddLine("Dying in " .. CT_RA_FormatTime(360-stats["FD"]));
		end
	elseif ( stats and stats["Dead"] ) then
		if ( stats["Dead"] < 360 and not UnitIsGhost(unitid) ) then
			GameTooltip:AddLine("Releasing in " .. CT_RA_FormatTime(360-stats["Dead"]));
		else
			GameTooltip:AddLine("Dead for " .. CT_RA_FormatTime(stats["Dead"]));
		end
	end
	if ( stats and stats["Rebirth"] and stats["Rebirth"] > 0 ) then
		GameTooltip:AddLine("Rebirth up in: " .. CT_RA_FormatTime(stats["Rebirth"]));
	elseif ( stats and stats["Reincarnation"] and stats["Reincarnation"] > 0 ) then
		GameTooltip:AddLine("Ankh up in: " .. CT_RA_FormatTime(stats["Reincarnation"]));
	elseif ( stats and stats["Soulstone"] and stats["Soulstone"] > 0 ) then
		GameTooltip:AddLine("Soulstone up in: " .. CT_RA_FormatTime(stats["Soulstone"]));
	elseif ( stats and stats["Raise Ally"] and stats["Raise Ally"] > 0 ) then
		GameTooltip:AddLine("Raise Ally up in: " .. CT_RA_FormatTime(stats["Raise Ally"]));
	end
	GameTooltip:Show();
	CT_RA_CurrentMemberFrame = self;
end

function CT_RA_FormatTime(num)
	num = floor(num + 0.5);
	local hour, min, sec, str = 0, 0, 0, "";

	hour = floor(num/3600);
	min = floor(mod(num, 3600)/60);
	sec = mod(num, 60);

	if ( hour > 0 ) then
		str = hour .. "h";
	end

	if ( min > 0 ) then
		if ( strlen(str) > 0 ) then
			str = str .. ", ";
		end
		str = str .. min .. "m";
	end

	if ( sec > 0 or strlen(str) == 0 ) then
		if ( strlen(str) > 0 ) then
			str = str .. ", ";
		end
		str = str .. sec .. "s";
	end
	return str;

end


function CT_RA_Drag_OnEnter(self)
	CT_RAMenuHelp_SetTooltip(self);
	if (strsub(self:GetName(), 1, 14) == "CT_RAGroupDrag" and not InCombatLockdown()) then
		GameTooltip:SetText("Click to drag.\nShift: Drag all.");
	else
		GameTooltip:SetText("Click to drag.");
	end
end

function CT_RA_BuffButton_OnEnter(self)
	if ( CT_RA_LockPosition ) then
		return;
	end
	CT_RAMenuHelp_SetTooltip(self);
	local left, secure;
	local stats = CT_RA_Stats[self.owner];
	if ( stats and stats["Buffs"][self.name] and stats["Buffs"][self.name][2] ) then
		left = stats["Buffs"][self.name][2];
		if ( stats["Reporting"] and ( stats["Version"] or 0 ) >= 1.38 ) then
			secure = 1;
		end
		secure = 1;
	end
	if ( self.name and left ) then
		local str;
		if ( left >= 60 ) then
			secs = floor(mod(left, 60));
			mins = floor((left - secs) / 60);
		else
			mins = 0;
			secs = left;
		end
		if ( mins < 0 ) then
			mins = "00";
		elseif ( mins < 10 ) then
			mins = "0" .. mins;
		end
		if ( secs < 0 ) then
			secs = "00";
		elseif ( secs < 10 ) then
			secs = "0" .. secs;
		end
		if ( not secure ) then
			GameTooltip:SetText(self.name .. " (" .. mins .. ":" .. secs .. "?)");
		else
			GameTooltip:SetText(self.name .. " (" .. mins .. ":" .. secs .. ")");
		end
	elseif ( self.name ) then
		GameTooltip:SetText(self.name);
	end
end

function CT_RA_AssistMT(id)
	if ( CT_RA_MainTanks[id] ) then
		for i = 1, GetNumRaidMembers(), 1 do
			local uId = "raid" .. i;
			if ( UnitName(uId) == CT_RA_MainTanks[id] ) then
				AssistUnit(uId);
				return;
			end
		end
	end
end

function CT_RA_SendStatus()
	CT_RA_Auras = {
		["buffs"] = { },
		["debuffs"] = { }
	}; -- Reset everything so every buff & debuff is treated as new
	CT_RA_AddMessage("V " .. CT_RA_VersionNumber);
end

function CT_RA_AddToQueue(type, nick, name)
	tinsert(CT_RA_BuffsToCure, { ["type"] = type, ["nick"] = nick, ["name"] = name });
end

function CT_RA_GetDebuff()
	return tremove(CT_RA_BuffsToCure);
end

local cureTable;
function CT_RA_GetCure(school)
	local _, classEN = UnitClass("player");
	if (not classEN) then
		return nil;
	end

	if (not cureTable) then
		-- Create this table one time.
		cureTable = {
			[CT_RA_CLASS_DRUID_EN] = {
				-- "Remove Corruption" will remove all curse & poison from a friend.
				-- "Nature's Cure" will remove all magic & curse & poison from a friend.
				[CT_RA_DEBUFFTYPE_CURSE] = { CT_RA_CURE_NATURES_CURE, CT_RA_CURE_REMOVE_CORRUPTION },
				[CT_RA_DEBUFFTYPE_MAGIC] = CT_RA_CURE_NATURES_CURE,
				[CT_RA_DEBUFFTYPE_POISON] = { CT_RA_CURE_NATURES_CURE, CT_RA_CURE_REMOVE_CORRUPTION },
			},
			[CT_RA_CLASS_MAGE_EN] = {
				-- "Remove Curse" will remove all curses from a friend.
				[CT_RA_DEBUFFTYPE_CURSE] = CT_RA_CURE_REMOVE_CURSE,
			},
			[CT_RA_CLASS_PALADIN_EN] = {
				-- "Cleanse" will remove all poison & disease from a friend.
				-- "Sacred Cleansing" will remove all poison & disease & magic from a friend.
				[CT_RA_DEBUFFTYPE_DISEASE] = { CT_RA_CURE_SACRED_CLEANSING, CT_RA_CURE_CLEANSE },
				[CT_RA_DEBUFFTYPE_MAGIC] = CT_RA_CURE_SACRED_CLEANSING,
				[CT_RA_DEBUFFTYPE_POISON] = { CT_RA_CURE_SACRED_CLEANSING, CT_RA_CURE_CLEANSE },
			},
			[CT_RA_CLASS_PRIEST_EN] = {
				-- "Dispel Magic" will remove 1 beneficial magic from an enemy.
				-- "Purify" will remove all magic from a friend.
				-- "Purify" will remove all disease from a friend.
				[CT_RA_DEBUFFTYPE_DISEASE] = CT_RA_CURE_PURIFY,
				[CT_RA_DEBUFFTYPE_MAGIC] = CT_RA_CURE_PURIFY,
			},
			[CT_RA_CLASS_SHAMAN_EN] = {
				-- "Purge" will remove 1 beneficial magic from an enemy.
				-- "Cleanse Spirit" will remove all curse from a friend.
				-- "Purify Spirit" will remove all curse & magic from a friend.
				[CT_RA_DEBUFFTYPE_CURSE] = { CT_RA_CURE_CLEANSE_SPIRIT, CT_RA_CURE_PURIFY_SPIRIT },
				[CT_RA_DEBUFFTYPE_MAGIC] = CT_RA_CURE_PURIFY_SPIRIT,
			},
			[CT_RA_CLASS_MONK_EN] = {
				-- "Detox" will remove all poison & disease from a friend.
				-- "Internal Medicine" will remove all poison & disease & magic from a friend.
				-- "Revival" will and remove all poison & disease & magic from all party and raid members.
				[CT_RA_DEBUFFTYPE_DISEASE] = { CT_RA_CURE_INTERNAL_MEDICINE, CT_RA_CURE_REVIVAL, CT_RA_CURE_DETOX },
				[CT_RA_DEBUFFTYPE_MAGIC]   = { CT_RA_CURE_INTERNAL_MEDICINE, CT_RA_CURE_REVIVAL },
				[CT_RA_DEBUFFTYPE_POISON]  = { CT_RA_CURE_INTERNAL_MEDICINE, CT_RA_CURE_REVIVAL, CT_RA_CURE_DETOX },
			},
		};
	end

	local playerCures = cureTable[classEN];
	if ( playerCures and playerCures[school] ) then

		local tmp = playerCures[school];
		if ( type(tmp) == "table" ) then
			-- If they know the spell and the talent...
			if ( CT_RA_ClassSpells[(tmp[1])] and CT_RA_ClassTalents[(tmp[2])]) then
				-- Return the spell name.
				return tmp[1];
			end
			return nil;
		else
			-- If they know the spell...
			if ( CT_RA_ClassSpells[tmp] ) then
				-- Return the spell name.
				return tmp;
			else
				return nil;
			end
		end
	end

	return nil;
end

--[[
function CT_RA_UpdateRaidGroupColors()
	local tempOptions = CT_RAMenu_Options["temp"];
	local defaultColors = tempOptions["DefaultColor"];
	local r, g, b, a = defaultColors.r, defaultColors.g, defaultColors.b, defaultColors.a;
	for y = 1, MAX_RAID_MEMBERS, 1 do
		local frame = CT_RA_UnitIDFrameMap["raid"..y];
		if ( y <= 10 ) then
			local mt = _G["CT_RAMTGroupUnitButton" .. y];
			mt:SetBackdropColor(r, g, b, a);
			mt.Percent:SetTextColor(r, g, b);
			mt = _G["CT_RAPTGroupUnitButton" .. y];
			mt:SetBackdropColor(r, g, b, a);
			mt.Percent:SetTextColor(r, g, b);
		end
		if ( not frame.status ) then
			frame:SetBackdropColor(r, g, b, a);
		end
		frame.Percent:SetTextColor(r, g, b);
		local name = UnitName("raid"..y);
		if ( CT_RA_Stats[name] ) then
			CT_RA_UpdateUnitBuffs(CT_RA_Stats[name]["Buffs"], frame, name);
		end
	end
end
--]]

function CT_RA_UpdateRaidGroupColors()
	local tempOptions = CT_RAMenu_Options["temp"];
	local member;
	for y = 1, MAX_RAID_MEMBERS, 1 do
		if ( y <= 10 ) then
			member = CT_RAMTGroup:GetAttribute("child".. y);
			if ( member ) then
				member:SetBackdropColor(tempOptions["DefaultColor"].r, tempOptions["DefaultColor"].g, tempOptions["DefaultColor"].b, tempOptions["DefaultColor"].a);
				member.Percent:SetTextColor(tempOptions["PercentColor"].r, tempOptions["PercentColor"].g, tempOptions["PercentColor"].b);
			end
		end
		member = CT_RA_UnitIDFrameMap["raid"..y];
		if ( member ) then
			if ( not member.status ) then
				member:SetBackdropColor(tempOptions["DefaultColor"].r, tempOptions["DefaultColor"].g, tempOptions["DefaultColor"].b, tempOptions["DefaultColor"].a);
			end
			member.Percent:SetTextColor(tempOptions["PercentColor"].r, tempOptions["PercentColor"].g, tempOptions["PercentColor"].b);
			if ( CT_RA_Stats[UnitName("raid"..y)] ) then
				CT_RA_UpdateUnitBuffs(CT_RA_Stats[UnitName("raid"..y)]["Buffs"], member, UnitName("raid"..y));
			end
		end
	end
end

function CT_RA_UpdateRaidMovability()
	if (InCombatLockdown()) then
		return;
	end

	local tempOptions = CT_RAMenu_Options["temp"];
	for i = 1, CT_RA_MaxGroups, 1 do
		if ( tempOptions["LockGroups"] or not tempOptions["ShowGroups"] or not tempOptions["ShowGroups"][i] ) then
			_G["CT_RAGroupDrag" .. i]:Hide();
		else
			if ( _G["CT_RAGroup" .. i].hasMembers ) then
				_G["CT_RAGroupDrag" .. i]:Show();
			end
		end
	end
	if ( tempOptions["LockGroups"] or not tempOptions["ShowMTs"] or tempOptions["HideMTs"] ) then
		_G["CT_RAMTGroupDrag"]:Hide();
	else
		for i = 1, 10, 1 do
			if ( CT_RA_MainTanks[i] ) then
				CT_RAMTGroupDrag:Show();
				break;
			else
				CT_RAMTGroupDrag:Hide();
			end
		end
	end

	if ( tempOptions["LockGroups"]  ) then
		_G["CT_RAPTGroupDrag"]:Hide();
	else
		for i = 1, 10, 1 do
			if ( CT_RA_PTargets[i] ) then
				CT_RAPTGroupDrag:Show();
				break;
			else
				CT_RAPTGroupDrag:Hide();
			end
		end
	end
end

function CT_RA_AddToBuffQueue(name, nick)
	tinsert(CT_RA_BuffsToRecast, { ["name"] = name, ["nick"] = nick });
end

function CT_RA_GetBuff()
	return tremove(CT_RA_BuffsToRecast);
end

function CT_RA_Print(msg, r, g, b)
	DEFAULT_CHAT_FRAME:AddMessage(msg, r, g, b);
end

function CT_RA_SubSortByName()
	local tempOptions = CT_RAMenu_Options["temp"];
	-- Sort the name of the players in the raid.
	-- Returns an array containing raid roster numbers in player name sequence, followed by unfilled player slots.
	-- Thanks to Dargen of Eternal Keggers for this function
	local temp;
	local subsort = {};
	local count;
	local name;
	count = GetNumRaidMembers();
	if ( not tempOptions["SubSortByName"] ) then
		for i = 1, MAX_RAID_MEMBERS, 1 do
			subsort[i] = {};
			subsort[i][1] = i;
		end
		return subsort;
	end
	local playerName = UnitName("player");
	for i = 1, MAX_RAID_MEMBERS, 1 do
		subsort[i] = {};
		subsort[i][1] = i;
		if ( i <= count ) then
			name = UnitName("raid" .. i);
			if ( not name ) then name = playerName; end
			if ((name == nil) or (name == UNKNOWNOBJECT) or (name == UKNOWNBEING)) then name = ""; end
			subsort[i][2] = name;
		else
			subsort[i][2] = "";
		end
	end
	local swap;
	for j = 1, count - 1, 1 do
		swap = false;
		for i = 1, count - j, 1 do
			if ( subsort[i][2] > subsort[i+1][2] ) then
				-- Swap
				temp = subsort[i];
				subsort[i] = subsort[i+1];
				subsort[i+1] = temp;
				swap = true;
			end
		end
		if ( not swap ) then
			break;
		end
	end
	return subsort;
end

function CT_RA_SortByClass()
	local tempOptions = CT_RAMenu_Options["temp"];
	CT_RA_SetSortType("class");
	CT_RA_ButtonIndexes = { };
	CT_RA_CurrPositions = { };
	local groupnum = 1;
	local membernum = 1;
	for i = 1, MAX_RAID_MEMBERS, 1 do
		if ( i <= CT_RA_MaxGroups ) then
			local group = _G["CT_RAGroup"..i];
			group.num = 0;
			local label = _G["CT_RAOptionsGroup" .. i .. "Label"];
			if ( label ) then
				label:SetText("Group " .. i);
			end
		end
	end
	local subsort = CT_RA_SubSortByName();
	local i;
	for j = 1, GetNumRaidMembers(), 1 do
		i = subsort[j][1];
		local name, rank, subgroup, level, class, fileName, zone, online, isDead = GetRaidRosterInfo(i);
		if ( class and CT_RA_ClassPositions[class] ) then
			local posClass = CT_RA_ClassPositions[class];
			local group = _G["CT_RAGroup" .. posClass];
			if ( name ) then
				CT_RA_CurrPositions[name] = { CT_RA_ClassPositions[class], i };
			end
			_G[group:GetName() .. "GroupName"]:SetText(class);
		end
	end
end

function CT_RA_SortByGroup()
	local tempOptions = CT_RAMenu_Options["temp"];
	CT_RA_SetSortType("group");
	CT_RA_ButtonIndexes = { };
	CT_RA_CurrPositions = { };
	local groupnum = 1;
	local membernum = 1;
	for i = 1, MAX_RAID_MEMBERS, 1 do
		if ( i <= CT_RA_MaxGroups ) then
			local group = _G["CT_RAGroup"..i];
			group.num = 0;
			local label = _G["CT_RAOptionsGroup" .. i .. "Label"];
			if ( label ) then
				label:SetText("Group " .. i);
			end
		end
	end
	local subsort = CT_RA_SubSortByName();
	local i;
	for j = 1, GetNumRaidMembers(), 1 do
		i = subsort[j][1];
		local name, rank, subgroup, level, class, fileName, zone, online, isDead = GetRaidRosterInfo(i);
		local group = _G["CT_RAGroup" .. subgroup];
		if ( name ) then
			CT_RA_CurrPositions[name] = { subgroup, i };
		end
		_G[group:GetName() .. "GroupName"]:SetText("Group " .. subgroup);
	end
end

function CT_RA_LinkDrag(frame, drag, point, relative, x, y)
	if (InCombatLockdown() and frame:IsProtected()) then
		return;
	end
	frame:ClearAllPoints();
	frame:SetPoint(point, drag:GetName(), relative, x, y);
end

CT_RA_ConvertedRaid = 1;
CT_RA_HasInvited = { };

local CT_RA_GameTooltip_ClearMoney;

local function CT_RA_MoneyToggle()
	if( CT_RA_GameTooltip_ClearMoney ) then
		GameTooltip_ClearMoney = CT_RA_GameTooltip_ClearMoney;
		CT_RA_GameTooltip_ClearMoney = nil;
	else
		CT_RA_GameTooltip_ClearMoney = GameTooltip_ClearMoney;
		GameTooltip_ClearMoney = CT_RA_GameTooltipFunc_ClearMoney;
	end
end

function CT_RA_GameTooltipFunc_ClearMoney()

end

function CT_RA_GetBuffIndex(buffname)
	local i = 1;
	local name = UnitBuff("player", i)
	while ( name ) do
		if ( buffname == name ) then
			return i;
		end
		i = i + 1;
		name = UnitAura("player", i)
	end
	return nil;
end

function CT_RA_GetBuffTimeLeft(index)
	local _, duration, expirationTime, timeLeft;
	_, _, _, _, duration, expirationTime = UnitBuff("player", index);
	if (not expirationTime) then
		expirationTime = GetTime();
		duration = expirationTime;
	end
	timeLeft = expirationTime - GetTime();
	if (timeLeft < 0) then
		timeLeft = 0;
	end
	return timeLeft;
end

function CT_RA_GetBuffTexture(index)
	local _, icon = UnitBuff("player", index);
	return icon;
end

function CT_RA_UpdateFrame_OnUpdate(self, elapsed)
	if ( self.showDialog ) then
		self.showDialog = self.showDialog - elapsed;
		if ( self.showDialog <= 0 ) then
			if ( CT_RAChanges_DisplayDialog ) then
				CT_RAChanges_DisplayDialog();
			end
			self.showDialog = nil;
		end
	end

	if ( self.lastInvite ) then
		self.lastInvite = self.lastInvite - elapsed;
		if ( self.lastInvite <= 0 ) then
			self.lastInvite = nil;
			self.inviteName = nil;
		end
	end
	if ( self.invite ) then
		self.invite = self.invite - elapsed;
		if ( self.invite <= 0 ) then
			if ( not CT_RA_ConvertedRaid ) then
				GuildRoster();
				CT_RA_ConvertedRaid = 1;
				ConvertToRaid();
				self.invite = 3;
			else
				CT_RA_InviteGuild(CT_RA_MinLevel, CT_RA_MaxLevel);
				self.invite = nil;
			end
		end
	end
	if ( self.startinviting ) then
		self.startinviting = self.startinviting - elapsed;
		if ( self.startinviting <= 0 ) then
			self.startinviting = nil;
			CT_RA_HasInvited = { };
			if ( GetNumRaidMembers() == 0 ) then
				CT_RA_ConvertedRaid = nil;
			else
				CT_RA_ConvertedRaid = 1;
			end
			local inZone = "";
			if ( CT_RA_ZoneInvite ) then
				inZone = " from " .. GetRealZoneText();
			end
			local numInvites = CT_RA_InviteGuild(CT_RA_MinLevel, CT_RA_MaxLevel);
			if ( CT_RA_MinLevel == CT_RA_MaxLevel ) then
				CT_RA_Print("<CTRaid> " .. numInvites .. " Guild Members of level |c00FFFFFF" .. CT_RA_MinLevel .. "|r have been invited" .. inZone .. ".", 1, 0.5, 0);
			else
				CT_RA_Print("<CTRaid> " .. numInvites .. " Guild Members of levels |c00FFFFFF" .. CT_RA_MinLevel .. "|r to |c00FFFFFF" .. CT_RA_MaxLevel .. "|r have been invited" .. inZone .. ".", 1, 0.5, 0);
			end
		end
	end
	if ( self.closeroster ) then
		self.closeroster = self.closeroster - elapsed;
		if ( self.closeroster <= 0 ) then
			HideUIPanel(FriendsFrame);
			self.closeroster = nil;
		end
	end

	-- Only run the ones below if we're in a raid.
	if ( CT_RA_NumRaidMembers == 0 ) then
		return;
	end

	self.mouseOverUpdate = self.mouseOverUpdate - elapsed;
	if ( self.mouseOverUpdate <= 0 ) then
		self.mouseOverUpdate = 0.1;
		if ( CT_RA_CurrentMemberFrame ) then
			local parent = CT_RA_CurrentMemberFrame.frameParent;
			if ( SpellIsTargeting() and ( strsub(parent.name, 1, 12) == "CT_RAMTGroup" or SpellCanTargetUnit("raid" .. parent.id) ) ) then
				SetCursor("CAST_CURSOR");
			elseif ( SpellIsTargeting() ) then
				SetCursor("CAST_ERROR_CURSOR");
			end
		end
	end

	if ( self.hasAggroAlert ) then
		self.hasAggroAlert = self.hasAggroAlert - elapsed;
		if ( self.hasAggroAlert <= 0 ) then
			self.hasAggroAlert = nil;
		end
	end
	self.updateAFK = self.updateAFK + elapsed;
	if ( self.updateAFK >= 1 ) then
		self.updateAFK = self.updateAFK - 1;
		for k, v in pairs(CT_RA_Stats) do
			if ( v["AFK"] ) then
				v["AFK"][2] = v["AFK"][2] + 1;
			end
			if ( v["DND"] ) then
				v["DND"][2] = v["DND"][2] + 1;
			end
			if ( v["Dead"] ) then
				v["Dead"] = v["Dead"] + 1;
			end
			if ( v["Offline"] ) then
				v["Offline"] = v["Offline"] + 1;
			end
			if ( v["FD"] ) then
				v["FD"] = v["FD"] + 1;
			end
			if ( v["Rebirth"] ) then
				v["Rebirth"] = v["Rebirth"] - 1;
			end
			if ( v["Reincarnation"] ) then
				v["Reincarnation"] = v["Reincarnation"] - 1;
			end
			if ( v["Soulstone"] ) then
				v["Soulstone"] = v["Soulstone"] - 1;
			end
			if ( v["Raise Ally"] ) then
				v["Raise Ally"] = v["Raise Ally"] - 1;
			end
		end
	end

	self.update = self.update + elapsed;
	if ( self.update >= 1 ) then
		for k, v in pairs(CT_RA_BuffTimeLeft) do
			local buffIndex, buffTimeLeft, buffName;
			buffIndex = CT_RA_GetBuffIndex(k);
			if ( buffIndex ) then
				buffTimeLeft = CT_RA_GetBuffTimeLeft(buffIndex);
				if ( buffTimeLeft ) then
					if ( abs(CT_RA_BuffTimeLeft[k]-buffTimeLeft) >= 2 ) then
						local index, num;
						for key, val in pairs(CT_RAMenu_Options["temp"]["BuffTable"]) do
							local spellData = CT_RA_BuffSpellData[ (val["index"]) ];
							if (not spellData) then
								spellData = next(CT_RA_BuffSpellData);
							end
--							if ( type(spellData["name"]) == "table" ) then
--								local t = spellData["name"]; -- t == Table of 'equivalent' buff names
--								for n = 1, #t do
--									if ( k == t[n] ) then
--										buffName = k;
--										index = val["index"];
--										num = n;
--										break;
--									end
--								end
							if ( spellData["name"] == k ) then
								buffName = k;
								index, num = val["index"], 0;
								break;
							end
						end
						if ( not index and not num ) then
							if ( k == CT_RA_BUFF_FEIGN_DEATH ) then
								buffName = CT_RA_BUFF_FEIGN_DEATH;
								index, num = -1, 0;
							end
						end
						if ( index and num ) then
							local playerName = UnitName("player");
							local stats = CT_RA_Stats[playerName];
							if ( not stats ) then
								CT_RA_Stats[playerName] = {
									["Buffs"] = { },
									["Debuffs"] = { },
									["Position"] = { }
								};
								stats = CT_RA_Stats[playerName];
							end
							stats["Buffs"][buffName] = { string.find(CT_RA_GetBuffTexture(buffIndex), "([%w_&]+)$"), floor(buffTimeLeft+0.5) };
							CT_RA_AddMessage("RN " .. floor(buffTimeLeft+0.5) .. " " .. index .. " " .. num);
						end
					end
					CT_RA_BuffTimeLeft[k] = buffTimeLeft;
				end
			end
		end
		for k, v in pairs(CT_RA_Stats) do
			if ( v["Buffs"] ) then
				for key, val in pairs(v["Buffs"]) do
					if ( key ~= "n" and type(val) == "table" and val[2] ) then
						val[2] = val[2] - 1;
					end
				end
			end
		end
		self.update = self.update - 1;
	end
	if ( self.time ) then
		self.time = self.time - elapsed;
		if ( self.time <= 0 ) then
			self.time = nil;
			CT_RA_AddMessage("SR");
			if ( CT_RA_VersionNumber ) then
				CT_RA_AddMessage("V " .. CT_RA_VersionNumber);
			end
		end
		if ( self.SS ) then
			self.SS = nil;
		end
	end

	if ( self.SS ) then
		self.SS = self.SS - elapsed;
		if ( self.SS <= 0 ) then
			self.SS = nil;
			CT_RA_AddMessage("SR");
			if ( CT_RA_VersionNumber ) then
				CT_RA_AddMessage("V " .. CT_RA_VersionNumber);
			end
		end
	end
	if ( self.scheduleUpdate ) then
		self.scheduleUpdate = self.scheduleUpdate - elapsed;
		if ( self.scheduleUpdate <= 0 ) then
			if ( CT_RA_InCombat ) then
				self.scheduleUpdate = 1;
			else
				self.scheduleUpdate = nil;
				for i = 1, GetNumRaidMembers(), 1 do
					if ( UnitIsUnit("raid" .. i, "player") ) then
						local useless, useless, subgroup = GetRaidRosterInfo(i);
						self.updateDelay = subgroup / 2;
						return;
					end
				end
			end
		end
	end
	if ( self.scheduleMTUpdate ) then
		self.scheduleMTUpdate = self.scheduleMTUpdate - elapsed;
		if ( self.scheduleMTUpdate <= 0 ) then
			self.scheduleMTUpdate = nil;
			if ( CT_RA_IsSendingWithVersion(1.08) ) then
				for k, v in pairs(CT_RA_MainTanks) do
					CT_RA_AddMessage("SET " .. k .. " " .. v);
				end
			end
		end
	end
	if ( self.updateDelay ) then
		self.updateDelay = self.updateDelay - elapsed;
		if ( self.updateDelay <= 0 ) then
			self.updateDelay = nil;
			CT_RA_SendStatus();
			CT_RA_UpdateRaidGroup(1);
		end
	end
	if ( self.voteTimer ) then
		self.voteTimer = self.voteTimer - elapsed;
		if ( self.voteTimer <= 0 ) then
			if ( CT_RA_VotePerson ) then
				local numCount = 0;
				for i = 1, GetNumRaidMembers(), 1 do
					if ( UnitIsConnected("raid" .. i) ) then
						numCount = numCount + 1;
					end
				end
				local noVotes = numCount-(CT_RA_VotePerson[2]+CT_RA_VotePerson[3]+1);
				local yesPercent, noPercent, noVotePercent = 0, 0, 0;
				if ( CT_RA_VotePerson[2] > 0 ) then
					yesPercent = floor(CT_RA_VotePerson[2]/(CT_RA_VotePerson[2]+CT_RA_VotePerson[3]+noVotes)*100+0.5);
				end
				if ( CT_RA_VotePerson[3] > 0 ) then
					noPercent = floor(CT_RA_VotePerson[3]/(CT_RA_VotePerson[2]+CT_RA_VotePerson[3]+noVotes)*100+0.5);
				end
				if ( yesPercent+noPercent < 100 ) then
					noVotePercent = 100-(yesPercent+noPercent);
				end
				CT_RA_Print("<CTRaid> Vote results for \"|c00FFFFFF" .. CT_RA_VotePerson[4] .. "|r\": |c00FFFFFF" .. CT_RA_VotePerson[2] .. "|r (|c00FFFFFF" .. yesPercent .. "%|r) Yes / |c00FFFFFF" .. CT_RA_VotePerson[3] .. "|r (|c00FFFFFF" .. noPercent .. "%|r) No / |c00FFFFFF" .. noVotes .. "|r (|c00FFFFFF" .. noVotePercent .. "%|r) did not vote.", 1, 0.5, 0);
				SendChatMessage("<CTRaid> Vote results for \"" .. CT_RA_VotePerson[4] .. "\": " .. CT_RA_VotePerson[2] .. " (" .. yesPercent .. "%) Yes / " .. CT_RA_VotePerson[3] .. " (" .. noPercent .. "%) No / " .. noVotes .. " (" .. noVotePercent .. "%) did not vote.", "RAID");
				CT_RA_VotePerson = nil;
			end
			self.voteTimer = nil;
		end
	end
	if ( self.readyTimer ) then
		self.readyTimer = self.readyTimer - elapsed;
		if ( self.readyTimer <= 0 ) then
			CT_RA_CheckReady_Person = nil;
			self.readyTimer = nil;
			local numNotReady, numAfk = 0, 0
			local notReadyString, afkString = "", "";
			for k, v in pairs(CT_RA_Stats) do
				if ( v["notready"] and v["notready"] == 2 ) then
					numNotReady = numNotReady + 1;
					if ( strlen(notReadyString) > 0 ) then
						notReadyString = notReadyString .. ", ";
					end
					notReadyString = notReadyString .. "|c00FFFFFF" .. k .. "|r";
				elseif ( v["notready"] and v["notready"] == 1 ) then
					numAfk = numAfk + 1;
					if ( strlen(afkString) > 0 ) then
						afkString = afkString .. ", ";
					end
					afkString = afkString .. "|c00FFFFFF" .. k .. "|r";
				end
				CT_RA_Stats[k]["notready"] = nil;
			end
			if ( numNotReady > 0 ) then
				if ( numNotReady == 1 ) then
					CT_RA_Print("<CTRaid> " .. notReadyString .. " is not ready.", 1, 1, 0);
				elseif ( numNotReady >= 8 ) then
					CT_RA_Print("<CTRaid> |c00FFFFFF" .. numNotReady .. "|r raid members are not ready.", 1, 1, 0);
				else
					CT_RA_Print("<CTRaid> |c00FFFFFF" .. numNotReady .. "|r raid members (" .. notReadyString .. ") are not ready.", 1, 1, 0);
				end
				CT_RA_UpdateRaidGroup(1);
			end
			if ( numAfk > 0 ) then
				if ( numAfk == 1 ) then
					CT_RA_Print("<CTRaid> " ..afkString .. " is away from keyboard.", 1, 1, 0);
				elseif ( numAfk >= 8 ) then
					CT_RA_Print("<CTRaid> |c00FFFFFF" .. numAfk.. "|r raid members are away from keyboard.", 1, 1, 0);
				else
					CT_RA_Print("<CTRaid> |c00FFFFFF" .. numAfk .. "|r raid members (" .. afkString .. ") are away from keyboard.", 1, 1, 0);
				end
				CT_RA_UpdateRaidGroup(1);
			end
		end
	end
	if ( self.rlyTimer ) then
		self.rlyTimer = self.rlyTimer - elapsed;
		if ( self.rlyTimer <= 0 ) then
			self.rlyTimer = nil;
			local numNotReady, numAfk = 0, 0
			local notReadyString, afkString = "", "";
			for k, v in pairs(CT_RA_Stats) do
				if ( v["rly"] and v["rly"] == 2 ) then
					numNotReady = numNotReady + 1;
					if ( strlen(notReadyString) > 0 ) then
						notReadyString = notReadyString .. ", ";
					end
					notReadyString = notReadyString .. "|c00FFFFFF" .. k .. "|r";
				elseif ( v["rly"] and v["rly"] == 1 ) then
					numAfk = numAfk + 1;
					if ( strlen(afkString) > 0 ) then
						afkString = afkString .. ", ";
					end
					afkString = afkString .. "|c00FFFFFF" .. k .. "|r";
				end
				CT_RA_Stats[k]["rly"] = nil;
			end
			if ( numNotReady > 0 ) then
				if ( numNotReady == 1 ) then
					CT_RA_Print("<CTRaid> " .. notReadyString .. " says |c00FFFFFFNO WAI!|r.", 1, 1, 0);
				elseif ( numNotReady >= 8 ) then
					CT_RA_Print("<CTRaid> |c00FFFFFF" .. numNotReady .. "|r raid members say |c00FFFFFFNO WAI!|r.", 1, 1, 0);
				else
					CT_RA_Print("<CTRaid> |c00FFFFFF" .. numNotReady .. "|r raid members (" .. notReadyString .. ") say |c00FFFFFFNO WAI!|r.", 1, 1, 0);
				end
				CT_RA_UpdateRaidGroup(1);
			end
			if ( numAfk > 0 ) then
				if ( numAfk == 1 ) then
					CT_RA_Print("<CTRaid> " ..afkString .. " says nothing.", 1, 1, 0);
				elseif ( numAfk >= 8 ) then
					CT_RA_Print("<CTRaid> |c00FFFFFF" .. numAfk.. "|r raid members say nothing.", 1, 1, 0);
				else
					CT_RA_Print("<CTRaid> |c00FFFFFF" .. numAfk .. "|r raid members (" .. afkString .. ") say nothing.", 1, 1, 0);
				end
				CT_RA_UpdateRaidGroup(1);
			end
		end
	end
	if ( CT_RA_Squelch > 0 ) then
		CT_RA_Squelch = CT_RA_Squelch - elapsed;
		if ( CT_RA_Squelch <= 0 ) then
			CT_RA_Squelch = 0;
			CT_RA_Print("<CTRaid> Quiet Mode has been automatically disabled (timed out).", 1, 0.5, 0);
		end
	end
	if ( self.updateMT ) then
		self.updateMT = self.updateMT - elapsed;
		if ( self.updateMT <= 0 ) then
			self.updateMT = 0.25;
			CT_RA_UpdateMTs();
			CT_RA_UpdatePTs();
		end
	end
	for k, v in pairs(CT_RA_CurrDebuffs) do
		CT_RA_CurrDebuffs[k][1] = CT_RA_CurrDebuffs[k][1] - elapsed;
		if ( CT_RA_CurrDebuffs[k][1] < 0 ) then
			local _, _, name, dType = string.find(k, "^([^@]+)@(.+)$");
			local msg = "";
			if ( name == dType ) then
				dType = "";
			else
				dType = " (|c00FFFFFF" .. dType .. "|r)";
			end
			if ( CT_RA_CurrDebuffs[k][2] == 1 ) then
				CT_RA_Print("<CTRaid> |c00FFFFFF" .. CT_RA_CurrDebuffs[k][4] .. "|r has been debuffed by '|c00FFFFFF" .. name .. "|r'" .. dType .. msg .. ".", 1, 0.5, 0);
			else
				CT_RA_Print("<CTRaid> |c00FFFFFF" .. CT_RA_CurrDebuffs[k][2] .. "|r players have been debuffed by '|c00FFFFFF" .. name .. "|r'" .. dType .. msg .. ".", 1, 0.5, 0);
			end
			CT_RA_CurrDebuffs[k] = nil;
		end
	end
	if ( self.rangeTimer ) then
		self.rangeTimer = self.rangeTimer - elapsed;
		if ( self.rangeTimer <= 0 ) then
			self.rangeTimer = self.rangeTimerMax;
			CT_RA_UpdateRange();
		end
	end
end

function CT_RA_UpdateFrame_OnEvent(self, event, arg1, ...)
	if ( event == "GROUP_ROSTER_UPDATE" ) then  -- "PARTY_MEMBERS_CHANGED"
		if ( not CT_RA_ConvertedRaid ) then
			self.invite = 3;
		end
	elseif ( event == "CHAT_MSG_SYSTEM" ) then
		local _, _, name = string.find(arg1, "^([^%s]+) is already in a group%.$");
		if ( name and self.inviteName and self.inviteName == name ) then
			self.inviteName = nil;
			self.lastInvite = nil;
			SendChatMessage("<CTRaid> You are already grouped.", "WHISPER", nil, name);
		end
	end
end

function CT_RA_InviteGuild(min, max)
	local offline = GetGuildRosterShowOffline();
	local selection = GetGuildRosterSelection();
	SetGuildRosterShowOffline(0);
	SetGuildRosterSelection(0);
	GetGuildRosterInfo(0);
	local inviteBeforeRaid = 4-GetNumPartyMembers();
	local numInvites = 0;
	local numGuildMembers = GetNumGuildMembers();
	CT_RA_UpdateFrame.closeroster = 2;
	local RealZoneText = GetRealZoneText();
	if (RealZoneText == nil) then RealZoneText = "?"; end
	local playerName = UnitName("player");
	for i = 1, numGuildMembers, 1 do
		local name, rank, rankIndex, level, class, zone, note, officernote, online, status = GetGuildRosterInfo(i);
		if ( level >= min and level <= max and name ~= playerName and not CT_RA_HasInvited[i] and online ) then
			if ( zone == nil ) then zone = "???"; end
			if ( not CT_RA_ZoneInvite or ( CT_RA_ZoneInvite and zone == RealZoneText ) ) then
				CT_RA_HasInvited[i] = 1;
				InviteUnit(name);
				numInvites = numInvites + 1;
				if ( numInvites == inviteBeforeRaid and not CT_RA_ConvertedRaid ) then
					CT_RA_UpdateFrame.invite = 1.5;
					break;
				end
			end
		end
	end
	SetGuildRosterShowOffline(offline);
	SetGuildRosterSelection(selection);
	return numInvites;
end

function CT_RA_ProcessMessages(self, elapsed)
	if ( self.flush ) then
		self.flush = self.flush - elapsed;
		if ( self.flush <= 0 ) then
			self.flush = 1;
			self.numMessagesSent = 0;
		end
	end
	if ( self.elapsed ) then
		self.elapsed = self.elapsed - elapsed;
		if ( self.elapsed <= 0 ) then
			if ( #CT_RA_Comm_MessageQueue > 0 and self.numMessagesSent < 4 ) then
				CT_RA_SendMessageQueue(self);
			end
			self.elapsed = 0.1;
		end
	end
end
function CT_RA_SendMessageQueue(self)
	local retstr = "";
	local numSent = 0;

	for key, val in pairs(CT_RA_Comm_MessageQueue) do
		if ( strlen(retstr)+strlen(val)+1 > 255 ) then
			CT_RA_SendMessage(retstr);
			self.numMessagesSent = self.numMessagesSent + 1;
			tremove(CT_RA_Comm_MessageQueue, key);
			if ( self.numMessagesSent == 4 ) then
				return;
			end
			retstr = "";
		end
		if ( retstr ~= "" ) then
			retstr = retstr .. "#";
		end
		retstr = retstr .. val;
	end
	if ( retstr ~= "" ) then
		CT_RA_SendMessage(retstr);
		self.numMessagesSent = self.numMessagesSent + 1;
	end
	CT_RA_Comm_MessageQueue = { };
end

function CT_RA_Split(msg, char)
	local arr = { };
	while (string.find(msg, char) ) do
		local iStart, iEnd = string.find(msg, char);
		tinsert(arr, strsub(msg, 1, iStart-1));
		msg = strsub(msg, iEnd+1, strlen(msg));
	end
	if ( strlen(msg) > 0 ) then
		tinsert(arr, msg);
	end
	return arr;
end

function CT_RA_IsSendingWithVersion(version)
	local playerName = UnitName("player");
	local names = { };
	if ( not CT_RA_Level or CT_RA_Level < 1 ) then
		return nil;
	end
	for i = 1, GetNumRaidMembers(), 1 do
		local name, rank, subgroup, level, class, fileName = GetRaidRosterInfo(i);
		local stats = CT_RA_Stats[name];
		if ( rank >= 1 and name ~= playerName and stats and stats["Version"] and stats["Version"] >= version and name < playerName ) then
			return nil;
		end
	end
	return 1;
end

function CT_RA_ScanPartyAuras(unit)
	local name = UnitName(unit);
	if ( not name ) then
		return;
	end
	local id = string.gsub(unit, "^raid(%d+)$", "%1");
	local frame = CT_RA_UnitIDFrameMap["raid"..id];
	local stats = CT_RA_Stats[name];
	if ( not stats ) then
		CT_RA_Stats[name] = {
			["Buffs"] = { },
			["Debuffs"] = { },
			["Position"] = { }
		};
		stats = CT_RA_Stats[name];
		CT_RA_ScanUnitBuffs(unit, name, id);
		CT_RA_ScanUnitDebuffs(unit, name, id);
		CT_RA_UpdateUnitBuffs(stats["Buffs"], frame, name);
	else
		CT_RA_ScanUnitDebuffs(unit, name, id);
		CT_RA_ScanUnitBuffs(unit, name, id);
		local isFD = CT_RA_CheckFD(name, "raid" .. id);
		if ( isFD > 0 ) then
			CT_RA_UpdateUnitDead(frame);
		end
		CT_RA_UpdateUnitBuffs(stats["Buffs"], frame, name);
	end
end

function CT_RA_CheckFD(name, unit)
	local class = UnitClass(unit);
	if ( class ~= CT_RA_CLASS_HUNTER and class ~= CT_RA_CLASS_PRIEST ) then
		return 0;
	end
	local hasFD = 0;
	local num = 0;
	local buff, texture = UnitBuff(unit, 1);
	while ( buff ) do
		if ( texture == "Interface\\Icons\\Ability_Rogue_FeignDeath" ) then
			hasFD = 1;
			break;
		elseif ( texture == "Interface\\Icons\\Spell_Holy_GreaterHeal" ) then
			hasFD = 2;
			break;
		end
		num = num + 1;
		buff, texture = UnitBuff(unit, num+1);
	end
	return hasFD;
end

function CT_RA_ScanUnitBuffs(unit, name, id)
	local tempOptions = CT_RAMenu_Options["temp"];
	local oldAuras = { };
	local stats = CT_RA_Stats[name]["Buffs"];
	for k, v in pairs(stats) do
		if ( k ~= "n" ) then
			oldAuras[k] = 1;
		end
	end
	stats.n = 0;
	local num = 0;
	local buffName, buff, _, _, dur = UnitBuff(unit, 1);
	local duplicateTextures = {
		["Interface\\Icons\\Spell_Nature_Regeneration"] = true,
		["Interface\\Icons\\Spell_Nature_LightningShield"] = true
	};
	while ( buff ) do
		num = num + 1;
		local buffT = CT_RA_BuffSpellNumbers[buffName];
		if ( buffT and not stats[buffName] ) then
			stats[buffName] = { buff, dur or 0 };
			if ( UnitIsUnit(unit, "player") ) then
				CT_RA_BuffTimeLeft[buffName] = dur or 0;
			end
		end
		stats.n = stats.n + 1;
		oldAuras[buffName] = nil;
		buffName, buff, _, _, dur = UnitBuff(unit, num+1);
	end
	for k, v in pairs(oldAuras) do
		stats[k] = nil;
		local buffTbl;
		for key, val in pairs(tempOptions["BuffTable"]) do
			local spellData = CT_RA_BuffSpellData[ (val["index"]) ];
			if (not spellData) then
				spellData = next(CT_RA_BuffSpellData);
			end
--			if ( type(spellData["name"]) == "table" ) then
--				for kk, vv in pairs(spellData["name"]) do
--					if ( k == vv ) then
--						buffTbl = val;
--						break;
--					end
--				end
--			else
				if ( k == spellData["name"] ) then
					buffTbl = val;
					break;
				end
--			end
		end
		if ( buffTbl ) then
			local uId = "raid" .. id;
			if ( not UnitIsDead(uId) and UnitIsVisible(uId) and not tempOptions["NotifyDebuffs"]["hidebuffs"] and k ~= CT_RA_BUFF_POWER_WORD_SHIELD ) then
				if ( buffTbl["show"] ~= -1 ) then
					local currPos = CT_RA_CurrPositions[name];
					if ( currPos ) then
						if ( tempOptions["NotifyDebuffs"][currPos[1]] and tempOptions["NotifyDebuffsClass"][CT_RA_ClassPositions[UnitClass("raid" .. currPos[2])]] ) then
							if ( CT_RA_ClassSpells and CT_RA_ClassSpells[k] ) then
								CT_RA_Print("<CTRaid> '|c00FFFFFF" .. name .. "|r's '|c00FFFFFF" .. k .. "|r' has faded.", 1, 0.5, 0);
							end
						end
					end
				end
			end
		end
	end
end

function CT_RA_ScanUnitDebuffs(unit, name, id)
	local tempOptions = CT_RAMenu_Options["temp"];
	local oldAuras = { };
	local stats = CT_RA_Stats[name]["Debuffs"];
	for k, v in pairs(stats) do
		if ( k ~= "n" ) then
			oldAuras[k] = 1;
		end
	end
	stats.n = 0;
	local num = 0;
	local debuffName, debuff, applications, dType = UnitDebuff(unit, 1);
	while ( debuff ) do
		stats.n = stats.n + 1;
		num = num + 1;
		oldAuras[debuffName] = nil;
		if ( not stats[debuffName] ) then
			if ( debuffName == CT_RA_DEBUFF_WEAKENED_SOUL ) then
				dType = CT_RA_DEBUFF_WEAKENED_SOUL;
			elseif ( debuffName == CT_RA_DEBUFF_RECENTLY_BANDAGED ) then
				dType = CT_RA_DEBUFF_RECENTLY_BANDAGED;
			end
			local debuffType;
			for k, v in pairs(tempOptions["DebuffColors"]) do
				if ( dType == v["type"] ) then
					debuffType = v;
					break;
				end
			end
			if ( debuffType ) then
				local uId = "raid" .. id;
				stats[debuffName] = { dType, 0, gsub(debuff, "^Interface\\Icons\\(.+)$", "%1") };
				if ( CastParty_AddDebuff ) then
					CastParty_AddDebuff(uId, dType);
				end
				if ( tempOptions["NotifyDebuffs"]["main"] and debuffName ~= CT_RA_DEBUFF_RECENTLY_BANDAGED and debuffName ~= CT_RA_DEBUFF_MIND_VISION and debuffType["id"] ~= -1 ) then
					local currPos = CT_RA_CurrPositions[name];
					if ( currPos ) then
						if ( tempOptions["NotifyDebuffs"][currPos[1]] and tempOptions["NotifyDebuffsClass"][CT_RA_ClassPositions[UnitClass(uId)]] ) then
							CT_RA_AddToQueue(dType, uId);
							CT_RA_AddDebuffMessage(debuffName, dType, name);
						end
					end
				end
			end
		end
		debuffName, debuff, applications, dType = UnitDebuff(unit, num+1);
	end
	for k, v in pairs(oldAuras) do
		stats[k] = nil;
	end
end

function CT_RA_ShowHideDebuffs()
	local tempOptions = CT_RAMenu_Options["temp"];
	if (tempOptions["ShowDebuffs"]) then
		tempOptions["ShowDebuffs"] = nil;
	else
		tempOptions["ShowDebuffs"] = 1;
	end
	if ( tempOptions["ShowDebuffs"] ) then
		L_UIDropDownMenu_SetSelectedID(CT_RAMenuFrameBuffsBuffsDropDown, 2);
		CT_RAMenuFrameBuffsBuffsDropDownText:SetText("Show debuffs");
	elseif ( tempOptions["ShowBuffsDebuffed"] ) then
		L_UIDropDownMenu_SetSelectedID(CT_RAMenuFrameBuffsBuffsDropDown, 3);
		CT_RAMenuFrameBuffsBuffsDropDownText:SetText("Show buffs until debuffed");
	else
		L_UIDropDownMenu_SetSelectedID(CT_RAMenuFrameBuffsBuffsDropDown, 1);
		CT_RAMenuFrameBuffsBuffsDropDownText:SetText("Show buffs");
	end
	CT_RA_UpdateRaidGroup(2);
end

-- Hook ChatFrame_MessageEventHandler()
-- Thanks to Darco for the idea & some of the code
CT_RA_OldChatFrame_MessageEventHandler = ChatFrame_MessageEventHandler;
function CT_RA_NewChatFrame_MessageEventHandler(self, event, arg1, ...)
	if ( event == "CHAT_MSG_SYSTEM" ) then
		local iStart, iEnd, sName, iID, iDays, iHours, iMins, iSecs = string.find(arg1, "(.+) %(ID=(%w+)%): (%d+)d (%d+)h (%d+)m (%d+)s");
		if ( sName ) then
			local table = date("*t");
			table["sec"] = table["sec"] + (tonumber(iDays) * 86400) + (tonumber(iHours) * 3600) + (tonumber(iMins) * 60) + iSecs;
			arg1 = arg1 .. " ("..date("%A %b %d, %I:%M%p", time(table)) .. ")";
		end
	elseif ( event == "CHAT_MSG_WHISPER_INFORM" ) then
		if ( arg1 == "<CTRaid> You are already grouped." or string.find(arg1, "<CTRaid> Quiet mode is enabled in the raid%. Please be quiet%. %d+ seconds remaining%.") ) then
			return;
		end
	end
	CT_RA_OldChatFrame_MessageEventHandler(self, event, arg1, ...);
end

ChatFrame_MessageEventHandler = CT_RA_NewChatFrame_MessageEventHandler;

-- Hook some dialog script handlers
local oldDialogs = { };
oldDialogs["RESURRECTSHOW"] = StaticPopupDialogs["RESURRECT"].OnShow;
oldDialogs["RESURRECT_NO_SICKNESSSHOW"] = StaticPopupDialogs["RESURRECT_NO_SICKNESS"].OnShow;
oldDialogs["RESURRECT_NO_TIMERSHOW"] = StaticPopupDialogs["RESURRECT_NO_TIMER"].OnShow;
oldDialogs["DEATHSHOW"] = StaticPopupDialogs["DEATH"].OnShow;

StaticPopupDialogs["RESURRECT"].OnShow = function(self) oldDialogs["RESURRECTSHOW"](self) CT_RA_AddMessage("RESSED") end;
StaticPopupDialogs["RESURRECT_NO_SICKNESS"].OnShow = function(self) oldDialogs["RESURRECT_NO_SICKNESSSHOW"](self) CT_RA_AddMessage("RESSED") end;
StaticPopupDialogs["RESURRECT_NO_TIMER"].OnShow = function(self) oldDialogs["RESURRECT_NO_TIMERSHOW"](self) CT_RA_AddMessage("RESSED") end;
StaticPopupDialogs["RESURRECT"].OnHide = function() CT_RA_AddMessage("NORESSED") end;
StaticPopupDialogs["RESURRECT_NO_SICKNESS"].OnHide = function() CT_RA_AddMessage("NORESSED") end;
StaticPopupDialogs["RESURRECT_NO_TIMER"].OnHide = function() if ( not StaticPopup_FindVisible("DEATH") ) then CT_RA_AddMessage("NORESSED") end end;
StaticPopupDialogs["DEATH"].OnShow = function(self) oldDialogs["DEATHSHOW"](self) if ( ResurrectGetOfferer() and not ResurrectHasSickness() ) then CT_RA_AddMessage("CANRES") end end;

-- Hook StaticPopup_OnShow
hooksecurefunc("StaticPopup_OnShow", function(self)
	if ( self.which and strsub(self.which, 1, 9) == "RESURRECT" ) then
		CT_RA_AddMessage("RESSED");
	end
end);

function CT_RA_ResFrame_DropDown_OnClick(self)
	local tempOptions = CT_RAMenu_Options["temp"];
	if (self.value == "ToggleLock") then
		if (tempOptions["LockMonitor"]) then
			tempOptions["LockMonitor"] = nil;
		else
			tempOptions["LockMonitor"] = 1;
		end
	elseif (self.value == "HideWindow") then
		tempOptions["ShowMonitor"] = nil;
		CT_RA_UpdateResFrame();
		CT_RAMenu_UpdateMenu();
	elseif (self.value == "CloseMenu") then
		L_CloseDropDownMenus();
	end
end

function CT_RA_ResFrame_InitButtons(self)
	local tempOptions = CT_RAMenu_Options["temp"];
	local info;

	info = {};
	info.text = "Resurrection Monitor";
	info.isTitle = 1;
	info.justifyH = "CENTER";
	info.notCheckable = 1;
	L_UIDropDownMenu_AddButton(info);

	info = { };
	if ( tempOptions["LockMonitor"] ) then
		info.text = "Unlock window";
	else
		info.text = "Lock window";
	end
	info.value = "ToggleLock";
	info.notCheckable = 1;
	info.func = CT_RA_ResFrame_DropDown_OnClick;
	L_UIDropDownMenu_AddButton(info);

	info = { };
	info.text = "Background color";
	info.hasColorSwatch = 1;
	info.hasOpacity = 1;
	if ( tempOptions["RMBG"] ) then
		info.r = ( tempOptions["RMBG"].r );
		info.g = ( tempOptions["RMBG"].g );
		info.b = ( tempOptions["RMBG"].b );
		info.opacity = ( tempOptions["RMBG"].a );
	else
		info.r = 0;
		info.g = 0;
		info.b = 0;
		info.opacity = 0.5;
	end
	info.notClickable = 1;
	info.swatchFunc = CT_RA_ResFrame_DropDown_SwatchFunc;
	info.opacityFunc = CT_RA_ResFrame_DropDown_OpacityFunc;
	info.cancelFunc = CT_RA_ResFrame_DropDown_CancelFunc;
	info.notCheckable = 1;
	L_UIDropDownMenu_AddButton(info);

	info = { };
	info.text = "Hide window";
	info.value = "HideWindow";
	info.notCheckable = 1;
	info.func = CT_RA_ResFrame_DropDown_OnClick;
	L_UIDropDownMenu_AddButton(info);

	info = {};
	info.text = "Close this menu";
	info.value = "CloseMenu";
	info.notCheckable = 1;
	info.func = CT_RA_ResFrame_DropDown_OnClick;
	L_UIDropDownMenu_AddButton(info);
end

function CT_RA_ResFrame_DropDown_SwatchFunc()
	local tempOptions = CT_RAMenu_Options["temp"];
	local r, g, b = ColorPickerFrame:GetColorRGB();
	if ( not tempOptions["RMBG"] ) then
		tempOptions["RMBG"] = { ["r"] = r, ["g"] = g, ["b"] = b, ["a"] = 0 };
	else
		tempOptions["RMBG"]["r"] = r;
		tempOptions["RMBG"]["g"] = g;
		tempOptions["RMBG"]["b"] = b;
	end
	CT_RA_ResFrame:SetBackdropColor(r, g, b, tempOptions["RMBG"]["a"]);
	CT_RA_ResFrame:SetBackdropBorderColor(1, 1, 1, tempOptions["RMBG"]["a"]);
end

function CT_RA_ResFrame_DropDown_OpacityFunc()
	local tempOptions = CT_RAMenu_Options["temp"];
	local r, g, b = 1, 1, 1;
	if ( tempOptions["RMBG"] ) then
		r, g, b = tempOptions["RMBG"].r, tempOptions["RMBG"].g, tempOptions["RMBG"].b;
	end
	local a = OpacitySliderFrame:GetValue();
	tempOptions["RMBG"]["a"] = a;
	CT_RA_ResFrame:SetBackdropColor(r, g, b, a);
	CT_RA_ResFrame:SetBackdropBorderColor(1, 1, 1, a);
end

function CT_RA_ResFrame_DropDown_CancelFunc(val)
	local tempOptions = CT_RAMenu_Options["temp"];
	tempOptions["RMBG"] = {
		["r"] = val.r,
		["g"] = val.g,
		["b"] = val.b,
		["a"] = val.opacity
	};
	CT_RA_ResFrame:SetBackdropColor(val.r, val.g, val.b, val.opacity);
	CT_RA_ResFrame:SetBackdropBorderColor(1, 1, 1, val.opacity);
end

function CT_RA_ResFrame_OnLoad(self)
	L_UIDropDownMenu_Initialize(self, CT_RA_ResFrame_InitButtons, "MENU");
end

function CT_RA_SendReady()
	CT_RA_AddMessage("READY");
end

function CT_RA_SendNotReady()
	CT_RA_AddMessage("NOTREADY");
end

function CT_RA_SendYes()
	CT_RA_AddMessage("VOTEYES");
end

function CT_RA_SendNo()
	CT_RA_AddMessage("VOTENO");
end

function CT_RA_SendRly()
	CT_RA_AddMessage("YARLY");
end

function CT_RA_SendNoRly()
	CT_RA_AddMessage("NORLY");
end

function CT_RA_ReadyFrame_OnUpdate(self, elapsed)
	if ( self.hide ) then
		self.hide = self.hide - elapsed;
		if ( self.hide <= 0 ) then
			self:Hide();
		end
	end
end

function CT_RA_ToggleGroupSort()
	local tempOptions = CT_RAMenu_Options["temp"];
	if ( tempOptions["SORTTYPE"] == "group" ) then
		CT_RA_SetSortType("class");
	else
		CT_RA_SetSortType("group");
	end

	CT_RA_UpdateRaidGroup(0);
	CT_RA_UpdateRaidFrameOptions();
	CT_RAOptions_UpdateGroups();
end

function CT_RA_SetSortType(sort_type)
	local tempOptions = CT_RAMenu_Options["temp"];
	CT_RA_LoadSortOptions_ShowHideWindows();
	if (CT_RAMenu_SaveWindowPositions) then
		CT_RAMenu_SaveWindowPositions();
	end
	if ( sort_type == "class" ) then
		tempOptions["SORTTYPE"] = "class";
		CT_RA_NumGroups = #CT_RA_ClassIndices;
		if ( CT_RAMenuFrameGeneralMiscDropDown and CT_RAMenuFrame:IsVisible() ) then
			L_UIDropDownMenu_SetSelectedID(CT_RAMenuFrameGeneralMiscDropDown, 2);
		end
		if ( CT_RAMenuFrameGeneralMiscDropDownText ) then
			CT_RAMenuFrameGeneralMiscDropDownText:SetText("Class");
		end
	else
		tempOptions["SORTTYPE"] = "group";
		CT_RA_NumGroups = NUM_RAID_GROUPS;
		if ( CT_RAMenuFrameGeneralMiscDropDown and CT_RAMenuFrame:IsVisible() ) then
			L_UIDropDownMenu_SetSelectedID(CT_RAMenuFrameGeneralMiscDropDown, 1);
		end
		if ( CT_RAMenuFrameGeneralMiscDropDownText ) then
			CT_RAMenuFrameGeneralMiscDropDownText:SetText("Group");
		end
	end
	if (CT_RAMenu_UpdateWindowPositions) then
		CT_RAMenu_UpdateWindowPositions();
	end
end

function CT_RA_DragAllWindows(self, start)
	if (InCombatLockdown()) then
		return;
	end
	local id = tonumber(self:GetName():match("(%d+)$"));
	if ( start ) then
		local group = _G["CT_RAGroupDrag" .. id];
		local x, y = group:GetLeft(), group:GetTop();

		if ( not x or not y ) then
			return;
		end
		for i = 1, CT_RA_MaxGroups, 1 do
			if ( i ~= id ) then
				local oGroup = _G["CT_RAGroupDrag" .. i];
				local oX, oY = oGroup:GetLeft(), oGroup:GetTop();
				if ( oX and oY ) then
					oGroup:ClearAllPoints();
					oGroup:SetPoint("TOPLEFT", "CT_RAGroupDrag" .. id, "TOPLEFT", oX-x, oY-y);
				end
			end
		end
	else
		for i = 1, CT_RA_MaxGroups, 1 do
			if ( i ~= id ) then
				local oGroup = _G["CT_RAGroupDrag" .. i];
				local oX, oY = oGroup:GetLeft(), oGroup:GetTop();
				if ( oX and oY ) then
					oGroup:ClearAllPoints();
					oGroup:SetPoint("TOPLEFT", "UIParent", "TOPLEFT", oX, oY-UIParent:GetTop());
				end
			end
		end
	end
end

function CT_RA_CheckGroups()
	if ( GetNumRaidMembers() == 0 ) then
		return;
	end
	local numPartyMembers = GetNumPartyMembers();
	if ( not CT_RA_PartyMembers ) then
		CT_RA_PartyMembers = { };
		if ( UnitName("party" .. numPartyMembers) ) then
			for i = 1, numPartyMembers, 1 do
				CT_RA_PartyMembers[UnitName("party"..i)] = i;
			end
		end
		return;
	end
	local joined = "";
	local left = "";
	local numleft = 0;
	local numjoin = 0;
	if ( not UnitName("party" .. numPartyMembers) and numPartyMembers > 0 ) then
		CT_RA_PartyMembers = { };
		return;
	end
	for i = 1, numPartyMembers, 1 do
		local uName = UnitName("party" .. i);
		if ( uName and not CT_RA_PartyMembers[uName] ) then
			if ( numjoin > 0 ) then
				joined = joined .. "|r, |c00FFFFFF";
			end
			joined = joined .. uName;
			numjoin = numjoin + 1;
		end
		CT_RA_PartyMembers[uName] = nil;
	end

	for k, v in pairs(CT_RA_PartyMembers) do
		if ( numleft > 0 ) then
			left = left .. "|r, |c00FFFFFF";
		end
		left = left .. k;
		numleft = numleft + 1;
	end
	local tempOptions = CT_RAMenu_Options["temp"];
	if ( tempOptions["NotifyGroupChange"] and ( numjoin > 0 or numleft > 0 ) ) then
		if ( tempOptions["NotifyGroupChangeSound"] ) then
			PlaySoundFile("Sound\\Spells\\Thorns.wav");
		end
		if ( numjoin > 1 ) then
			CT_RA_Print("<CTRaid> |c00FFFFFF" .. joined .. "|r have joined your party.", 1, 0.5, 0);
		elseif ( numjoin == 1 ) then
			CT_RA_Print("<CTRaid> |c00FFFFFF" .. joined .. "|r has joined your party.", 1, 0.5, 0);
		end
		if ( numleft > 1 ) then
			CT_RA_Print("<CTRaid> |c00FFFFFF" .. left .. "|r have left your party.", 1, 0.5, 0);
		elseif ( numleft == 1 ) then
			CT_RA_Print("<CTRaid> |c00FFFFFF" .. left .. "|r has left your party.", 1, 0.5, 0);
		end
	end
	CT_RA_PartyMembers = { };
	for i = 1, numPartyMembers, 1 do
		local uName = UnitName("party" .. i);
		if ( uName ) then
			CT_RA_PartyMembers[uName] = 1;
		end
	end
end

function CT_RA_Emergency_UpdateHealth()
	local tempOptions = CT_RAMenu_Options["temp"];
	local numRaidMembers = GetNumRaidMembers();
	if ( not tempOptions["ShowEmergency"] or ( numRaidMembers == 0 and not tempOptions["ShowEmergencyOutsideRaid"] ) ) then
		CT_RA_EmergencyFrame:Hide();
		return;
	else
		CT_RA_EmergencyFrame:Show();
	end
	for i = 1, 5, 1 do
		CT_RA_EmergencyFrame["frame"..i]:Hide();
	end
	CT_RA_EmergencyFrame.maxPercent = nil;
	local healthThreshold = tempOptions["EMThreshold"];
	if ( not healthThreshold ) then
		healthThreshold = 0.9;
	end
	CT_RA_Emergency_Units = { };
	local health;
	if ( not tempOptions["ShowEmergencyParty"] and GetNumRaidMembers() > 0 ) then
		health = CT_RA_Emergency_RaidHealth;
		health = { };
		local numMembers = GetNumRaidMembers();
		for i = 1, numMembers, 1 do
			local uId = "raid" .. i;
			local curr, max = UnitHealth(uId), UnitHealthMax(uId);
			if ( curr and max ) then
				local percent;
				if (max == 0) then
					percent = 0;
				else
					percent = curr / max;
				end
				if ( percent <= healthThreshold ) then
					tinsert(health, { curr, max, uId, i, percent });
				end
			end
		end
	else
		health = { };
		for i = 1, GetNumPartyMembers(), 1 do
			local uId = "party" .. i;
			local curr, max = UnitHealth(uId), UnitHealthMax(uId);
			if ( curr and max ) then
				local percent;
				if (max == 0) then
					percent = 0;
				else
					percent = curr / max;
				end
				if ( percent <= healthThreshold ) then
					tinsert(health, { curr, max, uId, nil, percent });
				end
			end
		end
		local curr, max = UnitHealth("player"), UnitHealthMax("player");
		local percent;
		if (max == 0) then
			percent = 0;
		else
			percent = curr / max;
		end
		if ( percent <= healthThreshold ) then
			tinsert(health, { curr, max, "player", nil, percent });
		end
	end

	table.sort(
		health,
		function(v1, v2)
			return v1[5] < v2[5];
		end
	);
	CT_RA_EmergencyFrameTitle:Show();
	CT_RA_EmergencyFrameDrag:Show();
	local nextFrame = 0;

	local _, classEN = UnitClass("player");
	local checkRangeFunc = tempOptions["ShowEmergencyRange"] and classRangeSpells[classEN];

	for k, v in pairs(health) do
		if (
			not UnitIsDead(v[3]) and
			not UnitIsGhost(v[3]) and
			UnitIsConnected(v[3]) and
			UnitIsVisible(v[3]) and
			(
				not CT_RA_Stats[UnitName(v[3])] or
				not CT_RA_Stats[UnitName(v[3])]["Dead"]
			) and
			(
				not tempOptions["EMClasses"] or
				not tempOptions["EMClasses"][UnitClass(v[3])]
			) and
			(
				not checkRangeFunc or
				IsSpellInRange(checkRangeFunc, v[3]) ~= 0
			)
		   ) then
			local name, rank, subgroup, level, class, fileName;
			local obj = CT_RA_EmergencyFrame["frame" .. (nextFrame+1)];
			if ( GetNumRaidMembers() > 0 and not tempOptions["ShowEmergencyParty"] and v[4] ) then
				name, rank, subgroup, level, class, fileName = GetRaidRosterInfo(v[4]);
				local colors = RAID_CLASS_COLORS[fileName];
				if ( colors ) then
					obj.Name:SetTextColor(colors.r, colors.g, colors.b);
				end
			else
				obj.Name:SetTextColor(1, 1, 1);
			end
			if ( not subgroup or not tempOptions["EMGroups"] or not tempOptions["EMGroups"][subgroup] ) then
				nextFrame = nextFrame + 1;
				obj:Show();
				CT_RA_EmergencyFrame.maxPercent = v[5];
				CT_RA_Emergency_Units[UnitName(v[3])] = 1;
				obj.ClickFrame.unitid = v[3];
				obj.HPBar:SetMinMaxValues(0, v[2]);
				obj.HPBar:SetValue(v[1]);
				obj.Name:SetText(UnitName(v[3]));
				obj.Deficit:SetText(v[1]-v[2]);

				if ( UnitIsUnit(v[3], "player") ) then
					obj.HPBar:SetStatusBarColor(1, 0, 0);
					obj.HPBG:SetVertexColor(1, 0, 0, tempOptions["BGOpacity"]);
				elseif ( UnitInParty(v[3]) ) then
					obj.HPBar:SetStatusBarColor(0, 1, 1);
					obj.HPBG:SetVertexColor(0, 1, 1, tempOptions["BGOpacity"]);
				else
					obj.HPBar:SetStatusBarColor(0, 1, 0);
					obj.HPBG:SetVertexColor(0, 1, 0, tempOptions["BGOpacity"]);
				end
			end
		end
		if ( nextFrame == 5 ) then
			break;
		end
	end
end

function CT_RA_Emergency_OnEnter(self)
	if ( SpellIsTargeting() ) then
		SetCursor("CAST_CURSOR");
	elseif ( not SpellCanTargetUnit(self.unitid) and SpellIsTargeting() ) then
		SetCursor("CAST_ERROR_CURSOR");
	end
end

function CT_RA_Emergency_OnUpdate(self, elapsed)
	self.update = self.update - elapsed;
	if ( self.update <= 0 ) then
		self.update = 0.1;
		if ( self.cursor ) then
			if ( SpellIsTargeting() and SpellCanTargetUnit(self.unitid) ) then
				SetCursor("CAST_CURSOR");
			elseif ( SpellIsTargeting() ) then
				SetCursor("CAST_ERROR_CURSOR");
			end
		end
	end
end

function CT_RA_Emergency_DropDown_OnLoad(self)
	L_UIDropDownMenu_Initialize(self, CT_RA_Emergency_DropDown_Initialize, "MENU");
end

function CT_RA_Emergency_DropDown_Initialize(self)
	local tempOptions = CT_RAMenu_Options["temp"];
	local info;
	if ( L_UIDROPDOWNMENU_MENU_VALUE == "Classes" ) then
		info = {};
		info.text = "Classes";
		info.isTitle = 1;
		info.justifyH = "CENTER";
		info.notCheckable = 1;
		L_UIDropDownMenu_AddButton(info, L_UIDROPDOWNMENU_MENU_LEVEL);

		for j, k in ipairs(CT_RA_ClassSorted) do
			-- local v = CT_RA_ClassPositions[k];
			info = {};
			info.text = k;
			info.value = "c" .. k;
			info.func = CT_RA_Emergency_DropDown_OnClick;
			info.checked = ( not tempOptions["EMClasses"] or not tempOptions["EMClasses"][k] );
			info.keepShownOnClick = 1;
			info.tooltipTitle = "Toggle Class";
			info.tooltipText = "Toggles displaying the selected class, allowing you to hide certain classes from the Emergency Monitor.";
			L_UIDropDownMenu_AddButton(info, L_UIDROPDOWNMENU_MENU_LEVEL);
		end
		return;
	end

	if ( L_UIDROPDOWNMENU_MENU_VALUE == "Groups" ) then
		info = {};
		info.text = "Groups";
		info.isTitle = 1;
		info.justifyH = "CENTER";
		info.notCheckable = 1;
		L_UIDropDownMenu_AddButton(info, L_UIDROPDOWNMENU_MENU_LEVEL);
		for i = 1, NUM_RAID_GROUPS, 1 do
			info = {};
			info.text = "Group " .. i;
			info.value = "g" .. i;
			info.func = CT_RA_Emergency_DropDown_OnClick;
			info.checked = ( not tempOptions["EMGroups"] or not tempOptions["EMGroups"][i] );
			info.keepShownOnClick = 1;
			info.tooltipTitle = "Toggle Group";
			info.tooltipText = "Toggles displaying the selected group, allowing you to hide certain groups from the Emergency Monitor.";
			L_UIDropDownMenu_AddButton(info, L_UIDROPDOWNMENU_MENU_LEVEL);
		end
		return;
	end
	info = {};
	info.text = "Emergency Monitor";
	info.isTitle = 1;
	info.justifyH = "CENTER";
	info.notCheckable = 1;
	L_UIDropDownMenu_AddButton(info);

	info = {};
	info.text = "Classes";
	info.hasArrow = 1;
	info.notCheckable = 1;
	L_UIDropDownMenu_AddButton(info);

	info = {};
	info.text = "Groups";
	info.value = "Groups";
	info.hasArrow = 1;
	info.notCheckable = 1;
	L_UIDropDownMenu_AddButton(info);

	info = { };
	if ( tempOptions["LockEmergency"] ) then
		info.text = "Unlock window";
	else
		info.text = "Lock window";
	end
	info.value = "mToggleLock";
	info.notCheckable = 1;
	info.func = CT_RA_Emergency_DropDown_OnClick;
	L_UIDropDownMenu_AddButton(info);

	info = { };
	info.text = "Background color";
	info.hasColorSwatch = 1;
	info.hasOpacity = 1;
	if ( tempOptions["EMBG"] ) then
		info.r = ( tempOptions["EMBG"].r );
		info.g = ( tempOptions["EMBG"].g );
		info.b = ( tempOptions["EMBG"].b );
		info.opacity = ( tempOptions["EMBG"].a );
	else
		info.r = 0;
		info.g = 0;
		info.b = 0;
		info.opacity = 0.33;
	end
	info.notClickable = 1;
	info.swatchFunc = CT_RA_Emergency_DropDown_SwatchFunc;
	info.opacityFunc = CT_RA_Emergency_DropDown_OpacityFunc;
	info.cancelFunc = CT_RA_Emergency_DropDown_CancelFunc;
	info.notCheckable = 1;
	L_UIDropDownMenu_AddButton(info);

	info = {};
	info.text = "Close this menu";
	info.value = "mCloseMenu";
	info.notCheckable = 1;
	info.func = CT_RA_Emergency_DropDown_OnClick;
	L_UIDropDownMenu_AddButton(info);
end

function CT_RA_Emergency_DropDown_SwatchFunc()
	local tempOptions = CT_RAMenu_Options["temp"];
	local r, g, b = ColorPickerFrame:GetColorRGB();
	if ( not tempOptions["EMBG"] ) then
		tempOptions["EMBG"] = { ["r"] = r, ["g"] = g, ["b"] = b, ["a"] = 0 };
	else
		tempOptions["EMBG"]["r"] = r;
		tempOptions["EMBG"]["g"] = g;
		tempOptions["EMBG"]["b"] = b;
	end
	CT_RA_EmergencyFrame:SetBackdropColor(r, g, b, tempOptions["EMBG"]["a"]);
	CT_RA_EmergencyFrame:SetBackdropBorderColor(1, 1, 1, tempOptions["EMBG"]["a"]);
end

function CT_RA_Emergency_DropDown_OpacityFunc()
	local tempOptions = CT_RAMenu_Options["temp"];
	local r, g, b = 1, 1, 1;
	if ( tempOptions["EMBG"] ) then
		r, g, b = tempOptions["EMBG"].r, tempOptions["EMBG"].g, tempOptions["EMBG"].b;
	end
	local a = OpacitySliderFrame:GetValue();
	tempOptions["EMBG"]["a"] = a;
	CT_RA_EmergencyFrame:SetBackdropColor(r, g, b, a);
	CT_RA_EmergencyFrame:SetBackdropBorderColor(1, 1, 1, a);
end

function CT_RA_Emergency_DropDown_CancelFunc(val)
	local tempOptions = CT_RAMenu_Options["temp"];
	tempOptions["EMBG"] = {
		["r"] = val.r,
		["g"] = val.g,
		["b"] = val.b,
		["a"] = val.opacity
	};
	CT_RA_EmergencyFrame:SetBackdropColor(val.r, val.g, val.b, val.opacity);
	CT_RA_EmergencyFrame:SetBackdropBorderColor(1, 1, 1, val.opacity);
end

function CT_RA_Emergency_DropDown_OnClick(self)
	local tempOptions = CT_RAMenu_Options["temp"];
	local menu = strsub(self.value, 1, 1);
	local value = strsub(self.value, 2);
	if (menu == "m") then
		if (value == "CloseMenu") then
			L_CloseDropDownMenus();
			return;
		elseif (value == "ToggleLock") then
			if (tempOptions["LockEmergency"]) then
				tempOptions["LockEmergency"] = nil;
			else
				tempOptions["LockEmergency"] = 1;
			end
		end
	elseif (menu == "c") then
		if ( not tempOptions["EMClasses"] ) then
			tempOptions["EMClasses"] = { };
		end
		tempOptions["EMClasses"][value] = not tempOptions["EMClasses"][value];
		CT_RA_Emergency_UpdateHealth();
	elseif (menu == "g") then
		if ( not tempOptions["EMGroups"] ) then
			tempOptions["EMGroups"] = { };
		end
		value = tonumber(value);
		tempOptions["EMGroups"][value] = not tempOptions["EMGroups"][value];
		CT_RA_Emergency_UpdateHealth();
	end
end

function CT_RA_Emergency_ToggleDropDown(self)
	local left, top = self:GetCenter();
	local uileft, uitop = UIParent:GetCenter();
	if ( left > uileft ) then
		CT_RA_EmergencyFrameDropDown.point = "TOPRIGHT";
		CT_RA_EmergencyFrameDropDown.relativePoint = "BOTTOMLEFT";
	else
		CT_RA_EmergencyFrameDropDown.point = "TOPLEFT";
		CT_RA_EmergencyFrameDropDown.relativePoint = "BOTTOMRIGHT";
	end
	CT_RA_EmergencyFrameDropDown.relativeTo = self:GetName();
	L_ToggleDropDownMenu(1, nil, CT_RA_EmergencyFrameDropDown);
end

-- RADurability stuff
function CT_RADurability_GetDurability()
	local currDur, maxDur, brokenItems = 0, 0, 0;
	local itemIds = {
		1, 2, 3, 5, 6, 7, 8, 9, 10, 16, 17, 18
	};
	for k, v in pairs(itemIds) do
		CT_RADurationTooltip:ClearLines();
		CT_RADurationTooltip:SetInventoryItem("player", v);
		for i = 1, CT_RADurationTooltip:NumLines(), 1 do
			local useless, useless, sMin, sMax = string.find(_G["CT_RADurationTooltipTextLeft" .. i]:GetText() or "", CT_RA_DURABILITY);
			if ( sMin and sMax ) then
				local iMin, iMax = tonumber(sMin), tonumber(sMax);
				if ( iMin == 0 ) then
					brokenItems = brokenItems + 1;
				end
				currDur = currDur + iMin;
				maxDur = maxDur + iMax;
				break;
			end
		end
	end
	return currDur, maxDur, brokenItems;
end

function CT_RAReagents_GetReagents()
	local numItems = 0;
	local classes = {
		[CT_RA_CLASS_MAGE_EN] = { CT_RA_REAGENT_MAGE , CT_RA_REAGENT_MAGE_SPELL },
		[CT_RA_CLASS_DRUID_EN] = { CT_RA_REAGENT_DRUID ,CT_RA_REAGENT_DRUID_SPELL },
		[CT_RA_CLASS_SHAMAN_EN] = { CT_RA_REAGENT_SHAMAN, CT_RA_REAGENT_SHAMAN_SPELL }
	};
	local _, classEN = UnitClass("player");
	local plClass = classes[classEN];
	if ( not plClass or ( plClass[2] and not CT_RA_ClassSpells[plClass[2]] ) ) then
		return;
	end
	for i = 0, 4, 1 do
		for y = 1, MAX_CONTAINER_ITEMS, 1 do
			local link = GetContainerItemLink(i, y);
			if ( link ) then
				local _, _, name = string.find(link, "%[(.+)%]");
				if ( name ) then
					if ( plClass and plClass[1] == name ) then
						local texture, itemCount, locked, quality, readable = GetContainerItemInfo(i,y);
						numItems = numItems + itemCount;
					end
				end
			end
		end
	end
	return numItems;
end

function CT_RAItem_GetItems(itemName)
	local numItems = 0;
	for i = 0, 4, 1 do
		for y = 1, MAX_CONTAINER_ITEMS, 1 do
			local link = GetContainerItemLink(i, y);
			if ( link ) then
				local _, _, name = string.find(link, "%[(.+)%]");
				if ( name == itemName ) then
					local texture, itemCount, locked, quality, readable = GetContainerItemInfo(i,y);
					numItems = numItems + itemCount;
				end
			end
		end
	end
	return numItems;
end

CT_RADurability_Shown = { };
CT_RADurability_Sorting = {
	["curr"] = 4,
	[3] = { "a", "a" },
	[4] = { "a", "a" }
};
tinsert(UISpecialFrames, "CT_RA_DurabilityFrame");


function CT_RADurability_Add(name, info, fileName, ...)
	local tbl = { name, info, fileName };
	for i = 1, select('#', ...), 1 do
		tinsert(tbl, ( tonumber((select(i, ...))) or select(i, ...) ));
	end
	tinsert(CT_RADurability_Shown, tbl);
	CT_RADurability_Sort(CT_RADurability_Sorting["curr"], 1);
	CT_RADurability_Update();
end

function CT_RADurability_Sort(sortBy, maintain)
	if ( CT_RADurability_Sorting["curr"] ~= sortBy ) then
		CT_RADurability_Sorting[sortBy][1] = CT_RADurability_Sorting[sortBy][2];
	end
	CT_RADurability_Sorting["curr"] = sortBy;
	if ( CT_RADurability_Sorting[sortBy][1] == "a" ) then
		if ( not maintain ) then
			CT_RADurability_Sorting[sortBy][1] = "b";
		end
	else
		if ( not maintain ) then
			CT_RADurability_Sorting[sortBy][1] = "a";
		end
	end
	if ( CT_RADurability_Sorting[sortBy][1] == "b" ) then
		table.sort(CT_RADurability_Shown,
			function(t1, t2)
				if (t1[sortBy] == t2[sortBy] ) then
					if ( t1[3] == t2[3] ) then
						return t1[1] < t2[1]
					else
						return t1[3] < t2[3]
					end
				else
					return t1[sortBy] < t2[sortBy]
				end
			end
		);
	else
		table.sort(CT_RADurability_Shown,
			function(t1, t2)
				if (t1[sortBy] == t2[sortBy] ) then
					if ( t1[3] == t2[3] ) then
						return t1[1] < t2[1]
					else
						return t1[3] < t2[3]
					end
				else
					return t1[sortBy] > t2[sortBy]
				end
			end
		);
	end
	CT_RADurability_Update();
end

function CT_RADurability_Update()
	local numEntries = #CT_RADurability_Shown;
	FauxScrollFrame_Update(CT_RA_DurabilityFrameScrollFrame, numEntries, 19, 20);

	for i = 1, 19, 1 do
		local button = _G["CT_RA_DurabilityFramePlayer" .. i];
		local index = i + FauxScrollFrame_GetOffset(CT_RA_DurabilityFrameScrollFrame);
		if ( index <= numEntries ) then
			if ( numEntries <= 19 ) then
				button:SetWidth(275);
			else
				button:SetWidth(253);
			end
			if ( CT_RA_DurabilityFrame.type ~= "RARST" or numEntries <= 19 ) then
				CT_RA_DurabilityFrameScrollFrame:SetPoint("TOPLEFT", "CT_RA_DurabilityFrame", "TOPLEFT", 19, -27);
				_G[button:GetName() .. "Resist1"]:SetPoint("LEFT", button:GetName(), "LEFT", 127, 0);
				CT_RA_DurabilityFrameNameTab:SetWidth(135);
			else
				CT_RA_DurabilityFrameScrollFrame:SetPoint("TOPLEFT", "CT_RA_DurabilityFrame", "TOPLEFT", 19, -32);
				_G[button:GetName() .. "Resist1"]:SetPoint("LEFT", button:GetName(), "LEFT", 110, 0);
				CT_RA_DurabilityFrameNameTab:SetWidth(118);
			end
			button:Show();
			_G[button:GetName() .. "Name"]:SetText(CT_RADurability_Shown[index][1]);
			local color = RAID_CLASS_COLORS[CT_RADurability_Shown[index][3]];
			if ( color ) then
				_G[button:GetName() .. "Name"]:SetTextColor(color.r, color.g, color.b);
			end
			_G[button:GetName() .. "Info"]:SetText(CT_RADurability_Shown[index][2]);
			for i = 1, 5, 1 do
				if ( CT_RA_DurabilityFrame.type == "RARST" and CT_RADurability_Shown[index][3+i] ~= -1 ) then
					_G[button:GetName() .. "Resist" .. i]:SetText(CT_RADurability_Shown[index][3+i]);
					_G[button:GetName() .. "Resist" .. i]:Show();
				else
					_G[button:GetName() .. "Resist" .. i]:Hide();
				end
			end
		else
			button:Hide();
		end
	end

end

CT_RA_CurrDebuffs = { };

function CT_RA_AddDebuffMessage(name, dType, player)
	if ( not dType ) then
		return;
	end
	if ( CT_RA_CurrDebuffs[name .. "@" .. dType] ) then
		if ( not CT_RA_CurrDebuffs[name .. "@" .. dType][3][player] ) then
			CT_RA_CurrDebuffs[name .. "@" .. dType][3][player] = 1;
			CT_RA_CurrDebuffs[name .. "@" .. dType][2] = CT_RA_CurrDebuffs[name .. "@" .. dType][2] + 1;
			CT_RA_CurrDebuffs[name .. "@" .. dType][1] = 0.4;
		end
	else
		CT_RA_CurrDebuffs[name .. "@" .. dType] = {
			0.4, 1, {
				[player] = 1
			},
			player
		};
	end
end

function CT_RA_RGBToHex(r, g, b)
	return format("%.2x%.2x%.2x", floor(r*255), floor(g*255), floor(b*255));
end
