local UnitName = CT_RA_UnitName;
local GetNumRaidMembers = CT_RA_GetNumRaidMembers;

-- Refer to RAID_CLASS_COLORS[] in FontStyles.xml for Blizzard's r,g,b values of these colors:
CT_RAMeters_ColorTable = {
	[CT_RA_CLASS_HUNTER] = "|c" .. RAID_CLASS_COLORS[CT_RA_CLASS_HUNTER_EN].colorStr,
	[CT_RA_CLASS_WARLOCK] = "|c" .. RAID_CLASS_COLORS[CT_RA_CLASS_WARLOCK_EN].colorStr,
	[CT_RA_CLASS_PRIEST] = "|c" .. RAID_CLASS_COLORS[CT_RA_CLASS_PRIEST_EN].colorStr,
	[CT_RA_CLASS_PALADIN] = "|c" .. RAID_CLASS_COLORS[CT_RA_CLASS_PALADIN_EN].colorStr,
	[CT_RA_CLASS_MAGE] = "|c" .. RAID_CLASS_COLORS[CT_RA_CLASS_MAGE_EN].colorStr,
	[CT_RA_CLASS_ROGUE] = "|c" .. RAID_CLASS_COLORS[CT_RA_CLASS_ROGUE_EN].colorStr,
	[CT_RA_CLASS_DRUID] = "|c" .. RAID_CLASS_COLORS[CT_RA_CLASS_DRUID_EN].colorStr,
	[CT_RA_CLASS_SHAMAN] = "|c" .. RAID_CLASS_COLORS[CT_RA_CLASS_SHAMAN_EN].colorStr,
	[CT_RA_CLASS_WARRIOR] = "|c" .. RAID_CLASS_COLORS[CT_RA_CLASS_WARRIOR_EN].colorStr,
	[CT_RA_CLASS_DEATHKNIGHT] = "|c" .. RAID_CLASS_COLORS[CT_RA_CLASS_DEATHKNIGHT_EN].colorStr,
	[CT_RA_CLASS_MONK] = "|c" .. RAID_CLASS_COLORS[CT_RA_CLASS_MONK_EN].colorStr,
};

function CT_RAMeters_GetMeterOptions()
	if (not CT_RAMenu_Options["temp"]["StatusMeters"]) then
		CT_RAMenu_Options["temp"]["StatusMeters"] = {
			["Health Display"] = { },
			["Mana Display"] = { },
			["Raid Health"] = { },
			["Raid Mana"] = { },
			["Background"] = {
				["r"] = 0,
				["g"] = 0,
				["b"] = 1,
				["a"] = 0.5,
			},
		};
	end
	return CT_RAMenu_Options["temp"]["StatusMeters"];
end

function CT_RAMeters_InitDropDown()
	local meterOptions = CT_RAMeters_GetMeterOptions();
	local info;
	if ( L_UIDROPDOWNMENU_MENU_LEVEL == 2 ) then
		info = {};
		info.text = L_UIDROPDOWNMENU_MENU_VALUE;
		info.justifyH = "CENTER";
		info.isTitle = 1;
		info.notCheckable = 1;
		L_UIDropDownMenu_AddButton(info, L_UIDROPDOWNMENU_MENU_LEVEL);

		local nonManaUsers = {
			[CT_RA_CLASS_ROGUE] = 1,
			[CT_RA_CLASS_WARRIOR] = 1,
			[CT_RA_CLASS_DEATHKNIGHT] = 1,
		};
		for j, k in ipairs(CT_RA_ClassSorted) do
			-- local v = CT_RA_ClassPositions[k];
			local value;
			if ( L_UIDROPDOWNMENU_MENU_VALUE == "Class Health" ) then
				value = "Health Display";
			elseif ( L_UIDROPDOWNMENU_MENU_VALUE == "Class Mana" ) then
				value = "Mana Display";
			else
				-- "Raid Health" or "Raid Mana"
				value = L_UIDROPDOWNMENU_MENU_VALUE;
			end
			if ( ( value == "Health Display" or value == "Raid Health" ) or not nonManaUsers[k] ) then
				info = { };
				info.text = k;
				info.value = { value, k };
				info.checked = ( meterOptions and meterOptions[value] and meterOptions[value][k] );
				info.keepShownOnClick = 1;
				info.func = CT_RAMeters_DropDown_OnClick;
				L_UIDropDownMenu_AddButton(info, L_UIDROPDOWNMENU_MENU_LEVEL);
			end
		end
		return;
	end

	info = {};
	info.text = "RaidStatus";
	info.justifyH = "CENTER";
	info.isTitle = 1;
	info.notCheckable = 1;
	L_UIDropDownMenu_AddButton(info);

	info = {};
	info.text = "Class Health";
	info.hasArrow = 1;
	info.notCheckable = 1;
	L_UIDropDownMenu_AddButton(info);

	info = {};
	info.text = "Class Mana";
	info.hasArrow = 1;
	info.notCheckable = 1;
	L_UIDropDownMenu_AddButton(info);

	info = {};
	info.text = "Raid Health";
	info.hasArrow = 1;
	info.notCheckable = 1;
	L_UIDropDownMenu_AddButton(info);

	info = {};
	info.text = "Raid Mana";
	info.hasArrow = 1;
	info.notCheckable = 1;
	L_UIDropDownMenu_AddButton(info);

--	info = {};
--	info.disabled = 1;
--	L_UIDropDownMenu_AddButton(info);

	info = {};
	info.text = "AFK";
	info.value = "AFK Count";
	info.checked = ( meterOptions and meterOptions["AFK Count"] );
	info.keepShownOnClick = 1;
	info.func = CT_RAMeters_DropDown_OnClick;
	L_UIDropDownMenu_AddButton(info);

	info = {};
	info.text = "Dead";
	info.value = "Dead Count";
	info.checked = ( meterOptions and meterOptions["Dead Count"] );
	info.keepShownOnClick = 1;
	info.func = CT_RAMeters_DropDown_OnClick;
	L_UIDropDownMenu_AddButton(info);

	info = {};
	info.text = "Not In Zone";
	info.value = "notInZone";
	info.checked = ( meterOptions and meterOptions["notInZone"] );
	info.keepShownOnClick = 1;
	info.func = CT_RAMeters_DropDown_OnClick;
	L_UIDropDownMenu_AddButton(info);

	info = {};
	info.text = "Offline";
	info.value = "Offline Count";
	info.checked = ( meterOptions and meterOptions["Offline Count"] );
	info.keepShownOnClick = 1;
	info.func = CT_RAMeters_DropDown_OnClick;
	L_UIDropDownMenu_AddButton(info);

	info = {};
	info.text = "PVP";
	info.value = "PVP Count";
	info.checked = ( meterOptions and meterOptions["PVP Count"] );
	info.keepShownOnClick = 1;
	info.func = CT_RAMeters_DropDown_OnClick;
	L_UIDropDownMenu_AddButton(info);

	info = {};
	info.text = "Total";
	info.value = "Total Count";
	info.checked = ( meterOptions and meterOptions["Total Count"] );
	info.keepShownOnClick = 1;
	info.func = CT_RAMeters_DropDown_OnClick;
	L_UIDropDownMenu_AddButton(info);

	info = {};
	info.text = "Hide count if zero";
	info.value = "HideZero";
	info.checked = ( meterOptions and meterOptions["HideZero"] );
	info.keepShownOnClick = 1;
	info.func = CT_RAMeters_DropDown_OnClick;
	L_UIDropDownMenu_AddButton(info);

--	info = {};
--	info.disabled = 1;
--	L_UIDropDownMenu_AddButton(info);

	info = {};
	if ( meterOptions and meterOptions["Lock"] ) then
		info.text = "Unlock Window";
	else
		info.text = "Lock window";
	end
	info.value = "LockMeter";
	info.notCheckable = 1;
	info.func = CT_RAMeters_DropDown_OnClick;
	L_UIDropDownMenu_AddButton(info);

	info = { };
	info.text = "Background color";
	info.hasColorSwatch = 1;
	info.hasOpacity = 1;
	if ( meterOptions and meterOptions["Background"] ) then
		info.r = ( meterOptions["Background"].r );
		info.g = ( meterOptions["Background"].g );
		info.b = ( meterOptions["Background"].b );
		info.opacity = ( meterOptions["Background"].a );
	else
		info.r = 0;
		info.g = 0;
		info.b = 1;
		info.opacity = 0.5;
	end
	info.notClickable = 1;
	info.swatchFunc = CT_RAMeters_DropDown_SwatchFunc;
	info.opacityFunc = CT_RAMeters_DropDown_OpacityFunc;
	info.cancelFunc = CT_RAMeters_DropDown_CancelFunc;
	info.notCheckable = 1;
	L_UIDropDownMenu_AddButton(info);

	info = {};
	info.text = "Hide window";  -- |c00FF8080 |r
	info.value = "Hide";
	info.notCheckable = 1;
	info.func = CT_RAMeters_DropDown_OnClick;
	L_UIDropDownMenu_AddButton(info);

	info = {};
	info.text = "Close this menu";
	info.value = "CloseMenu";
	info.notCheckable = 1;
	info.func = CT_RAMeters_DropDown_OnClick;
	L_UIDropDownMenu_AddButton(info);
end

function CT_RAMeters_DropDown_SwatchFunc()
	local meterOptions = CT_RAMeters_GetMeterOptions();
	local r, g, b = ColorPickerFrame:GetColorRGB();
	meterOptions["Background"]["r"] = r;
	meterOptions["Background"]["g"] = g;
	meterOptions["Background"]["b"] = b;
	CT_RAMetersFrame:SetBackdropColor(r, g, b, meterOptions["Background"]["a"]);
end

function CT_RAMeters_DropDown_OpacityFunc()
	local meterOptions = CT_RAMeters_GetMeterOptions();
	local a = OpacitySliderFrame:GetValue();
	meterOptions["Background"]["a"] = a;
	CT_RAMetersFrame:SetBackdropColor(meterOptions["Background"].r, meterOptions["Background"].g, meterOptions["Background"].b, a);
	CT_RAMetersFrame:SetBackdropBorderColor(1, 1, 1, a);
end

function CT_RAMeters_DropDown_CancelFunc(val)
	local meterOptions = CT_RAMeters_GetMeterOptions();
	meterOptions["Background"] = {
		["r"] = val.r,
		["g"] = val.g,
		["b"] = val.b,
		["a"] = val.opacity
	};
	CT_RAMetersFrame:SetBackdropColor(val.r, val.g, val.b, val.opacity);
	CT_RAMetersFrame:SetBackdropBorderColor(1, 1, 1, val.opacity);
end

function CT_RAMeters_OnLoad(self)
	self:SetBackdropColor(0, 0, 1, 0.5);
end

function CT_RAMeters_DropDown_OnLoad(self)
	L_UIDropDownMenu_Initialize(self, CT_RAMeters_InitDropDown, "MENU");
end

function CT_RAMeters_DropDown_OnClick(self)
	local meterOptions = CT_RAMeters_GetMeterOptions();

	if ( self.value == "LockMeter" ) then
		meterOptions["Lock"] = not meterOptions["Lock"];
		return;
	elseif ( self.value == "HideZero" ) then
		meterOptions["HideZero"] = not meterOptions["HideZero"];
		CT_RAMeters_UpdateWindow();
		return;
	elseif ( self.value == "Hide" ) then
		CT_RAMenuFrameGeneralMiscShowMetersCB:SetChecked(false);
		meterOptions["Show"] = nil;
		CT_RAMetersFrame:Hide();
		return;
	elseif ( self.value == "CloseMenu" ) then
		CloseDropDownMenus();
		return;
	end

	if ( type(self.value) == "table" ) then
		-- We have either HP or Mana Display/Totals
		meterOptions[self.value[1]][self.value[2]] = not meterOptions[self.value[1]][self.value[2]];
	else
		-- Just AFK Count/Dead Count/PVP Count/Not In Zone/Total Count
		meterOptions[self.value] = not meterOptions[self.value];
	end
	CT_RAMeters_UpdateWindow();
end

function CT_RAMeters_GetTables()
	-- Create tables if they don't exist. Return references to the tables.

	if (not CT_RAMeters_StatsTable) then
		CT_RAMeters_StatsTable = {
			["Generic"] = {
				["isDead"] = 0,
				["isAfk"] = 0,
				["notInZone"] = 0,
				["isOffline"] = 0,
				["isPVP"] = 0,
				["total"] = 0,
			},
			[CT_RA_CLASS_WARRIOR] = { ["health"] = 0, ["mana"] = 0, ["num"] = 0 },
			[CT_RA_CLASS_DRUID] = { ["health"] = 0, ["mana"] = 0, ["num"] = 0, ["numMana"] = 0 },
			[CT_RA_CLASS_MAGE] = { ["health"] = 0, ["mana"] = 0, ["num"] = 0, ["numMana"] = 0 },
			[CT_RA_CLASS_WARLOCK] = { ["health"] = 0, ["mana"] = 0, ["num"] = 0, ["numMana"] = 0 },
			[CT_RA_CLASS_ROGUE] = { ["health"] = 0, ["mana"] = 0, ["num"] = 0 },
			[CT_RA_CLASS_HUNTER] = { ["health"] = 0, ["mana"] = 0, ["num"] = 0, ["numMana"] = 0 },
			[CT_RA_CLASS_PRIEST] = { ["health"] = 0, ["mana"] = 0, ["num"] = 0, ["numMana"] = 0 },
			[CT_RA_CLASS_PALADIN] = { ["health"] = 0, ["mana"] = 0, ["num"] = 0, ["numMana"] = 0 },
			[CT_RA_CLASS_SHAMAN] = { ["health"] = 0, ["mana"] = 0, ["num"] = 0, ["numMana"] = 0 },
			[CT_RA_CLASS_DEATHKNIGHT] = { ["health"] = 0, ["mana"] = 0, ["num"] = 0, ["numMana"] = 0 },
			[CT_RA_CLASS_MONK] = { ["health"] = 0, ["mana"] = 0, ["num"] = 0, ["numMana"] = 0 },
		};
	end

	if (not CT_RAMeters_ResultsTable) then
		CT_RAMeters_ResultsTable = {
			["hpDisplay"] = { "", 0 },
			["mpDisplay"] = { "", 0 },
			["raidHp"] = { "", 1 },
			["raidMp"] = { "", 1 },
			["afkCount"] = { "", 1 },
			["deadCount"] = { "", 1 },
			["notInZone"] = { "", 1 },
			["offlineCount"] = { "", 1 },
			["pvpCount"] = { "", 1 },
			["totalCount"] = { "", 1 },
		};
	end

	if (not CT_RAMeters_OrderTable) then
		CT_RAMeters_OrderTable = {
			{ "raidHp", "|c00FF2222", "|r" },
			{ "raidMp", "|c006666FF", "|r" },
			{ "hpDisplay", "", "" },
			{ "mpDisplay", "", "" },
			{ "afkCount", "|c00CCCCCC", "|r" },
			{ "deadCount", "|c00666666", "|r" },
			{ "offlineCount", "|c00999999", "|r" },
			{ "notInZone", "|c00FF5533", "|r" },
			{ "pvpCount", "|c00FFD468", "|r" },
			{ "totalCount", "|c00DDDDDD", "|r" },
		};
	end

	return CT_RAMeters_StatsTable, CT_RAMeters_ResultsTable, CT_RAMeters_OrderTable;
end

function CT_RAMeters_ResetTables()
	-- Reset the contents of the tables.
	for k, v in pairs(CT_RAMeters_StatsTable) do
		for k2, v2 in pairs(v) do
			v[k2] = 0;
		end
	end
	for k, v in pairs(CT_RAMeters_ResultsTable) do
		v[1] = "";  -- Text to display in raid status window
		v[2] = 1; -- Number of lines in raid status window for this item
	end
end

function CT_RAMeters_UpdateWindow()
	local meterOptions = CT_RAMeters_GetMeterOptions();
	local playerZone = GetRealZoneText("player");

	if ( not meterOptions or GetNumRaidMembers() == 0 ) then
		CT_RAMetersFrameText:SetText("No stats to track");
		CT_RAMetersFrame:SetWidth(125);
		CT_RAMetersFrame:SetHeight(41);
		return;
	end

	local statsTable, resultsTable, orderTable = CT_RAMeters_GetTables();
	CT_RAMeters_ResetTables();

	-- Get all the stats
	for i = 1, GetNumRaidMembers(), 1 do
		local id = "raid" .. i;
		if ( UnitIsConnected(id) or 1 ) then
			local name = UnitName(id);
			local class = UnitClass(id);
			local health = 0;
			local mana = 0;
			local isDead = (
				( UnitIsDead(id) or UnitIsGhost(id) ) and
				( not CT_RA_Stats[name] or not CT_RA_Stats[name]["FD"] )
			);
			local isAfk = ( CT_RA_Stats[name] and CT_RA_Stats[name]["AFK"] );
			if ( class and statsTable[class] ) then
				if (
					( meterOptions["Raid Health"] and meterOptions["Raid Health"][class] ) or
					( meterOptions["Health Display"] and meterOptions["Health Display"][class] )
				) then
					if (UnitHealthMax(id) == 0) then
						health = 0;
					else
						health = UnitHealth(id) / UnitHealthMax(id);
					end
				end
				if (
					UnitPowerType(id) == 0 and
					(
						( meterOptions["Raid Mana"] and meterOptions["Raid Mana"][class] ) or
						( meterOptions["Mana Display"] and meterOptions["Mana Display"][class] )
					)
				) then
					statsTable[class]["numMana"] = statsTable[class]["numMana"] + 1;
					if (UnitPowerMax(id) == 0) then
						mana = 0;
					else
						mana = UnitPower(id) / UnitPowerMax(id);
					end
				end
				statsTable[class]["health"] = statsTable[class]["health"] + health;
				statsTable[class]["mana"] = statsTable[class]["mana"] + mana;
				if ( isDead ) then
					statsTable["Generic"]["isDead"] = statsTable["Generic"]["isDead"] + 1;
				end
				if ( isAfk ) then
					statsTable["Generic"]["isAfk"] = statsTable["Generic"]["isAfk"] + 1;
				end
				statsTable[class]["num"] = statsTable[class]["num"] + 1;
			end
			if (UnitIsPVP(id) or UnitIsPVPFreeForAll(id)) then
				statsTable["Generic"]["isPVP"] = statsTable["Generic"]["isPVP"] + 1;
			end
			if (meterOptions["Not in zone"]) then
				local _, _, _, _, _, _, zone = GetRaidRosterInfo(i);
				if (zone and zone ~= playerZone) then
					statsTable["Generic"]["notInZone"] = statsTable["Generic"]["notInZone"] + 1;
				end
			end
		else
			statsTable["Generic"]["isOffline"] = statsTable["Generic"]["isOffline"] + 1;
		end
	end
	statsTable["Generic"]["total"] = GetNumRaidMembers();

	-- Raid Health
	if ( meterOptions["Raid Health"] ) then
		local combinedHealth, numHealth = 0, 0;
		for k, v in pairs(meterOptions["Raid Health"]) do
			if ( v and statsTable[k] and statsTable[k]["num"] > 0 ) then
				combinedHealth = combinedHealth + statsTable[k]["health"];
				numHealth = numHealth + statsTable[k]["num"];
			end
		end
		if ( numHealth > 0 ) then
			local percent;
			if (numHealth == 0) then
				percent = 0;
			else
				percent = combinedHealth / numHealth;
			end
			combinedHealth = floor(percent * 100 + 0.5);
			resultsTable["raidHp"][1] = "Raid Health: " .. combinedHealth .. "%";
		end
	end

	-- Raid Mana
	if ( meterOptions["Raid Mana"] ) then
		local combinedMana, numMana = 0, 0;
		for k, v in pairs(meterOptions["Raid Mana"]) do
			if ( v and statsTable[k] and statsTable[k]["numMana"] > 0 ) then
				combinedMana = combinedMana + statsTable[k]["mana"];
				numMana = numMana + statsTable[k]["numMana"];
			end
		end
		if ( numMana > 0 ) then
			local percent;
			if (numMana == 0) then
				percent = 0;
			else
				percent = combinedMana / numMana;
			end
			combinedMana = floor(percent * 100 + 0.5);
			resultsTable["raidMp"][1] = "Raid Mana: " .. combinedMana .. "%";
		end
	end

	local minToShow = 0;
	if ( meterOptions["HideZero"] ) then
		minToShow = 1;
	end

	-- AFK Count
	if ( meterOptions["AFK Count"] and statsTable["Generic"]["isAfk"] >= minToShow) then
		resultsTable["afkCount"][1] = "AFK: " .. statsTable["Generic"]["isAfk"];
	end

	-- Dead Count
	if ( meterOptions["Dead Count"] and statsTable["Generic"]["isDead"] >= minToShow) then
		resultsTable["deadCount"][1] = "Dead: " .. statsTable["Generic"]["isDead"];
	end

	-- Offline Count
	if ( meterOptions["Offline Count"] and statsTable["Generic"]["isOffline"] >= minToShow) then
		resultsTable["offlineCount"][1] = "Offline: " .. statsTable["Generic"]["isOffline"];
	end

	-- PVP Count
	if ( meterOptions["PVP Count"] and statsTable["Generic"]["isPVP"] >= minToShow) then
		resultsTable["pvpCount"][1] = "PVP: " .. statsTable["Generic"]["isPVP"];
	end

	-- Not in zone
	if ( meterOptions["notInZone"] and statsTable["Generic"]["notInZone"] >= minToShow) then
		resultsTable["notInZone"][1] = "Not In Zone: " .. statsTable["Generic"]["notInZone"];
	end

	-- Total Count
	if ( meterOptions["Total Count"] and statsTable["Generic"]["total"] >= minToShow) then
		resultsTable["totalCount"][1] = "Total: " .. statsTable["Generic"]["total"];
	end

	-- Health Display
	resultsTable["hpDisplay"][2] = 0;
	if ( meterOptions["Health Display"] ) then
		local v;
		for i, k in ipairs(CT_RA_ClassSorted) do
			v = meterOptions["Health Display"][k];
			if ( v and statsTable[k] and statsTable[k]["num"] > 0 ) then
				if ( strlen(resultsTable["hpDisplay"][1]) > 0 ) then
					resultsTable["hpDisplay"][1] = resultsTable["hpDisplay"][1] .. "\n";
				end
				local percent;
				if (statsTable[k]["num"] == 0) then
					percent = 0;
				else
					percent = floor(statsTable[k]["health"] / statsTable[k]["num"] * 100 + 0.5);
				end
				resultsTable["hpDisplay"][1] = resultsTable["hpDisplay"][1] .. CT_RAMeters_ColorTable[k] .. k .. " Health: " .. percent .. "%|r";
				resultsTable["hpDisplay"][2] = resultsTable["hpDisplay"][2] + 1;
			end
		end
	end

	-- Mana Display
	resultsTable["mpDisplay"][2] = 0;
	if ( meterOptions["Mana Display"]) then
		local v;
		for i, k in ipairs(CT_RA_ClassSorted) do
			v = meterOptions["Mana Display"][k];
			if ( v and statsTable[k] and statsTable[k]["numMana"] > 0 ) then
				if ( strlen(resultsTable["mpDisplay"][1]) > 0 ) then
					resultsTable["mpDisplay"][1] = resultsTable["mpDisplay"][1] .. "\n";
				end
				local percent;
				if (statsTable[k]["numMana"] == 0) then
					percent = 0;
				else
					percent = floor(statsTable[k]["mana"] / statsTable[k]["numMana"] * 100 + 0.5);
				end
				resultsTable["mpDisplay"][1] = resultsTable["mpDisplay"][1] .. CT_RAMeters_ColorTable[k] .. k .. " Mana: " .. percent .. "%|r";
				resultsTable["mpDisplay"][2] = resultsTable["mpDisplay"][2] + 1;
			end
		end
	end

	-- Add together all the stats
	local out, numLines = "", 0;
	for i = 1, #orderTable, 1 do
		local val = resultsTable[ (orderTable[i][1]) ];
		if ( strlen(val[1]) > 0 ) then
			if ( strlen(out) > 0 ) then
				out = out .. "\n";
			end
			out = out .. orderTable[i][2] .. val[1] .. orderTable[i][3];
			numLines = numLines + val[2];
		end
	end
	if ( out == "" ) then
		numLines = 1;
		CT_RAMetersFrameText:SetText("No stats to track");
	else
		CT_RAMetersFrameText:SetText(out);
	end
	local width = CT_RAMetersFrameText:GetStringWidth();
	if ( width < 109 ) then
		width = 109;
	end
	CT_RAMetersFrame:SetWidth(width + 16);
	CT_RAMetersFrame:SetHeight(25 + (numLines * 14) + 4);
end

function CT_RAMeters_OnUpdate(self, elapsed)
	self.update = self.update - elapsed;
	if ( self.update <= 0 ) then
		self.update = 2;
		CT_RAMeters_UpdateWindow();
	end
end

local metersDropDownInitialized;
function CT_RAMeters_OnMouseDown(self, button)
	if ( button == "LeftButton" and ( not CT_RAMenu_Options["temp"]["StatusMeters"] or not CT_RAMenu_Options["temp"]["StatusMeters"]["Lock"] ) ) then
		self:StartMoving();
	elseif ( button == "RightButton" ) then
		if (not metersDropDownInitialized) then
			CT_RAMeters_DropDown_OnLoad(CT_RAMetersFrameDropDown);
			metersDropDownInitialized = true;
		end
		ToggleDropDownMenu(1, nil, _G[self:GetName() .. "DropDown"], self:GetName(), 47, 15);
	end
end
