local UnitName = CT_RA_UnitName;

-- Debuffs
CT_RA_DEBUFF_WEAKENED_SOUL = (GetSpellInfo(6788)) or "Weakened Soul";
CT_RA_DEBUFF_RECENTLY_BANDAGED = (GetSpellInfo(11196)) or "Recently Bandaged";
CT_RA_DEBUFF_MIND_VISION = (GetSpellInfo(2096)) or "Mind Vision";

-- Special buffs
CT_RA_BUFF_POWER_WORD_SHIELD = (GetSpellInfo(17)) or "Power Word: Shield";
CT_RA_BUFF_SOULSTONE_RESURRECTION = (GetSpellInfo(20707)) or "Soulstone";  -- (buff lasts 15 minutes)

-- Cures
CT_RA_CURE_REMOVE_CORRUPTION = (GetSpellInfo(2782)) or "Remove Corruption";  -- Druid
CT_RA_CURE_NATURES_CURE = (GetSpellInfo(88423)) or "Nature's Cure";  -- Druid
CT_RA_CURE_REMOVE_CURSE = (GetSpellInfo(475)) or "Remove Curse";  -- Mage
CT_RA_CURE_CLEANSE = (GetSpellInfo(4987)) or "Cleanse";  -- Paladin
CT_RA_CURE_SACRED_CLEANSING = (GetSpellInfo(53551)) or "Sacred Cleansing";  -- Paladin
CT_RA_CURE_PURIFY = (GetSpellInfo(527)) or "Purify"; -- Priest
CT_RA_CURE_CLEANSE_SPIRIT = (GetSpellInfo(51886)) or "Cleanse Spirit"; -- Shaman
CT_RA_CURE_PURIFY_SPIRIT = (GetSpellInfo(77130)) or "Purify Spirit"; -- Shaman
CT_RA_CURE_DETOX = (GetSpellInfo(115450)) or "Detox";  -- Monk
CT_RA_CURE_INTERNAL_MEDICINE = (GetSpellInfo(115451)) or "Detox";  -- Monk
CT_RA_CURE_REVIVAL = (GetSpellInfo(115310)) or "Revival";  -- Monk

-- Spells used to bring anyone back to life (not self-only spells).
CT_RA_REZ_RESURRECTION = (GetSpellInfo(2006)) or "Resurrection"; -- Priest (non-combat)
CT_RA_REZ_REDEMPTION = (GetSpellInfo(7328)) or "Redemption"; -- Paladin (non-combat)
CT_RA_REZ_REBIRTH = (GetSpellInfo(20484)) or "Rebirth"; -- Druid (10 minute cooldown)
CT_RA_REZ_ANCESTRAL_SPIRIT = (GetSpellInfo(2008)) or "Ancestral Spirit"; -- Shaman (non-combat)
CT_RA_REZ_REVIVE = (GetSpellInfo(50769)) or "Revive"; -- Druid (non-combat)
CT_RA_REZ_RAISE_ALLY = (GetSpellInfo(61999)) or "Raise Ally";  -- Deathknight (10 min cooldown)
CT_RA_REZ_RESUSCITATE = (GetSpellInfo(115178)) or "Resuscitate";  -- Monk (non-combat)

-- Feign Death
local name, rank, icon = GetSpellInfo(5384);
CT_RA_BUFF_FEIGN_DEATH = name or "Feign Death";
CT_RA_ICON_FEIGN_DEATH = icon or "Interface\\Icons\\Ability_Rogue_FeignDeath";
CT_RA_ICON_FEIGN_DEATH = gsub(CT_RA_ICON_FEIGN_DEATH, "^Interface\\Icons\\(.+)$", "%1");

-- Hunter's Mark
CT_RA_DEBUFF_HUNTERS_MARK = (GetSpellInfo(1130)) or "Hunter's Mark";

-- Spells used to check range.
CT_RA_RANGE_DRUID = (GetSpellInfo(5185)) or "Healing Touch";  -- 40 yards
CT_RA_RANGE_PRIEST = (GetSpellInfo(2061)) or "Flash Heal";  -- 40 yards
CT_RA_RANGE_PALADIN = (GetSpellInfo(85673)) or "Word of Glory";  -- 40 yards
CT_RA_RANGE_SHAMAN = (GetSpellInfo(331)) or "Healing Wave";  -- 40 yards
CT_RA_RANGE_MONK = (GetSpellInfo(115175)) or "Soothing Mist";  -- 40 yards

-- RAReg/RADur
-- I believe in WoW 5 (Mists of Pandaria) that reagents are no longer being used for spells,
-- Going to leave these reagents in the code for future reference.
CT_RA_REAGENT_MAGE_SPELL = (GetSpellInfo(43987)) or "Ritual of Refreshment";
CT_RA_REAGENT_DRUID_SPELL = (GetSpellInfo(20484)) or "Rebirth";
CT_RA_REAGENT_SHAMAN_SPELL = (GetSpellInfo(27740)) or "Reincarnation";

-- Text shown on button in death popup window when Shaman has Reincarnation available for use.
CT_RA_REZ_REINCARNATION = (GetSpellInfo(27740)) or "Reincarnation"; -- (see StaticPopup.lua for "DEATH")

-- For someone with a soulstone, the 2nd button on the death popu window shows "Use soulstone" (ie. USE_SOULSTONE) (see StaticPopup.lua)
-- Creating a Soulstone has a 10 minute cooldown.

-- Buffs known to the addon.
-- Table index is the CTRA internal id number for the buff or group of buffs.
-- Each value is a table with the following keys:
-- .opt == Should the buff appear in the buff options window? 0==No, >0==Yes (.opt is a priority number)
--         Buffs in a new table are sorted by the .opt (priority) value and then by the .name value.
-- .spellid == Global spell id.
-- .name == Spell name string.
-- .icon == Icon texture name (no path, just the file name).
CT_RA_BuffSpellData = {
	[1]  = { spellid = 21562, opt =       9 }, -- Power Word: Fortitude
--	[2]  = { spellid =  1126, opt =       9 }, -- Mark of the Wild  (removed in CTRA 8.0.1.5)
	[3]  = { spellid =  1459, opt =       9 }, -- Arcane Intellect/Brilliance
--	[4]  = { spellid =   nil, opt =       9 }, -- ? (Number 4 hasn't been used in a long time)
--	[5]  = { spellid = 27683, opt =       9 }, -- Shadow Protection (Not in WoW 5.04)
	[6]  = { spellid =    17, opt =  2      }, -- Power Word: Shield
	[7]  = { spellid = 20707, opt =      8  }, -- Soulstone Resurrection
--	[8]  = { spellid = 16875, opt =       9 }, -- Divine Spirit (Not in WoW 4.0.1)
--	[9]  = { spellid =   467, opt =     7   }, -- Thorns (Not in WoW 5.04)
--	[10] = { spellid =  6346, opt =   5     }, -- Fear Ward  (removed in CTRA 8.0.1.5)
--	[11] = { spellid = 19740, opt =       9 }, -- Blessing of Might (removed in CTRA 8.0.1.5)
--	[12] = { spellid = 56521, opt =       9 }, -- Blessing of Wisdom (Not in WoW 4.0.1)
--	[13] = { spellid = 20217, opt =       9 }, -- Blessing of Kings (removed in CTRA 8.0.1.5)
--	[14] = { spellid =   nil, opt =       9 }, -- Blessing of Salvation (Not in WoW 4.0.1)
--	[15] = { spellid = 32770, opt =       9 }, -- Blessing of Light (Not in WoW 4.0.1)
--	[16] = { spellid =   nil, opt =       9 }, -- Blessing of Sanctuary (Not in WoW 4.0.1)
	[17] = { spellid =   139, opt = 1       }, -- Renew
	[18] = { spellid =   774, opt = 1       }, -- Rejuvenation
	[19] = { spellid =  8936, opt = 1       }, -- Regrowth
--	[20] = { spellid =  1267, opt =       9 }, -- Amplify Magic (Not in WoW 4.0.1)
--	[21] = { spellid =  1266, opt =       9 }, -- Dampen Magic (Not in WoW 4.0.1)
	[22] = { spellid = 33763, opt = 1       }, -- Lifebloom
	[23] = { spellid = 48438, opt = 1       }, -- Wild Growth
	[24] = { spellid = 33076, opt = 1       }, -- Prayer of Mending (added in CTRA 4.003)
--	[25] = { spellid = 61316, opt =       9 }, -- Dalaran Brilliance (added in CTRA 4.003, remoted in CTRA 8.0.1.5
};

-- Fill in other data using GetSpellInfo()
for num, spellData in pairs(CT_RA_BuffSpellData) do
	local name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange;
	local spellid = spellData["spellid"];
	name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange = GetSpellInfo(spellid);
	if (not spellData["name"]) then
		spellData["name"] = name or UNKNOWN or "Unknown";
	end
	if (not spellData["icon"]) then
		spellData["icon"] = icon; -- or "Interface\\Icons\\Spell_Holy_WordFortitude";
		--spellData["icon"] = gsub(spellData["icon"], "^Interface\\Icons\\(.+)$", "%1");
	end
end

-- Build table of internal id numbers indexed by buff name.
CT_RA_BuffSpellNumbers = {};
for num, spellData in pairs(CT_RA_BuffSpellData) do
	local name = spellData["name"];
--	if (type(name) == "table") then
--		for i, nam in pairs(name) do
--			CT_RA_BuffSpellNumbers[nam] = num;
--		end
--	else
		CT_RA_BuffSpellNumbers[name] = num;
--	end
end

function CT_RASets_UpdateOptionSetBuffs(setName)
	-- Update the buffs in the specified option set table.
	-- This should be called after loading an option set.
	local newList;

	local optionsTable = CT_RAMenu_Options[setName];
	if (not optionsTable) then
		return;
	end

	local buffTable = optionsTable["BuffTable"];
	if (not buffTable) then
		-- Create a new buff table for this option set.
		buffTable = {};
		optionsTable["BuffTable"] = buffTable;
		optionsTable["unchanged"] = nil;
		newList = true;
	end

	-- Remove buffs that don't apply to this version of the addon.
	for num, buffData in pairs(buffTable) do
		local index = buffData["index"];
		local spellData = CT_RA_BuffSpellData[index];
		-- If buff not in our master list, or buff is not for use on options window...
		if (not spellData or spellData["opt"] <= 0) then
			-- Remove the buff
			buffTable[num] = nil;
			optionsTable["unchanged"] = nil;
		end
	end

	-- Add missing buffs that are in this version of the addon.
	local maxBuffs = 0;
	for index, spellData in pairs(CT_RA_BuffSpellData) do
		-- If buff is for use on options window...
		if (spellData["opt"] > 0) then
			maxBuffs = maxBuffs + 1;
			-- Lookup the internal buff number in the option set's buff table.
			local found;
			for num, buffData in pairs(buffTable) do
				if (buffData["index"] == index) then
					found = index;
					break;
				end
			end
			if (not found) then
				-- Add the buff to the end of the list.
--				tinsert(buffTable, { ["show"] = 1, ["index"] = index });
				buffTable[maxBuffs] = { ["show"] = 1, ["index"] = index };
				optionsTable["unchanged"] = nil;
			end
		end
	end

	-- Copy the buffTable items into a new array with no gaps.
	local newBuffTable = {};
	local index = 0;
	for num, buffData in pairs(buffTable) do
		index = index + 1;
		newBuffTable[index] = buffData;
	end
	optionsTable["BuffTable"] = newBuffTable;
	buffTable = newBuffTable;

	-- If this is a new list, then convert old settings and sort the new list.
	if (newList) then
		local buffArray = optionsTable["BuffArray"];

		-- If the old BuffArray table is present in this options set,
		-- then preserve the show/hide settings.
		if (buffArray) then
			-- Copy the old show/hide settings.
			for arrayNum, arrayData in pairs(buffArray) do
				local arrayIndex = arrayData["index"];
				local tableData = buffTable[arrayIndex];
				if (tableData) then
					tableData["show"] = arrayData["show"];
				end
				-- If old spell is the mage "intellect" bundle of spells...
				if (arrayIndex == 3) then
					-- Use same setting for Dalaran Brilliance
					tableData = buffTable[25];
					if (tableData) then
						tableData["show"] = arrayData["show"];
					end
				end
			end
		end

		-- Sort the new BuffTable.
		-- First gather some information about the old BuffArray.
		local numBrilliance;
		if (buffArray) then
			for arrayNum, arrayData in pairs(buffArray) do
				if (arrayData["index"] == 3) then
					-- Remember the position of Arcane Brilliance and Dalaran Brilliance in the old BuffArray.
					-- They used to be together at the same spot, along with Arcance/Dalaran Intellect.
					numBrilliance = arrayNum;
				end
			end
		end
		-- If both buffs are in the old BuffArray, then sort them by their
		-- position in the old table.
		--
		-- If only one buff is in the old BuffArray, then sort it higher in the new
		-- BuffTable than a buff that isn't in the new table.
		--
		-- If neither buff is in the old BuffArray, then sort them by option priority then by name.
		sort(buffTable,
			function(a, b)
				-- Get internal id numbers of the two buffs.
				local aIndex = a["index"] or 1;
				local bIndex = b["index"] or 1;
				-- Check if the buffs are in the old BuffArray.
				local aOldNum, bOldNum;
				if (buffArray) then
					if (aIndex == 25 and numBrilliance) then
						-- This is Dalaran Brilliance (which is now a separate buff from Arcane Brilliance).
						-- Use same position as the old Arcane Brilliance + Dalaran Brilliance combo.
						aOldNum = numBrilliance;
					else
						-- Lookup this buff's position in the old BuffArray.
						for arrayNum, arrayData in pairs(buffArray) do
							if (arrayData["index"] == aIndex) then
								aOldNum = arrayNum;
								break;
							end
						end
					end
					if (bIndex == 25 and numBrilliance) then
						-- This is Dalaran Brilliance (which is now a separate buff from Arcane Brilliance).
						-- Use same position as the old Arcane Brilliance + Dalaran Brilliance combo.
						bOldNum = numBrilliance;
					else
						-- Lookup this buff's position in the old BuffArray.
						for arrayNum, arrayData in pairs(buffArray) do
							if (arrayData["index"] == bIndex) then
								bOldNum = arrayNum;
								break;
							end
						end
					end
				end
				if (aOldNum and bOldNum) then
					-- Both are present in old BuffArray, so sort by postion in old BuffArray.
					return aOldNum < bOldNum;
				elseif (aOldNum) then
					-- Only first one is present in old BuffArray, so it sorts before new buffs.
					return true;
				elseif (bOldNum) then
					-- Only second is present in old BuffArray, so it sorts before new buffs.
					return false;
				else
					-- Neither one is in old BuffArray, so sort by option priority and then by name.
					local aSpellData = CT_RA_BuffSpellData[aIndex];
					local bSpellData = CT_RA_BuffSpellData[bIndex];
					local aName, bName;
					local aOpt, bOpt;
					if (aSpellData) then
						aName = aSpellData["name"];
						aOpt = aSpellData["opt"];
--						if (type(aName) == "table") then
--							aName = aName[1];
--						end
					end
					if (bSpellData) then
						bName = bSpellData["name"];
						bOpt = bSpellData["opt"];
--						if (type(bName) == "table") then
--							bName = bName[1];
--						end
					end
					if (aOpt < bOpt) then
						return true;
					elseif (aOpt > bOpt) then
						return false;
					else
						return (aName or "") < (bName or "");
					end
				end
			end
		);
	end
end

function CT_RA_CreateDefaultSet()
	-- Create the "Default" set of options.

	-- Prior to CT_RaidAssist 4.003:
	-- 	CT_RAMenu_Options["optionsetname"]["BuffArray"]:
	-- 		.show == 1 (show) or -1 (don't show)
	-- 		.index == CTRA internal spell number.
	-- 		.name == A single spell name string, or a table of spell name strings.
	--	An existing BuffArray table is not used after conversion, but it is also
	-- 	not deleted for now.

	-- As of CT_RaidAssist 4.003:
	-- 	CT_RAMenu_Options["optionsetname"]["BuffTable"]:
	-- 		.show == 1 (show) or -1 (don't show)
	-- 		.index == CTRA internal spell number.
	--	The .name was dropped to make it easier to add/remove/rename spells.

	local default = {
		PlayRSSound = 1,
		MenuLocked = 1,
		ShowMTs = { 1, 1, 1, 1, 1 },
		NotifyDebuffsClass = {},
		NotifyDebuffs = {},
		DefaultColor = { r = 0, g = 0.1, b = 0.9, a = 0.5 },
		MemberHeight = 40,
		PercentColor = { r = 1, g = 1, b = 1 },
		DefaultAlertColor = { r = 1, g = 1, b = 1 },
		BGOpacity = 0.4,
		WindowPositions = { },
		-- Starting with CT_RaidAssist 4.003, BuffArray no longer being used.
		-- Starting with CT_RaidAssist 4.003, BuffTable is the replacement for BuffArray.
		BuffTable = { },
		DebuffColors = {
			{ ["type"] = CT_RA_DEBUFFTYPE_CURSE, ["r"] = 1, ["g"] = 0, ["b"] = 0.75, ["a"] = 0.5, ["id"] = 4, ["index"] = 1 },
			{ ["type"] = CT_RA_DEBUFFTYPE_MAGIC, ["r"] = 1, ["g"] = 0, ["b"] = 0, ["a"] = 0.5, ["id"] = 6, ["index"] = 2 },
			{ ["type"] = CT_RA_DEBUFFTYPE_POISON, ["r"] = 0, ["g"] = 0.5, ["b"] = 0, ["a"] = 0.5, ["id"] = 3, ["index"] = 3 },
			{ ["type"] = CT_RA_DEBUFFTYPE_DISEASE, ["r"] = 1, ["g"] = 1, ["b"] = 0, ["a"] = 0.5, ["id"] = 5, ["index"] = 4 },
			{ ["type"] = CT_RA_DEBUFF_WEAKENED_SOUL, ["r"] = 1, ["g"] = 0, ["b"] = 1, ["a"] = 0.5, ["id"] = 2, ["index"] = 5 },
			{ ["type"] = CT_RA_DEBUFF_RECENTLY_BANDAGED, ["r"] = 0, ["g"] = 0, ["b"] = 0, ["a"] = 0.5, ["id"] = 1, ["index"] = 6 },
		},
		ShowGroups = { },
		SpellCastDelay = 0.5,
		SORTTYPE = "group",
	};
	for i = 1, CT_RA_MaxGroups do
		default["NotifyDebuffsClass"][i] = 1;
	end
	for i = 1, NUM_RAID_GROUPS do
		default["NotifyDebuffs"][i] = 1;
	end
	CT_RAMenu_Options["Default"] = default;

	-- Update the buff table for the "Default" option set.
	CT_RASets_UpdateOptionSetBuffs("Default");

	CT_RAMenu_Options["Default"]["unchanged"] = 1;
end

function CT_RASets_CopyTable(source)
	if ( type(source) == "table" ) then
		local dest = { };
		for k, v in pairs(source) do
			dest[k] = CT_RASets_CopyTable(v);
		end
		return dest;
	else
		return source;
	end
end

function CT_RA_ResetOptions()
	-- Reset all options
	CT_RAMenu_Options = {};

	-- Create the "Default" option set. This set cannot be deleted, but the user can save it.
	CT_RA_CreateDefaultSet();

	-- Copy the "Default" set into the "temp" set
	CT_RAMenu_Options["temp"] = CT_RASets_CopyTable(CT_RAMenu_Options["Default"]);
	CT_RAMenu_Options["temp"]["unchanged"] = 1;
	CT_RASets_UpdateOptionSetBuffs("temp");

	CT_RAMenu_CurrSet = "Default";
	CT_RASets_ButtonPosition = 16;
end


CT_RA_ResetOptions();


function CT_RASets_OnEvent(self, event, ...)
	if (event == "VARIABLES_LOADED") then
		CT_RASets_MoveButton();
	elseif (event == "PLAYER_REGEN_DISABLED") then
		if (L_UIDROPDOWNMENU_OPEN_MENU == "CT_RASets_DropDown") then
			L_CloseDropDownMenus();
		end
	end
end

function CT_RASets_MoveButton()
	CT_RASets_Button:SetPoint("TOPLEFT", "Minimap", "TOPLEFT", 52 - (80 * cos(CT_RASets_ButtonPosition)), (80 * sin(CT_RASets_ButtonPosition)) - 52);
end

local CT_RASets_DropDown_initialized;
function CT_RASets_ToggleDropDown()
	if (not CT_RASets_DropDown_initialized) then
		CT_RASets_DropDown_OnLoad(CT_RASets_DropDown);
		CT_RASets_DropDown_initialized = true;
	end
	CT_RASets_DropDown.point = "TOPRIGHT";
	CT_RASets_DropDown.relativePoint = "BOTTOMLEFT";
	L_ToggleDropDownMenu(1, nil, CT_RASets_DropDown);
end

function CT_RASets_DropDown_Initialize(self)
	--CT_RASets_OpenedLevel = CT_RA_Level;
	CT_RASets_OpenedLevel = 0;

	local inCombat = InCombatLockdown();

	local info = {};
	info.text = "CT_RaidAssist";
	info.isTitle = 1;
	info.justifyH = "CENTER";
	info.notCheckable = 1;
	L_UIDropDownMenu_AddButton(info);

	info = { };
	info.text = "Open CTRA options";
	info.value = ".options";
	info.notCheckable = 1;
	info.disabled = inCombat;
	info.func = CT_RASets_DropDown_OnClick;
	L_UIDropDownMenu_AddButton(info);

	info = { };
	info.text = "Open CTRA raid window";
	info.value = ".ctraid";
	info.notCheckable = 1;
	info.disabled = inCombat;
	info.func = CT_RASets_DropDown_OnClick;
	L_UIDropDownMenu_AddButton(info);

	if ( ( CT_RASets_OpenedLevel or 0 ) >= 1 ) then
		info = { };
		info.text = "Target management";
		info.value = ".target";
		info.notCheckable = 1;
		info.disabled = inCombat;
		info.func = CT_RASets_DropDown_OnClick;
		L_UIDropDownMenu_AddButton(info);
	end

	info = { };
	if ( CT_RAMenu_Options["temp"]["LockGroups"] ) then
		info.text = "Unlock raid frames";
	else
		info.text = "Lock raid frames";
	end
	info.value = ".locktoggle";
	info.notCheckable = 1;
	info.disabled = inCombat;
	info.func = CT_RASets_DropDown_OnClick;
	L_UIDropDownMenu_AddButton(info);

	info = { };
	info.text = "Edit option sets";
	info.value = ".editsets";
	info.notCheckable = 1;
	info.disabled = inCombat;
	info.func = CT_RASets_DropDown_OnClick;
	L_UIDropDownMenu_AddButton(info);

	local numSets = 0;
	local sets = {};
	for k, v in pairs(CT_RAMenu_Options) do
		if ( k ~= "temp" ) then
			numSets = numSets + 1;
			if ( numSets == 8 ) then
				break;
			end
			tinsert(sets, k);
		end
	end
	if ( numSets > 0 ) then
		sort(sets, function (a, b)
				if (string.lower(a) < string.lower(b)) then
					return true;
				else
					return false;
				end
		end);

		info.text = "--- Option Sets ---";
		info.isTitle = 1;
		info.justifyH = "CENTER";
		info.notCheckable = 1;
		L_UIDropDownMenu_AddButton(info);

		for i, k in ipairs(sets) do
			info = { };
			info.text = k;
			info.value = "*" .. k;
			info.isTitle = nil;
			if ( CT_RAMenu_CurrSet == k ) then
				info.checked = 1;
			end
			info.disabled = inCombat;
			info.tooltipTitle = "Change Set";
			info.tooltipText = "Changes the current option set to this one, updating all of your settings to match the ones specified in the option set.";
			info.func = CT_RASets_DropDown_OnClick;
			L_UIDropDownMenu_AddButton(info);
		end
	end
end

function CT_RASets_DropDown_OnClick(self)
	if (self.value == ".options") then
		if (not InCombatLockdown()) then
			ShowUIPanel(CT_RAMenuFrame);
		end

	elseif (self.value == ".target") then
		ShowUIPanel(CT_RATargetFrame);

	elseif (self.value == ".editsets") then
		if (not InCombatLockdown()) then
			ShowUIPanel(CT_RAMenuFrame);
			CT_RAMenuButton_OnClick(self, 5);
		end

	elseif (self.value == ".locktoggle") then
		if (not InCombatLockdown()) then
			CT_RAMenu_Options["temp"]["LockGroups"] = not CT_RAMenu_Options["temp"]["LockGroups"];
			CT_RA_UpdateRaidFrames();
			CT_RAMenu_UpdateMenu();
			CT_RAMenu_UpdateOptionSets();
		end

	elseif (self.value == ".ctraid") then
		if (not InCombatLockdown()) then
			ShowUIPanel(CT_RATabFrame);
		end

	elseif (strsub(self.value, 1, 1) == "*") then
		for k, v in pairs(CT_RAMenu_Options) do
			if ( k ~= "temp" ) then
				if (k == strsub(self.value, 2)) then
					if (not InCombatLockdown()) then
						CT_RAMenu_LoadSet(k);
					end
					return;
				end
			end
		end
	end
end

function CT_RASets_DropDown_OnLoad(self)
	L_UIDropDownMenu_Initialize(self, CT_RASets_DropDown_Initialize, "MENU");
end

tinsert(UISpecialFrames, "CT_RAMenu_NewSetFrame");
tinsert(UISpecialFrames, "CT_RAMenu_DeleteSetFrame");

-- -----------------------------------------------------------------------

-- These CT_RASetsEdit* and CT_RASet_New functions are not used anywhere.
-- It may have been new code Cide was working on, or old code that he left here.
-- I've commented it out for now.

--[[

CT_RASetsEditFrame_NumButtons = 7;

function CT_RASetsEditFrame_Update()
	local numEntries = 0;
	for k, v in pairs(CT_RAMenu_Options) do
		numEntries = numEntries + 1;
	end
	FauxScrollFrame_Update(CT_RASetsEditFrameScrollFrame, numEntries, CT_RASetsEditFrame_NumButtons , 32);

	for i = 1, CT_RASetsEditFrame_NumButtons, 1 do
		local button = _G["CT_RASetsEditFrameBackdropButton" .. i];
		local index = i + FauxScrollFrame_GetOffset(CT_RASetsEditFrameScrollFrame);
		local num, name = 0, nil;
		if ( i <= numEntries ) then

			for k, v in pairs(CT_RAMenu_Options) do
				num = num + 1;
				if ( num == index ) then
					name = k;
					break;
				end
			end
			if ( name ) then
				button:Show();
				if ( CT_RASetsEditFrame.selected == name ) then
					_G[button:GetName() .. "CheckButton"]:SetChecked(1);
				else
					_G[button:GetName() .. "CheckButton"]:SetChecked(nil);
				end
				_G[button:GetName() .. "Name"]:SetText(name);
			end
		else
			button:Hide();
		end
	end
end

function CT_RASetsEditCB_Check(id)
	for i = 1, CT_RASetsEditFrame_NumButtons, 1 do
		_G["CT_RASetsEditFrameBackdropButton" .. i .. "CheckButton"]:SetChecked(nil);
	end
	if ( not id ) then
		return;
	end
	_G["CT_RASetsEditFrameBackdropButton" .. id .. "CheckButton"]:SetChecked(1);
	local num = 0;
	for k, v in pairs(CT_RAMenu_Options) do
		if ( k ~= "temp" ) then
			num = num + 1;
			if ( num == id+FauxScrollFrame_GetOffset(CT_RASetsEditFrameScrollFrame) ) then
				CT_RASetsEditFrame.selected = k;
				if ( k == "Default" ) then
					CT_RASetsEditFrame_EnableDelete(nil);
				else
					CT_RASetsEditFrame_EnableDelete(1);
				end
				return;
			end
		end
	end
	CT_RASetsEditFrame_EnableDelete(nil);
end

function CT_RASetsEditFrame_EnableDelete(enable)
	if ( enable ) then
		CT_RASetsEditFrameDeleteButton:Enable();
	else
		CT_RASetsEditFrameDeleteButton:Disable();
	end
end

function CT_RASetsEdit_Delete()
	if ( CT_RASetsEditFrame.selected ) then
		CT_RAMenu_Options[CT_RASetsEditFrame.selected] = nil;
		if ( CT_RASetsEditFrame.selected == CT_RAMenu_CurrSet ) then
			CT_RAMenu_CurrSet = "Default";
			CT_RA_UpdateRaidGroup(0);
			CT_RAOptions_Update();
			CT_RA_UpdateMTs(true);
			CT_RA_UpdatePTs(true);
			CT_RA_UpdateVisibility();
			CT_RA_UpdateRaidFrameOptions();
			CT_RAMenu_UpdateMenu();
		end
	end
	CT_RASetsEditFrame.selected = nil;
	CT_RASetsEditFrame_Update();
	CT_RASetsEditFrame_EnableDelete(nil);
end

function CT_RASetsEditNewDropDown_OnLoad(self)
	L_UIDropDownMenu_Initialize(self, CT_RASetsEditNew_DropDown_Initialize);
	L_UIDropDownMenu_SetWidth(self, 180);
	L_UIDropDownMenu_SetSelectedName(CT_RASetsEditNew_DropDown, "Default");
end

function CT_RASetsEditNew_DropDown_Initialize(self)
	local info = {};
	for k, v in pairs(CT_RAMenu_Options) do
		if ( k ~= "temp" ) then
			info = { };
			info.text = k;
			info.func = CT_RASetsEditNew_DropDown_OnClick;
			L_UIDropDownMenu_AddButton(info);
		end
	end
end

function CT_RASetsEditNew_DropDown_OnClick(self)
	local num = 0;
	for k, v in pairs(CT_RAMenu_Options) do
		if ( k ~= "temp" ) then
			num = num + 1;
			if ( num == self:GetID() ) then
				CT_RASetsEditNewFrame.set = k;
				L_UIDropDownMenu_SetSelectedName(CT_RASetsEditNew_DropDown, k);
				return;
			end
		end
	end
	CT_RASetsEditNewFrame.set = "Default";
	L_UIDropDownMenu_SetSelectedName(CT_RASetsEditNew_DropDown, "Default");
end

function CT_RASet_New()
	local name = CT_RASetsEditNewFrameNameEB:GetText();
	if ( strlen(name) > 0 and CT_RASetsEditNewFrame.set and CT_RAMenu_Options[CT_RASetsEditNewFrame.set] and not CT_RAMenu_Options[name] ) then
		CT_RAMenu_Options[name] = { };
		for k, v in pairs(CT_RAMenu_Options[CT_RASetsEditNewFrame.set]) do
			CT_RAMenu_Options[name][k] = v;
		end
	end
	CT_RASetsEditFrame_Update();
end

--]]

-- -----------------------------------------------------------------------
