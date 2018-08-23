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
-- Some lines of code borrowed from MoveTalkingHead addon by Ketho (EU-Boulderfist) 


--------------------------------------------
-- Initialization

local _G = getfenv(0);
local module = _G.CT_BottomBar;

local ctRelativeFrame = module.ctRelativeFrame;
local appliedOptions;

local CT_BB_TalkingHead_IsEnabled = nil;

--------------------------------------------
-- Action bar arrows and page number

local function addon_Update(self)
	-- Update the frame
	-- self == talking head object

	self.helperFrame:ClearAllPoints();
	self.helperFrame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", -5, 5);
	self.helperFrame:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", 5, -5);
end

local function addon_Enable(self)
	CT_BB_TalkingHead_IsEnabled = true;
	TalkingHeadFrame:ClearAllPoints();
	TalkingHeadFrame:SetPoint("BOTTOM",self.frame,"BOTTOM", 0,0);
end

local function addon_Disable(self)
	CT_BB_TalkingHead_IsEnabled = false;
	TalkingHeadFrame:ClearAllPoints();
	TalkingHeadFrame:SetPoint("BOTTOM","UIParent","BOTTOM", 0, 96);
end

local function addon_Init(self)
	-- Initialization
	-- self == actionbar arrows bar object

	appliedOptions = module.appliedOptions;

	module.ctActionBarPage = self;

	local frame = CreateFrame("Frame", "CT_BottomBar_" .. self.frameName .. "_GuideFrame");
	self.helperFrame = frame;
	
	if (not TalkingHeadFrame) then TalkingHead_LoadUI(); end
	
	self.frame:SetHeight(155);
	self.frame:SetWidth(570);
	
	for i, alertSubSystem in pairs(AlertFrame.alertFrameSubSystems) do
		if alertSubSystem.anchorFrame == TalkingHeadFrame then
			tremove(AlertFrame.alertFrameSubSystems, i);
		end
	end
	
	TalkingHeadFrame.ignoreFramePositionManager = true;
	--TalkingHeadFrame:SetParent(self.frame);
	
	--local timeelapsed = 0;
	hooksecurefunc("TalkingHeadFrame_PlayCurrent", function()
	--[[TalkingHeadFrame:HookScript("OnUpdate", function(thframe, elapsed)
	 	timeelapsed = timeelapsed + elapsed;
	 	if timeelapsed > 0.1 then
	 		DEFAULT_CHAT_FRAME:AddMessage("test");
	 		timeelapsed = 0;
	 	end--]]
	 	if (CT_BB_TalkingHead_IsEnabled) then
			TalkingHeadFrame:ClearAllPoints();
			TalkingHeadFrame:SetPoint("BOTTOM",self.frame,"BOTTOM", 0,0);
		else
			TalkingHeadFrame:ClearAllPoints();
			TalkingHeadFrame:SetPoint("BOTTOM","UIParent","BOTTOM", 0, 96);
		end	
	end);
	
	
	

	return true;
end

local function addon_Register()
	module:registerAddon(
		"Talking Head",  -- option name
		"CTTalkingHead",  -- used in frame names
		"Talking Head",  -- shown in options window & tooltips
		"Talking Head (quest dialogue)",  -- title for horizontal orientation
		nil,  -- title for vertical orientation
		{ "BOTTOM", ctRelativeFrame, "BOTTOM", 0, 96 },
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
		TalkingHeadFrame
	);
end

module.loadedAddons["Talking Head"] = addon_Register;
