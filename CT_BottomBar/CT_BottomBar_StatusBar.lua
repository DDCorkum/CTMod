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

CT_BottomBar_StatusBar_DefaultParent = nil;
CT_BottomBar_StatusBar_Frame = nil;
CT_BottomBar_StatusBar_HelperFrame = nil;

--------------------------------------------
-- Status Tracking Bar Manager

local function addon_Update(self)
	-- Update the frame
	-- self == status tracking bar manager object

	CT_BottomBar_StatusBar_Frame:SetWidth(appliedOptions.customStatusBarWidth or 1024);
		
	StatusTrackingBarManager:ClearAllPoints();
	StatusTrackingBarManager:SetPoint("TOPLEFT", self.frame, 0, 0);
	StatusTrackingBarManager:UpdateBarsShown();
	
	CT_BottomBar_StatusBar_HelperFrame:ClearAllPoints();
	CT_BottomBar_StatusBar_HelperFrame:SetPoint("TOPLEFT", CT_BottomBar_StatusBar_Frame, "TOPLEFT", -5, 5);
	CT_BottomBar_StatusBar_HelperFrame:SetPoint("BOTTOMRIGHT", CT_BottomBar_StatusBar_Frame, "BOTTOMRIGHT", 5, -5);



end


local function addon_Enable(self)
	if (not not self.frame) then
		StatusTrackingBarManager:SetParent(self.frame);
		StatusTrackingBarManager:UpdateBarsShown();
	end
end

local function addon_Disable(self)
	if (not not CT_BottomBar_StatusBar_DefaultParent) then
		StatusTrackingBarManager:SetParent(CT_BottomBar_StatusBar_DefaultParent);
		StatusTrackingBarManager:UpdateBarsShown();
	end
end

local function addon_Init(self)
	-- Initialization
	-- self == status tracking bar manager object

	appliedOptions = module.appliedOptions;
	module.ctStatusBar = self;
	module.CT_BottomBar_StatusBar_SetWidth = addon_Update;

	CT_BottomBar_StatusBar_Frame = self.frame;
	CT_BottomBar_StatusBar_Frame:SetFrameLevel(MainMenuBarArtFrame:GetFrameLevel() + 1);
	
	CT_BottomBar_StatusBar_HelperFrame = CreateFrame("Frame", "CT_BottomBar_" .. self.frameName .. "_GuideFrame");
	self.helperFrame = CT_BottomBar_StatusBar_HelperFrame;
	CT_BottomBar_StatusBar_DefaultParent = StatusTrackingBarManager:GetParent();
		
	CT_BottomBar_StatusBar_Frame.OnStatusBarsUpdated = CT_BottomBar_StatusBar_OnStatusBarsUpdated;

	addon_Update(self);
	return true;
end

function CT_BottomBar_StatusBar_OnStatusBarsUpdated(self)
	--CT_BottomBar_StatusBar_DefaultParent.OnStatusBarsUpdated(self)
end

local function addon_Register()
	module:registerAddon(
		"Status Bar",  -- option name
		"StatusBar",  -- used in frame names
		"Status Bar (XP & rep)",  -- shown in options window & tooltips
		"Status Bar",  -- title for horizontal orientation
		nil,  -- title for vertical orientation
		{ "BOTTOMLEFT", ctRelativeFrame, "BOTTOM", -512, 18 },
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
		StatusBarTrackingManager
	);
end



module.loadedAddons["Status Bar"] = addon_Register;