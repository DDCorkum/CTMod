--[[
--
--  CT_RaidAssist_MTPlayers 5.3
--
--  Adds a Main Tank Players group and a Main Tank Pets group to
--  CT_RaidAssist's Main Tank Targets group.
--
--  Right click the title of the Main Tank Targets group to configure
--  the settings.
--
--  Author: Dargen of Eternal Keggers, Terenas.
--          http://www.eternalkeggers.net
--
--  Addons: http://www.wowinterface.com/portal.php?uid=25131
--          http://my.curse.com/members/Dargen.aspx
--
--  CT Mod: http://www.ctmod.net
--
--]]

-- ----------
-- Saved variables
-- ----------
CT_RA_MTPlayers_Status = 1;  -- Status: 0=disabled, 1=enabled

-- ----------
-- Variables which are not saved.
-- ----------
CT_RA_MTPlayers_cVersion = "5.3";

CT_RA_MTPlayers_Slash1 = "/ramtp"
CT_RA_MTPlayers_Slash2 = "/ctmtp"

CT_RA_MTPlayers_InWorld = nil;  -- Gets set to 1 once player is in the world.
CT_RA_MTPlayers_Test = nil; -- nil=Not test mode, 1=Test mode
CT_RA_MTPlayers_AttachedTo = nil;
CT_RA_MTPlayers_DragAll = nil;
CT_RA_MTPlayers_SavePoint = {};
CT_RA_MTPlayers_FoundRaid = nil;


-- The valid MT group names.
--
-- The Players and Pets groups are named so as to take advantage
-- of existing tests done in CT_RaidAssist that compare
-- for the letters "CT_RAMTGroup" at the start of the frame
-- name.  This allows existing CT_RaidAssist code to handle
-- the new frames when possible (eg. CT_RA_MemberFrame_OnEnter)
-- without duplicating that code in this addon.
--
-- This array is not the only location of the individual group names.
-- First element should be the MT Target group, then Players, then Pets.
-- The order of these groups is important (see prepareFrame2()).
CT_RA_MTPlayers_Groups = {
	"CT_RAMTGroup",
	"CT_RAMTGroupPlayer",
	"CT_RAMTGroupPet",
};


-- These are the names of the CT_RaidAssist functions that get hooked.
local CT_RA_MTPlayers_HookedFuncs = {
	{name = "CT_RA_UpdateUnitDebuffs"},
	{name = "CT_RA_UpdateUnitBuffs"},

	{name = "CT_RA_UpdateMTs"},
	{name = "CT_RA_UpdateRaidFrames"},
	{name = "CT_RA_UpdateRaidFrameData"},
	{name = "CT_RA_UpdateRaidFrameOptions"},

	{name = "CT_RAMenuMisc_OnUpdate"},
	{name = "CT_RAMenuAdditional_ScalingMT_OnValueChanged"},

	{name = "CT_RAMTGroupDrag", script = "OnMouseDown", new = "CT_RAMTGroupDrag"},
	{name = "CT_RAMTGroupPlayerDrag", script = "OnMouseDown", new = "CT_RAMTGroupDrag"},
	{name = "CT_RAMTGroupPetDrag", script = "OnMouseDown", new = "CT_RAMTGroupDrag"},

	{name = "CT_RAMTGroupDrag", script = "OnMouseUp", new = "CT_RAMTGroupDrag"},
	{name = "CT_RAMTGroupPlayerDrag", script = "OnMouseUp", new = "CT_RAMTGroupDrag"},
	{name = "CT_RAMTGroupPetDrag", script = "OnMouseUp", new = "CT_RAMTGroupDrag"},

	{name = "CT_RA_UpdateRaidMovability"},
	{name = "CT_RA_UpdateRaidGroupColors"},

	{name = "CT_RAMenu_General_ResetWindows"},
	{name = "CT_RAMenu_SaveWindowPositions"},
	{name = "CT_RAMenu_UpdateWindowPositions"},

	{name = "CT_RA_MemberFrame_OnEnter"},
	{name = "CT_RA_Drag_OnEnter"},

	{name = "CT_RA_CreateDefaultSet"},
	{name = "CT_RAMenu_LoadSet_GetValues"},
};

-- This is used to save original functions when hooking them.
CT_RA_MTPlayers_OldFunc = {};


-- ------------------------------------------------------------
-- Command line functions.
-- ------------------------------------------------------------


function CT_RA_MTPlayers_Command(msg)
	-- ----------
	-- Examine command line.
	-- ----------
	local pos1, pos2, cmd, rest = string.find(msg, "^%s-(%S+)(.*)");

	local command = "";
	if (cmd) then
		command = string.lower(cmd);
	else
		cmd = "";
	end

	if (command == CT_RA_MTPlayers_TEXT_Command_Help or command == "?" or command == "") then
		CT_RA_MTPlayers_Command_Help();

	elseif (command == CT_RA_MTPlayers_TEXT_Command_Status) then
		CT_RA_MTPlayers_Command_Status();

	elseif (command == CT_RA_MTPlayers_TEXT_Command_Enable) then
		CT_RA_MTPlayers_Command_Enable();

	elseif (command == CT_RA_MTPlayers_TEXT_Command_Disable) then
		CT_RA_MTPlayers_Command_Disable();

	elseif (command == CT_RA_MTPlayers_TEXT_Command_Toggle) then
		CT_RA_MTPlayers_Command_Toggle();

	elseif (command == CT_RA_MTPlayers_TEXT_Command_Players) then
		-- Toggle MT Players group.
		CT_RA_MTPlayers_Command_Players()

	elseif (command == CT_RA_MTPlayers_TEXT_Command_Pets) then
		-- Toggle MT Pets group.
		CT_RA_MTPlayers_Command_Pets()

	elseif (command == "_test") then
		CT_RA_MTPlayers_Command_Test();

	else
		-- Invalid command.
		CT_RA_MTPlayers_InvalidCommand()
	end
end


function CT_RA_MTPlayers_Print(text)
	-- ----------
	-- Print
	-- ----------
	CT_RA_MTPlayers_Print2("<CT_RA_MTPlayers> " .. text);
end


function CT_RA_MTPlayers_Print2(msg)
	-- ----------------
	-- Print a message.
	-- ----------------
	DEFAULT_CHAT_FRAME:AddMessage(msg);
	return;
end


function CT_RA_MTPlayers_Command_Help()
	-- ----------
	-- Help command.
	-- ----------
	local slash = CT_RA_MTPlayers_Slash1 .. " ";
	CT_RA_MTPlayers_Print2(" ");
	CT_RA_MTPlayers_Print2("CT_RA_MTPlayers " .. CT_RA_MTPlayers_cVersion .. " by Dargen, Eternal Keggers, Terenas.");
	CT_RA_MTPlayers_Print2(" ");
	CT_RA_MTPlayers_Print2(slash .. "[" .. CT_RA_MTPlayers_TEXT_Command_Help .. "] -- " .. CT_RA_MTPlayers_TEXT_Help_Help);
	CT_RA_MTPlayers_Print2(slash .. CT_RA_MTPlayers_TEXT_Command_Status .. " -- " .. CT_RA_MTPlayers_TEXT_Help_Status);
	CT_RA_MTPlayers_Print2(slash .. CT_RA_MTPlayers_TEXT_Command_Enable .. " -- " .. CT_RA_MTPlayers_TEXT_Help_Enable);
	CT_RA_MTPlayers_Print2(slash .. CT_RA_MTPlayers_TEXT_Command_Disable .. " -- " .. CT_RA_MTPlayers_TEXT_Help_Disable);
	CT_RA_MTPlayers_Print2(slash .. CT_RA_MTPlayers_TEXT_Command_Toggle .. " -- " .. CT_RA_MTPlayers_TEXT_Help_Toggle);
	CT_RA_MTPlayers_Print2(slash .. CT_RA_MTPlayers_TEXT_Command_Players .. " -- " .. CT_RA_MTPlayers_TEXT_Help_Players);
	CT_RA_MTPlayers_Print2(slash .. CT_RA_MTPlayers_TEXT_Command_Pets .. " -- " .. CT_RA_MTPlayers_TEXT_Help_Pets);
	CT_RA_MTPlayers_Print2(" ");
	CT_RA_MTPlayers_Print2(CT_RA_MTPlayers_TEXT_Help_RightClick);
end


function CT_RA_MTPlayers_Command_Version()
	-- ----------
	-- Version command.
	-- ----------
	CT_RA_MTPlayers_Print(CT_RA_MTPlayers_cVersion);
end


function CT_RA_MTPlayers_Command_Status()
	-- ----------
	-- Status command.
	-- ----------
	CT_RA_MTPlayers_isCTRA(1);
	CT_RA_MTPlayers_ShowStatus();
end


function CT_RA_MTPlayers_Command_Enable()
	-- ----------
	-- Enable command.
	-- ----------
	if (InCombatLockdown()) then
		return;
	end

	CT_RA_MTPlayers_Set_Status(1);
	CT_RA_MTPlayers_ShowStatus();
end


function CT_RA_MTPlayers_Command_Disable()
	-- ----------
	-- Disable command.
	-- ----------
	if (InCombatLockdown()) then
		return;
	end

	CT_RA_MTPlayers_Set_Status(0);
	CT_RA_MTPlayers_ShowStatus();
end


function CT_RA_MTPlayers_Command_Toggle()
	-- ----------
	-- Toggle command (enable/disable).
	-- ----------
	local tempOptions = CT_RAMenu_Options["temp"];

	if (InCombatLockdown()) then
		return;
	end

	if (CT_RA_MTPlayers_Status ~= 1) then
		CT_RA_MTPlayers_Set_Status(1);
	else
		CT_RA_MTPlayers_Set_Status(0);
	end
	CT_RA_MTPlayers_ShowStatus();
end


function CT_RA_MTPlayers_Command_Players()
	-- ----------
	-- Toggle MT Players
	-- ----------
	if (InCombatLockdown()) then
		return;
	end

	CT_RA_MTPlayers_Set_Players();
end


function CT_RA_MTPlayers_Command_Pets()
	-- ----------
	-- Toggle MT Pets
	-- ----------
	if (InCombatLockdown()) then
		return;
	end

	CT_RA_MTPlayers_Set_Pets();
end


function CT_RA_MTPlayers_Command_Test()
	-- ----------
	-- Test command.
	-- ----------
	if (CT_RA_MTPlayers_Test) then
		CT_RA_MTPlayers_Test = nil;
		CT_RA_MTPlayers_Print("Test mode disabled.");
	else
		CT_RA_MTPlayers_Test = 1;
		CT_RA_MTPlayers_Print("Test mode enabled.");
	end
end


function CT_RA_MTPlayers_InvalidCommand()
	-- --------------
	-- Invalid command message.
	-- --------------
	CT_RA_MTPlayers_Print(CT_RA_MTPlayers_TEXT_InvalidCommand .. " " .. CT_RA_MTPlayers_Slash1 .. " " .. CT_RA_MTPlayers_TEXT_Command_Help);
end


-- ------------------------------------------------------------
-- Status functions.
-- ------------------------------------------------------------


function CT_RA_MTPlayers_ShowStatus()
	-- ----------
	-- Show status.
	-- ----------
	local tempOptions = CT_RAMenu_Options["temp"];

	if (CT_RA_MTPlayers_Status ~= 1) then
		CT_RA_MTPlayers_Print(CT_RA_MTPlayers_TEXT_IsDisabled);
	else
		CT_RA_MTPlayers_Print(CT_RA_MTPlayers_TEXT_IsEnabled);
	end
end


-- ------------------------------------------------------------
-- Configuration functions.
-- ------------------------------------------------------------


function CT_RA_MTPlayers_DefaultTo(optionsTable, optionName, defaultValue)
	-- ----------
	-- Assign default value to variable if the current value is nil.
	-- ----------
	if (not optionsTable[optionName]) then
		optionsTable[optionName] = defaultValue;
	end
end


function CT_RA_MTPlayers_SetValue(new, current)
	-- ----------
	-- General routine to set value to new value of 0 or 1,
	-- or to toggle between those two values if new value is nil.
	-- ----------
	local value;

	if (new == nil) then
		if (current == 1) then
			value = 0;
		else
			value = 1;
		end
	elseif (new == 1) then
		value = 1;
	else
		value = 0;
	end

	return value;
end


function CT_RA_MTPlayers_Set_Common(value, optionName, combat, update)
	-- ----------
	-- Common function to set a value.
	-- ----------
	local tempOptions = CT_RAMenu_Options["temp"];

	if (combat) then
		if (InCombatLockdown()) then
			return;
		end
	end

	tempOptions[optionName] = CT_RA_MTPlayers_SetValue(value, tempOptions[optionName]);

	if (update) then
		CT_RA_UpdateRaidFrameData();
		CT_RA_UpdateMTs(true);
	end
end


function CT_RA_MTPlayers_Set_Status(value, print)
	-- ----------
	-- Enable/disable this addon.
	-- ----------
	local tempOptions = CT_RAMenu_Options["temp"];

	if (InCombatLockdown()) then
		return;
	end

	CT_RA_MTPlayers_Status = CT_RA_MTPlayers_SetValue(value, CT_RA_MTPlayers_Status);

	if (print) then
		CT_RA_MTPlayers_ShowStatus();
	end

	if (CT_RA_MTPlayers_Status == 1) then
		-- -----
		-- Enable the addon.
		-- -----

		-- Update the Main Tank Player and Pet frames.
		CT_RA_UpdateRaidFrameData();
		CT_RA_UpdateMTs(true);

		-- Set scaling timer to trigger a quick update.
		CT_RAMenuGlobalFrame.scaleupdate = 0.1;
	else
		-- -----
		-- Disable the addon.
		-- -----

		-- Hide the Players and Pets groups.

		CT_RAMTGroupPlayer:Hide();
		if (CT_RAMTGroupPlayer.GroupName) then
			CT_RAMTGroupPlayer.GroupName:Hide();
		end
		CT_RAMTGroupPlayerDrag:Hide();
		CT_RAMTGroupPlayerMenu:Hide();

		CT_RAMTGroupPet:Hide();
		if (CT_RAMTGroupPet.GroupName) then
			CT_RAMTGroupPet.GroupName:Hide();
		end
		CT_RAMTGroupPetDrag:Hide();
		CT_RAMTGroupPetMenu:Hide();

		CT_RAMTGroupMenu:Hide();

		if (not CT_RA_MTPlayers_isCTRA()) then
			return;
		end

		CT_RA_UpdateRaidFrameData();
		CT_RA_UpdateMTs(true);
	end
end


function CT_RA_MTPlayers_Set_Players(value)
	-- ----------
	-- Enable/disable MT Players group.
	-- ----------
	CT_RA_MTPlayers_Set_Common(value, "ctmtp_MTPlayers", true, true);
end


function CT_RA_MTPlayers_Set_Pets(value)
	-- ----------
	-- Enable/disable MT Pets group.
	-- ----------
	CT_RA_MTPlayers_Set_Common(value, "ctmtp_MTPets", true, true);
end

function CT_RA_MTPlayers_Set_PlayerBuffs(value)
	-- ----------
	-- Show or hide player buffs/debuffs in the MT Players group.
	-- ----------
	local tempOptions = CT_RAMenu_Options["temp"];
	tempOptions["ctmtp_PlayerBuffs"] = CT_RA_MTPlayers_SetValue(value, tempOptions["ctmtp_PlayerBuffs"]);
	CT_RA_UpdateMTs(true);
end

function CT_RA_MTPlayers_Set_GroupHasNoPet(value)
	-- ----------
	-- Hide MT Pets group if group has no pet.
	-- ----------
	CT_RA_MTPlayers_Set_Common(value, "ctmtp_GroupHasNoPet", true, true);
end

--function CT_RA_MTPlayers_Set_PlayerHasNoPet(value)
--	-- ----------
--	-- Hide MT Pets box if player has no pet.
--	-- ----------
--	CT_RA_MTPlayers_Set_Common(value, "ctmtp_PlayerHasNoPet", true, true);
--end

function CT_RA_MTPlayers_Set_LockJoined(value)
	-- ----------
	-- Join MT groups together.
	-- ----------
	CT_RA_MTPlayers_Set_Common(value, "ctmtp_LockJoined", true, true);
end

function CT_RA_MTPlayers_Set_SidePlayer(value)
	-- ----------
	-- Side of MT Targets that the MT Player group is on.
	-- ----------
	CT_RA_MTPlayers_Set_Common(value, "ctmtp_SidePlayer", true, true);
end

function CT_RA_MTPlayers_Set_SidePet(value)
	-- ----------
	-- Side of MT Targets that the MT Pet group is on.
	-- ----------
	CT_RA_MTPlayers_Set_Common(value, "ctmtp_SidePet", true, true);
end

function CT_RA_MTPlayers_Set_SidePetPlayer(value)
	-- ----------
	-- Side of MT Player that the MT Pet group is on.
	-- ----------
	CT_RA_MTPlayers_Set_Common(value, "ctmtp_SidePetPlayer", true, true);
end

function CT_RA_MTPlayers_Set_HideMTAndPlayers(value)
	-- ----------
	-- Enable/disable hiding of MT Players group when MT Targets are hidden.
	-- ----------
	CT_RA_MTPlayers_Set_Common(value, "ctmtp_HideMTAndPlayers", true, true);
end


function CT_RA_MTPlayers_Set_HideMTAndPets(value)
	-- ----------
	-- Enable/disable hiding of MT Pets group when MT Targets are hidden.
	-- ----------
	CT_RA_MTPlayers_Set_Common(value, "ctmtp_HideMTAndPets", true, true);
end

function CT_RA_MTPlayers_Set_GapHide(value)
	-- ----------
	-- Hide gap between joined MT groups (when frame border is hidden).
	-- ----------
	CT_RA_MTPlayers_Set_Common(value, "ctmtp_GapHide", true, true);
end

function CT_RA_MTPlayers_Set_AlignToTitle(value)
	-- ----------
	-- Align to MT group title after dragging.
	-- ----------
	local tempOptions = CT_RAMenu_Options["temp"];
	tempOptions["ctmtp_AlignToTitle"] = CT_RA_MTPlayers_SetValue(value, tempOptions["ctmtp_AlignToTitle"]);
end


-- ------------------------------------------------------------
-- Initialization functions.
-- ------------------------------------------------------------


function CT_RA_MTPlayers_isCTRA(showErr)
	-- --------------
	-- Test if CT_RaidAssist is present and compatible.
	-- --------------
	local ok = true;
	for i = 1, #CT_RA_MTPlayers_HookedFuncs do
		local f = CT_RA_MTPlayers_HookedFuncs[i];
		if (f.script) then
			local frame = _G[f.name];
			if (not frame) then
				ok = false;
				break;
			end
			if (not frame:GetScript(f.script)) then
				ok = false;
				break;
			end
		else
			if (not _G[f.name]) then
				ok = false;
				break;
			end
		end
	end
	if (ok) then
		return true;
	end

	if (showErr) then
	        -- "CT_RaidAssist not detected/incompatible."
	        CT_RA_MTPlayers_Print(CT_RA_MTPlayers_TEXT_CTRaid_Fail);
	end
        return false;
end

function CT_RA_MTPlayers_SetDefaultOptions(optionsTable)
	-- --------------
	-- Assigns default values for the options.
	-- --------------
	CT_RA_MTPlayers_DefaultTo(optionsTable, "ctmtp_MTPlayers", 1);  -- Main Tank Players: 0 == disabled, 1 == enabled
	CT_RA_MTPlayers_DefaultTo(optionsTable, "ctmtp_MTPets", 1);  -- Main Tank Pets: 0 == disabled, 1 == enabled
	CT_RA_MTPlayers_DefaultTo(optionsTable, "ctmtp_GroupHasNoPet", 1);  -- Hide MT Pets group when none of MT's have a pet: 0==Show always, 1=Hide when no pet
--	CT_RA_MTPlayers_DefaultTo(optionsTable, "ctmtp_PlayerHasNoPet", 1);  -- Hide an MT Player's pet box when they don't have a pet: 0==Show always, 1=Hide when no pet
	CT_RA_MTPlayers_DefaultTo(optionsTable, "ctmtp_AlignToTitle", 0);  -- Align other groups to the dragged group's title (when the dragged group doesn't overlap anything): 0=No, 1=Yes
	CT_RA_MTPlayers_DefaultTo(optionsTable, "ctmtp_GapHide", 0);  -- Hide horizontal gap between MT players/MT Targets/MT Pets: 1=Hide, 0=Show
	CT_RA_MTPlayers_DefaultTo(optionsTable, "ctmtp_LockJoined", 1);  -- Join MT groups: 0=No, 1=Yes.
	CT_RA_MTPlayers_DefaultTo(optionsTable, "ctmtp_WindowPositions", {});  -- Saved window positions
	CT_RA_MTPlayers_DefaultTo(optionsTable, "ctmtp_PlayerBuffs", 1);  -- 0==Don't show player buffs/debuffs, 1==Show player buffs/debuffs
	CT_RA_MTPlayers_DefaultTo(optionsTable, "ctmtp_HideMTAndPlayers", 1);   -- 1==Hide MT Players group when MT Targets group is hidden, 0=Don't hide
	CT_RA_MTPlayers_DefaultTo(optionsTable, "ctmtp_HideMTAndPets", 1);  -- 1==Hide MT Pets group when MT Targets group is hidden, 0=Don't hide

	-- New saved variables in 1.5
	CT_RA_MTPlayers_DefaultTo(optionsTable, "ctmtp_SidePlayer", 0); -- 0==MT Players on left side of MT Targets, 1==Right side
	CT_RA_MTPlayers_DefaultTo(optionsTable, "ctmtp_SidePet", 0); -- 0==MT Pets on left side of MT Targets, 1==Right side
	CT_RA_MTPlayers_DefaultTo(optionsTable, "ctmtp_SidePetPlayer", 0); -- 0==MT Pets on left side of MT Players, 1==Right side
end

function CT_RA_MTPlayers_OnLoad()
	-- --------------
	-- Loading addon.
	-- --------------
	if (not CT_RA_RegisterSlashCmd) then
		SLASH_RAMTP1 = CT_RA_MTPlayers_Slash1;
		SLASH_RAMTP2 = CT_RA_MTPlayers_Slash2;
		SlashCmdList["RAMTP"] = function( msg )
			CT_RA_MTPlayers_Command(msg);
		end
	else
		CT_RA_RegisterSlashCmd(CT_RA_MTPlayers_Slash1,
			"Usable via |b" .. CT_RA_MTPlayers_Slash1 .. " players|eb, or |b" .. CT_RA_MTPlayers_Slash1 .. " pets|eb, this shows/hides the MT Players or MT Pets group.",
			30, "RAMTP", CT_RA_MTPlayers_Command, CT_RA_MTPlayers_Slash1, CT_RA_MTPlayers_Slash2);
	end

	CT_RA_MTPlayers:RegisterEvent("VARIABLES_LOADED");
	CT_RA_MTPlayers:RegisterEvent("PLAYER_ENTERING_WORLD");
	CT_RA_MTPlayers:RegisterEvent("GROUP_ROSTER_UPDATE");
	CT_RA_MTPlayers:RegisterEvent("PLAYER_REGEN_DISABLED");
	CT_RA_MTPlayers:RegisterEvent("PLAYER_REGEN_ENABLED");
	CT_RA_MTPlayers:RegisterEvent("UPDATE_BINDINGS");
	CT_RA_MTPlayers:RegisterEvent("UNIT_PET");
--	CT_RA_MTPlayers:RegisterEvent("ADDON_ACTION_BLOCKED");
end


function CT_RA_MTPlayers_OnEvent(self, event, ...)
	-- --------------
	-- Handle events.
	-- --------------
	local tempOptions = CT_RAMenu_Options["temp"];

	if (event == "PLAYER_ENTERING_WORLD") then
		if (not CT_RA_MTPlayers_InWorld) then
			CT_RA_MTPlayers_InWorld = 1;

			-- Raid status window enhancements.
			if (CT_RA_MTPlayers_isCTRA()) then
				local ok = CT_RA_MTPlayers_Init();
				if (not ok) then
					CT_RA_MTPlayers_Print("Error initializing addon.");
				end
			end

			CT_RAMenu_UpdateWindowPositions();
		end
		CT_RA_MTPlayers_FoundRaid = nil;

	elseif (event == "VARIABLES_LOADED") then
		if (not CT_RA_MTPlayers_Status) then
			CT_RA_MTPlayers_Status = 0;
		end
		-- Set default values for any missing options.
		CT_RA_MTPlayers_SetDefaultOptions(tempOptions);

	elseif (event == "GROUP_ROSTER_UPDATE") then
		-- When initially logging in CT_RA_MTPlayers_GetNumRaidMembers() returns 0 even if you are in a raid.
		-- When we get this event and the function returns a non-zeo value, then update the
		-- MT frames, and set a var so we don't do this again until next login.
		if (not CT_RA_MTPlayers_RaidRosterUpdate) then
			if (CT_RA_MTPlayers_GetNumRaidMembers() > 0) then
				CT_RA_MTPlayers_Set_Status(CT_RA_MTPlayers_Status);
				CT_RA_MTPlayers_RaidRosterUpdate = 1;
			end
		end
	elseif (event == "PLAYER_REGEN_DISABLED") then
		-- About to enter combat (frames about to be locked down).
		if (not CT_RA_MTPlayers_AttachedTo and tempOptions["ctmtp_LockJoined"] == 1) then
			-- While we are in combat lockdown, we will keep the
			-- MT groups attached to each other by their drag frames.
			-- Only one of the visible drag frames can be used to move
			-- the attached groups.
			CT_RA_MTPlayers_AttachAllMTWindows();
		end
	elseif (event == "PLAYER_REGEN_ENABLED") then
		-- Have just left combat (frames are no longer locked down).
		if (CT_RA_MTPlayers_AttachedTo and not CT_RA_MTPlayers_DragAll) then
			CT_RA_MTPlayers_UnattachAllMTWindows();
			CT_RA_UpdateRaidFrameData();
			CT_RA_UpdateMTs(true);
		end
	elseif (event == "UPDATE_BINDINGS") then
		CT_RA_MTPlayers_UpdateBindings();
	elseif (event == "UNIT_PET") then
		CT_RA_MTPlayers_EK_RA_UpdateRaidFrames();

--[[
	elseif (event == "ADDON_ACTION_BLOCKED") then
		local arg1, arg2 = ...;
		-- arg1 == addon, arg2 == function
		if (arg1 == "CT_RA_MTPlayers") then
			CT_RA_MTPlayers_Print(event .. ", " .. arg1 .. ", " .. (arg2 or "nil"));
		else
			if (strsub(arg2, 1, 18) == "CT_RAMTGroupPlayer") or
			   (strsub(arg2, 1, 15) == "CT_RAMTGroupPet") or
			   (strsub(arg2, 1, 16) == "CT_RAMTGroupMenu") then

				CT_RA_MTPlayers_Print(event .. ", " .. arg1 .. ", " .. (arg2 or "nil"));
			end
		end
]]

	end
end


function CT_RA_MTPlayers_Init()
	-- ----------
	-- Initialize
	-- ----------

	-- Hook some CT_RaidAssist functions.
	local ok = true;
	for i = 1, #CT_RA_MTPlayers_HookedFuncs do
		local f = CT_RA_MTPlayers_HookedFuncs[i];
		ok = CT_RA_MTPlayers_Hook(f.name, f.script, f.new);
		if (not ok) then
			return false;
		end
	end

	local tempOptions = CT_RAMenu_Options["temp"];
	local newScaling = (tempOptions["MTScaling"] or 1);
	local mtwidth, ptwidth, height = CT_RA_GetMTFrameData();

	CT_RAMTGroupPlayer:SetScale(newScaling);
	CT_RAMTGroupPet:SetScale(newScaling);

	CT_RAMTGroupPlayerDrag:SetWidth(mtwidth*newScaling);
	CT_RAMTGroupPlayerDrag:SetHeight(height*newScaling/2);

	CT_RAMTGroupPlayerMenu:SetWidth(mtwidth*newScaling);
	CT_RAMTGroupPlayerMenu:SetHeight(height*newScaling/2);

	CT_RAMTGroupPetDrag:SetWidth(mtwidth*newScaling);
	CT_RAMTGroupPetDrag:SetHeight(height*newScaling/2);

	CT_RAMTGroupPetMenu:SetWidth(mtwidth*newScaling);
	CT_RAMTGroupPetMenu:SetHeight(height*newScaling/2);

	CT_RAMTGroupMenu:SetWidth(CT_RAMTGroupDrag:GetWidth());
	CT_RAMTGroupMenu:SetHeight(CT_RAMTGroupDrag:GetHeight());

	-- Set status
	CT_RA_MTPlayers_Set_Status(CT_RA_MTPlayers_Status);

	return true;
end

function CT_RA_MTPlayers_Hook(name, script, new)
	-- ----------
	-- Hook a CT_RaidAssist function or frame:script.
	-- ----------
	local oldObject, oldScript;
	local newObject;

	if (not new) then
		new = name;
	end

	oldObject = _G[name];
	if (not oldObject) then
		return false;
	end

	if (script) then
		oldScript = oldObject:GetScript(script);
		if (not oldScript) then
			return false;
		end
		newObject = _G["CT_RA_MTPlayers_" .. new .. script];
		if (not newObject) then
			return false;
		end
	else
		newObject = _G["CT_RA_MTPlayers_" .. new];
		if (not newObject) then
			return false;
		end
	end

	if (script) then
		CT_RA_MTPlayers_OldFunc[name .. script] = oldScript;
		oldObject:SetScript(script, newObject)
	else
		CT_RA_MTPlayers_OldFunc[name] = oldObject;
		_G[name] = newObject;
	end

	return true;
end


function CT_RA_MTPlayers_UpdateBindings()
	-- ----------
	-- Update key bindings.
	-- ----------
	local key;
	for i = 1, 10, 1 do
		key = GetBindingKey("CT_RA_MTPLAYERS_MTPLAYER" .. i);
		if (key) then
			SetOverrideBindingClick(CT_RAFrame, false, key, "CT_RAMTGroupPlayerUnitButton" .. i);
		end
		key = GetBindingKey("CT_RA_MTPLAYERS_MTPET" .. i);
		if (key) then
			SetOverrideBindingClick(CT_RAFrame, false, key, "CT_RAMTGroupPetUnitButton" .. i);
		end
	end
end


-- ------------------------------------------------------------
-- Operating functions.
-- ------------------------------------------------------------

function CT_RA_MTPlayers_GetNumRaidMembers()
	if (IsInRaid()) then
		return GetNumGroupMembers();
	else
		return 0;
	end
end

function CT_RA_MTPlayers_UnitName(unit)
	local name, realm;
	if (UnitExists(unit)) then
		name, realm = UnitName(unit);
		if (name and realm and realm ~= "") then
			return name .. "-" .. realm;
		end
	end
	return name;
end

function CT_RA_MTPlayers_GetShowStatus()
	-- ----------
	-- Determine which MT groups to display (targets, players, pets).
	--
	-- Returns 3 values:
	--   1) Show targets: 1==Yes, nil==No.
	--   2) Show players: 1==Yes, nil==No.
	--   3) Show pets: 1==Yes, nil==No.
	-- ----------
	local showmts, showmtplayers, showmtpets;
	local tempOptions = CT_RAMenu_Options["temp"];
	local numRaidMembers = CT_RA_MTPlayers_GetNumRaidMembers();

	-- Are there any main tanks?
	local havemts = false;
	for i = 1, ( tempOptions["ShowNumMTs"] or 10 ), 1 do
		if ( CT_RA_MainTanks[i] ) then
			havemts = true;
			break;
		end
	end

	if (CT_RA_MTPlayers_Status == 1) then
		if (numRaidMembers > 0 and havemts) then
			if (not tempOptions["HideMTs"]) then
				showmts = 1;
			end
			if (tempOptions["ctmtp_MTPlayers"] == 1) then
				showmtplayers = 1;
				if (not showmts and tempOptions["ctmtp_HideMTAndPlayers"] == 1) then
					showmtplayers = nil;
				end
			end
			if (tempOptions["ctmtp_MTPets"] == 1) then
				showmtpets = 1;
				if (not showmts and tempOptions["ctmtp_HideMTAndPets"] == 1) then
					showmtpets = nil;
				end
			end
		end
	end

	if (showmtpets and tempOptions["ctmtp_GroupHasNoPet"] == 1) then
		-- Hide MT Pets group if none of the main tanks has a pet.

		local petfound;
		local showNumTanks = ( tempOptions["ShowNumMTs"] or 10 );

		if (havemts and showNumTanks > 0) then
			local raidid, name;
			for i = 1, numRaidMembers, 1 do
				raidid = nil;
				name = CT_RA_MTPlayers_UnitName("raid" .. i);
				for k, v in pairs(CT_RA_MainTanks) do
					if (v and v == name) then
						raidid = "raidpet" .. i;
						break;
					end
				end
				if (raidid and UnitExists(raidid) and strlen(CT_RA_MTPlayers_UnitName(raidid) or "") > 0 ) then
					petfound = 1;
					break;
				end
			end
		end

		if (not petfound) then
			-- Hide the MT Pets group
			showmtpets = nil;
		end
	end

	return showmts, showmtplayers, showmtpets;
end


function CT_RA_MTPlayers_Update_AlignToTitle(Group)
	-- ----------
	-- Line up the MT windows vertically so that their
	-- titles are at the same Y value as the specified group.
	-- ----------
	local tempOptions = CT_RAMenu_Options["temp"];

	if ( tempOptions["LockGroups"] ) then
		return;
	end

--	if (not Group) then
--		Group = _G[this:GetName()];
--	end

	local X, Y = Group:GetLeft(), Group:GetTop();

	if (not X or not Y) then
		return;
	end

	if (InCombatLockdown()) then
		return;
	end

	for key, cGroup in ipairs(CT_RA_MTPlayers_Groups) do
		local cDrag = cGroup .. "Drag";
		if ( cDrag ~= Group:GetName() ) then
			local oGroup = _G[cDrag];
			local oX, oY = oGroup:GetLeft(), oGroup:GetTop();
			if ( oX and Y ) then
				oGroup:ClearAllPoints();
				oGroup:SetPoint("TOPLEFT", "UIParent", "TOPLEFT", oX, Y-UIParent:GetTop());
			end
		end
	end
end


function CT_RA_MTPlayers_UpdateMenuFrames()
	-- ----------
	-- Hide/unhide the frames used to trap right clicks in order to display
	-- a menu when the drag frames are hidden.
	-- ----------
	if (InCombatLockdown()) then
		return;
	end

	local showmts, showmtplayers, showmtpets = CT_RA_MTPlayers_GetShowStatus();

	-- Show/Hide the special MTGroup frame.
	-- This frame sits at same position as CT_RAMTGroupDrag.
	-- I needed it to be able to trap right mouse buttons when
	-- all windows are locked and the drag frames are hidden.
	if (CT_RAMTGroupDrag:IsShown() or not showmts) then
		CT_RAMTGroupMenu:Hide();
	else
		CT_RAMTGroupMenu:Show();
		CT_RAMTGroupMenu:SetWidth(CT_RAMTGroupDrag:GetWidth());
		CT_RAMTGroupMenu:SetHeight(CT_RAMTGroupDrag:GetHeight());
	end

	if (CT_RAMTGroupPlayerDrag:IsShown() or not showmtplayers) then
		CT_RAMTGroupPlayerMenu:Hide();
	else
		CT_RAMTGroupPlayerMenu:Show();
	end

	if (CT_RAMTGroupPetDrag:IsShown() or not showmtpets) then
		CT_RAMTGroupPetMenu:Hide();
	else
		CT_RAMTGroupPetMenu:Show();
	end
end

function CT_RA_MTPlayers_AttachAllMTWindows(attachTo)
	-- ----------
	-- Attach all the MT groups together by their drag frames.
	-- ----------
	if (InCombatLockdown()) then
		return;
	end

	if (not attachTo) then
		-- Use the first drag frame that is not hidden.
		for key, cGroup in ipairs(CT_RA_MTPlayers_Groups) do
			local cDrag = cGroup .. "Drag";
			local oDrag = _G[cDrag];
			if (oDrag:IsShown()) then
				attachTo = oDrag;
				break;
			end
		end
	end

	if (not attachTo) then
		return false;
	end

	local cThisDrag = attachTo:GetName();

	local nThisDragX, nThisDragY = attachTo:GetLeft(), attachTo:GetTop();
	if ( not nThisDragX or not nThisDragY ) then
		return false;
	end

	CT_RA_MTPlayers_AttachedTo = { attachTo };

	for key, cGroup in ipairs(CT_RA_MTPlayers_Groups) do
		local cDrag = cGroup .. "Drag";

		if ( cDrag ~= cThisDrag ) then
			local oDrag = _G[cDrag];
			local nDragX, nDragY = oDrag:GetLeft(), oDrag:GetTop();
			if ( nDragX and nDragY ) then
				oDrag:ClearAllPoints();
				oDrag:SetPoint("TOPLEFT", cThisDrag, "TOPLEFT", nDragX - nThisDragX, nDragY - nThisDragY);

				table.insert(CT_RA_MTPlayers_AttachedTo, oDrag);
			end
		end
	end

	return true;
end

function CT_RA_MTPlayers_UnattachAllMTWindows()
	-- ----------
	-- Unattach all the MT groups.
	-- ----------
	if (not CT_RA_MTPlayers_AttachedTo) then
		return false;
	end

	if (InCombatLockdown()) then
		return false;
	end

	local cThisDrag = CT_RA_MTPlayers_AttachedTo[1]:GetName();

	for key, cGroup in ipairs(CT_RA_MTPlayers_Groups) do
		local cDrag = cGroup .. "Drag";
		if ( cDrag ~= cThisDrag ) then
			local oDrag = _G[cDrag];
			local nDragX, nDragY = oDrag:GetLeft(), oDrag:GetTop();
			if ( nDragX and nDragY ) then
				oDrag:ClearAllPoints();
				oDrag:SetPoint("TOPLEFT", "UIParent", "TOPLEFT", nDragX, nDragY - UIParent:GetTop());
			end
		end
	end

	CT_RA_MTPlayers_AttachedTo = nil;
	return true;
end


-- ------------------------------------------------------------
-- Hooked function: CT_RA_CreateDefaultSet (from CT_RASets.lua)
-- ------------------------------------------------------------

function CT_RA_MTPlayers_CT_RA_CreateDefaultSet()
	-- --------------
	-- This function gets called instead of CT_RA_CreateDefaultSet().
	-- --------------

	-- Call the original function.
	if (CT_RA_MTPlayers_OldFunc.CT_RA_CreateDefaultSet) then
		CT_RA_MTPlayers_OldFunc.CT_RA_CreateDefaultSet();
	end

	if (CT_RA_MTPlayers_Status ~= 1) then
		return;
	end

	-- Update the "Default" option set with the default options for CT_RA_MTPlayers (if any are missing).
	-- Since the "Default" set was just created, all CT_RA_MTPlayers options are missing.
	CT_RA_MTPlayers_SetDefaultOptions(CT_RAMenu_Options["Default"]);
end


-- ------------------------------------------------------------
-- Hooked function: CT_RAMenu_LoadSet_GetValues (from CT_RASets.lua)
-- ------------------------------------------------------------

function CT_RA_MTPlayers_CT_RAMenu_LoadSet_GetValues(name)
	-- --------------
	-- This function gets called instead of CT_RAMenu_LoadSet_GetValues().
	-- --------------
	local tempOptions = CT_RAMenu_Options["temp"];

	-- Call the original function.
	if (CT_RA_MTPlayers_OldFunc.CT_RAMenu_LoadSet_GetValues) then
		CT_RA_MTPlayers_OldFunc.CT_RAMenu_LoadSet_GetValues(name);
	end

	if (CT_RA_MTPlayers_Status ~= 1) then
		return;
	end

	-- Update the "temp" option set with the default options for CT_RA_MTPlayers (if any are missing).
	-- The loaded set may not have all the options needed for CT_RA_MTPlayers.
	CT_RA_MTPlayers_SetDefaultOptions(CT_RAMenu_Options["temp"]);
end


-- ------------------------------------------------------------
-- Hooked function: CT_RA_UpdateUnitBuffs (from CT_RaidAssist.lua)
-- ------------------------------------------------------------

function CT_RA_MTPlayers_CT_RA_UpdateUnitBuffs(buffs, frame, nick)
	-- ----------
	-- This function gets called instead of CT_RA_UpdateUnitBuffs().
	-- ----------
	local tempOptions = CT_RAMenu_Options["temp"];

	-- Call the original function.
	if (CT_RA_MTPlayers_OldFunc.CT_RA_UpdateUnitBuffs) then
		CT_RA_MTPlayers_OldFunc.CT_RA_UpdateUnitBuffs(buffs, frame, nick);
	end

	if (CT_RA_MTPlayers_Status ~= 1) then
		return;
	end

	if (tempOptions["ctmtp_MTPlayers"] ~= 1) then
		return;
	end

	-- Update the person's buffs on their Main Tank Player frame.
	local num = 1;
	local frame = CT_RAMTGroupPlayer:GetAttribute("child1");
	while (frame and frame:IsShown()) do
		local raidid = frame:GetAttribute("unit");  -- unit id of tank
		if (raidid) then
			local name = CT_RA_MTPlayers_UnitName(raidid);
			if (name == nick) then
				CT_RA_MTPlayers_MTP_UpdateUnitBuffs(buffs, frame, name);
			end
		end
		num = num + 1;
		frame = CT_RAMTGroupPlayer:GetAttribute("child" .. num);
	end
end

function CT_RA_MTPlayers_MTP_UpdateUnitBuffs(buffs, frame, name)
	-- ----------
	-- Call CT_RA_UpdateUnitBuffs() for a Main Tank Player frame.
	-- ----------
	local tempOptions = CT_RAMenu_Options["temp"];

	if (CT_RA_MTPlayers_Status ~= 1) then
		return;
	end

	if (tempOptions["ctmtp_PlayerBuffs"] ~= 1) then
		-- Hide the buff and debuffs
		for j = 1, 4 do
			frame["BuffButton" .. j]:Hide();
		end
		for j = 1, 2 do
			frame["DebuffButton" .. j]:Hide();
		end
		return;
	end

	if ( tempOptions["ShowGroups"] ) then
		-- Temporarily pretend that the MT Players group is group 1, and that the option to show group 1 is enabled.
		-- This saves me from having to make a copy of the CT_RA_UpdateUnitBuffs() function and modifying it to work
		-- with the MT Players group.
		local saveparent = frame.frameParent;
		frame.frameParent = {};
		frame.frameParent.id = 1;

		local savegroup = tempOptions["ShowGroups"][frame.frameParent.id];
		tempOptions["ShowGroups"][frame.frameParent.id] = 1;

		if (CT_RA_MTPlayers_OldFunc.CT_RA_UpdateUnitBuffs) then
			CT_RA_MTPlayers_OldFunc.CT_RA_UpdateUnitBuffs(buffs, frame, name);
		end

		-- Restore the original value.
		tempOptions["ShowGroups"][frame.frameParent.id] = savegroup;
		frame.frameParent = saveparent;
	end
end


-- ------------------------------------------------------------
-- Hooked function: CT_RA_UpdateUnitDebuffs (from CT_RaidAssist.lua)
-- ------------------------------------------------------------

function CT_RA_MTPlayers_CT_RA_UpdateUnitDebuffs(debuffs, frame)
	-- ----------
	-- This function gets called instead of CT_RA_UpdateUnitDebuffs().
	-- ----------
	local tempOptions = CT_RAMenu_Options["temp"];

	-- Call the original function.
	if (CT_RA_MTPlayers_OldFunc.CT_RA_UpdateUnitDebuffs) then
		CT_RA_MTPlayers_OldFunc.CT_RA_UpdateUnitDebuffs(debuffs, frame);
	end

	if (CT_RA_MTPlayers_Status ~= 1) then
		return;
	end

	if (tempOptions["ctmtp_MTPlayers"] ~= 1) then
		return;
	end

	-- If this person is a main tank, then update their Main Tank Player frame.
	if (not frame or not frame.id) then
		return;
	end
	local raidid = "raid" .. frame.id;
	local nick = CT_RA_MTPlayers_UnitName(raidid);

	-- Update the person's debuffs on their Main Tank Player frame.
	local num = 1;
	local frame = CT_RAMTGroupPlayer:GetAttribute("child1");
	while (frame and frame:IsShown()) do
		local raidid = frame:GetAttribute("unit");  -- unit id of tank
		if (raidid) then
			local name = CT_RA_MTPlayers_UnitName(raidid);
			if (name == nick) then
				CT_RA_MTPlayers_MTP_UpdateUnitDebuffs(debuffs, frame);
			end
		end
		num = num + 1;
		frame = CT_RAMTGroupPlayer:GetAttribute("child" .. num);
	end
end

function CT_RA_MTPlayers_MTP_UpdateUnitDebuffs(debuffs, frame)
	-- ----------
	-- Call CT_RA_UpdateUnitDebuffs() for a Main Tank Player frame.
	-- ----------
	local tempOptions = CT_RAMenu_Options["temp"];

	if (tempOptions["ctmtp_PlayerBuffs"] ~= 1) then
		-- Hide the debuffs
		for j = 1, 2 do
			frame["DebuffButton" .. j]:Hide();
		end
		return;
	end

	if ( tempOptions["ShowGroups"] ) then
		-- Temporarily pretend that the MT Pets group is group 1, and that the option to show group 1 is enabled.
		-- This saves me from having to make a copy of the CT_RA_UpdateUnitBuffs() function and modifying it to work
		-- with the MT Pets group.
		local saveparent = frame.frameParent;
		frame.frameParent = {};
		frame.frameParent.id = 1;

		local savegroup = tempOptions["ShowGroups"][frame.frameParent.id];
		tempOptions["ShowGroups"][frame.frameParent.id] = 1;

		if (CT_RA_MTPlayers_OldFunc.CT_RA_UpdateUnitDebuffs) then
			CT_RA_MTPlayers_OldFunc.CT_RA_UpdateUnitDebuffs(debuffs, frame);
		end

		-- Restore the original value.
		tempOptions["ShowGroups"][frame.frameParent.id] = savegroup;
		frame.frameParent = saveparent;
	end
end






-- ------------------------------------------------------------
-- Hooked function: CT_RA_UpdateMTs (from CT_RaidAssist.lua)
-- ------------------------------------------------------------

function CT_RA_MTPlayers_CT_RA_UpdateMTs(forceUpdate)
	-- ----------
	-- This function gets called instead of CT_RA_UpdateMTs().
	-- ----------
	local tempOptions = CT_RAMenu_Options["temp"];

	-- Call the original function first
	if (CT_RA_MTPlayers_OldFunc.CT_RA_UpdateMTs) then
		CT_RA_MTPlayers_OldFunc.CT_RA_UpdateMTs(forceUpdate);
	end

	if (CT_RA_MTPlayers_Status == 1) then
		-- Handle the Main Tank Players and Pets
		CT_RA_MTPlayers_EK_RA_UpdateMTPs(forceUpdate);
	end
end

function CT_RA_MTPlayers_EK_RA_UpdateMTPs(forceUpdate)
	-- ----------
	-- Update the Main Tank Players.
	-- This is a heavily modified copy of CT_RA_UpdateMTs().
	-- ----------
	local tempOptions = CT_RAMenu_Options["temp"];
	local alphaRange = tempOptions.AlphaRange;
	CT_RA_MTPlayers_UpdateMenuFrames();

	local CT_RA_MainTanks = CT_RA_MainTanks;

	if (tempOptions["ctmtp_MTPlayers"] == 1) then
		local num = 1;
		local frame = CT_RAMTGroupPlayer:GetAttribute("child1");
		while (frame and frame:IsShown()) do
			local val;
			local frameParent = frame.frameParent;
			local raidid = frame:GetAttribute("unit");  -- unit id of tank
			if (raidid) then
				val = CT_RA_MTPlayers_UnitName(raidid);
				if ( val ) then
					local mtid = raidid:match("^(%a+%d+)");

					local name = (CT_RA_MTPlayers_UnitName(raidid) or "");
					local hpmax = UnitHealthMax(raidid);
					local mpmax = UnitPowerMax(raidid);
					local hppercent;
					local mppercent;
					if (hpmax and hpmax ~= 0) then
						hppercent = UnitHealth(raidid)/hpmax;
					else
						hppercent = -1;
					end
					if (mpmax and mpmax ~= 0) then
						mppercent = UnitPower(raidid)/mpmax;
					else
						mppercent = -1;
					end

					local stats, isFD, isDead, isAFK, isRessed, isOnline;
					stats, isFD, isDead = CT_RA_Stats[name], false, false;
					if ( UnitIsGhost(raidid) or UnitIsDead(raidid) ) then
						isFD = CT_RA_CheckFD(name, raidid)
						isDead = ( isFD == 0 );
					end
					if (stats) then
						isAFK = (stats["AFK"] ~= nil);
						isRessed = stats["isRessed"] or false;
					else
						isAFK = false;
						isRessed = false;
					end
					isOnline = UnitIsConnected(raidid) or false;

					if (
						forceUpdate
						or name ~= ( frame.unitName or "" )
						or hppercent ~= ( frame.hppercent or -1 )
						or mppercent ~= ( frame.mppercent or -1 )
						or isOnline ~= frame.ekisOnline  -- not UnitIsConnected(raidid)
						or isFD ~= frame.ekisFD
						or isDead ~= frame.ekisDead
						or isAFK ~= frame.ekisAFK
						or isRessed ~= frame.ekisRessed
					) then
--[[
						if ( not isOnline ) then  -- UnitIsConnected(raidid) ) then
							frame.unitName = nil;
							frame.hppercent = nil;
							frame.mppercent = nil;
							frame.ekisOnline = nil;
							frame.ekisFD = nil;
							frame.ekisDead = nil;
							frame.ekisAFK = nil;
							frame.ekisRessed = nil;
						else
--]]
							frame.unitName = name;
							frame.hppercent = hppercent;
							frame.mppercent = mppercent;
							frame.ekisOnline = isOnline;
							frame.ekisFD = isFD;
							frame.ekisDead = isDead;
							frame.ekisAFK = isAFK;
							frame.ekisRessed = isRessed;
--						end
						CT_RA_MTPlayers_EK_RA_UpdateMTP(raidid, mtid, frame, val, false);
					elseif (alphaRange) then
						frame:SetAlpha(CT_RA_UnitAlpha(raidid, nil));
						CT_RA_UpdateRaidTargetIcon(frame, raidid);
					end
				end
			end
			num = num + 1;
			frame = CT_RAMTGroupPlayer:GetAttribute("child" .. num);
		end
	end

	if (tempOptions["ctmtp_MTPets"] == 1) then
		local num = 1;
		local frame = CT_RAMTGroupPet:GetAttribute("child1");
		while (frame and frame:IsShown()) do
			local val;
			local raidid = frame:GetAttribute("unit");  -- unit id of tank
			if (raidid) then
				val = CT_RA_MTPlayers_UnitName(raidid);
			end
			if ( val ) then
				local frameParent = frame.frameParent;
				local raidid = frame.unit;  -- unit id of tank's pet
				if ( raidid ) then
					local mtid = raidid:match("^(%a+%d+)");

					local name = (CT_RA_MTPlayers_UnitName(raidid) or "");
					local hpmax = UnitHealthMax(raidid);
					local mpmax = UnitPowerMax(raidid);
					local hppercent;
					local mppercent;
					if (hpmax and hpmax ~= 0) then
						hppercent = UnitHealth(raidid)/hpmax;
					else
						hppercent = -1;
					end
					if (mpmax and mpmax ~= 0) then
						mppercent = UnitPower(raidid)/mpmax;
					else
						mppercent = -1;
					end

					local isDead, isOnline;
					if ( UnitIsGhost(raidid) or UnitIsDead(raidid) ) then
						isDead = true;
					else
						isDead = false;
					end
					isOnline = UnitIsConnected(raidid) or false;
					if (
						forceUpdate
						or name ~= ( frame.unitName or "" )
						or hppercent ~= ( frame.hppercent or -1 )
						or mppercent ~= ( frame.mppercent or -1 )
						or isOnline ~= frame.ekisOnline  -- not UnitIsConnected(raidid)
						or isDead ~= frame.ekisDead
					) then
--[[
						if ( not isOnline ) then  -- UnitIsConnected(raidid) ) then
							frame.unitName = nil;
							frame.hppercent = nil;
							frame.mppercent = nil;
							frame.ekisOnline = nil;
							frame.ekisDead = nil;
						else
--]]
							frame.unitName = name;
							frame.hppercent = hppercent;
							frame.mppercent = mppercent;
							frame.ekisOnline = isOnline;
							frame.ekisDead = isDead;
--						end
						CT_RA_MTPlayers_EK_RA_UpdateMTP(raidid, mtid, frame, val, true);
					elseif (alphaRange) then
						frame:SetAlpha(CT_RA_UnitAlpha(raidid, nil));
						CT_RA_UpdateRaidTargetIcon(frame, raidid);
					end
				end
			end
			num = num + 1;
			frame = CT_RAMTGroupPet:GetAttribute("child" .. num);
		end
	end
end

function CT_RA_MTPlayers_EK_RA_UpdateMTP(raidid, mtid, frame, val, isPet)
	-- ----------
	-- Update a Main Tank Player or Pet
	-- ----------
	local tempOptions = CT_RAMenu_Options["temp"];

	-- Call a modified copy of the standard CT_RA_UpdateMT() to udpate name, health, mana, height, width, etc.
	CT_RA_MTPlayers_EK_RA_UpdateMT(raidid, mtid, frame, val, isPet);

	if (isPet) then
		return;
	end

	if (tempOptions["ctmtp_MTPlayers"] ~= 1) then
		return;
	end

	-- Update the Main Tank Players buffs and debuffs.
	local id = frame.id;
	if ( not id ) then
		return;
	end
	local name = CT_RA_MTPlayers_UnitName("raid" .. id);
	local stats = CT_RA_Stats[name];
	if ( stats ) then
		CT_RA_MTPlayers_MTP_UpdateUnitBuffs(stats["Buffs"], frame, name);
	end
end

function CT_RA_MTPlayers_EK_RA_UpdateMT(raidid, mtid, frame, val, isPet)
	-- ----------
	-- Update a Main Tank Player/Pet's health, etc.
	-- This is a modified copy of CT_RA_UpdateMT() (from CT_RaidAssist.lua)
	-- ----------
	local tempOptions = CT_RAMenu_Options["temp"];
	local frameName = frame.name;
	local mtwidth, ptwidth, height = CT_RA_GetMTFrameData();
	local alpha;

	if (not InCombatLockdown()) then
		frame:SetWidth(mtwidth); frame:SetHeight(height);
	end

	local defaultColors = tempOptions.DefaultColor;
	frame:SetBackdropColor(defaultColors.r, defaultColors.g, defaultColors.b, defaultColors.a);

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
	if ( raidid and UnitExists(raidid) and strlen(CT_RA_MTPlayers_UnitName(raidid) or "") > 0 ) then
		local health, healthmax, mana, manamax = UnitHealth(raidid), UnitHealthMax(raidid), UnitPower(raidid), UnitPowerMax(raidid);

		frame.Name:SetHeight(15);
		frame.Status:Hide();
		frame.HPBar:Show();
		frame.HPBG:Show();
-- &&		frame.MPBar:Show();
-- &&		frame.MPBG:Show();
		frame.Name:Show();

		local manaType = UnitPowerType(raidid);
		if ( ( manaType == 0 and not tempOptions["HideMP"] ) or ( manaType > 0 and not tempOptions["HideRP"] and (UnitIsPlayer(raidid) or isPet) ) ) then
			local manaTbl = PowerBarColor[manaType];
			frame.MPBar:SetStatusBarColor(manaTbl.r, manaTbl.g, manaTbl.b);
			frame.MPBG:SetVertexColor(manaTbl.r, manaTbl.g, manaTbl.b, (tempOptions["BGOpacity"] or 0.4));
			frame.MPBar:SetMinMaxValues(0, manamax);
			frame.MPBar:SetValue(mana);
-- &&		else
-- &&			frame.MPBar:Hide();
-- &&			frame.MPBG:Hide();
		end

		local _, class = UnitClass(raidid);
		-- && This "if...end" copied from CT_RA_UpdateUnitDead() and modified.
		if ( not CT_RA_HideClassManaBar(class) ) then
			frame.MPBar:Show();
			frame.MPBG:Show();
-- &&			if ( canShowInfo ) then
-- &&				frame.Percent:Show();
-- &&			else
-- &&				frame.Percent:Hide();
-- &&			end
		else
			frame.MPBar:Hide();
			frame.MPBG:Hide();
		end

		frame.Status:Hide();

		local stats, isFD, isDead;
		if (not isPet) then
			local name = (CT_RA_MTPlayers_UnitName(raidid));
			stats, isFD, isDead = CT_RA_Stats[name], false, false;
			if ( UnitIsGhost(raidid) or UnitIsDead(raidid) ) then
				isFD = CT_RA_CheckFD(name, raidid)
				if ( isFD == 0 ) then
					isDead = 1;
				end
			end
		else
			if ( UnitIsGhost(raidid) or UnitIsDead(raidid) ) then
				isDead = 1;
			end
		end

		if ( not UnitIsConnected(raidid) ) then
			frame.HPBar:Hide();
			frame.HPBG:Hide();
			frame.Percent:Hide();
			frame.MPBar:Hide();
			frame.MPBG:Hide();
			frame.Status:Show();
			frame.Status:SetText("OFFLINE");
			frame.status = "offline";

		elseif ( isFD == 1 or isFD == 2 ) then
			frame.HPBar:Hide();
			frame.HPBG:Hide();
			frame.Percent:Hide();
			frame.MPBar:Hide();
			frame.MPBG:Hide();
			frame.Status:Show();
			if ( isFD == 1 ) then
				frame.Status:SetText("Feign Death");
				frame.status = "feigndeath";
			elseif ( isFD == 2 ) then
				frame.Status:SetText("SoR");
				frame.status = "spiritofredemption";
			end

		elseif ( stats and stats["Ressed"] ) then
			frame.HPBar:Hide();
			frame.HPBG:Hide();
			frame.Percent:Hide();
			frame.MPBar:Hide();
			frame.MPBG:Hide();
			frame.Status:Show();
			if ( stats["Ressed"] == 1 ) then
				frame.Status:SetText("Resurrected");
			elseif ( stats["Ressed"] == 2 ) then
				frame.Status:SetText("SS Available");
			else
				frame.Status:SetText("Resurrected");
			end
			frame.status = "resurrected";

		elseif ( isDead ) then
			frame.HPBar:Hide();
			frame.HPBG:Hide();
			frame.Percent:Hide();
			frame.MPBar:Hide();
			frame.MPBG:Hide();
			frame.Status:Show();
			frame.Status:SetText("DEAD");
			frame.status = "dead";

		elseif ( stats and stats["AFK"] and tempOptions["ShowAFK"] ) then
			frame.HPBar:Hide();
			frame.HPBG:Hide();
			frame.Percent:Hide();
			frame.MPBar:Hide();
			frame.MPBG:Hide();
			frame.Status:Show();
			frame.Status:SetText("AFK");
			frame.status = "afk";

		elseif ( health and healthmax and not UnitIsDead(raidid) and not UnitIsGhost(raidid) ) then
			-- && The following code was copied from the CT_RA_UpdateUnitHealth() function and modified:
			local showHP = tempOptions["ShowHP"];
			local memberHeight = 40;  -- && tempOptions["MemberHeight"];
			local maxHealth = healthmax;
			local percent;
			if (maxHealth == 0) then
				percent = 0;
			else
				percent = floor(health / maxHealth * 100);
			end
			frame.HPBar:SetMinMaxValues(0, healthmax);
			frame.HPBar:SetValue(health);
			frame.Percent:Show();

			frame.status = nil;

			if ( showHP and showHP == 1 and maxHealth and memberHeight == 40 ) then
				if (maxHealth == 0) then
					frame.Percent:SetText(0 .. "/" .. maxHealth);
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
					frame.Percent:SetText(health .. "/" .. mxHealth);
				end
			elseif ( showHP and showHP == 2 and memberHeight == 40 ) then
				frame.Percent:SetText(percent .. "%");
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
					frame.Percent:SetText(diff);
				else
					frame.Percent:SetText(percent-100 .. "%");
				end
			else
				frame.Percent:Hide();
			end
			local hppercent = percent/100;
			if ( hppercent >= 0 and hppercent <= 1 ) then
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
				frame.HPBar:SetStatusBarColor(r, g, 0);
				frame.HPBG:SetVertexColor(r, g, 0, (tempOptions["BGOpacity"] or 0.4));
			end
			alpha = CT_RA_UnitAlpha(raidid, percent);
		else
			frame.status = nil;

			frame.HPBar:Hide();
			frame.HPBG:Hide();
		end
		frame.Name:SetText(CT_RA_MTPlayers_UnitName(raidid));
-- &&		if ( UnitCanAttack("player", raidid) ) then
-- &&			frame.Name:SetTextColor(1, 0.5, 0);
-- &&		else
			frame.Name:SetTextColor(0.5, 1, 0);
-- &&		end
		frame.unitName = CT_RA_MTPlayers_UnitName(raidid);
	else
		frame.Percent:Hide();
		frame.HPBar:Hide();
		frame.HPBG:Hide();
		frame.MPBar:Hide();
		frame.MPBG:Hide();
		frame.Status:Hide();
		frame.status = nil;
		if (isPet) then
			frame.Name:SetText(val .. "'s Pet");
		else
			frame.Name:SetText(val);  -- &&   .. "'s Target");
		end
		frame.Name:SetHeight(30);
		frame.Name:SetTextColor(1, 0.82, 0);
		-- frame:SetBackdropColor(0.3, 0.3, 0.3, 1);
	end

	if (frame.status) then
		frame:SetBackdropColor(0.3, 0.3, 0.3, 1);
	end
	if (not alpha) then
		alpha = CT_RA_UnitAlpha(raidid, nil);
	end
	frame:SetAlpha(alpha);
	CT_RA_UpdateRaidTargetIcon(frame, raidid);
end


-- ------------------------------------------------------------
-- Hooked function: CT_RA_UpdateRaidFrames (from CT_RaidAssist.lua)
-- ------------------------------------------------------------

function CT_RA_MTPlayers_CT_RA_UpdateRaidFrames()
	-- ----------
	-- This function gets called instead of CT_RA_UpdateRaidFrames().
	-- ----------
	local tempOptions = CT_RAMenu_Options["temp"];

	-- Call the original function first
	if (CT_RA_MTPlayers_OldFunc.CT_RA_UpdateRaidFrames) then
		CT_RA_MTPlayers_OldFunc.CT_RA_UpdateRaidFrames();
	end

	if (CT_RA_MTPlayers_Status ~= 1) then
		return;
	end

	if (CT_RA_MTPlayers_Status == 1) then
		-- Handle the Main Tank Players and Pets
		CT_RA_MTPlayers_EK_RA_UpdateRaidFrames()
	end
end

function CT_RA_MTPlayers_EK_RA_UpdateRaidFrames()
	-- ----------
	-- This is a modified copy of CT_RA_UpdateRaidFrames().
	-- ----------
	if (InCombatLockdown()) then
		return;
	end

	local showmts, showmtplayers, showmtpets = CT_RA_MTPlayers_GetShowStatus();

	local tempOptions = CT_RAMenu_Options["temp"];
	local numRaidMembers = CT_RA_NumRaidMembers;

	local showGroups = tempOptions["ShowGroups"];
	local lockGroups = tempOptions["LockGroups"];
	local hideNames = tempOptions["HideNames"];


	if (showmtplayers) then
		-- Main Tank Players
		if ( numRaidMembers > 0 and next(CT_RA_MainTanks) ) then
			CT_RAMTGroupPlayer:Show();
			if ( hideNames ) then
				CT_RAMTGroupPlayer.GroupName:Hide();
			else
				CT_RAMTGroupPlayer.GroupName:Show();
			end

			if ( lockGroups ) then
				CT_RAMTGroupPlayerDrag:Hide();
			else
				CT_RAMTGroupPlayerDrag:Show();
			end
		else
			CT_RAMTGroupPlayer:Hide();
			CT_RAMTGroupPlayerDrag:Hide();
		end
	else
		CT_RAMTGroupPlayer:Hide();
		CT_RAMTGroupPlayerDrag:Hide();
	end

	if (showmtpets) then
		-- Main Tank Pets
		if ( numRaidMembers > 0 and next(CT_RA_MainTanks) ) then
			local foundPet;

			CT_RAMTGroupPet:Show();

-- Can't do this with secure frames, since the SecureGroupHeader is in control
-- of showing and hiding group member frames.
--
--			if (tempOptions["ctmtp_PlayerHasNoPet"] == 1) then
--				-- Hide pet boxes for players that don't have a pet.
--				local num = 1;
--				local frame = CT_RAMTGroupPet:GetAttribute("child1");
--				while (frame and frame:IsShown()) do
--					local raidid = frame.unit;  -- unit id of tank's pet
--					if (raidid) then
--						if (UnitExists(raidid)) then
--							foundPet = 1;
--							frame:Show();
--						else
--							frame:Hide();
--						end
--					else
--						frame:Hide();
--					end
--					num = num + 1;
--					frame = CT_RAMTGroupPet:GetAttribute("child" .. num);
--				end
--			end

			if ( hideNames ) then
				CT_RAMTGroupPet.GroupName:Hide();
			else
				CT_RAMTGroupPet.GroupName:Show();
			end

			if ( lockGroups ) then
				CT_RAMTGroupPetDrag:Hide();
			else
				CT_RAMTGroupPetDrag:Show();
			end
		else
			CT_RAMTGroupPet:Hide();
			CT_RAMTGroupPetDrag:Hide();
		end
	else
		CT_RAMTGroupPet:Hide();
		CT_RAMTGroupPetDrag:Hide();
	end


end


-- ------------------------------------------------------------
-- Modified copy of function: prepareFrame (from CT_RaidAssist.lua)
-- ------------------------------------------------------------

-- Locally bound frame cache
local frameCache = CT_RA_Cache;

local function prepareFrame2(splitView, showmts, showmtplayers, showmtpets)
	local ord, pos, grp, grpDis, grpVis;
	local ancPos, ancGrp, ancDrag;

	local mtwidth, ptwidth, height = CT_RA_GetMTFrameData();

	local tempOptions = CT_RAMenu_Options["temp"];
	local showMTT = (tempOptions["ShowMTTT"] or false);
	local hideBorder = tempOptions["HideBorder"];

	-- Positions of the groups if they are all shown.
	-- Position 1 == left, 2 == middle, 3 == right.
	-- Group 1 == Target, 2 == Player, 3 == Pet.
	-- ord == Array of group numbers (subscript == position, value == group number).
	-- pos == Array of positions (subscript == group, value == position).
	if (tempOptions["ctmtp_SidePlayer"] == 0) then
		if (tempOptions["ctmtp_SidePet"] == 0) then
			if (tempOptions["ctmtp_SidePetPlayer"] == 0) then
				ord = {3,2,1}; -- Pet, Player, Target
				pos = {3,2,1};
			else
				ord = {2,3,1}; -- Player, Pet, Target
				pos = {3,1,2};
			end
		else
			ord = {2,1,3}; -- Player, Target, Pet
			pos = {2,1,3};
		end
	else
		if (tempOptions["ctmtp_SidePet"] == 1) then
			if (tempOptions["ctmtp_SidePetPlayer"] == 0) then
				ord = {1,3,2}; -- Target, Pet, Player
				pos = {1,3,2};
			else
				ord = {1,2,3}; -- Target, Player, Pet
				pos = {1,2,3};
			end
		else
			ord = {3,1,2}; -- Pet, Target, Player
			pos = {2,3,1};
		end
	end

	-- Determine which group the others will anchor to.
	if (CT_RA_MTPlayers_AnchorToGroup) then
		local ancTo = CT_RA_MTPlayers_AnchorToGroup;
		if (ancTo == 1 and showmts) then
			ancGrp = 1;
		elseif (ancTo == 2 and showmtplayers) then
			ancGrp = 2;
		elseif (ancTo == 3 and showmtpets) then
			ancGrp = 3;
		end
	end

	if (not ancGrp) then
		if (showmts) then
			-- Anchor to the Targets group
			ancGrp = 1;
		elseif (showmtplayers) then
			-- Anchor to the Players group
			ancGrp = 2;
		elseif (showmtpets) then
			-- Anchor to the Pets group
			ancGrp = 3;
		else
			-- Nothing visible, so anchor to the Players group.
			ancGrp = 2;
		end
	end

	ancDrag = _G[CT_RA_MTPlayers_Groups[ancGrp] .. "Drag"];

	-- Establish visibility of each group.
	grpVis = { showmts, showmtplayers, showmtpets };

	-- Pretend the anchor group is visible (for the purpose of determining distances from the anchor).
	-- The ony time the anchor group won't be visible, is when all of the groups are not visible.
	grpVis[ancGrp] = 1;

	-- Determine the position (1,2,3) of the anchor group.
	ancPos = pos[ancGrp];

	-- Determine the distance of each group to the anchor.
	-- The anchor will have a distance value of 0.
	-- 1 frame to the left of the anchor is a distance value of -1, etc.
	-- 1 frame to the right of the anchor is a distance value of 1, etc.
	grpDis = {};
	grpDis[ancGrp] = 0;
	local d = 0;
	for p = ancPos - 1, 1, -1 do
		-- If the group in the previous position (ie. to the right) was visible, then change the value of d.
		-- If it wasn't visible, then we want this group to sit on top of the previous one.
		if (grpVis[ord[p+1]]) then
			d = d - 1;
		end
		-- Save the distance from the anchor to this group.
		grpDis[ord[p]] = d;
	end
	d = 0;
	for p = ancPos + 1, 3, 1 do
		-- If the group in the previous position (ie. to the left) was visible, then change the value of d.
		-- If it wasn't visible, then we want this group to sit on top of the previous one.
		if (grpVis[ord[p-1]]) then
			d = d + 1;
		end
		-- Save the distance from the anchor to this group.
		grpDis[ord[p]] = d;
	end


	local grp, attach, relFrame, offset;

	-- Set which group we are using.
	grp = splitView;

	if (tempOptions["ctmtp_LockJoined"] == 1 and grp ~= ancGrp) then
		local width = mtwidth;
		if (hideBorder) then
			if (tempOptions["ctmtp_GapHide"] == 1) then
				width = width - 10;
			end
		end
		offset = width * grpDis[grp];
		if (grp == 1 or ancGrp == 1) then
			-- Anchoring the Targets group to a non-Targets group, or vice versa.
			-- If Targets Targets are visible, then we need to further adjust the offset by half of the frame width.
			if (showMTT) then
				local adjust = width / 2;
				if (offset < 0) then
					offset = offset - adjust;
				else
					offset = offset + adjust;
				end
			end
		end

		relFrame = ancDrag;
		attach = 1;
	end

	return attach, relFrame, offset, ancGrp;
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

local function prepareFrame(frame, dragFrame, template, initFunction, title, splitView, useModifier, showmts, showmtplayers, showmtpets)
	-- splitview: 1 == MT Target, 2 == MT Player, 3 == MT Pet
	local tempOptions = CT_RAMenu_Options["temp"];
	local numRaidMembers = CT_RA_NumRaidMembers;

	local showReversed = tempOptions["ShowReversed"];
	local showHorizontal = splitView == nil and tempOptions["ShowHorizontal"];
	local hideBorder = tempOptions["HideBorder"];
	local removeSpace = hideBorder and tempOptions["HideSpace"];

	if ( splitView ~= 1 and not frame.init ) then
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

	if (splitView ~= 1) then
		-- Change this attribute each time in case something has changed.
		frame:SetAttribute("initialConfigFunction", initFunction(frame) );
	end

--	local splitOffset = ( hideBorder and 5 ) or 0;

	local point1;
	if ( showReversed ) then
		point1 = "BOTTOM";
	else
		point1 = "TOP";
		if (splitView ~= 1) then
			frame:SetAttribute("sortDir", "ASC");
		end
	end

	local attach, relFrame, offset, ancGrp = prepareFrame2(splitView, showmts, showmtplayers, showmtpets);

	frame:SetAttribute("point", point1);

	if (not (CT_RA_MTPlayers_AttachedTo or CT_RA_MTPlayers_DragAll or dragFrame.ekdragMode)) then
		if (attach) then
			if (splitView ~= ancGrp) then
				CT_RA_MTPlayers_SavePoint[splitView] = { dragFrame, relFrame, point1, offset, 0 };
			end

			offset = offset * (tempOptions["MTScaling"] or 1);

			-- Anchor one group to the other using their drag frames.
			dragFrame:ClearAllPoints();
			dragFrame:SetPoint("CENTER", relFrame, "CENTER", offset, 0);

			-- Re-anchor the drag frame relative to the UIParent.
			local t = dragFrame:GetTop();
			local l = dragFrame:GetLeft();
			if (t and l) then
				dragFrame:ClearAllPoints();
				dragFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", l, t);
			end
		else
			-- Re-anchor the drag frame relative to the UIParent.
			local t = dragFrame:GetTop();
			local l = dragFrame:GetLeft();
			if (t and l) then
				dragFrame:ClearAllPoints();
				dragFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", l, t);
			end
		end
	end

	if (splitView == 1) then
		return;
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

	if ( showReversed ) then
		frame:ClearAllPoints();
		frame:SetPoint("BOTTOM", dragFrame, "BOTTOM", 0, 14);
	else
		frame:ClearAllPoints();
		frame:SetPoint("TOP", dragFrame, "TOP", 0, -14);
	end

	return frame;
end

local function CT_RA_prepareMTPlayersAndPets()
	-- Prepare Main Tank Players and Main Tank Pets
	if (InCombatLockdown()) then
		return;
	end

	local showmts, showmtplayers, showmtpets = CT_RA_MTPlayers_GetShowStatus();

	local tempOptions = CT_RAMenu_Options["temp"];
	local showMTT = (tempOptions["ShowMTTT"] or false);
	local sortMTs = tempOptions["SortMTs"];
	local numRaidMembers = CT_RA_NumRaidMembers;
	local frame;
	local list, num, obj;

	-- Build a comma separate list of the Main Tank names.
	list = "";
	num = 0;
-- &&	if ( not tempOptions["HideMTs"] ) then
	if ( showmts or showmtplayers or showmtpets ) then
		for i = 1, 10, 1 do
			obj = CT_RA_MainTanks[i];
			if ( obj ) then
				list = list .. obj .. ",";
				num = num + 1;
				if ( num == (tempOptions["ShowNumMTs"] or 10)) then
					break;
				end
			end
		end
		list = strsub(list, 0, -2);
	end

	CT_RA_MTPlayers_SavePoint = {};  -- This will be updated by prepareFrame()

	-- Main Tank Players
--	if (showmtplayers) then
		frame = CT_RAMTGroupPlayer;

	        local oldIgnore = frame:GetAttribute("_ignore");
	        frame:SetAttribute("_ignore", "attributeChanges");

		prepareFrame(frame, CT_RAMTGroupPlayerDrag, "CT_RAMTMemberTemplate", CT_RA_SetupMTFrame, "MT Players", 2, "", showmts, showmtplayers, showmtpets);
		if (sortMTs) then
			frame:SetAttribute("sortMethod", "NAME");
		else
			frame:SetAttribute("sortMethod", "NAMELIST");
		end
		frame:SetAttribute("nameList", list);

	        frame:SetAttribute("_ignore", oldIgnore);
	        frame:SetAttribute("_update", frame:GetAttribute("_update"));

		CT_RA_preparePreCreate(frame);
--	end

	-- Main Tank Pets
--	if (showmtpets) then
		frame = CT_RAMTGroupPet;

	        local oldIgnore = frame:GetAttribute("_ignore");
	        frame:SetAttribute("_ignore", "attributeChanges");

		prepareFrame(frame, CT_RAMTGroupPetDrag, "CT_RAMTMemberTemplate", CT_RA_SetupMTFrame, "MT Pets", 3, "pet", showmts, showmtplayers, showmtpets);
		if (sortMTs) then
			frame:SetAttribute("sortMethod", "NAME");
		else
			frame:SetAttribute("sortMethod", "NAMELIST");
		end
		frame:SetAttribute("nameList", list);

	        frame:SetAttribute("_ignore", oldIgnore);
	        frame:SetAttribute("_update", frame:GetAttribute("_update"));

		CT_RA_preparePreCreate(frame);
--	end

	-- Main Tank Targets (drag frame)
--	if (not showmts) then
		-- This prepareFrame call is just to position the MT Targets drag frame. Populating it with names will be done
		-- by the original function, which gets called when we return from here.
		-- We're passing a 1 as the splitView value, rather than the -1 or 1 that the original CT_RaidAssist code passed.
		prepareFrame(CT_RAMTGroup, CT_RAMTGroupDrag, "CT_RAMTMemberTemplate", CT_RA_SetupMTFrame, "MT Targets", 1, "target", showmts, showmtplayers, showmtpets);
--	end

	CT_RA_MTPlayers_AnchorToGroup = nil;
end

-- ------------------------------------------------------------
-- Hooked function: CT_RA_UpdateRaidFrameData (from CT_RaidAssist.lua)
-- ------------------------------------------------------------

function CT_RA_MTPlayers_CT_RA_UpdateRaidFrameData()
	-- ----------
	-- This function gets called instead of CT_RA_UpdateRaidFrameData().
	-- ----------
	local tempOptions = CT_RAMenu_Options["temp"];

	if (CT_RA_MTPlayers_Status == 1) then
		-- Handle the Main Tank Players and Pets
		CT_RA_MTPlayers_EK_RA_UpdateRaidFrameData()
	end

	-- Call the original function.
	if (CT_RA_MTPlayers_OldFunc.CT_RA_UpdateRaidFrameData) then
		CT_RA_MTPlayers_OldFunc.CT_RA_UpdateRaidFrameData();
	end

end

function CT_RA_MTPlayers_EK_RA_UpdateRaidFrameData()
	-- ----------
	-- This is a modified copy of CT_RA_UpdateRaidFrameData().
	-- ----------
	if (InCombatLockdown()) then
		return;
	end

	-- Main Tank Players and Main Tank Pets
	CT_RA_prepareMTPlayersAndPets();
end


-- ------------------------------------------------------------
-- Hooked function: CT_RA_UpdateRaidFrameOptions (from CT_RaidAssist.lua)
-- ------------------------------------------------------------

function CT_RA_MTPlayers_CT_RA_UpdateRaidFrameOptions()
	-- ----------
	-- This function gets called instead of CT_RA_UpdateRaidFrameOptions().
	-- ----------
	local tempOptions = CT_RAMenu_Options["temp"];

	if (CT_RA_MTPlayers_Status == 1) then
		-- Handle the Main Tank Players and Pets
		CT_RA_MTPlayers_EK_RA_UpdateRaidFrameOptions()
	end

	-- Call the original function.
	if (CT_RA_MTPlayers_OldFunc.CT_RA_UpdateRaidFrameOptions) then
		CT_RA_MTPlayers_OldFunc.CT_RA_UpdateRaidFrameOptions();
	end
end

function CT_RA_MTPlayers_EK_RA_UpdateRaidFrameOptions()
	-- ----------
	-- This is a modified copy of CT_RA_UpdateRaidFrameOptions().
	-- ----------
	if (InCombatLockdown()) then
		return;
	end

	-- Main Tank Players and Main Tank Pets
	CT_RA_prepareMTPlayersAndPets();
end


-- ------------------------------------------------------------
-- Hooked function: CT_RAMenuMisc_OnUpdate (from CT_RAMenu.lua)
-- ------------------------------------------------------------

function CT_RA_MTPlayers_CT_RAMenuMisc_OnUpdate(self, elapsed)
	-- ----------
	-- This function gets called instead of CT_RAMenuMisc_OnUpdate().
	-- ----------
	local tempOptions = CT_RAMenu_Options["temp"];

	if (CT_RA_MTPlayers_Status ~= 1) then
		if (CT_RA_MTPlayers_OldFunc.CT_RAMenuMisc_OnUpdate) then
			CT_RA_MTPlayers_OldFunc.CT_RAMenuMisc_OnUpdate(self, elapsed);
		end
		return;
	end

	-- Handle the Main Tank Players and Pets
	CT_RA_MTPlayers_EK_RAMenuMisc_OnUpdate(self, elapsed)
end

function CT_RA_MTPlayers_EK_RAMenuMisc_OnUpdate(self, elapsed)
	-- ----------
	-- This is a modified copy of CT_RA_UpdateRaidFrameOptions().
	-- ----------
	local tempOptions = CT_RAMenu_Options["temp"];
	local newScaling = (tempOptions["MTScaling"] or 1);

	local scaleupdate;
	if ( self.scaleupdate ) then

		local temp = self.scaleupdate - elapsed;
		if ( temp <= 0 ) then

			scaleupdate = true;
			if ( tempOptions["MTScaling"] ) then
--				local newScaling = (tempOptions["MTScaling"] or 1);
				local mtwidth, ptwidth, height = CT_RA_GetMTFrameData();
-- &&
--[[
				CT_RAMTGroup:SetScale(newScaling);
				CT_RAMTTGroup:SetScale(newScaling);
				CT_RAPTGroup:SetScale(newScaling);
				CT_RAPTTGroup:SetScale(newScaling);
				CT_RAMTGroupDrag:SetWidth(mtwidth*newScaling);
				CT_RAMTGroupDrag:SetHeight(height*newScaling/2);
				CT_RAPTGroupDrag:SetWidth(ptwidth*newScaling);
				CT_RAPTGroupDrag:SetHeight(height*newScaling/2);
]]

				if (not InCombatLockdown()) then
					CT_RAMTGroupPlayer:SetScale(newScaling);
					CT_RAMTGroupPet:SetScale(newScaling);

					CT_RAMTGroupPlayerDrag:SetWidth(mtwidth*newScaling);
					CT_RAMTGroupPlayerDrag:SetHeight(height*newScaling/2);
					CT_RAMTGroupPlayerMenu:SetWidth(mtwidth*newScaling);
					CT_RAMTGroupPlayerMenu:SetHeight(height*newScaling/2);

					CT_RAMTGroupPetDrag:SetWidth(mtwidth*newScaling);
					CT_RAMTGroupPetDrag:SetHeight(height*newScaling/2);
					CT_RAMTGroupPetMenu:SetWidth(mtwidth*newScaling);
					CT_RAMTGroupPetMenu:SetHeight(height*newScaling/2);
				end
			end

		end
	end

	if (CT_RA_MTPlayers_OldFunc.CT_RAMenuMisc_OnUpdate) then
		CT_RA_MTPlayers_OldFunc.CT_RAMenuMisc_OnUpdate(self, elapsed);
	end

	CT_RAMTGroupMenu:SetWidth(CT_RAMTGroupDrag:GetWidth());
	CT_RAMTGroupMenu:SetHeight(CT_RAMTGroupDrag:GetHeight());

	if (InCombatLockdown()) then
		return;
	end

	if (not self.ekscaleupdate) then
		self.ekscaleupdate = 1;
	end
	self.ekscaleupdate = self.ekscaleupdate - elapsed;
	if (self.ekscaleupdate <= 0) then
		self.ekscaleupdate = 1;

		if (not (CT_RA_MTPlayers_AttachedTo or CT_RA_MTPlayers_DragAll)) then
			for k, v in ipairs(CT_RA_MTPlayers_SavePoint) do
				local drag = v[1];
				if (not drag.ekdragMode) then
					drag:ClearAllPoints();
					drag:SetPoint(v[3], v[2], v[3], v[4] * newScaling, v[5]);

					-- Re-anchor the drag frame relative to the UIParent.
					local t = drag:GetTop();
					local l = drag:GetLeft();
					if (t and l) then
						drag:ClearAllPoints();
						drag:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", l, t);
					end
				end
			end
		end
	end
end


-- ------------------------------------------------------------
-- Hooked function: CT_RAMenuAdditional_ScalingMT_OnValueChanged (from CT_RAMenu.lua)
-- ------------------------------------------------------------

function CT_RA_MTPlayers_CT_RAMenuAdditional_ScalingMT_OnValueChanged(self)
	-- ----------
	-- This function gets called instead of CT_RA_UpdateRaidFrameOptions().
	-- ----------
	local tempOptions = CT_RAMenu_Options["temp"];

	-- Call the original function.
	if (CT_RA_MTPlayers_OldFunc.CT_RAMenuAdditional_ScalingMT_OnValueChanged) then
		CT_RA_MTPlayers_OldFunc.CT_RAMenuAdditional_ScalingMT_OnValueChanged(self);
	end

	if (CT_RA_MTPlayers_Status ~= 1) then
		return;
	end

	-- Handle the Main Tank Players and Pets
	CT_RA_MTPlayers_EK_RAMenuAdditional_ScalingMT_OnValueChanged(self)
end

function CT_RA_MTPlayers_EK_RAMenuAdditional_ScalingMT_OnValueChanged(self)
	-- ----------
	-- This is a modified copy of CT_RAMenuAdditional_ScalingMT_OnValueChanged().
	-- ----------
	local tempOptions = CT_RAMenu_Options["temp"];

	local newScaling = (tempOptions["MTScaling"] or 1);
	local mtwidth, ptwidth, height = CT_RA_GetMTFrameData();

--[[
	CT_RAMTGroup:SetScale(newScaling);
	CT_RAMTTGroup:SetScale(newScaling);
	CT_RAPTGroup:SetScale(newScaling);
	CT_RAPTTGroup:SetScale(newScaling);
	CT_RAMTGroupDrag:SetWidth(mtwidth*newScaling);
	CT_RAMTGroupDrag:SetHeight(height*newScaling/2);
	CT_RAPTGroupDrag:SetWidth(ptwidth*newScaling);
	CT_RAPTGroupDrag:SetHeight(height*newScaling/2);
]]


	if (not InCombatLockdown()) then
		CT_RAMTGroupPlayer:SetScale(newScaling);
		CT_RAMTGroupPet:SetScale(newScaling);

		CT_RAMTGroupPlayerDrag:SetWidth(mtwidth*newScaling);
		CT_RAMTGroupPlayerDrag:SetHeight(height*newScaling/2);
		CT_RAMTGroupPlayerMenu:SetWidth(mtwidth*newScaling);
		CT_RAMTGroupPlayerMenu:SetHeight(height*newScaling/2);

		CT_RAMTGroupPetDrag:SetWidth(mtwidth*newScaling);
		CT_RAMTGroupPetDrag:SetHeight(height*newScaling/2);
		CT_RAMTGroupPetMenu:SetWidth(mtwidth*newScaling);
		CT_RAMTGroupPetMenu:SetHeight(height*newScaling/2);
	end

	CT_RAMTGroupMenu:SetWidth(CT_RAMTGroupDrag:GetWidth());
	CT_RAMTGroupMenu:SetHeight(CT_RAMTGroupDrag:GetHeight());

	if (InCombatLockdown()) then
		return;
	end

	if (not (CT_RA_MTPlayers_AttachedTo or CT_RA_MTPlayers_DragAll)) then
		for k, v in ipairs(CT_RA_MTPlayers_SavePoint) do
			local drag = v[1];
			if (not drag.ekdragMode) then
				drag:ClearAllPoints();
				drag:SetPoint(v[3], v[2], v[3], v[4] * newScaling, v[5]);

				-- Re-anchor the drag frame relative to the UIParent.
				local t = drag:GetTop();
				local l = drag:GetLeft();
				if (t and l) then
					drag:ClearAllPoints();
					drag:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", l, t);
				end
			end
		end
	end
end


-- ------------------------------------------------------------
-- Hooked script: OnMouseDown for the drag frames (from CT_RaidAssist.xml)
-- ------------------------------------------------------------

local dropdownInitialized;

function CT_RA_MTPlayers_CT_RAMTGroupDragOnMouseDown(self, button)
	-- ----------
	-- Mouse button pressed on a drag frame.
	--
	-- Called instead of the OnMouseDown </Script> code for CT_RAMTGroupDrag
	-- which is inherited from CT_RAGroupDragTemplate.
	--
	-- The original function is called at the end if the
	-- event is still unhandled.
	-- ----------
	local tempOptions = CT_RAMenu_Options["temp"];
	local mtdrag, mtmenu;
	local cFrame;

	if (CT_RA_MTPlayers_Status ~= 1) then
		-- Call original function.
		if (CT_RA_MTPlayers_OldFunc.CT_RAMTGroupDragOnMouseDown) then
			CT_RA_MTPlayers_OldFunc.CT_RAMTGroupDragOnMouseDown();
		end
		return;
	end

	cFrame = self:GetName();

	if (cFrame == "CT_RAMTGroupPlayerMenu") then
		mtmenu = 1;
		CT_RA_MTPlayers_MenuFrameNum = 2;
	elseif (cFrame == "CT_RAMTGroupPetMenu") then
		mtmenu = 1;
		CT_RA_MTPlayers_MenuFrameNum = 3;
	elseif (cFrame == "CT_RAMTGroupMenu") then
		mtmenu = 1;
		CT_RA_MTPlayers_MenuFrameNum = 1;
	else
		cFrame = self:GetName();
		for key, val in ipairs(CT_RA_MTPlayers_Groups) do
			if (cFrame == val .. "Drag") then
				mtdrag = 1;
				CT_RA_MTPlayers_MenuFrameNum = key;
				break;
			end
		end
	end

	if (button == "LeftButton") then
		if (mtdrag) then
			local dragMode;

			if (CT_RA_MTPlayers_AttachedTo) then
				-- The groups are attached together, which means that
				-- the user wants to keep them joined, and we are in
				-- combat lockdown (or we are about to be).

				-- Only allow the user to drag the "attached to" group.
				if (CT_RA_MTPlayers_AttachedTo[1]:GetName() == cFrame) then
					dragMode = 2;
				else
					-- Don't allow this drag frame to be dragged.
					return;
				end

			-- The groups are not attached together. Either the user wants
			-- to keep them unjoined, or we are not in combat lockdown.

			elseif (tempOptions["ctmtp_LockJoined"] == 1) then
				dragMode = 2;   -- Drag all MT windows at the same time.

			elseif (IsShiftKeyDown()) then
				if (InCombatLockdown()) then
					dragMode = 1;   -- Drag individual group.
				else
					dragMode = 2;   -- Drag all MT windows at the same time.
				end
			else
				dragMode = 1;   -- Drag individual group.
			end

			if (dragMode) then
				self.ekdragMode = dragMode;

				if (dragMode == 2) then
					CT_RA_MTPlayers_DragAll = 1;
					if (not CT_RA_MTPlayers_AttachedTo) then
						-- We are not currently in combat lockdown (and we are not about to be).
						CT_RA_MTPlayers_AttachAllMTWindows(self);
					end
					self:StartMoving();
					return;

				elseif (dragMode == 1) then
					self:StartMoving();
					return;
				end
			end
		end

	elseif (button == "RightButton") then
		if (mtdrag or mtmenu) then

			if (CT_RA_MTPlayers_DragAll or self.ekdragMode) then
				-- Don't open menu while user is dragging the frame.
				return;
			end

			local oDrop = CT_RA_MTPlayers_DropDown;
			local cFrame = self:GetName();
			if (not dropdownInitialized) then
				CT_RA_MTPlayers_DropDown_OnLoad(oDrop);
				dropdownInitialized = true;
			end
			L_ToggleDropDownMenu(1, nil, oDrop, cFrame, 47, 15);
			return;
		end
	end

	if (mtmenu) then
		return;
	end

	-- Call original function.
	if (CT_RA_MTPlayers_OldFunc.CT_RAMTGroupDragOnMouseDown) then
		CT_RA_MTPlayers_OldFunc.CT_RAMTGroupDragOnMouseDown();
	end
end



-- ------------------------------------------------------------
-- Hooked script: OnMouseUp for the drag frames (from CT_RaidAssist.xml)
-- ------------------------------------------------------------

function CT_RA_MTPlayers_CT_RAMTGroupDragOnMouseUp(self, button)
	-- ----------
	-- Mouse button released on a drag frame.
	--
	-- Called instead of the OnMouseUp </Script> code for CT_RAMTGroupDrag
	-- which is inherited from CT_RAGroupDragTemplate.
	--
	-- The original function is called at the end if the
	-- event is still unhandled.
	-- ----------
	local tempOptions = CT_RAMenu_Options["temp"];
	local mtdrag;
	local cFrame;

	if (CT_RA_MTPlayers_Status ~= 1) then
		-- Call original function.
		if (CT_RA_MTPlayers_OldFunc.CT_RAMTGroupDragOnMouseUp) then
			CT_RA_MTPlayers_OldFunc.CT_RAMTGroupDragOnMouseUp();
		end
		return;
	end

	cFrame = self:GetName();
	for key, val in ipairs(CT_RA_MTPlayers_Groups) do
		if (cFrame == val .. "Drag") then
			mtdrag = 1;
			break;
		end
	end

	if ( button == "LeftButton" ) then

		if (mtdrag) then

			if ( CT_RA_MTPlayers_AttachedTo ) then
				-- Was dragging all groups.
				self:StopMovingOrSizing();
				self.ekdragMode = nil;
				CT_RA_MTPlayers_DragAll = nil;
				if (not InCombatLockdown()) then
					CT_RA_MTPlayers_UnattachAllMTWindows();
					CT_RA_UpdateRaidFrameData();
					CT_RA_UpdateMTs(true);
				end
				CT_RAMenu_SaveWindowPositions();
				return;
			end

			-- Was dragging a single group.
			self:StopMovingOrSizing();
			self.ekdragMode = nil;
			if (tempOptions["ctmtp_AlignToTitle"] == 1) then
				CT_RA_MTPlayers_Update_AlignToTitle(self);
			end
			CT_RAMenu_SaveWindowPositions();
			return;
		end
	end

	-- Call original function.
	if (CT_RA_MTPlayers_OldFunc.CT_RAMTGroupDragOnMouseUp) then
		CT_RA_MTPlayers_OldFunc.CT_RAMTGroupDragOnMouseUp();
	end
end



-- ------------------------------------------------------------
-- Hooked function: CT_RA_Drag_OnEnter (from CT_RaidAssist.lua)
-- ------------------------------------------------------------

function CT_RA_MTPlayers_CT_RA_Drag_OnEnter(oFrame)
	-- ----------
	-- Mouse is over a drag frame.
	--
	-- Called instead of CT_RA_Drag_OnEnter().
	--
	-- Calls the original function first, then
	-- tests for player/pet/target drag frames
	-- in order to customize the tooltip.
	-- ----------
	local tempOptions = CT_RAMenu_Options["temp"];
	local mtdrag, mtmenu;
	local cFrame;

--	if (not oFrame) then
--		oFrame = this;
--	end

	-- Call the original function.
	if (CT_RA_MTPlayers_OldFunc.CT_RA_Drag_OnEnter) then
		CT_RA_MTPlayers_OldFunc.CT_RA_Drag_OnEnter(oFrame);
	end

	if (CT_RA_MTPlayers_Status ~= 1) then
		return;
	end

	cFrame = oFrame:GetName();

	if (cFrame == "CT_RAMTGroupPlayerMenu") then
		mtmenu = 1;
	elseif (cFrame == "CT_RAMTGroupPetMenu") then
		mtmenu = 1;
	elseif (cFrame == "CT_RAMTGroupMenu") then
		mtmenu = 1;
	else
		for key, val in ipairs(CT_RA_MTPlayers_Groups) do
			if (cFrame == val .. "Drag") then
				mtdrag = 1;
				break;
			end
		end
	end

	if (mtmenu or mtdrag) then
		local xp = "LEFT";
		local yp = "BOTTOM";
		local xo = 0;
		local yo = -15;
		local xthis, ythis = oFrame:GetCenter();
		local xui, yui = UIParent:GetCenter();
		if ( xthis < xui ) then
			xp = "RIGHT";
		end
		if ( ythis < yui ) then
			yp = "TOP";
			yo = 15;
		end
		GameTooltip:SetOwner(oFrame, "ANCHOR_" .. yp .. xp, xo, yo);

--		CT_RAMenuHelp_SetTooltip(oFrame);

		if (mtdrag) then
			-- MT Players, pets, targets

			-- If the MT groups are attached to each other...
			if (CT_RA_MTPlayers_AttachedTo) then
				-- If we are in combat lockdown mode...
				if (InCombatLockdown()) then
					-- Only allow the user to drag the "attached to" group.
					if (CT_RA_MTPlayers_AttachedTo[1]:GetName() == cFrame) then
						GameTooltip:AddLine(CT_RA_MTPlayers_TEXT_Click_Drag_All);
					end
				else
					-- Not in combat lockdown mode, so user can drag any of the groups.
					GameTooltip:AddLine(CT_RA_MTPlayers_TEXT_Click_Drag_All);
				end
			else
				-- MT groups are not attached together.
				-- If user is keeping the groups joined together...
				if (tempOptions["ctmtp_LockJoined"] == 1) then
					-- Show the "click to drag all" line.
					GameTooltip:AddLine(CT_RA_MTPlayers_TEXT_Click_Drag_All);
				else
					-- User is keeping the groups independent.
					GameTooltip:AddLine(CT_RA_MTPlayers_TEXT_Click_Drag);
					if (not InCombatLockdown()) then
						GameTooltip:AddLine(CT_RA_MTPlayers_TEXT_Shift_Click_Drag_All);
					end
				end
			end

			-- If not dragging frame(s), then allow the right click menu.
			if (not (CT_RA_MTPlayers_DragAll or oFrame.ekdragMode)) then
				GameTooltip:AddLine(CT_RA_MTPlayers_TEXT_Right_Click_Menu);
			end
		else
			-- This is not a drag frame. Show just the right click line for opening the menu.
			GameTooltip:AddLine(CT_RA_MTPlayers_TEXT_Right_Click_Menu);
		end

--		GameTooltip:FadeOut();
		GameTooltip:Show();
	end
end


-- ------------------------------------------------------------
-- Drop down menu functions:
-- ------------------------------------------------------------


function CT_RA_MTPlayers_DropDown_OnLoad(self)
	-- ----------
	-- Initialize drop down menu when it is loaded.
	-- ----------
	L_UIDropDownMenu_Initialize(self, CT_RA_MTPlayers_DropDown_InitButtons, "MENU");
end


function CT_RA_MTPlayers_DropDown_OnClick(self)
	-- ----------
	-- User clicked on a drop down menu item.
	-- ----------
	local tempOptions = CT_RAMenu_Options["temp"];

	if ( self.value == "showplayers" ) then
		CT_RA_MTPlayers_Set_Players();

	elseif ( self.value == "hidemtandplayers" ) then
		CT_RA_MTPlayers_Set_HideMTAndPlayers();

	elseif ( self.value == "showplayerbuffs" ) then
		CT_RA_MTPlayers_Set_PlayerBuffs();

	elseif ( self.value == "showpets" ) then
		CT_RA_MTPlayers_Set_Pets();

	elseif ( self.value == "hidemtandpets" ) then
		CT_RA_MTPlayers_Set_HideMTAndPets();

	elseif ( self.value == "lock_joined" ) then
		if (not InCombatLockdown()) then
			if (tempOptions["ctmtp_LockJoined"] == 0) then
				CT_RA_MTPlayers_AnchorToGroup = CT_RA_MTPlayers_MenuFrameNum;
			end
			CT_RA_MTPlayers_Set_LockJoined(); -- nil == Toggle
		end

	elseif ( self.value == "side_player" ) then
		CT_RA_MTPlayers_Set_SidePlayer();

	elseif ( self.value == "side_pet" ) then
		CT_RA_MTPlayers_Set_SidePet();

	elseif ( self.value == "side_petplayer" ) then
		CT_RA_MTPlayers_Set_SidePetPlayer();

	elseif ( self.value == "group_has_no_pet" ) then
		CT_RA_MTPlayers_Set_GroupHasNoPet();

--	elseif ( self.value == "player_has_no_pet" ) then
--		CT_RA_MTPlayers_Set_PlayerHasNoPet();

	elseif ( self.value == "align_to_title" ) then
		CT_RA_MTPlayers_Set_AlignToTitle();

	elseif ( self.value == "toggle_mtt") then
		if (not InCombatLockdown()) then
			-- Toggle MT Targets
			tempOptions["HideMTs"] = not tempOptions["HideMTs"];
			if (CT_RAMenuFrameGeneralMiscShowMTsCB) then
				CT_RAMenuFrameGeneralMiscShowMTsCB:SetChecked(not tempOptions["HideMTs"]);
			end
			CT_RA_UpdateRaidFrameData();
			CT_RA_UpdateMTs(true);
		end

	elseif ( self.value == "toggle_mttt") then
		if (not InCombatLockdown()) then
			-- Toggle MT Targets Targets
			if (tempOptions["ShowMTTT"]) then
				tempOptions["ShowMTTT"] = nil;
			else
				tempOptions["ShowMTTT"] = 1;
			end
			if (CT_RAMenuFrameMiscDisplayShowMTTTCB) then
				CT_RAMenuFrameMiscDisplayShowMTTTCB:SetChecked(tempOptions["ShowMTTT"]);
			end
			CT_RA_UpdateRaidFrameData();
			CT_RA_UpdateMTs(true);
		end

	elseif ( self.value == "hide_gap" ) then
		CT_RA_MTPlayers_Set_GapHide()

	end
end


function CT_RA_MTPlayers_DropDown_InitButtons(self)
	-- ----------
	-- Initialize drop down menu buttons.
	-- ----------
	local tempOptions = CT_RAMenu_Options["temp"];
	local dropdown, info;
	local keepShownOnClick = nil;

	-- x Show Targets group
	-- x    Show Targets Targets group
	-- x Show Players group
	-- x    Hide when Targets are hidden
	-- x    Show buffs/debuffs
	-- x Show Pets group
	-- x    Hide when Targets are hidden
	-- x    Hide group if there are no pets
	-- x    Hide box if player has no pet
	-- x Join the groups together
	-- x    Show Players to right of Targets
	-- x    Show Pets to right of Targets
	-- x    Show Pets to right of Players
	-- x    No gap when border is hidden
	-- x Align to title after dragging

	info = {};
	info.text = "MT Groups";
	info.isTitle = 1;
	info.justifyH = "CENTER";
	info.notCheckable = 1;
	L_UIDropDownMenu_AddButton(info);

	info = { };
	info.text = CT_RA_MTPlayers_TEXT_Menu_Show_MTTargets;
	info.func = CT_RA_MTPlayers_DropDown_OnClick;
	info.value = "toggle_mtt";
	info.notCheckable = nil;
	if (not tempOptions["HideMTs"]) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.keepShownOnClick = keepShownOnClick;
	if (InCombatLockdown()) then
		info.disabled = 1;
	end
	L_UIDropDownMenu_AddButton(info);

	info = { };
	info.text = "    " .. CT_RA_MTPlayers_TEXT_Menu_Show_MTTTargets;
	info.func = CT_RA_MTPlayers_DropDown_OnClick;
	info.value = "toggle_mttt";
	info.notCheckable = nil;
	if (tempOptions["ShowMTTT"]) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.keepShownOnClick = keepShownOnClick;
	if (tempOptions["HideMTs"]) then
		info.disabled = 1;
	end
	if (InCombatLockdown()) then
		info.disabled = 1;
	end
	L_UIDropDownMenu_AddButton(info);

	info = { };
	info.text = CT_RA_MTPlayers_TEXT_Menu_Show_MTPlayers;
	info.func = CT_RA_MTPlayers_DropDown_OnClick;
	info.value = "showplayers";
	info.notCheckable = nil;
	if ( tempOptions["ctmtp_MTPlayers"] == 1 ) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.keepShownOnClick = keepShownOnClick;
	if (InCombatLockdown()) then
		info.disabled = 1;
	end
	L_UIDropDownMenu_AddButton(info);

	info = { };
	info.text = "    " .. CT_RA_MTPlayers_TEXT_Menu_Hide_MTAndPlayers;
	info.func = CT_RA_MTPlayers_DropDown_OnClick;
	info.value = "hidemtandplayers";
	info.notCheckable = nil;
	if ( tempOptions["ctmtp_HideMTAndPlayers"] == 1 ) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.keepShownOnClick = keepShownOnClick;
	if (tempOptions["ctmtp_MTPlayers"] ~= 1) then
		info.disabled = 1;
	end
	if (InCombatLockdown()) then
		info.disabled = 1;
	end
	L_UIDropDownMenu_AddButton(info);

	info = { };
	info.text = "    " .. CT_RA_MTPlayers_TEXT_Menu_Show_PlayerBuffs;
	info.func = CT_RA_MTPlayers_DropDown_OnClick;
	info.value = "showplayerbuffs";
	info.notCheckable = nil;
	if ( tempOptions["ctmtp_PlayerBuffs"] == 1 ) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.keepShownOnClick = keepShownOnClick;
	if (tempOptions["ctmtp_MTPlayers"] ~= 1) then
		info.disabled = 1;
	end
	L_UIDropDownMenu_AddButton(info);

	info = { };
	info.text = CT_RA_MTPlayers_TEXT_Menu_Show_MTPets;
	info.func = CT_RA_MTPlayers_DropDown_OnClick;
	info.value = "showpets";
	info.notCheckable = nil;
	if (tempOptions["ctmtp_MTPets"] == 1) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.keepShownOnClick = keepShownOnClick;
	if (InCombatLockdown()) then
		info.disabled = 1;
	end
	L_UIDropDownMenu_AddButton(info);

	info = { };
	info.text = "    " .. CT_RA_MTPlayers_TEXT_Menu_Hide_MTAndPets;
	info.func = CT_RA_MTPlayers_DropDown_OnClick;
	info.value = "hidemtandpets";
	info.notCheckable = nil;
	if ( tempOptions["ctmtp_HideMTAndPets"] == 1 ) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.keepShownOnClick = keepShownOnClick;
	if (tempOptions["ctmtp_MTPets"] ~= 1) then
		info.disabled = 1;
	end
	if (InCombatLockdown()) then
		info.disabled = 1;
	end
	L_UIDropDownMenu_AddButton(info);

	info = { };
	if (tempOptions["ctmtp_GroupHasNoPet"] == 1) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.text = "    " .. CT_RA_MTPlayers_TEXT_Menu_Hide_Group_No_Pets;
	info.func = CT_RA_MTPlayers_DropDown_OnClick;
	info.value = "group_has_no_pet";
	info.notCheckable = nil;
	info.keepShownOnClick = keepShownOnClick;
	if (tempOptions["ctmtp_MTPets"] ~= 1) then
		info.disabled = 1;
	end
	if (InCombatLockdown()) then
		info.disabled = 1;
	end
	L_UIDropDownMenu_AddButton(info);

--	info = { };
--	if (tempOptions["ctmtp_PlayerHasNoPet"] == 1) then
--		info.checked = 1;
--	else
--		info.checked = nil;
--	end
--	info.text = "    " .. CT_RA_MTPlayers_TEXT_Menu_Hide_Box_No_Pets;
--	info.func = CT_RA_MTPlayers_DropDown_OnClick;
--	info.value = "player_has_no_pet";
--	info.notCheckable = nil;
--	info.keepShownOnClick = keepShownOnClick;
--	if (tempOptions["ctmtp_MTPets"] ~= 1) then
--		info.disabled = 1;
--	end
--	if (InCombatLockdown()) then
--		info.disabled = 1;
--	end
--	L_UIDropDownMenu_AddButton(info);

	info = { };
	if (tempOptions["ctmtp_LockJoined"] == 1) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.text = CT_RA_MTPlayers_TEXT_Menu_Join_MTGroups;
	info.func = CT_RA_MTPlayers_DropDown_OnClick;
	info.value = "lock_joined";
	info.notCheckable = nil;
	info.keepShownOnClick = keepShownOnClick;
	if (InCombatLockdown()) then
		info.disabled = 1;
	end
	L_UIDropDownMenu_AddButton(info);

	info = { };
	if (tempOptions["ctmtp_SidePlayer"] == 1) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.text = "    " .. CT_RA_MTPlayers_TEXT_Menu_Side_Player;
	info.func = CT_RA_MTPlayers_DropDown_OnClick;
	info.value = "side_player";
	info.notCheckable = nil;
	info.keepShownOnClick = keepShownOnClick;
	if (tempOptions["ctmtp_LockJoined"] ~= 1) then
		info.disabled = 1;
	end
	if (InCombatLockdown()) then
		info.disabled = 1;
	end
	L_UIDropDownMenu_AddButton(info);

	info = { };
	if (tempOptions["ctmtp_SidePet"] == 1) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.text = "    " .. CT_RA_MTPlayers_TEXT_Menu_Side_Pet;
	info.func = CT_RA_MTPlayers_DropDown_OnClick;
	info.value = "side_pet";
	info.notCheckable = nil;
	info.keepShownOnClick = keepShownOnClick;
	if (tempOptions["ctmtp_LockJoined"] ~= 1) then
		info.disabled = 1;
	end
	if (InCombatLockdown()) then
		info.disabled = 1;
	end
	L_UIDropDownMenu_AddButton(info);

	info = { };
	if (tempOptions["ctmtp_SidePetPlayer"] == 1) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.text = "    " .. CT_RA_MTPlayers_TEXT_Menu_Side_PetPlayer;
	info.func = CT_RA_MTPlayers_DropDown_OnClick;
	info.value = "side_petplayer";
	info.notCheckable = nil;
	info.keepShownOnClick = keepShownOnClick;
	if (tempOptions["ctmtp_LockJoined"] ~= 1) then
		info.disabled = 1;
	end
	if (InCombatLockdown()) then
		info.disabled = 1;
	end
	L_UIDropDownMenu_AddButton(info);

	info = { };
	if (tempOptions["ctmtp_GapHide"] == 1) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.text = "    " .. CT_RA_MTPlayers_TEXT_Menu_Hide_Gap;
	info.func = CT_RA_MTPlayers_DropDown_OnClick;
	info.value = "hide_gap";
	info.notCheckable = nil;
	info.keepShownOnClick = keepShownOnClick;
	if (tempOptions["ctmtp_LockJoined"] ~= 1) then
		info.disabled = 1;
	end
	if (InCombatLockdown()) then
		info.disabled = 1;
	end
	L_UIDropDownMenu_AddButton(info);

	info = { };
	if (tempOptions["ctmtp_AlignToTitle"] == 1) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.text = CT_RA_MTPlayers_TEXT_Menu_Align_To_Title;
	info.func = CT_RA_MTPlayers_DropDown_OnClick;
	info.value = "align_to_title";
	info.notCheckable = nil;
	info.keepShownOnClick = keepShownOnClick;
	if (tempOptions["ctmtp_LockJoined"] == 1) then
		info.disabled = 1;
	end
	L_UIDropDownMenu_AddButton(info);

	info = { };
	info.text = CT_RA_MTPlayers_TEXT_Menu_Close;
	info.func = function()
		L_CloseDropDownMenus()
	end;
	info.arg1 = 1;
	info.notCheckable = 1;
	L_UIDropDownMenu_AddButton(info);
end


-- ------------------------------------------------------------
-- Hooked function: CT_RA_UpdateRaidMovability (from CT_RaidAssist.lua)
-- ------------------------------------------------------------

function CT_RA_MTPlayers_CT_RA_UpdateRaidMovability()
	-- ----------
	-- This function gets called instead of CT_RA_UpdateRaidMovability().
	-- ----------
	local tempOptions = CT_RAMenu_Options["temp"];

	-- Call the original function.
	if (CT_RA_MTPlayers_OldFunc.CT_RA_UpdateRaidMovability) then
		CT_RA_MTPlayers_OldFunc.CT_RA_UpdateRaidMovability();
	end

	if (CT_RA_MTPlayers_Status ~= 1) then
		return;
	end

	if (InCombatLockdown()) then
		return;
	end

	local showmts, showmtplayers, showmtpets = CT_RA_MTPlayers_GetShowStatus();

	if ( tempOptions["LockGroups"] or (not showmtplayers) ) then
		CT_RAMTGroupPlayerDrag:Hide();
	else
		for i = 1, 10, 1 do
			if ( CT_RA_MainTanks[i] ) then
				CT_RAMTGroupPlayerDrag:Show();
				break;
			else
				CT_RAMTGroupPlayerDrag:Hide();
			end
		end
	end

	if ( tempOptions["LockGroups"] or (not showmtpets) ) then
		CT_RAMTGroupPetDrag:Hide();
	else
		for i = 1, 10, 1 do
			if ( CT_RA_MainTanks[i] ) then
				CT_RAMTGroupPetDrag:Show();
				break;
			else
				CT_RAMTGroupPetDrag:Hide();
			end
		end
	end
end


-- ------------------------------------------------------------
-- Hooked function: CT_RAMenu_General_ResetWindows (from CT_RAMenu.lua)
-- ------------------------------------------------------------

function CT_RA_MTPlayers_CT_RAMenu_General_ResetWindows()
	-- ----------
	-- This function gets called instead of CT_RAMenu_General_ResetWindows().
	-- ----------
	local tempOptions = CT_RAMenu_Options["temp"];

	if (InCombatLockdown()) then
		return;
	end

	-- Call the original function.
	if (CT_RA_MTPlayers_OldFunc.CT_RAMenu_General_ResetWindows) then
		CT_RA_MTPlayers_OldFunc.CT_RAMenu_General_ResetWindows();
	end

	if (CT_RA_MTPlayers_Status ~= 1) then
		return;
	end

	CT_RA_MTPlayers_Set_LockJoined(0); -- 0 == Unjoin the MT Players and MT Pets frames before we reset their positions.

	CT_RAMTGroupPlayerDrag:ClearAllPoints();
	CT_RAMTGroupPetDrag:ClearAllPoints();

	local x, y;
	local left, top, uitop = CT_RAMTGroupDrag:GetLeft(), CT_RAMTGroupDrag:GetTop(), UIParent:GetTop();
	if ( left and top and uitop ) then
		x = left;
		y = (top - uitop) - 240;
	else
		x = 570;
		y = -375;
	end
	CT_RAMTGroupPlayerDrag:SetPoint("TOPLEFT", "UIParent", "TOPLEFT", x, y);
	CT_RAMTGroupPetDrag:SetPoint("TOPLEFT", "UIParent", "TOPLEFT", x - 95, y);

	CT_RAMenu_SaveWindowPositions();
end


-- ------------------------------------------------------------
-- Hooked function: CT_RA_UpdateRaidGroupColors (from CT_RaidAssist.lua)
-- ------------------------------------------------------------

function CT_RA_MTPlayers_CT_RA_UpdateRaidGroupColors()
	-- ----------
	-- This function gets called instead of CT_RA_UpdateRaidGroupColors().
	-- ----------
	local tempOptions = CT_RAMenu_Options["temp"];

	-- Call the original function.
	if (CT_RA_MTPlayers_OldFunc.CT_RA_UpdateRaidGroupColors) then
		CT_RA_MTPlayers_OldFunc.CT_RA_UpdateRaidGroupColors();
	end

	if (CT_RA_MTPlayers_Status ~= 1) then
		return;
	end

	local defaultColor = tempOptions["DefaultColor"];
	local percentColor = tempOptions["PercentColor"];

	local y = 1;
	local member = CT_RAMTGroupPlayer:GetAttribute("child1");
	while (member) do
		local raidid = member:GetAttribute("unit");
		if ( not member.status ) then
			member:SetBackdropColor(defaultColor.r, defaultColor.g, defaultColor.b, defaultColor.a);
		end
		member.Percent:SetTextColor(percentColor.r, percentColor.g, percentColor.b);
		if ( raidid and UnitExists(raidid) ) then
			local name = CT_RA_MTPlayers_UnitName(raidid);
			if ( CT_RA_Stats[name] ) then
				CT_RA_MTPlayers_MTP_UpdateUnitBuffs(CT_RA_Stats[name]["Buffs"], member, name);
			end
		end
		y = y + 1;
		member = CT_RAMTGroupPlayer:GetAttribute("child".. y);
	end

	local y = 1;
	local member = CT_RAMTGroupPet:GetAttribute("child1");
	while (member) do
		local raidid = member.unit;
		if ( not member.status ) then
			member:SetBackdropColor(defaultColor.r, defaultColor.g, defaultColor.b, defaultColor.a);
		end
		member.Percent:SetTextColor(percentColor.r, percentColor.g, percentColor.b);
		y = y + 1;
		member = CT_RAMTGroupPet:GetAttribute("child".. y);
	end
end


-- ------------------------------------------------------------
-- Hooked function: CT_RAMenu_SaveWindowPositions (from CT_RAMenu.lua)
-- ------------------------------------------------------------

function CT_RA_MTPlayers_CT_RAMenu_SaveWindowPositions()
	-- ----------
	-- This function gets called instead of CT_RAMenu_SaveWindowPositions().
	-- ----------
	local tempOptions = CT_RAMenu_Options["temp"];

	-- Call the original function.
	if (CT_RA_MTPlayers_OldFunc.CT_RAMenu_SaveWindowPositions) then
		CT_RA_MTPlayers_OldFunc.CT_RAMenu_SaveWindowPositions();
	end

	if (CT_RA_MTPlayers_Status ~= 1) then
		return;
	end

	tempOptions["ctmtp_WindowPositions"] = { };
	local left, top, uitop;

	left, top, uitop = CT_RAMTGroupPlayerDrag:GetLeft(), CT_RAMTGroupPlayerDrag:GetTop(), UIParent:GetTop();
	if ( left and top and uitop ) then
		tempOptions["ctmtp_WindowPositions"]["CT_RAMTGroupPlayerDrag"] = { left, top-uitop };
	end

	left, top, uitop = CT_RAMTGroupPetDrag:GetLeft(), CT_RAMTGroupPetDrag:GetTop(), UIParent:GetTop();
	if ( left and top and uitop ) then
		tempOptions["ctmtp_WindowPositions"]["CT_RAMTGroupPetDrag"] = { left, top-uitop };
	end
end


-- ------------------------------------------------------------
-- Hooked function: CT_RAMenu_UpdateWindowPositions (from CT_RAMenu.lua)
-- ------------------------------------------------------------

function CT_RA_MTPlayers_CT_RAMenu_UpdateWindowPositions()
	-- ----------
	-- This function gets called instead of CT_RAMenu_UpdateWindowPositions().
	-- ----------
	local tempOptions = CT_RAMenu_Options["temp"];

	-- Call the original function.
	if (CT_RA_MTPlayers_OldFunc.CT_RAMenu_UpdateWindowPositions) then
		CT_RA_MTPlayers_OldFunc.CT_RAMenu_UpdateWindowPositions();
	end

	if (CT_RA_MTPlayers_Status ~= 1) then
		return;
	end

	if (InCombatLockdown()) then
		return;
	end

	if ( tempOptions["ctmtp_WindowPositions"] ) then
		for k, v in pairs(tempOptions["ctmtp_WindowPositions"]) do
			local oFrame = _G[k];
			if (oFrame) then
				oFrame:ClearAllPoints();
				oFrame:SetPoint("TOPLEFT" , "UIParent", "TOPLEFT", v[1], v[2]);
			end
		end
	end
end


-- ------------------------------------------------------------
-- Hooked function: CT_RA_MemberFrame_OnEnter (from CT_RaidAssist.lua)
-- ------------------------------------------------------------

function CT_RA_MTPlayers_CT_RA_MemberFrame_OnEnter(self)
	local tempOptions = CT_RAMenu_Options["temp"];
	local parent = self.frameParent;
	local id = self.id;
	local cFrame = parent.name;

	local oldFunc = true;
	if (CT_RA_MTPlayers_Status == 1) then
		-- Addon is enabled.
		if (strsub(cFrame, 1, 15) == "CT_RAMTGroupPet" ) then
			oldFunc = false;
		end
	end
	if (oldFunc) then
		-- Call the original function.
		if (CT_RA_MTPlayers_OldFunc.CT_RA_MemberFrame_OnEnter) then
			CT_RA_MTPlayers_OldFunc.CT_RA_MemberFrame_OnEnter(self);
		end
		return;
	end

	local name;
	if ( CT_RA_MainTanks[id] ) then
		name = CT_RA_MainTanks[id];
	end
	for i = 1, CT_RA_MTPlayers_GetNumRaidMembers(), 1 do
		local memberName = GetRaidRosterInfo(i);
		if ( name == memberName ) then
			id = i;
			break;
		end
	end

	local unitid = "raidpet"..id;

	if ( SpellIsTargeting() ) then
		SetCursor("CAST_CURSOR");
	end
	if ( SpellIsTargeting() and not SpellCanTargetUnit(unitid) ) then
		SetCursor("CAST_ERROR_CURSOR");
	end
	if ( tempOptions["HideTooltip"] ) then
		return;
	end

	if (not UnitExists(unitid)) then
		return;
	end

	local pname, rank, subgroup, level, class, fileName, zone, online, isDead = GetRaidRosterInfo(id);

	name = CT_RA_MTPlayers_UnitName(unitid);
	if (not name) then
		name = "";
	end
	if (name == "") then
		name = pname;
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

	local race, ctype, color, text;

	level = UnitLevel(unitid);
	if (not level) then
		level = 0;
	end
	if (level == 0) then
		level = "?";
	end

	class = UnitClass(unitid);  -- eg. Mage
	if (class) then
		fileName = string.upper(class);  -- eg. MAGE
	else
		fileName = "";
	end

	race = UnitCreatureFamily(unitid);  -- eg. "Imp"
	ctype = UnitCreatureType(unitid);  -- eg. "Demon"
	if (not race) then
		race = ctype;
		ctype = nil;
	end

	color = RAID_CLASS_COLORS[fileName];
	if ( not color ) then
		color = { ["r"] = 1, ["g"] = 1, ["b"] = 1 };
	end
	GameTooltip:AddDoubleLine(name, level, color.r, color.g, color.b, 1, 1, 1);

	text = "";
	if (race) then
		text = race;
	end
	if (class) then
		if (text ~= "") then
			text = text .. " ";
		end
		text = text .. class;
	end
	if (text ~= "") then
		GameTooltip:AddLine(text, 1, 1, 1);
	end

	if (ctype) then
		GameTooltip:AddLine(ctype, 1, 1, 1);
	end

	if (UnitIsDead(unitid)) then
		GameTooltip:AddLine("Dead");
	end

	GameTooltip:Show();
	CT_RA_CurrentMemberFrame = self;
end

