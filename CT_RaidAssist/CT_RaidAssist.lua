------------------------------------------------
--            CT_RaidAssist (CTRA)            --
--                                            --
-- Provides features to assist raiders incl.  --
-- customizable raid frames.  CTRA was the    --
-- original raid frame in Vanilla (pre 1.11)  --
-- but has since been re-written completely   --
-- to integrate with the more modern UI.      --
--                                            --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
--					      --
-- Original credits to Cide and TS            --
-- Improved by Dargen circa late Vanilla      --
-- Maintained by Resike from 2014 to 2017     --
-- Rebuilt by Dahk Celes (ddc) in 2019        --
------------------------------------------------

--------------------------------------------
-- Performance Optimization and Retail vs. Classic differences

-- FrameXML api
local GetClassColor = function(fileName)		
	if not fileName then return 0,0,0; end
	if C_ClassColor then	-- introduced in 8.1
		return C_ClassColor.GetClassColor(fileName):GetRGB();
	elseif (GetClassColor) then	-- depreciated in 8.1 but still seems to work
		return GetClassColor(fileName);
	else
		-- alternative for 1.13.2 (classic)
		local colors =
		{
			["HUNTER"] = {0.67, 0.83, 0.45, "ffabd473"},
			["WARLOCK"] = {0.53, 0.53, 0.93, "ff8787ed"},
			["PRIEST"] = {1.00, 1.00, 1.00, "ffffffff"},
			["PALADIN"] = {0.96, 0.55, 0.73, "fff58cba"},
			["MAGE"] = {0.25, 0.78, 0.92, "ff40c7eb"},
			["ROGUE"] = {1.00, 0.96, 0.41, "fffff569"},
			["DRUID"] = {1.00, 0.49, 0.04, "ffff7d0a"},
			["SHAMAN"] = {0.00, 0.44, 0.87, "ff0070de"},
			["WARRIOR"] = {0.78, 0.61, 0.43, "ffc79c6e"},
		}
		return unpack(colors[fileName] or { });
	end
end;
local CompactRaidFrameManager_SetSetting = CompactRaidFrameManager_SetSetting;
local GetInspectSpecialization = GetInspectSpecialization or function() return nil; end	-- doesn't exist in classic
local GetSpecializationRoleByID = GetSpecializationRoleByID or function() return nil; end -- doesn't exist in classic
local GetReadyCheckStatus = GetReadyCheckStatus;
local InCombatLockdown = InCombatLockdown;
local IncomingSummonStatus = (C_IncomingSummon and C_IncomingSummon.IncomingSummonStatus) or function() return 0; end	-- doesn't exist in classic, and 0 means no incoming summons
local RegisterStateDriver = RegisterStateDriver;
local SetPortraitTexture = SetPortraitTexture;
local UnitAura = UnitAura;
local UnitClass = UnitClass;
local UnitExists = UnitExists;
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs or function() return 0; end -- doesn't exist in classic, and zero means no absorb bar will be created
local UnitInRange = UnitInRange;
local UnitIsDeadOrGhost = UnitIsDeadOrGhost;
local UnitIsUnit = UnitIsUnit;
local UnitHealth = UnitHealth;
local UnitHealthMax = UnitHealthMax;
local UnitGroupRolesAssigned = UnitGroupRolesAssigned or function() return nil; end -- doesn't exist in classic
local UnitName = UnitName;
local UnitPower = UnitPower;
local UnitPowerMax = UnitPowerMax;
local UnregisterStateDriver = UnregisterStateDriver;

-- lua functions
local max = max;
local min = min;
local select = select;
local strsplit = strsplit;


--------------------------------------------
-- Pseudo-Object-Oriented Design

local StaticCTRAReadyCheck;		-- Adds features to help you share your ready check status with raid members
local StaticCTRAFrames;			-- Wrapper over all raid-frame portions of the addon
local NewCTRAWindow;			-- Set of player frames (and optionally labels or target frames) sharing a common appearance and anchor point
local NewCTRAPlayerFrame;		-- A single, interactive player frame that is contained in a window
local NewCTRATargetFrame;		-- A single, interactive target frame that is contained in a window


--------------------------------------------
-- Initialization

local MODULE_TOC_NAME, module = ...;
local _G = getfenv(0);

local MODULE_TOC_VERSION = strmatch(GetAddOnMetadata(MODULE_TOC_NAME, "version"), "^([%d.]+)");

module.name = "CT_RaidAssist";
module.version = MODULE_TOC_VERSION;

_G[module.name] = module;
CT_Library:registerModule(module);

module.text = module.text or { };	-- see localization.lua
local L = module.text

-- triggered by module.update("init")
function module:init()	
	module.CTRAReadyCheck = StaticCTRAReadyCheck();
	module.CTRAFrames = StaticCTRAFrames();
	
	-- convert from pre-BFA CTRA to 8.2.0.5
	--if (not module:getOption("CTRA_LastConversion") or module:getOption("CTRA_LastConversion") < 8.205) then
	--	module:setOption("CTRA_LastConversion", 8.205, true)
	--	-- there was code here to do the conversion, but now that is removed and no longer necessary
	--
	--end
end

-- triggered by CT_Library whenever a setting changes, and upon initialization, to call functions associated with tailoring various functionality as required
function module:update(option, value)
	if (option == "init") then
		module:init();
	else
		module.CTRAReadyCheck:Update(option, value);
		module.CTRAFrames:Update(option, value);
	end
end

--produces the options frames
function module:frame()
	-- see CT_Library
	local optionsFrameList = module:framesInit();
		
	-- Ready Check Monitor
	module.CTRAReadyCheck:Frame(optionsFrameList);

	-- Custom Raid Frames
	module.CTRAFrames:Frame(optionsFrameList);

	-- see CT_Library
	return "frame#all", module:framesGetData(optionsFrameList);
end

local function slashCommand()
	module:showModuleOptions(module.name)
end

module:setSlashCmd(slashCommand, "/ctra", "/ctraid", "/ctraidassist");
 

--------------------------------------------
-- Extended Ready Checks

local CTRAReadyCheck;
function StaticCTRAReadyCheck()
	if CTRAReadyCheck then
		return CTRAReadyCheck;		-- this can only be created once (hense the name 'static')
	end
	
	local obj = { };
	CTRAReadyCheck = obj;
	
	-- PRIVATE PROPERTIES
	local extendReadyChecks = module:getOption("CTRA_ExtendReadyChecks") ~= false;
	local monitorDurability = module:getOption("CTRA_MonitorDurability") or 50;
	
	local invSlots =
	{
		-- name, 		anchorPt, 	relTo, 			relPtm		xOff, 	yOff, 		width, 	height, 		leftTexCoord,	rightTexCoord,	topTexCoord,	bottomTexCoord
		{INVSLOT_HEAD,		"TOP",		"",			"TOP",		0,	-10,		18,	22,			0.0,		0.140625,	0.0,		0.171875},
		{INVSLOT_SHOULDER,	"TOP",		INVSLOT_HEAD,		"BOTTOM",	0,	16,		48,	22,			0.140625,	0.515625,	0.0,		0.171875},
		{INVSLOT_CHEST,		"TOP",		INVSLOT_SHOULDER,	"TOP",		0,	-7,		20,	22,			0.515625,	0.6640625,	0.0,		0.171875},
		{INVSLOT_WRIST,		"TOP",		INVSLOT_SHOULDER,	"BOTTOM",	0,	7,		44,	22,			0.6640625,	1.0,		0.0,		0.171875},
		{INVSLOT_HAND,		"TOP",		INVSLOT_WRIST,		"BOTTOM",	0,	15,		42,	18,			0.0,		0.328125,	0.171875,	0.3046875},
		{INVSLOT_WAIST,		"TOP",		INVSLOT_CHEST,		"BOTTOM",	0,	6,		16,	5,			0.328125,	0.46875,	0.171875,	0.203125},
		{INVSLOT_LEGS,		"TOP",		INVSLOT_WAIST,		"BOTTOM",	0,	2,		29,	20,			0.46875,	0.6875,		0.171875,	0.3203125},
		{INVSLOT_FEET,		"TOP",		INVSLOT_LEGS,		"BOTTOM",	0,	8,		41,	32,			0.6875,		1.0,		0.171875,	0.4140625},
		{INVSLOT_MAINHAND,	"RIGHT",	INVSLOT_WRIST,		"LEFT",		0,	-6,		20,	45,			0.0,		0.140625,	0.3203125,	0.6640625},
		{INVSLOT_OFFHAND,	"LEFT",		INVSLOT_WRIST,		"RIGHT",	0,	10,		25,	31,			0.1875,		0.375,		0.3203125,	0.5546875},
		--{"OffWeapon",		"LEFT",		INVSLOT_WRIST,		"RIGHT",	0,	-6,		20,	45,			0.0,		0.140625,	0.3203125,	0.6640625},
		{INVSLOT_RANGED,	"TOP",		INVSLOT_OFFHAND,	"BOTTOM",	0,	5,		28,	38,			0.1875,		0.3984375,	0.5546875,	0.84375},
	}

	-- PRIVATE METHODS
	local function configureAfterReadyCheckFrame()
		local frame = CreateFrame("Frame", nil, UIParent);
		frame:Hide();
		frame:SetSize(323,97);
		frame:SetPoint("CENTER", 0, -10);
		frame:RegisterEvent("PLAYER_REGEN_DISABLED");
		frame:RegisterEvent("GROUP_LEFT");
		frame:RegisterEvent("READY_CHECK");
		frame:RegisterUnitEvent("READY_CHECK_CONFIRM", "player");
		frame:RegisterEvent("READY_CHECK_FINISHED");
		frame:SetScript("OnEvent",
			function(self, event, arg1)
				if (event == "PLAYER_REGEN_DISABLED") then
					self:Hide();
				elseif (event == "GROUP_LEFT") then
					self:Hide();
				elseif (event == "READY_CHECK") then
					self:Hide();
					SetPortraitTexture(frame.portrait, arg1)
					self.status = GetReadyCheckStatus("player");
					self.initiator = arg1;
				elseif (event == "READY_CHECK_CONFIRM") then
					self.status = GetReadyCheckStatus("player");
				elseif (event == "READY_CHECK_FINISHED") then
					if (extendReadyChecks) then
						if (self.status == "waiting") then
							self:Show();
							self.text:SetText(L["CT_RaidAssist/frame/WasAFK"]);
						elseif (self.status == "notready") then
							self:Show();
							self.text:SetText(L["CT_RaidAssist/frame/WasNotReady"]);
						elseif (not self.status) then
							self:Show();
							SetPortraitTexture(frame.portrait, "player");
							self.text:SetText(L["CT_RaidAssist/frame/MissedCheck"]);
							self.initiator = nil;
						end
					else
						self.initiator = nil;
					end
				end
			end
		);

		frame.portrait = frame:CreateTexture(nil, "BACKGROUND");
		frame.portrait:SetSize(50,50);
		frame.portrait:SetPoint("TOPLEFT", 7, -6);

		frame.texture = frame:CreateTexture(nil, "ARTWORK");
		frame.texture:SetSize(323, 97);
		frame.texture:SetTexture("Interface\\RaidFrame\\UI-ReadyCheckFrame");
		frame.texture:SetTexCoord(0, 0.630859375, 0, 0.7578125);
		frame.texture:SetPoint("TOPLEFT");

		frame.text = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal");
		frame.text:SetSize(240, 0);
		frame.text:SetJustifyV("MIDDLE");
		frame.text:SetPoint("CENTER", frame, "TOP", 20, -35);
		frame.text:SetText("Are you ready now?");

		frame.footnote = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
		frame.footnote:SetPoint("BOTTOMRIGHT", -10, 10);
		frame.footnote:SetTextColor(0.35, 0.35, 0.35);
		frame.footnote:SetText("/ctra");

		frame.returnedButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate");
		frame.returnedButton:SetText("Ready");
		frame.returnedButton:SetSize(119, 24);
		frame.returnedButton:SetPoint("TOPRIGHT", frame, "TOP", 13, -55);
		frame.returnedButton:SetScript("OnClick",
			function()
				PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
				frame:Hide();
				if (frame.initiator and UnitExists(frame.initiator) and UnitInRange(frame.initiator)) then
					DoEmote("ready", frame.initiator);
				else
					SendChatMessage("Ready", "RAID");
				end
				frame.initiator = nil;
			end
		);

		frame.goingafkButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate");
		frame.goingafkButton:SetText("Cancel");
		frame.goingafkButton:SetSize(119, 24);
		frame.goingafkButton:SetPoint("TOPLEFT", frame, "TOP", 17, -55);
		frame.goingafkButton:SetScript("OnClick",
			function()
				frame:Hide();
			end
		);
	end
	
	local function configureDurabilityMonitor()
	
		local frame = CreateFrame("Frame", nil, UIParent);
		frame:Hide();
		frame:SetSize(110, 120);
		frame:SetPoint("LEFT", ReadyCheckFrame, "RIGHT", 10, 0);
		frame:RegisterEvent("PLAYER_REGEN_DISABLED");
		frame:RegisterEvent("GROUP_LEFT");
		frame:RegisterEvent("READY_CHECK");
		frame:RegisterUnitEvent("READY_CHECK_CONFIRM", "player");
		frame:RegisterEvent("READY_CHECK_FINISHED");
		frame:RegisterEvent("UPDATE_INVENTORY_DURABILITY");
		frame:SetScript("OnEvent",
			function(__, event)
				if (InCombatLockdown()) then return; end
				if (event == "READY_CHECK") then
					frame:Show();
				else
					frame:Hide();
				end
			end
		);
		
		frame.closeButton = CreateFrame("Button", nil, frame, "SecureHandlerClickTemplate");
		frame.closeButton:SetSize(24, 24);
		frame.closeButton:SetPoint("TOPRIGHT");
		frame.closeButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up");
		frame.closeButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down");
		frame.closeButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight");
		frame.closeButton:SetAttribute("_onclick", [=[ self:GetParent():Hide(); ]=]);
		
		frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
		frame.text:SetPoint("BOTTOM", 0, 24);
		
		for __, bodyPart in ipairs(invSlots) do
			frame[bodyPart[1]] = frame:CreateTexture(nil, "ARTWORK");
			frame[bodyPart[1]]:SetTexture("Interface\\Durability\\UI-Durability-Icons");
			frame[bodyPart[1]]:SetPoint(bodyPart[2], (bodyPart[3] ~= "" and frame[bodyPart[3]]) or frame, bodyPart[4], bodyPart[5], bodyPart[6]);
			frame[bodyPart[1]]:SetSize(bodyPart[7], bodyPart[8]);
			frame[bodyPart[1]]:SetTexCoord(bodyPart[9], bodyPart[10], bodyPart[11], bodyPart[12]);
		end

		frame:SetScript("OnShow", 
			function()
				local worst, worstTex = 100, "";
				for __, bodyPart in ipairs(invSlots) do
					local current, maximum = GetInventoryItemDurability(bodyPart[1]);
					if (maximum and maximum > 0) then
						if (current/maximum * 100 < worst) then
							worst = floor(current/maximum * 100);
							worstTex = GetInventoryItemTexture("player", bodyPart[1]);
						end
						if (current == 0) then
							frame[bodyPart[1]]:SetVertexColor(1.0, 0.0, 0.0, 1.00);
						elseif (current/maximum > monitorDurability/100) then
							frame[bodyPart[1]]:SetVertexColor(1.0, 1.0, 1.0, 1.00 - 0.50 * current / maximum);
						else
							frame[bodyPart[1]]:SetVertexColor(1.0, 1.0, 0.0, 1.00 - 0.50 * current / maximum);
						end
					else
						frame[bodyPart[1]]:SetVertexColor(1.0, 1.0, 1.0, 0.25);
					end
				end
				frame.text:SetText("|T" .. worstTex ..  ":0|t " .. worst .. "%");
				if (worst >= monitorDurability) then
					frame:Hide();
				end
			end
		);
	end
	
	-- PUBLIC METHODS
	
	function obj:Update(option, value)
		if (option == "CTRA_ExtendReadyChecks") then
			extendReadyChecks = value;
		elseif (option == "CTRA_MonitorDurability") then
			monitorDurability = value;
		elseif (option == "CTRA_ShareDurability") then
			if (value) then
				module:InstallLibDurability()
			else
				print("Please /reload for CTRA to stop sharing durability.  Other addons (DBM, oRA, etc.) may re-activate this feature.");
			end
		end
	end
	
	function obj:Frame(optionsFrameList)
		-- helper functions to shorten the code a bit
		local optionsAddFrame = function(offset, size, details, data) module:framesAddFrame(optionsFrameList, offset, size, details, data); end
		local optionsAddObject = function(offset, size, details) module:framesAddObject(optionsFrameList, offset, size, details); end
		local optionsAddScript = function(name, func) module:framesAddScript(optionsFrameList, name, func); end
		local optionsAddTooltip = function(text) module:framesAddScript(optionsFrameList, "onenter", function(obj) module:displayTooltip(obj, text, "CT_ABOVEBELOW", 0, 0, CTCONTROLPANEL); end); end
		local optionsBeginFrame = function(offset, size, details, data) module:framesBeginFrame(optionsFrameList, offset, size, details, data); end
		local optionsEndFrame = function() module:framesEndFrame(optionsFrameList); end
		
		-- commonly used colors
		local textColor1 = "0.9:0.9:0.9";
		local textColor2 = "0.7:0.7:0.7";

		-- Heading
		optionsAddObject(-20, 17, "font#tl:5:%y#v:GameFontNormalLarge#" .. L["CT_RaidAssist/Options/ReadyCheckMonitor/Heading"]);
		--optionsAddObject(-5, 2*14, "font#tl:15:%y#s:0:%s#l:13:0#r#" .. L["CT_RaidAssist/Options/ReadyCheckMonitor/Line1"] .. "#" .. textColor2 .. ":l");
		
		-- Extend overdue readychecks
		optionsBeginFrame(-15, 26, "checkbutton#tl:10:%y#n:CTRA_ExtendReadyChecksCheckButton#o:CTRA_ExtendReadyChecks:1#" .. L["CT_RaidAssist/Options/ReadyCheckMonitor/ExtendReadyChecksCheckButton"]);
			optionsAddTooltip({L["CT_RaidAssist/Options/ReadyCheckMonitor/ExtendReadyChecksCheckButton"],L["CT_RaidAssist/Options/ReadyCheckMonitor/ExtendReadyChecksTooltip"] .. "#" .. textColor1});
		optionsEndFrame();
		
		-- Monitor and share durability
		optionsBeginFrame(0, 26, "checkbutton#tl:10:%y#n:CTRA_ShareDurabilityCheckButton#o:CTRA_ShareDurability:true#" .. L["CT_RaidAssist/Options/ReadyCheckMonitor/ShareDurabilityCheckButton"]);
			optionsAddTooltip({L["CT_RaidAssist/Options/ReadyCheckMonitor/ShareDurabilityCheckButton"],L["CT_RaidAssist/Options/ReadyCheckMonitor/ShareDurabilityTooltip"] .. "#" .. textColor1});
		optionsEndFrame();
		optionsAddObject(-5, 2*14, "font#tl:15:%y#s:0:%s#l:13:0#r#" .. L["CT_RaidAssist/Options/ReadyCheckMonitor/MonitorDurabilityLabel"] .. "#" .. textColor2 .. ":l");
		optionsAddObject( -20	, 17, "slider#tl:50:%y#s:200:%s#n:CTRA_MonitorDurabilitySlider#o:CTRA_MonitorDurability:50#" .. L["CT_RaidAssist/Options/ReadyCheckMonitor/MonitorDurabilitySlider"] .. "#0:50:5");


	end
	
	-- PUBLIC CONSTRUCTOR
	do
		configureAfterReadyCheckFrame();
		module:InstallLibDurability(); -- see Libs/LibDurability.lua
		configureDurabilityMonitor();
		return obj;
	end
end


--------------------------------------------
-- CTRAFrames

local CTRAFrames;
function StaticCTRAFrames()
	if CTRAFrames then
		return CTRAFrames;		-- this can only be created once (hense the name 'static')
	end
	
	-- PUBLIC INTERFACE
	local obj = { };
	CTRAFrames = obj;
	
	-- private properties, and where applicable their default values
	local windows = { };			-- non-interactive frames that anchor and orient assigned collections of PlayerFrames, TargetFrames and LabelFrames
	local selectedWindow = nil;		-- the currently selected window
	local listener = nil;			-- listener for joining and leaving a raid
	local enabledState;			-- are the raidframes enabled (but possibly hidden if not in a raid)
	local settingsOverlayToStopClicks;	-- button that sits overtop several options to stop interactions with them
	local dummyFrame;			-- pretend CTRAPlayerFrame to illustrate options
	local optionsWaiting = { };		-- options to be applied once combat ends
	local defaultFramesHooked;		-- prevents hooks from being applied multiple times

	-- private methods
	
	-- prevents the default blizzard frames from appearing, and prints a notice if the user tries to use them
	local function hideDefaultFrames()		
		
		-- STEP 1: Hide the frames
		-- STEP 2: Do step 3 once only
		-- STEP 3: Send a message the first time someone tries to show the frames while CT is hiding them
		
		-- STEP 1:
		RegisterStateDriver(CompactRaidFrameContainer, "visibility", "hide");
		
		-- STEP 2:
		if defaultFramesHooked then return; end
		defaultFramesHooked = 1;
		
		-- STEP 3:
		local function forHooking()
			if (module:getOption("CTRAFrames_HideBlizzardDefaultFrames") ~= false and obj:IsEnabled() and defaultFramesHooked == 1) then
				print("Note:|n  CT_RaidAssist is hiding Blizzard's default raid frames.|n  Please type |cFFFFFF00/ctra|r to reconfigure this behaviour");
				defaultFramesHooked = 2;
			end
		end
		for i=1, 8 do
			local button = _G["CompactRaidFrameManagerDisplayFrameFilterOptionsFilterGroup" .. i];
			if (button) then
				button:HookScript("OnClick", forHooking);
			end
		end
		if (CompactRaidFrameManagerDisplayFrameHiddenModeToggle) then
			CompactRaidFrameManagerDisplayFrameHiddenModeToggle:HookScript("OnClick", forHooking);
		end
	end
	
	-- allows the default blizzard frames to reappear
	local function showDefaultFrames()
		
		-- STEP 1: Stop forcing the frames to be hidden
		-- STEP 2: Update them to their natural state
		
		-- STEP 1:
		UnregisterStateDriver(CompactRaidFrameContainer, "visibility");
		
		-- STEP 2:
		CompactRaidFrameManager_SetSetting("IsShown",CompactUnitFrameProfiles_GetAutoActivationState());    --    (IsInRaid() and true) or (IsInGroup() and CompactRaidFrameManagerDisplayFrameHiddenModeToggle.shownMode) or false);
		--CompactRaidFrameContainer_TryUpdate(CompactRaidFrameContainer);
	end
	
	-- public methods
	function obj:Enable()
		-- STEP 1: if not already enabled, do steps 2-4
		-- STEP 2: create (if necessary) and enable CTRAWindow objects
		-- STEP 3: set a flag to respond positively to IsEnabled() queries
		-- STEP 4: focus the options menu if it is created already (otherwise, this step will occur when it is created)
		-- STEP 5: hide the default ui frames (if appropriate)
		
		--STEP 1:
		if (not self:IsEnabled() and not InCombatLockdown()) then
			
			--STEP 2:
			for i = 1, (module:getOption("CTRAFrames_NumEnabledWindows") or 1) do
				if (not windows[i]) then
					windows[i] = NewCTRAWindow(self);
				end
				windows[i]:Enable(i);
			end
			
			-- STEP 3
			enabledState = true;
			if (not selectedWindow) then
				selectedWindow = 1
			end
			
			-- STEP 4:
			windows[selectedWindow]:Focus();
			if (settingsOverlayToStopClicks) then 
				settingsOverlayToStopClicks:Hide();
			end
			
			-- STEP 5:
			if (module:getOption("CTRAFrames_HideBlizzardDefaultFrames")) then
				hideDefaultFrames();
			end
		end		
	end
	
	function obj:Disable()
		-- STEP 1: if not already disabled, do steps 2-4
		-- STEP 2: disable all current CTRAWindow objects
		-- STEP 3: set a flag to respond negatively to IsEnabled() queries
		-- STEP 4: stop hiding the blizzard default frames
		
		--STEP 1:
		if (self:IsEnabled() and not InCombatLockdown()) then
			--STEP 2:
			for __, window in ipairs(windows) do
				if (window:IsEnabled()) then
					-- the windows are disabled and stored in windows for future use; they are not 'deleted' because WoW won't garbage collect frames
					window:Disable();	-- the window and its assigned content deregisters from all events
				end
			end
			
			-- STEP 3
			enabledState = nil;
			
			if (settingsOverlayToStopClicks) then
				settingsOverlayToStopClicks:Show();
			end
			
			-- STEP 4:
			showDefaultFrames();
		end
	end
	
	function obj:IsEnabled()
		return enabledState;
	end

	function obj:ToggleEnableState (value)
		if (
			(value or module:getOption("CTRAFrames_EnableFrames")) == 1
			or ((value or module:getOption("CTRAFrames_EnableFrames") or 2) == 2 and IsInRaid())  --  default
			or ((value or module:getOption("CTRAFrames_EnableFrames")) == 3 and IsInGroup())
		) then
			self:Enable();
		else
			self:Disable();
		end
	end
		
	function obj:Update(option, value)
		if (option) then
			optionsWaiting[option] = value;
		end
		if (not InCombatLockdown()) then
			for key, val in pairs(optionsWaiting) do
				if (key == "CTRAFrames_EnableFrames") then
					self:ToggleEnableState(val);
				elseif (key == "CTRAFrames_HideBlizzardDefaultFrames") then
					if (val and obj:IsEnabled()) then
						hideDefaultFrames();
					else
						showDefaultFrames();
					end
				end
				optionsWaiting[key] = nil;
			end
			--optionsWaiting = { };
		end
		for i, window in ipairs(windows) do
			if (option) then
				if (strfind(option, "CTRAWindow" .. i .. "_") == 1) then
					window:Update(strsub(option,strfind(option, "_")+1), value);
				end
			else
				window:Update();
			end
		end
		if (dummyFrame and option and strfind(option, "CTRAWindow" .. (selectedWindow or 1) .. "_") == 1) then
			dummyFrame:Update(strsub(option,strfind(option, "_")+1), value);
		end
	end
	

	
	function obj:Frame(optionsFrameList)
		-- helper functions to shorten the code a bit
		local optionsAddFrame = function(offset, size, details, data) module:framesAddFrame(optionsFrameList, offset, size, details, data); end
		local optionsAddObject = function(offset, size, details) module:framesAddObject(optionsFrameList, offset, size, details); end
		local optionsAddScript = function(name, func) module:framesAddScript(optionsFrameList, name, func); end
		local optionsAddTooltip = function(text, anchor) module:framesAddScript(optionsFrameList, "onenter", function(obj) module:displayTooltip(obj, text, anchor or "CT_ABOVEBELOW", 0, 0, CTCONTROLPANEL); end); end
		local optionsBeginFrame = function(offset, size, details, data) module:framesBeginFrame(optionsFrameList, offset, size, details, data); end
		local optionsEndFrame = function() module:framesEndFrame(optionsFrameList); end
		
		local optionsWindowizeObject = function(property) 
			-- overloads the traditional CT_Library behaviour
			optionsAddScript("onload",
				function(obj)
					obj.option = function() return "CTRAWindow" .. selectedWindow .. "_" .. property; end
				end
			);
		end

		local optionsWindowizeSlider = function(property) 
			-- overloads the traditional CT_Library behaviour; same as above but with .suspend property
			optionsAddScript("onload",
				function(slider)
					slider.option = function()
						if (slider.suspend) then
							return nil;
						else
							return "CTRAWindow" .. selectedWindow .. "_" .. property;
						end
					end
				end
			);
		end
								
		-- commonly used colors
		local textColor1 = "0.9:0.9:0.9";
		local textColor2 = "0.7:0.7:0.7";
		
		
		-- Heading
		optionsAddObject(-30, 17, "font#tl:5:%y#v:GameFontNormalLarge#Custom Raid Frames"); -- Custom Raid Frames
		
		-- General Options
		optionsAddObject(-15, 26, "font#tl:15:%y#Enable CTRA Frames?#" .. textColor1 .. ":l"); -- Enable custom raid frames
		optionsAddFrame( 26, 20, "dropdown#tl:130:%y#s:120:%s#n:CTRAFrames_EnableFramesDropDown#o:CTRAFrames_EnableFrames:2 #Always#During Raids#During Groups#Never");
		optionsBeginFrame( -5,  20, "checkbutton#tl:15:%y#n:CTRAFrames_HideBlizzardDefaultFramesCheckButton#o:CTRAFrames_HideBlizzardDefaultFrames:true#" .. L["CT_RaidAssist/Options/Frames/HideBlizzardDefaultCheckButton"]);
			optionsAddTooltip({L["CT_RaidAssist/Options/Frames/HideBlizzardDefaultCheckButton"],L["CT_RaidAssist/Options/Frames/HideBlizzardDefaultTooltip"] .. "#" .. textColor1});
		optionsEndFrame();
		
		
		-- Everything below this line will pseudo-disable when the frames are disabled
		optionsBeginFrame(-5, 0, "frame#tl:0:%y#br:tr:0:%b#n:");
			optionsAddScript("onload",
				function(frame)
					settingsOverlayToStopClicks = CreateFrame("Button", nil, frame);
					settingsOverlayToStopClicks:SetAllPoints();
					settingsOverlayToStopClicks:RegisterForClicks("AnyDown", "AnyUp");
					local tex = settingsOverlayToStopClicks:CreateTexture(nil, "OVERLAY");
					tex:SetAllPoints();
					tex:SetColorTexture(0,0,0,0.50);
					settingsOverlayToStopClicks:SetFrameLevel(25);
					settingsOverlayToStopClicks:SetScript("OnEnter",
						function()
							module:displayTooltip(settingsOverlayToStopClicks, "Raid frames are currently disabled!\nYou must enable them using the dropdown above.", "ANCHOR_CURSOR");
						end
					);
				end
			);
		
			-- Window Selection
			optionsBeginFrame(0, 0, "frame#tl:0:%y#br:tr:0:%b");

				-- Heading
				optionsAddObject(-15,  17, "font#tl:5:%y#v:GameFontNormal#n:CTRAFrames_SelectedWindowHeading#" .. L["CT_RaidAssist/Options/WindowControls/Heading"]);
				optionsAddObject(-5, 2*14, "font#tl:15:%y#s:0:%s#l:13:0#r#" .. L["CT_RaidAssist/Options/WindowControls/Line1"] .. "#" .. textColor2 .. ":l");
				
				-- select which window to configure
				optionsAddObject(-10, 14, "font#tl:15:%y#v:ChatFontNormal#" .. L["CT_RaidAssist/Options/WindowControls/SelectionLabel"]);
				optionsBeginFrame(19, 24, "button#tl:105:%y#s:24:%s#n:CTRAFrames_PreviousWindowButton");
					optionsAddScript("onclick",
						function(button)
							if (selectedWindow > 1) then
								selectedWindow = selectedWindow - 1;
								windows[selectedWindow]:Focus();
								UIDropDownMenu_SetText(CTRAFrames_WindowSelectionDropDown, format(L["CT_RaidAssist/WindowTitle"],selectedWindow));
								if (selectedWindow == 1) then
									button:Disable();
								end
								CTRAFrames_NextWindowButton:Enable();
							end
						end
					);
					optionsAddScript("onload",
						function(button)
							button:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up");
							button:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down");
							button:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled");
							button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight");
							button:Disable();
						end
					);
				optionsEndFrame();
				optionsBeginFrame(24, 24, "button#tl:125:%y#s:24:%s#n:CTRAFrames_NextWindowButton");
					optionsAddScript("onclick",
						function(button)
							if (selectedWindow < (module:getOption("CTRAFrames_NumEnabledWindows") or 1)) then
								selectedWindow = selectedWindow + 1;
								windows[selectedWindow]:Focus();
								UIDropDownMenu_SetText(CTRAFrames_WindowSelectionDropDown, format(L["CT_RaidAssist/WindowTitle"],selectedWindow));
								if (selectedWindow == (module:getOption("CTRAFrames_NumEnabledWindows") or 1)) then
									button:Disable();
								end
								CTRAFrames_PreviousWindowButton:Enable();
							end
						end
					);
					optionsAddScript("onload",
						function(button)
							button:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up");
							button:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down");
							button:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled");
							button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight");
							if ((module:getOption("CTRAFrames_NumEnabledWindows") or 1) == 1) then
								button:Disable();
							end
						end
					);
				optionsEndFrame();
				optionsBeginFrame(20, 20, "dropdown#tl:140:%y#n:CTRAFrames_WindowSelectionDropDown");
					optionsAddScript("onload",
						function(dropdown)
							UIDropDownMenu_SetText(dropdown, "Window 1");
							UIDropDownMenu_Initialize(dropdown,
								function(frame, level)
									for i=1, (module:getOption("CTRAFrames_NumEnabledWindows") or 1) do
										local dropdownEntry = { }
										dropdownEntry.text = format(L["CT_RaidAssist/WindowTitle"],i);
										dropdownEntry.value = i;
										dropdownEntry.func = function()
											selectedWindow = i;
											print(format(L["CT_RaidAssist/Options/WindowControls/WindowSelectedMessage"],i));
											if ((module:getOption("CTRAFrames_NumEnabledWindows") or 1) == 1) then
												CTRAFrames_PreviousWindowButton:Disable();
												CTRAFrames_NextWindowButton:Disable();
											elseif ((module:getOption("CTRAFrames_NumEnabledWindows") or 1) == selectedWindow) then
												CTRAFrames_PreviousWindowButton:Enable();
												CTRAFrames_NextWindowButton:Disable();
											elseif (selectedWindow == 1) then
												CTRAFrames_PreviousWindowButton:Disable();
												CTRAFrames_NextWindowButton:Enable();
											else
												CTRAFrames_PreviousWindowButton:Enable();
												CTRAFrames_NextWindowButton:Enable();
											end
											windows[i]:Focus();
											UIDropDownMenu_SetText(frame, format(L["CT_RaidAssist/WindowTitle"],i));
										end
										UIDropDownMenu_AddButton(dropdownEntry, level);
									end
								end
							)
						end
					);
				optionsEndFrame();

				-- create a new window
				optionsBeginFrame(-5, 30, "button#tl:15:%y#s:80:%s#v:UIPanelButtonTemplate#" .. L["CT_RaidAssist/Options/WindowControls/AddButton"]);
					optionsAddScript("onclick", 
						function()
							selectedWindow = (module:getOption("CTRAFrames_NumEnabledWindows") or 1) + 1;
							module:setOption("CTRAFrames_NumEnabledWindows", selectedWindow, true);
							if (not windows[selectedWindow]) then
								windows[selectedWindow] = NewCTRAWindow(self)
							end
							windows[selectedWindow]:Enable(selectedWindow);
							windows[selectedWindow]:Focus();
							UIDropDownMenu_SetText(CTRAFrames_WindowSelectionDropDown, format(L["CT_RaidAssist/WindowTitle"],selectedWindow));
							CTRAFrames_DeleteWindowButton:Enable(); -- the delete button may have been previously disabled if there was only one window available
							CTRAFrames_PreviousWindowButton:Enable();
							CTRAFrames_NextWindowButton:Disable();
							print(format(L["CT_RaidAssist/Options/WindowControls/WindowAddedMessage"],selectedWindow));
						end
					);
					optionsAddTooltip({L["CT_RaidAssist/Options/WindowControls/AddTooltip"] .. "#1:0.82:1"}, "ANCHOR_TOPLEFT");
				optionsEndFrame();
				
				-- clone an existing window
				optionsBeginFrame( 30, 30, "button#tl:110:%y#s:80:%s#v:UIPanelButtonTemplate#" .. L["CT_RaidAssist/Options/WindowControls/CloneButton"]);
					optionsAddScript("onclick", 
						function()
							local windowToClone = selectedWindow;
							selectedWindow = (module:getOption("CTRAFrames_NumEnabledWindows") or 1) + 1;
							module:setOption("CTRAFrames_NumEnabledWindows", selectedWindow, true);
							if (not windows[selectedWindow]) then
								windows[selectedWindow] = NewCTRAWindow(self);
							end
							windows[selectedWindow]:Enable(selectedWindow, windowToClone);
							windows[selectedWindow]:Focus();
							UIDropDownMenu_SetText(CTRAFrames_WindowSelectionDropDown, format(L["CT_RaidAssist/WindowTitle"],selectedWindow));
							CTRAFrames_DeleteWindowButton:Enable(); -- the delete button may have been previously disabled if there was only one window available
							CTRAFrames_PreviousWindowButton:Enable();
							CTRAFrames_NextWindowButton:Disable();
							print(format(L["CT_RaidAssist/Options/WindowControls/WindowClonedMessage"],selectedWindow));
						end
					);
					optionsAddTooltip({L["CT_RaidAssist/Options/WindowControls/CloneTooltip"] .. "#1:0.82:1#w"}, "ANCHOR_TOPLEFT");
				optionsEndFrame();
				
				-- delete a window
				optionsBeginFrame( 30, 30, "button#tl:205:%y#s:80:%s#v:UIPanelButtonTemplate#" .. L["CT_RaidAssist/Options/WindowControls/DeleteButton"] .. "#n:CTRAFrames_DeleteWindowButton");
					optionsAddScript("onclick", 
						function(button)
							-- make sure the user really means it, and that this isn't the very last window
							if ((module:getOption("CTRAFrames_NumEnabledWindows") or 1) == 1) then
								return;
							end
							
							if (not IsShiftKeyDown()) then
								print(L["CT_RaidAssist/Options/WindowControls/DeleteTooltip"]);
								return;
							end
							
							--delete the window, and push this frame to the end of the table
							local windowToDelete = windows[selectedWindow];
							windowToDelete:Disable(true); -- now the window is disabled, and its settings are also DELETED because the flag was set to true
							module:setOption("CTRAFrames_NumEnabledWindows", (module:getOption("CTRAFrames_NumEnabledWindows") or 1) - 1, true); -- now we are tracking one fewer window being enabled
							tinsert(windows,tremove(windows,selectedWindow)); -- pushes this frame to the end of the table, beyond numEnabledWindows
							
							-- inform remaining windows of their new positions, and copy saved variable data from their previous positions
							for i=selectedWindow, module:getOption("CTRAFrames_NumEnabledWindows"), 1 do
								windows[i]:Enable(i,i+1); 
							end
							
							-- if we previously deleted the last-most window, then we need to go earlier in the stack
							if (selectedWindow > module:getOption("CTRAFrames_NumEnabledWindows")) then
								-- we are now looking at a non-enabled window that is at the end of the stack (possible the one we just deleted)
								selectedWindow = module:getOption("CTRAFrames_NumEnabledWindows");
							end
							
							-- update the appearance of the options frame
							windows[selectedWindow]:Focus(); -- the options panel should now focus on this window
							UIDropDownMenu_SetText(CTRAFrames_WindowSelectionDropDown, format(L["CT_RaidAssist/WindowTitle"],selectedWindow));
							if (module:getOption("CTRAFrames_NumEnabledWindows") == 1) then
								button:Disable();
								CTRAFrames_PreviousWindowButton:Disable();
								CTRAFrames_NextWindowButton:Disable();
							elseif (selectedWindow == module:getOption("CTRAFrames_NumEnabledWindows")) then
								CTRAFrames_NextWindowButton:Disable();
							elseif (selectedWindow == 1) then
								CTRAFrames_PreviousWindowButton:Disable();
							end
							print(format(L["CT_RaidAssist/Options/WindowControls/WindowDeletedMessage"],windowToDelete));
						end
					);
					optionsAddTooltip({L["CT_RaidAssist/Options/WindowControls/DeleteTooltip"] .. "#1:0.82:1#w"}, "ANCHOR_TOPLEFT");
					optionsAddScript("onshow",
						function(button)
							if ((module:getOption("CTRAFrames_NumEnabledWindows") or 1) == 1) then
								button:Disable();
							end
						end
					);
				optionsEndFrame();
				
			optionsEndFrame();
		
			-- Settings for the current window
			optionsBeginFrame(0, 0, "frame#tl:10:%y#br:tr:0:%b#");
				
				-- Groups, Roles, Classes
				optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormal#" .. L["CT_RaidAssist/Options/Window/Groups/Header"]);
				optionsAddObject(-5, 2*14, "font#tl:15:%y#s:0:%s#l:13:0#r#" .. L["CT_RaidAssist/Options/Window/Groups/Line1"] .. "#" .. textColor2 .. ":l");
				optionsAddObject(-10,  20, "font#tl:15:%y#s:0:%s#" .. L["CT_RaidAssist/Options/Window/Groups/GroupHeader"] .. "#" .. textColor1 .. ":l");
				for i=1, 8 do
					optionsBeginFrame( -5,  20, "checkbutton#tl:15:%y#n:CTRAWindow_ShowGroup" .. i .. "CheckButton#Gp " .. i);
						optionsAddScript("onload",
							function(button)
								button.option = function() return "CTRAWindow" .. selectedWindow .. "_ShowGroup" .. i; end
								button:SetFrameLevel(20);
							end
							
						);
						optionsAddTooltip({L["CT_RaidAssist/Options/Window/Groups/GroupTooltipHeader"],L["CT_RaidAssist/Options/Window/Groups/GroupTooltipContent"]}, "CT_BESIDE", 0, 0, CTCONTROLPANEL);
					optionsEndFrame();
				end
				optionsAddObject(220, 20, "font#tl:110:%y#s:0:%s#" .. L["CT_RaidAssist/Options/Window/Groups/RoleHeader"] .. "#" .. textColor1 .. ":l");
				for __, val in ipairs((module:getGameVersion() == CT_GAME_VERSION_RETAIL and {"Myself", "Tanks", "Heals", "Melee", "Range"}) or {"Myself"}) do
					optionsBeginFrame( -5,  25, "checkbutton#tl:110:%y#n:CTRAWindow_Show" .. val .. "CheckButton#" .. val);
						optionsAddScript("onload",
							function(button)
								button.option = function() return "CTRAWindow" .. selectedWindow .. "_Show" .. val; end
								button:SetFrameLevel(21);
							end
						);
					optionsEndFrame();
				end
				if(module:getGameVersion() == CT_GAME_VERSION_CLASSIC) then
					optionsAddObject(-5, 115, "font#tl:110:%y#Sort by tank, \nheals, and dps \nunavailable \nin Classic#" .. textColor2 .. ":l");
				end
				optionsAddObject(170, 20, "font#tl:205:%y#s:0:%s#" .. L["CT_RaidAssist/Options/Window/Groups/ClassHeader"] .. "#" .. textColor1 .. ":l");
				for __, class in ipairs(
					(module:getGameVersion() == CT_GAME_VERSION_RETAIL and 
						{
							{"DeathKnights", "DthK"},
							{"DemonHunters", "DemH"},
							{"Druids", "Drui"},
							{"Hunters", "Hunt"},
							{"Mages", "Mage"},
							{"Monks", "Monk"},
							{"Paladins", "Pali"},
							{"Priests", "Prst"},
							{"Rogues", "Roug"},
							{"Shamans", "Sham"},
							{"Warlocks", "Wrlk"},
							{"Warriors", "Warr"},
						}
					)
					or
						{
							{"Druids", "Drui"},
							{"Hunters", "Hunt"},
							{"Mages", "Mage"},
							{"Monks", "Monk"},
							{"Paladins", "Pali"},
							{"Priests", "Prst"},
							{"Rogues", "Roug"},
							{"Shamans", "Sham"},
							{"Warlocks", "Wrlk"},
							{"Warriors", "Warr"},
						}
				) do
					optionsBeginFrame((module:getGameVersion() == CT_GAME_VERSION_RETAIL and -5) or -6, 15, "checkbutton#tl:205:%y#n:CTRAWindow_Show" .. class[1] .. "CheckButton#" .. class[2]);
						optionsAddScript("onload",
							function(button)
								button.option = function() return "CTRAWindow" .. selectedWindow .. "_Show" .. class[1]; end
								button:SetFrameLevel(22);
							end
						);
					optionsEndFrame();
				end								
				
				-- Orientation and Wrapping
				optionsAddObject(-5,   17, "font#tl:5:%y#v:GameFontNormal#" .. L["CT_RaidAssist/Options/Window/Layout/Heading"]);
				optionsAddObject(-5, 2*14, "font#tl:15:%y#s:0:%s#l:13:0#r#" .. L["CT_RaidAssist/Options/Window/Layout/Tip"] .. "#" .. textColor2 .. ":l");
				optionsAddObject(-15, 26, "font#tl:15:%y#" .. L["CT_RaidAssist/Options/Window/Layout/OrientationLabel"] .. "#" .. textColor1 .. ":l");
				optionsBeginFrame(26,   20, "dropdown#tl:140:%y#s:100:%s#n:CTRAWindow_OrientationDropDown" .. L["CT_RaidAssist/Options/Window/Layout/OrientationDropdown"]);
					optionsWindowizeObject("Orientation");
				optionsEndFrame();
				optionsAddObject(-26, 20, "font#l:tl:15:%y#" .. L["CT_RaidAssist/Options/Window/Layout/WrapLabel"] .. "#" .. textColor1 .. ":l");
				optionsBeginFrame(26, 17, "slider#tl:160:%y#s:110:%s#n:CTRAWindow_WrapAfterSlider#" .. L["CT_RaidAssist/Options/Window/Layout/WrapSlider"] .. ":2:40#2:40:1");
					optionsWindowizeSlider("WrapAfter");
					optionsAddTooltip({L["CT_RaidAssist/Options/Window/Layout/WrapTooltipHeader"],L["CT_RaidAssist/Options/Window/Layout/WrapTooltipContent"]});
				optionsEndFrame();
				optionsBeginFrame(-10, 15, "checkbutton#tl:40:%y#n:CTRAWindow_GrowUpwardCheckButton#Grow Upward");
					optionsWindowizeObject("GrowUpward");
				optionsEndFrame();
				optionsBeginFrame(15, 15, "checkbutton#tl:160:%y#n:CTRAWindow_GrowLeftCheckButton#Grow Left");
					optionsWindowizeObject("GrowLeft");
				optionsEndFrame();				
				-- Size and Spacing
				optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormal#Size and Spacing");
				optionsAddObject(-5, 2*14, "font#tl:15:%y#s:0:%s#l:13:0#r#Should frames touch each other, or be spaced apart vertically and horizontally?#" .. textColor2 .. ":l");
				optionsBeginFrame(-20, 17, "slider#tl:15:%y#s:110:%s#n:CTRAWindow_HorizontalSpacingSlider#HSpacing = <value>:Touching:Far#0:100:1");
					optionsWindowizeSlider("HorizontalSpacing");
				optionsEndFrame();
				optionsBeginFrame( 20, 17, "slider#tl:150:%y#s:110:%s#n:CTRAWindow_VerticalSpacingSlider#VSpacing = <value>:Touching:Far#0:100:1");
					optionsWindowizeSlider("VerticalSpacing");
				optionsEndFrame();
				optionsAddObject(-25, 1*14, "font#tl:15:%y#s:0:%s#l:13:0#r#How big should the frames themselves be?#" .. textColor2 .. ":l");
				optionsBeginFrame(-20, 17, "slider#tl:50:%y#s:200:%s#n:CTRAWindow_PlayerFrameScaleSlider#Scale = <value>%:50%:150%#50:150:5");
					optionsWindowizeSlider("PlayerFrameScale");
				optionsEndFrame();
				
				
				-- Appearance of Player Frames
				optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormal#" .. L["CT_RaidAssist/Options/Window/Appearance/Heading"]);
				optionsAddObject(-5, 2*14, "font#tl:15:%y#s:0:%s#l:13:0#r#" .. L["CT_RaidAssist/Options/Window/Appearance/Line1"] .. "#" .. textColor2 .. ":l");
				optionsBeginFrame( -5, 30, "button#tl:15:%y#s:80:%s#v:UIPanelButtonTemplate#Classic#n:CTRAWindow_ClassicSchemeButton");
					optionsAddScript("onclick", 
						function()
							local presetClassic =
							{
								"ColorUnitFullHealthCombat",
								"ColorUnitZeroHealthCombat",
								"ColorUnitFullHealthNoCombat",
								"ColorUnitZeroHealthNoCombat",
								"ColorReadyCheckWaiting",
								"ColorReadyCheckNotReady",
								"ColorBackground",
								"ColorBackgroundDeadOrGhost",
								"ColorBackgroundClass",
								"ColorBorder",
								"ColorBorderBeyondRange",
								"ColorBorderClass",
								"HealthBarAsBackground",
								"EnablePowerBar",
							}
							for __, property in ipairs(presetClassic) do
								module:setOption("CTRAWindow" .. selectedWindow .. "_" .. property, nil, true);		--the default is to look like classic, so just nil them out
								self:Update("CTRAWindow" .. selectedWindow .. "_" .. property, windows[selectedWindow]:GetProperty(property));	-- forces the window's update function to actually trigger with the default
							end
							windows[selectedWindow]:Focus();
						end
					);
					optionsAddTooltip({"Classic", "Keep the retro look from CTRA in Vanilla: |n- Original color scheme|n- Original health and power bars|n- Health doesn't change color when injured#0.9:0.9:0.9"});
				optionsEndFrame();
				optionsBeginFrame( 30, 30, "button#tl:110:%y#s:80:%s#v:UIPanelButtonTemplate#Hybrid#n:CTRAWindow_HybridSchemeButton");
					optionsAddScript("onclick", 
						function()
							local presetHybrid =
							{
								["ColorUnitFullHealthCombat"] = {0.00, 1.00, 0.00, 0.75},
								["ColorUnitZeroHealthCombat"] = {1.00, 1.00, 0.00, 1.00},
								["ColorUnitFullHealthNoCombat"] = {0.00, 1.00, 0.00, 0.75},
								["ColorUnitZeroHealthNoCombat"] = {0.00, 1.00, 0.00, 1.00},
								["ColorReadyCheckWaiting"] = {0.40, 0.40, 0.40, 0.80},
								["ColorReadyCheckNotReady"] = {0.80, 0.40, 0.40, 0.80},
								["ColorBackground"] = {0.00, 0.05, 0.80, 0.55},
								["HealthBarAsBackground"] = false,
								["EnablePowerBar"] = false,
							}							
							for key, val in pairs(presetHybrid) do
								module:setOption("CTRAWindow" .. selectedWindow .. "_" .. key, val, true);
							end
							windows[selectedWindow]:Focus();
						end
					);
					optionsAddTooltip({"Hybrid","In-between the classic and modern looks: |n- Health bar changes color a bit when injured|n- No power bar (mana, rage, etc.)|n- In-between color scheme#0.9:0.9:0.9"});
				optionsEndFrame();
				optionsBeginFrame( 30, 30, "button#tl:205:%y#s:80:%s#v:UIPanelButtonTemplate#Modern#n:CTRAWindow_ModernSchemeButton");
					optionsAddScript("onclick", 
						function()
							local presetModern =
							{
								["ColorUnitFullHealthCombat"] = {0.00, 1.00, 0.00, 0.50},
								["ColorUnitZeroHealthCombat"] = {1.00, 0.00, 0.00, 1.00},
								["ColorUnitFullHealthNoCombat"] = {0.00, 1.00, 0.00, 0.00},
								["ColorUnitZeroHealthNoCombat"] = {1.00, 0.00, 0.00, 0.25},
								["ColorReadyCheckWaiting"] = {0.35, 0.35, 0.35, 0.65},
								["ColorReadyCheckNotReady"] = {0.80, 0.35, 0.35, 0.65},
								["ColorBackground"] = {0.00, 0.00, 0.60, 0.60},
								["HealthBarAsBackground"] = true,
								["EnablePowerBar"] = false,
							}						
							for key, val in pairs(presetModern) do
								module:setOption("CTRAWindow" .. selectedWindow .. "_" .. key, val, true);
							end
							windows[selectedWindow]:Focus();
						end
					);
					optionsAddTooltip({"Modern", "Adopt a modern feel like many retail addons|n- Health bar fills the whole background|n- No power/mana bar|n- Health bar is hidden away outside combat|n- Health bar changes bright colors when injured#0.9:0.9:0.9"});
				optionsEndFrame();
				optionsBeginFrame(-10, 26, "checkbutton#tl:10:%y#n:CTRAWindow_HealthBarAsBackgroundCheckButton:false#" .. L["CT_RaidAssist/Options/Window/Appearance/HealthBarAsBackgroundCheckButton"]);
					optionsWindowizeObject("HealthBarAsBackground");
					optionsAddTooltip({L["CT_RaidAssist/Options/Window/Appearance/HealthBarAsBackgroundCheckButton"],L["CT_RaidAssist/Options/Window/Appearance/HealthBarAsBackgroundTooltip"] .. "#" .. textColor1});
				optionsEndFrame();
				optionsBeginFrame(0, 26, "checkbutton#tl:10:%y#n:CTRAWindow_EnablePowerBarCheckButton:true#" .. L["CT_RaidAssist/Options/Window/Appearance/EnablePowerBarCheckButton"]);
					optionsWindowizeObject("EnablePowerBar");
					optionsAddTooltip({L["CT_RaidAssist/Options/Window/Appearance/EnablePowerBarCheckButton"],L["CT_RaidAssist/Options/Window/Appearance/EnablePowerBarTooltip"] .. "#" .. textColor1});
				optionsEndFrame();
				optionsBeginFrame(0, 26, "checkbutton#tl:10:%y#n:CTRAWindow_EnableTargetFrameCheckButton:true#" .. L["CT_RaidAssist/Options/Window/Appearance/EnableTargetFrameCheckButton"]);
					optionsWindowizeObject("EnableTargetFrame");
					optionsAddTooltip({L["CT_RaidAssist/Options/Window/Appearance/EnableTargetFrameCheckButton"],L["CT_RaidAssist/Options/Window/Appearance/EnableTargetFrameTooltip"] .. "#" .. textColor1});
				optionsEndFrame();
				
				-- Buffs and Debuffs
				optionsAddObject(-10,   17, "font#tl:5:%y#v:GameFontNormal#" .. L["CT_RaidAssist/Options/Window/Auras/Heading"]);
				optionsAddObject(-21,   20, "font#l:tl:13:%y#" .. L["CT_RaidAssist/Options/Window/Auras/NoCombatLabel"] .. "#" .. textColor1 .. ":l");
				optionsBeginFrame(26,   20, "dropdown#tl:140:%y#s:110:%s#n:CTRAWindow_AuraFilterNoCombatDropDown" .. L["CT_RaidAssist/Options/Window/Auras/DropDown"]);
					optionsWindowizeObject("AuraFilterNoCombat");
				optionsEndFrame();				
				optionsAddObject(-21,   20, "font#l:tl:13:%y#" .. L["CT_RaidAssist/Options/Window/Auras/CombatLabel"] .. "#" .. textColor1 .. ":l");
				optionsBeginFrame(26,   20, "dropdown#tl:140:%y#s:110:%s#n:CTRAWindow_AuraFilterCombatDropDown" .. L["CT_RaidAssist/Options/Window/Auras/DropDown"]);
					optionsWindowizeObject("AuraFilterCombat");
				optionsEndFrame();
				optionsBeginFrame(-10, 15, "checkbutton#tl:10:%y#n:CTRAWindow_ShowBossAurasCheckButton#" .. L["CT_RaidAssist/Options/Window/Auras/ShowBossCheckButton"]);
					optionsWindowizeObject("ShowBossAuras");
					optionsAddTooltip({L["CT_RaidAssist/Options/Window/Auras/ShowBossCheckButton"],L["CT_RaidAssist/Options/Window/Auras/ShowBossTip"] .. "#" .. textColor1});
				optionsEndFrame();
				optionsBeginFrame(-10, 15, "checkbutton#tl:10:%y#n:CTRAWindow_ShowReverseCooldownCheckButton#" .. L["CT_RaidAssist/Options/Window/Auras/ShowReverseCooldownCheckButton"]);
					optionsWindowizeObject("ShowReverseCooldown");
					optionsAddTooltip({L["CT_RaidAssist/Options/Window/Auras/ShowReverseCooldownCheckButton"],L["CT_RaidAssist/Options/Window/Auras/ShowReverseCooldownTip"] .. "#" .. textColor1});
				optionsEndFrame();
				optionsBeginFrame(-10, 15, "checkbutton#tl:10:%y#n:CTRAWindow_RemovableDebuffColorCheckButton#" .. L["CT_RaidAssist/Options/Window/Auras/RemovableDebuffColorCheckButton"]);
					optionsWindowizeObject("RemovableDebuffColor");
					optionsAddTooltip({L["CT_RaidAssist/Options/Window/Auras/RemovableDebuffColorCheckButton"],L["CT_RaidAssist/Options/Window/Auras/RemovableDebuffColorTip"] .. "#" .. textColor1});
				optionsEndFrame();
				
				-- Colors
				optionsAddObject(-20, 17, "font#tl:5:%y#v:GameFontNormal#Colors");
				optionsAddObject(-5,  14, "font#tl:15:%y#s:0:%s#l:13:0#r#" .. L["CT_RaidAssist/Options/Window/Color/Line1"] .. "#" .. textColor2 .. ":l");
				optionsBeginFrame(-10, 0, "frame#tl:0:%y#br:tr:0:%b#");
					optionsAddScript("onload",
						function(frame)
							dummyFrame = NewCTRAPlayerFrame(
								{
									GetProperty = function(__, property)
										if (not selectedWindow) then
											windows[1] = NewCTRAWindow(self);
											selectedWindow = 1;
										end
										if (property) then
											return windows[selectedWindow]:GetProperty(property);
										--elseif (windows[1]) then
										--	return windows[1]:GetProperty(property);
										else
											return nil;
										end
									end
								},
								frame
							);
							if (not selectedWindow) then
								windows[1] = NewCTRAWindow(self);
								selectedWindow = 1;
							end
							dummyFrame:Enable("player", 5, 0 + 0.00001 * selectedWindow);
						end
					);
					for i, item in ipairs({
						{property = "ColorBackground", label = "Background Alive", tooltip = "Background when the unit is alive", hasAlpha = "true"},
						{property = "ColorBackgroundDeadOrGhost", label = "Background Dead", tooltip = "Background when the unit is dead or a ghost", hasAlpha = "true"},
						{property = "ColorBorder", label = "Border In Range", tooltip = "Border when the unit is within 30 yards"},
						{property = "ColorBorderBeyondRange", label = "Border Too Far", tooltip = "Border when the unit is not found within 30 yards"},
						{property = "ColorUnitFullHealthNoCombat", label = "Full Health No Combat", tooltip = "Color of the health bar at 100% outside combat"},
						{property = "ColorUnitZeroHealthNoCombat", label = "Near Death No Combat", tooltip = "Color of the health bar when nearly dead outside combat"},
						-- START OF LEFT COLUMN
						{property = "ColorUnitFullHealthCombat", label = "Full Health Combat", tooltip = "Color of the health bar at 100% during combat"},
						{property = "ColorUnitZeroHealthCombat", label = "Near Death Combat", tooltip = "Color of the health bar when nearly dead during combat"},
					}) do
						optionsBeginFrame((i == 7 and 37) or -5, 16, "colorswatch#tl:" .. ((i > 6 and "-10") or "130") .. ":%y#s:16:16#n:CTRAWindow_" .. item.property .. "ColorSwatch#true");  -- the final #true causes it to use alpha
							optionsWindowizeObject(item.property);
							optionsAddScript("onenter",
								function(swatch)
									local r, g, b, a = unpack(windows[selectedWindow]:GetProperty(item.property));
									module:displayTooltip(swatch, {item.tooltip .. "#" .. 1 - ((1-r)/3) .. ":" .. 1 - ((1-g)/3) .. ":" .. 1 - ((1-b)/3) , "Current:  |cFFFF6666r = " .. floor(100*r) .. "%|r, |cFF66FF66g = " .. floor(100*g) .. "%|r, |cFF6666FFb = " .. floor(100*b) .. ((a and ("%|r, |cFFFFFFFFa = " .. floor(100*a) .. "%")) or "%")}, "CT_ABOVEBELOW", 0, 0, CTCONTROLPANEL);
								end
							);
						optionsEndFrame();
						optionsAddObject(16, 16, "font#tl:" .. ((i > 6 and "10") or "150") .. ":%y#s:0:%s#l:13:0#r#" .. item.label .. "#" .. textColor1 .. ":l");
					end;
				optionsEndFrame();
								
				optionsAddObject(-5, 2*14, "font#tl:15:%y#s:0:%s#l:13:0#r#" .. L["CT_RaidAssist/Options/Window/Color/Line2"] .. "#" .. textColor2 .. ":l");

				optionsBeginFrame(-20, 17, "slider#tl:15:%y#s:110:%s#n:CTRAWindow_ColorBackgroundClassSlider#" .. L["CT_RaidAssist/Options/Window/Color/BackgroundClassSlider"] .. ":Off:100%#0:100:5");
					optionsWindowizeSlider("ColorBackgroundClass");
					optionsAddTooltip({L["CT_RaidAssist/Options/Window/Color/BackgroundClassHeading"],L["CT_RaidAssist/Options/Window/Color/BackgroundClassTip"] .. "#" .. textColor1});
				optionsEndFrame();
				optionsBeginFrame(17, 17, "slider#tl:150:%y#s:110:%s#n:CTRAWindow_ColorBorderClassSlider#" .. L["CT_RaidAssist/Options/Window/Color/BorderClassSlider"] .. ":Off:100%#0:100:5");
					optionsWindowizeSlider("ColorBorderClass");
					optionsAddTooltip({L["CT_RaidAssist/Options/Window/Color/BorderClassHeading"],L["CT_RaidAssist/Options/Window/Color/BorderClassTip"] .. "#" .. textColor1});
				optionsEndFrame();				
			
			optionsEndFrame();  -- end of the window
			
			-- this is called only once the entire frame has been created
			optionsAddScript("onshow",
				function()
					if (self:IsEnabled()) then
						windows[selectedWindow]:Focus();
						for i=1, (module:getOption("CTRAFrames_NumEnabledWindows") or 1) do
							windows[i]:ShowAnchor();
						end
						settingsOverlayToStopClicks:Hide();
					else
						settingsOverlayToStopClicks:Show();
					end
				end
			);
			
			optionsAddScript("onhide",
				function()
					for i=1, #(windows) do
						windows[i]:HideAnchor();
					end
				end
			);
		optionsEndFrame();  -- end of everything below the "enable CTRA frames" checkbox
		return;  -- nothing is returned because this is entirely encapsulated within the existing optionsFrameList event begun by CTRA:frame()
	end

	function obj:GetDummyFrame()
		return dummyFrame;
	end
	
	-- public constructor
	do
		listener = CreateFrame("Frame", nil);
		listener:RegisterEvent("PLAYER_ENTERING_WORLD");		-- defers creating the frames until the player is in the game
		listener:RegisterEvent("GROUP_ROSTER_UPDATE");			-- the frames might enable only during raids, groups, or always!
		listener:RegisterEvent("PLAYER_REGEN_ENABLED");			-- in case the player's membership in a group/raid changed during combat
		listener:HookScript("OnEvent",
			function(self, event)
				obj:ToggleEnableState();
				obj:Update();
				if (event == "PLAYER_ENTERING_WORLD") then
					-- a hack because SpellInfo() isn't quite ready at PLAYER_ENTERING_WORLD in Classic
					C_Timer.After(1, function() obj:Update(); end);		-- in case SpellInfo() is a split second late loading
					C_Timer.After(10, function() obj:Update(); end);	-- in case SpellInfo() is a few seconds late loading
				end
			end
		);	
		return obj;
	end
end


--------------------------------------------
-- CTRAWindow

function NewCTRAWindow(owningCTRAFrames)
	
	-- public interface
	local obj = { };

	-- private properties
	local owner = owningCTRAFrames;	-- pointer to the interface of CTRAFrames object that owns this window
	local windowID;			-- nil if disabled, or the number corresponding to which window this is
	local anchorFrame;		-- small movable anchor to orient the window
	local windowFrame;		-- appearance of the window itself
	local playerFrames = { };	-- CTRAPlayerFrame objects
	local targetFrames = { };	-- CTRATargetFrame objects
	local currentOptions = { };
	local defaultOptions = 		-- configuration data for the default options in showing a window
	{
		["ShowGroup1"] = true,		-- default is to show groups 1 to 8
		["ShowGroup2"] = true,
		["ShowGroup3"] = true,
		["ShowGroup4"] = true,
		["ShowGroup5"] = true,
		["ShowGroup6"] = true,
		["ShowGroup7"] = true,
		["ShowGroup8"] = true,
		["ShowMyself"] = false,
		["ShowTanks"] = false,
		["ShowHeals"] = false,
		["ShowMelee"] = false,
		["ShowRange"] = false,
		["ShowDeathKnights"] = false,
		["ShowDemonHunters"] = false,
		["ShowDruids"] = false,
		["ShowHunters"] = false,
		["ShowMages"] = false,
		["ShowMonks"] = false,
		["ShowPaladins"] = false,
		["ShowPriests"] = false,
		["ShowRogues"] = false,
		["ShowShamans"] = false,
		["ShowWarlocks"] = false,
		["ShowWarriors"] = false,
		["Orientation"] = 1,		-- columns
		["GrowUpward"] = false,
		["GrowLeft"] = false,
		["WrapAfter"] = 5,
		["HorizontalSpacing"] = 1,
		["VerticalSpacing"] = 1,
		["PlayerFrameScale"] = 100,
		["ColorUnitFullHealthCombat"] = {0.00, 1.00, 0.00, 1.00},
		["ColorUnitZeroHealthCombat"] = {0.00, 1.00, 0.00, 1.00},
		["ColorUnitFullHealthNoCombat"] = {0.00, 1.00, 0.00, 1.00},
		["ColorUnitZeroHealthNoCombat"] = {0.00, 1.00, 0.00, 1.00},
		["ColorBackground"] = {0.00, 0.10, 0.90, 0.50},
		["ColorBackgroundDeadOrGhost"] = {0.10, 0.10, 0.10, 0.50},
		["ColorBackgroundClass"] = 0,
		["ColorBorder"] = {1.00, 1.00, 1.00, 0.75},
		["ColorBorderBeyondRange"] = {0.10, 0.10, 0.10, 0.75},
		["ColorBorderClass"] = 0,
		["ColorReadyCheckWaiting"] = {0.45, 0.45, 0.45, 1.00},
		["ColorReadyCheckNotReady"] = {0.80, 0.45, 0.45, 1.00},
		["RemovableDebuffColor"] = true,
		["HealthBarAsBackground"] = false,
		["EnablePowerBar"] = true,
		["AuraFilterNoCombat"] = 1,
		["AuraFilterCombat"] = 2,
		["ShowBossAuras"] = true,
		["ShowReverseCooldown"] = true,
		["EnableTargetFrame"] = false,
	};

	-- private methods
	function obj:Enable(asWindow, copyFromWindow)
		assert(type(asWindow) == "number" and asWindow > 0, "CTRA Window being enabled without a valid number");
		if (InCombatLockdown()) then return; end
		
		
		-- STEP 1: If copyFromWindow then this window should clone the settings from something else before proceeding further
		-- STEP 2: If this window has never been enabled, then create its component windowFrame and anchorFrame
		-- STEP 3: If this window was not previously enabled, then register for all events
		-- STEP 4: Position the anchor via module:RegisterMovable
		-- STEP 5: Set flags to track the frame's enabled identity
		-- STEP 6: Initialize and/or update the child frames
		-- STEP 7: If the CT options are currently open, show the movable anchor

		
		
		-- STEP 1:
		if (copyFromWindow and type(copyFromWindow) == "number") then
			for key, __ in pairs(defaultOptions) do
				module:setOption("CTRAWindow" .. asWindow .. "_" .. key,module:getOption("CTRAWindow" .. copyFromWindow .. "_" .. key),true, false);
			end
		end
		
		-- STEP 2:
		if (not anchorFrame or not windowFrame) then
			-- anchor to handle positioning, with assistance from CT_Library
			anchorFrame = CreateFrame("Frame", nil, UIParent);
			anchorFrame:SetSize(80,20);
			anchorFrame:SetPoint("CENTER", -300/asWindow, UIParent:GetHeight()/(3 + asWindow)); -- causes multiple new windows to be sort of cascading
			anchorFrame:SetFrameLevel(4);	-- places it above windowFrame (1), and above the visualFrame (2) and secureButton (3) components of CTRAPlayerFrame
			anchorFrame.texture = anchorFrame:CreateTexture(nil,"BACKGROUND");
			anchorFrame.texture:SetAllPoints(true);
			anchorFrame.texture:SetColorTexture(1,1,0,0.5);
			anchorFrame:SetScript("OnMouseDown",
				function()
					if (windowID) then
						module:moveMovable("CTRAWindow" .. windowID)
					end
				end
			);
			anchorFrame:SetScript("OnMouseUp",
				function()
					if (windowID) then
						module:stopMovable("CTRAWindow" .. windowID)
					end
				end
			);
			anchorFrame:SetScript("OnEnter",
				function()
					module:displayTooltip(anchorFrame, {"Left-click to drag this window"}, "ANCHOR_TOPRIGHT");
				end
			);
			-- indicator which window this is
			anchorFrame.text = anchorFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
			anchorFrame.text:SetPoint("LEFT", anchorFrame, "LEFT", 10, 0);
			anchorFrame.text:SetTextColor(1,1,1,1);
			
			-- window that player frames reside in
			windowFrame = CreateFrame("Frame", nil, UIParent);
			windowFrame:SetScale((module:getGameVersion() == CT_GAME_VERSION_CLASSIC and 1) or 1.03);
			windowFrame:SetSize(1,1);	-- arbitrary, just to make it exist
			windowFrame:SetPoint("LEFT", anchorFrame, "LEFT");
			windowFrame:Show();
			windowFrame:SetScript("OnEvent",
				function(__, event)
					if (event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_REGEN_ENABLED") then
						self:Update();
					end
				end
			);
		end
		
		
		-- STEP 3:
		if (not self:IsEnabled()) then
			windowFrame:RegisterEvent("GROUP_ROSTER_UPDATE");
			windowFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
			windowFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
		end
		
		-- STEP 4:
		module:registerMovable("CTRAWindow" .. asWindow, anchorFrame, true);
		
		-- STEP 5:
		windowID = asWindow;
		
		-- STEP 6:
		self:Update();
		
		-- STEP 7:
		if (module:isControlPanelShown()) then
			self:ShowAnchor();
		else
			self:HideAnchor();
		end
		
		for key, __ in pairs(currentOptions) do
			currentOptions[key] = nil;
		end

		
	end
	
	function obj:Disable(deletePermanently)
		
		-- STEP 1: If deletePermanently then the settings for this window must be eliminated
		-- STEP 2: Deregister from all events
		-- STEP 3: Disable all child frames
		-- STEP 4: Disappear the anchor via module:UnregisterMovable
		-- STEP 5: Set flags to track the frame's disabled state
		-- STEP 6: Remove the anchor (which might already be hidden)
		
		-- STEP 1:
		if (deletePermanently and windowID) then
			for key, __ in pairs(defaultOptions) do
				module:setOption("CTRAWindow" .. windowID .. "_" .. key,nil,true,false);
			end
			module:resetMovable("CTRAWindow" .. windowID);
		end
		
		-- STEP 2:
		windowFrame:UnregisterEvent("GROUP_ROSTER_UPDATE");
		windowFrame:UnregisterEvent("PLAYER_ENTERING_WORLD");
		windowFrame:UnregisterEvent("PLAYER_REGEN_ENABLED");
		
		-- STEP 3:
		for __, playerframe in pairs(playerFrames) do
			playerframe:Disable();
		end
		for __, targetframe in pairs(targetFrames) do
			targetframe:Disable();
		end
		
		-- STEP 4:
		module:UnregisterMovable("CTRAWindow" .. windowID);
		self:HideAnchor();
		
		-- STEP 5:
		windowID = nil;		
	end
	
	function obj:IsEnabled()
		return windowID ~= nil;
	end
	
	function obj:GetWindowID()
		return windowID;
	end
	
	-- returns the value associated with this window, or returns
	function obj:GetProperty(option)
		local id = windowID or 1;		--even if CTRAFrames are disabled and no windowID has ever been set, the options menu might still ask a sample player frame and need to configur eit.
		if (currentOptions[option]) then
			return currentOptions[option];
		end
		local savedValue = module:getOption("CTRAWindow" .. id .. "_" .. option);
		if (savedValue ~= nil) then
			currentOptions[option] = savedValue;
			return savedValue;
		end
		currentOptions[option] = defaultOptions[option];
		return defaultOptions[option];
	end
	
	
	function obj:Update(option, value)
		-- STEP 1: Update children and local copies of saved variables
		-- STEP 2: If enabled, continue to steps 3 and 4.
		-- STEP 3: Outside combat, obtain a roster of self, party members and raid members to use during step 2
		-- STEP 4: Determine which players to show in this window, and construct/configure CTRAPlayerFrames accordingly
		
		-- STEP 1:
		if (option) then
			currentOptions[option] = value;
			for __, obj in ipairs(playerFrames) do
				obj:Update(option, value);
			end
			for __, obj in ipairs(targetFrames) do
				obj:Update(option, value);
			end
		end

		-- STEP 2:
		if (not obj:IsEnabled()) then
			return;
		end

		-- STEP 3:
		local roster = { };
		if (IsInRaid() or UnitExists("raid2")) then
			for i=1, min(MAX_RAID_MEMBERS, GetNumGroupMembers()) do
				local name, __, subgroup, __, __, fileName, __, __, __, role, __, combatRole = GetRaidRosterInfo(i);
				roster[i] = 
				{
					["name"] = name,
					["class"] = fileName,
					["role"] = (
						(combatRole ~= "NONE" and combatRole)  
						or role
						or GetSpecializationRoleByID(GetInspectSpecialization("raid" .. i))
					),
					["isPlayer"] = UnitIsUnit("raid" .. i, "player");
					["group"] = subgroup,
					["unit"] = "raid" .. i,
				}
			end
		else
			roster[1] = 
			{
				["name"] = UnitName("player"),
				["class"] = select(2, UnitClass("player")),
				["role"] = (
					UnitGroupRolesAssigned("player") 
					or GetSpecializationRoleByID(GetInspectSpecialization("player"))
				),
				["isPlayer"] = true,
				["group"] = 1,
				["unit"] = "player",
			}
			if (IsInGroup()) then
				for i=1, GetNumGroupMembers()-1 do
					roster[i+1] = 
					{
						["name"] = UnitName("party" .. i),
						["class"] = select(2, UnitClass("party" .. i)),
						["role"] = (
							UnitGroupRolesAssigned("party" .. i) 
							or GetSpecializationRoleByID(GetInspectSpecialization("party" .. i))
						),
						["isPlayer"] = false,
						["group"] = 1,
						["unit"] = "party" .. i,
					}
				end
			end
		end

		-- STEP 4:
		local categories =
		{
			-- {
			--	[1] = property,			-- name of the associated saved variable to check for, if this category is to be displayed
			--	[2] = sortFunc,			-- function to determine which units are included
			--	[3] = labelText,		-- label to show if ShowLabels is true (not yet implemented, 7 Jul 19)
			-- }

			{"ShowGroup1", function(rosterEntry) return rosterEntry.group == 1; end, "Gp 1",},
			{"ShowGroup2", function(rosterEntry) return rosterEntry.group == 2; end, "Gp 2",},
			{"ShowGroup3", function(rosterEntry) return rosterEntry.group == 3; end, "Gp 3",},
			{"ShowGroup4", function(rosterEntry) return rosterEntry.group == 4; end, "Gp 4",},
			{"ShowGroup5", function(rosterEntry) return rosterEntry.group == 5; end, "Gp 5",},
			{"ShowGroup6", function(rosterEntry) return rosterEntry.group == 6; end, "Gp 6",},
			{"ShowGroup7", function(rosterEntry) return rosterEntry.group == 7; end, "Gp 7",},
			{"ShowGroup8", function(rosterEntry) return rosterEntry.group == 8; end, "Gp 8",},		
			{	"ShowMyself",
				function(rosterEntry) return rosterEntry.isPlayer; end,
				"Me",
			},
			{
				"ShowTanks",
				function(rosterEntry) return rosterEntry.role == "TANK" or rosterEntry.role == "maintank" or rosterEntry.role == "mainassist"; end,
				"|TInterface\\AddOns\\CT_RaidAssist\\Images\\tankicon:0|t",
			},
			{
				"ShowHeals",
				function(rosterEntry) return rosterEntry.role == "HEALER"; end,
				"|TInterface\\AddOns\\CT_RaidAssist\\Images\\healicon:0|t",
			},
			{
				"ShowMelee",
				function(rosterEntry)
					return rosterEntry.role == "DAMAGER" and (
						rosterEntry.class == "WARRIOR"			
						or rosterEntry.class == "PALADIN"
						or (rosterEntry.class == "HUNTER" and GetInspectSpecialization(rosterEntry.unit) == 255)
						or rosterEntry.class == "ROGUE"
						or rosterEntry.class == "DEATHKNIGHT"
						or (rosterEntry.class == "SHAMAN" and GetInspectSpecialization(rosterEntry.unit) == 263)
						or rosterEntry.class == "MONK"
						or (rosterEntry.class == "DRUID" and GetInspectSpecialization(rosterEntry.unit) == 103)
						or rosterEntry.class == "DEMONHUNTER"
					);
				end,
				"|TInterface\\AddOns\\CT_RaidAssist\\Images\\dpsicon:0|t",
			},
			{
				"ShowRange",
				function(rosterEntry)
					return rosterEntry.role == "DAMAGER" and (
					(rosterEntry.class == "HUNTER" and GetInspectSpecialization(rosterEntry.unit) ~= 255)   --if GetInspectSpecialization fails (returns 0) then we assume ranged just to at least show the player in a frame
					or rosterEntry.class == "PRIEST"
					or (rosterEntry.class == "SHAMAN" and GetInspectSpecialization(rosterEntry.unit) ~= 263)
					or rosterEntry.class == "MAGE"
					or rosterEntry.class == "WARLOCK"
					or (rosterEntry.class == "DRUID" and GetInspectSpecialization(rosterEntry.unit) ~= 103)
					);
				end,
				"|TInterface\\AddOns\\CT_RaidAssist\\Images\\dpsicon:0|t",
			},
			{"ShowDeathKnights", function(rosterEntry) return rosterEntry.class == "DEATHKNIGHT"; end, "DK",},
			{"ShowDemonHunters", function(rosterEntry) return rosterEntry.class == "DEMONHUNTER"; end, "DH",},
			{"ShowDruids", function(rosterEntry) return rosterEntry.class == "DRUID"; end, "Dr",},
			{"ShowHunters", function(rosterEntry) return rosterEntry.class == "HUNTER"; end, "Hu",},
			{"ShowMages", function(rosterEntry) return rosterEntry.class == "MAGE"; end, "Ma",},
			{"ShowMonks", function(rosterEntry) return rosterEntry.class == "MONK"; end, "Mo",},
			{"ShowPaladins", function(rosterEntry) return rosterEntry.class == "PALADIN"; end, "Pa",},
			{"ShowPriests", function(rosterEntry) return rosterEntry.class == "PRIEST"; end, "Pr",},
			{"ShowRogues", function(rosterEntry) return rosterEntry.class == "ROGUE"; end, "Ro",},
			{"ShowShamans", function(rosterEntry) return rosterEntry.class == "SHAMAN"; end, "Sh",},
			{"ShowWarlocks", function(rosterEntry) return rosterEntry.class == "WARLOCK"; end, "Wk",},
			{"ShowWarriors", function(rosterEntry) return rosterEntry.class == "WARRIOR"; end, "Wr",},		
		};
		local x = 0;
		local y = 0;
		local w = 0;
		local rows = 0;
		local cols = 0;
		for __, frame in pairs(playerFrames) do
			frame:Disable();
		end
		for __, frame in pairs(targetFrames) do
			frame:Disable();
		end
		local playersShown = 0;
		for __, category in pairs(categories) do  -- (from step 2)
			if self:GetProperty(category[1]) then

				-- this group must be shown, if there is anyone in it to show
				for __, rosterEntry in ipairs(roster) do
					if category[2](rosterEntry) then

						-- show this person
						playersShown = playersShown + 1;
						if (not playerFrames[playersShown]) then
							playerFrames[playersShown] = NewCTRAPlayerFrame(self, windowFrame);
						end
						playerFrames[playersShown]:Enable(rosterEntry.unit, (self:GetProperty("GrowLeft") and -x) or x, (self:GetProperty("GrowUpward") and -y + 50) or y - 10);
						if (self:GetProperty("EnableTargetFrame")) then
							if (not targetFrames[playersShown]) then
								targetFrames[playersShown] = NewCTRATargetFrame(self, windowFrame);
							end
							targetFrames[playersShown]:Enable(rosterEntry.unit .. "target", (self:GetProperty("GrowLeft") and -x) or x, (self:GetProperty("GrowUpward") and -y + 12) or y - 48);	-- 38 lower than the associated playerFrame
						end

						-- move the anchor (and wrap to a new col/row if necessary) for the next person, and keep track of the max number of rows and columns in use
						w = w + 1;
						if (w == self:GetProperty("WrapAfter")) then
							if (self:GetProperty("Orientation") == 1 or self:GetProperty("Orientation") == 3) then
								x = x + 90 + self:GetProperty("HorizontalSpacing");
								y = 0;
								if (w > rows) then
									rows = w;
								end
								if (w == 1) then
									-- first entry in a new column!
									cols = cols + 1;
								end
							else
								x = 0;
								y = y - 40 - self:GetProperty("VerticalSpacing") - ((self:GetProperty("EnableTargetFrame") and 20) or 0);
								if (w > cols) then
									cols = w;
								end
								if (w == 1) then
									-- first entry in a new row!
									rows = rows + 1
								end
							end
							w = 0;
						else
							if (self:GetProperty("Orientation") == 1 or self:GetProperty("Orientation") == 3) then
								-- x = x;
								y = y - 40 - self:GetProperty("VerticalSpacing") - ((self:GetProperty("EnableTargetFrame") and 20) or 0);

								if (w > rows) then
									rows = w;
								end
								if (w == 1) then
									-- first entry in a new column!
									cols = cols + 1;
								end
							else
								x = x + 90 + self:GetProperty("HorizontalSpacing");
								-- y = y;
								if (w > cols) then
									cols = w;
								end
								if (w == 1) then
									-- first entry in a new row!
									rows = rows + 1
								end
							end
						end
					end
				end

				-- move the anchor to the start of a new row/col if appropriate
				if (w > 0 and (self:GetProperty("Orientation") == 1 or self:GetProperty("Orientation") == 2)) then
					w = 0;
					if (self:GetProperty("Orientation") == 1) then
						x = x + 90 + self:GetProperty("HorizontalSpacing");
						y = 0;
					else
						x = 0;
						y = y - 40 - self:GetProperty("VerticalSpacing") - ((self:GetProperty("EnableTargetFrame") and 20) or 0);
					end	
				end

			end
		end
	end
	
	function obj:Focus()
		if (not self:IsEnabled()) then
			return;
		end
		for key, __ in pairs(defaultOptions) do
			if (_G["CTRAWindow_" .. key .. "CheckButton"]) then
				_G["CTRAWindow_" .. key .. "CheckButton"]:Enable();
				_G["CTRAWindow_" .. key .. "CheckButton"]:SetChecked(self:GetProperty(key));
			elseif (_G["CTRAWindow_" .. key .. "DropDown"]) then
				local dropdown = _G["CTRAWindow_" .. key .. "DropDown"];
				UIDropDownMenu_EnableDropDown(dropdown)
				UIDropDownMenu_Initialize(dropdown, dropdown.initialize);
				UIDropDownMenu_SetSelectedValue(dropdown, self:GetProperty(key));
			elseif (_G["CTRAWindow_" .. key .. "Slider"]) then
				_G["CTRAWindow_" .. key .. "Slider"]:Enable();
				_G["CTRAWindow_" .. key .. "Slider"].suspend = 1;			-- hack to stop OnValueChanged from storing the value in SavedVariables
				_G["CTRAWindow_" .. key .. "Slider"]:SetValue(self:GetProperty(key));
				_G["CTRAWindow_" .. key .. "Slider"].suspend = nil;
			elseif (_G["CTRAWindow_" .. key .. "ColorSwatch"]) then
				local swatch = _G["CTRAWindow_" .. key .. "ColorSwatch"];
				swatch:Enable();
				local tex = swatch:GetNormalTexture();
				tex:SetVertexColor(unpack(self:GetProperty(key)));
			end
		end
		local dummyFrame = owner:GetDummyFrame();
		if (dummyFrame) then
			dummyFrame:Enable("player", 0, 0 + 0.00001 * windowID);
			dummyFrame:Update("PlayerFrameScale", self:GetProperty("PlayerFrameScale"));
		end
	end
	
	function obj:ShowAnchor()
		if (self:IsEnabled() and not InCombatLockdown()) then
			anchorFrame:Show();
			anchorFrame.text:SetText(format(L["CT_RaidAssist/WindowTitle"],windowID));
		else
			self:HideAnchor();
		end
	end
	
	function obj:HideAnchor()
		if (anchorFrame and not InCombatLockdown()) then
			anchorFrame:Hide();
		end
	end
	
	-- public constructor
	return obj;
end

--------------------------------------------
-- CTRAPlayerFrame

function NewCTRAPlayerFrame(parentInterface, parentFrame)
	
	-- PUBLIC INTERFACE
	
	local obj = { };
	
	-- PRIVATE PROPERTIES
	
	local owner;			-- pointer to the CTRAWindow interface for calling functions like :GetProperty()
	local parent;			-- pointer to the CTRAWindow's frame object that is a parent for the visualFrame
	local visualFrame;		-- generic frame that shows various textures
	local secureButton;		-- SecureUnitActionButton that sits in front and responds to mouseclicks
	local listenerFrame;		-- generic frame that listens to various events
	local requestedUnit;		-- the unit that this object is requested to display at the next opportunity
	local requestedXOff;		-- the x coordinate to position this object's frames at the next opportunity (relative to parent's left)w
	local requestedYOff;		-- the y coordinate to position this object's frames at the next opportunity (relative to parent's top)
	local shownUnit;		-- the unit that this object is currently showing (which cannot change during combat)
	local shownXOff;		-- the x coordinate this frame is currently showing
	local shownYOff;		-- the y coordinate this frame is currently showing
	local optionsWaiting = { };	-- a list of options that need to be triggered once combat ends
	
	-- graphical textures and fontstrings of visualFrame
	local background;
	local colorBackgroundRed, colorBackgroundGreen, colorBackgroundBlue, colorBackgroundAlpha;
	local colorBackgroundDeadOrGhostRed, colorBackgroundDeadOrGhostGreen, colorBackgroundDeadOrGhostBlue, colorBackgroundDeadOrGhostAlpha;
	local colorBorderRed, colorBorderGreen, colorBorderBlue, colorBorderAlpha;
	local colorBorderBeyondRangeRed, colorBorderBeyondRangeGreen, colorBorderBeyondRangeBlue, colorBorderBeyondRangeAlpha
	local healthBarFullCombat, healthBarZeroCombat, healthBarFullNoCombat, healthBarZeroNoCombat;
	local absorbBarFullCombat, absorbBarZeroCombat, absorbBarFullNoCombat, absorbBarZeroNoCombat;
	local healthBarWidth;
	local powerBar, powerBarWidth;
	local roleTexture;
	local unitNameFontStringLarge, unitNameFontStringSmall;
	local aura1Texture, aura2Texture, aura3Texture, aura4Texture, aura5Texture;
	local auraBoss1Texture, auraBoss2Texture, auraBoss3Texture;
	local aura1CooldownParent, aura2CooldownParent, aura3CooldownParent, aura4CooldownParent, aura5CooldownParent;
	local aura1Cooldown, aura2Cooldown, aura3Cooldown, aura4Cooldown, aura5Cooldown;
	local auraBoss1CooldownParent, auraBoss2CooldownParent, auraBoss3CooldownParent;
	local auraBoss1Cooldown, auraBoss2Cooldown, auraBoss3Cooldown;
	local auraBoss1CountFontString, auraBoss2CountFontString, auraBoss3CountFontString;
	local statusTexture, statusFontString, statusBackground;
	local durabilityAverage, durabilityBroken, durabilityTime;
	
	
	-- PRIVATE FUNCTIONS

	-- creates (if necessary) and configures all the settings for background and borders, but must not be run until visualFrame exists using self:Update()
	local function configureBackdrop()
		background = background or visualFrame:CreateTexture(nil, "BACKGROUND");
		background:SetPoint("TOPLEFT", visualFrame, 3, -3);
		background:SetPoint("BOTTOMRIGHT", visualFrame, -3, 3);
		colorBackgroundRed, colorBackgroundGreen, colorBackgroundBlue, colorBackgroundAlpha = unpack(owner:GetProperty("ColorBackground"));
		colorBackgroundDeadOrGhostRed, colorBackgroundDeadOrGhostGreen, colorBackgroundDeadOrGhostBlue, colorBackgroundDeadOrGhostAlpha = unpack(owner:GetProperty("ColorBackgroundDeadOrGhost"));
		
		visualFrame:SetBackdrop({["edgeFile"] = "Interface\\Tooltips\\UI-Tooltip-Border",["edgeSize"] = 16,});
		colorBorderRed, colorBorderGreen, colorBorderBlue, colorBorderAlpha = unpack(owner:GetProperty("ColorBorder"));
		colorBorderBeyondRangeRed, colorBorderBeyondRangeGreen, colorBorderBeyondRangeBlue, colorBorderBeyondRangeAlpha = unpack(owner:GetProperty("ColorBorderBeyondRange"));
	end
	
	-- updates the background and borders, but must not be run until configureBackdrop() has been done
	local function updateBackdrop()
		if (shownUnit and UnitExists(shownUnit)) then
			if (UnitIsDeadOrGhost(shownUnit)) then
				background:SetColorTexture(colorBackgroundDeadOrGhostRed, colorBackgroundDeadOrGhostGreen, colorBackgroundDeadOrGhostBlue, colorBackgroundDeadOrGhostAlpha);
				if (UnitInRange(shownUnit) or UnitIsUnit(shownUnit, "player")) then
					visualFrame:SetBackdropBorderColor(colorBorderRed, colorBorderGreen, colorBorderBlue, colorBorderAlpha);
				else
					visualFrame:SetBackdropBorderColor(colorBorderBeyondRangeRed, colorBorderBeyondRangeGreen, colorBorderBeyondRangeBlue, colorBorderBeyondRangeAlpha);
				end
			else
				local removableDebuff = select(4, UnitAura(shownUnit, 1, "RAID HARMFUL"));
				if (removableDebuff and owner:GetProperty("RemovableDebuffColor")) then
					local color = DebuffTypeColor[removableDebuff] or {r = 1, g = 0, b = 0};
					background:SetColorTexture(colorBackgroundRed/2 + color.r/2, colorBackgroundGreen/2 + color.g/2, colorBackgroundBlue/2 + color.b/2, colorBackgroundAlpha*0.8 + 0.2);
					if (UnitInRange(shownUnit) or UnitIsUnit(shownUnit, "player")) then
						visualFrame:SetBackdropBorderColor(color.r, color.g, color.b, colorBorderAlpha*0.8 + 0.2);
					else
						visualFrame:SetBackdropBorderColor(colorBorderBeyondRangeRed, colorBorderBeyondRangeGreen, colorBorderBeyondRangeBlue, colorBorderBeyondRangeAlpha);
					end
				else
					local classR, classG, classB = GetClassColor(select(2,UnitClass(shownUnit)));
					local ratio = owner:GetProperty("ColorBackgroundClass")/100;
					if (classR and ratio > 0) then
						background:SetColorTexture(colorBackgroundRed * (1-ratio) + classR * ratio, colorBackgroundGreen * (1-ratio) + classG * ratio, colorBackgroundBlue * (1-ratio) + classB * ratio, colorBackgroundAlpha);
					else
						background:SetColorTexture(colorBackgroundRed, colorBackgroundGreen, colorBackgroundBlue, colorBackgroundAlpha);
					end
					if (UnitInRange(shownUnit) or UnitIsUnit(shownUnit, "player")) then
						ratio = owner:GetProperty("ColorBorderClass")/100;
						if (classR and ratio > 0) then
							visualFrame:SetBackdropBorderColor(colorBorderRed * (1-ratio) + classR * ratio, colorBorderGreen * (1-ratio) + classG * ratio, colorBorderBlue * (1-ratio) + classB * ratio, colorBorderAlpha);
						else
							visualFrame:SetBackdropBorderColor(colorBorderRed, colorBorderGreen, colorBorderBlue, colorBorderAlpha);
						end
					else
						visualFrame:SetBackdropBorderColor(colorBorderBeyondRangeRed, colorBorderBeyondRangeGreen, colorBorderBeyondRangeBlue, colorBorderBeyondRangeAlpha);
					end
				end
			end
		end	

	end

	-- creates health and absorb bar textures	
	local function configureHealthBar()
		healthBarFullCombat = healthBarFullCombat or visualFrame:CreateTexture(nil, "ARTWORK");
		healthBarZeroCombat = healthBarZeroCombat or visualFrame:CreateTexture(nil, "ARTWORK");
		healthBarFullNoCombat = healthBarFullNoCombat or visualFrame:CreateTexture(nil, "ARTWORK");
		healthBarZeroNoCombat = healthBarZeroNoCombat or visualFrame:CreateTexture(nil, "ARTWORK");
		absorbBarFullCombat = absorbBarFullCombat or visualFrame:CreateTexture(nil, "ARTWORK");
		absorbBarZeroCombat = absorbBarZeroCombat or visualFrame:CreateTexture(nil, "ARTWORK");
		absorbBarFullNoCombat = absorbBarFullNoCombat or visualFrame:CreateTexture(nil, "ARTWORK");
		absorbBarZeroNoCombat = absorbBarZeroNoCombat or visualFrame:CreateTexture(nil, "ARTWORK");		

		healthBarFullCombat:SetTexture("Interface\\TargetingFrame\\UI-StatusBar");
		healthBarZeroCombat:SetTexture("Interface\\TargetingFrame\\UI-StatusBar");
		healthBarFullNoCombat:SetTexture("Interface\\TargetingFrame\\UI-StatusBar");
		healthBarZeroNoCombat:SetTexture("Interface\\TargetingFrame\\UI-StatusBar");
		absorbBarFullCombat:SetTexture("Interface\\TargetingFrame\\UI-StatusBar");
		absorbBarZeroCombat:SetTexture("Interface\\TargetingFrame\\UI-StatusBar");
		absorbBarFullNoCombat:SetTexture("Interface\\TargetingFrame\\UI-StatusBar");
		absorbBarZeroNoCombat:SetTexture("Interface\\TargetingFrame\\UI-StatusBar");
		
		
		if (owner:GetProperty("HealthBarAsBackground")) then
			healthBarFullCombat:SetPoint("TOPLEFT", visualFrame, "TOPLEFT", 4,  -4);
			healthBarFullCombat:SetPoint("BOTTOMLEFT", visualFrame, "BOTTOMLEFT", 4, 4);
			healthBarWidth = 82;
		else
			healthBarFullCombat:SetPoint("TOPLEFT", visualFrame, "BOTTOMLEFT", 10, 18);
			healthBarFullCombat:SetPoint("BOTTOMLEFT", visualFrame, "BOTTOMLEFT", 10, 12);
			healthBarWidth = 70;
		end
		
		healthBarZeroCombat:SetPoint("TOPLEFT", healthBarFullCombat);
		healthBarZeroCombat:SetPoint("BOTTOMRIGHT", healthBarFullCombat);
		
		healthBarFullNoCombat:SetPoint("TOPLEFT", healthBarFullCombat);
		healthBarFullNoCombat:SetPoint("BOTTOMRIGHT", healthBarFullCombat);
		
		healthBarZeroNoCombat:SetPoint("TOPLEFT", healthBarFullCombat);
		healthBarZeroNoCombat:SetPoint("BOTTOMRIGHT", healthBarFullCombat);
		
		absorbBarFullCombat:SetPoint("TOPLEFT", healthBarFullCombat, "TOPRIGHT");
		absorbBarFullCombat:SetPoint("BOTTOMLEFT", healthBarFullCombat, "BOTTOMRIGHT");
		
		absorbBarZeroCombat:SetPoint("TOPLEFT", absorbBarFullCombat);
		absorbBarZeroCombat:SetPoint("BOTTOMRIGHT", absorbBarFullCombat);
		
		absorbBarFullNoCombat:SetPoint("TOPLEFT", absorbBarFullCombat);
		absorbBarFullNoCombat:SetPoint("BOTTOMRIGHT", absorbBarFullCombat);
		
		absorbBarZeroNoCombat:SetPoint("TOPLEFT", absorbBarFullCombat);	
		absorbBarZeroNoCombat:SetPoint("BOTTOMRIGHT", absorbBarFullCombat);
		
		local r,g,b,a;
		r,g,b,a = unpack(owner:GetProperty("ColorUnitFullHealthCombat"));
		healthBarFullCombat:SetVertexColor(r,g,b);
		absorbBarFullCombat:SetVertexColor(r,g,b);
		healthBarFullCombat.maxAlpha = a;

		r,g,b,a = unpack(owner:GetProperty("ColorUnitZeroHealthCombat"));
		healthBarZeroCombat:SetVertexColor(r,g,b);
		absorbBarZeroCombat:SetVertexColor(r,g,b);
		healthBarZeroCombat.maxAlpha = a;
		
		r,g,b,a = unpack(owner:GetProperty("ColorUnitFullHealthNoCombat"));
		healthBarFullNoCombat:SetVertexColor(r,g,b);
		absorbBarFullNoCombat:SetVertexColor(r,g,b);
		healthBarFullNoCombat.maxAlpha = a;
		
		r,g,b,a = unpack(owner:GetProperty("ColorUnitZeroHealthNoCombat"));
		healthBarZeroNoCombat:SetVertexColor(r,g,b);
		absorbBarZeroNoCombat:SetVertexColor(r,g,b);
		healthBarZeroNoCombat.maxAlpha = a;
	
	end
	
	-- updates the health and absorb bars, but must only be called after configureHealthBar has been used at least once
	local function updateHealthBar()
		if (shownUnit) then
			if (UnitExists(shownUnit) and not UnitIsDeadOrGhost(shownUnit)) then
				-- the unit is alive and should have a health bar
				local healthRatio = UnitHealth(shownUnit) / UnitHealthMax(shownUnit);
				local absorbRatio = (UnitGetTotalAbsorbs(shownUnit) / UnitHealthMax(shownUnit)) or 0;  -- the actual value in WoW Retail, or 0 in WoW Classic
				if (healthRatio > 1) then
					healthRatio = 1;
				elseif (healthRatio < 0.001) then
					healthRatio = 0.001
				end
				if (healthRatio + absorbRatio > 1) then
					absorbRatio = 1 - healthRatio;
				end
				if (absorbRatio < 0.001) then
					absorbRatio = 0.001
				end
				healthBarFullCombat:SetWidth(healthBarWidth * healthRatio)
				absorbBarFullCombat:SetWidth(healthBarWidth * absorbRatio)
				if (InCombatLockdown()) then
					healthBarFullCombat:SetAlpha(healthRatio * healthBarFullCombat.maxAlpha);
					healthBarZeroCombat:SetAlpha((1 - healthRatio)  * healthBarZeroCombat.maxAlpha);
					healthBarFullNoCombat:SetAlpha(0);
					healthBarZeroNoCombat:SetAlpha(0);
					absorbBarFullCombat:SetAlpha(healthRatio /2 * healthBarFullCombat.maxAlpha);
					absorbBarZeroCombat:SetAlpha((1 - healthRatio) /2 * healthBarZeroCombat.maxAlpha);
					absorbBarFullNoCombat:SetAlpha(0);
					absorbBarZeroNoCombat:SetAlpha(0);
				else
					healthBarFullNoCombat:SetAlpha(healthRatio * healthBarFullNoCombat.maxAlpha);
					healthBarZeroNoCombat:SetAlpha((1 - healthRatio)  * healthBarZeroNoCombat.maxAlpha);				
					healthBarFullCombat:SetAlpha(0);
					healthBarZeroCombat:SetAlpha(0);
					absorbBarFullNoCombat:SetAlpha(healthRatio /2 * healthBarFullNoCombat.maxAlpha);
					absorbBarZeroNoCombat:SetAlpha((1 - healthRatio) /2 * healthBarZeroNoCombat.maxAlpha);				
					absorbBarFullCombat:SetAlpha(0);
					absorbBarZeroCombat:SetAlpha(0);
				end
			else
				-- the unit is dead, or maybe doesn't even exist, so show nothing!
				healthBarFullCombat:SetAlpha(0);
				healthBarZeroCombat:SetAlpha(0);
				healthBarFullNoCombat:SetAlpha(0);
				healthBarZeroNoCombat:SetAlpha(0);
				absorbBarFullCombat:SetAlpha(0);
				absorbBarZeroCombat:SetAlpha(0);
				absorbBarFullNoCombat:SetAlpha(0);
				absorbBarZeroNoCombat:SetAlpha(0);
			end
		end
	end
	
	-- creates the power bar, but must not be called until visualFrame is created
	local function configurePowerBar()
		powerBar = powerBar or visualFrame:CreateTexture(nil, "ARTWORK", nil, 1);
		powerBar:SetTexture("Interface\\TargetingFrame\\UI-StatusBar");
		powerBar:SetHeight(6);
		if (shownUnit and UnitExists(shownUnit)) then
			local powerType, powerToken, altR, altG, altB = UnitPowerType(shownUnit);
			local info = PowerBarColor[powerToken];
			if ( info ) then
				--The PowerBarColor takes priority
				powerBar:SetVertexColor(info.r, info.g, info.b);
			else
				if (not altR) then
					-- Couldn't find a power token entry. Default to indexing by power type or just mana if  we don't have that either.
					info = PowerBarColor[powerType] or PowerBarColor["MANA"];
					powerBar:SetVertexColor(info.r, info.g, info.b);
				else
					powerBar:SetVertexColor(altR, altG, altB);
				end
			end
		else
			local info = PowerBarColor["MANA"]
			powerBar:SetVertexColor(info.r, info.g, info.b);
		end
		if (owner:GetProperty("HealthBarAsBackground")) then	-- the powerBar shifts in size and location to align nicely with the healthBar
			powerBar:SetPoint("BOTTOMLEFT", visualFrame, 4, 4);		
		else
			powerBar:SetPoint("BOTTOMLEFT", visualFrame, 10, 6);
		end
		powerBarWidth = (owner:GetProperty("HealthBarAsBackground") and 82) or 70;
	end
	
	-- updates the power bar (mana, energy, etc.), but must not be called until after configurePowerBar
	local function updatePowerBar()
		if (shownUnit) then
			if (UnitExists(shownUnit) and not UnitIsDeadOrGhost(shownUnit) and owner:GetProperty("EnablePowerBar")) then
				local powerRatio = UnitPower(shownUnit) / UnitPowerMax(shownUnit);
				if (powerRatio < 0.01) then 
					powerBar:Hide();
				else 
					powerBar:SetWidth(powerBarWidth*min(1,powerRatio));
					powerBar:Show();
				end
				-- use the same alpha rules as the health bar for consistency... except base it on UnitPower == UnitPowerMax instead of Health == HealthMax
				if (InCombatLockdown()) then
					powerBar:SetAlpha(powerRatio > 0.99 and owner:GetProperty("ColorUnitFullHealthCombat")[4] or owner:GetProperty("ColorUnitZeroHealthCombat")[4]);
				else
					powerBar:SetAlpha(powerRatio > 0.99 and owner:GetProperty("ColorUnitFullHealthNoCombat")[4] or owner:GetProperty("ColorUnitZeroHealthNoCombat")[4]);
				end	
			else
				powerBar:Hide();
			end
		end
	end
	
	-- creates a texture to display the tank/heal/dps role icon in top left; but visualFrame must exist already
	local configureRoleTexture = function()
		roleTexture = roleTexture or visualFrame:CreateTexture(nil, "OVERLAY");
		roleTexture:SetSize(12,12);
		roleTexture:SetPoint("TOPLEFT", visualFrame, 1.80, -1.80);	
	end
	
	-- creates and updates the role icon in the top left
	local updateRoleTexture = function()
		if (shownUnit and UnitExists(shownUnit)) then
			local roleAssigned, targetIndex = UnitGroupRolesAssigned(shownUnit), GetRaidTargetIndex(shownUnit);
			if (targetIndex and targetIndex <= 8) then
				roleTexture:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons");
				if (targetIndex == 1) then
					roleTexture:SetTexCoord(0.00, 0.25, 0.00, 0.25);
				elseif (targetIndex == 2) then
					roleTexture:SetTexCoord(0.25, 0.50, 0.00, 0.25);
				elseif (targetIndex == 3) then
					roleTexture:SetTexCoord(0.50, 0.75, 0.00, 0.25);
				elseif (targetIndex == 4) then
					roleTexture:SetTexCoord(0.75, 1.00, 0.00, 0.25);
				elseif (targetIndex == 5) then
					roleTexture:SetTexCoord(0.00, 0.25, 0.25, 0.50);
				elseif (targetIndex == 6) then
					roleTexture:SetTexCoord(0.25, 0.50, 0.25, 0.50);
				elseif (targetIndex == 7) then
					roleTexture:SetTexCoord(0.50, 0.75, 0.25, 0.50);
				else
					roleTexture:SetTexCoord(0.75, 1.00, 0.25, 0.50);
				end
				roleTexture:Show();
			elseif (roleAssigned == "DAMAGER") then
				roleTexture:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES");
				roleTexture:SetTexCoord(0.3125, 0.609375, 0.34375, 0.640625);  -- GetTexCoordsForRoleSmallCircle("DAMAGER");
				roleTexture:Show();
			elseif (roleAssigned == "HEALER") then
				roleTexture:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES");
				roleTexture:SetTexCoord(0.3125, 0.609375, 0.015625, 0.3125);  -- GetTexCoordsForRoleSmallCircle("HEALER");
				roleTexture:Show();
			elseif (roleAssigned == "TANK") then
				roleTexture:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES");
				roleTexture:SetTexCoord(0, 0.296875, 0.34375, 0.640625);  -- GetTexCoordsForRoleSmallCircle("TANK");
				roleTexture:Show();
			else	-- no role assigned
				roleTexture:Hide();
			end
		end
	end
	
	local function configureStatusIndicators()
		statusTexture = statusTexture or visualFrame:CreateTexture(nil, "OVERLAY");
		statusTexture:SetPoint("BOTTOMLEFT", 1.80, 1.80);
		statusTexture:SetSize(15, 15);
		
		statusFontString = statusFontString or visualFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
		statusFontString:SetPoint("TOP", visualFrame, "CENTER");
		
		statusBackground = statusBackground or visualFrame:CreateTexture(nil, "ARTWORK", nil, 2); -- the 4th parameter, '2', draws this in front of the power bar
		statusBackground:SetPoint("TOPLEFT", 4, -4);
		statusBackground:SetPoint("BOTTOMRIGHT", -4, 4);
		statusBackground:SetColorTexture(1,1,1);
	end
	
	local function updateStatusIndicators()
		if (shownUnit and UnitExists(shownUnit)) then
			local summonStatus, readyStatus, afkStatus, connectionStatus = 
				IncomingSummonStatus(shownUnit), 		 -- at the top of the file, IncomingSummonStatus is defined as C_IncomingSummon.IncomingSummonStatus or it just returns zero in classic
				GetReadyCheckStatus(shownUnit),
				UnitIsAFK(shownUnit),
				UnitIsConnected(shownUnit)
			if (summonStatus > 0) then
				statusTexture:SetTexture(2470702);
				statusTexture:Show();
				statusFontString:Show()
				statusBackground:Show();
				if (summonStatus == 1) then		-- GetAtlasInfo("Raid-Icon-SummonPending")
					statusTexture:SetTexCoord(0.5390625, 0.7890625, 0.015625, 0.515625);
					statusFontString:SetText("Summoned");
					statusBackground:SetVertexColor(unpack(owner:GetProperty("ColorReadyCheckWaiting")));
				elseif (summonStatus == 2) then		-- GetAtlasInfo("Raid-Icon-SummonAccepted")
					statusTexture:SetTexCoord(0.0078125, 0.2578125, 0.15625, 0.515625);
					statusFontString:SetText("Arriving");
					statusBackground:SetVertexColor(unpack(owner:GetProperty("ColorReadyCheckWaiting")));
				else					-- GetAtlasInfo("Raid-Icon-SummonDeclined")
					statusTexture:SetTexCoord(0.2734375, 0.5234375, 0.015625, 0.515625);
					statusFontString:SetText("Declined");
					statusBackground:SetVertexColor(unpack(owner:GetProperty("ColorReadyCheckNotReady")));
				end
			elseif (readyStatus) then
				statusTexture:Show();
				if (readyStatus == "notready") then
					statusTexture:SetTexture(READY_CHECK_NOT_READY_TEXTURE);
					statusTexture:SetTexCoord(0,1,0,1);
					statusFontString:Show();
					statusFontString:SetText("Not Ready");
					statusBackground:Show();
					statusBackground:SetVertexColor(unpack(owner:GetProperty("ColorReadyCheckNotReady")));
				elseif (readyStatus == "waiting") then
					statusFontString:Show();
					statusBackground:Show();
					statusBackground:SetVertexColor(unpack(owner:GetProperty("ColorReadyCheckWaiting")));
					if ((durabilityAverage or 100) < (module:getOption("CTRA_MonitorDurability") or 50) and GetTime() - (durabilityTime or 0) < 30) then
						statusTexture:SetTexture(1121272);
						statusTexture:SetTexCoord(0.4609375, 0.5234375, 0.328125, 0.390625);
						statusFontString:SetText("Gear: " .. durabilityAverage .. "%");
					else
						statusTexture:SetTexture(READY_CHECK_WAITING_TEXTURE);
						statusTexture:SetTexCoord(0,1,0,1);
						statusFontString:SetText("No Reply");
					end
				else
					statusTexture:SetTexture(READY_CHECK_READY_TEXTURE);
					statusTexture:SetTexCoord(0,1,0,1);
					statusFontString:Hide();
					statusBackground:Hide();
				end
			elseif (afkStatus) then
				statusTexture:Hide();
				statusFontString:Show();
				statusFontString:SetText("AFK");
				statusBackground:Show();
				statusBackground:SetVertexColor(unpack(owner:GetProperty("ColorReadyCheckWaiting")));
			elseif (connectionStatus == false) then
				statusTexture:Hide();
				statusFontString:Show();
				statusFontString:SetText("DC");
				statusBackground:Show();
				statusBackground:SetVertexColor(unpack(owner:GetProperty("ColorReadyCheckNotReady")));
			else
				statusTexture:Hide();
				statusFontString:Hide();
				statusBackground:Hide();
			end
		else
			statusTexture:Hide();
			statusFontString:Hide();
			statusBackground:Hide();
		end
	end
	
	-- creates the font strings to dislay the unit's name, with customization to counter the ugly side effects of SetScale()
	local configureUnitNameFontString = function()

		-- limit memory usage by using the same FontObject for the whole module
		-- this intended to simulate the use of "static" keyword in other programming languages
		if (not module.GetUnitNameFontLarge) then	
			module.unitNameFontLarge = { }		
			module.GetUnitNameFontLarge = function(__, scale)
				if (not module.unitNameFontLarge[scale]) then
					module.unitNameFontLarge[scale] = CreateFont("CTRA_UnitNameLargeWithScale" .. scale);
					module.unitNameFontLarge[scale]:SetFont("Fonts\\FRIZQT__.TTF", 8 * scale);
				end
				return module.unitNameFontLarge[scale];
			end
		end

		if (not module.GetUnitNameFontSmall) then
			module.unitNameFontSmall = { }
			module.GetUnitNameFontSmall = function(__, scale)
				if (not module.unitNameFontSmall[scale]) then
					module.unitNameFontSmall[scale] = CreateFont("CTRA_UnitNameSmallWithScale" .. scale);
					module.unitNameFontSmall[scale]:SetFont("Fonts\\FRIZQT__.TTF", 7 * scale);
				end
				return module.unitNameFontSmall[scale];
			end
		end

		
		local scale = owner:GetProperty("PlayerFrameScale") / 100;
		
		unitNameFontStringLarge = unitNameFontStringLarge or visualFrame:CreateFontString(nil, "OVERLAY");
		unitNameFontStringLarge:SetIgnoreParentScale(true);
		unitNameFontStringLarge:SetFontObject(module:GetUnitNameFontLarge(scale));
		unitNameFontStringLarge:SetPoint("BOTTOMLEFT", visualFrame, "LEFT", 12 * scale, 1);	-- leave room for roleTexture
		unitNameFontStringLarge:SetPoint("BOTTOMRIGHT", visualFrame, "RIGHT", -12 * scale, 1);	-- leave room for aura icons
		unitNameFontStringLarge:SetHeight(8 * scale);	-- prevents a shift when the name is truncated
		
	
		unitNameFontStringSmall = unitNameFontStringSmall or visualFrame:CreateFontString(nil, "OVERLAY");
		unitNameFontStringSmall:SetIgnoreParentScale(true);
		unitNameFontStringSmall:SetFontObject(module:GetUnitNameFontSmall(scale));
		unitNameFontStringSmall:SetPoint("BOTTOMLEFT", visualFrame, "LEFT", 12 * scale, 1.5 * scale);		-- leave room for roleTexture
		unitNameFontStringSmall:SetPoint("BOTTOMRIGHT", visualFrame, "RIGHT", -12 * scale, 1.5 * scale);	-- leave room for aura icons
		unitNameFontStringSmall:SetHeight(7 * scale);	-- prevents a shift when the name is truncated
	end
	
	-- creates and updates the player's name
	local updateUnitNameFontString = function()
		if (shownUnit) then
			if (UnitExists(shownUnit)) then
				-- show the name, but omit the server
				local name;
				name = strsplit("-", UnitName(shownUnit), 2);
				local classR, classG, classB = GetClassColor(select(2,UnitClass(shownUnit)));
				if (strlen(name) < 10) then
					unitNameFontStringLarge:SetText(name);
					unitNameFontStringLarge:SetTextColor(classR, classG, classB);
					unitNameFontStringLarge:Show();
					unitNameFontStringSmall:Hide();
				else
					unitNameFontStringSmall:SetText(name);
					unitNameFontStringSmall:SetTextColor(classR, classG, classB);
					unitNameFontStringSmall:Show();
					unitNameFontStringLarge:Hide();
				end
			else
				unitNameFontStringLarge:Hide();
				unitNameFontStringSmall:Hide();
			end
		end
	end
	
	local configureAuras = function()
	
		local bgr, bgg, bgb, bga = unpack(owner:GetProperty("ColorBackground"));
		bgr, bgg, bgb, bga = bgr * 0.5, bgg * 0.5, bgb * 0.5, bga * 0.25 + 0.5
	
		aura1Texture = aura1Texture or visualFrame:CreateTexture(nil, "OVERLAY");
		aura1Texture:SetSize(10,10);
		aura1Texture:SetPoint("TOPRIGHT", visualFrame, -5, -5);
		aura1Texture:SetTexCoord(0.04,0.96,0.04,0.96);
		aura1CooldownParent = aura1CooldownParent or CreateFrame("Frame", nil, visualFrame);
		aura1CooldownParent:SetSize(10,10);
		aura1CooldownParent:SetPoint("TOPRIGHT", visualFrame, -5, -5);
		aura1Cooldown = aura1Cooldown or CreateFrame("Cooldown", nil, aura1CooldownParent, "CooldownFrameTemplate");
		aura1Cooldown:SetAllPoints();
		aura1Cooldown:SetDrawEdge(false);
		aura1Cooldown:SetReverse(true);
		aura1Cooldown:SetSwipeColor(bgr, bgg, bgb, bga);

		aura2Texture = aura2Texture or visualFrame:CreateTexture(nil, "OVERLAY");
		aura2Texture:SetSize(10,10);
		aura2Texture:SetPoint("TOPRIGHT", visualFrame, -5, -15);
		aura2Texture:SetTexCoord(0.04,0.96,0.04,0.96);
		aura2CooldownParent = aura2CooldownParent or CreateFrame("Frame", nil, visualFrame);
		aura2CooldownParent:SetSize(10,10);
		aura2CooldownParent:SetPoint("TOPRIGHT", visualFrame, -5, -15);
		aura2Cooldown = aura2Cooldown or CreateFrame("Cooldown", nil, aura2CooldownParent, "CooldownFrameTemplate");
		aura2Cooldown:SetAllPoints();
		aura2Cooldown:SetDrawEdge(false);
		aura2Cooldown:SetReverse(true);
		aura2Cooldown:SetSwipeColor(bgr, bgg, bgb, bga);
		
		aura3Texture = aura3Texture or visualFrame:CreateTexture(nil, "OVERLAY");
		aura3Texture:SetSize(10,10);
		aura3Texture:SetPoint("TOPRIGHT", visualFrame, -5, -25);
		aura3Texture:SetTexCoord(0.04,0.96,0.04,0.96);
		aura3CooldownParent = aura3CooldownParent or CreateFrame("Frame", nil, visualFrame);
		aura3CooldownParent:SetSize(10,10);
		aura3CooldownParent:SetPoint("TOPRIGHT", visualFrame, -5, -25);
		aura3Cooldown = aura3Cooldown or CreateFrame("Cooldown", nil, aura3CooldownParent, "CooldownFrameTemplate");
		aura3Cooldown:SetAllPoints();
		aura3Cooldown:SetDrawEdge(false);
		aura3Cooldown:SetReverse(true);
		aura3Cooldown:SetSwipeColor(bgr, bgg, bgb, bga);

		aura4Texture = aura4Texture or visualFrame:CreateTexture(nil, "OVERLAY");
		aura4Texture:SetSize(10,10);
		aura4Texture:SetPoint("TOPRIGHT", visualFrame, -15, -25);
		aura4Texture:SetTexCoord(0.04,0.96,0.04,0.96);
		aura4CooldownParent = aura4CooldownParent or CreateFrame("Frame", nil, visualFrame);
		aura4CooldownParent:SetSize(10,10);
		aura4CooldownParent:SetPoint("TOPRIGHT", visualFrame, -15, -25);
		aura4Cooldown = aura4Cooldown or CreateFrame("Cooldown", nil, aura4CooldownParent, "CooldownFrameTemplate");
		aura4Cooldown:SetAllPoints();
		aura4Cooldown:SetDrawEdge(false);
		aura4Cooldown:SetReverse(true);
		aura4Cooldown:SetSwipeColor(bgr, bgg, bgb, bga);
		
		aura5Texture = aura5Texture or visualFrame:CreateTexture(nil, "OVERLAY");
		aura5Texture:SetSize(10,10);
		aura5Texture:SetPoint("TOPRIGHT", visualFrame, -15, -15);
		aura5Texture:SetTexCoord(0.04,0.96,0.04,0.96);
		aura5CooldownParent = aura5CooldownParent or CreateFrame("Frame", nil, visualFrame);
		aura5CooldownParent:SetSize(10,10);
		aura5CooldownParent:SetPoint("TOPRIGHT", visualFrame, -15, -15);
		aura5Cooldown = aura5Cooldown or CreateFrame("Cooldown", nil, aura5CooldownParent, "CooldownFrameTemplate");
		aura5Cooldown:SetAllPoints();
		aura5Cooldown:SetDrawEdge(false);
		aura5Cooldown:SetReverse(true);
		aura5Cooldown:SetSwipeColor(bgr, bgg, bgb, bga);
		
		auraBoss1Texture = auraBoss1Texture or visualFrame:CreateTexture(nil, "OVERLAY");
		auraBoss1Texture:SetSize(11,11);
		auraBoss1Texture:SetTexCoord(0.04,0.96,0.04,0.96);
		auraBoss1CountFontString = auraBoss1CountFontString or visualFrame:CreateFontString(nil, "OVERLAY");
		auraBoss1CountFontString:SetFont("Fonts\\ARIALN.TTF", 7, "");
		auraBoss1CountFontString:SetPoint("TOP", auraBoss1Texture, "BOTTOM");
		auraBoss1CooldownParent = auraBoss1CooldownParent or CreateFrame("Frame", nil, visualFrame);
		auraBoss1CooldownParent:SetSize(10,10);
		auraBoss1CooldownParent:SetPoint("CENTER", auraBoss1Texture);
		auraBoss1Cooldown = auraBoss1Cooldown or CreateFrame("Cooldown", nil, auraBoss1CooldownParent, "CooldownFrameTemplate");
		auraBoss1Cooldown:SetAllPoints();
		auraBoss1Cooldown:SetDrawEdge(false);
		auraBoss1Cooldown:SetReverse(true);
		auraBoss1Cooldown:SetSwipeColor(bgr, bgg, bgb, bga);
		
		auraBoss2Texture = auraBoss2Texture or visualFrame:CreateTexture(nil, "OVERLAY");
		auraBoss2Texture:SetSize(11,11);
		auraBoss2Texture:SetTexCoord(0.04,0.96,0.04,0.96);
		auraBoss2Texture:SetPoint("LEFT", auraBoss1Texture, "RIGHT", 1, 0);
		auraBoss2CountFontString = auraBoss2CountFontString or visualFrame:CreateFontString(nil, "OVERLAY");
		auraBoss2CountFontString:SetFont("Fonts\\ARIALN.TTF", 7, "");
		auraBoss2CountFontString:SetPoint("TOP", auraBoss2Texture, "BOTTOM");
		auraBoss2CooldownParent = auraBoss2CooldownParent or CreateFrame("Frame", nil, visualFrame);
		auraBoss2CooldownParent:SetSize(10,10);
		auraBoss2CooldownParent:SetPoint("LEFT", auraBoss1Texture, "RIGHT", 1, 0);
		auraBoss2Cooldown = auraBoss2Cooldown or CreateFrame("Cooldown", nil, auraBoss2CooldownParent, "CooldownFrameTemplate");
		auraBoss2Cooldown:SetAllPoints();
		auraBoss2Cooldown:SetDrawEdge(false);
		auraBoss2Cooldown:SetReverse(true);
		auraBoss2Cooldown:SetSwipeColor(bgr, bgg, bgb, bga);
		
		auraBoss3Texture = auraBoss3Texture or visualFrame:CreateTexture(nil, "OVERLAY");
		auraBoss3Texture:SetSize(11,11);
		auraBoss3Texture:SetTexCoord(0.04,0.96,0.04,0.96);
		auraBoss3Texture:SetPoint("LEFT", auraBoss2Texture, "RIGHT", 1, 0);
		auraBoss3CountFontString = auraBoss3CountFontString or visualFrame:CreateFontString(nil, "OVERLAY");
		auraBoss3CountFontString:SetFont("Fonts\\ARIALN.TTF", 7, "");
		auraBoss3CountFontString:SetPoint("TOP", auraBoss3Texture, "BOTTOM");
		auraBoss3CooldownParent = auraBoss3CooldownParent or CreateFrame("Frame", nil, visualFrame);
		auraBoss3CooldownParent:SetSize(10,10);
		auraBoss3CooldownParent:SetPoint("LEFT", auraBoss2Texture, "RIGHT", 1, 0);
		auraBoss3Cooldown = auraBoss3Cooldown or CreateFrame("Cooldown", nil, auraBoss3CooldownParent, "CooldownFrameTemplate");
		auraBoss3Cooldown:SetAllPoints();
		auraBoss3Cooldown:SetDrawEdge(false);
		auraBoss3Cooldown:SetReverse(true);
		auraBoss3Cooldown:SetSwipeColor(bgr, bgg, bgb, bga);
	end
	
	-- creates and updates buff/debuff icons; however, an update only occurs once every 0.1 seconds
--	local aurasLastUpdated = 0;
--	local aurasUpdatePlanned = false;
	local function updateAuras()
		
		-- STEP 1: perform steps 2 and 3 no more than once every 0.1 seconds				-- CURRENTLY DISABLED... DOESN'T SEEM NECESSARY
		-- STEP 2: selected buffs and debuffs for boss encounters, at the middle of the frame
		-- STEP 3: all other buffs and debuffs, filtered, at the right edge of the frame

		-- STEP 1:
--[[		local elapsed = GetTime() - aurasLastUpdated;
		if (elapsed < 0.1) then
			if (not aurasUpdatePlanned) then
				aurasUpdatePlanned = true;
				C_Timer.After(elapsed, updateAuras);
			end
			print("update pending");
			return;
		else
			print("updating now");
			aurasUpdatePlanned = false;
			aurasLastUpdated = GetTime();
		end
--]]		
		
		if (shownUnit) then
			
			-- STEP 2:
			local numBossShown = 0;
			if(UnitExists(shownUnit) and owner:GetProperty("ShowBossAuras")) then		
				for auraIndex = 1, 40 do
					local name, icon, count, debuffType, duration, expirationTime, __, __, __, spellId = UnitAura(shownUnit, auraIndex, "");
					if (not name or numBossShown == 3) then
						break;
					elseif (module.CTRA_Configuration_BossAuras[spellId] and (count or 0) >= module.CTRA_Configuration_BossAuras[spellId]) then
						numBossShown = numBossShown + 1;
						local tex = (numBossShown == 1 and auraBoss1Texture) or (numBossShown == 2 and auraBoss2Texture) or auraBoss3Texture;
						local cooldown = (numBossShown == 1 and auraBoss1Cooldown) or (numBossShown == 2 and auraBoss2Cooldown) or auraBoss3Cooldown;
						tex:SetTexture(icon);
						tex:Show();
						tex.name = name;
						tex.count = count;
						tex.debuffType = debuffType;
						local string = (numBossShown == 1 and auraBoss1CountFontString) or (numBossShown == 2 and auraBoss2CountFontString) or auraBoss3CountFontString;
						if ((count or 0) > 1) then
							local color = DebuffTypeColor[debuffType or ""];
							string:SetText(count);
							string:SetTextColor(1 - (1-color.r)/2, 1 - (1-color.g)/2, 1 - (1-color.b)/2);
							string:Show();
						else
							string:Hide();
						end
						if (owner:GetProperty("ShowReverseCooldown") and duration and duration >= 12 and expirationTime and expirationTime > 0) then
							print(name .. " has duration " .. duration .. " and expires at " .. expirationTime);
							cooldown:SetCooldown(expirationTime - duration * 0.4, duration * 0.4);
						else
							cooldown:Clear();
						end
					end
				end
				auraBoss1Texture:SetPoint("TOPLEFT", visualFrame, "CENTER", 0.5 - (numBossShown * 6), 1);
			end
			while (numBossShown  < 3) do
				numBossShown = numBossShown + 1;
				local tex = (numBossShown == 1 and auraBoss1Texture) or (numBossShown == 2 and auraBoss2Texture) or auraBoss3Texture;
				tex:Hide();
				local string = (numBossShown == 1 and auraBoss1CountFontString) or (numBossShown == 2 and auraBoss2CountFontString) or auraBoss3CountFontString;
				string:Hide();
				local cooldown = (numBossShown == 1 and auraBoss1Cooldown) or (numBossShown == 2 and auraBoss2Cooldown) or auraBoss3Cooldown;
				cooldown:Clear();
			end
			
			-- STEP 3:
			local numShown = 0;
			local filterType = (InCombatLockdown() and owner:GetProperty("AuraFilterCombat") or owner:GetProperty("AuraFilterNoCombat"));
			if(UnitExists(shownUnit) and not UnitIsDeadOrGhost(shownUnit) and filterType ~= 6) then	
				local filterText;
				if (filterType == 1) then
					filterText = "RAID HELPFUL";	-- default out of combat
				elseif (filterType == 2) then
					filterText = "RAID HARMFUL";	-- default in combat
				elseif (filterType == 3) then
					filterText = "HELPFUL";
				elseif (filterType == 4) then
					filterText = "HARMFUL";
				elseif (filterType == 5) then
					filterText = "HELPFUL";		-- further filtered by conditional statements during for loop below
				end
				for auraIndex = 1, 40 do
					local name, icon, count, debuffType, duration, expirationTime, source, __, __, spellId = UnitAura(shownUnit, auraIndex, filterText);
					if (not name or not spellId or numShown == 5) then
						break;
					elseif(
						not (owner:GetProperty("ShowBossAuras") and (module.CTRA_Configuration_BossAuras[spellId] and (count or 0) >= module.CTRA_Configuration_BossAuras[spellId]))
						and (filterType == 2 or filterType == 4 or not SpellIsSelfBuff(spellId))			-- excludes self-only buffs
						and (filterType ~= 5 or source == "player" or source == "vehicle" or source == "pet")		-- complements filterType == 5  (buffs cast by the player only)
					) then
						numShown = numShown + 1;
						local tex = (numShown == 1 and aura1Texture) or (numShown == 2 and aura2Texture) or (numShown == 3 and aura3Texture) or (numShown == 4 and aura4Texture) or aura5Texture;
						local cooldown = (numShown == 1 and aura1Cooldown) or (numShown == 2 and aura2Cooldown) or (numShown == 3 and aura3Cooldown) or (numShown == 4 and aura4Cooldown) or aura5Cooldown;
						tex:SetTexture(icon);
						tex:Show();
						tex.name = name;
						tex.count = count;
						tex.debuffType = debuffType;
						if (owner:GetProperty("ShowReverseCooldown") and duration and duration >= 15 and expirationTime and expirationTime > 0) then
							cooldown:SetCooldown(expirationTime - duration * 0.3, duration * 0.3);
						else
							cooldown:Clear();
						end
					end
				end
			end
			while (numShown < 5) do
				numShown = numShown + 1;
				local tex = (numShown == 1 and aura1Texture) or (numShown == 2 and aura2Texture) or (numShown == 3 and aura3Texture) or (numShown == 4 and aura4Texture) or aura5Texture;
				local cooldown = (numShown == 1 and aura1Cooldown) or (numShown == 2 and aura2Cooldown) or (numShown == 3 and aura3Cooldown) or (numShown == 4 and aura4Cooldown) or aura5Cooldown;
				tex:Hide();
				cooldown:Clear();
			end
		end
	end
	
	-- returns a table with nomod, mod:shift, mod:ctrl or mod:alt as a key and then a valid spellName as a value
	local canRezCombat = function()
		local __, class = UnitClass("player");
		if (module.CTRA_Configuration_RezAbilities[class]) then
			local combatRezToCast = { };
			local hasRez = nil;
			for __, details in ipairs(module.CTRA_Configuration_RezAbilities[class]) do
				if (GetSpellInfo(L["CT_RaidAssist/Spells/" .. details.name]) and details.combat and (details.gameVersion == nil or details.gameVersion == module:getGameVersion()) and combatRezToCast[details.modifier] == nil) then
					combatRezToCast[details.modifier] = L["CT_RaidAssist/Spells/" .. details.name];
					hasRez = true;
				end
			end
			if (hasRez) then
				return combatRezToCast;
			end
		end
		return nil;
	end
	
	-- returns a table with nomod, mod:shift, mod:ctrl or mod:alt as a key and then a valid spellName as a value
	local canRezNoCombat = function()
		local __, class = UnitClass("player");
		if (module.CTRA_Configuration_RezAbilities[class]) then
			local nocombatRezToCast = { };
			local hasRez = nil;
			for __, details in ipairs(module.CTRA_Configuration_RezAbilities[class]) do
				if (GetSpellInfo(L["CT_RaidAssist/Spells/" .. details.name]) and details.nocombat and (details.gameVersion == nil or details.gameVersion == module:getGameVersion()) and nocombatRezToCast[details.modifier] == nil) then
					nocombatRezToCast[details.modifier] = L["CT_RaidAssist/Spells/" .. details.name];
					hasRez = true;
				end
			end
			if (hasRez) then
				return nocombatRezToCast;
			end
		end
		return nil;
	end

	-- returns two tables:
	--    the first table has nomod, mod:shift, mod:ctrl or mod:alt as a key and then a valid spellName as a value
	--    the second table is a simple list of debuffs the player can do something about where [1] is magic, [2] is curse, [3] is poison and [4] is disease, and the value is the name of the spell whose cooldown should be checked
	local canRemoveDebuff = function()				
		local __, class = UnitClass("player");
		local spec = GetInspectSpecialization("player");
		if (module.CTRA_Configuration_FriendlyRemoves[class]) then
			local friendlyRemovesToCast = { };
			local hasFriendlyRemoves = nil;
			for __, details in ipairs(module.CTRA_Configuration_FriendlyRemoves[class]) do
				if (GetSpellInfo(L["CT_RaidAssist/Spells/" .. details.name]) and (details.gameVersion == nil or details.gameVersion == module:getGameVersion()) and friendlyRemovesToCast[details.modifier] == nil and (details.spec == nil or spec == nil or details.spec == spec)) then
					friendlyRemovesToCast[details.modifier] = L["CT_RaidAssist/Spells/" .. details.name];
					hasFriendlyRemoves = true;
				end
			end
			if (hasFriendlyRemoves) then
				return friendlyRemovesToCast;
			end
		end
		return nil;
	end

	-- returns two tables:
	--    the first table has nomod, mod:shift, mod:ctrl or mod:alt as a key and then a valid spellName as a value
	--    the second table are a list of spells that should be checked to ensure they are not missing, using spellName as key and then a table with 'scope' (default: "raid") and 'noStack' (default: nil)
	local canBuff = function()				
		local __, class = UnitClass("player");
		if (module.CTRA_Configuration_Buffs[class]) then
			local buffsToCast = { };
			local hasBuffs = nil;
			for __, details in ipairs(module.CTRA_Configuration_Buffs[class]) do
				if (GetSpellInfo(L["CT_RaidAssist/Spells/" .. details.name]) and (details.gameVersion == nil or details.gameVersion == module:getGameVersion()) and (buffsToCast[details.modifier] == nil)) then
					buffsToCast[details.modifier] = L["CT_RaidAssist/Spells/" .. details.name];
					hasBuffs = true;
				end
			end
			if (hasBuffs) then
				return buffsToCast;
			end
		end
		return nil;
	end
	
	-- updates secureButton macros once out of combat
	local updateMacros = function()
		if (InCombatLockdown()) then return; end
		
		-- left click just targets
		secureButton:SetAttribute("*macrotext1", "/target " .. shownUnit);
		
		-- right click does several things
		local macroRight = ""
		local rezCombat = canRezCombat();
		local rezNoCombat = canRezNoCombat();
		local removeDebuff = canRemoveDebuff();
		local applyBuff = canBuff();
		if (rezCombat or rezNoCombat or removeDebuff or applyBuff) then
			macroRight = macroRight .. "/cast";
			if (rezCombat) then						-- [@party1, exists, dead, combat, nomod] Rebirth;
				for modifier, spellName in pairs(rezCombat) do
					macroRight = macroRight .. " [@" .. shownUnit .. ", exists, dead, combat, " .. modifier .. "] " .. spellName .. ";";
				end
			end			
			if (rezNoCombat) then						-- [@party1, exists, dead, nocombat, nomod] Resurrection;
				for modifier, spellName in pairs(rezNoCombat) do
					macroRight = macroRight .. " [@" .. shownUnit .. ", exists, dead, nocombat, " .. modifier .. "] " .. spellName .. ";";
				end
			end
			if (removeDebuff) then						-- [@party1, exists, nodead, combat, nomod] Abolish Poison; [@party1, nodead, combat, mod:shift] Remove Curse;
				for modifier, spellName in pairs(removeDebuff) do
					macroRight = macroRight .. " [@" .. shownUnit .. ", exists, nodead, combat, " .. modifier .. "] " .. spellName .. ";";
				end
			end	
			if (applyBuff) then						-- [@party1, exists, nodead, nocombat, nomod] Arcane Intellect; [@party1, nodead, nocombat, mod:shift] Arcane Brilliance;
				for modifier, spellName in pairs(applyBuff) do
					macroRight = macroRight .. " [@" .. shownUnit .. ", exists, nodead, nocombat, " .. modifier .. "] " .. spellName .. ";";
				end
			end
		end
		secureButton:SetAttribute("*macrotext2", macroRight);
	end
	
	local function updateDurability(percent, broken, sender, __)
		if (shownUnit and sender == UnitName(shownUnit)) then
			durabilityAverage = percent;
			durabilityBroken = broken;
			durabilityTime = GetTime();
			updateStatusIndicators();
		end
	end
	
	local function clearDurability()
		durabilityAverage, durabilityBroken, durabilityTime = nil, nil, nil;
	end
	
	-- PUBLIC FUNCTIONS
	
	function obj:Enable(unit, xOff, yOff)
		if (not unit) then
			self:Disable();
			return;
		end
		requestedUnit = unit;
		requestedXOff = xOff;
		requestedYOff = yOff;
		self:Update();
	end
	
	function obj:Disable()
		requestedUnit = nil;
		requestedXOff = nil;
		requestedYOff = nil;
		self:Update();
	end
	
	function obj:IsEnabled()
		return requestedUnit ~= nil
	end
	
	function obj:IsShown()
		return shownUnit ~= nil
	end
	
	function obj:Update(option, value)
		-- STEP 1: Construct the secureButton and visualFrame if required, but only while out of combat, before proceeding to any of the following steps
		-- STEP 2: Respond to changes in the CTRA options affecting how the frames should appear and behaive, but only while out of combat
		-- STEP 3: Respond to changes directed by the parent window (requestedUnit, requestedXOff, requestedYOff) while respecting combat limitations


		-- STEP 1
		if not visualFrame or not secureButton then
			if InCombatLockdown() then
				return;
			else
				-- overall dimensions
				visualFrame = CreateFrame("Frame", nil, parent, nil);
				visualFrame:SetSize(90, 40);
				visualFrame:SetScale(owner:GetProperty("PlayerFrameScale")/100);
								
				-- overlay button that can be clicked to do stuff in combat (the secure configuration is made later in step 3)
				secureButton = CreateFrame("Button", nil, visualFrame, "SecureUnitButtonTemplate");
				secureButton:SetAllPoints();
				secureButton:RegisterForClicks("AnyDown");
				secureButton:SetAttribute("*type1", "macro");
				secureButton:SetAttribute("*type2", "macro");
				secureButton:HookScript("OnEnter",
					function()
						if (UnitExists(shownUnit)) then
							GameTooltip:SetOwner(parent, (owner:GetProperty("GrowUpward") and "ANCHOR_BOTTOMRIGHT") or "ANCHOR_TOPLEFT");
							local className, classFilename = UnitClass(shownUnit);
							local r,g,b = GetClassColor(classFilename);
							GameTooltip:AddDoubleLine(UnitName(shownUnit) or "", UnitLevel(shownUnit) or "", r,g,b, 1,1,1);
							local mapid = C_Map.GetBestMapForUnit(shownUnit);
							GameTooltip:AddDoubleLine((UnitRace(shownUnit) or "") .. " " .. (className or ""), (not UnitInRange(shownUnit) and mapid and C_Map.GetMapInfo(mapid).name) or "", 1, 1, 1, 0.5, 0.5, 0.5);
							if (auraBoss1Texture:IsShown()) then
								local color = DebuffTypeColor[auraBoss1Texture.debuffType or ""];
								GameTooltip:AddLine("|T" .. auraBoss1Texture:GetTexture() .. ":0|t " .. (auraBoss1Texture.name or "") .. ((auraBoss1Texture.count or 0) > 1 and (" (" .. auraBoss1Texture.count .. ")") or ""), color and color["r"], color and color["g"], color and color["b"]);
								if (auraBoss2Texture:IsShown()) then
									color = DebuffTypeColor[auraBoss2Texture.debuffType or ""];
									GameTooltip:AddLine("|T" .. auraBoss2Texture:GetTexture() .. ":0|t " .. (auraBoss2Texture.name or "") .. ((auraBoss2Texture.count or 0) > 1 and (" (" .. auraBoss2Texture.count .. ")") or ""), color and color["r"], color and color["g"], color and color["b"]);
									if (auraBoss3Texture:IsShown()) then
										color = DebuffTypeColor[auraBoss3Texture.debuffType or ""];
										GameTooltip:AddLine("|T" .. auraBoss3Texture:GetTexture() .. ":0|t " .. (auraBoss3Texture.name or "") .. ((auraBoss3Texture.count or 0) > 1 and (" (" .. auraBoss3Texture.count .. ")") or ""), color and color["r"], color and color["g"], color and color["b"]);
									end
								end
							end
							if (aura1Texture:IsShown()) then
								local color = DebuffTypeColor[aura1Texture.debuffType or ""];
								GameTooltip:AddLine("|T" .. aura1Texture:GetTexture() .. ":0|t " .. (aura1Texture.name or "") .. ((aura1Texture.count or 0) > 1 and (" (" .. aura1Texture.count .. ")") or ""), color and color["r"], color and color["g"], color and color["b"]);
								if (aura2Texture:IsShown()) then
									color = DebuffTypeColor[aura2Texture.debuffType or ""];
									GameTooltip:AddLine("|T" .. aura2Texture:GetTexture() .. ":0|t " .. (aura2Texture.name or "") .. ((aura2Texture.count or 0) > 1 and (" (" .. aura2Texture.count .. ")") or ""), color and color["r"], color and color["g"], color and color["b"]);
									if (aura3Texture:IsShown()) then
										color = DebuffTypeColor[aura3Texture.debuffType or ""];
										GameTooltip:AddLine("|T" .. aura3Texture:GetTexture() .. ":0|t " .. (aura3Texture.name or "") .. ((aura3Texture.count or 0) > 1 and (" (" .. aura3Texture.count .. ")") or ""), color and color["r"], color and color["g"], color and color["b"]);
										if (aura4Texture:IsShown()) then
											color = DebuffTypeColor[aura4Texture.debuffType or ""];
											GameTooltip:AddLine("|T" .. aura4Texture:GetTexture() .. ":0|t " .. (aura4Texture.name or "") .. ((aura4Texture.count or 0) > 1 and (" (" .. aura4Texture.count .. ")") or ""), color and color["r"], color and color["g"], color and color["b"]);
											if (aura5Texture:IsShown()) then
												color = DebuffTypeColor[aura5Texture.debuffType or ""];
												GameTooltip:AddLine("|T" .. aura5Texture:GetTexture() .. ":0|t " .. (aura5Texture.name or "") .. ((aura5Texture.count or 0) > 1 and (" (" .. aura5Texture.count .. ")") or ""), color and color["r"], color and color["g"], color and color["b"]);
											end
										end
									end
								end
							end

							if (not module.GameTooltipExtraLine) then
								module.GameTooltipExtraLine = GameTooltip:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
								module.GameTooltipExtraLine:SetPoint("BOTTOM", 0, 6);
								module.GameTooltipExtraLine:SetText(L["CT_RaidAssist/PlayerFrame/TooltipFooter"]);
								module.GameTooltipExtraLine:SetScale(0.90);
							end	
							if (not InCombatLockdown()) then
								-- Durability
								if (durabilityAverage) then
									local time = GetTime() - (durabilityTime or 0);
									if (durabilityBroken > 0) then
										GameTooltip:AddLine(format(L["CT_RaidAssist/PlayerFrame/TooltipItemsBroken"],durabilityBroken, durabilityAverage, floor(time/60),time - floor(time/60) * 60), 1.0, 1.0, 0.0);
									else
										GameTooltip:AddLine(format(L["CT_RaidAssist/PlayerFrame/TooltipItemsNotBroken"],durabilityAverage,  floor(time/60),time - floor(time/60) * 60), 0.9, 0.9, 0.9);
									end
								end
								
								-- Consumables
								for i=1, 40 do
									local name, icon, __, __, __, __, __, __, __, spellId = UnitAura(shownUnit, i, "HELPFUL CANCELABLE");
									if (not name or not spellId) then
										break;
									end
									local isConsumable = module.CTRA_Configuration_Consumables[spellId];
									if (isConsumable) then
										if (type(isConsumable) == "number") then
											local itemName, __, __, __, __, __, __, __, __, itemIcon = GetItemInfo(isConsumable);
											if (itemName and itemIcon) then
												GameTooltip:AddLine("|T" .. icon .. ":0|t " .. name .. " from " .. "|T" .. itemIcon .. ":0|t " .. itemName, 0.9, 0.9, 0.9);
											else
												GameTooltip:AddLine("|T" .. icon .. ":0|t " .. name, 0.9, 0.9, 0.9);
											end
										else
											GameTooltip:AddLine("|T" .. icon .. ":0|t " .. name, 0.9, 0.9, 0.9);
										end
									end
								end

								-- Guide to spells that can be cast
								local buff = canBuff();
								local remove = canRemoveDebuff();
								local rezCombat = canRezCombat();
								local rezNoCombat = canRezNoCombat();
								if (buff or remove or rezCombat or rezNoCombat) then
									GameTooltip:AddLine("|nRight click...");
									if buff then for modifier, spellName in pairs(buff) do
										GameTooltip:AddDoubleLine("|cFF33CC66nocombat" .. ((modifier ~= "nomod" and (", " .. modifier)) or ""), "|cFF33CC66"  .. spellName);
									end end
									if remove then for modifier, spellName in pairs(remove) do
										GameTooltip:AddDoubleLine("|cFFCC6666combat" .. ((modifier ~= "nomod" and (", " .. modifier)) or ""), "|cFFCC6666" .. spellName);
									end end
									if rezCombat then for modifier, spellName in pairs(rezCombat) do 
										GameTooltip:AddDoubleLine("|cFFCC6666combat, dead" .. ((modifier ~= "nomod" and (", " .. modifier)) or ""), "|cFFCC6666" .. spellName);
									end end
									if rezNoCombat then for modifier, spellName in pairs(rezNoCombat) do 
										GameTooltip:AddDoubleLine("|cFF999999nocombat, dead" .. ((modifier ~= "nomod" and (", " .. modifier)) or ""), "|cFF999999" .. spellName);
									end end
								end
								GameTooltip:Show();
								module.GameTooltipExtraLine:Show();
								GameTooltip:SetHeight(GameTooltip:GetHeight()+5);
								GameTooltip:SetWidth(max(150,GameTooltip:GetWidth()));
								if (owner.GetWindowID and module:getOption("MOVABLE-CTRAWindow" .. owner:GetWindowID())) then
									module.GameTooltipExtraLine:SetTextColor(0.50, 0.50, 0.50);
								else
									module.GameTooltipExtraLine:SetTextColor(1,1,1);
								end
							else
								GameTooltip:Show();
							end
						end
					end
				);
				secureButton:HookScript("OnLeave",
					function()
						module.GameTooltipExtraLine:Hide();
						GameTooltip:Hide();
					end
				);
			end
		end
		
		-- STEP 2:
		if (option) then
			optionsWaiting[option] = value;
		end
		if (not InCombatLockdown()) then
			for key, val in pairs(optionsWaiting) do
				if (key == "PlayerFrameScale") then
					visualFrame:SetScale((val or 100)/100);
					configureUnitNameFontString();
				elseif (
					key == "ColorUnitFullHealthCombat"
					or key == "ColorUnitZeroHealthCombat"
					or key == "ColorUnitFullHealthNoCombat"
					or key == "ColorUnitZeroHealthNoCombat"
				) then
					configureHealthBar();
				elseif (
					key == "ColorReadyCheckWaiting"
					or key == "ColorReadyCheckNotReady"
				) then
					updateStatusIndicators();
				elseif (
					key == "HealthBarAsBackground"
				) then
					configureHealthBar();
					configurePowerBar();
				elseif (key == "EnablePowerBar") then
					powerBar:SetShown(val);
				elseif (
					key == "ColorBackground"
					or key == "ColorBorder"
				) then
					configureBackdrop();
				end
			end
			optionsWaiting = { };
		end
		
		-- STEP 3:
		if (not InCombatLockdown() and (requestedUnit ~= shownUnit or requestedXOff ~= shownXOff or requestedYOff ~= shownYOff)) then
			-- set the flags
			shownUnit = requestedUnit;
			shownXOff = requestedXOff;
			shownYOff = requestedYOff;

			-- register or de-register events
			if (not listenerFrame) then
				listenerFrame = CreateFrame("Frame", nil);
				listenerFrame:SetScript("OnEvent",
					function(__, event)
						if (event == "SPELLS_CHANGED") then
							updateMacros();
						elseif (event == "UNIT_NAME_UPDATE") then
							updateUnitNameFontString();
						elseif (event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" or event == "UNIT_ABSORB_AMOUNT_CHANGED") then
							updateHealthBar();
							updateBackdrop();
						elseif (event == "UNIT_POWER_UPDATE") then
							updatePowerBar();
						elseif (event == "UNIT_DISPLAYPOWER") then
							configurePowerBar();
						elseif (event == "UNIT_AURA") then
							updateAuras();
							updateBackdrop();
						elseif (event == "PLAYER_REGEN_DISABLED") then
							updateMacros();
						elseif (event == "READY_CHECK") then
							local LD = LibStub:GetLibrary("LibDurability", true);
							if (LD) then LD:RequestDurability(); end
							updateStatusIndicators();
						elseif (
							event == "INCOMING_SUMMON_CHANGED"
							or event == "ACCEPT_SUMMON"
							or event == "CANCEL_SUMMON"
							or event == "READY_CHECK_CONFIRM"
							or event == "READY_CHECK_FINISHED"
							or event == "PLAYER_FLAGS_CHANGED"
							or event == "UNIT_CONNECTION"
						) then
							updateStatusIndicators();
						elseif (event == "RAID_TARGET_UPDATE") then
							updateRoleTexture();
						end
					end
				);
				local timeElapsed = 0;
				listenerFrame:SetScript("OnUpdate",
					function(__, elapsed)
						timeElapsed = timeElapsed + elapsed;
						if (timeElapsed < 2.5) then return; end
						timeElapsed = 0;
						updateBackdrop();
						updateStatusIndicators();
					end
				);
			end

			-- configure the visualFrame and its children
			if (shownUnit) then
				RegisterStateDriver(visualFrame, "visibility", "[@" .. shownUnit .. ", exists] show, hide");
				visualFrame:Show();
				configureBackdrop();		-- these MUST happen before the update____() funcs below
				configureHealthBar();
				configurePowerBar();
				configureRoleTexture();
				configureUnitNameFontString();
				configureAuras();
				configureStatusIndicators();
				listenerFrame:UnregisterAllEvents();  -- probably not required, but doing it to be absolute
				listenerFrame:RegisterUnitEvent("UNIT_NAME_UPDATE", shownUnit);			-- updateName();
				listenerFrame:RegisterUnitEvent("UNIT_HEALTH", shownUnit);			-- updateHealthBar(); updateBackdrop();
				listenerFrame:RegisterUnitEvent("UNIT_MAXHEALTH", shownUnit);			-- updateHealthBar(); updateBackdrop();
				listenerFrame:RegisterUnitEvent("UNIT_POWER_UPDATE", shownUnit);		-- updatePowerBar();
				listenerFrame:RegisterUnitEvent("UNIT_DISPLAYPOWER", shownUnit);		-- configurePowerBar();
				listenerFrame:RegisterUnitEvent("UNIT_AURA", shownUnit);			-- updateAuras();
				listenerFrame:RegisterEvent("READY_CHECK");					-- updateStatusIndicators();
				listenerFrame:RegisterUnitEvent("READY_CHECK_CONFIRM", shownUnit);		-- updateStatusIndicators();
				listenerFrame:RegisterEvent("READY_CHECK_FINISHED");				-- updateStatusIndicators();
				listenerFrame:RegisterUnitEvent("PLAYER_FLAGS_CHANGED", shownUnit);		-- updateStatusIndicators();
				listenerFrame:RegisterUnitEvent("UNIT_CONNECTION", shownUnit);			-- updateStatusIndicators();
				listenerFrame:RegisterEvent("CANCEL_SUMMON");					-- updateRoleTexture();
				listenerFrame:RegisterEvent("CONFIRM_SUMMON");					-- updateRoleTexture();
				listenerFrame:RegisterEvent("RAID_TARGET_UPDATE");				-- updateRoleTexture();
				if (module:getGameVersion() == CT_GAME_VERSION_RETAIL) then
					listenerFrame:RegisterUnitEvent("INCOMING_SUMMON_CHANGED", shownUnit);		-- updateStatusIndicators();
					listenerFrame:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", shownUnit);	-- updateHealthBar; updateBackdrop();
				end
				
			else
				UnregisterStateDriver(visualFrame, "visibility");
				visualFrame:Hide();
				listenerFrame:UnregisterAllEvents();
				return;		-- go absolutely no further if we arn't supposed to be showing anything any more!
			end

			-- reposition the frames
			visualFrame:SetPoint("TOPLEFT", requestedXOff, requestedYOff);

			-- configure the secureButton for the new unit
			secureButton:SetAttribute("unit", shownUnit);
			updateMacros();
		end
		-- visualFrame's children must be updated whenever group composition changes in case the players have changed position within the group or raid.
		-- if shownUnit exists then it can be assumed the previous conditional evaluated to true at some point and therefore the configure___() funcs have been used
		if (shownUnit) then
			updateBackdrop();
			updateHealthBar();
			updatePowerBar();
			updateRoleTexture();
			updateUnitNameFontString();
			updateAuras();
			updateStatusIndicators();
			updateMacros();
			clearDurability();
		end
	end
	
	-- PUBLIC CONSTRUCTOR
	do
		owner = parentInterface;	
		parent = parentFrame;
		
		local LD = LibStub:GetLibrary("LibDurability", true);
		if (LD) then
			LD:Register(obj,updateDurability)
		end
		
		return obj;			-- that's it!  nothing else is done until obj:Enable()
	end
	
end	-- end CTRAPlayerFrame

--------------------------------------------
-- CTRATargetFrame

function NewCTRATargetFrame(parentInterface, parentFrame)
	
	-- PUBLIC INTERFACE
	
	local obj = { };
	
	-- PRIVATE PROPERTIES
	
	local owner;			-- pointer to the CTRAWindow interface for calling functions like :GetProperty()
	local parent;			-- pointer to the CTRAWindow's frame object that is a parent for the visualFrame
	local visualFrame;		-- generic frame that shows various textures
	local secureButton;		-- SecureUnitActionButton that sits in front and responds to mouseclicks
	local listenerFrame;		-- generic frame that listens to various events
	local requestedUnit;		-- the unit that this object is requested to display at the next opportunity
	local requestedXOff;		-- the x coordinate to position this object's frames at the next opportunity (relative to parent's left)w
	local requestedYOff;		-- the y coordinate to position this object's frames at the next opportunity (relative to parent's top)
	local shownUnit;		-- the unit that this object is currently showing (which cannot change during combat)
	local shownXOff;		-- the x coordinate this frame is currently showing
	local shownYOff;		-- the y coordinate this frame is currently showing
	local optionsWaiting = { };	-- a list of options that need to be triggered once combat ends
	
	-- graphical textures and fontstrings of visualFrame
	local background;
	local unitNameFontStringSmall;
	
	
	-- PRIVATE FUNCTIONS

	-- creates (if necessary) and configures all the settings for background and borders, but must not be run until visualFrame exists using self:Update()
	local function configureBackdrop()
		background = background or visualFrame:CreateTexture(nil, "BACKGROUND");
		background:SetPoint("TOPLEFT", visualFrame, 3, -3);
		background:SetPoint("BOTTOMRIGHT", visualFrame, -3, 3);
		background:SetColorTexture(unpack(owner:GetProperty("ColorBackground")));
		visualFrame:SetBackdrop({["edgeFile"] = "Interface\\Tooltips\\UI-Tooltip-Border",["edgeSize"] = 16,});
		visualFrame:SetBackdropBorderColor(unpack(owner:GetProperty("ColorBorder")));
	end
	
	-- creates the font strings to dislay the unit's name, with customization to counter the ugly side effects of SetScale()
	local configureUnitNameFontString = function()

		-- limit memory usage by using the same FontObject for the whole module
		-- this intended to simulate the use of "static" keyword in other programming languages
		if (not module.GetUnitNameFontSmall) then
			module.unitNameFontSmall = { }
			module.GetUnitNameFontSmall = function(__, scale)
				if (not module.unitNameFontSmall[scale]) then
					module.unitNameFontSmall[scale] = CreateFont("CTRA_UnitNameSmallWithScale" .. scale);
					module.unitNameFontSmall[scale]:SetFont("Fonts\\FRIZQT__.TTF", 7 * scale);
				end
				return module.unitNameFontSmall[scale];
			end
		end
		
		local scale = owner:GetProperty("PlayerFrameScale") / 100;
	
		unitNameFontStringSmall = unitNameFontStringSmall or visualFrame:CreateFontString(nil, "OVERLAY");
		unitNameFontStringSmall:SetIgnoreParentScale(true);
		unitNameFontStringSmall:SetFontObject(module:GetUnitNameFontSmall(scale));
		unitNameFontStringSmall:SetPoint("LEFT", visualFrame, "LEFT", 4 * scale, 0);		-- leave room for roleTexture
		unitNameFontStringSmall:SetPoint("RIGHT", visualFrame, "RIGHT", -4 * scale, 0);	-- leave room for aura icons
		unitNameFontStringSmall:SetHeight(7 * scale);	-- prevents a shift when the name is truncated
		
		unitNameFontStringSmall:SetTextColor(1,1,1,1);	-- done here just once, because mobs don't have a class!
	end
	
	-- creates and updates the player's name
	local updateUnitNameFontString = function()
		if (shownUnit) then
			if (UnitExists(shownUnit)) then
				unitNameFontStringSmall:Show();
				unitNameFontStringSmall:SetText(UnitName(shownUnit));
			else
				unitNameFontStringSmall:Hide();
			end
		end
	end

	-- updates secureButton macros once out of combat, based on the last call of configureMacros
	local updateMacros = function()
		if (InCombatLockdown()) then return; end
		secureButton:SetAttribute("*macrotext1", "/target " .. shownUnit);
	end
	
	-- PUBLIC FUNCTIONS
	
	function obj:Enable(unit, xOff, yOff)
		if (not unit) then
			self:Disable();
			return;
		end
		requestedUnit = unit;
		requestedXOff = xOff;
		requestedYOff = yOff;
		self:Update();
	end
	
	function obj:Disable()
		requestedUnit = nil;
		requestedXOff = nil;
		requestedYOff = nil;
		self:Update();
	end
	
	function obj:IsEnabled()
		return requestedUnit ~= nil
	end
	
	function obj:IsShown()
		return shownUnit ~= nil
	end
	
	function obj:Update(option, value)
		-- STEP 1: Construct the secureButton and visualFrame if required, but only while out of combat, before proceeding to any of the following steps
		-- STEP 2: Respond to changes in the CTRA options affecting how the frames should appear and behaive, but only while out of combat
		-- STEP 3: Respond to changes directed by the parent window (requestedUnit, requestedXOff, requestedYOff) while respecting combat limitations


		-- STEP 1
		if not visualFrame or not secureButton then
			if InCombatLockdown() then
				return;
			else
				-- overall dimensions
				visualFrame = CreateFrame("Frame", nil, parent, nil);
				visualFrame:SetSize(90, 20);
				visualFrame:SetScale(owner:GetProperty("PlayerFrameScale")/100);
								
				-- overlay button that can be clicked to do stuff in combat (the secure configuration is made later in step 3)
				secureButton = CreateFrame("Button", nil, visualFrame, "SecureUnitButtonTemplate");
				secureButton:SetAllPoints();
				secureButton:RegisterForClicks("LeftButtonDown");
				secureButton:SetAttribute("*type1", "macro");
				secureButton:HookScript("OnEnter",
					function()
						if (UnitExists(shownUnit)) then
							GameTooltip:SetOwner(parent, "ANCHOR_TOPLEFT");
							GameTooltip:AddDoubleLine(UnitName(shownUnit) or "", UnitLevel(shownUnit) or "", 1,1,1, 1,1,1);
							if (not module.GameTooltipExtraLine) then
								module.GameTooltipExtraLine = GameTooltip:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
								module.GameTooltipExtraLine:SetPoint("BOTTOM", 0, 6);
								module.GameTooltipExtraLine:SetText("/ctra to move and configure");
								module.GameTooltipExtraLine:SetTextColor(0.35, 0.35, 0.35);
								module.GameTooltipExtraLine:SetScale(0.90);
							end
							GameTooltip:Show();
							if (not InCombatLockdown()) then
								module.GameTooltipExtraLine:Show();
								GameTooltip:SetHeight(GameTooltip:GetHeight()+3);
								GameTooltip:SetWidth(max(150,GameTooltip:GetWidth()));
							end
						end
					end
				);
				secureButton:HookScript("OnLeave",
					function()
						GameTooltip:Hide();
						module.GameTooltipExtraLine:Hide();
					end
				);
			end
		end
		
		-- STEP 2:
		if (option) then
			optionsWaiting[option] = value;
		end
		if (not InCombatLockdown()) then
			for key, val in pairs(optionsWaiting) do
				if (key == "PlayerFrameScale") then
					visualFrame:SetScale((val or 100)/100);
					configureUnitNameFontString();
				elseif (
					key == "ColorTargetFrameBackground"
					or key == "ColorTargetFrameBorder"
				) then
					configureBackdrop();
				end
			end
			optionsWaiting = { };
		end
		
		-- STEP 3:
		if (not InCombatLockdown() and (requestedUnit ~= shownUnit or requestedXOff ~= shownXOff or requestedYOff ~= shownYOff)) then
			-- set the flags
			shownUnit = requestedUnit;
			shownXOff = requestedXOff;
			shownYOff = requestedYOff;

			-- register or de-register events
			if (not listenerFrame) then
				listenerFrame = CreateFrame("Frame", nil);
				listenerFrame:SetScript("OnEvent",
					function(__, event)
						if (event == "UNIT_NAME_UPDATE" or event == "UNIT_TARGET") then
							updateUnitNameFontString();
						end
					end
				);
			end

			-- configure the visualFrame and its children
			if (shownUnit) then
				RegisterStateDriver(visualFrame, "visibility", "[@" .. strsub(shownUnit, 1, -7) .. ", dead] hide; [@" .. shownUnit .. ", harm, nodead] show; hide");	-- [@raid1, dead] hide; [@raid1target, harm nodead] show; hide
				visualFrame:Show();
				configureBackdrop();		-- these MUST happen before the update____() funcs below
				configureUnitNameFontString();
				listenerFrame:UnregisterAllEvents();  -- probably not required, but doing it to be absolute
				listenerFrame:RegisterUnitEvent("UNIT_NAME_UPDATE", shownUnit);			-- updateUnitNameFontString();
				listenerFrame:RegisterUnitEvent("UNIT_TARGET", strsub(shownUnit, 1, -7));	-- updateUnitNameFontString()
			else
				UnregisterStateDriver(visualFrame, "visibility");
				visualFrame:Hide();
				listenerFrame:UnregisterAllEvents();
				return;		-- go absolutely no further if we arn't supposed to be showing anything any more!
			end

			-- reposition the frames
			visualFrame:SetPoint("TOPLEFT", requestedXOff, requestedYOff);

			-- configure the secureButton for the new unit
			secureButton:SetAttribute("unit", shownUnit);
			updateMacros();
		end
		
		-- visualFrame's children must be updated whenever group composition changes in case the players have changed position within the group or raid.
		-- if shownUnit exists then it can be assumed the previous conditional evaluated to true at some point and therefore the configure___() funcs have been used
		if (shownUnit) then
			updateUnitNameFontString();
		end
	end
	
	-- PUBLIC CONSTRUCTOR
	do
		owner = parentInterface;	
		parent = parentFrame;
		return obj;			-- that's it!  nothing else is done until obj:Enable()
	end
end  -- end CTRATargetFrame