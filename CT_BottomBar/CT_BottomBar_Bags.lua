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
-- Bags Bar

local function addon_UpdateOrientation(self, orientation)
	-- Anchor the frames according to the specified orientation
	-- self == bags bar object
	-- orientation == "ACROSS" or "DOWN"

	local frames = self.frames;
	local obj;
	local spacing;

	orientation = orientation or "ACROSS";
	if (module:getGameVersion() == CT_GAME_VERSION_RETAIL) then
		spacing = spacing or appliedOptions.bagsBarSpacing or 2;
	elseif (module:getGameVersion() == CT_GAME_VERSION_CLASSIC) then
		spacing = spacing or appliedOptions.bagsBarSpacing or 4;
	end

	for i = 2, #frames do
		obj = frames[i];
		obj:ClearAllPoints();
		obj:SetParent(self.frame);
	end
	if (appliedOptions.bagsBarHideBags) then
		local backpack = frames[#frames];
		for i = 2, #frames - 1 do
			obj = frames[i];
			obj:SetPoint("CENTER", backpack);
			obj:Hide();
		end
		backpack:SetPoint("BOTTOMLEFT", self.frame, 0, 0);
		backpack:Show();
	else
		for i = 2, #frames do
			obj = frames[i];
			if (i == 2) then
				-- Left most bag (CharacterBag3Slot)
				obj:SetPoint("BOTTOMLEFT", self.frame, 0, 0);
			else
				if ( orientation == "ACROSS" ) then
					obj:SetPoint("LEFT", frames[i-1], "RIGHT", spacing, 0);
				else
					obj:SetPoint("TOP", frames[i-1], "BOTTOM", 0, -spacing);
				end
			end
			obj:Show();
		end
	end
end

local function addon_Update(self)
	-- Update the frame
	-- self == bags bar object

	-- Anchor the guide frame
	local obj1;
	local obj2;
	if (appliedOptions.bagsBarHideBags) then
		obj1 = MainMenuBarBackpackButton;  -- Left most bag
		obj2 = MainMenuBarBackpackButton;  -- Right most bag
	else
		obj1 = CharacterBag3Slot;  -- Left most bag
		obj2 = MainMenuBarBackpackButton;  -- Right most bag
	end

	self.helperFrame:ClearAllPoints();
	self.helperFrame:SetPoint("TOPLEFT", obj1, 0, 0);
	self.helperFrame:SetPoint("BOTTOMRIGHT", obj2);

	-- Anchor the objects.
	addon_UpdateOrientation(self, self.orientation);
end

local function addon_Init(self)
	-- Initialization
	-- self == bags bar object

	appliedOptions = module.appliedOptions;

	module.ctBagsBar = self;

	self.frame:SetFrameLevel(MainMenuBarArtFrame:GetFrameLevel() + 1);

	local frame = CreateFrame("Frame", "CT_BottomBar_" .. self.frameName .. "_GuideFrame");
	self.helperFrame = frame;

	return true;
end

local function addon_Register()
	local x, y;
	if (module:getGameVersion() == CT_GAME_VERSION_RETAIL) then
		x = 345;
		y = 28;
	elseif (module:getGameVersion() == CT_GAME_VERSION_CLASSIC) then
		x = 300;
		y = 2;
	end		
	module:registerAddon(
		"Bags Bar",  -- option name
		"BagsBar",  -- used in frame names
		module.text["CT_BottomBar/Options/BagsBar"],  -- shown in options window & tooltips
		module.text["CT_BottomBar/Options/BagsBar"],  -- title for horizontal orientation
		"Bags",  -- title for vertical orientation
		{ "BOTTOMLEFT", ctRelativeFrame, "BOTTOM", x, y },  --default position
		{ -- settings
			orientation = "ACROSS",
			saveShown = true, -- save/load the shown state of frames
		},
		addon_Init,
		nil,  -- no post init function
		nil,  -- no config function
		addon_Update,
		addon_UpdateOrientation,
		nil,  -- no enable func
		nil,  -- no disable func
		"helperFrame",
		CharacterBag3Slot,
		CharacterBag2Slot,
		CharacterBag1Slot,
		CharacterBag0Slot,
		MainMenuBarBackpackButton
	);
end

module.loadedAddons["Bags Bar"] = addon_Register;
