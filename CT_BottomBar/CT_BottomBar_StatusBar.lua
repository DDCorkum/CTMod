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

--------------------------------------------
-- Status Tracking Bar Manager

local function addon_Update(self)
	-- Update the frame
	-- self == status tracking bar manager object

	self.helperFrame:ClearAllPoints();
	self.helperFrame:SetPoint("TOPLEFT", StatusTrackingBarManager, "TOPLEFT", -5, 5);
	self.helperFrame:SetPoint("BOTTOMRIGHT", StatusTrackingBarManager, "BOTTOMRIGHT", 5, -5);

	--StatusTrackingBarManager:SetParent(self.frame);
	StatusTrackingBarManager:ClearAllPoints();
	StatusTrackingBarManager:SetPoint("TOPLEFT", self.frame, 0, 0);

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

	self.frame:SetFrameLevel(MainMenuBarArtFrame:GetFrameLevel() + 1);
	self.frame:SetWidth(StatusTrackingBarManager:GetWidth());
	--self.frame:SetHeight(StatusTrackingBarManager:GetHeight());

	local helperframe = CreateFrame("Frame", "CT_BottomBar_" .. self.frameName .. "_GuideFrame");
	self.helperFrame = helperframe;
	CT_BottomBar_StatusBar_DefaultParent = StatusTrackingBarManager:GetParent();
	
	self.frame.OnStatusBarsUpdated = CT_BottomBar_StatusBar_OnStatusBarsUpdated;
	
	--StatusTrackingBarManager:SetParent(self.frame);  --better to call this during addon_Enable
	
	return true;
end

function CT_BottomBar_StatusBar_OnStatusBarsUpdated(self)
	--CT_BottomBar_StatusBar_DefaultParent.OnStatusBarsUpdated(self)
end


local function addon_Register()
	module:registerAddon(
		"Status Bar",  -- option name
		"StatusBar",  -- used in frame names
		"Status Bar",  -- shown in options window & tooltips
		"Status Bar",  -- title for horizontal orientation
		nil,  -- title for vertical orientation
		{ "BOTTOMLEFT", ctRelativeFrame, "BOTTOM", -400, 140 },
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
		StatusBarTrackingManager
	);
end



module.loadedAddons["Status Bar"] = addon_Register;