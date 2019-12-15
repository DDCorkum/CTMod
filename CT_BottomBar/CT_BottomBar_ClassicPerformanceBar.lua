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

local isEnabled = nil;

--------------------------------------------
-- Performance Monitor

local function addon_Update(self)
	-- Update the frame
	-- self == actionbar arrows bar object

	self.helperFrame:ClearAllPoints();
	self.helperFrame:SetPoint("TOPLEFT", MainMenuBarPerformanceBarFrame, "TOPLEFT", -5, 5);
	self.helperFrame:SetPoint("BOTTOMRIGHT", MainMenuBarPerformanceBarFrame, "BOTTOMRIGHT", 5, 0);

end

local function updatePosition(self)
	if (isEnabled) then
		MainMenuBarPerformanceBarFrame:SetPoint("BOTTOMRIGHT", self.frame, 0, 0);
		self.frame:SetClampRectInsets(5,5,35,15);
	else
		MainMenuBarPerformanceBarFrame:SetPoint("BOTTOMRIGHT", MainMenuBar, -235, -10);
	end
end

local function addon_Enable(self)
	isEnabled = true;
	updatePosition(self);
end

local function addon_Disable(self)
	isEnabled = false;
	updatePosition(self);
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

local function addon_PostInit(self)
	local isActive = nil;
	hooksecurefunc(MainMenuBarPerformanceBarFrame, "SetPoint", function()
		if (isActive) then
			return;
		else
			isActive = true;
			updatePosition(self);
			isActive = nil;
		end
		
	end);
end

local function addon_Register()
	module:registerAddon(
		"Classic Performance Bar",  -- option name
		"ClassicPerformanceBar",  -- used in frame names
		module.text["CT_BottomBar/Options/ClassicPerformanceBar"],  -- shown in options window & tooltips
		module.text["CT_BottomBar/Options/ClassicPerformanceBar"],  -- title for horizontal orientation
		nil,  -- title for vertical orientation
		{ "BOTTOMRIGHT", ctRelativeFrame, "BOTTOM", 277, -10 },
		{ -- settings
			orientation = "ACROSS",
		},
		addon_Init,
		addon_PostInit,  -- no post init function
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
