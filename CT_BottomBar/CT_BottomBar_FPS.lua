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
	-- self == framerate container

	self.helperFrame:ClearAllPoints();
	self.helperFrame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", -5, 5);
	self.helperFrame:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", 5, -5);
	
end

local function addon_Enable(self)
	if (FramerateLabel:IsShown()) then
		FramerateLabel:Hide();
		FramerateText:Hide();
		self.fontstring:Show();
	end
	ToggleFramerate = function(benchmark)
		FramerateText.benchmark = benchmark;
		if self.fontstring:IsShown() then
			self.fontstring:Hide();
		else
			self.fontstring:Show();
		end
		WorldFrame.fpsTime = 0;
	end
	
end

local function addon_Disable(self)
	if (self.fontstring:IsShown()) then
		FramerateLabel:Show();
		FramerateText:Show();
		self.fontstring:Hide();
	end	
	-- the original code from WorldFrame.lua
	ToggleFramerate = function(benchmark)
		FramerateText.benchmark = benchmark;
		if ( FramerateText:IsShown() ) then
			FramerateLabel:Hide();
			FramerateText:Hide();
		else
			FramerateLabel:Show();
			FramerateText:Show();
		end
		WorldFrame.fpsTime = 0;
	end;
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
	
	self.fontstring = self.frame:CreateFontString(nil, "ARTWORK", "ChatFontNormal");
	self.fontstring:SetPoint("CENTER");
	self.fontstring:Hide();
	
	local timeElapsed = 0;
	self.frame:SetScript("OnUpdate",
		function(__, elapsed)
			timeElapsed = timeElapsed + elapsed;
			if (timeElapsed < 0.25) then return; end
			timeElapsed = 0;
			self.fontstring:SetText("FPS: " .. floor(GetFramerate()*10)/10);
			if (self.fontstring:GetText():sub(-2,-2) ~= ".") then
				self.fontstring:SetText(self.fontstring:GetText() .. ".0");
			end
		end
	);
		
	return true;
end

local function addon_Register()
	module:registerAddon(
		"Framerate Bar",  -- option name
		"Frameratebar",  -- used in frame names
		module.text["CT_BottomBar/Options/FPSBar"],  -- shown in options window & tooltips
		module.text["CT_BottomBar/Options/FPSBar"],  -- title for horizontal orientation
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
		addon_Disable,  -- no disable function
		"helperFrame",
		FramerateLabel,
		FramerateText
	);
end

module.loadedAddons["Framerate Bar"] = addon_Register;
