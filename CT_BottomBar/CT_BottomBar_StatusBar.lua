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

local CT_BottomBar_StatusBar_Frame = nil;
local CT_BottomBar_StatusBar_HelperFrame = nil;
local CT_BottomBar_StatusBar_CustomManager = nil;

--------------------------------------------
-- Status Tracking Bar Manager

local function addon_Update(self)
	-- Update the frame
	-- self == status tracking bar manager object

	CT_BottomBar_StatusBar_Frame:SetWidth(appliedOptions.customStatusBarWidth or 1024);
		
	CT_BottomBar_StatusBar_CustomManager:ClearAllPoints();
	CT_BottomBar_StatusBar_CustomManager:SetPoint("TOPLEFT", self.frame, 0, 0);
	CT_BottomBar_StatusBar_CustomManager:UpdateBarsShown();
	
	CT_BottomBar_StatusBar_HelperFrame:ClearAllPoints();
	CT_BottomBar_StatusBar_HelperFrame:SetPoint("TOPLEFT", CT_BottomBar_StatusBar_Frame, "TOPLEFT", -5, 5);
	CT_BottomBar_StatusBar_HelperFrame:SetPoint("BOTTOMRIGHT", CT_BottomBar_StatusBar_Frame, "BOTTOMRIGHT", 5, -5);



end


local function addon_Enable(self)
	StatusTrackingBarManager:Hide();
	CT_BottomBar_StatusBar_CustomManager:Show();
end

local function addon_Disable(self)
	StatusTrackingBarManager:Show();
	CT_BottomBar_StatusBar_CustomManager:Hide();
end

local function addon_Init(self)
	-- Initialization
	-- self == status tracking bar manager object

	appliedOptions = module.appliedOptions;
	module.ctStatusBar = self;
	module.CT_BottomBar_StatusBar_SetWidth = addon_Update;

	CT_BottomBar_StatusBar_Frame = self.frame;
	CT_BottomBar_StatusBar_Frame:SetFrameLevel(MainMenuBarArtFrame:GetFrameLevel() + 1);
	CT_BottomBar_StatusBar_Frame.OnStatusBarsUpdated = CT_BottomBar_StatusBar_OnStatusBarsUpdated;
	
	CT_BottomBar_StatusBar_HelperFrame = CreateFrame("Frame", "CT_BottomBar_" .. self.frameName .. "_GuideFrame");
	self.helperFrame = CT_BottomBar_StatusBar_HelperFrame;
	
	
	CT_BottomBar_StatusBar_CustomManager = CreateFrame("FRAME", "CT_StatusTrackingBarManager", CT_BottomBar_StatusBar_Frame, "StatusTrackingBarManagerTemplate");
	CT_BottomBar_StatusBar_CustomManager:AddBarFromTemplate("FRAME", "ReputationStatusBarTemplate");
	CT_BottomBar_StatusBar_CustomManager:AddBarFromTemplate("FRAME", "HonorStatusBarTemplate");
	CT_BottomBar_StatusBar_CustomManager:AddBarFromTemplate("FRAME", "ArtifactStatusBarTemplate");
	CT_BottomBar_StatusBar_CustomManager:AddBarFromTemplate("FRAME", "ExpStatusBarTemplate");
        CT_BottomBar_StatusBar_CustomManager:AddBarFromTemplate("FRAME", "AzeriteBarTemplate"); 
	CT_BottomBar_StatusBar_CustomManager.UpdateBarsShown = CT_BottomBar_StatusBar_UpdateBarsShown;

	addon_Update(self);
	return true;
end

local function addon_PostInit(self)
	if (module:getOption("enableStatus Bar") == false) then addon_Disable(self); end
	CT_BottomBar_StatusBar_UpdateBarsShown(self)	
end


function CT_BottomBar_StatusBar_UpdateBarsShown(self)
 	local visibleBars = {};
 	if ( CT_BottomBar_StatusBar_CustomManager.bars[1].ShouldBeVisible() and not module:getOption("customStatusBarHideReputation")) then	table.insert(visibleBars, CT_BottomBar_StatusBar_CustomManager.bars[1]); end
  	if ( CT_BottomBar_StatusBar_CustomManager.bars[2].ShouldBeVisible() and not module:getOption("customStatusBarHideHonor")) then table.insert(visibleBars, CT_BottomBar_StatusBar_CustomManager.bars[2]); end
  	if ( CT_BottomBar_StatusBar_CustomManager.bars[3].ShouldBeVisible() and not module:getOption("customStatusBarHideArtifact")) then table.insert(visibleBars, CT_BottomBar_StatusBar_CustomManager.bars[3]); end
  	if ( CT_BottomBar_StatusBar_CustomManager.bars[4].ShouldBeVisible() and not module:getOption("customStatusBarHideExp")) then	table.insert(visibleBars, CT_BottomBar_StatusBar_CustomManager.bars[4]); end
  	if ( CT_BottomBar_StatusBar_CustomManager.bars[5].ShouldBeVisible() and not module:getOption("customStatusBarHideAzerite")) then table.insert(visibleBars, CT_BottomBar_StatusBar_CustomManager.bars[5]); end
   	table.sort(visibleBars, function(left, right) return left:GetPriority() < right:GetPriority() end);
	CT_BottomBar_StatusBar_CustomManager:LayoutBars(visibleBars); 	
end

function CT_BottomBar_StatusBar_OnStatusBarsUpdated(self)
	--This is supposed to be lots of shifting, but meh
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
		addon_PostInit,  -- no post init function
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