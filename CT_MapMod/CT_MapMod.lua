
------------------------------------------------
--                 CT_MapMod                  --
--                                            --
-- Simple addon that allows the user to add   --
-- notes and gathered nodes to the world map. --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
------------------------------------------------

--------------------------------------------
-- Initialization

local module = { };
local _G = getfenv(0);

local MODULE_NAME = "CT_MapMod";
local MODULE_VERSION = strmatch(GetAddOnMetadata(MODULE_NAME, "version"), "^([%d.]+)");

module.name = MODULE_NAME;
module.version = MODULE_VERSION;

_G[MODULE_NAME] = module;
CT_Library:registerModule(module);

CT_MapMod_Notes = {}; 		-- Beginning in 8.0.1.4, this is where all notes are stored
CT_UserMap_Notes = {};  	-- Legacy variable holding map notes prior to 8.0.1.4

module.update = function(self, optName, value)
	if (optName == "init") then		
		
		-- convert saved notes from the old (pre-BFA) format into the new one
		for i, note in ipairs(CT_UserMap_Notes) do
			-- do something!
		end
		
		-- load the DataProvider which does all the work
		WorldMapFrame:AddDataProvider(CreateFromMixins(CT_MapMod_DataProviderMixin));
	
	else	
		-- not much to do!
	end
end



--------------------------------------------
-- DataProvider
-- Manages the adding, updating, and removing of data like icons, blobs or text to the map canvas

CT_MapMod_DataProviderMixin = CreateFromMixins(MapCanvasDataProviderMixin);
 
function CT_MapMod_DataProviderMixin:OnAdded(owningMap)
  -- Optionally override in your mixin, called when this provider is added to a map canvas
  self.owningMap = owningMap;
end
 
function CT_MapMod_DataProviderMixin:OnRemoved(owningMap)
  -- Optionally override in your mixin, called when this provider is removed from a map canvas
  assert(owningMap == self.owningMap);
  self.owningMap = nil;
 
  if self.registeredEvents then
    for event in pairs(self.registeredEvents) do
      owningMap:UnregisterEvent(event);
    end
    self.registeredEvents = nil;
  end
end
 
function CT_MapMod_DataProviderMixin:RemoveAllData()
	-- Override in your mixin, this method should remove everything that has been added to the map
	self:GetMap():RemoveAllPinsByTemplate("CT_MapMod_PinTemplate");
	self:GetMap():RemoveAllPinsByTemplate("CT_MapMod_CornerPinTemplate");
	module.tl = nil;
	module.br = nil;
end
 
function CT_MapMod_DataProviderMixin:RefreshAllData(fromOnShow)
	-- Override in your mixin, this method should assume the map is completely blank, and refresh any data necessary on the map
	
	-- Clear the map
	self:RemoveAllData();
	
	-- Fetch the pins to be used for this map
	local mapid = self:GetMap():GetMapID();
	if (mapid and CT_MapMod_Notes[mapid]) then
		for i, info in ipairs(CT_MapMod_Notes[mapid]) do
			self:GetMap():AcquirePin("CT_MapMod_PinTemplate", info.x, info.y, info.name, info.descript, info.icon, info.set);
		end
	end
	
	-- Create pins in the tl and br corners to calculate the map size (for cursor coords)
	module.tl = self:GetMap():AcquirePin("CT_MapMod_CornerPinTemplate", "tl");
	module.br = self:GetMap():AcquirePin("CT_MapMod_CornerPinTemplate", "br");
	
	-- DEBUGGING: create a couple extra pins for testing purposes only
	local debugPins =
	{
		-- pins for testing purposes only
		--[1] = { x = 0.5, y = 0.5, name = "HelloWorld!" },
		--[2] = { x = 0.2, y = 0.3, name = "White Diamond" }
	};
	for i, info in ipairs(debugPins) do
		self:GetMap():AcquirePin("CT_MapMod_PinTemplate", info.x, info.y, info.name, info.descript, info.icon, info.set);
	end
end
 
function CT_MapMod_DataProviderMixin:OnShow()
  -- Override in your mixin, called when the map canvas is shown
end
 
function CT_MapMod_DataProviderMixin:OnHide()
  -- Override in your mixin, called when the map canvas is closed
end
 
function CT_MapMod_DataProviderMixin:OnMapInsetSizeChanged(mapInsetIndex, expanded)
  -- Optionally override in your mixin, called when a map inset changes sizes
end
 
function CT_MapMod_DataProviderMixin:OnMapInsetMouseEnter(mapInsetIndex)
  -- Optionally override in your mixin, called when a map inset gains mouse focus
end
 
function CT_MapMod_DataProviderMixin:OnMapInsetMouseLeave(mapInsetIndex)
  -- Optionally override in your mixin, called when a map inset loses mouse focus
end
 
function CT_MapMod_DataProviderMixin:OnCanvasScaleChanged()
  -- Optionally override in your mixin, called when the canvas scale changes
end
 
function CT_MapMod_DataProviderMixin:OnCanvasPanChanged()
  -- Optionally override in your mixin, called when the pan location changes
end
 
function CT_MapMod_DataProviderMixin:OnCanvasSizeChanged()
  -- Optionally override in your mixin, called when the canvas size changes
end
 
function CT_MapMod_DataProviderMixin:OnEvent(event, ...)
  -- Override in your mixin to accept events register via RegisterEvent
end
 
function CT_MapMod_DataProviderMixin:OnGlobalAlphaChanged()
  -- Optionally override in your mixin if your data provider obeys global alpha, called when the global alpha changes
end
 
function CT_MapMod_DataProviderMixin:GetMap()
  return self.owningMap;
end
 
function CT_MapMod_DataProviderMixin:OnMapChanged()
  --  Optionally override in your mixin, called when map ID changes
  self:RefreshAllData();
end
 
function CT_MapMod_DataProviderMixin:RegisterEvent(event)
  -- Since data providers aren't frames this provides a similar method of event registration, but always calls self:OnEvent(event, ...)
  if not self.registeredEvents then
    self.registeredEvents = {}
  end
  if not self.registeredEvents[event] then
    self.registeredEvents[event] = true;
    self:GetMap():AddDataProviderEvent(event);
  end
end
 
function CT_MapMod_DataProviderMixin:UnregisterEvent(event)
  if self.registeredEvents and self.registeredEvents[event] then
    self.registeredEvents[event] = nil;
    self:GetMap():RemoveDataProviderEvent(event);
  end
end
 
function CT_MapMod_DataProviderMixin:SignalEvent(event, ...)
  if self.registeredEvents and self.registeredEvents[event] then
    self:OnEvent(event, ...);
  end
end

 
--------------------------------------------
-- Primary PinMixin
-- Pins that may be added to the map canvas, like icons, blobs or text

CT_MapMod_PinMixin = CreateFromMixins(MapCanvasPinMixin);

function CT_MapMod_PinMixin:OnLoad()
	-- Override in your mixin, called when this pin is created
	self:SetWidth(25);
	self:SetHeight(25);
	self.texture = self:CreateTexture(nil,"ARTWORK");
end
 
function CT_MapMod_PinMixin:OnAcquired(...) -- the arguments here are anything that are passed into AcquirePin after the pinTemplate
	-- Override in your mixin, called when this pin is being acquired by a data provider but before its added to the map
	self.x, self.y, self.name, self.descript, self.icon, self.set = ...;
	self:SetPosition(self.x, self.y);
	if (self.icon) then
		-- set the pin to look like what it should
	else
		self.texture:SetTexture("Interface\\RaidFrame\\UI-RaidFrame-Threat");
	end
	self.texture:SetAllPoints();
	self:Show();
end
 
function CT_MapMod_PinMixin:OnReleased()
	-- Override in your mixin, called when this pin is being released by a data provider and is no longer on the map
	if (self.isShowingTip) then
		GameTooltip:Hide();
		self.isShowingTip = nil;
	end
	self:Hide();
	
end
 
function CT_MapMod_PinMixin:OnClick(button)
	-- Override in your mixin, called when this pin is clicked
end

function CT_MapMod_PinMixin:OnMouseEnter()
	-- Override in your mixin, called when the mouse enters this pin
	if (self.name) then
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 5);
		GameTooltip:SetText(self.name);
		GameTooltip:Show();
		self.isShowingTip = true;
	end
end
 
function CT_MapMod_PinMixin:OnMouseLeave()
	-- Override in your mixin, called when the mouse leaves this pin
	if (self.isShowingTip) then
		GameTooltip:Hide();
		self.isShowingTip = nil;
	end
end
 
function CT_MapMod_PinMixin:OnMouseDown()
  -- Override in your mixin, called when the mouse is pressed on this pin
end
 
function CT_MapMod_PinMixin:OnMouseUp()
  -- Override in your mixin, called when the mouse is released
end
 
function CT_MapMod_PinMixin:OnMapInsetSizeChanged(mapInsetIndex, expanded)
  -- Optionally override in your mixin, called when a map inset changes sizes
end
 
function CT_MapMod_PinMixin:OnMapInsetMouseEnter(mapInsetIndex)
  -- Optionally override in your mixin, called when a map inset gains mouse focus
end
 
function CT_MapMod_PinMixin:OnMapInsetMouseLeave(mapInsetIndex)
  -- Optionally override in your mixin, called when a map inset loses mouse focus
end


--[[ 
		function CT_MapMod_PinMixin:SetNudgeTargetFactor(newFactor)
		  self.nudgeTargetFactor = newFactor;
		end

		function CT_MapMod_PinMixin:GetNudgeTargetFactor()
		  return self.nudgeTargetFactor or 0;
		end

		function CT_MapMod_PinMixin:SetNudgeSourceRadius(newRadius)
		  self.nudgeSourceRadius = newRadius;
		end

		function CT_MapMod_PinMixin:GetNudgeSourceRadius()
		  return self.nudgeSourceRadius or 0;
		end

		function CT_MapMod_PinMixin:SetNudgeSourceMagnitude(nudgeSourceZoomedOutMagnitude, nudgeSourceZoomedInMagnitude)
		  self.nudgeSourceZoomedOutMagnitude = nudgeSourceZoomedOutMagnitude;
		  self.nudgeSourceZoomedInMagnitude = nudgeSourceZoomedInMagnitude;
		end

		function CT_MapMod_PinMixin:GetNudgeSourceZoomedOutMagnitude()
		  return self.nudgeSourceZoomedOutMagnitude;
		end

		function CT_MapMod_PinMixin:GetNudgeSourceZoomedInMagnitude()
		  return self.nudgeSourceZoomedInMagnitude;
		end

		function CT_MapMod_PinMixin:SetNudgeZoomedInFactor(newFactor)
		  self.zoomedInNudge = newFactor;
		end

		function CT_MapMod_PinMixin:GetZoomedInNudgeFactor()
		  return self.zoomedInNudge or 0;
		end

		function CT_MapMod_PinMixin:SetNudgeZoomedOutFactor(newFactor)
		  self.zoomedOutNudge = newFactor;
		end

		function CT_MapMod_PinMixin:GetZoomedOutNudgeFactor()
		  return self.zoomedOutNudge or 0;
		end

		function CT_MapMod_PinMixin:IgnoresNudging()
		  return self.insetIndex or (self:GetNudgeSourceRadius() == 0 and self:GetNudgeTargetFactor() == 0);
		end

		function CT_MapMod_PinMixin:GetMap()
		  return self.owningMap;
		end

		function CT_MapMod_PinMixin:GetNudgeVector()
		  return self.nudgeVectorX, self.nudgeVectorY;
		end

		function CT_MapMod_PinMixin:GetNudgeSourcePinZoomedOutNudgeFactor()
		  return self.nudgeSourcePinZoomedOutNudgeFactor or 0;
		end

		function CT_MapMod_PinMixin:GetNudgeSourcePinZoomedInNudgeFactor()
		  return self.nudgeSourcePinZoomedInNudgeFactor or 0;
		end

		-- x and y should be a normalized vector.
		function CT_MapMod_PinMixin:SetNudgeVector(sourcePinZoomedOutNudgeFactor, sourcePinZoomedInNudgeFactor, x, y)
		  self.nudgeSourcePinZoomedOutNudgeFactor = sourcePinZoomedOutNudgeFactor;
		  self.nudgeSourcePinZoomedInNudgeFactor = sourcePinZoomedInNudgeFactor;
		  self.nudgeVectorX = x;
		  self.nudgeVectorY = y;
		  self:ApplyCurrentPosition();
		end

		function CT_MapMod_PinMixin:GetNudgeFactor()
		  return self.nudgeFactor or 0;
		end

		function CT_MapMod_PinMixin:SetNudgeFactor(nudgeFactor)
		  self.nudgeFactor = nudgeFactor;
		  self:ApplyCurrentPosition();
		end

		function CT_MapMod_PinMixin:GetNudgeZoomFactor()
		  local zoomPercent = self:GetMap():GetCanvasZoomPercent();
		  local targetFactor = Lerp(self:GetZoomedOutNudgeFactor(), self:GetZoomedInNudgeFactor(), zoomPercent);
		  local sourceFactor = Lerp(self:GetNudgeSourcePinZoomedOutNudgeFactor(), self:GetNudgeSourcePinZoomedInNudgeFactor(), zoomPercent);
		  return targetFactor * sourceFactor;
		end

		function CT_MapMod_PinMixin:SetPosition(normalizedX, normalizedY, insetIndex)
		  self.normalizedX = normalizedX;
		  self.normalizedY = normalizedY;
		  self.insetIndex = insetIndex;
		  self:GetMap():SetPinPosition(self, normalizedX, normalizedY, insetIndex);
		end

		-- Returns the global position if not part of an inset, otherwise returns local coordinates of that inset
		function CT_MapMod_PinMixin:GetPosition()
		  return self.normalizedX, self.normalizedY, self.insetIndex;
		end

		-- Returns the global position, even if part of an inset
		function CT_MapMod_PinMixin:GetGlobalPosition()
		  if self.insetIndex then
		    return self:GetMap():GetGlobalPosition(self.normalizedX, self.normalizedY, self.insetIndex);
		  end
		  return self.normalizedX, self.normalizedY;
		end

		function CT_MapMod_PinMixin:PanTo(normalizedXOffset, normalizedYOffset)
		  local normalizedX, normalizedY = self:GetGlobalPosition();
		  self:GetMap():PanTo(normalizedX + (normalizedXOffset or 0), (normalizedY or 0));
		end

		function CT_MapMod_PinMixin:PanAndZoomTo(normalizedXOffset, normalizedYOffset)
		  local normalizedX, normalizedY = self:GetGlobalPosition();
		  self:GetMap():PanAndZoomTo(normalizedX + (normalizedXOffset or 0), (normalizedY or 0));
		end

		function CT_MapMod_PinMixin:OnCanvasScaleChanged()
		  self:ApplyCurrentScale();
		  self:ApplyCurrentAlpha();
		end

		function CT_MapMod_PinMixin:OnCanvasPanChanged()
		  -- Optionally override in your mixin, called when the pan location changes
		end

		function CT_MapMod_PinMixin:OnCanvasSizeChanged()
		  -- Optionally override in your mixin, called when the canvas size changes
		end

		function CT_MapMod_PinMixin:SetIgnoreGlobalPinScale(ignore)
		  self.ignoreGlobalPinScale = ignore;
		end

		function CT_MapMod_PinMixin:IsIgnoringGlobalPinScale()
		  return not not self.ignoreGlobalPinScale;
		end

		function CT_MapMod_PinMixin:SetScalingLimits(scaleFactor, startScale, endScale)
		  self.scaleFactor = scaleFactor;
		  self.startScale = startScale and math.max(startScale, .01) or nil;
		  self.endScale = endScale and math.max(endScale, .01) or nil;
		end

		AM_PIN_SCALE_STYLE_VISIBLE_WHEN_ZOOMED_IN = 1;
		AM_PIN_SCALE_STYLE_VISIBLE_WHEN_ZOOMED_OUT = 2;
		AM_PIN_SCALE_STYLE_WITH_TERRAIN = 3;

		function CT_MapMod_PinMixin:SetScaleStyle(scaleStyle)
		  if scaleStyle == AM_PIN_SCALE_STYLE_VISIBLE_WHEN_ZOOMED_IN then
		    self:SetScalingLimits(1.5, 0.0, 2.55);
		  elseif scaleStyle == AM_PIN_SCALE_STYLE_VISIBLE_WHEN_ZOOMED_OUT then
		    self:SetScalingLimits(1.5, 0.825, 0.0);
		  elseif scaleStyle == AM_PIN_SCALE_STYLE_WITH_TERRAIN then
		    self:SetScalingLimits(nil, nil, nil);
		    if self:IsIgnoringGlobalPinScale() then
		      self:SetScale(1.0);
		    else
		      self:SetScale(self:GetGlobalPinScale());
		    end
		  end
		end

		function CT_MapMod_PinMixin:SetAlphaLimits(alphaFactor, startAlpha, endAlpha)
		  self.alphaFactor = alphaFactor;
		  self.startAlpha = startAlpha;
		  self.endAlpha = endAlpha;
		end

		AM_PIN_ALPHA_STYLE_VISIBLE_WHEN_ZOOMED_IN = 1;
		AM_PIN_ALPHA_STYLE_VISIBLE_WHEN_ZOOMED_OUT = 2;
		AM_PIN_ALPHA_STYLE_ALWAYS_VISIBLE = 3;

		function CT_MapMod_PinMixin:SetAlphaStyle(alphaStyle)
		  if alphaStyle == AM_PIN_ALPHA_STYLE_VISIBLE_WHEN_ZOOMED_IN then
		    self:SetAlphaLimits(2.0, 0.0, 1.0);
		  elseif alphaStyle == AM_PIN_ALPHA_STYLE_VISIBLE_WHEN_ZOOMED_OUT then
		    self:SetAlphaLimits(2.0, 1.0, 0.0);
		  elseif alphaStyle == AM_PIN_ALPHA_STYLE_ALWAYS_VISIBLE then
		    self:SetAlphaLimits(nil, nil, nil);
		  end
		end

		function CT_MapMod_PinMixin:ApplyCurrentPosition()
		  self:GetMap():ApplyPinPosition(self, self.normalizedX, self.normalizedY, self.insetIndex);
		end

		function CT_MapMod_PinMixin:ApplyCurrentScale()
		  local scale;
		  if self.startScale and self.startScale and self.endScale then
		    local parentScaleFactor = 1.0 / self:GetMap():GetCanvasScale();
		    scale = parentScaleFactor * Lerp(self.startScale, self.endScale, Saturate(self.scaleFactor * self:GetMap():GetCanvasZoomPercent()));
		  elseif not self:IsIgnoringGlobalPinScale() then
		    scale = 1;
		  end
		  if scale then
		    if not self:IsIgnoringGlobalPinScale() then
		      scale = scale * self:GetMap():GetGlobalPinScale();
		    end
		    self:SetScale(scale);
		    self:ApplyCurrentPosition();
		  end
		end

		function CT_MapMod_PinMixin:ApplyCurrentAlpha()
		  if self.alphaFactor and self.startAlpha and self.endAlpha then
		    local alpha = Lerp(self.startAlpha, self.endAlpha, Saturate(self.alphaFactor * self:GetMap():GetCanvasZoomPercent()));
		    self:SetAlpha(alpha);
		    self:SetShown(alpha > 0.05);
		  end
		end

		function CT_MapMod_PinMixin:UseFrameLevelType(pinFrameLevelType, index)
		  self.pinFrameLevelType = pinFrameLevelType;
		  self.pinFrameLevelIndex = index;
		end

		function CT_MapMod_PinMixin:GetFrameLevelType(pinFrameLevelType)
		  return self.pinFrameLevelType or "PIN_FRAME_LEVEL_DEFAULT";
		end
--]]
function CT_MapMod_PinMixin:ApplyFrameLevel()
	--local frameLevel = self:GetMap():GetPinFrameLevelsManager():GetValidFrameLevel(self.pinFrameLevelType, self.pinFrameLevelIndex);
	--self:SetFrameLevel(frameLevel);
	self:SetFrameLevel(3000);
end


--------------------------------------------
-- CornerPinMixin
-- Pins added to the tl and br corners for calculating the map size (to facilitate cursor coords)

CT_MapMod_CornerPinMixin = CreateFromMixins(MapCanvasPinMixin);

function CT_MapMod_CornerPinMixin:OnLoad()
	-- Override in your mixin, called when this pin is created
	self:SetWidth(.1);
	self:SetHeight(.1);
	--self.texture = self:CreateTexture(nil,"ARTWORK");
end
 
function CT_MapMod_CornerPinMixin:OnAcquired(...) -- the arguments here are anything that are passed into AcquirePin after the pinTemplate
	-- Override in your mixin, called when this pin is being acquired by a data provider but before its added to the map
	self.corner = ...;
	if (self.corner == "tl") then self:SetPosition(0.0,0.0); end
	if (self.corner == "br") then self:SetPosition(1.0,1.0); end
	--self.texture:SetTexture("Interface\\RaidFrame\\UI-RaidFrame-Threat");
	--self:Show();
end
 
function CT_MapMod_CornerPinMixin:OnReleased()
	-- Override in your mixin, called when this pin is being released by a data provider and is no longer on the map
	
	-- nothing to do	
end

function CT_MapMod_CornerPinMixin:ApplyFrameLevel()
	--local frameLevel = self:GetMap():GetPinFrameLevelsManager():GetValidFrameLevel(self.pinFrameLevelType, self.pinFrameLevelIndex);
	--self:SetFrameLevel(frameLevel);
	self:SetFrameLevel(3100);
end


--------------------------------------------
-- UI elements added to the world map title bar

do
	module:getFrame	(
		{
			["button#n:CT_MapMod_CreateNoteButton#s:80:16#tl:t:+120:-2#v:UIPanelButtonTemplate#New Pin"] =	{
				["onload"] = function(self)
					self:Disable();
				end,
				["onclick"] = function(self, arg1)
					if ( arg1 == "LeftButton" ) then
						if (module.isEditingNote or module.isCreatingNote) then
							return;
						else
							module.isCreatingNote = true;
							-- offer dialogue to create a note
							DEFAULT_CHAT_FRAME:AddMessage("CT_MapMod: Sorry, this feature isn't rebuilt yet for WoW 8.0");
						end
					end
				end,
				["onenter"] = function(self)
					GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 30, -60);
					GameTooltip:SetText("CT: Add a new pin to the map");
					GameTooltip:Show();
				end,
				["onleave"] = function(self)
					GameTooltip:Hide();
				end
			},
		["button#n:CT_MapMod_OptionsButton#s:80:16#tl:t:+205:-2#v:UIPanelButtonTemplate#Options"] = {
				["onclick"] = function(self, arg1)
					module:showModuleOptions(module.name);
				end,
				["onenter"] = function(self)
					GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 30, -60);
					GameTooltip:SetText("/ctmap");
					GameTooltip:Show();
				end,
				["onleave"] = function(self)
					GameTooltip:Hide();
				end
			},
		["frame#n:CT_MapMod_px#s:40:16#tl:t:-240:-2"] = { 
				["onload"] = function(self)
					local text = self:CreateFontString(nil,"ARTWORK","ChatFontNormal");
					text:SetAllPoints();
					text:SetText("x:");
					module.px = text;
				end,
			},
		["frame#n:CT_MapMod_py#s:40:16#tl:t:-200:-2"] =  { 
				["onload"] = function(self)
					local text = self:CreateFontString(nil,"ARTWORK","ChatFontNormal");
					text:SetAllPoints();
					text:SetText("y:");
					module.py = text;
				end,
			},
		["frame#n:CT_MapMod_cx#s:40:16#tl:t:-140:-2"] =  { 
				["onload"] = function(self)
					local text = self:CreateFontString(nil,"ARTWORK","ChatFontNormal");
					text:SetTextColor(.6,.6,.6);
					text:SetAllPoints();
					text:SetText("x:");
					module.cx = text;
				end,
			},
		["frame#n:CT_MapMod_cy#s:40:16#tl:t:-100:-2"] =  { 
				["onload"] = function(self)
					local text = self:CreateFontString(nil,"ARTWORK","ChatFontNormal");
					text:SetTextColor(.6,.6,.6);
					text:SetAllPoints();
					text:SetText("y:");
					module.cy = text;
				end,
			},
		},
		WorldMapFrame.BorderFrame
	);
	
	local ismouseovermap = false;
	local timesinceupdate = 0;
	--local coverframe = CreateFrame("FRAME",nil,WorldMapFrame.ScrollContainer);
	--coverframe:SetAllPoints();
	--coverframe:SetFrameLevel(WorldMapFrame.ScrollContainer:GetFrameLevel())
	WorldMapFrame.ScrollContainer:HookScript("OnEnter", function(self)
		ismouseovermap = true;
	end);
	WorldMapFrame.ScrollContainer:HookScript("OnLeave", function(self)
		ismouseovermap = false;
	end);
	WorldMapFrame.ScrollContainer:HookScript("OnUpdate", function(self, elapsed)
		timesinceupdate = timesinceupdate + elapsed;
		if (timesinceupdate < .25) then return; end
		timesinceupdate = 0;
		local mapid = WorldMapFrame:GetMapID();
		if (mapid) then
			local playerposition = C_Map.GetPlayerMapPosition(mapid,"player");
			if (playerposition) then
				local px, py = playerposition:GetXY();
				px = math.floor(px*1000)/10;
				py = math.floor(py*1000)/10;
				module.px:SetText("x:" .. px);
				module.py:SetText("y:" .. py);
				module.px:SetTextColor(1,1,1);
				module.py:SetTextColor(1,1,1);
			else
				module.px:SetText("x:");
				module.py:SetText("y:");
				module.px:SetTextColor(.6,.6,.6);
				module.py:SetTextColor(.6,.6,.6);
			end
		end
		if (mapid and module.tl and module.br) then 
			local cursorx, cursory = GetCursorPosition();
			local frameleft = module.tl:GetLeft() * module.tl:GetEffectiveScale();
			local frametop = module.tl:GetBottom() * module.tl:GetEffectiveScale();
			local framebottom = module.br:GetBottom() * module.br:GetEffectiveScale();
			local frameright = module.br:GetLeft() * module.br:GetEffectiveScale();
						
			-- checking juuuuust to be safe
			if (not cursorx or not cursory or not frameleft or not frametop or not framebottom or not frameright) then return; end
			
			local cx = (cursorx - frameleft) / (frameright - frameleft);
			local cy = 1 - (cursory - framebottom) / (frametop - framebottom)
			
			if (cx >= 0 and cy >= 0 and cx <= 1 and cy <= 1) then
				-- the cursor is over the map!
				cx = math.floor(cx*1000)/10;
				cx = math.max(math.min(cx,100),0);
				cy = math.floor(cy*1000)/10;
				cy = math.max(math.min(cy,100),0);
				module.cx:SetText("x:" .. cx);
				module.cy:SetText("y:" .. cy);
				module.cx:SetTextColor(1,1,1);
				module.cy:SetTextColor(1,1,1);
			else
				-- the cursor is NOT over the map :(
				module.cx:SetText("x:");
				module.cy:SetText("y:");
				module.cx:SetTextColor(.6,.6,.6);
				module.cy:SetTextColor(.6,.6,.6);
			end
		else
			-- the cursor is... confused?
			module.cx:SetTextColor(.6,.6,.6);
			module.cy:SetTextColor(.6,.6,.6);			
		end
	end);
end

--------------------------------------------
-- Options inside /ctmap

-- Slash command
local function slashCommand(msg)
	module:showModuleOptions(module.name);
end

module:setSlashCmd(slashCommand, "/ctmapmod", "/ctmap", "/mapmod");


local theOptionsFrame;

local optionsFrameList;
local function optionsInit()
	optionsFrameList = module:framesInit();
end
local function optionsGetData()
	return module:framesGetData(optionsFrameList);
end
local function optionsAddFrame(offset, size, details, data)
	module:framesAddFrame(optionsFrameList, offset, size, details, data);
end
local function optionsAddObject(offset, size, details)
	module:framesAddObject(optionsFrameList, offset, size, details);
end
local function optionsAddScript(name, func)
	module:framesAddScript(optionsFrameList, name, func);
end
local function optionsBeginFrame(offset, size, details, data)
	module:framesBeginFrame(optionsFrameList, offset, size, details, data);
end
local function optionsEndFrame()
	module:framesEndFrame(optionsFrameList);
end

-- Options frame
module.frame = function()
	local textColor0 = "1.0:1.0:1.0";
	local textColor1 = "0.9:0.9:0.9";
	local textColor2 = "0.7:0.7:0.7";
	local textColor3 = "0.9:0.72:0.0";
	local xoffset, yoffset;

	optionsInit();

	optionsBeginFrame(-5, 0, "frame#tl:0:%y#r");
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#Tips");
		optionsAddObject( -2, 3*14, "font#t:0:%y#s:0:%s#l:13:0#r#You can use /ctmap, /ctmapmod, or /mapmod to open this options window directly.#" .. textColor2 .. ":l");
		optionsAddObject( -5, 3*14, "font#t:0:%y#s:0:%s#l:13:0#r#To access most of the options for CT_MapMod, open the game's World Map and click on the 'Notes' button.#" .. textColor2 .. ":l");

		optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#Under Construction");
		optionsAddObject(-10, 3*14, "font#t:0:%y#s:0:%s#l:13:0#r#Patch 8.0.1 broke everything!  Most functionality is still being rebuilt from scratch.  Sorry!#" .. textColor2 .. ":l");

	optionsEndFrame();

	return "frame#all", optionsGetData();
end
