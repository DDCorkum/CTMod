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

--------------------------------------------
-- Initialization

local module = select(2,...);
local _G = getfenv(0);

local MODULE_NAME = "CT_UnitFrames";
local MODULE_VERSION = strmatch(GetAddOnMetadata(MODULE_NAME, "version"), "^([%d.]+)");

module.name = MODULE_NAME;
module.version = MODULE_VERSION;

_G[MODULE_NAME] = module;
CT_Library:registerModule(module);


--------------------------------------------
-- Common functions

function CT_UnitFrames_LinkFrameDrag(frame, drag, point, relative, x, y)
	frame:ClearAllPoints();
	frame:SetPoint(point, drag:GetName(), relative, x, y);
end

function CT_UnitFrames_ResetPosition(name)
	-- Reset the position of a movable frame (name == nil == all movable frames).
	if (InCombatLockdown()) then
		return;
	end
	local yoffset = 0;
	if (TitanMovable_GetPanelYOffset and TITAN_PANEL_PLACE_TOP and TitanPanelGetVar) then
		yoffset = yoffset + (tonumber( TitanMovable_GetPanelYOffset(TITAN_PANEL_PLACE_TOP, TitanPanelGetVar("BothBars")) ) or 0);
	end
	if (not name or name == "CT_AssistFrame_Drag") then
		CT_AssistFrame_Drag:ClearAllPoints();
		CT_AssistFrame_Drag:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 500, -25 + yoffset);
		CT_AssistFrame_Drag:SetUserPlaced(true);
	end
	if (not name or name == "CT_FocusFrame_Drag") then
		CT_FocusFrame_Drag:ClearAllPoints();
		CT_FocusFrame_Drag:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 500, -180 + yoffset);
		CT_FocusFrame_Drag:SetUserPlaced(true);
	end
end

function CT_UnitFrames_ResetDragLink(name)
	-- Reset the link between a drag frame and its companion frame (name == nil == all movable frames).
	if (InCombatLockdown()) then
		return;
	end
	if (not name or name == "CT_AssistFrame_Drag") then
		CT_UnitFrames_LinkFrameDrag(CT_AssistFrame, CT_AssistFrame_Drag, "TOPLEFT", "TOPLEFT", -15, 21);
	end
	if (not name or name == "CT_FocusFrame_Drag") then
		CT_UnitFrames_LinkFrameDrag(CT_FocusFrame, CT_FocusFrame_Drag, "TOPLEFT", "TOPLEFT", -15, 21);
	end
end

function CT_UnitFrames_TextStatusBar_UpdateTextString(textStatusBar, settings, lockShow)
	local textString = textStatusBar.TextString or textStatusBar.ctTextString;	--ctTextString is used to avoid creating taint
	if (module:getGameVersion() == CT_GAME_VERSION_CLASSIC) then
		if (not textString) then
			local intermediateFrame = CreateFrame("Frame", nil, textStatusBar);
			intermediateFrame:SetFrameLevel(5);
			intermediateFrame:SetAllPoints();
			textString = intermediateFrame:CreateFontString(nil, "OVERLAY", "TextStatusBarText");
			textString:SetPoint("CENTER", textStatusBar);
			textStatusBar.ctTextString = textString;
		end
		if ((textString.ctControlled == "Classic" or textString.ctControlled == nil) and CT_UnitFramesOptions.makeFontLikeRetail) then
			-- set or change it to retail font, but do it just once
			textString:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE");
			textString.ctControlled = "Retail";
		elseif ((textString.ctControlled == "Retail" or textString.ctControlled == nil) and not CT_UnitFramesOptions.makeFontLikeRetail) then
			-- set or change it to classic font, but do it just once
			textString:SetFont("Fonts\\ARIALN.TTF", 14, "OUTLINE");
			textString.ctControlled = "Classic";	
		end
	end
	if(textString) then
		if (lockShow == nil) then lockShow = textStatusBar.lockShow; end
		local value = textStatusBar:GetValue();
		local valueMin, valueMax = textStatusBar:GetMinMaxValues();
		if ( ( tonumber(valueMax) ~= valueMax or valueMax > 0 ) and not ( textStatusBar.pauseUpdates ) ) then
			local style = settings[1];
			local abbreviate = CT_UnitFramesOptions.largeAbbreviate ~= false;
			local breakup = CT_UnitFramesOptions.largeBreakUp ~= false;
			local prefix;
			if (lockShow > 0) then
				style = 4;
				prefix = 1;
			end
			textStatusBar:Show();
			if ( value and valueMax > 0 and ( style == 2 ) ) then
				-- Percent
				if ( value == 0 and textStatusBar.zeroText ) then
					textString:SetText(textStatusBar.zeroText);
					textStatusBar.isZero = 1;
					textString:Show();
					return;
				end
				value = math.ceil((value / valueMax) * 100);
				if (abbreviate) then
					value = module:abbreviateLargeNumbers(value, breakup);
				elseif (breakup) then
					value = module:breakUpLargeNumbers(value, breakup);
				end
				if ( textStatusBar.prefix and prefix ) then
					textString:SetText(textStatusBar.prefix .. " " .. value .. "%");
				else
					textString:SetText(value .. "%");
				end
			elseif ( value == 0 and textStatusBar.zeroText ) then
				textString:SetText(textStatusBar.zeroText);
				textStatusBar.isZero = 1;
				textString:Show();
				return;
			elseif (style == 1) then
				-- None
				textString:SetText("");
				textStatusBar.isZero = nil;
				textStatusBar:Show();
			elseif (style == 3) then
				-- Deficit
				textStatusBar.isZero = nil;
				value = value - valueMax;
				if (value >= 0) then
					value = "";
				else
					if (abbreviate) then
						value = module:abbreviateLargeNumbers(value, breakup);
					elseif (breakup) then
						value = module:breakUpLargeNumbers(value, breakup);
					end
				end
				if ( textStatusBar.prefix and prefix ) then
					textString:SetText(textStatusBar.prefix .. " " .. value);
				else
					textString:SetText(value);
				end
			elseif (style == 5) then
				-- Current
				textStatusBar.isZero = nil;
				if (abbreviate) then
					value = module:abbreviateLargeNumbers(value, breakup);
				elseif (breakup) then
					value = module:breakUpLargeNumbers(value, breakup);
				end
				if ( textStatusBar.prefix and prefix ) then
					textString:SetText(textStatusBar.prefix .. " " .. value);
				else
					textString:SetText(value);
				end
			else
				-- Values
				textStatusBar.isZero = nil;
--				if ( textStatusBar.capNumericDisplay ) then
				if (abbreviate) then
					value = module:abbreviateLargeNumbers(value, breakup);
					valueMax = module:abbreviateLargeNumbers(valueMax, breakup);
				elseif (breakup) then
					value = module:breakUpLargeNumbers(value, breakup);
					valueMax = module:breakUpLargeNumbers(valueMax, breakup);
				end
				if ( textStatusBar.prefix and prefix ) then
					textString:SetText(textStatusBar.prefix .. " " .. value .. "/" .. valueMax);
				else
					textString:SetText(value .. "/" .. valueMax);
				end
			end
			textString:Show();
		else
			textString:Hide();
			textStatusBar:Hide();
		end
		textString:SetTextColor(settings[2], settings[3], settings[4], settings[5]);
	end
end

function CT_UnitFrames_BesideBar_UpdateTextString(textStatusBar, settings, textString)
	if(textString) then
		local value = textStatusBar:GetValue();
		local valueMin, valueMax = textStatusBar:GetMinMaxValues();
		if ( ( tonumber(valueMax) ~= valueMax or valueMax > 0 ) ) then
			local style = settings[1];
			local abbreviate = CT_UnitFramesOptions.largeAbbreviate ~= false;
			local breakup = CT_UnitFramesOptions.largeBreakUp ~= false;
			if ( value and valueMax > 0 and ( style == 2 ) ) then
				-- Percent
				value = math.ceil((value / valueMax) * 100);
				if (abbreviate) then
					value = module:abbreviateLargeNumbers(value, breakup);
				elseif (breakup) then
					value = module:breakUpLargeNumbers(value, breakup);
				end
				textString:SetText(value .. "%");
			elseif (style == 1) then
				-- None
				textString:SetText("");
			elseif (style == 3) then
				-- Deficit
				value = value - valueMax;
				if (value >= 0) then
					value = "";
				else
					if (abbreviate) then
						value = module:abbreviateLargeNumbers(value, breakup);
					elseif (breakup) then
						value = module:breakUpLargeNumbers(value, breakup);
					end
				end
				textString:SetText(value);
			elseif (style == 5) then
				-- Current
				if (abbreviate) then
					value = module:abbreviateLargeNumbers(value, breakup);
				elseif (breakup) then
					value = module:breakUpLargeNumbers(value, breakup);
				end
				textString:SetText(value);
			else
				-- Values
--				if ( textStatusBar.capNumericDisplay ) then
				if (abbreviate) then
					value = module:abbreviateLargeNumbers(value, breakup);
					valueMax = module:abbreviateLargeNumbers(valueMax, breakup);
				elseif (breakup) then
					value = module:breakUpLargeNumbers(value, breakup);
					valueMax = module:breakUpLargeNumbers(valueMax, breakup);
				end
				textString:SetText(value .. "/" .. valueMax);
			end
			textString:Show();
		else
			textString:Hide();
		end
		textString:SetTextColor(settings[2], settings[3], settings[4], settings[5]);
	end
end

function CT_UnitFrames_HealthBar_OnValueChanged(self, value, smooth)
	if ( not value ) then
		return;
	end
	local r, g, b;
	local min, max = self:GetMinMaxValues();
	if ( (value < min) or (value > max) ) then
		return;
	end
	if ( (max - min) > 0 ) then
		value = (value - min) / (max - min);
	else
		value = 0;
	end
	if(smooth) then
		if(value > 0.5) then
			r = (1.0 - value) * 2;
			g = 1.0;
		else
			r = 1.0;
			g = value * 2;
		end
	else
		r = 0.0;
		g = 1.0;
	end
	b = 0.0;
	if ( not self.lockColor ) then
		self:SetStatusBarColor(r, g, b);
	end
end
