local module = select(2,...);

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

function CT_PartyFrame_AnchorSideText()
	for id = 1, 4 do
		CT_PartyFrame_AnchorSideText_Single(id);
	end
end

function CT_PartyFrame_ShowBarText()
	UnitFrameHealthBar_Update(PartyMemberFrame1HealthBar, "party1");
	UnitFrameManaBar_Update(PartyMemberFrame1ManaBar, "party1");

	UnitFrameHealthBar_Update(PartyMemberFrame2HealthBar, "party2");
	UnitFrameManaBar_Update(PartyMemberFrame2ManaBar, "party2");

	UnitFrameHealthBar_Update(PartyMemberFrame3HealthBar, "party3");
	UnitFrameManaBar_Update(PartyMemberFrame3ManaBar, "party3");

	UnitFrameHealthBar_Update(PartyMemberFrame4HealthBar, "party4");
	UnitFrameManaBar_Update(PartyMemberFrame4ManaBar, "party4");
end

function CT_PartyFrame_TextStatusBar_UpdateTextString(bar)

	if (bar == PartyMemberFrame1HealthBar or bar == PartyMemberFrame2HealthBar or bar == PartyMemberFrame3HealthBar or bar == PartyMemberFrame4HealthBar) then
		if (CT_UnitFramesOptions) then
			local textRight;

			if (bar == PartyMemberFrame1HealthBar) then
				textRight = CT_PartyFrame1HealthRight; -- _G["CT_PartyFrame" .. bar:GetParent():GetID() .. "HealthBar"];

			elseif (bar == PartyMemberFrame2HealthBar) then
				textRight = CT_PartyFrame2HealthRight;

			elseif (bar == PartyMemberFrame3HealthBar) then
				textRight = CT_PartyFrame3HealthRight;

			elseif (bar == PartyMemberFrame4HealthBar) then
				textRight = CT_PartyFrame4HealthRight;
			end

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
				textRight:SetFont("Fonts\\FRIZQT__.TTF", barTextString.ctSize + 7);
			end
			
			CT_UnitFrames_TextStatusBar_UpdateTextString(bar, CT_UnitFramesOptions.styles[2][1])
			CT_UnitFrames_HealthBar_OnValueChanged(bar, tonumber(bar:GetValue()), not CT_UnitFramesOptions.oneColorHealth)
			CT_UnitFrames_BesideBar_UpdateTextString(bar, CT_UnitFramesOptions.styles[2][2], textRight)
		end

	elseif (bar == PartyMemberFrame1ManaBar or bar == PartyMemberFrame2ManaBar or bar == PartyMemberFrame3ManaBar or bar == PartyMemberFrame4ManaBar) then
		if (CT_UnitFramesOptions) then
			local textRight;

			if (bar == PartyMemberFrame1ManaBar) then
				textRight = CT_PartyFrame1ManaRight; -- _G["CT_PartyFrame" .. bar:GetParent():GetID() .. "ManaBar"];

			elseif (bar == PartyMemberFrame2ManaBar) then
				textRight = CT_PartyFrame2ManaRight;

			elseif (bar == PartyMemberFrame3ManaBar) then
				textRight = CT_PartyFrame3ManaRight;

			elseif (bar == PartyMemberFrame4ManaBar) then
				textRight = CT_PartyFrame4ManaRight;
			end
			
			
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
				textRight:SetFont("Fonts\\FRIZQT__.TTF", barTextString.ctSize + 7);
			end

			CT_UnitFrames_TextStatusBar_UpdateTextString(bar, CT_UnitFramesOptions.styles[2][3])
			CT_UnitFrames_BesideBar_UpdateTextString(bar, CT_UnitFramesOptions.styles[2][4], textRight)
		end
	end
end

hooksecurefunc("TextStatusBar_UpdateTextString", CT_PartyFrame_TextStatusBar_UpdateTextString);
hooksecurefunc("ShowTextStatusBarText", CT_PartyFrame_TextStatusBar_UpdateTextString);
hooksecurefunc("HideTextStatusBarText", CT_PartyFrame_TextStatusBar_UpdateTextString);

hooksecurefunc("PartyMemberFrame_UpdateNotPresentIcon",
	function(self)
		local id = self:GetID() or 1;
		CT_PartyFrame_AnchorSideText_Single(id);
	end
);

function CT_PartyFrame_UpdateClassColor()
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

module:regEvent("GROUP_ROSTER_UPDATE", CT_PartyFrame_UpdateClassColor);