local UnitName = CT_RA_UnitName;
local GetNumRaidMembers = CT_RA_GetNumRaidMembers;

tinsert(UISpecialFrames, "CT_RA_SlashCmdFrame");

function CT_RASlashCmd_DisplayDialog()
	table.sort(CT_RA_SlashCmds, function(t1, t2)
		return t1[2] < t2[2]
	end);
	-- Initialize dialog
	local totalHeight = 0;
	for i = 1, 30, 1 do
		local obj = _G["CT_RA_SlashCmdFrameScrollFrameCmdsCmd" .. i];
		if ( CT_RA_SlashCmds[i] ) then
			obj.slashCommand = CT_RA_SlashCmds[i][2];
			obj:Show();
			_G[obj:GetName() .. "Text"]:SetText(CT_RA_SlashCmds[i][2]);
			_G[obj:GetName() .. "Description"]:SetText(CT_RA_SlashCmds[i][3]);
			if ( strlen(CT_RA_SlashCmds[i][4]) > 0 ) then
				_G[obj:GetName() .. "Available"]:SetText("Shortcuts Available: |c00FFFFFF" .. CT_RA_SlashCmds[i][4] .. "|r");
				obj:SetHeight(CT_RA_SlashCmds[i][1]+33);
			else
				_G[obj:GetName() .. "Available"]:SetText("");
				obj:SetHeight(CT_RA_SlashCmds[i][1]+25);
			end
			_G[obj:GetName() .. "Description"]:SetHeight(CT_RA_SlashCmds[i][1]);
			totalHeight = totalHeight + CT_RA_SlashCmds[i][1];
		else
			obj:Hide();
		end
		if ( i > 1 ) then
			obj:SetPoint("TOPLEFT", "CT_RA_SlashCmdFrameScrollFrameCmdsCmd" .. (i-1), "BOTTOMLEFT");
		end
	end
	CT_RA_SlashCmdFrameScrollFrameCmds:SetHeight(totalHeight);
	ShowUIPanel(CT_RA_SlashCmdFrame);
	CT_RA_SlashCmdFrameScrollFrame:UpdateScrollChildRect();
	
	local minVal, maxVal = CT_RA_SlashCmdFrameScrollFrameScrollBar:GetMinMaxValues();
	if ( maxVal == 0 ) then
		CT_RA_SlashCmdFrameScrollFrameScrollBar:Hide();
	else
		CT_RA_SlashCmdFrameScrollFrameScrollBar:Show();
	end
end

CT_RA_SlashCmds = { };

function CT_RA_RegisterSlashCmd(title, description, height, identifier, func, ...)
	SlashCmdList[identifier] = func;
	local otherCmds = "";
	for i = 1, select('#', ...), 1 do
		_G["SLASH_" .. identifier .. i] = (select(i, ...));
		if ( i > 1 ) then
			if ( strlen(otherCmds) > 0 ) then
				otherCmds = otherCmds .. ", ";
			end
			otherCmds = otherCmds .. (select(i, ...));
		end
	end
	local num = 0;
	while ( string.find(description, "|b.-|eb") ) do
		description = string.gsub(description, "^(.*)|b(.-)|eb(.*)$", "%1|c00FFD100%2|r%3");
		num = num + 1;
		if ( num > 10 ) then
			break;
		end
	end
	tinsert(CT_RA_SlashCmds, { height, title, description, otherCmds });
end

function CT_RA_Invite(msg)
	if ( not GetGuildInfo("player") ) then
		CT_RA_Print("<CTRaid> You need to be in a guild to mass invite.");
		return;
	end
	if ( ( not CT_RA_Level or CT_RA_Level == 0 ) and GetNumRaidMembers() > 0 ) then
		CT_RA_Print("<CTRaid> You must be promoted or raid leader to mass invite.", 1, 1, 0);
		return;
	end
	local inZone = "";
	if ( CT_RA_ZoneInvite ) then
		inZone = " in " .. GetRealZoneText();
	end
	local useless, useless, min, max = string.find(msg, "^(%d+)-(%d+)$");
	min = tonumber(min);
	max = tonumber(max);
	if ( min and max ) then
		if ( min > max ) then
			local temp = min;
			min = max;
			max = temp;
		end
		if ( min < 1 ) then min = 1; end
		-- if ( max > 70 ) then max = 70; end
		if ( min == max ) then
			SendChatMessage("Raid invites are coming in 10 seconds for players level " .. min .. inZone .. ", leave your groups.", "GUILD");
		else
			SendChatMessage("Raid invites are coming in 10 seconds for players level " .. min .. " to " .. max .. inZone .. ", leave your groups.", "GUILD");
		end
		GuildRoster();
		CT_RA_MinLevel = min;
		CT_RA_MaxLevel = max;
		CT_RA_UpdateFrame.startinviting = 10;
	else
		useless, useless, min = string.find(msg, "^(%d+)$");
		min = tonumber(min);
		if ( min ) then
			if ( min < 1 ) then min = 1; end
			-- if ( min > 70 ) then min = 70; end
			GuildRoster();
			SendChatMessage("Raid invites are coming in 10 seconds for players level " .. min .. inZone .. ", leave your groups.", "GUILD");
			CT_RA_MinLevel = min;
			CT_RA_MaxLevel = min;
			CT_RA_UpdateFrame.startinviting = 10;
		else
			if ( CT_RA_ZoneInvite ) then
				CT_RA_Print("<CTRaid> Syntax Error. Usage: |c00FFFFFF/razinvite level|r or |c00FFFFFF/razinvite minlevel-maxlevel|r.", 1, 0.5, 0);
				CT_RA_Print("<CTRaid> This command mass invites everybody in the guild in the current zone within the selected level range (or only selected level if maxlevel is omitted).", 1, 0.5, 0);
			else
				CT_RA_Print("<CTRaid> Syntax Error. Usage: |c00FFFFFF/rainvite level|r or |c00FFFFFF/rainvite minlevel-maxlevel|r.", 1, 0.5, 0);
				CT_RA_Print("<CTRaid> This command mass invites everybody in the guild within the selected level range (or only selected level if maxlevel is omitted).", 1, 0.5, 0);
			end
		end
	end
end

-- Slash commands
	-- /raslash
CT_RA_RegisterSlashCmd("/rahelp", "Shows this dialog.", 15, "RAHELP", CT_RASlashCmd_DisplayDialog, "/rahelp");

	-- /rares
CT_RA_RegisterSlashCmd("/rares", "Usable via |b/rares [show/hide]|eb, this shows or hides the resurrection monitor.", 15, "RARES", function(msg)
	msg = string.lower(msg);
	if ( msg == "show" ) then
--		if ( GetNumRaidMembers() > 0 ) then
--			CT_RA_ResFrame:Show();
--		end
		CT_RAMenu_Options["temp"]["ShowMonitor"] = 1;
		CT_RA_UpdateResFrame();
		CT_RAMenu_UpdateMenu();
	elseif ( msg == "hide" ) then
--		CT_RA_ResFrame:Hide();
		CT_RAMenu_Options["temp"]["ShowMonitor"] = nil;
		CT_RA_UpdateResFrame();
		CT_RAMenu_UpdateMenu();
	else
		CT_RA_Print("<CTRaid> Usage: |c00FFFFFF/rares [show/hide]|r - Shows/hides the Resurrection Monitor.", 1, 0.5, 0);
	end
end, "/rares");

	-- /rs
CT_RA_RegisterSlashCmd("/rs", "Usable via |b/rs [text]|eb, this sends a message to all CTRA users in the raid, which appears in the center of the screen (|brequires leader or promoted status|eb).", 30, "RS", function(msg)
	if ( CT_RA_Level >= 1 ) then
		if ( CT_RAMenu_Options["temp"]["SendRARS"] ) then
			SendChatMessage(msg, "RAID");
		end
		CT_RA_AddMessage("MS " .. string.gsub(msg, "%%[tT]", UnitName("target") or TARGET_TOKEN_NOT_FOUND));
	else
		CT_RA_Print("<CTRaid> You must be promoted or leader to do that!", 1, 1, 0);
	end
end, "/rs");

	-- /raupdate
CT_RA_RegisterSlashCmd("/raupdate", "Updates raid stats (|brequires leader or promoted status|eb).", 15, "RAUPDATE", function()
	if ( CT_RA_Level >= 1 ) then
		CT_RA_AddMessage("SR");
		CT_RA_Print("<CTRaid> Stats have been updated for the raid group.", 1, 0.5, 0);
	else
		CT_RA_Print("<CTRaid> You must be promoted or leader to do that!", 1, 0.5, 0);
	end
end, "/raupdate", "/raupd");

	-- /rakeyword
CT_RA_RegisterSlashCmd("/rakeyword", "Automatically invites people that whisper you the specified keyword. Usage: |b/rakeyword [off]|eb, or |b/rakeyword keyword|eb", 30, "RAKEYWORD", function(msg)
	msg = string.lower(msg);
	if ( msg == "off" ) then
		CT_RAMenu_Options["temp"]["KeyWord"] = nil;
		CT_RA_Print("<CTRaid> Keyword Inviting has been turned off.", 1, 0.5, 0);
	elseif ( msg == "" ) then
		local kw = CT_RAMenu_Options["temp"]["KeyWord"];
		if ( kw ) then
			CT_RA_Print("<CTRaid> The Invite Keyword is: '|c00FFFFFF" .. kw .. "|r'. Use |c00FFFFFF/rakeyword off|r to turn Keyword Inviting off.", 1, 0.5, 0);
		else
			CT_RA_Print("<CTRaid> There is no Invite Keyword set.", 1, 0.5, 0);
		end
	else
		CT_RAMenu_Options["temp"]["KeyWord"] = msg;
		CT_RA_Print("<CTRaid> Invite Keyword has been set to '|c00FFFFFF" .. msg .. "|r'. Use |c00FFFFFF/rakeyword off|r to turn Keyword Inviting off.", 1, 0.5, 0);
	end
end, "/rakeyword", "/rakw");

	-- /radisband
CT_RA_RegisterSlashCmd("/radisband", "Disbands the raid (|brequires leader or promoted status|eb)", 15, "RADISBAND", function(msg)
	if ( CT_RA_Level and CT_RA_Level >= 1 ) then
		CT_RA_Print("<CTRaid> Disbanding raid...", 1, 0.5, 0);
		SendChatMessage("<CTRaid> Disbanding raid on request by " .. UnitName("player") .. ".", "RAID");
		for i = 1, GetNumRaidMembers(), 1 do
			local name, rank, subgroup, level, class, fileName, zone, online, isDead = GetRaidRosterInfo(i);
			if ( online and rank <= CT_RA_Level and name ~= UnitName("player") ) then
				UninviteUnit(name);
			end
		end
		CT_RA_AddMessage("DB");
		LeaveParty();
	else
		CT_RA_Print("<CTRaid> You need to be raid leader or promoted to do that!", 1, 0.5, 0);
	end
end, "/radisband");

	-- /rashow
CT_RA_RegisterSlashCmd("/rashow", "Usable via |b/rashow|eb, |b/rashow all|eb, |b/rashow groups|eb, |b/rashow classes|eb, or |b/rashow both|eb, this shows all hidden groups/classes, all groups or classes (depends on sort type), all groups, all classes, or all groups and classes.", 45, "RASHOW", function(msg)
	if (InCombatLockdown()) then
		return;
	end
	msg = string.lower(msg);
	if ( msg == "all" ) then
		local tempOptions = CT_RAMenu_Options["temp"];
		if (tempOptions["SORTTYPE"] == "class") then
			CT_RA_CheckAllClasses(1);
		else
			CT_RA_CheckAllGroups(1);
		end
	elseif ( msg == "both" ) then
		-- Show all the groups and classes
		CT_RA_CheckAllGroupsAndClasses(1);
	elseif ( msg == "groups" ) then
		-- Show all the groups
		CT_RA_CheckAllGroups(1);
	elseif ( msg == "classes" ) then
		-- Show all the classes
		CT_RA_CheckAllClasses(1);
	else
		-- Unhide the groups (if any are hidden)
		CT_RA_UnhideWindows();
	end
end, "/rashow");

	-- /rahide
CT_RA_RegisterSlashCmd("/rahide", "Usable via |b/rahide|eb, |b/rahide all|eb, |b/rahide groups|eb, |b/rahide classes|eb, or |b/rahide both|eb, this hides all visible groups/classes, all groups or classes (depends on sort type), all groups, all classes, or all groups and classes.", 45, "RAHIDE", function(msg)
	if (InCombatLockdown()) then
		return;
	end
	msg = string.lower(msg);
	if ( msg == "all" ) then
		local tempOptions = CT_RAMenu_Options["temp"];
		if (tempOptions["SORTTYPE"] == "class") then
			CT_RA_CheckAllClasses(nil);
		else
			CT_RA_CheckAllGroups(nil);
		end
	elseif ( msg == "both" ) then
		-- Hide all the groups and classes
		CT_RA_CheckAllGroupsAndClasses(nil);
	elseif ( msg == "groups" ) then
		-- Hide all the groups
		CT_RA_CheckAllGroups(nil);
	elseif ( msg == "classes" ) then
		-- Hide all the classes
		CT_RA_CheckAllClasses(nil);
	else
		-- Hide the groups (if not already hidden)
		CT_RA_HideWindows();
	end
end, "/rahide");

	-- /raoptions
CT_RA_RegisterSlashCmd("/raoptions", "Shows the options dialog.", 20, "RAOPTIONS", function(msg)
	CT_RAMenuFrame:Show();
end, "/raoptions", "/ctra", "/ctraid");

	-- /rainvite
CT_RA_RegisterSlashCmd("/rainvite", "Usable via |b/rainvite minlevel-maxlevel|eb or |b/rainvite level|eb this will invite all guild members within the chosen level range.", 30, "RAINVITE", function(msg)
	CT_RA_ZoneInvite = nil;
	CT_RA_Invite(msg);
end, "/rainvite", "/rainv");

	-- /razinvite
CT_RA_RegisterSlashCmd("/razinvite", "Usable via |b/rainvite minlevel-maxlevel|eb or |b/rainvite level|eb this will invite all guild members within the chosen level range in your own zone.", 30, "RAZINVITE", function(msg)
	CT_RA_ZoneInvite = 1;
	CT_RA_Invite(msg);
end, "/razinvite", "/razinv");

	-- /radur
CT_RA_RegisterSlashCmd("/radur", "Performs a durability check, which shows every CTRA member's durability percent (|brequires promoted or leader status|eb).", 30, "RADUR", function()
	if ( CT_RA_Level >= 1 ) then
		CT_RADurability_Shown = { };
		CT_RADurability_Sorting = {
			["curr"] = 4,
			[3] = { "a", "a" },
			[4] = { "a", "a" }
		};
		CT_RA_DurabilityFrame.type = "RADUR";
		CT_RA_DurabilityFrame.arg = nil;
		CT_RADurability_Update();
		ShowUIPanel(CT_RA_DurabilityFrame);
		CT_RA_DurabilityFrameValueTab:SetText("Durability Percent");
		CT_RA_DurabilityFrameValueTab:Show();
		for i = 1, 5, 1 do
			_G["CT_RA_DurabilityFrameResistTab" .. i]:Hide();
		end
		CT_RA_DurabilityFrameTitle:SetText("Durability Check");
		CT_RA_AddMessage("DURC");
	else
		CT_RA_Print("<CTRaid> You need to be promoted or leader to do that!", 1, 0.5, 0);
	end
end, "/radur");

	-- /rareg
CT_RA_RegisterSlashCmd("/rareg", "Performs a reagent check, which shows every CTRA member's reagent count (|brequires promoted or leader status|eb).", 30, "RAREG", function()
	if ( CT_RA_Level >= 1 ) then
		CT_RADurability_Shown = { };
		CT_RADurability_Sorting = {
			["curr"] = 3,
			[3] = { "a", "a" },
			[4] = { "a", "a" }
		};
		CT_RA_DurabilityFrame.type = "RAREG";
		CT_RA_DurabilityFrame.arg = nil;
		CT_RA_DurabilityFrameValueTab:SetText("Reagent Count");
		CT_RA_DurabilityFrameValueTab:Show();
		for i = 1, 5, 1 do
			_G["CT_RA_DurabilityFrameResistTab" .. i]:Hide();
		end
		CT_RADurability_Update();
		ShowUIPanel(CT_RA_DurabilityFrame);
		CT_RA_DurabilityFrameTitle:SetText("Reagent Check");
		CT_RA_AddMessage("REAC");
	else
		CT_RA_Print("<CTRaid> You need to be promoted or leader to do that!", 1, 0.5, 0);
	end
end, "/rareg", "/rareag", "/rareagent");


	-- /raitem
CT_RA_RegisterSlashCmd("/raitem", " Usable via |b/raitem ItemName|eb or |b/raitem [ItemLink]|eb; allowing for you to type in or Shift+Click a link to see everyone in raid who has the item listed.  (Very useful to do |b/raitem Aqual Quintessence|eb to see who came to MC prepared).", 45, "RAITEM", function(itemName)
	if ( CT_RA_Level >= 1 ) then
		if ( not itemName ) then
			CT_RA_Print("<CTRaid> Usage: |c00FFFFFF/raitem Item Name|r  NOTE: You can also use item links.", 1, 0.5, 0);
			return;
		end
		local _, _, linkName = string.find(itemName, "%[(.+)%]");
		if ( linkName ) then
			itemName = linkName;
		end
		CT_RADurability_Shown = { };
		CT_RADurability_Sorting = {
			["curr"] = 4,
			[3] = { "a", "a" },
			[4] = { "a", "a" }
		};
		CT_RA_DurabilityFrame.type = "RAITEM";
		CT_RA_DurabilityFrame.arg = itemName;
		CT_RA_DurabilityFrameValueTab:SetText("Item Count");
		CT_RA_DurabilityFrameValueTab:Show();
		for i = 1, 5, 1 do
			_G["CT_RA_DurabilityFrameResistTab" .. i]:Hide();
		end
		CT_RADurability_Update();
		ShowUIPanel(CT_RA_DurabilityFrame);
		CT_RA_DurabilityFrameTitle:SetText("Item Check");
		CT_RA_AddMessage("ITMC " .. itemName);
	else
		CT_RA_Print("<CTRaid> You need to be promoted or leader to do that!", 1, 0.5, 0);
	end
end, "/raitem");

	-- /raversion
CT_RA_RegisterSlashCmd("/raversion", "Performs a version check, which shows every member's CTRA version.", 15, "RAVERSION", function()
		CT_RADurability_Shown = { };
		CT_RADurability_Sorting = {
			["curr"] = 4,
			[3] = { "a", "b" },
			[4] = { "a", "b" }
		};
		CT_RA_DurabilityFrame.type = "RAVERSION";
		CT_RA_DurabilityFrameValueTab:SetText("Version");
		CT_RA_DurabilityFrameValueTab:Show();
		for i = 1, 5, 1 do
			_G["CT_RA_DurabilityFrameResistTab" .. i]:Hide();
		end
		CT_RADurability_Update();
		ShowUIPanel(CT_RA_DurabilityFrame);
		CT_RA_DurabilityFrameTitle:SetText("Version Check");
		for i = 1, GetNumRaidMembers(), 1 do
			local name = UnitName("raid" .. i);
			if ( CT_RA_Stats[name] and CT_RA_Stats[name]["Version"] ) then
				local name, rank, subgroup, level, class, fileName = GetRaidRosterInfo(i);
				CT_RADurability_Add(name, CT_RA_Stats[name]["Version"], fileName, CT_RA_Stats[name]["Version"]);
			else
				local name, rank, subgroup, level, class, fileName = GetRaidRosterInfo(i);
				CT_RADurability_Add(name, "|c00666666No CTRA Found|r", fileName, 0);
			end
		end
end, "/raversion", "/raver");

	-- /raresist (Thanks Sudo!)
CT_RA_RegisterSlashCmd("/raresist", "Performs a resistance check, which shows every CTRA member's resistances (|brequires promoted or leader status|eb).", 30, "RARST", function(msg)
	if ( CT_RA_Level >= 1 ) then
		CT_RADurability_Shown = { };
		CT_RADurability_Sorting = {
			["curr"] = 3,
			[3] = { "a", "a" },
			[4] = { "b", "b" },
			[5] = { "b", "b" },
			[6] = { "b", "b" },
			[7] = { "b", "b" },
			[8] = { "b", "b" },
		};
		
		CT_RA_DurabilityFrame.type = "RARST";
		CT_RA_DurabilityFrameValueTab:Hide();
		for i = 1, 5, 1 do
			_G["CT_RA_DurabilityFrameResistTab" .. i]:Show();
		end
		CT_RADurability_Update();
		ShowUIPanel(CT_RA_DurabilityFrame);
		CT_RA_DurabilityFrameTitle:SetText("Resist Check");
		CT_RA_AddMessage("RSTC");
	else
		CT_RA_Print("<CTRaid> You need to be promoted or leader to do that!", 1, 0.5, 0);
	end
end, "/raresist", "/raresists");

	-- /razone
CT_RA_RegisterSlashCmd("/razone", "Performs a zone check, which shows every CTRA member outside of your zone.", 30, "RAZONE", function(msg)
	CT_RADurability_Shown = { };
	CT_RADurability_Sorting = {
		["curr"] = 3,
		[3] = { "a", "a" },
		[4] = { "a", "a" }
	};
	CT_RA_DurabilityFrame.type = "RAZONE";
	CT_RA_DurabilityFrameValueTab:Show();
	for i = 1, 5, 1 do
		_G["CT_RA_DurabilityFrameResistTab" .. i]:Hide();
	end
	CT_RADurability_Update();
	ShowUIPanel(CT_RA_DurabilityFrame);
	CT_RA_DurabilityFrameTitle:SetText("Zone Check");
	CT_RA_DurabilityFrameValueTab:SetText("Zone Name");
	
	local name, rank, subgroup, level, class, fileName, zone;
	for i = 1, GetNumRaidMembers(), 1 do
		name, rank, subgroup, level, class, fileName, zone = GetRaidRosterInfo(i);
		if ( name ~= UnitName("player") and zone and zone ~= "" and zone ~= "Offline" and zone ~= GetRealZoneText() ) then
			CT_RADurability_Add(name, zone, fileName);
		end
	end
end, "/razone");

	-- /raquiet (by Angarth)
CT_RA_RegisterSlashCmd("/raquiet", "Stop the raid from talking while leaders talk (|brequires leader or promoted status|eb).", 15, "RASQUELCH", function()
	if ( CT_RA_Level >= 1 ) then
		if ( CT_RA_Squelch > 0 ) then
			SendChatMessage("<CTRaid> Quiet mode is over.", "RAID");
			CT_RA_Print("<CTRaid> Quiet Mode has been disabled.", 1, 0.5, 0);
			CT_RA_Squelch = 0;
		else
			SendChatMessage("<CTRaid> Quiet mode, no talking.", "RAID");
			CT_RA_Print("<CTRaid> Quiet Mode has been enabled.", 1, 0.5, 0);
			CT_RA_Squelch = 5*60;
		end
	else
		CT_RA_Print("<CTRaid> You must be promoted or leader to do that!", 1, 0.5, 0);
	end
end, "/raquiet", "/rasquelch");

	-- /ratab
CT_RA_RegisterSlashCmd("/ratab", "Display the CT raid window.", 15, "RATAB", function()
	ShowUIPanel(CT_RATabFrame);
end, "/ratab");

-- Hook SendChatMessage()
local oldSendChatMessage = SendChatMessage;
function SendChatMessage(msg, type, language, target)
		if ( type == "RAID" ) then
			if ( CT_RA_Squelch > 0 and CT_RA_Level < 1 ) then
				CT_RA_Print("<CTRaid> You can't talk in the raid channel at this time (Quiet Mode enabled).", 1, 0.5, 0);
				return;
			end
		end
		oldSendChatMessage(msg, type, language, target);
end
