------------------------------------------------
--               CT_BottomBar                 --
--                                            --
-- Breaks up the main menu bar into pieces,   --
-- allowing you to hide and move the pieces   --
-- independently of each other.               --
--                                            --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
------------------------------------------------

-- Credit:
-- CT_BB module written by DDCorkum


--------------------------------------------
-- Initialization

local _G = getfenv(0);
local module = _G.CT_BottomBar;

local ctRelativeFrame = module.ctRelativeFrame;
local appliedOptions;

local CT_BB_StanceBar_IsEnabled = nil;

--------------------------------------------
-- Action bar arrows and page number

local function moveStanceBar()
	if (not StanceBarFrame or InCombatLockdown()) then return; end
	if (CT_BB_StanceBar_IsEnabled) then
		StanceButton1:ClearAllPoints();
		StanceButton1:SetPoint("BOTTOMLEFT",CT_BottomBar_CTStanceBarFrame_Frame);	
	else
		StanceButton1:ClearAllPoints();
		StanceButton1:SetPoint("BOTTOMLEFT",StanceBarFrame);	
	end
end

local function addon_Update(self)
	-- Update the frame
	-- self == talking head object

	self.helperFrame:ClearAllPoints();
	self.helperFrame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", -5, 5);
	self.helperFrame:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", 5, -5);
end

local function addon_Enable(self)
	CT_BB_StanceBar_IsEnabled = true;
	moveStanceBar();
end

local function addon_Disable(self)
	CT_BB_StanceBar_IsEnabled = false;
	moveStanceBar();
end

local function addon_Init(self)
	-- Initialization
	-- self == stance bar object

	appliedOptions = module.appliedOptions;

	module.ctStanceBar = self;

	local frame = CreateFrame("Frame", "CT_BottomBar_" .. self.frameName .. "_GuideFrame");
	self.helperFrame = frame;
	
	self.frame:SetHeight(32);
	self.frame:SetWidth(29);
	
	hooksecurefunc("UIParent_ManageFramePositions", moveStanceBar);
	StanceBarFrame:HookScript("OnShow", moveStanceBar);

	return true;
end

local function addon_Register()
	module:registerAddon(
		"Stance Bar",  -- option name
		"CTStanceBarFrame",  -- used in frame names
		"Stance Bar",  -- shown in options window & tooltips
		"Stance Bar",  -- title for horizontal orientation
		nil,  -- title for vertical orientation
		{ "BOTTOMLEFT", MainMenuBar, "TOPLEFT", 30, 9 },
		{ -- settings
			orientation = "ACROSS",
		},
		addon_Init,
		nil,  -- no post init function
		nil,  -- no config function
		addon_Update,
		nil,  -- no orientation function
		addon_Enable,
		addon_Disable,  -- no disable function
		"helperFrame",
		StanceBarFrame
	);
end

module.loadedAddons["Stance Bar"] = addon_Register;
