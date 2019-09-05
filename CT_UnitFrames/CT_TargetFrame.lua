local inworld;
function CT_TargetFrameOnEvent(self, event, arg1, ...)

	if ( event == "PLAYER_ENTERING_WORLD" ) then
		if (inworld == nil) then
			inworld = 1;
			if (_G["CT_Library"]:getGameVersion() == CT_GAME_VERSION_RETAIL) then
				hooksecurefunc("UnitFrame_UpdateThreatIndicator", CT_TargetFrame_UpdateThreatIndicator);
			end
			CT_TargetFrame_SetClassPosition(true);

			TargetFrameHealthBar:SetScript("OnLeave", function() GameTooltip:Hide(); end);
			TargetFrameManaBar:SetScript("OnLeave", function() GameTooltip:Hide(); end);

			if ( GetCVarBool("predictedPower") ) then
				local statusbar = TargetFrameManaBar;
				statusbar:SetScript("OnUpdate", UnitFrameManaBar_OnUpdate);
				UnitFrameManaBar_UnregisterDefaultEvents(statusbar);
			end
		end
	end
end

local function CT_TargetFrame_ResetUserPlacedPosition()
	if (not InCombatLockdown()) then
		-- Reposition 15 to the right of where Blizzard puts it (250) to allow
		-- enough room between the player and target frames so that
		-- both can show "100%" beside their health/mana bars if needed.
                -- See also: CT_PlayerFrame.xml
		TargetFrame:ClearAllPoints();
		TargetFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 265, -4);
	end
end
hooksecurefunc("TargetFrame_ResetUserPlacedPosition", CT_TargetFrame_ResetUserPlacedPosition);


-- Adapting code by github user shoestare, this function now performs two tasks:
--   STEP 1 (original): Displays the unit class or creature type in the target class frame
--   STEP 2 (new in 8.2.0.8): Changes the color of the target class frame to indicate friend, hostile, pvp, etc.
function CT_SetTargetClass()
	-- STEP 1:
	if ( not CT_UnitFramesOptions.displayTargetClass ) then
		return;
	end
	if ( not UnitExists("target") or not UnitExists("player") ) then
		CT_TargetFrameClassFrameText:SetText("");
		return;
	end
	if ( UnitIsPlayer("target") ) then
		CT_TargetFrameClassFrameText:SetText(UnitClass("target") or "");
	else
		CT_TargetFrameClassFrameText:SetText(UnitCreatureType("target") or "");
	end

	-- STEP 2:
	local r, g, b = 0, 0, 0;
	if (UnitIsFriend("target", "player")) then
		if (UnitIsPlayer("target")) then
			-- set the overall shade
			if (UnitInParty("target") or UnitInRaid("target")) then
				g,b = 0.5, 0.5;
			elseif (UnitIsInMyGuild("target")) then
				g,b = 0.25, 0.25;
			end
			-- set the primary color
			if (UnitIsPVP("target")) then
				g = 1;
			else
				b = 1;
			end
		else
			-- friendly, but not a player
			b = 1;
		end
	elseif ( UnitIsEnemy("target", "player") or UnitIsPVP("target") or UnitIsPVPFreeForAll("target")) then
		r = 1;
	else
		if (UnitIsPlayer("target")) then
			-- non-hostile player of the other faction
			r, g = 0.75, 0.25
		else
			-- non-hostile mob
			r, g = 0.5, 0.5
		end
	end
	CT_TargetFrameClassFrame:SetBackdropColor(r, g, b, 0.5);
end

function CT_TargetofTargetHealthCheck ()
	if ( not UnitIsPlayer("targettarget") ) then
		TargetFrameToTPortrait:SetVertexColor(1.0, 1.0, 1.0, 1.0);
	end
end
hooksecurefunc("TargetofTargetHealthCheck", CT_TargetofTargetHealthCheck);

function CT_TargetFrame_UpdateThreatIndicator(indicator, numericIndicator, unit)
	if (numericIndicator and numericIndicator == TargetFrameNumericalThreat) then
		local center = true;
		if (numericIndicator:IsShown()) then
			if (CT_UnitFramesOptions and CT_UnitFramesOptions.displayTargetClass) then
				center = false;
			end
		end
		if (center) then
			-- Center class frame over unit name
			CT_TargetFrame_SetClassPosition(true);
			-- Center numeric threat indicator
			CT_TargetFrame_SetThreatPosition(true, numericIndicator);
		else
			-- Shift class frame to the right
			CT_TargetFrame_SetClassPosition(false);
			-- Shift numeric threat indicator to the left.
			CT_TargetFrame_SetThreatPosition(false, numericIndicator);
		end
	end
end

function CT_TargetFrame_SetClassPosition(center)
	local frame = CT_TargetFrameClassFrame;
	frame:ClearAllPoints();

	local buffsOnTop = TARGET_FRAME_BUFFS_ON_TOP;
	if (center or buffsOnTop) then
		-- Center the class over the unit name.
		if (buffsOnTop) then
			-- Center class below the unit frame
			local xoff;
			if (TargetFrameToT and TargetFrameToT:IsShown()) then
				xoff = -13;
			else
				xoff = 0;
			end
			frame:SetPoint("TOP", TargetFrameTextureFrameName, "BOTTOM", xoff, -31);
		else
			frame:SetPoint("BOTTOM", TargetFrameTextureFrameName, "TOP", 0, 5);
		end
		frame:SetWidth(100);
		CT_TargetFrameClassFrameText:SetWidth(96);
	else
		-- Leave room on the left to display threat indicator.
		frame:SetPoint("BOTTOMLEFT", TargetFrameTextureFrameName, "TOPLEFT", 35, 5);
		frame:SetWidth(86);
		CT_TargetFrameClassFrameText:SetWidth(82);
	end
end

function CT_TargetFrame_SetThreatPosition(center, numericIndicator)
	local frame = numericIndicator;
	frame:ClearAllPoints();
	if (center) then
		frame:SetPoint("BOTTOM", TargetFrame, "TOP", -50, -22);
	else
		frame:SetPoint("BOTTOMLEFT", TargetFrame, "TOPLEFT", 7, -22);
	end
end

function CT_TargetFrame_AnchorSideText()
	local fsTable = { "CT_TargetHealthLeft", "CT_TargetManaLeft" };
	for i, name in ipairs(fsTable) do
		local frame = _G[name];

--		<Anchor point="RIGHT" relativeTo="TargetFrame" relativePoint="TOPLEFT">
--		<AbsDimension x="4" y="-46"/>
		local xoff = (CT_UnitFramesOptions.targetTextSpacing or 0);
		local yoff = -(46 + (i-1)*11);
		local onRight = CT_UnitFramesOptions.targetTextRight;
		frame:ClearAllPoints();
		if (onRight) then
			frame:SetPoint("LEFT", TargetFrame, "TOPRIGHT", xoff, yoff);
		else
			xoff = xoff - 4;
			frame:SetPoint("RIGHT", TargetFrame, "TOPLEFT", -xoff, yoff);
		end

	end
end

function CT_TargetFrame_ShowBarText()
	UnitFrameHealthBar_Update(TargetFrameHealthBar, "target");
	UnitFrameManaBar_Update(TargetFrameManaBar, "target");
end

function CT_TargetFrame_TextStatusBar_UpdateTextString(bar)

	if (bar == TargetFrameHealthBar and CT_UnitFramesOptions) then
		local style;
		if (UnitIsFriend("target", "player")) then
			style = CT_UnitFramesOptions.styles[3][1];
		else
			style = CT_UnitFramesOptions.styles[3][5];
		end
		CT_UnitFrames_TextStatusBar_UpdateTextString(bar, style, 0)
		CT_UnitFrames_HealthBar_OnValueChanged(bar, tonumber(bar:GetValue()), not CT_UnitFramesOptions.oneColorHealth)
		CT_UnitFrames_BesideBar_UpdateTextString(bar, CT_UnitFramesOptions.styles[3][2], CT_TargetHealthLeft)

	elseif (bar == TargetFrameManaBar and CT_UnitFramesOptions) then
		CT_UnitFrames_TextStatusBar_UpdateTextString(bar, CT_UnitFramesOptions.styles[3][3], 0)
		CT_UnitFrames_BesideBar_UpdateTextString(bar, CT_UnitFramesOptions.styles[3][4], CT_TargetManaLeft)
	end
end
hooksecurefunc("TextStatusBar_UpdateTextString", CT_TargetFrame_TextStatusBar_UpdateTextString);

function CT_TargetFrame_ShowTextStatusBarText(bar)
	if (bar == TargetFrameHealthBar or bar == TargetFrameManaBar) then
		CT_TargetFrame_TextStatusBar_UpdateTextString(bar);
	end
end
hooksecurefunc("ShowTextStatusBarText", CT_TargetFrame_ShowTextStatusBarText);

function CT_TargetFrame_HideTextStatusBarText(bar)
	if (bar == TargetFrameHealthBar or bar == TargetFrameManaBar) then
		CT_TargetFrame_TextStatusBar_UpdateTextString(bar);
	end
end
hooksecurefunc("HideTextStatusBarText", CT_TargetFrame_HideTextStatusBarText);

