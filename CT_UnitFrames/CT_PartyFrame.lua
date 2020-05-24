------------------------------------------------
--               CT_UnitFrames                --
--                                            --
-- Heavily customizable mod that allows you   --
-- to modify the Blizzard unit frames into    --
-- your personal style and liking.            --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
------------------------------------------------

local module = select(2, ...);

local _G = _G
local tonumber = tonumber

function CT_PartyFrameSlider_OnLoad(self)
	_G[self:GetName().."Text"]:SetText(CT_UFO_PARTYTEXTSIZE);
	_G[self:GetName().."High"]:SetText(CT_UFO_PARTYTEXTSIZE_LARGE);
	_G[self:GetName().."Low"]:SetText(CT_UFO_PARTYTEXTSIZE_SMALL);
	self:SetMinMaxValues(1, 5);
	self:SetValueStep(0.5);
	self:SetObeyStepOnDrag(true)
	self.tooltipText = "Allows you to change the text size of the party health & mana texts.";
end

local function CT_PartyFrame_AnchorSideText_Single(id)
	local textRight;
	local notPresentIcon = _G["PartyMemberFrame" .. id .. "NotPresentIcon"];
	local ctPartyFrame = _G["CT_PartyFrame" .. id];
	for i = 1, 2 do
		if (i == 1) then
			textRight = _G["CT_PartyFrame" .. id .. "HealthRight"];
		else
			textRight = _G["CT_PartyFrame" .. id .. "ManaRight"];
		end

		local ancP, relTo, relP, xoff, yoff = textRight:GetPoint(1);
		xoff = -6 + (CT_UnitFramesOptions.partyTextSpacing or 9);
		if (notPresentIcon:IsVisible()) then
			xoff = xoff + 28;
		end

		-- <Anchor point="LEFT" relativePoint="RIGHT">
		textRight:ClearAllPoints();
		textRight:SetPoint(ancP, relTo, relP, xoff, yoff);
	end
end

local function CT_PartyFrame_TextStatusBar_UpdateTextString(bar)
	if (CT_UnitFrameOptions) then

		-- compatibility with WoW Classic
		local barTextString = bar.TextString or bar.ctTextString;
		if (not barTextString) then
			local intermediateFrame = CreateFrame("Frame", nil, bar);
			intermediateFrame:SetFrameLevel(5);
			intermediateFrame:SetAllPoints();
			barTextString = intermediateFrame:CreateFontString(nil, "ARTWORK", "GameTooltipTextSmall");
			barTextString:SetPoint("CENTER", bar);
			barTextString.ctControlled = "Party";
			bar.ctTextString = barTextString;
		end

		-- font
		if (barTextString.ctSize ~= (CT_UnitFramesOptions.partyTextSize or 3)) then
			barTextString.ctSize = CT_UnitFramesOptions.partyTextSize or 3
			barTextString:SetFont("Fonts\\FRIZQT__.TTF", barTextString.ctSize + 7, "OUTLINE");
			bar.textRight:SetFont("Fonts\\FRIZQT__.TTF", barTextString.ctSize + 7);
		end
		
		-- apply changes for the health and mana bars
		if (bar.type == "health") then	
			module:UpdateStatusBarTextString(bar, CT_UnitFramesOptions.styles[2][1])
			CT_UnitFrames_HealthBar_OnValueChanged(bar, tonumber(bar:GetValue()), not CT_UnitFramesOptions.oneColorHealth)
			module:UpdateBesideBarTextString(bar, CT_UnitFramesOptions.styles[2][2], bar.textRight)
		else -- if bar.type == "mana"
			module:UpdateStatusBarTextString(bar, CT_UnitFramesOptions.styles[2][3])
			module:UpdateBesideBarTextString(bar, CT_UnitFramesOptions.styles[2][4], bar.textRight)			
		end
	end
end

module:regEvent("PLAYER_LOGIN", function()
	local bars = {PartyMemberFrame1HealthBar, PartyMemberFrame1ManaBar, PartyMemberFrame2HealthBar, PartyMemberFrame2ManaBar, PartyMemberFrame3HealthBar, PartyMemberFrame3ManaBar, PartyMemberFrame4HealthBar, PartyMemberFrame4ManaBar};
	local textRight = {CT_PartyFrame1HealthRight, CT_PartyFrame1ManaRight, CT_PartyFrame2HealthRight, CT_PartyFrame2ManaRight, CT_PartyFrame3HealthRight, CT_PartyFrame3ManaRight, CT_PartyFrame4HealthRight, CT_PartyFrame4ManaRight};
	for i=1, 8 do
		bars[i]:HookScript("OnEnter", CT_PartyFrame_TextStatusBar_UpdateTextString);
		bars[i]:HookScript("OnLeave", CT_PartyFrame_TextStatusBar_UpdateTextString);
		bars[i]:HookScript("OnValueChanged", CT_PartyFrame_TextStatusBar_UpdateTextString);
		bars[i].textRight = textRight[i];
		bars[i].type = i%2 == 1 and "health" or "mana";
	end
end);

--[[	-- replaced by hooks onto each specific frame during PLAYER_LOGIN
	hooksecurefunc("TextStatusBar_UpdateTextString", CT_PartyFrame_TextStatusBar_UpdateTextString);
	hooksecurefunc("ShowTextStatusBarText", CT_PartyFrame_TextStatusBar_UpdateTextString);
	hooksecurefunc("HideTextStatusBarText", CT_PartyFrame_TextStatusBar_UpdateTextString);
--]]

hooksecurefunc("PartyMemberFrame_UpdateNotPresentIcon",
	function(self)
		local id = self:GetID() or 1;
		CT_PartyFrame_AnchorSideText_Single(id);
	end
);


function module:AnchorPartyFrameSideText()
	for id = 1, 4 do
		CT_PartyFrame_AnchorSideText_Single(id);
	end
end

function module:ShowPartyFrameBarText()
	UnitFrameHealthBar_Update(PartyMemberFrame1HealthBar, "party1");
	UnitFrameManaBar_Update(PartyMemberFrame1ManaBar, "party1");
	CT_PartyFrame_TextStatusBar_UpdateTextString(PartyMemberFrame1HealthBar);
	CT_PartyFrame_TextStatusBar_UpdateTextString(PartyMemberFrame1ManaBar);

	UnitFrameHealthBar_Update(PartyMemberFrame2HealthBar, "party2");
	UnitFrameManaBar_Update(PartyMemberFrame2ManaBar, "party2");
	CT_PartyFrame_TextStatusBar_UpdateTextString(PartyMemberFrame2HealthBar);
	CT_PartyFrame_TextStatusBar_UpdateTextString(PartyMemberFrame2ManaBar);
	
	UnitFrameHealthBar_Update(PartyMemberFrame3HealthBar, "party3");
	UnitFrameManaBar_Update(PartyMemberFrame3ManaBar, "party3");
	CT_PartyFrame_TextStatusBar_UpdateTextString(PartyMemberFrame3HealthBar);
	CT_PartyFrame_TextStatusBar_UpdateTextString(PartyMemberFrame3ManaBar);

	UnitFrameHealthBar_Update(PartyMemberFrame4HealthBar, "party4");
	UnitFrameManaBar_Update(PartyMemberFrame4ManaBar, "party4");
	CT_PartyFrame_TextStatusBar_UpdateTextString(PartyMemberFrame4HealthBar);
	CT_PartyFrame_TextStatusBar_UpdateTextString(PartyMemberFrame4ManaBar);
end


local function UpdatePartyFrameClassColors()
	local GetClassColor = GetClassColor or C_ClassColor.GetClassColor
	for i=1, 4 do
		if (CT_UnitFramesOptions.partyClassColor and UnitExists("party" .. i)) then
			local r, g, b = GetClassColor(select(2,UnitClass("party" .. i)));
			_G["PartyMemberFrame" .. i .. "Name"]:SetTextColor(r or 1, g or 0.82, b or 0);
		else
			_G["PartyMemberFrame" .. i .. "Name"]:SetTextColor(1,0.82,0);
		end
		
	end
end

module.UpdatePartyFrameClassColors = UpdatePartyFrameClassColors;
module:regEvent("GROUP_ROSTER_UPDATE", UpdatePartyFrameClassColors);
module:regEvent("PLAYER_LOGIN", UpdatePartyFrameClassColors);