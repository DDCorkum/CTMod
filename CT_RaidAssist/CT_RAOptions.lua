local UnitName = CT_RA_UnitName;
local GetNumRaidMembers = CT_RA_GetNumRaidMembers;

CT_RA_VersionNumber = 8.0105; -- Used for number comparisons

CT_RA_Version = "v" .. CT_RA_VersionNumber;
CT_RA_MOVINGMEMBER = nil;
CT_RA_CURRSLOT = nil;
CT_RA_CurrPositions = { };
CT_RA_CustomPositions = { };
CT_RA_MainTanks = { };
CT_RA_CurrMembers = { };
CT_RA_ButtonIndexes = { };
CT_RATab_AutoPromotions = { };

local CT_RATabFrame_SubFrames = { "CT_RAOptionsFrame", "CT_RAOptions2Frame" };

function CT_RATabFrame_OnLoad(self)
	UIPanelWindows["CT_RATabFrame"] = { area = "left",	pushable = 3,	whileDead = 1 };

	PanelTemplates_SetNumTabs(self, #CT_RATabFrame_SubFrames);
	self.selectedTab = 1;
	PanelTemplates_UpdateTabs(self);
end

function CT_RATabFrame_ShowSubFrame(frameName)
	for index, value in pairs(CT_RATabFrame_SubFrames) do
		if ( value == frameName ) then
			_G[value]:Show()
		else
			_G[value]:Hide();
		end
	end
end

function CT_RATabFrame_OnShow()
	CT_RATabFrameTitleText:SetText("CT_RaidAssist  " .. CT_RA_Version);
	CT_RATabFrame_Update();
	PlaySound(841);
end

function CT_RATabFrame_Update()
	if ( CT_RATabFrame.selectedTab == 1 ) then
		CT_RATabFrameTopLeft:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-General-TopLeft");
		CT_RATabFrameTopRight:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-General-TopRight");
		CT_RATabFrameBottomLeft:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-General-BottomLeft");
		CT_RATabFrameBottomRight:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-General-BottomRight");
		CT_RATabFrame_ShowSubFrame("CT_RAOptionsFrame");
	elseif ( CT_RATabFrame.selectedTab == 2 ) then
		CT_RATabFrameTopLeft:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-TopLeft");
		CT_RATabFrameTopRight:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-TopRight");
		CT_RATabFrameBottomLeft:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-General-BottomLeft");
		CT_RATabFrameBottomRight:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-General-BottomRight");
		CT_RATabFrame_ShowSubFrame("CT_RAOptions2Frame");
	end
end

function CT_RATabFrame_OnHide()
	PlaySound(851);
end

function CT_RATabFrame_Tab_OnClick(self)
	PanelTemplates_Tab_OnClick(self, CT_RATabFrame);
	CT_RATabFrame_OnShow(self);
end

function CT_RAOptionsGroupButton_OnMouseDown(self, button)
	if ( button == "RightButton" and self.name ) then
		ToggleDropDownMenu(1, nil, _G["CT_RAOptionsGroupButton"..self:GetID().."DropDown"]);
	end
end

function CT_RAOptions_Update()
	-- Reset group index counters;
	for i=1, NUM_RAID_GROUPS do
		_G["CT_RAOptionsGroup"..i].nextIndex = 1;
	end
	-- Clear out all the slots buttons
	CT_RAOptionsGroup_ResetSlotButtons();

	local numRaidMembers = GetNumRaidMembers();
	local raidGroup, color;
	local button;
	local buttonName, buttonLevel, buttonClass, buttonRank;
	local name, rank, subgroup, level, class, fileName, zone, online, isDead, reqChange;
	local temp = { };
	local REDr, REDg, REDb = RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b;
	local GRAYr, GRAYg, GRAYb = GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b;
	for i=1, MAX_RAID_MEMBERS do
		button = _G["CT_RAOptionsGroupButton"..i];
		if ( i <= numRaidMembers ) then
			name, rank, subgroup, level, class, fileName, zone, online, isDead = GetRaidRosterInfo(i);
			if ( not name or not CT_RA_CurrPositions[name] ) then
				if ( name ) then
					CT_RA_CurrPositions[name] = { subgroup };
				end
			end
			if ( name and CT_RA_CurrPositions[name] ) then
				CT_RA_CurrPositions[name][2] = i;
			end
			if ( subgroup ) then
				raidGroup = _G["CT_RAOptionsGroup"..subgroup];
				-- To prevent errors when the server hiccups
				if ( raidGroup.nextIndex <= MEMBERS_PER_RAID_GROUP ) then
					buttonName = _G["CT_RAOptionsGroupButton"..i.."Name"];
					buttonLevel = _G["CT_RAOptionsGroupButton"..i.."Level"];
					buttonClass = _G["CT_RAOptionsGroupButton"..i.."Class"];
					buttonRank = _G["CT_RAOptionsGroupButton"..i.."Rank"];
					button.id = i;

					button.name = name;

					if ( level == 0 ) then
						level = "";
					end

					if ( not name ) then
						name = UNKNOWN;
					end

					buttonName:SetText(name);
					buttonLevel:SetText(level);
					buttonClass:SetText(class);
					if ( isDead ) then
						buttonName:SetVertexColor(REDr, REDg, REDb);
						buttonClass:SetVertexColor(REDr, REDg, REDb);
						buttonLevel:SetVertexColor(REDr, REDg, REDb);
					elseif ( online ) then
						color = RAID_CLASS_COLORS[fileName];
						if ( color ) then
							local r, g, b = color.r, color.g, color.b;
							buttonName:SetVertexColor(r, g, b);
							buttonLevel:SetVertexColor(r, g, b);
							buttonClass:SetVertexColor(r, g, b);
						end
					else
						buttonName:SetVertexColor(GRAYr, GRAYg, GRAYb);
						buttonClass:SetVertexColor(GRAYr, GRAYg, GRAYb);
						buttonLevel:SetVertexColor(GRAYr, GRAYg, GRAYb);
					end

					buttonRank:SetText("");
					for k, v in pairs(CT_RA_MainTanks) do
						if ( v == name ) then
							buttonRank:SetText(k);
							break;
						end
					end

					-- Anchor button to slot
					local slot = raidGroup.nextIndex;
					if ( not CT_RA_MOVINGMEMBER or CT_RA_MOVINGMEMBER ~= button  ) then
						button:SetPoint("TOPLEFT", "CT_RAOptionsGroup"..subgroup.."Slot"..slot, "TOPLEFT", 0, 0);
					end

					-- Save slot for future use
					button.slot = "CT_RAOptionsGroup"..subgroup.."Slot"..slot;
					-- Save the button's subgroup too
					button.subgroup = subgroup;
					-- Tell the slot what button is in it
					_G["CT_RAOptionsGroup"..subgroup.."Slot"..slot].button = button:GetName();
					raidGroup.nextIndex = raidGroup.nextIndex + 1;
					button:SetID(i);
					button:Show();
				end
			end
		else
			button:Hide();
		end
	end
end

function CT_RAOptions_UpdateGroups()
	local numRaidMembers = GetNumRaidMembers();
	local subgroup, _, online, isDead, fileName;
	local RAID_CLASS_COLORS = RAID_CLASS_COLORS;
	local REDr, REDg, REDb = RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b;
	local GRAYr, GRAYg, GRAYb = GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b;
	for i = 1, MAX_RAID_MEMBERS do
		_, _, _, _, _, fileName, _, online, isDead = GetRaidRosterInfo(i);
		if ( isDead ) then
			_G["CT_RAOptionsGroupButton"..i.."Name"]:SetVertexColor(REDr, REDg, REDb);
			_G["CT_RAOptionsGroupButton"..i.."Class"]:SetVertexColor(REDr, REDg, REDb);
			_G["CT_RAOptionsGroupButton"..i.."Level"]:SetVertexColor(REDr, REDg, REDb);
		elseif ( online ) then
			local color = RAID_CLASS_COLORS[fileName];
			if ( color ) then
				local r, g, b = color.r, color.g, color.b;
				_G["CT_RAOptionsGroupButton"..i.."Name"]:SetVertexColor(r, g, b);
				_G["CT_RAOptionsGroupButton"..i.."Class"]:SetVertexColor(r, g, b);
				_G["CT_RAOptionsGroupButton"..i.."Level"]:SetVertexColor(r, g, b);
			end
		else
			_G["CT_RAOptionsGroupButton"..i.."Name"]:SetVertexColor(GRAYr, GRAYg, GRAYb);
			_G["CT_RAOptionsGroupButton"..i.."Class"]:SetVertexColor(GRAYr, GRAYg, GRAYb);
			_G["CT_RAOptionsGroupButton"..i.."Level"]:SetVertexColor(GRAYr, GRAYg, GRAYb);
		end
	end
end

function CT_RAOptions_UpdateMTs()
	local numRaidMembers = GetNumRaidMembers();
	local name, rank;
	local RAID_CLASS_COLORS = RAID_CLASS_COLORS;
	local REDr, REDg, REDb = RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b;
	local GRAYr, GRAYg, GRAYb = GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b;
	for i = 1, MAX_RAID_MEMBERS do
		name = GetRaidRosterInfo(i);
		rank = _G["CT_RAOptionsGroupButton"..i.."Rank"];
		rank:SetText("");

		for k, v in pairs(CT_RA_MainTanks) do
			if ( v == name ) then
				rank:SetText(k);
				break;
			end
		end
	end
end

function CT_RAOptionsGroup_ResetSlotButtons()
	for i=1, NUM_RAID_GROUPS do
		for j=1, MEMBERS_PER_RAID_GROUP do
			_G["CT_RAOptionsGroup"..i.."Slot"..j].button = nil;
		end
	end
end

function CT_RAOptionsGroupFrame_OnUpdate(self, elapsed)
	if ( CT_RA_MOVINGMEMBER ) then
		local button, slot;
		CT_RA_CURRSLOT = nil;
		for i=1, NUM_RAID_GROUPS do
			for j=1, MEMBERS_PER_RAID_GROUP do
				slot = _G["CT_RAOptionsGroup"..i.."Slot"..j];
				if ( slot:IsMouseOver() ) then
					slot:LockHighlight();
					CT_RA_CURRSLOT = slot;
				else
					slot:UnlockHighlight();
				end
			end
		end
	end
end

function CT_RAMemberDropDown_OnLoad(self)
	L_UIDropDownMenu_Initialize(self, CT_RAMemberDropDown_Initialize, "MENU");
end

function CT_RAMemberDropDown_Initialize(self)
	local info;
	if ( type(L_UIDROPDOWNMENU_MENU_VALUE) == "table" and L_UIDROPDOWNMENU_MENU_VALUE[1] == "Main Tanks" ) then
		info = {};
		info.text = "Main Tanks";
		info.isTitle = 1;
		L_UIDropDownMenu_AddButton(info, L_UIDROPDOWNMENU_MENU_LEVEL);
		local isMT;
		for key, value in pairs(CT_RA_MainTanks) do
			if ( value == L_UIDROPDOWNMENU_MENU_VALUE[2] ) then
				isMT = key;
				break;
			end
		end
		for i = 1, 10, 1 do
			info = {};
			if ( isMT == i ) then
				info.text = "|c00DFFFFFRemove MT " .. i;
				if (CT_RA_MainTanks[i]) then
					info.text = info.text .. "  (" .. CT_RA_MainTanks[i] .. ")";
				end
				info.text = info.text .. "|r";
				info.value = { L_UIDROPDOWNMENU_MENU_VALUE[1], L_UIDROPDOWNMENU_MENU_VALUE[2], i, isMT, 1 };
				info.tooltipTitle = "Remove Main Tank"
				info.tooltipText = "Removes the Main Tank from the MT window.";
			else
				info.text = "Set MT " .. i;
				if (CT_RA_MainTanks[i]) then
					info.text = info.text .. "  (" .. CT_RA_MainTanks[i] .. ")";
				end
				info.value = { L_UIDROPDOWNMENU_MENU_VALUE[1], L_UIDROPDOWNMENU_MENU_VALUE[2], i, isMT };
				info.tooltipTitle = "Set Main Tank"
				info.tooltipText = "Sets a main tank, which allows everyone to see the main tank(s) target info";
			end
			info.func = CT_RAMemberDropDown_OnClick;
			L_UIDropDownMenu_AddButton(info, L_UIDROPDOWNMENU_MENU_LEVEL);
		end
		return;
	end
	if ( type(L_UIDROPDOWNMENU_MENU_VALUE) == "table" and L_UIDROPDOWNMENU_MENU_VALUE[1] == "Player Targets" ) then
		info = {};
		info.text = "Player Targets";
		info.isTitle = 1;
		info.notCheckable = 1;
		L_UIDropDownMenu_AddButton(info, L_UIDROPDOWNMENU_MENU_LEVEL);
		local isPT;
		if ( CT_RA_PTargets ) then
			for key, value in pairs(CT_RA_PTargets) do
				if ( value == L_UIDROPDOWNMENU_MENU_VALUE[2] ) then
					isPT = key;
					break;
				end
			end
		end
		info = {};
		if ( isPT ) then
			info.text = "|c00DFFFFFRemove PT|r";
			info.value = { L_UIDROPDOWNMENU_MENU_VALUE[1], L_UIDROPDOWNMENU_MENU_VALUE[2], isPT, 1 };
			info.tooltipTitle = "Remove Player Target"
			info.tooltipText = "Removes the Player Target from the PT window.";
		else
			info.text = "Set PT"
			info.value = { L_UIDROPDOWNMENU_MENU_VALUE[1], L_UIDROPDOWNMENU_MENU_VALUE[2], isPT };
			info.tooltipTitle = "Set Player Target"
			info.tooltipText = "Sets a player target, which allows you to easily see the person's health and target.";
		end
		info.func = CT_RAMemberDropDown_OnClick;
		L_UIDropDownMenu_AddButton(info, L_UIDROPDOWNMENU_MENU_LEVEL);
		return;
	end
	info = {};
	info.text = self:GetParent().name;
	info.isTitle = 1;
	info.notCheckable = 1;
	L_UIDropDownMenu_AddButton(info);
	if ( CT_RA_Level < 1 ) then
		info = { };
		info.text = "|c00666666Main Tanks|r";
		info.tooltipTitle = "Promotion Required";
		info.tooltipText = "In order to set main tanks, you need to at least be a promoted user, or raid leader.";
		info.notCheckable = 1;
		L_UIDropDownMenu_AddButton(info);
	else
		info = {};
		info.text = "Main Tanks";
		info.value = { "Main Tanks", self:GetParent().name };
		info.hasArrow = 1;
		info.notCheckable = 1;
		L_UIDropDownMenu_AddButton(info);
	end
	info = {};
	info.text = "Player Targets";
	info.value = { "Player Targets", self:GetParent().name };
	info.hasArrow = 1;
	info.notCheckable = 1;
	L_UIDropDownMenu_AddButton(info);

	info = { };
	info.text = "Auto-Promote";
	info.tooltipTitle = "Auto-Promote";
	info.tooltipText = "When checked, this player is automatically promoted when he or she joins the raid.";
	info.checked = CT_RATab_AutoPromotions[self:GetParent().name];
	info.value = self:GetParent().id;
	info.func = CT_RATab_AutoPromote_OnClick;
	L_UIDropDownMenu_AddButton(info);
end

function CT_RAMemberDropDown_OnClick(self)
	if ( self.value[1] == "Main Tanks" ) then
		if ( self.value[5] ) then
			CT_RA_SendMessage("R " .. self.value[2]);
		else
			CT_RA_SendMessage("SET " .. self.value[3] .. " " .. self.value[2]);
		end
	elseif ( self.value[1] == "Player Targets" ) then
		if ( self.value[4] ) then
			tremove(CT_RA_PTargets, self.value[3]);
		else
			tinsert(CT_RA_PTargets, self.value[2]);
		end
		CT_RA_UpdatePTs(true);
	end
	CT_RA_UpdateRaidFrameData();
	CloseMenus();
end

-- These functions, CT_RAMemberDropDownRemove*, are not being used anywhere.
--[[
function CT_RAMemberDropDownRemove_OnLoad(self)
	L_UIDropDownMenu_Initialize(self, CT_RAMemberDropDownRemove_Initialize, "MENU");
end

function CT_RAMemberDropDownRemove_Initialize(self)
	local info;
	if ( self.id and self.name ) then
		info = {};
		info.text = self:GetParent().name;
		info.isTitle = 1;
		info.notCheckable = 1;
		L_UIDropDownMenu_AddButton(info);

		info = {};
		info.text = "Remove MT";
		info.value = self:GetParent().name;
		info.func = CT_RAMemberDropDownRemove_OnClick;
		info.notCheckable = 1;
		info.tooltipTitle = "Remove Main Tank"
		info.tooltipText = "Removes the main tank";
		L_UIDropDownMenu_AddButton(info);
	end
end

function CT_RAMemberDropDownRemove_OnClick(self)
	for k, v in pairs(CT_RA_MainTanks) do
		if ( v == self.value ) then
			CT_RA_SendMessage("R " .. v);
			return;
		end
	end
end
]]

function CT_RAOptions2Frame_OnShow(self)
	local tempOptions = CT_RAMenu_Options["temp"];
	local label;
	for i = 1, NUM_RAID_GROUPS do
		label = _G["CT_RAOptions2GroupCB" .. i .. "Label"];
		label:SetText("Group " .. i);
	end
	-- Arrange the checkboxes so the classes appear to be in alphabetical order (from left to right).
	local classes = {};
	for k, v in pairs(CT_RA_ClassPositions) do
		tinsert(classes, k);
	end
	sort(classes, function (a, b)
			if (string.lower(a) < string.lower(b)) then
				return true;
			else
				return false;
			end
	end);
	local cb;
	for i = 1, CT_RA_MaxGroups do
		cb = _G["CT_RAOptions2ClassCB" .. i];
		cb:ClearAllPoints();
	end
	local cb2, pos;
	local c = 1;
	local across = 2;
	for i = 1, CT_RA_MaxGroups do
		pos = CT_RA_ClassPositions[(classes[i])];
		_G["CT_RAOptions2ClassCB" .. pos .. "Label"]:SetText(classes[i]);
		cb = _G["CT_RAOptions2ClassCB" .. pos];
		if (i == 1) then
			cb:SetPoint("TOPLEFT", self, "TOPLEFT", 22, -220);
		elseif (c == 1) then
			pos = CT_RA_ClassPositions[(classes[i - across])];
			cb2 = _G["CT_RAOptions2ClassCB" .. pos];
			cb:SetPoint("TOPLEFT", cb2, "BOTTOMLEFT", 0, -3);
		else
			cb:SetPoint("LEFT", cb2, "RIGHT", 135, 0);
		end
		cb2 = cb;
		c = c + 1;
		if (c > across) then
			c = 1;
		end
	end
	CT_RASortWindowPositions:SetChecked(tempOptions["SortWindowPositions"]);
end

function CT_RA_SortWindowPositions(different)
	local tempOptions = CT_RAMenu_Options["temp"];
	tempOptions["SortWindowPositions"] = different;
	CT_RAMenu_UpdateOptionSets();
end

function CT_RA_GroupCB_OnClick(self)
	-- User clicked on a group checkbox
	CT_RA_SetGroup(self.id, self:GetChecked());
	CT_RA_UpdateGroupOptions();
	CT_RA_UpdateRaidGroup(0);
	CT_RA_UpdateRaidFrames();
	CT_RAMenu_UpdateOptionSets();
end

function CT_RA_ClassCB_OnClick(self)
	-- User clicked on a class checkbox
	CT_RA_SetClass(self.id, self:GetChecked());
	CT_RA_UpdateGroupOptions();
	CT_RA_UpdateRaidGroup(0);
	CT_RA_UpdateRaidFrames();
	CT_RAMenu_UpdateOptionSets();
end

