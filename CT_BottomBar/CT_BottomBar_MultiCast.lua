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
-- MultiCast Bar (Totem bar)


-- knownMultiCastSummonSpells
-- index: TOTEM_MULTI_CAST_SUMMON_SPELLS 
-- value: spellId if the spell is known, nil otherwise
local knownMultiCastSummonSpells = { };

-- knownMultiCastRecallSpells
-- index: TOTEM_MULTI_CAST_RECALL_SPELLS 
-- value: spellId if the spell is known, nil otherwise
local knownMultiCastRecallSpells = { };


local function addon_MultiCastSummonSpellButton_Update(self)
	-- self == MultiCastSummonSpellButton

	local parent = module.ctMultiCast.frame;

	-- first update which multi-cast spells we actually know
	for index, spellId in next, TOTEM_MULTI_CAST_SUMMON_SPELLS do
		knownMultiCastSummonSpells[index] = (IsSpellKnown(spellId) and spellId) or nil;
	end

	-- update the spell button
	local spellId = knownMultiCastSummonSpells[self:GetID()];
--	self.spellId = spellId;
	if ( HasMultiCastActionBar() and spellId ) then
		-- reanchor the first slot button take make room for this button
		local width = self:GetWidth();
		local xOffset = width + 8 + 3;
		local page;
		for i = 1, NUM_MULTI_CAST_PAGES do
			page = _G["MultiCastActionPage"..i];
			page:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", xOffset, 3);
		end
		MultiCastSlotButton1:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", xOffset, 3);

		MultiCastSummonSpellButton:Show();
	else
		-- reanchor the first slot button take the place of this button
		local xOffset = 3;
		local page;
		for i = 1, NUM_MULTI_CAST_PAGES do
			page = _G["MultiCastActionPage"..i];
			page:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", xOffset, 3);
		end
		MultiCastSlotButton1:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", xOffset, 3);

		MultiCastSummonSpellButton:Hide();
	end

	MultiCastSlotButton1:SetPoint("CENTER", parent, "CENTER", 0, 0);
	MultiCastSlotButton2:SetPoint("CENTER", parent, "CENTER", 0, 0);
	MultiCastSlotButton3:SetPoint("CENTER", parent, "CENTER", 0, 0);
	MultiCastSlotButton4:SetPoint("CENTER", parent, "CENTER", 0, 0);

	MultiCastSummonSpellButton:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 3, 3);
end

local function addon_MultiCastRecallSpellButton_Update(self)
	-- self == MultiCastRecallSpellButton

	-- first update which multi-cast spells we actually know
	for index, spellId in next, TOTEM_MULTI_CAST_RECALL_SPELLS do
		knownMultiCastRecallSpells[index] = (IsSpellKnown(spellId) and spellId) or nil;
	end

	-- update the spell button
	local spellId = knownMultiCastRecallSpells[self:GetID()];
--	self.spellId = spellId;
	if ( HasMultiCastActionBar() and spellId ) then
		-- anchor to the last shown slot
		local activeSlots = MultiCastActionBarFrame.numActiveSlots;
		if ( activeSlots > 0 ) then
			self:SetPoint("LEFT", _G["MultiCastSlotButton"..activeSlots], "RIGHT", 8, 0);
			self:SetPoint("BOTTOMLEFT", module.ctMultiCast.frame, "BOTTOMLEFT", 36, 3);
		end

		MultiCastRecallSpellButton:Show();
	else
		self:SetPoint("LEFT", MultiCastSummonSpellButton, "RIGHT", 8, 0);
		self:SetPoint("BOTTOMLEFT", module.ctMultiCast.frame, "BOTTOMLEFT", 36, 3);

		MultiCastRecallSpellButton:Hide();
	end
end

local function addon_UpdateOrientation(self)
	-- Update the frame
	-- self == multi cast object

	if (InCombatLockdown()) then
		return;
	end

	addon_MultiCastSummonSpellButton_Update( MultiCastSummonSpellButton );
	addon_MultiCastRecallSpellButton_Update( MultiCastRecallSpellButton );
end

local function addon_Update(self)
	-- Update the frame
	-- self == multi cast object

	if (not InCombatLockdown()) then
		MultiCastActionBarFrame:EnableMouse(0);

		local obj1 = MultiCastSummonSpellButton;
		local obj2 = MultiCastRecallSpellButton;

		self.helperFrame:ClearAllPoints();
		self.helperFrame:SetPoint("TOPLEFT", obj1);
--		self.helperFrame:SetPoint("BOTTOMRIGHT", obj2);
		self.helperFrame:SetWidth(230);
		self.helperFrame:SetHeight(30);

		addon_UpdateOrientation(self);
	end
end

local function addon_Hooked_MultiCastActionBarFrame_Update(self)
	-- (hooksecurefunc of MultiCastActionBarFrame_Update in MultiCastActionBarFrame.lua)
	-- self == MultiCastActionBarFrame

	if (module.ctMultiCast.isDisabled) then
		return;
	end

	addon_Update(module.ctMultiCast);
end

local function addon_Disable(self)

	if (CT_BarMod and CT_BarMod.CT_BarMod_Shift_MultiCast_UpdatePositions) then
		CT_BarMod.CT_BarMod_Shift_MultiCast_UpdatePositions();
	end

	-- Call Blizzard's function which may adjust the position
	-- of the bar.
	UIParent_ManageFramePositions();
end

local function addon_Init(self)
	-- Initialization
	-- self == multi cast object

	appliedOptions = module.appliedOptions;

	module.ctMultiCast = self;

	local frame = CreateFrame("Frame", "CT_BottomBar_" .. self.frameName .. "_GuideFrame");
	self.helperFrame = frame;

	hooksecurefunc("MultiCastActionBarFrame_Update", addon_Hooked_MultiCastActionBarFrame_Update);

	return true;
end

local function addon_Register()
	module:registerAddon(
		"MultiCastBar",  -- option name
		"MultiCastBar",  -- used in frame names
		"MultiCast Bar",  -- shown in options window & tooltips
		"MultiCast Bar",  -- title for horizontal orientation
		"MCast",  -- title for vertical orientation
		{ "BOTTOMLEFT", ctRelativeFrame, "BOTTOM", -486, 149 },
		{ -- settings
			orientation = "ACROSS",
			-- These classes have this bar and therefore will have this bar enabled by default.
			["perClass"] = {
				["SHAMAN"] = true,
			},
		},
		addon_Init,
		nil,  -- no post init function
		nil,  -- no config function
		addon_Update,
		nil,  -- not assigning the orientation function (not for use with this bar)
		nil,  -- no enable func
		addon_Disable,
		"helperFrame",
		MultiCastActionPage1,
		MultiCastActionPage2,
		MultiCastActionPage3,
		MultiCastSlotButton1,
		MultiCastSlotButton2,
		MultiCastSlotButton3,
		MultiCastSlotButton4,
		MultiCastSummonSpellButton,
		MultiCastRecallSpellButton,
		MultiCastFlyoutFrame
	);
end

--module.loadedAddons["MultiCastBar"] = addon_Register;
