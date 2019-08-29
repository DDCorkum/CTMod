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

--------------------------------------------
-- Initialization

local _G = getfenv(0);
local module = _G.CT_BottomBar;

local ctRelativeFrame = module.ctRelativeFrame;
local appliedOptions;

--------------------------------------------
-- Action bar arrows and page number

local function addon_Update(self)
	-- Update the frame
	-- self == actionbar arrows bar object

	self.helperFrame:ClearAllPoints();
	self.helperFrame:SetPoint("TOPLEFT", MainMenuBarPerformanceBarFrame, "TOPLEFT", -5, 5);
	self.helperFrame:SetPoint("BOTTOMRIGHT", MainMenuBarPerformanceBarFrame, "BOTTOMRIGHT", 5, 0);

end

local function addon_Enable(self)
	MainMenuBarPerformanceBarFrame:SetPoint("BOTTOMRIGHT", self.frame, 0, 0);
	self.frame:SetClampRectInsets(5,5,35,15);
end

local function addon_Disable(self)
	MainMenuBarPerformanceBarFrame:SetPoint("BOTTOMRIGHT", MainMenuBar, -227, -10);
end

local function addon_Init(self)
	-- Initialization
	-- self == actionbar arrows bar object

	appliedOptions = module.appliedOptions;

	module.ctClassicPerformanceBar = self;

	self.frame:SetFrameLevel(1);

	local frame = CreateFrame("Frame", "CT_BottomBar_" .. self.frameName .. "_GuideFrame");
	self.helperFrame = frame;

	return true;
end

local function addon_Register()
	module:registerAddon(
		"Classic Performance Bar",  -- option name
		"ClassicPerformanceBar",  -- used in frame names
		"Performance Bar",  -- shown in options window & tooltips
		nil,  -- title for horizontal orientation
		nil,  -- title for vertical orientation
		{ "BOTTOMRIGHT", MainMenuBar, "BOTTOMRIGHT", -227, -10 },
		{ -- settings
			orientation = "ACROSS",
		},
		addon_Init,
		nil,  -- no post init function
		nil,  -- no config function
		addon_Update,
		nil,  -- no orientation function
		addon_Enable,
		addon_Disable,
		"helperFrame",
		MainMenuBarPerformanceBarFrame
	);
end

module.loadedAddons["Classic Performance Bar"] = addon_Register;
