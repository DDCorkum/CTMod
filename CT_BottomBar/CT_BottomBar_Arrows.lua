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

	local objUp = ActionBarUpButton;
	local objDown = ActionBarDownButton;
	local objPage = MainMenuBarArtFrame.PageNumber;

	self.helperFrame:ClearAllPoints();
	self.helperFrame:SetPoint("TOPLEFT", objUp, "TOPLEFT", 5, -5);
	self.helperFrame:SetPoint("BOTTOMRIGHT", objDown, "BOTTOMRIGHT", 5, 5);

	objDown:SetParent(self.frame);
	objDown:ClearAllPoints();
	objDown:SetPoint("BOTTOMLEFT", self.frame, 0, 0);

	objUp:SetParent(self.frame);
	objUp:ClearAllPoints();
	objUp:SetPoint("BOTTOMLEFT", objDown, "TOPLEFT", 0, -12);

	objPage:SetParent(self.frame);
	objPage:ClearAllPoints();
	objPage:SetPoint("TOPLEFT", objDown, "TOPLEFT", 32.5, 0);
end

local function addon_Enable(self)
	self.frame:SetClampRectInsets(10, -10, 39, 10);
end

local function addon_Init(self)
	-- Initialization
	-- self == actionbar arrows bar object

	appliedOptions = module.appliedOptions;

	module.ctActionBarPage = self;

	self.frame:SetFrameLevel(MainMenuBarArtFrame:GetFrameLevel() + 1);

	local frame = CreateFrame("Frame", "CT_BottomBar_" .. self.frameName .. "_GuideFrame");
	self.helperFrame = frame;

	return true;
end

local function addon_Register()
	module:registerAddon(
		"Action Bar Arrows",  -- option name
		"ActionBarPage",  -- used in frame names
		"Action Bar Page",  -- shown in options window & tooltips
		"Page",  -- title for horizontal orientation
		nil,  -- title for vertical orientation
		{ "BOTTOMLEFT", ctRelativeFrame, "BOTTOM", -6, -5 },
		{ -- settings
			orientation = "ACROSS",
		},
		addon_Init,
		nil,  -- no post init function
		nil,  -- no config function
		addon_Update,
		nil,  -- no orientation function
		addon_Enable,
		nil,  -- no disable function
		"helperFrame",
		ActionBarUpButton,
		ActionBarDownButton,
		MainMenuBarPageNumber
	);
end

module.loadedAddons["Action Bar Arrows"] = addon_Register;
