function CT_PlayerFrame_AnchorSideText()
	local fsTable = { "CT_PlayerHealthRight", "CT_PlayerManaRight" };
	for i, name in ipairs(fsTable) do
		local frame = _G[name];

--		<Anchor point="LEFT" relativeTo="PlayerFrame" relativePoint="TOPRIGHT">
--		<AbsDimension x="-3.4" y="-46"/>
		local xoff = (CT_UnitFramesOptions.playerTextSpacing or 0);
		local yoff = -(46 + (i-1)*11);
		local onRight = not CT_UnitFramesOptions.playerTextLeft;
		frame:ClearAllPoints();
		if (onRight) then
			frame:SetPoint("LEFT", PlayerFrame, "TOPRIGHT", (-3.4 + xoff), yoff);
		else
			frame:SetPoint("RIGHT", PlayerFrame, "TOPLEFT",  -(xoff), yoff);
		end

	end
end

function CT_PlayerFrame_ShowBarText()
	UnitFrameHealthBar_Update(PlayerFrameHealthBar, "player");
	UnitFrameManaBar_Update(PlayerFrameManaBar, "player");
end

function CT_PlayerFrame_TextStatusBar_UpdateTextString(bar)

	if (bar == PlayerFrameHealthBar) then
		if (CT_UnitFramesOptions) then
			CT_UnitFrames_TextStatusBar_UpdateTextString(bar, CT_UnitFramesOptions.styles[1][1])
			CT_UnitFrames_HealthBar_OnValueChanged(bar, tonumber(bar:GetValue()), not CT_UnitFramesOptions.oneColorHealth)
			CT_UnitFrames_BesideBar_UpdateTextString(bar, CT_UnitFramesOptions.styles[1][2], CT_PlayerHealthRight)
		end

	elseif (bar == PlayerFrameManaBar) then
		if (CT_UnitFramesOptions) then
			CT_UnitFrames_TextStatusBar_UpdateTextString(bar, CT_UnitFramesOptions.styles[1][3])
			CT_UnitFrames_BesideBar_UpdateTextString(bar, CT_UnitFramesOptions.styles[1][4], CT_PlayerManaRight)
		end
	end
end
hooksecurefunc("TextStatusBar_UpdateTextString", CT_PlayerFrame_TextStatusBar_UpdateTextString);

function CT_PlayerFrame_ShowTextStatusBarText(bar)
	if (bar == PlayerFrameHealthBar or bar == PlayerFrameManaBar) then
		CT_PlayerFrame_TextStatusBar_UpdateTextString(bar);
	end
end
hooksecurefunc("ShowTextStatusBarText", CT_PlayerFrame_ShowTextStatusBarText);

function CT_PlayerFrame_HideTextStatusBarText(bar)
	if (bar == PlayerFrameHealthBar or bar == PlayerFrameManaBar) then
		CT_PlayerFrame_TextStatusBar_UpdateTextString(bar);
	end
end
hooksecurefunc("HideTextStatusBarText", CT_PlayerFrame_HideTextStatusBarText);

function CT_PetFrame_TextStatusBar_UpdateTextString(bar)

	if (bar == PetFrameHealthBar) then
		if (CT_UnitFramesOptions) then
			CT_UnitFrames_HealthBar_OnValueChanged(bar, tonumber(bar:GetValue()), not CT_UnitFramesOptions.oneColorHealth)
		end
	end
end
hooksecurefunc("TextStatusBar_UpdateTextString", CT_PetFrame_TextStatusBar_UpdateTextString);

