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

local ceil = ceil;
local format = format;
local pairs = pairs;
local tinsert = tinsert;
local tostring = tostring;
local tremove = tremove;
local GetCursorPosition = GetCursorPosition;
local IsShiftKeyDown = IsShiftKeyDown;

local editButton = module.editButtonClass;

-- End Local Copies
--------------------------------------------

--------------------------------------------
-- Options

local editFrame;
local function editFrameSkeleton()
	local dragStart, originalSelection, draggedButtons, dragButtonPool, selectedButtons, origButton;
	if ( not selectedButtons ) then
		selectedButtons = { };
	end
	
	local function updateColor(self)
		local over = self.over;
		if ( over == 3 ) then
			self.texture:SetVertexColor(0.4, 0.5, 0.28, 0.8);
		elseif ( over == 2 ) then
			if ( selectedButtons[self] ) then
				self.texture:SetVertexColor(1, 0.72, 0, 0.9);
			else
				self.texture:SetVertexColor(1, 0.75, 0.26, 0.45);
			end
		elseif ( over == 1 ) then
			if ( selectedButtons[self] ) then
				self.texture:SetVertexColor(1, 0.9, 0.3, 0.83);
			else
				self.texture:SetVertexColor(1, 1, 1, 0.75);
			end
		else
			if ( selectedButtons[self] ) then
				self.texture:SetVertexColor(1, 0.82, 0, 0.75);
			else
				self.texture:SetVertexColor(1, 1, 1, 0.25);
			end
		end
	end
	
	local dragData;
	local function dragButtonSkeleton()
		if ( not dragData ) then
			dragData = {
				"texture#all#1:0.82:0",
			};
		end
		return "frame#p:CT_BarModEditFrame#st:TOOLTIP#s:23:23", dragData;
	end
	
	local uiScale;
	local function updateDrag(self)
		local x, y = GetCursorPosition();
		if (uiScale == 0) then
			x = 0;
			y = 0;
		else
			x = x / uiScale;
			y = y / uiScale;
		end
		origButton:ClearAllPoints();
		origButton:SetPoint("CENTER", nil, "BOTTOMLEFT", x, y);
	end
	
	local function getDragButton()
		local button = ( dragButtonPool and tremove(dragButtonPool) );
		if ( not button ) then
			button = module:getFrame(dragButtonSkeleton);
		end
		return button;
	end
	
	local function startDrag(startButton)
		if ( not draggedButtons ) then
			draggedButtons = { };
		end
		
		-- Create the original button
		local button = getDragButton();
		origButton = button;
		button.isOrig = true;
		button:ClearAllPoints();
		button:SetPoint("CENTER", startButton, "CENTER");
		button:Show();
		
		for key, value in pairs(selectedButtons) do
			-- Highlight the original button as guide
			key.over = 3;
			updateColor(key);

			-- Create a button following the mouse
			if ( key ~= startButton ) then
				button = getDragButton();
				button:ClearAllPoints();
				button:SetPoint("CENTER", key, "CENTER");
				button:Show();

				local bX, bY = button:GetCenter();
				local oX, oY = origButton:GetCenter();

				button:ClearAllPoints();
				button:SetPoint("CENTER", origButton, "CENTER", bX-oX, bY-oY);
			else
				button = origButton;
			end
			tinsert(draggedButtons, button);
		end
		uiScale = UIParent:GetScale();
		editFrame:SetScript("OnUpdate", updateDrag);
	end
	
	local function stopDrag()
		if ( draggedButtons and draggedButtons[1] ) then
			if ( not dragButtonPool ) then
				dragButtonPool = { };
			end
			
			local obj;
			for key, value in pairs(draggedButtons) do
				value.isOrig = nil;
				value:Hide();
				tinsert(dragButtonPool, value);
				draggedButtons[key] = nil;
			end
			editFrame:SetScript("OnUpdate", nil);
			origButton = nil;
		elseif ( origButton ) then
			-- We're dragging real frames
			origButton:ondragstop(origButton.button, "RightButton");
		end

		for key, value in pairs(selectedButtons) do
			if ( key:IsMouseOver() ) then
				key.over = 1;
			else
				key.over = nil;
			end
			updateColor(key);
		end
	end
	
	local function toggleSelected(obj, force)
		if ( force ) then
			selectedButtons[obj] = force;
		elseif ( force == false or selectedButtons[obj] ) then
			selectedButtons[obj] = nil;
		else
			selectedButtons[obj] = obj:GetID();
		end
	end
	
	local data = { 
		"texture#tl:43:-46#br:tl:374:-49#1:1:1:1",
		"texture#tl:374:-46#br:tl:377:-382#1:1:1:1",
		"texture#tl:46:-380#br:tl:374:-382#1:1:1:1",
		"texture#tl:43:-48#br:tl:46:-382#1:1:1:1",
		
		["button#s:54:62#br:-20:25"] = {
			["onload"] = function(self)
				local normalTexture = self:CreateTexture(nil, "BACKGROUND");
				normalTexture:SetTexture("Interface\\AddOns\\CT_BarMod\\Images\\recycleBin");
				normalTexture:SetTexCoord(0.078125, 0.921875, 0.03125, 0.96875);
				normalTexture:SetAllPoints(self);
				
				local highlightTexture = self:CreateTexture(nil, "BACKGROUND");
				highlightTexture:SetTexture("Interface\\AddOns\\CT_BarMod\\Images\\recycleBinHighlight");
				highlightTexture:SetTexCoord(0.078125, 0.921875, 0.03125, 0.96875);
				highlightTexture:SetAllPoints(self);
				
				self:SetNormalTexture(normalTexture);
				self:SetHighlightTexture(highlightTexture);
			end
		},
		
		["onleave"] = function(self)
			if ( draggedButtons and draggedButtons[1] ) then
				if ( not self:IsMouseOver() ) then
					local selectedButtons = module.selectedEditButtons;
					if ( selectedButtons ) then
						selectedButtons:deselect();
						selectedButtons:savePosition();
					end
					
					local object, button, origObject;
					for key, value in pairs(draggedButtons) do
						object = editButton:new(nil, false, true);
						button = object.button;
						button:ClearAllPoints();
						button:SetPoint("CENTER", value);
						object:savePosition();
						object:select();
						
						if ( value.isOrig ) then
							origObject = object;
						end
					end
					
					origObject:ondragstart(origObject.button, "RightButton");
					stopDrag();
					origButton = origObject;
				end
			end
		end,
		
		["onload"] = function(self)
			self:EnableMouse(true);
		end
	};
	local buttonTemplate = {
		"texture#i:texture#tl:2:-2#br:-2:2#1:1:1",

		["onenter"] = function(self)
			if ( draggedButtons and draggedButtons[1] ) then
				return;
			end
			self.over = 1;
			updateColor(self);
			if ( dragStart ) then
				-- Figure out x and y
				local dId, oId = self:GetID(), dragStart:GetID();
				local dX, dY = dId % 12, ceil(dId / 12);
				local oX, oY = oId % 12, ceil(oId / 12);
				if ( dX == 0 ) then dX = 12; end
				if ( oX == 0 ) then oX = 12; end
				
				-- Code below assumes dX < oX and dY < oY, change place if that's not the case
				if ( dX > oX ) then dX, oX = oX, dX; end
				if ( dY > oY ) then dY, oY = oY, dY; end
				
				local parent, obj = self.parent;
				for x = 1, 12, 1 do
					for y = 1, 12, 1 do
						obj = parent[tostring((y - 1) * 12 + x)];
						if ( x >= dX and x <= oX and y >= dY and y <= oY ) then
							toggleSelected(obj, not originalSelection[obj]);
							obj.over = 2;
						else
							toggleSelected(obj, originalSelection[obj] or false);
							if ( self == obj ) then
								obj.over = 1;
							else
								obj.over = nil;
							end
						end
						updateColor(obj);
					end
				end
			end
		end,

		["onleave"] = function(self)
			if ( draggedButtons and draggedButtons[1] ) then
				if ( self.over ~= 3 ) then
					self.over = nil;
					updateColor(self);
				end
				return;
			elseif ( not dragStart ) then
				self.over = nil;
			end
			updateColor(self);
		end,
		
		["onload"] = function(self)
			self.texture:SetVertexColor(1, 1, 1, 0.25);
			self:RegisterForDrag("LeftButton", "RightButton");
		end,
		
		["onclick"] = function(self)
			toggleSelected(self);
			updateColor(self);
		end,
		
		["ondragstart"] = function(self)
			if ( IsShiftKeyDown() ) then
				dragStart = self;
				if ( not originalSelection ) then
					originalSelection = { };
				else
					module:clearTable(originalSelection);
				end
				for key, value in pairs(selectedButtons) do
					originalSelection[key] = value;
				end
				toggleSelected(self);
				updateColor(self);
			
			elseif ( selectedButtons and selectedButtons[self] ) then
				startDrag(self);
			end
		end,
		
		["ondragstop"] = function(self)
			if ( dragStart ) then
				dragStart = nil;
				local parent, obj = self.parent;
				for i = 1, 144, 1 do
					obj = parent[tostring(i)];
					if ( obj:IsMouseOver() ) then
						obj.over = 1;
					else
						obj.over = nil;
					end
					updateColor(obj);
				end
				return;
			end
			stopDrag();
		end,
	};
	
	for x = 1, 12, 1 do
		for y = 1, 12, 1 do
			data[format("button#i:%d#tl:%d:%d#s:27:27#li:buttonTemplate",
				(y - 1) * 12 + x, 21 + 27 * x, -26 - 27 * y)] = buttonTemplate;
		end
	end
	
	return "optionframe#s:700:550#n:CT_BarModEditFrame#CT_BarMod Edit", data;
end

--[[if ( not editFrame ) then
	editFrame = module:getFrame(editFrameSkeleton);
end
editFrame:Show();]]
