------------------------------------------------
--               CT_BarMod                    --
--                                            --
-- Intuitive yet powerful action bar addon,   --
-- featuring per-button positioning as well   --
-- as scaling while retaining the concept of  --
-- grouped buttons and action bars.           --
--                                            --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
------------------------------------------------

--------------------------------------------
-- Initialization

local _G = getfenv(0);
local module = _G.CT_BarMod;

-- End Initialization
--------------------------------------------

--------------------------------------------
-- Local Copies

local pairs = pairs;
local select = select;
local GetCursorPosition = GetCursorPosition;
local IsControlKeyDown = IsControlKeyDown;
local IsShiftKeyDown = IsShiftKeyDown;

local actionButtonList = module.actionButtonList;
local ATTRIBUTE_NOOP = ATTRIBUTE_NOOP;

-- End Local Copies
--------------------------------------------

--------------------------------------------
-- Selection Handler

local selectedButtons = { };
module.selectedEditButtons = selectedButtons;

-- Apply a method onto all of the entries
local lastMethod;
local function doMethod(...)
	for key, value in pairs(selectedButtons) do
		value[lastMethod](value, select(2, ...));
	end
end
setmetatable(selectedButtons, { __index = function(key, value)
	lastMethod = value; return doMethod; end });
	
--------------------------------------------
-- Edit Button Class

local editButton = { };
local actionButton = module.actionButtonClass;

setmetatable(editButton, { __index = actionButton });
module.editButtonClass = editButton;

-- Constructor
function editButton:constructor(...)
	-- Call default behavior
	actionButton.constructor(self, ...);
	
	local button = self.button;
	--button:SetButtonState("NORMAL", true);
	button:SetAttribute("action", -1);
	button.icon:SetVertexColor(0.25, 0.25, 0.25);
end

-- Destructor
function editButton:destructor(...)
	self.button.icon:SetVertexColor(1, 1, 1);
	
	-- Call default behavior
	--button:SetButtonState("NORMAL", false);
	actionButton.destructor(self, ...);
end

-- OnMouseDown handler
local mainButton;

function editButton:ondragstart(frame, button)
	if ( self.selected ) then
		for key, value in pairs(selectedButtons) do
			if ( value ~= self ) then
				value:anchor(self);
			end
		end
		self:move();
		mainButton = self;
	else
		self:move();
	end
end

-- OnMouseUp handler
function editButton:ondragstop(frame, button)
	selectedButtons:savePosition();
	selectedButtons:stopMove();
	self:stopMove();
end

-- PostClick handler
function editButton:postclick(frame, button)
	if ( self.moving ) then
		frame:SetChecked(self.selected);
		return;
	end
	if ( frame:GetChecked() ) then
		self:select();
	else
		self:deselect();
	end
end

-- Add to selection
function editButton:select()
	selectedButtons[self.button] = self;
	self.selected = true;
	self.button:SetChecked(true);
end

-- Remove from selection
function editButton:deselect()
	selectedButtons[self.button] = nil;
	self.selected = nil;
	self.button:SetChecked(false);
end

-- Modify scale depending on delta scale
function editButton:modifyScale(scaleChange)
	self:setScale(self.scale + scaleChange);
end

-- Re-anchor to another button
function editButton:anchor(object)
	if ( object and object ~= self ) then
		local bButton, oButton = self.button, object.button;
		local bX, bY, bScale = self.xPos, self.yPos, self.scale;
		local oX, oY, oScale = object.xPos, object.yPos, object.scale;

		if (bScale == 0) then
			bX = 0;
			bY = 0;
		else
			bX = bX / bScale;
			bY = bY / bScale;
		end
		if (oScale == 0) then
			oX = 0;
			oY = 0;
		else
			oX = oX / oScale;
			oY = oY / oScale;
		end
		bButton:ClearAllPoints();
		bButton:SetPoint("CENTER", oButton, "CENTER", bX - oX, bY - oY);
	end
end

--------------------------------------------
-- Mode Handlers

-- Scale Updater
local controlState, lastY, scaleUpdaterFrame;
local function scaleUpdate(self, elapsed)
	local newState = IsControlKeyDown();
	if ( newState ) then
		if ( not controlState ) then
			local _, y = GetCursorPosition();
			lastY = y;
		else
			local _, y = GetCursorPosition();
			local scaleChange = (y-lastY)/128;
			lastY = y;
			selectedButtons:modifyScale(scaleChange);
			if ( mainButton and mainButton.moving ) then
				selectedButtons:anchor(mainButton);
			end
		end
	end
	controlState = newState;
end

-- Selector Updater
local selectorMode;
local function isInside(left, right, top, bottom, button)
	local scale = button:GetScale();
	local bLeft, bRight, bTop, bBottom = button:GetLeft() * scale, 
		button:GetRight() * scale, button:GetTop() * scale, button:GetBottom() * scale;

	return not (
			bLeft > right or
			bRight < left or
			bTop < bottom or
			bBottom > top
		);
end

local selectorUpdaterFrame, selectFrame, selectButton;
local shiftState, isSelecting, prevSelected, initialX, initialY;

local function selectorUpdate(self, elapsed)
	local newState = IsShiftKeyDown();
	local oldState = shiftState;
	shiftState = newState;
	
	if ( newState ~= oldState ) then
		if ( newState and not selectFrame ) then
			
			selectFrame = module:getFrame(function()
				return "frame", {
					"texture#all#0.5:0.5:1:0.3",
					"texture#bl:tl#br:tr#s:0:2#0.1:0.1:0.4",
					"texture#tl:tr#bl:br#s:2:0#0.1:0.1:0.4",
					"texture#tl:bl#tr:br#s:0:2#0.1:0.1:0.4",
					"texture#tr:tl#br:bl#s:2:0#0.1:0.1:0.4"
				};
			end);
			
			selectButton = CreateFrame("Button", "TB");
			selectButton:SetPoint("TOPLEFT", nil, "TOPLEFT");
			selectButton:SetPoint("BOTTOMRIGHT", nil, "BOTTOMRIGHT");
			selectButton:SetScript("OnMouseDown", function(self, button)
				if ( button == "RightButton" ) then
					selectorMode = 2;
				else
					selectorMode = 1;
				end
				
				-- Start dragging
				for key, value in pairs(selectedButtons) do
					prevSelected[value] = true;
				end
				
				local scale = UIParent:GetScale();
				initialX, initialY = GetCursorPosition();
				if (scale == 0) then
					initialX = 0;
					initialY = 0;
				else
					initialX = initialX / scale;
					initialY = initialY / scale;
				end
				
				selectFrame:Show();
				selectFrame:ClearAllPoints();
				selectFrame:SetWidth(0); selectFrame:SetHeight(0);
				
				isSelecting = true;
			end);
			selectButton:SetScript("OnMouseUp", function(self)
				-- Stop dragging
				module:clearTable(prevSelected);
				
				selectFrame:Hide();
				if ( not shiftState ) then
					selectButton:Hide();
				end
				
				isSelecting = nil;
			end);
		
		elseif ( not oldState ) then
			selectButton:Show();
		end
	end
	
	if ( isSelecting ) then
		local scale = UIParent:GetScale();
		local newX, newY = GetCursorPosition();
		local initialX, initialY = initialX, initialY;
		local scaledX, scaledY;
		if (scale == 0) then
			scaledX = 0;
			scaledY = 0;
		else
			scaledX = newX / scale;
			scaledY = newY / scale;
		end
		local width, height;
		
		width, height = initialX-scaledX, initialY-scaledY;
		selectFrame:ClearAllPoints();
		
		if ( width < 0 ) then
			if ( height < 0 ) then
				selectFrame:SetPoint("BOTTOMLEFT", nil, initialX, initialY);
				selectFrame:SetPoint("TOPRIGHT", nil, "BOTTOMLEFT", scaledX, scaledY);
				initialY, newY = newY, initialY * scale;
			else
				selectFrame:SetPoint("BOTTOMLEFT", nil, initialX, scaledY);
				selectFrame:SetPoint("TOPRIGHT", nil, "BOTTOMLEFT", scaledX, initialY);
				initialY = initialY * scale;
			end
			initialX, newX = newX, initialX * scale;
		else
			if ( height < 0 ) then
				selectFrame:SetPoint("BOTTOMLEFT", nil, scaledX, initialY);
				selectFrame:SetPoint("TOPRIGHT", nil, "BOTTOMLEFT", initialX, scaledY);
				initialY, newY = newY, initialY * scale;
			else
				selectFrame:SetPoint("BOTTOMLEFT", nil, scaledX, scaledY);
				selectFrame:SetPoint("TOPRIGHT", nil, "BOTTOMLEFT", initialX, initialY);
				initialY = initialY * scale;
			end
			initialX = initialX * scale;
		end
		
		-- Find buttons inside the area
		for key, value in pairs(actionButtonList) do
			if ( isInside(newX, initialX, initialY, newY, value.button) ) then
				if ( selectorMode == 1 ) then
					value:select();
				else
					value:deselect();
				end
			else
				if ( prevSelected[value] ) then
					value:select();
				else
					value:deselect();
				end
			end
		end
	elseif ( selectButton and not shiftState ) then
		selectButton:Hide();
	end
end

local editButtonMeta = { __index = editButton };
module.editButtonMeta = editButtonMeta;
module.editEnable = function(self)
	-- Scale Updater
	if ( not scaleUpdaterFrame ) then
		scaleUpdaterFrame = CreateFrame("Frame");
	end
	scaleUpdaterFrame:SetScript("OnUpdate", scaleUpdate);
	
	-- Selector Updater
	if ( not prevSelected ) then
		prevSelected = { };
		selectorUpdaterFrame = CreateFrame("Frame");
	end
	selectorUpdaterFrame:SetScript("OnUpdate", selectorUpdate);
end
module.editDisable = function(self)
	if ( scaleUpdaterFrame ) then
		scaleUpdaterFrame:SetScript("OnUpdate", nil);
		selectorUpdaterFrame:SetScript("OnUpdate", nil);
	end
end

--------------------------------------------
-- Update Initialization

module.editUpdate = function(self, type, value)
	if ( type == "init" ) then

	end
end
