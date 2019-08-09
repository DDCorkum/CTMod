------------------------------------------------
--            CT_RaidAssist (CTRA)            --
--                                            --
-- Provides features to assist raiders incl.  --
-- customizable raid frames.  CTRA was the    --
-- original raid frame in Vanilla (pre 1.12?) --
-- but has since been re-written completely   --
-- to integrate with the more modern UI.      --
--                                            --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
--					      --
-- Original credits to Cide and TS            --
-- Maintained by Resike from 2014 to 2017     --
-- Rebuilt by Dahk Celes (ddc) in 2019        --
------------------------------------------------

--------------------------------------------
-- Performance Optimization

-- FrameXML api
local GetClassColor = GetClassColor;
local GetInspectSpecialization = GetInspectSpecialization or function() return nil; end	-- doesn't exist in classic
local GetSpecializationRoleByID = GetSpecializationRoleByID or function() return nil; end -- doesn't exist in classic
local GetReadyCheckStatus = GetReadyCheckStatus;
local InCombatLockdown = InCombatLockdown;
local UnitAura = UnitAura;
local UnitClass = UnitClass;
local UnitExists = UnitExists;
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs;
local UnitInRange = UnitInRange;
local UnitIsDeadOrGhost = UnitIsDeadOrGhost;
local UnitIsEnemy = UnitIsEnemy;
local UnitIsUnit = UnitIsUnit;
local UnitHealth = UnitHealth;
local UnitHealthMax = UnitHealthMax;
local UnitGroupRolesAssigned = UnitGroupRolesAssigned or function() return nil; end -- doesn't exist in classic
local UnitName = UnitName;
local UnitPower = UnitPower;
local UnitPowerMax = UnitPowerMax;

-- lua functions
local max = max;
local min = min;
local select = select;
local strsplit = strsplit;
local sqrt = sqrt;

--------------------------------------------
-- Initialization

local module = { };
local _G = getfenv(0);

local MODULE_NAME = "CT_RaidAssist";
local MODULE_VERSION = strmatch(GetAddOnMetadata(MODULE_NAME, "version"), "^([%d.]+)");

module.name = MODULE_NAME;
module.version = MODULE_VERSION;

_G[MODULE_NAME] = module;
CT_Library:registerModule(module);


-- THIS IS A PLACEHOLDER UNTIL LOCALIZATION CAN BE DONE FOR IMPORTANT SPELL NAMES
module.text = { }
L = module.text
L["CTRA/Spells/Revive"] = "Revive"
L["CTRA/Spells/Raise Ally"] = "Raise Ally"
L["CTRA/Spells/Soulstone"] = "Soulstone"
L["CTRA/Spells/Redemption"] = "Redemption"
L["CTRA/Spells/Resurrection"] = "Resurrection"
L["CTRA/Spells/Ancestral Spirit"] = "Ancestral Spirit"
L["CTRA/Spells/Rebirth"] = "Rebirth"
L["CTRA/Spells/Nature's Cure"] = "Nature's Cure"
L["CTRA/Spells/Remove Corruption"] = "Remove Corruption"
L["CTRA/Spells/Abolish Poison"] = "Abolish Poison"
L["CTRA/Spells/Cure Poison"] = "Cure Poison"
L["CTRA/Spells/Remove Curse"] = "Remove Curse"
L["CTRA/Spells/Revival"] = "Revival"
L["CTRA/Spells/Detox"] = "Detox"
L["CTRA/Spells/Cleanse"] = "Cleanse"
L["CTRA/Spells/Purify"] = "Purify"
L["CTRA/Spells/Cleanse Toxins"] = "Cleanse Toxins"
L["CTRA/Spells/Purify Disease"] = "Purify Disease"
L["CTRA/Spells/Dispel Magic"] = "Dispel Magic"
L["CTRA/Spells/Purify Spirit"] = "Purify Spirit"
L["CTRA/Spells/Cleanse Spirit"] = "Cleanse Spirit"
L["CTRA/Spells/Arcane Intellect"] = "Arcane Intellect"
L["CTRA/Spells/Arcane Brilliance"] = "Arcane Brilliance"
L["CTRA/Spells/Amplify Magic"] = "Amplify Magic"
L["CTRA/Spells/Dampen Magic"] = "Dampen Magic"
L["CTRA/Spells/Battle Shout"] = "Battle Shout"
L["CTRA/Spells/Power Word: Fortitude"] = "Power Word: Fortitude"
L["CTRA/Spells/Prayer of Fortitude"] = "Prayer of Fortitude"
L["CTRA/Spells/Trueshot Aura"] = "Trueshot Aura"






-- triggered by module.update("init")
module.init = function()
	module.CTRAFrames = NewCTRAFrames();
end

-- triggered by CT_Library whenever a setting changes, and upon initialization, to call functions associated with tailoring various functionality as required
module.update = function(self, option, value)
	if (option == "init") then
		module:init(option, value);
	--TODO: insert elseif with non-raid-frame functionality here
	else
		-- any functionality not handled exclusively by CTRA is related to the raid frames themselves and must be passed to the CTRAFrames object
		module.CTRAFrames:Update(option, value);
	end
end

--produces the options frames
module.frame = function()
	-- optionsFrameList is a table used by CT_Library that must be passed (by reference)
	local optionsFrameList;
	
	-- helper functions to shorten the code a bit
	local optionsInit = function() optionsFrameList = module:framesInit(); end
	local optionsGetData = function() return module:framesGetData(optionsFrameList); end
	local optionsAddFrame = function(offset, size, details, data) module:framesAddFrame(optionsFrameList, offset, size, details, data); end
	local optionsAddObject = function(offset, size, details) module:framesAddObject(optionsFrameList, offset, size, details); end
	local optionsAddScript = function(name, func) module:framesAddScript(optionsFrameList, name, func); end
	local optionsBeginFrame = function(offset, size, details, data) module:framesBeginFrame(optionsFrameList, offset, size, details, data); end
	local optionsEndFrame = function() module:framesEndFrame(optionsFrameList); end

	-- commonly used colors
	local textColor1 = "0.9:0.9:0.9";
	local textColor2 = "0.7:0.7:0.7";
	local textColor3 = "0.9:0.72:0.0";
	
	-- actual start of the options objects, ended by optionsGetData()
	optionsInit();
		-- Beta Test Warning
		optionsAddObject(  -5, 1*14, "font#tl:15:%y#s:0:%s#l:13:0#r#CTRA was recently rebuilt from scratch!#1:0.8:0:l");
		optionsAddObject(   0, 1*14, "font#tl:15:%y#s:0:%s#l:13:0#r#- Configure windows like CT_BuffMod#.8:0.4:0:l");
		optionsAddObject(   0, 1*14, "font#tl:15:%y#s:0:%s#l:13:0#r#- Right click to apply buffs or remove debuffs#0.8:0.4:0:l");
		optionsAddObject(   0, 1*14, "font#tl:15:%y#s:0:%s#l:13:0#r#- Removed legacy features because its 2019#0.8:0.4:0:l");
		optionsAddObject(   0, 1*14, "font#tl:15:%y#s:0:%s#l:13:0#r#- Simpler code using modern WoW API#0.8:0.4:0:l");
		optionsAddObject(   0, 1*14, "font#tl:15:%y#s:0:%s#l:13:0#r#- Optional use outside raids#0.8:0.4:0:l");
		optionsAddObject( -10, 2*14, "font#tl:15:%y#s:0:%s#l:13:0#r#Please provide feedback to make it better!#0.8:0.4:0:l");
				
		-- General Features
		optionsAddObject(-20, 17, "font#tl:5:%y#v:GameFontNormalLarge#General Features"); -- Custom Raid Frames
		optionsAddObject(-5, 2*14, "font#tl:15:%y#s:0:%s#l:13:0#r#These general features are separate from the custom raid frames.#" .. textColor2 .. ":l");
		optionsBeginFrame(-15, 26, "checkbutton#tl:10:%y#n:CTRA_ExtendReadyChecksCheckButton#o:CTRA_ExtendReadyChecks:1#Show extended ready checks");
			optionsAddScript("onenter", function(button)
					module:displayTooltip(button, "If you miss a /readycheck, \nprovide a button to say you returned", "ANCHOR_TOPLEFT");
				end
			);
			optionsAddScript("onleave", function()
					module:hideTooltip();
				end
			);
		optionsEndFrame();
		

		
	
		
		-- Custom Raid Frames
		module.CTRAFrames:Frame(optionsFrameList);
	
	return "frame#all", optionsGetData();
end

local function slashCommand()
	module:showModuleOptions(module.name)
end

module:setSlashCmd(slashCommand, "/ctra", "/ctraid", "/ctraidassist");

--------------------------------------------
-- General Configuration Data  (update these tables every expansion to reflect class changes)

-- Which buffs should be applied out of combat when right-clicking the player frame?  Used by CTRAPlayerFrame.  If multiple abilities have the same modifier, the first one takes precedence.
-- name: 	name of the spell to be cast 			(mandatory)
-- modifier: 	nomod, mod, mod:shift, mod:ctrl, or mod:alt	(mandatory)
-- gameVersion: if set, this line only applies to classic or retail using CT_GAME_VERSION_CLASSIC or CT_GAME_VERSION_RETAIL constants
local CTRA_Configuration_Buffs =
{
	["PRIEST"] =
	{
		{name = "Power Word: Fortitude", modifier = "nomod", },
	},
	["MAGE"] =
	{
		{name = "Arcane Intellect", modifier = "nomod", } ,
		{name = "Arcane Brilliance", modifier = "mod:shift", gameVersion = CT_GAME_VERSION_CLASSIC,},
		{name = "Amplify Magic", modifier = "mod:ctrl", gameVersion = CT_GAME_VERSION_CLASSIC,},
		{name = "Dampen Magic", modifier = "mod:alt", gameVersion = CT_GAME_VERSION_CLASSIC,},
	},
	["WARRIOR"] =
	{	
		{name = "Battle Shout", modifier = "nomod",},
	},
	["HUNTER"] =
	{
		{name = "Trueshot Aura", modifier = "nomod", gameVersion = CT_GAME_VERSION_CLASSIC,},
	},
}

-- Which spells should be cast in combat when right-clicking the player frame?  Used by CTRAPlayerFrame.  If multiple abilities have the same modifier, the first one takes precedence.
-- name: 	name of the spell to be cast 			(mandatory)
-- modifier: 	nomod, mod, mod:shift, mod:ctrl, or mod:alt	(mandatory)
-- magic: 	if set, the addon should indicate the presence of a removable magic debuff
-- curse, poison, disease: same as for magic
-- spec:	if set, this line only applies when GetInspectSpecialization("player") returns this SpecializationID
-- gameVersion: if set, this line only applies to classic or retail using CT_GAME_VERSION_CLASSIC or CT_GAME_VERSION_RETAIL constants
local CTRA_Configuration_FriendlyRemoves =												
{			
	["DRUID"] =										
	{											
		{name = "Nature's Cure", modifier = "nomod", magic = true, curse = true, poison = true, gameVersion == CT_GAME_VERSION_RETAIL},
		{name = "Remove Corruption", modifier = "nomod", curse = true, poison = true, gameVersion == CT_GAME_VERSION_RETAIL},
		{name = "Abolish Poison", modifier = "nomod", poison = true, gameVersion == CT_GAME_VERSION_CLASSIC},
		{name = "Cure Poison", modifier = "nomod", poison = true, gameVersion == CT_GAME_VERSION_CLASSIC},  	--  the first available 'nomod' on the list has precedence, so at lvl 26 this stops being used
		{name = "Remove Curse", modifier = "mod:shift", curse = true, gameVersion == CT_GAME_VERSION_CLASSIC},
	},
	["MAGE"] =
	{
		{name = "Remove Curse", modifier = "nomod", curse = true},
	},
	["MONK"] =
	{
		{name = "Detox", modifier = "nomod", spec = 270, magic = true, poison = true, disease = true},
		{name = "Detox", modifier = "nomod", poison = true, disease = true},	-- this is superceded for mistweavers by the higher one on the list with spec=270
	},
	["PALADIN"] =
	{
		{name = "Cleanse", modifier = "nomod", magic = true, poison = true, disease = true},	-- exists (in roughly equivalent forms) in both retail and classic
		{name = "Cleanse  Toxins", modifier = "nomod", poison = true, disease = true, gameVersion == CT_GAME_VERSION_RETAIL},	-- used by specs in retail who don't get the full cleanse
		{name = "Purify", modifier = "nomod", poison = true, disease = true, gameVersion == CT_GAME_VERSION_CLASSIC},	--at higher levels, replaced by cleanse
	},
	["PRIEST"] = 
	{
		{name = "Purify Disease", modifier = "nomod", disease = true, gameVersion == CT_GAME_VERSION_RETAIL},
		{name = "Purify", modifier = "nomod", magic = true, disease = true, gameVersion == CT_GAME_VERSION_RETAIL},
		{name = "Dispel Magic", modifier = "nomod", magic = true, gameVersion == CT_GAME_VERSION_CLASSIC},
	},
	["SHAMAN"] =
	{
		{name = "Purify Spirit", modifier = "nomod", magic = true, curse = true},
		{name = "Cleanse Spirit", modifier = "nomod", curse = true},
	},
}

-- Which spells should be cast on dead players when right-clicking the player frame?  Used by CTRAPlayerFrame.  If multiple abilities have the same modifier, the first one takes precedence.
-- name: 	name of the spell to be cast 			(mandatory)
-- modifier: 	nomod, mod, mod:shift, mod:ctrl, or mod:alt	(mandatory)
-- combat: 	if set, this spell may be cast during combat
-- nocombat:	if set, this spell may be cast outside combat
-- gameVersion: if set, this line only applies to classic or retail using CT_GAME_VERSION_CLASSIC or CT_GAME_VERSION_RETAIL constants
local CTRA_Configuration_RezAbilities =
{
	["DRUID"] =
	{
		{name = "Rebirth", modifier = "nomod", combat = true},
		{name = "Revive", modifier = "nomod", nocombat = true},
	},
	["DEATHKNIGHT"] =
	{
		{name = "Raise Ally", modifier = "nomod", combat = true, nocombat = true},
	},
	["WARLOCK"] =
	{
		{name = "Soulstone", modifier = "nomod", combat = true, gameVersion = CT_GAME_VERSION_RETAIL},	--TO DO: Make a classic version that uses the soulstone sitting in the bags
	},
	["PALADIN"] =
	{
		{name = "Redemption", modifier = "nomod", nocombat = true},
	},	
	["PRIEST"] =
	{
		{name = "Resurrection", modifier = "nomod", nocombat = true},
	},	
	["SHAMAN"] =
	{
		{name = "Ancestral Spirit", modifier = "nomod", nocombat = true},
	},
}


--------------------------------------------
-- Extended Ready Checks

local AfterNotReadyFrame = CreateFrame("Frame", nil, UIParent);
AfterNotReadyFrame:Hide();
AfterNotReadyFrame:SetSize(323,97);
AfterNotReadyFrame:SetPoint("CENTER", 0, -10);
AfterNotReadyFrame:RegisterEvent("PLAYER_REGEN_DISABLED");
AfterNotReadyFrame:RegisterEvent("GROUP_LEFT");
AfterNotReadyFrame:RegisterEvent("READY_CHECK");
AfterNotReadyFrame:RegisterUnitEvent("READY_CHECK_CONFIRM", "player");
AfterNotReadyFrame:RegisterEvent("READY_CHECK_FINISHED");
AfterNotReadyFrame:SetScript("OnEvent",
	function(self, event, arg1)
		if (event == "PLAYER_REGEN_DISABLED") then
			self:Hide();
		elseif (event == "GROUP_LEFT") then
			self:Hide();
		elseif (event == "READY_CHECK") then
			self:Hide();
			SetPortraitTexture(AfterNotReadyFrame.portrait, arg1)
			self.status = GetReadyCheckStatus("player");
			self.initiator = arg1;
		elseif (event == "READY_CHECK_CONFIRM") then
			self.status = GetReadyCheckStatus("player");
		elseif (event == "READY_CHECK_FINISHED") then
			if (module:getOption("CTRA_ExtendReadyChecks") ~= false) then
				if (self.status == "waiting") then
					self:Show();
					self.text:SetText("You were afk, are you back now?")
				elseif (self.status == "not ready") then
					self:Show();
					self.text:SetText("Are you ready now?")
				elseif (not self.status) then
					self:Show();
					SetPortraitTexture(AfterNotReadyFrame.portrait, "player")
					self.text:SetText("You might have missed a ready check!")
					self.initiator = nil;
				end
			else
				self.initiator = nil;
			end
		end
	end
);

AfterNotReadyFrame.portrait = AfterNotReadyFrame:CreateTexture(nil, "BACKGROUND");
AfterNotReadyFrame.portrait:SetSize(50,50);
AfterNotReadyFrame.portrait:SetPoint("TOPLEFT", 7, -6);

AfterNotReadyFrame.texture = AfterNotReadyFrame:CreateTexture(nil, "ARTWORK");
AfterNotReadyFrame.texture:SetSize(323, 97);
AfterNotReadyFrame.texture:SetTexture("Interface\\RaidFrame\\UI-ReadyCheckFrame");
AfterNotReadyFrame.texture:SetTexCoord(0, 0.630859375, 0, 0.7578125);
AfterNotReadyFrame.texture:SetPoint("TOPLEFT");

AfterNotReadyFrame.text = AfterNotReadyFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal");
AfterNotReadyFrame.text:SetSize(240, 0);
AfterNotReadyFrame.text:SetJustifyV("MIDDLE");
AfterNotReadyFrame.text:SetPoint("CENTER", AfterNotReadyFrame, "TOP", 20, -35);

AfterNotReadyFrame.returnedButton = CreateFrame("Button", nil, AfterNotReadyFrame, "UIPanelButtonTemplate");
AfterNotReadyFrame.returnedButton:SetText("Ready");
AfterNotReadyFrame.returnedButton:SetSize(119, 24);
AfterNotReadyFrame.returnedButton:SetPoint("TOPRIGHT", AfterNotReadyFrame, "TOP", 13, -55);
AfterNotReadyFrame.returnedButton:SetScript("OnClick",
	function()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
		AfterNotReadyFrame:Hide();
		if (AfterNotReadyFrame.initiator and UnitExists(AfterNotReadyFrame.initiator) and UnitInRange(AfterNotReadyFrame.initiator)) then
			DoEmote("ready", AfterNotReadyFrame.initiator);
		else
			SendChatMessage("Ready", "RAID");
		end
		AfterNotReadyFrame.initiator = nil;
	end
);

AfterNotReadyFrame.goingafkButton = CreateFrame("Button", nil, AfterNotReadyFrame, "UIPanelButtonTemplate");
AfterNotReadyFrame.goingafkButton:SetText("Cancel");
AfterNotReadyFrame.goingafkButton:SetSize(119, 24);
AfterNotReadyFrame.goingafkButton:SetPoint("TOPLEFT", AfterNotReadyFrame, "TOP", 17, -55);
AfterNotReadyFrame.goingafkButton:SetScript("OnClick",
	function()
		AfterNotReadyFrame:Hide();
		if (AfterNotReadyFrame.neverShow:GetChecked()) then
			module:setOption("CTRA_ExtendReadyChecks", false, true);
		end
	end
);

AfterNotReadyFrame.neverShow = CreateFrame("Checkbutton", nil, AfterNotReadyFrame);
AfterNotReadyFrame.neverShow:SetText("Never show this");
AfterNotReadyFrame.neverShow:SetAlpha(0.5);
AfterNotReadyFrame.neverShow:SetScale(0.5);
AfterNotReadyFrame.neverShow:SetPoint("TOP", AfterNotReadyFrame.goingafkButton, "BOTTOM", 0, -3);

--------------------------------------------
-- CTRAFrames

function NewCTRAFrames()
	-- private  and where applicable their default values
	local windows = { };			-- non-interactive frames that anchor and orient assigned collections of PlayerFrames, TargetFrames and LabelFrames
	local selectedWindow = nil;		-- the currently selected window
	local listener = nil;			-- listener for joining and leaving a raid
	local enabledState;			-- are the raidframes enabled (but possibly hidden if not in a raid)
	local settingsOverlayToStopClicks;	-- button that sits overtop several options to stop interactions with them
	local dummyFrame;			-- pretend CTRAPlayerFrame to illustrate options
	
	-- private methods
	local enable = function(self)
		-- STEP 1: if not already enabled, do steps 2-3
		-- STEP 2: create (if necessary) and enable CTRAWindow objects
		-- STEP 3: set a flag to respond positively to IsEnabled() queries
		-- STEP 4: focus the options menu if it is created already (otherwise, this step will occur when it is created)
		
		--STEP 1:
		if (not self:IsEnabled()) then
			
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
		end
	end
	
	local disable = function(self)
		-- STEP 1: if not already disabled, do steps 2-3
		-- STEP 2: disable all current CTRAWindow objects
		-- STEP 3: set a flag to respond negatively to IsEnabled() queries
		
		--STEP 1:
		if (self:IsEnabled()) then
			--STEP 2:
			for i, window in ipairs(windows) do
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
		end
	end
	
	local isEnabled = function(self)
		return enabledState;
	end

	local toggleEnableState = function(self, value)
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
		
	local update = function(self, option, value)
		if (option == "CTRAFrames_EnableFrames") then
			self:ToggleEnableState(value);
		end
		for i, window in ipairs(windows) do
			if (strfind(option, "CTRAWindow" .. i .. "_") == 1) then
				window:Update(strsub(option,strfind(option, "_")+1), value);
			end
		end
		if (dummyFrame and strfind(option, "CTRAWindow" .. (selectedWindow or 1) .. "_") == 1) then
			dummyFrame:Update(strsub(option,strfind(option, "_")+1), value);
		end
	end
	

	
	local optionsFrameSkeleton = function(self, optionsFrameList)
		-- helper functions to shorten the code a bit
		local optionsAddFrame = function(offset, size, details, data) module:framesAddFrame(optionsFrameList, offset, size, details, data); end
		local optionsAddObject = function(offset, size, details) module:framesAddObject(optionsFrameList, offset, size, details); end
		local optionsAddScript = function(name, func) module:framesAddScript(optionsFrameList, name, func); end
		local optionsBeginFrame = function(offset, size, details, data) module:framesBeginFrame(optionsFrameList, offset, size, details, data); end
		local optionsEndFrame = function() module:framesEndFrame(optionsFrameList); end
		
		-- commonly used colors
		local textColor1 = "0.9:0.9:0.9";
		local textColor2 = "0.7:0.7:0.7";
		local textColor3 = "0.9:0.72:0.0";
		
		
		-- Heading
		optionsAddObject(-30, 17, "font#tl:5:%y#v:GameFontNormalLarge#Custom Raid Frames"); -- Custom Raid Frames
		
		-- General Options
		optionsAddObject(-15, 26, "font#tl:15:%y#Enable CTRA Frames?#" .. textColor1 .. ":l"); -- Enable custom raid frames
		optionsAddFrame( 26, 20, "dropdown#tl:130:%y#s:120:%s#n:CTRAFrames_EnableFramesDropDown#o:CTRAFrames_EnableFrames:4#Always#During Raids#During Groups#Never"); 
		
		
		-- Everything below this line will pseudo-disable when the frames are disabled
		optionsBeginFrame(-5, 0, "frame#tl:0:%y#br:tr:0:%b#n:");
			optionsAddScript("onload",
				function(frame)
					settingsOverlayToStopClicks = CreateFrame("Button", nil, frame);
					settingsOverlayToStopClicks:SetAllPoints();
					settingsOverlayToStopClicks:RegisterForClicks("AnyDown", "AnyUp");
					local tex = settingsOverlayToStopClicks:CreateTexture(nil, "OVERLAY");
					tex:SetAllPoints();
					tex:SetColorTexture(0,0,0,0.25);
					settingsOverlayToStopClicks:SetFrameLevel(25);
					settingsOverlayToStopClicks:SetScript("OnEnter",
						function()
							module:displayTooltip(settingsOverlayToStopClicks, "Raid frames are currently disabled!\nYou must enable them using the dropdown above.", "ANCHOR_CURSOR");
						end
					);
					settingsOverlayToStopClicks:SetScript("OnLeave",
						function()
							module:hideTooltip()
						end
					);
				end
			);
		
			-- Window Selection
			optionsBeginFrame(0, 0, "frame#tl:0:%y#br:tr:0:%b");

				-- Heading
				optionsAddObject(-15,  17, "font#tl:5:%y#v:GameFontNormal#n:CTRAFrames_SelectedWindowHeading#Windows");
				optionsAddObject(-5, 1*14, "font#tl:15:%y#s:0:%s#l:13:0#r#Each window has its own appearance.#" .. textColor2 .. ":l");
				
				-- select which window to configure
				optionsAddObject(-10, 14, "font#tl:15:%y#v:ChatFontNormal#Select window:");
				optionsBeginFrame(19, 24, "button#tl:105:%y#s:24:%s#n:CTRAFrames_PreviousWindowButton");
					optionsAddScript("onclick",
						function(button)
							if (selectedWindow > 1) then
								selectedWindow = selectedWindow - 1;
								windows[selectedWindow]:Focus();
								L_UIDropDownMenu_SetText(CTRAFrames_WindowSelectionDropDown, "Window " .. selectedWindow);
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
								L_UIDropDownMenu_SetText(CTRAFrames_WindowSelectionDropDown, "Window " .. selectedWindow);
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
							L_UIDropDownMenu_SetText(dropdown, "Window 1");
							L_UIDropDownMenu_Initialize(dropdown,
								function(frame, level, menuList)
									for i=1, (module:getOption("CTRAFrames_NumEnabledWindows") or 1) do
										local dropdownEntry = { }
										dropdownEntry.text = "Window " .. i;
										dropdownEntry.value = i;
										dropdownEntry.func = function()
											selectedWindow = i;
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
											L_UIDropDownMenu_SetText(frame, "Window " .. i);
										end
										L_UIDropDownMenu_AddButton(dropdownEntry, level);
									end
								end
							)
						end
					);
				optionsEndFrame();

				-- create a new window
				optionsBeginFrame(-5, 30, "button#tl:15:%y#s:80:%s#v:UIPanelButtonTemplate#Add");
					optionsAddScript("onclick", 
						function(button)
							selectedWindow = (module:getOption("CTRAFrames_NumEnabledWindows") or 1) + 1;
							module:setOption("CTRAFrames_NumEnabledWindows", selectedWindow, true);
							if (not windows[selectedWindow]) then
								windows[selectedWindow] = NewCTRAWindow(self)
							end
							windows[selectedWindow]:Enable(selectedWindow);
							windows[selectedWindow]:Focus();
							L_UIDropDownMenu_SetText(CTRAFrames_WindowSelectionDropDown, "Window " .. selectedWindow);
							CTRAFrames_DeleteWindowButton:Enable(); -- the delete button may have been previously disabled if there was only one window available
							CTRAFrames_PreviousWindowButton:Enable();
							CTRAFrames_NextWindowButton:Disable();
						end
					);
					optionsAddScript("onenter",
						function(button)
							module:displayTooltip(button, {"Add a new window with default settings#1:0.82:1"}, "ANCHOR_TOPLEFT")
						end
					);
					optionsAddScript("onleave",
						function(button)
							module:hideTooltip();
						end
					);
				optionsEndFrame();
				
				-- clone an existing window
				optionsBeginFrame( 30, 30, "button#tl:110:%y#s:80:%s#v:UIPanelButtonTemplate#Clone");
					optionsAddScript("onclick", 
						function(button)
							windowToClone = selectedWindow;
							selectedWindow = (module:getOption("CTRAFrames_NumEnabledWindows") or 1) + 1;
							module:setOption("CTRAFrames_NumEnabledWindows", selectedWindow, true);
							if (not windows[selectedWindow]) then
								windows[selectedWindow] = NewCTRAWindow(self);
							end
							windows[selectedWindow]:Enable(selectedWindow, windowToClone);
							windows[selectedWindow]:Focus();
							L_UIDropDownMenu_SetText(CTRAFrames_WindowSelectionDropDown, "Window " .. selectedWindow);
							CTRAFrames_DeleteWindowButton:Enable(); -- the delete button may have been previously disabled if there was only one window available
							CTRAFrames_PreviousWindowButton:Enable();
							CTRAFrames_NextWindowButton:Disable();
						end
					);
					optionsAddScript("onenter",
						function(button)
							module:displayTooltip(button, {"Add a new window with settings that duplicate those of the currently selected window.#1:0.82:1#w"}, "ANCHOR_TOPLEFT")
						end
					);
					optionsAddScript("onleave",
						function(button)
							module:hideTooltip();
						end
					);
				optionsEndFrame();
				
				-- delete a window
				optionsBeginFrame( 30, 30, "button#tl:205:%y#s:80:%s#v:UIPanelButtonTemplate#Delete#n:CTRAFrames_DeleteWindowButton");
					optionsAddScript("onclick", 
						function(button)
							-- make sure the user really means it, and that this isn't the very last window
							if ((module:getOption("CTRAFrames_NumEnabledWindows") or 1) == 1 or not IsShiftKeyDown()) then
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
							L_UIDropDownMenu_SetText(CTRAFrames_WindowSelectionDropDown, "Window " .. selectedWindow);
							if (module:getOption("CTRAFrames_NumEnabledWindows") == 1) then
								self:Disable();
								CTRAFrames_PreviousWindowButton:Disable();
								CTRAFrames_NextWindowButton:Disable();
							elseif (selectedWindow == module:getOption("CTRAFrames_NumEnabledWindows")) then
								CTRAFrames_NextWindowButton:Disable();
							elseif (selectedWindow == 1) then
								CTRAFrames_PreviousWindowButton:Disable();
							end
						end
					);
					optionsAddScript("onenter",
						function(button)
							module:displayTooltip(button, {"Shift-click the 'Delete' button to delete the selected window.#1:0.82:1#w"}, "ANCHOR_TOPLEFT")
						end
					);
					optionsAddScript("onleave",
						function(button)
							module:hideTooltip();
						end
					);
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
			optionsBeginFrame(0, 0, "frame#tl:0:%y#br:tr:0:%b#");
					
				-- Groups, Roles, Classes
				optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormal#Group and Class Selections");
				optionsAddObject(-5, 2*14, "font#tl:15:%y#s:0:%s#l:13:0#r#Which groups, roles or classes should this window show?#" .. textColor2 .. ":l");
				optionsAddObject(-10,  20, "font#tl:15:%y#s:0:%s#Groups#" .. textColor1 .. ":l");
				for i=1, 8 do
					optionsBeginFrame( -5,  20, "checkbutton#tl:15:%y#n:CTRAWindow_ShowGroup" .. i .. "CheckButton#Gp " .. i);
						optionsAddScript("onload",
							function(button)
								button.option = function() return "CTRAWindow" .. selectedWindow .. "_ShowGroup" .. i; end
								button:SetFrameLevel(20);
							end
							
						);
					optionsEndFrame();
				end
				optionsAddObject(220, 20, "font#tl:110:%y#s:0:%s#Roles#" .. textColor1 .. ":l");
				for key, val in ipairs({"Myself", "Tanks", "Heals", "Melee", "Range"}) do
					optionsBeginFrame( -5,  25, "checkbutton#tl:110:%y#n:CTRAWindow_Show" .. val .. "CheckButton#" .. val);
						optionsAddScript("onload",
							function(button)
								button.option = function() return "CTRAWindow" .. selectedWindow .. "_Show" .. val; end
								button:SetFrameLevel(21);
							end
						);
					optionsEndFrame();
				end
				optionsAddObject(170, 20, "font#tl:205:%y#s:0:%s#Classes#" .. textColor1 .. ":l");
				for i, class in ipairs(
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
				) do
					optionsBeginFrame(-5, 15, "checkbutton#tl:205:%y#n:CTRAWindow_Show" .. class[1] .. "CheckButton#" .. class[2]);
						optionsAddScript("onload",
							function(button)
								button.option = function() return "CTRAWindow" .. selectedWindow .. "_Show" .. class[1]; end
								button:SetFrameLevel(22);
							end
						);
					optionsEndFrame();
				end								
				
				-- Orientation and Wrapping
				optionsAddObject(-5,   17, "font#tl:5:%y#v:GameFontNormal#Layout");
				optionsAddObject(-5, 2*14, "font#tl:15:%y#s:0:%s#l:13:0#r#Layout each group in its own column/row, or merge them into a single grid?#" .. textColor2 .. ":l");
				optionsAddObject(-15, 26, "font#tl:15:%y#Rows/Cols Per Group:#" .. textColor1 .. ":l");
				optionsBeginFrame(26,   20, "dropdown#tl:140:%y#s:100:%s#n:CTRAWindow_OrientationDropDown#New Column#New Row#Merge Down#Merge Across");
					optionsAddScript("onload",
						function(dropdown)
							dropdown.option = function() return "CTRAWindow" .. selectedWindow .. "_Orientation"; end
						end
					);
				optionsEndFrame();
				optionsAddObject(-20, 26, "font#tl:15:%y#Large Groups:#" .. textColor1 .. ":l");
				optionsBeginFrame(26, 17, "slider#tl:160:%y#s:110:%s#n:CTRAWindow_WrapSlider#Wrap after <value>:5:40#5:40:5");
					optionsAddScript("onload",
						function(slider)
							slider.option = function()
								if (slider.suspend) then
									return nil;
								else
									return "CTRAWindow" .. selectedWindow .. "_WrapAfter";
								end
							end
						end
					);
				optionsEndFrame();

				-- Size and Spacing
				optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormal#Size and Spacing");
				optionsAddObject(-5, 2*14, "font#tl:15:%y#s:0:%s#l:13:0#r#Should frames touch each other, or be spaced apart vertically and horizontally?#" .. textColor2 .. ":l");
				optionsBeginFrame(-20, 17, "slider#tl:15:%y#s:110:%s#n:CTRAWindow_HorizontalSpacingSlider#HSpacing = <value>:Touching:Far#0:100:1");
					optionsAddScript("onload",
						function(slider)
							slider.option = function()
								if (slider.suspend) then
									return nil;
								else
									return "CTRAWindow" .. selectedWindow .. "_HorizontalSpacing";
								end
							end
						end
					);
				optionsEndFrame();
				optionsBeginFrame( 20, 17, "slider#tl:150:%y#s:110:%s#n:CTRAWindow_VerticalSpacingSlider#VSpacing = <value>:Touching:Far#0:100:1");
					optionsAddScript("onload",
						function(slider)
							slider.option = function()
								if (slider.suspend) then
									return nil;
								else
									return "CTRAWindow" .. selectedWindow .. "_VerticalSpacing";
								end
							end
						end
					);
				optionsEndFrame();
				optionsAddObject(-25, 1*14, "font#tl:15:%y#s:0:%s#l:13:0#r#How big should the frames themselves be?#" .. textColor2 .. ":l");
				optionsBeginFrame(-20, 17, "slider#tl:50:%y#s:200:%s#n:CTRAWindow_PlayerFrameScaleSlider#Scale = <value>%#50:200:10");
					optionsAddScript("onload",
						function(slider)
							slider.option = function()
								if (slider.suspend) then
									return nil;
								else
									return "CTRAWindow" .. selectedWindow .. "_PlayerFrameScale";
								end
							end
						end
					);
				optionsEndFrame();
				
				
				-- Appearance of Player Frames
				optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormal#Appearance of Player Frames");
				optionsAddObject(-5, 2*14, "font#tl:15:%y#s:0:%s#l:13:0#r#Do you want the retro CTRA feel, or more a modern look?#" .. textColor2 .. ":l");
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
								"HealthBarAsBackground",
								"EnablePowerBar",
							}
							for i, property in ipairs(presetClassic) do
								module:setOption("CTRAWindow" .. selectedWindow .. "_" .. property, nil, true);		--the default is to look like classic, so just nil them out
								self:Update("CTRAWindow" .. selectedWindow .. "_" .. property, windows[selectedWindow]:GetProperty(property));	-- forces the window's update function to actually trigger with the default
							end
							windows[selectedWindow]:Focus();
						end
					);
					optionsAddScript("onenter",
							function(checkbox)
								module:displayTooltip(checkbox, "Keep the retro look from CTRA in Vanilla", "ANCHOR_TOPLEFT");
							end
						);
					optionsAddScript("onleave",
							function(checkbox)
								module:hideTooltip();
							end
						);
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
					optionsAddScript("onenter",
							function(checkbox)
								module:displayTooltip(checkbox, "In-between the classic and modern looks", "ANCHOR_TOPLEFT");
							end
						);
					optionsAddScript("onleave",
							function(checkbox)
								module:hideTooltip();
							end
						);
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
					optionsAddScript("onenter",
							function(checkbox)
								module:displayTooltip(checkbox, "Adopt a modern feel like many other addons", "ANCHOR_TOPLEFT");
							end
						);
					optionsAddScript("onleave",
							function(checkbox)
								module:hideTooltip();
							end
						);
				optionsEndFrame();
				optionsBeginFrame(-10, 26, "checkbutton#tl:10:%y#n:CTRAWindow_HealthBarAsBackgroundCheckButton:false#Show health as full-size background");
					optionsAddScript("onload",
						function(checkbox)
							checkbox.option = function()
								return "CTRAWindow" .. selectedWindow .. "_HealthBarAsBackground";
							end
						end
					);
					optionsAddScript("onenter",
							function(checkbox)
								module:displayTooltip(checkbox, "Fill the entire background instead of a small bar", "ANCHOR_TOPLEFT");
							end
						);
					optionsAddScript("onleave",
							function(checkbox)
								module:hideTooltip();
							end
						);
				optionsEndFrame();
				optionsBeginFrame(0, 26, "checkbutton#tl:10:%y#n:CTRAWindow_EnablePowerBarCheckButton:true#Show power bar?");
					optionsAddScript("onload",
						function(checkbox)
							checkbox.option = function()
								return "CTRAWindow" .. selectedWindow .. "_EnablePowerBar";
							end
						end
					);
					optionsAddScript("onenter",
							function(checkbox)
								module:displayTooltip(checkbox, "Show the mana, energy, rage, etc. at the bottom", "ANCHOR_TOPLEFT");
							end
						);
					optionsAddScript("onleave",
							function(checkbox)
								module:hideTooltip();
							end
						);
				optionsEndFrame();
				optionsBeginFrame(-10, 60, "frame#tl:0:%y#br:tr:0:%b#");
					optionsAddObject(  -5, 4*14, "font#tl:120:%y#s:0:%s#l:13:0#r#Work in progress!  \nControls will be added here to set colors");
					optionsAddScript("onload",
						function(frame)
							dummyFrame = NewCTRAPlayerFrame(
								{
									GetProperty = function(obj, property)
										if (property and selectedWindow) then
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
							dummyFrame:Enable("player", 10, 10);
						end
					);
				optionsEndFrame();
				
			
			optionsEndFrame();  -- end of the window
			
			-- this is called only once the entire frame has been created
			optionsAddScript("onshow",
				function(frame)
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
				function(frame)
					for i=1, #(windows) do
						windows[i]:HideAnchor();
					end
				end
			);
		optionsEndFrame();  -- end of everything below the "enable CTRA frames" checkbox
		return;  -- nothing is returned because this is entirely encapsulated within the existing optionsFrameList event begun by CTRA:frame()
	end

	-- public interface
	local Self = 
	{
		Enable = enable,
		Disable = disable,
		IsEnabled = isEnabled,
		ToggleEnableState = toggleEnableState,
		Update = update,
		Frame = optionsFrameSkeleton,
		
	}	
	
	-- public constructor
	listener = CreateFrame("Frame", nil);
	listener:RegisterEvent("PLAYER_ENTERING_WORLD");		-- defers creating the frames until the player is in the game
	listener:RegisterEvent("GROUP_ROSTER_UPDATE");			-- the frames might enable only during raids, groups, or always!
	listener:HookScript("OnEvent", function() Self:ToggleEnableState(); end);
	return Self;

end


--------------------------------------------
-- CTRAWindow

function NewCTRAWindow(owningCTRAFrames)
	-- private properties
	local owner = owningCTRAFrames;	-- pointer to the interface of CTRAFrames object that owns this window
	local windowID;			-- nil if disabled, or the number corresponding to which window this is
	local anchorFrame;		-- small movable anchor to orient the window
	local windowFrame;		-- appearance of the window itself
	local playerFrames = { };	-- CTRAPlayerFrame objects
	local labelFrames = { };	-- CTRALabelFrame objects (not yet implemented)
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
		["ColorBorder"] = {1.00, 1.00, 1.00, 0.75},
		["ColorBorderTargetTarget"] = {1.00, 0.10, 0.10, 0.75},
		["ColorBorderBeyondRange"] = {0.10, 0.10, 0.10, 0.75},
		["ColorReadyCheckWaiting"] = {0.45, 0.45, 0.45, 1.00},
		["ColorReadyCheckNotReady"] = {0.80, 0.45, 0.45, 1.00},
		["HealthBarAsBackground"] = false,
		["EnablePowerBar"] = true,
		["PlayerFrameShowGenericDebuffs"] = 1,			--auto, show only debuff types the player can remove
		["PlayerFrameShowEncounterDebuffs"] = 1,		--auto, show only debuff types the player is concerned with based on role
	};

	-- private methods
	local enable = function(self, asWindow, copyFromWindow)
		assert(type(asWindow) == "number" and asWindow > 0, "CTRA Window being enabled without a valid number");
		
		-- STEP 1: If copyFromWindow then this window should clone the settings from something else before proceeding further
		-- STEP 2: If this window has never been enabled, then create its component windowFrame and anchorFrame
		-- STEP 3: If this window was not previously enabled, then register for all events
		-- STEP 4: Position the anchor via module:RegisterMovable
		-- STEP 5: Set flags to track the frame's enabled identity
		-- STEP 6: Initialize and/or update the child frames
		-- STEP 7: If the CT options are currently open, show the movable anchor

		
		
		-- STEP 1:
		if (copyFromWindow and type(copyFromWindow) == "number") then
			for key, val in pairs(defaultOptions) do
				module:setOption("CTRAWindow" .. asWindow .. "_" .. key,module:getOption("CTRAWindow" .. copyFromWindow .. "_" .. key),true, false);
			end
		end
		
		-- STEP 2:
		if (not anchorFrame or not windowFrame) then
			-- anchor to handle positioning, with assistance from CT_Library
			anchorFrame = CreateFrame("Frame", nil, UIParent);
			anchorFrame:SetSize(10,10);
			anchorFrame:SetPoint("CENTER");
			anchorFrame.texture = anchorFrame:CreateTexture(nil,"BACKGROUND");
			anchorFrame.texture:SetAllPoints(true);
			anchorFrame.texture:SetColorTexture(1,1,0,0.5);
			anchorFrame:Hide();
			anchorFrame:SetScript("OnMouseDown",
				function(frame, button)
					if (windowID) then
						module:moveMovable("CTRAWindow" .. windowID)
					end
				end
			);
			anchorFrame:SetScript("OnMouseUp",
				function(frame, button)
					if (windowID) then
						module:stopMovable("CTRAWindow" .. windowID)
					end
				end
			);
			anchorFrame:SetScript("OnEnter",
				function(frame)
					module:displayTooltip(frame, {"Left-click to drag this window"}, "ANCHOR_TOPRIGHT");
				end
			);
			anchorFrame:SetScript("OnLeave",
				function(frame)
					module:hideTooltip();
				end
			);
			-- indicator which window this is
			anchorFrame.text = anchorFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
			anchorFrame.text:SetPoint("LEFT", anchorFrame, "RIGHT", 10, 0);
			anchorFrame.text:SetTextColor(1,1,1,1);
			
			-- window that player frames reside in, with 2 pixel padding on all sides
			windowFrame = CreateFrame("Frame", nil, UIParent);
			windowFrame:SetSize(4,4);
			windowFrame:SetPoint("TOPLEFT", anchorFrame, "BOTTOM", -5, -10);
			windowFrame:Show();
			windowFrame:SetScript("OnEvent",
				function(frame, event, ...)
					if (event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_REGEN_ENABLED") then
						self:Update();
					end
				end
			);
			
			-- background texture on the windowFrame (nearly transparent)
			windowFrame.background = windowFrame:CreateTexture(nil, "BACKGROUND");
			windowFrame.background:SetAllPoints();
			windowFrame.background:SetColorTexture(0,0,0,0.1);
		end
		
		-- STEP 3:
		if (not self:IsEnabled()) then
			windowFrame:RegisterEvent("GROUP_ROSTER_UPDATE");
			windowFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
			windowFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
		end
		
		-- STEP 4:
		module:registerMovable("CTRAWindow" .. asWindow, anchorFrame);
		
		-- STEP 5:
		windowID = asWindow;
		
		-- STEP 6:
		self:Update();
		
		-- STEP 7:
		if (CTRAFrames_SettingsFrame and CTRAFrames_SettingsFrame:IsShown()) then
			self:ShowAnchor();
		else
			self:HideAnchor();
		end
		
		-- DEBUGGING
		for key, val in pairs(currentOptions) do
			currentOptions[key] = nil;
		end

		
	end
	
	local disable = function(self, deletePermanently)
		-- STEP 1: If deletePermanently then the settings for this window must be eliminated
		-- STEP 2: Deregister from all events
		-- STEP 3: Disable all child frames
		-- STEP 4: Clear out the anchor via module:UnregisterMovable
		-- STEP 5: Set flags to track the frame's disabled state
		-- STEP 6: Hide the anchor (which might already be hidden)
		
		-- STEP 1:
		if (deletePermanently and windowID) then
			for key, val in pairs(defaultOptions) do
				module:setOption("CTRAWindow" .. windowID .. "_" .. key,nil,true,false);
			end
			module:resetMovable("CTRAWindow" .. windowID);
		end
		
		-- STEP 2:
		windowFrame:UnregisterEvent("GROUP_ROSTER_UPDATE");
		windowFrame:UnregisterEvent("PLAYER_ENTERING_WORLD");
		windowFrame:UnregisterEvent("PLAYER_REGEN_ENABLED");
		
		-- STEP 3:
		for i, playerframe in pairs(playerFrames) do
			playerframe:Disable();
		end
		
		-- STEP 4:
		module:UnregisterMovable("CTRAWindow" .. windowID);
		anchorFrame:Hide();
		
		
		-- STEP 5:
		windowID = nil;
		
		-- STEP 6:
		self:HideAnchor();
		
	end
	
	local isEnabled = function(self)
		return windowID ~= nil;
	end
	
	-- returns the value associated with this window, or returns
	local getProperty = function(self, option)
		if (currentOptions[option]) then
			return currentOptions[option];
		end
		if (not windowID) then
			return nil;
		end
		local savedValue = module:getOption("CTRAWindow" .. windowID .. "_" .. option);
		if (savedValue ~= nil) then
			currentOptions[option] = savedValue;
			return savedValue;
		end
		currentOptions[option] = defaultOptions[option];
		return defaultOptions[option];
	end
	
	
	local update = function(self, option, value)
		-- STEP 1: Outside combat, obtain a roster of self, party members and raid members to use during step 2
		-- STEP 2: Determine which players to show in this window, and construct/configure CTRAPlayerFrames accordingly
		-- STEP 3: Direct every CTRAPlayerFrame to update, passing along any settings changes and new assignments (the frames themselves will defer most changes until out of combat)
			
		-- STEP 2:
		local roster = { };
		if (IsInRaid() or UnitExists("raid2")) then
			for i=1, min(MAX_RAID_MEMBERS, GetNumGroupMembers()) do
				local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, loot, combatRole = GetRaidRosterInfo(i);
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

		-- STEP 3:
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
		local x = 2;   -- essentially x=0, but with a small offset
		local y = -2;  -- essentially y=0, but with a small offset
		local w = 0;
		local rows = 0;
		local cols = 0;
		local playersShown = 0;
		for i, category in pairs(categories) do  -- (from step 2)
			if self:GetProperty(category[1]) then

				-- this group must be shown, if there is anyone in it to show
				for j, rosterEntry in ipairs(roster) do
					if category[2](rosterEntry) then

						-- show this person
						playersShown = playersShown + 1;
						if (not playerFrames[playersShown]) then
							playerFrames[playersShown] = NewCTRAPlayerFrame(self, windowFrame);
						end
						playerFrames[playersShown]:Enable(rosterEntry.unit, x, y, rosterEntry.role);

						-- move the anchor (and wrap to a new col/row if necessary) for the next person, and keep track of the max number of rows and columns in use
						w = w + 1;
						if (w == self:GetProperty("Wrap")) then
							if (self:GetProperty("Orientation") == 1 or self:GetProperty("Orientation") == 3) then
								x = x + self:GetProperty("PlayerFrameWidth") + self:GetProperty("HorizontalSpacing");
								y = -2;  -- essentially y=0, but with a small offset
								if (w > rows) then
									rows = w;
								end
								if (w == 1) then
									-- first entry in a new column!
									cols = cols + 1;
								end
							else
								x = 2;  -- essentially x=0, but with a small offset
								y = y - 40 - self:GetProperty("VerticalSpacing");
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
								y = y - 40 - self:GetProperty("VerticalSpacing");

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
				if (w > 0 and self:GetProperty("Orientation") == 1 or self:GetProperty("Orientation") == 2) then
					w = 0;
					if (self:GetProperty("Orientation") == 1) then
						x = x + 90 + self:GetProperty("HorizontalSpacing");
						y = -2; -- essentially y=0, but with a small offset
					else
						x = 2;  -- essentially x=0, but with a small offset
						y = y - 40 - self:GetProperty("VerticalSpacing");
					end	
				end

			end
			if (not InCombatLockdown()) then
				windowFrame:SetSize(
					4 + cols * (90 + self:GetProperty("HorizontalSpacing")),
					4 + rows * (40 + self:GetProperty("VerticalSpacing"))
				);
			end
		end
		for i=playersShown+1, #playerFrames do
			playerFrames[i]:Disable();
		end
		
		-- STEP 3:
		if (option) then
			currentOptions[option] = value;
			for i, obj in ipairs(playerFrames) do
				obj:Update(option, value);
			end
		end
	end
	
	local function updateOptionsFrame(self)
		if (not self:IsEnabled()) then
			self:Unfocus();
			return;
		end
		for key, val in pairs(defaultOptions) do
			if (_G["CTRAWindow_" .. key .. "CheckButton"]) then
				_G["CTRAWindow_" .. key .. "CheckButton"]:Enable();
				_G["CTRAWindow_" .. key .. "CheckButton"]:SetChecked(self:GetProperty(key));
			elseif (_G["CTRAWindow_" .. key .. "DropDown"]) then
				local dropdown = _G["CTRAWindow_" .. key .. "DropDown"];
				L_UIDropDownMenu_EnableDropDown(dropdown)
				L_UIDropDownMenu_Initialize(dropdown, dropdown.initialize);
				L_UIDropDownMenu_SetSelectedValue(dropdown, self:GetProperty(key));
			elseif (_G["CTRAWindow_" .. key .. "Slider"]) then
				_G["CTRAWindow_" .. key .. "Slider"]:Enable();
				_G["CTRAWindow_" .. key .. "Slider"].suspend = 1;			-- hack to stop OnValueChanged from storing the value in SavedVariables
				_G["CTRAWindow_" .. key .. "Slider"]:SetValue(self:GetProperty(key));
				_G["CTRAWindow_" .. key .. "Slider"].suspend = nil;
			end
		end
	end
	
	local function disableOptionsFrame(self)
		for key, val in pairs(defaultOptions) do
			if (_G["CTRAWindow_" .. key .. "CheckButton"]) then
				_G["CTRAWindow_" .. key .. "CheckButton"]:Disable();
			elseif (_G["CTRAWindow_" .. key .. "DropDown"]) then
				L_UIDropDownMenu_DisableDropDown(_G["CTRAWindow_" .. key .. "DropDown"])
			elseif (_G["CTRAWindow_" .. key .. "Slider"]) then
				_G["CTRAWindow_" .. key .. "Slider"]:Disable();
			end
		end
	end
	
	local function showAnchor(self)
		if (self:IsEnabled()) then
			anchorFrame:Show();
			anchorFrame.text:SetText("Window " .. windowID);
		else
			self:HideAnchor();
		end
	end
	
	local function hideAnchor(self)
		anchorFrame:Hide();
	end
	
	-- public interface, used and returned by the constructor
	local Self =
	{
		Enable = enable,
		Disable = disable,
		IsEnabled = isEnabled,
		Update = update,
		Frame = optionsFrameSkeleton,
		Focus = updateOptionsFrame,
		GetProperty = getProperty,
		ShowAnchor = showAnchor,
		HideAnchor = hideAnchor,
	};
	

	-- public constructor
	return Self;
end

--------------------------------------------
-- CTRAPlayerFrame

function NewCTRAPlayerFrame(parentInterface, parentFrame)
	-- private properties
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
	local macroLeft;		-- the macro used by secureButton during LeftButtonUp, except ~UNIT~ must be changed to shownUnit
	local macroRight;		-- the macro used by secureButton during RightButtonUp, except ~UNIT~ must be changed to shownUnit
	
	-- graphical textures and fontstrings of visualFrame
	local background;
	local healthBarFullCombat, healthBarZeroCombat, healthBarFullNoCombat, healthBarZeroNoCombat;
	local absorbBarFullCombat, absorbBarZeroCombat, absorbBarFullNoCombat, absorbBarZeroNoCombat;
	local healthBarWidth;
	local roleTexture;
	local unitNameFontStringLarge, unitNameFontStringSmall, unitNameFont;
	local aura1Texture, aura2Texture, aura3Texture
	
	
	-- PRIVATE FUNCTIONS

	-- creates (if necessary) and configures all the settings for background and borders, but must not be run until visualFrame exists using self:Update()
	local configureBackdrop = function()
		background = background or visualFrame:CreateTexture(nil, "BACKGROUND");
		background:SetPoint("TOPLEFT", visualFrame, 3, -3);
		background:SetPoint("BOTTOMRIGHT", visualFrame, -3, 3);
		background.colorBackgroundRed, background.colorBackgroundGreen, background.colorBackgroundBlue, background.colorBackgroundAlpha = unpack(owner:GetProperty("ColorBackground"));
		background.colorBackgroundDeadOrGhostRed, background.colorBackgroundDeadOrGhostGreen, background.colorBackgroundDeadOrGhostBlue, background.colorBackgroundDeadOrGhostAlpha = unpack(owner:GetProperty("ColorBackgroundDeadOrGhost"));
		
		visualFrame:SetBackdrop({["edgeFile"] = "Interface\\Tooltips\\UI-Tooltip-Border",["edgeSize"] = 16,});
		visualFrame.colorBorderRed, visualFrame.colorBorderGreen, visualFrame.colorBorderBlue, visualFrame.colorBorderAlpha = unpack(owner:GetProperty("ColorBorder"));
		visualFrame.colorBorderTargetTargetRed, visualFrame.colorBorderTargetTargetGreen, visualFrame.colorBorderTargetTargetBlue, visualFrame.colorBorderTargetTargetAlpha = unpack(owner:GetProperty("ColorBorderTargetTarget"));
		visualFrame.colorBorderBeyondRangeRed, visualFrame.colorBorderBeyondRangeGreen, visualFrame.colorBorderBeyondRangeBlue, visualFrame.colorBorderBeyondRangeAlpha = unpack(owner:GetProperty("ColorBorderBeyondRange"));
	end
	
	-- updates the background and borders, but must not be run until configureBackdrop() has been done
	local updateBackdrop = function()
		if (shownUnit and UnitExists(shownUnit)) then
			if (UnitIsDeadOrGhost(shownUnit)) then
				background:SetColorTexture(background.colorBackgroundDeadOrGhostRed, background.colorBackgroundDeadOrGhostGreen, background.colorBackgroundDeadOrGhostBlue, background.colorBackgroundDeadOrGhostAlpha);
			else
				background:SetColorTexture(background.colorBackgroundRed, background.colorBackgroundGreen, background.colorBackgroundBlue, background.colorBackgroundAlpha);
			end
			if (UnitInRange(shownUnit) or UnitIsUnit("player", shownUnit)) then
				if (UnitExists("target") and UnitIsUnit(shownUnit, "targettarget") and UnitIsEnemy("player", "target")) then
					visualFrame:SetBackdropBorderColor(visualFrame.colorBorderTargetTargetRed, visualFrame.colorBorderTargetTargetGreen, visualFrame.colorBorderTargetTargetBlue, visualFrame.colorBorderTargetTargetAlpha);
				else
					visualFrame:SetBackdropBorderColor(visualFrame.colorBorderRed, visualFrame.colorBorderGreen, visualFrame.colorBorderBlue, visualFrame.colorBorderAlpha);
				end
			else
				visualFrame:SetBackdropBorderColor(visualFrame.colorBorderBeyondRangeRed, visualFrame.colorBorderBeyondRangeGreen, visualFrame.colorBorderBeyondRangeBlue, visualFrame.colorBorderBeyondRangeAlpha);
			end
		end	

	end

	-- creates health and absorb bar textures	
	local configureHealthBar = function()
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
	local updateHealthBar = function()
		if (shownUnit) then
			if (UnitExists(shownUnit) and not UnitIsDeadOrGhost(shownUnit)) then
				-- the unit is alive and should have a health bar
				local healthRatio = UnitHealth(shownUnit) / UnitHealthMax(shownUnit);
				local absorbRatio = (module:getGameVersion() == CT_GAME_VERSION_RETAIL and (UnitGetTotalAbsorbs(shownUnit) / UnitHealthMax(shownUnit))) or 0;  -- the actual value in WoW Retail, or 0 in WoW Classic
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
	
	-- creates and updates the power bar (mana, energy, etc.)
	local powerR, powerG, powerB;
	local updatePowerBar = function(reconfigure)
		if (not visualFrame) then return; end
		if (not visualFrame.powerBar) then
			visualFrame.powerBar = visualFrame:CreateTexture(nil, "ARTWORK", nil, 1);	-- the fourth value '1' draws this over the health bar, but below ready checks
			visualFrame.powerBar:SetTexture("Interface\\TargetingFrame\\UI-StatusBar");
			visualFrame.powerBar:SetHeight(6);
		end	
		if (shownUnit) then
			if (UnitExists(shownUnit) and not UnitIsDeadOrGhost(shownUnit) and owner:GetProperty("EnablePowerBar")) then
				local maxWidth = (owner:GetProperty("HealthBarAsBackground") and 82) or 70;
				local powerRatio = UnitPower(shownUnit) / UnitPowerMax(shownUnit);
				if (powerRatio < 0.01) then 
					visualFrame.powerBar:Hide();
				else 
					visualFrame.powerBar:SetWidth(maxWidth*min(1,powerRatio));
					visualFrame.powerBar:Show();
				end
				if (not powerR or reconfigure) then
					local powerType, powerToken, altR, altG, altB = UnitPowerType(shownUnit);
					local info = PowerBarColor[powerToken];
					if ( info ) then
						--The PowerBarColor takes priority
					 	powerR, powerG, powerB = info.r, info.g, info.b;
					else
					 	if (not altR) then
					 		-- Couldn't find a power token entry. Default to indexing by power type or just mana if  we don't have that either.
					 		info = PowerBarColor[powerType] or PowerBarColor["MANA"];
					 		powerR, powerG, powerB = info.r, info.g, info.b;
						else
							powerR, powerG, powerB = altR, altG, altB;
						end
					end
					visualFrame.powerBar:SetVertexColor(powerR, powerG, powerB);
					if (owner:GetProperty("HealthBarAsBackground")) then					-- the powerBar shifts in size and location to align nicely with the healthBar
						visualFrame.powerBar:SetPoint("BOTTOMLEFT", visualFrame, 4, 4);		
					else
						visualFrame.powerBar:SetPoint("BOTTOMLEFT", visualFrame, 10, 6);
					end
				end
				local a;	-- use the same alpha rules as the health bar for consistency... except base it on UnitPower == UnitPowerMax instead of Health == HealthMax
				if (InCombatLockdown()) then
					a = powerRatio > 0.99 and owner:GetProperty("ColorUnitFullHealthCombat")[4] or owner:GetProperty("ColorUnitZeroHealthCombat")[4];
				else
					a = powerRatio > 0.99 and owner:GetProperty("ColorUnitFullHealthNoCombat")[4] or owner:GetProperty("ColorUnitZeroHealthNoCombat")[4];
				end	
			else
			
				visualFrame.powerBar:Hide();
			end
		end
	end
	
	-- creates a texture to display the tank/heal/dps role icon in top left; but visualFrame must exist already
	local configureRoleTexture = function()
		roleTexture = roleTexture or visualFrame:CreateTexture(nil, "OVERLAY");
		roleTexture:SetSize(10,10);
		roleTexture:SetPoint("TOPLEFT", visualFrame, 3, -5);	
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
				roleTexture:SetTexture("Interface\\AddOns\\CT_RaidAssist\\Images\\dpsicon");
				roleTexture:Show();
			elseif (roleAssigned == "HEALER") then
				roleTexture:SetTexture("Interface\\AddOns\\CT_RaidAssist\\Images\\healicon");
				roleTexture:Show();
			elseif (roleAssigned == "TANK") then
				roleTexture:SetTexture("Interface\\AddOns\\CT_RaidAssist\\Images\\tankicon");
				roleTexture:Show();
			else
				roleTexture:Hide();
			end
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
		unitNameFontStringLarge:SetPoint("BOTTOMLEFT", visualFrame, "LEFT", 12 * scale, 0);	-- leave room for roleTexture
		unitNameFontStringLarge:SetPoint("BOTTOMRIGHT", visualFrame, "RIGHT", -12 * scale, 0);	-- leave room for aura icons
		unitNameFontStringLarge:SetHeight(8 * scale);	-- prevents a shift when the name is truncated
		
	
		unitNameFontStringSmall = unitNameFontStringSmall or visualFrame:CreateFontString(nil, "OVERLAY");
		unitNameFontStringSmall:SetIgnoreParentScale(true);
		unitNameFontStringSmall:SetFontObject(module:GetUnitNameFontSmall(scale));
		unitNameFontStringSmall:SetPoint("BOTTOMLEFT", visualFrame, "LEFT", 12 * scale, 0.5 * scale);		-- leave room for roleTexture
		unitNameFontStringSmall:SetPoint("BOTTOMRIGHT", visualFrame, "RIGHT", -12 * scale, 0.5 * scale);	-- leave room for aura icons
		unitNameFontStringSmall:SetHeight(7 * scale);	-- prevents a shift when the name is truncated
	end
	
	-- creates and updates the player's name
	local updateUnitNameFontString = function()
		if (shownUnit) then
			if (UnitExists(shownUnit)) then
				-- show the name, but omit the server
				local name, realm;
				name, realm = strsplit("-", UnitName(shownUnit), 2);
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
		aura1Texture = aura1Texture or visualFrame:CreateTexture(nil, "OVERLAY");
		aura1Texture:SetSize(9,9);
		aura1Texture:SetPoint("TOPRIGHT", visualFrame, -5, -5);

		aura2Texture = aura2Texture or visualFrame:CreateTexture(nil, "OVERLAY");
		aura2Texture:SetSize(9,9);
		aura2Texture:SetPoint("TOPRIGHT", visualFrame, -5, -15);
		
		aura3Texture = aura3Texture or visualFrame:CreateTexture(nil, "OVERLAY");
		aura3Texture:SetSize(9,9);
		aura3Texture:SetPoint("TOPRIGHT", visualFrame, -5, -25);
	end
	
	-- creates and updates buff/debuff icons
	local updateAuras = function()
		if (shownUnit) then
			if(UnitExists(shownUnit) and not UnitIsDeadOrGhost(shownUnit)) then
				local filter = (InCombatLockdown() and "RAID HARMFUL") or "RAID HELPFUL";
				local name, icon = UnitAura(shownUnit, 1, filter);
				if (name) then
					aura1Texture:SetTexture(icon);
					aura1Texture:Show();
					aura1Texture.name = name;
					name, icon = UnitAura(shownUnit, 2, filter);
					if (name) then
						aura2Texture:SetTexture(icon);
						aura2Texture:Show();
						aura2Texture.name = name;
						name, icon = UnitAura(shownUnit, 3, filter);
						if (name) then
							aura3Texture:SetTexture(icon);
							aura3Texture:Show();
							aura3Texture.name = name;
						else
							aura3Texture:Hide();
						end
					else
						aura2Texture:Hide();
						aura3Texture:Hide();
					end
				else
					aura1Texture:Hide();
					aura2Texture:Hide();
					aura3Texture:Hide();
				end
			else
				aura1Texture:Hide();
				aura2Texture:Hide();
				aura3Texture:Hide();
			end
		end
	end
	
	-- creates and updates ready check indicators
	local updateReadyStatus = function()
		if (not visualFrame) then return; end
		if (not visualFrame.readyIcon or not visualFrame.readyText) then
			visualFrame.readyIcon = visualFrame:CreateTexture(nil, "OVERLAY");
			visualFrame.readyIcon:SetSize(10,10);
			visualFrame.readyIcon:SetPoint("LEFT", visualFrame, 4, 0);
			visualFrame.readyText = visualFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
			visualFrame.readyText:SetPoint("TOP", visualFrame, "CENTER");
			visualFrame.readyBackground = visualFrame:CreateTexture(nil, "ARTWORK", nil, 2);	-- the 4th param '2' draws this in front of the power bar
			visualFrame.readyBackground:SetPoint("TOPLEFT", 4, -4);
			visualFrame.readyBackground:SetPoint("BOTTOMRIGHT", -4, 4);
		end
		if (shownUnit) then
			local ready = GetReadyCheckStatus(shownUnit)
			if (ready == "waiting") then
				visualFrame.readyIcon:Show();
				visualFrame.readyIcon:SetTexture(READY_CHECK_WAITING_TEXTURE);
				visualFrame.readyText:Show();
				visualFrame.readyText:SetText("No Reply");
				visualFrame.readyBackground:SetColorTexture(unpack(owner:GetProperty("ColorReadyCheckWaiting")));
				visualFrame.readyBackground:Show();
			elseif (ready == "ready") then
				visualFrame.readyIcon:Show();
				visualFrame.readyIcon:SetTexture(READY_CHECK_READY_TEXTURE);
				visualFrame.readyText:Hide();
				visualFrame.readyBackground:Hide();
			elseif (ready == "not ready") then
				visualFrame.readyIcon:Show();
				visualFrame.readyIcon:SetTexture(READY_CHECK_NOT_READY_TEXTURE);
				visualFrame.readyText:Show();
				visualFrame.readyText:SetText("Not Ready");
				visualFrame.readyBackground:SetColorTexture(unpack(owner:GetProperty("ColorReadyCheckNotReady")));
				visualFrame.readyBackground:Show();
			else
				visualFrame.readyIcon:Hide();
				visualFrame.readyText:Hide();
				visualFrame.readyBackground:Hide();
			end
		end
	end
	
	-- returns a table with nomod, mod:shift, mod:ctrl or mod:alt as a key and then a valid spellName as a value
	local canRezCombat = function()
		local __, class = UnitClass("player");
		if (CTRA_Configuration_RezAbilities[class]) then
			local combatRezToCast = { };
			local hasRez = nil;
			for i, details in ipairs(CTRA_Configuration_RezAbilities[class]) do
				if (GetSpellInfo(module.text["CTRA/Spells/" .. details.name]) and details.combat and (details.gameVersion == nil or details.gameVersion == module:getGameVersion()) and combatRezToCast[details.modifier] == nil and (details.spec == nil or details.spec == spec)) then
					combatRezToCast[details.modifier] = module.text["CTRA/Spells/" .. details.name];
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
		if (CTRA_Configuration_RezAbilities[class]) then
			local nocombatRezToCast = { };
			local hasRez = nil;
			for i, details in ipairs(CTRA_Configuration_RezAbilities[class]) do
				if (GetSpellInfo(module.text["CTRA/Spells/" .. details.name]) and details.nocombat and (details.gameVersion == nil or details.gameVersion == module:getGameVersion()) and nocombatRezToCast[details.modifier] == nil and (details.spec == nil or details.spec == spec)) then
					nocombatRezToCast[details.modifier] = module.text["CTRA/Spells/" .. details.name];
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
		if (CTRA_Configuration_FriendlyRemoves[class]) then
			local friendlyRemovesToCast = { };
			local hasFriendlyRemoves = nil;
			for i, details in ipairs(CTRA_Configuration_FriendlyRemoves[class]) do
				if (GetSpellInfo(module.text["CTRA/Spells/" .. details.name]) and (details.gameVersion == nil or details.gameVersion == module:getGameVersion()) and friendlyRemovesToCast[details.modifier] == nil and (details.spec == nil or details.spec == spec)) then
					friendlyRemovesToCast[details.modifier] = module.text["CTRA/Spells/" .. details.name];
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
		if (CTRA_Configuration_Buffs[class]) then
			local buffsToCast = { };
			local hasBuffs = nil;
			for i, details in ipairs(CTRA_Configuration_Buffs[class]) do
				if (GetSpellInfo(module.text["CTRA/Spells/" .. details.name]) and (details.gameVersion == nil or details.gameVersion == module:getGameVersion()) and (buffsToCast[details.modifier] == nil)) then
					buffsToCast[details.modifier] = module.text["CTRA/Spells/" .. details.name];
					hasBuffs = true;
				end
			end
			if (hasBuffs) then
				return buffsToCast;
			end
		end
		return nil;
	end

	-- updates macroLeft and macroRight to support secureButton
	local updateMacros = function()
		if (InCombatLockdown() or not secureButton or not visualFrame) then return; end

		-- LeftButtonUp
		macroLeft = "/target ~UNIT~";	
		
		-- RightButtonUp
		macroRight = "";
		local rezCombat = canRezCombat();
		local rezNoCombat = canRezNoCombat();
		local removeDebuff = canRemoveDebuff();
		local applyBuff = canBuff();
		if (rezCombat or rezNoCombat or removeDebuff or applyBuff) then
			macroRight = macroRight .. "/cast";
			if (rezCombat) then						-- [@party1, exists, dead, combat, nomod] Rebirth;
				for modifier, spellName in pairs(rezCombat) do
					macroRight = macroRight .. " [@~UNIT~, exists, dead, combat, " .. modifier .. "] " .. spellName .. ";";
				end
			end			
			if (rezNoCombat) then						-- [@party1, exists, dead, nocombat, nomod] Resurrection;
				for modifier, spellName in pairs(rezNoCombat) do
					macroRight = macroRight .. " [@~UNIT~, exists, dead, nocombat, " .. modifier .. "] " .. spellName .. ";";
				end
			end
			if (removeDebuff) then						-- [@party1, exists, nodead, combat, nomod] Abolish Poison; [@party1, nodead, combat, mod:shift] Remove Curse;
				for modifier, spellName in pairs(removeDebuff) do
					macroRight = macroRight .. " [@~UNIT~, exists, nodead, combat, " .. modifier .. "] " .. spellName .. ";";
				end
			end	
			if (applyBuff) then						-- [@party1, exists, nodead, nocombat, nomod] Arcane Intellect; [@party1, nodead, nocombat, mod:shift] Arcane Brilliance;
				for modifier, spellName in pairs(applyBuff) do
					macroRight = macroRight .. " [@~UNIT~, exists, nodead, nocombat, " .. modifier .. "] " .. spellName .. ";";
				end
			end
		end
	end
	
	-- PUBLIC FUNCTIONS
	
	local enable = function(self, unit, xOff, yOff)
		if (not unit) then
			self:Disable();
			return;
		end
		requestedUnit = unit;
		requestedXOff = xOff or 2;
		requestedYOff = yOff or 2;
		self:Update();
	end
	
	local disable = function(self)
		requestedUnit = nil;
		requestedXOff = nil;
		requestedYOff = nil;
		self:Update();
	end
	
	local isEnabled = function(self)
		return requestedUnit ~= nil
	end
	
	local isShown = function(self)
		return shownUnit ~= nil
	end
	
	local update = function(self, option, value)
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
				visualFrame:Hide();
				visualFrame:SetSize(90, 40);
				visualFrame:SetScale(owner:GetProperty("PlayerFrameScale")/100);
								
				-- overlay button that can be clicked to do stuff in combat (the secure configuration is made later in step 3)
				secureButton = CreateFrame("Button", nil, visualFrame, "SecureUnitButtonTemplate");
				secureButton:SetAllPoints();
				secureButton:RegisterForClicks("LeftButtonUp", "RightButtonUp");
				secureButton:SetAttribute("type1", "macro");
				secureButton:SetAttribute("type2", "macro");
				secureButton:HookScript("OnEnter",
					function()
						GameTooltip:SetOwner(parent) --, "ANCHOR_RIGHT", 10, -50);
						local className, classFilename = UnitClass(shownUnit);
						local r,g,b = GetClassColor(classFilename);
						GameTooltip:AddDoubleLine(UnitName(shownUnit) or "", UnitLevel(shownUnit) or 0, r,g,b, 1,1,1);
						if ( UnitRace(shownUnit) and className ) then
							GameTooltip:AddLine(UnitRace(shownUnit) .. " " .. className, 1, 1, 1);
						end
						if (aura1Texture:IsShown()) then
							GameTooltip:AddLine("|T" .. aura1Texture:GetTexture() .. ":0|t  " .. (aura1Texture.name or ""));
							if (aura2Texture:IsShown()) then
								GameTooltip:AddLine("|T" .. aura2Texture:GetTexture() .. ":0|t  " .. (aura2Texture.name or ""));
								if (aura3Texture:IsShown()) then
									GameTooltip:AddLine("|T" .. aura3Texture:GetTexture() .. ":0|t  " .. (aura3Texture.name or ""));
								end
							end
						end
						local buff = canBuff();
						local remove = canRemoveDebuff();
						local rezCombat = canRezCombat();
						local rezNoCombat = canRezNoCombat();
						if (not InCombatLockdown() and buff or remove or rezCombat or rezNoCombat) then
							GameTooltip:AddLine("|nRight click...");
							if buff then for modifier, spellName in pairs(buff) do GameTooltip:AddDoubleLine("|cFF33FF66nocombat" .. ((modifier ~= "nomod" and (", " .. modifier)) or ""), "|cFF33FF66" .. module.text["CTRA/Spells/" .. spellName]); end end
							if rezCombat then for modifier, spellName in pairs(rezCombat) do GameTooltip:AddDoubleLine("|cFFCCCC66nocombat, dead" .. ((modifier ~= "nomod" and (", " .. modifier)) or ""), "|cFFCCCC66" .. module.text["CTRA/Spells/" .. spellName]); end end
							if remove then for modifier, spellName in pairs(remove) do GameTooltip:AddDoubleLine("|cFFFF6666combat" .. ((modifier ~= "nomod" and (", " .. modifier)) or ""), "|cFFFF6666" .. module.text["CTRA/Spells/" .. spellName]); end end
							if rezNoCombat then for modifier, spellName in pairs(rezNoCombat) do GameTooltip:AddDoubleLine("|cFFFF6666combat, dead" .. ((modifier ~= "nomod" and (", " .. modifier)) or ""), "|cFFFF6666" .. module.text["CTRA/Spells/" .. spellName]); end end
						end
						GameTooltip:Show();
						
					end
				);
				secureButton:HookScript("OnLeave",
					function()
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
					visualFrame:SetScale((value or 100)/100);
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
					updateReadyStatus();
				elseif (
					key == "HealthBarAsBackground"
				) then
					configureHealthBar();
					updatePowerBar(true);
				elseif (key == "EnablePowerBar") then
					visualFrame.powerBar:SetShown(value)
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
		if (requestedUnit ~= shownUnit or requestedXOff ~= shownXOff or requestedYOff ~= shownYOff) then
			if (not InCombatLockdown()) then
				-- set the flags
				shownUnit = requestedUnit;
				shownXOff = requestedXOff;
				shownYOff = requestedYOff;
				updateForced = nil;
				
				-- register or de-register events
				if (not listenerFrame) then
					listenerFrame = CreateFrame("Frame", nil);
					listenerFrame:SetScript("OnEvent",
						function(frame, event, ...)
							local args = {...};
							if (event == "SPELLS_CHANGED") then
								updateMacros();
							elseif (event == "UNIT_NAME_UPDATE") then
								updateUnitNameFontString();
							elseif (event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH") then
								updateHealthBar();
								updateBackdrop();
							elseif (event == "UNIT_POWER_UPDATE") then
								updatePowerBar();
							elseif (event == "UNIT_DISPLAYPOWER") then
								updatePowerBar(true);
							elseif (event == "UNIT_AURA") then
								updateAuras();
							elseif (event == "READY_CHECK") then
								updateReadyStatus()
							elseif (event == "READY_CHECK_CONFIRM") then
								updateReadyStatus();
							elseif (event == "READY_CHECK_FINISHED") then
								updateReadyStatus()
							end
						end
					);
					local timeElapsed = 0;
					listenerFrame:SetScript("OnUpdate",
						function(frame, elapsed)
							timeElapsed = timeElapsed + elapsed;
							if (timeElapsed < 3) then return; end
							timeElapsed = 0;
							updateBackdrop();
							
							--[[	THIS FOR LOOP IS FOR PERFORMANCE OPTIMIZATION TESTING ONLY
								local begin = debugprofilestop();		-- ~23 modern, ~26 classic
								print(" ");
								for i=1, 1000 do
									updateBackdrop()			--2.7 without target, 3.2 with target, 
									updateHealthBar();			--4.6 without absorb, 7.8 with absorbs
									updatePowerBar();			--3.0 modern, 5.4 classic
									updateRoleTexture();			--1.1 solo, 2.3 skull, 2.9 dps
									updateUnitNameFontString();		--2.3 solo, 2.9 for group member
									updateAuras();				--2.1 no buff, 8.6 one buff, 12.0 two buffs
									updateReadyStatus();			--1.1 solo, ?? during ready check
								end
								print (debugprofilestop() - begin);
							--]]

						end
					);
				end
				if (shownUnit and shownXOff and shownYOff) then
					visualFrame:Show(); 
					listenerFrame:UnregisterAllEvents();  -- probably not required, but doing it to be absolute
					listenerFrame:RegisterUnitEvent("UNIT_NAME_UPDATE", shownUnit);		-- updateName();
					listenerFrame:RegisterUnitEvent("UNIT_HEALTH", shownUnit);	-- updateHealthBar(); updateBackdrop();
					listenerFrame:RegisterUnitEvent("UNIT_MAXHEALTH", shownUnit);		-- updateHealthBar(); updateBackdrop();
					listenerFrame:RegisterUnitEvent("UNIT_POWER_UPDATE", shownUnit);	-- updatePowerBar();
					listenerFrame:RegisterUnitEvent("UNIT_DISPLAYPOWER", shownUnit);	-- updatePowerBar(true);
					listenerFrame:RegisterUnitEvent("UNIT_AURA", shownUnit);		-- updateAuras();
					listenerFrame:RegisterEvent("READY_CHECK");				-- updateReadyStatus();
					listenerFrame:RegisterUnitEvent("READY_CHECK_CONFIRM", shownUnit);	-- updateReadyStatus();
					listenerFrame:RegisterEvent("READY_CHECK_FINISHED");			-- updateReadyStatus();
				else
					visualFrame:Hide();
					listenerFrame:UnregisterAllEvents();
					return;		-- go absolutely no further if we arn't supposed to be showing anything any more!
				end

				-- reposition the frames
				visualFrame:SetPoint("TOPLEFT", requestedXOff, requestedYOff);
									
				-- configure the secureButton for the new unit
				secureButton:SetAttribute("unit", shownUnit);
				if not (macroLeft) then
					updateMacros();
				end
				local textL = gsub(macroLeft,"~UNIT~",shownUnit);
				local textR = gsub(macroRight,"~UNIT~",shownUnit);
				secureButton:SetAttribute("macrotext1", textL);
				secureButton:SetAttribute("macrotext2", textR);
			end
		end
		if (shownUnit) then
			configureBackdrop();
			updateBackdrop();
			configureHealthBar();
			updateHealthBar();
			updatePowerBar(true);
			configureRoleTexture();
			updateRoleTexture();
			configureUnitNameFontString();
			updateUnitNameFontString();
			configureAuras();
			updateAuras();
			updateReadyStatus();
		end	
	end
	
	-- PUBLIC INTERFACE
	
	local Self = {
		Enable = enable,
		Disable = disable,
		IsEnabled = isEnabled,
		IsShown = isShown,
		Update = update,
	}
	
	-- PUBLIC CONSTRUCTOR
	
	do
		owner = parentInterface;	
		parent = parentFrame;
		return Self;			-- that's it!  nothing else is done until Self:Enable()
	end
	
end	-- end CTRAPlayerFrame