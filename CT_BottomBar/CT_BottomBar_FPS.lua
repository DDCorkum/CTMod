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

local CT_BB_FPS_DefaultPoint = nil;
local CT_BB_FPS_DefaultRelativeTo = nil;
local CT_BB_FPS_DefaultRelativePoint = nil;
local CT_BB_FPS_DefaultX = nil;
local CT_BB_FPS_DefaultY = nil;

--------------------------------------------
-- Action bar arrows and page number

local function addon_Update(self)
	-- Update the frame
	-- self == framerate container

	self.helperFrame:ClearAllPoints();
	self.helperFrame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", -5, 5);
	self.helperFrame:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", 5, -5);
	
end


local function addon_Enable(self)
	if (not not self.frame) then
		FramerateLabel:ClearAllPoints();
		FramerateLabel:SetPoint("BOTTOMLEFT",self.frame,"BOTTOMLEFT", 0,0);
	end
end

local function addon_Disable(self)
	if (not not CT_BB_FPS_DefaultPoint) then
		FramerateLabel:ClearAllPoints();
		FramerateLabel:SetPoint(CT_BB_FPS_DefaultPoint,CT_BB_FPS_DefaultRelativeTo,CT_BB_FPS_DefaultRelativePoint, CT_BB_FPS_DefaultX, CT_BB_FPS_DefaultY);
	end
end


local function addon_Init(self)
	-- Initialization
	-- self == actionbar arrows bar object

	appliedOptions = module.appliedOptions;

	module.ctFramerateBar = self;

	self.frame:SetFrameLevel(MainMenuBarArtFrame:GetFrameLevel() + 1);
	self.frame:SetHeight(30);
	self.frame:SetWidth(90);

	local frame = CreateFrame("Frame", "CT_BottomBar_" .. self.frameName .. "_GuideFrame");
	self.helperFrame = frame;
	
	CT_BB_FPS_DefaultPoint, CT_BB_FPS_DefaultRelativeTo, CT_BB_FPS_DefaultRelativePoint, CT_BB_FPS_DefaultX, CT_BB_FPS_DefaultY = FramerateLabel:GetPoint(1);
		
	return true;
end

local function addon_Register()
	module:registerAddon(
		"Framerate Bar",  -- option name
		"Frameratebar",  -- used in frame names
		"FPS Indicator (CTRL-R)",  -- shown in options window & tooltips
		"FPS (Ctrl-R)",  -- title for horizontal orientation
		nil,  -- title for vertical orientation
		{ "BOTTOMLEFT", ctRelativeFrame, "BOTTOM", -20, 120 },
		{ -- settings
			orientation = "ACROSS",
			saveShown = false,  -- don't save shown state... let Blizzard show/hide it.
			noHideOption = true,  -- no "hide" option for this bar
		},
		addon_Init,
		nil,  -- no post init function
		nil,  -- no config function
		addon_Update,
		nil,  -- no orientation function
		addon_Enable,
		nil,  -- no disable function
		"helperFrame",
		FramerateLabel,
		FramerateText
	);
end

module.loadedAddons["Framerate Bar"] = addon_Register;
