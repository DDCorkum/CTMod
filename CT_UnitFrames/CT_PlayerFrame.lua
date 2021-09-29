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

local module = select(2, ...)

local function CT_PlayerFrame_HealthTextStatusBar_UpdateTextString(bar)
	if (CT_UnitFramesOptions) then
		module:UpdateStatusBarTextString(bar, CT_UnitFramesOptions.styles[1][1])
		CT_UnitFrames_HealthBar_OnValueChanged(bar, tonumber(bar:GetValue()), not CT_UnitFramesOptions.oneColorHealth)
		module:UpdateBesideBarTextString(bar, CT_UnitFramesOptions.styles[1][2], CT_PlayerHealthRight)
	end
end

local function CT_PlayerFrame_ManaTextStatusBar_UpdateTextString(bar)
	if (CT_UnitFramesOptions) then
		module:UpdateStatusBarTextString(bar, CT_UnitFramesOptions.styles[1][3])
		module:UpdateBesideBarTextString(bar, CT_UnitFramesOptions.styles[1][4], CT_PlayerManaRight)
	end
end

module:regEvent("PLAYER_LOGIN", function()
	PlayerFrameHealthBar:HookScript("OnEnter", CT_PlayerFrame_HealthTextStatusBar_UpdateTextString)
	PlayerFrameHealthBar:HookScript("OnLeave", CT_PlayerFrame_HealthTextStatusBar_UpdateTextString)
	PlayerFrameHealthBar:HookScript("OnValueChanged", CT_PlayerFrame_HealthTextStatusBar_UpdateTextString)
	PlayerFrameManaBar:HookScript("OnEnter", CT_PlayerFrame_ManaTextStatusBar_UpdateTextString)
	PlayerFrameManaBar:HookScript("OnLeave", CT_PlayerFrame_ManaTextStatusBar_UpdateTextString)
	PlayerFrameManaBar:HookScript("OnValueChanged", CT_PlayerFrame_ManaTextStatusBar_UpdateTextString)
	
	-- incoming heals on classic
	if (UnitGetTotalAbsorbs == nil) then
		module:addClassicIncomingHeals(PlayerFrame)
	end
end)

function module:ShowPlayerFrameBarText()
	CT_PlayerFrame_HealthTextStatusBar_UpdateTextString(PlayerFrameHealthBar)
	CT_PlayerFrame_ManaTextStatusBar_UpdateTextString(PlayerFrameManaBar)
end

function module:AnchorPlayerFrameSideText()
	local fsTable = { "CT_PlayerHealthRight", "CT_PlayerManaRight" }
	for i, name in ipairs(fsTable) do
		local frame = _G[name]
		
--		<Anchor point="LEFT" relativeTo="PlayerFrame" relativePoint="TOPRIGHT">
--		<AbsDimension x="-3.4" y="-46"/>
		local xoff = (CT_UnitFramesOptions.playerTextSpacing or 0)
		local yoff = -(46 + (i-1)*11)
		local onRight = not CT_UnitFramesOptions.playerTextLeft
		frame:ClearAllPoints()
		if (onRight) then
			frame:SetPoint("LEFT", PlayerFrame, "TOPRIGHT", (-3.4 + xoff), yoff)
		else
			frame:SetPoint("RIGHT", PlayerFrame, "TOPLEFT",  -(xoff), yoff)
		end

	end
end

local playerCoordsShown
local function playerCoordsFunc ()
	if (playerCoordsShown) then
		local mapid = C_Map.GetBestMapForUnit("player")
		if (mapid) then
			local playerposition = C_Map.GetPlayerMapPosition(mapid,"player")
			if (playerposition) then
				local px, py = playerposition:GetXY()
				if (not px or not py) then return; end  -- don't think this can ever happen
				CT_PlayerCoordsRight:SetText(format("%d, %d", px*100, py*100))
			else
				CT_PlayerCoordsRight:SetText("")
			end
		else
			CT_PlayerCoordsRight:SetText("")
		end
		C_Timer.After(1, playerCoordsFunc)
	end
end

function CT_PlayerFrame_PlayerCoords()
	if (CT_UnitFramesOptions.playerCoordsRight) then
		CT_PlayerCoordsRight:Show()
		playerCoordsShown = true
		playerCoordsFunc()
	else
		CT_PlayerCoordsRight:Hide()
		playerCoordsShown = nil
	end
end

