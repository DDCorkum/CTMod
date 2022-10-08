------------------------------------------------
--                  CT_Core                   --
--                                            --
-- Core addon for doing basic and popular     --
-- things in an intuitive way.                --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
------------------------------------------------

--------------------------------------------
-- Initialization

local module = { };
local _G = getfenv(0);

local MODULE_NAME = "CT_Core";
local MODULE_VERSION = strmatch(GetAddOnMetadata(MODULE_NAME, "version"), "^([%d.]+)");

module.name = MODULE_NAME;
module.version = MODULE_VERSION;

_G[MODULE_NAME] = module;
CT_Library:registerModule(module);

--------------------------------------------
-- Helper variable for bag automation

-- New events added here should also be added to local variable "events" in CT_Core_Other.lua
local bagAutomationEvents = {
	{shortlabel = "AH", label = "Auction House", openAll = "auctionOpenBags", backpack = "auctionOpenBackpack", nobags = "auctionOpenNoBags", close = "auctionCloseBags", show = true},
	{shortlabel = "Bank", label = "Player Bank", openAll = "bankOpenBags", backpack = "bankOpenBackpack", nobags = "bankOpenNoBags", bank = "bankOpenBankBags", close = "bankCloseBags", show = true},
	{shortlabel = "G-Bank", label = "Guild Bank", openAll = "gbankOpenBags", backpack = "gbankOpenBackpack", nobags = "gbankOpenNoBags", close = "gbankCloseBags", show = GuildBankFrame_LoadUI},
	{shortlabel = "Merchant", label = "Merchant Frame", openAll =  "merchantOpenBags", backpack = "merchantOpenBackpack", nobags = "merchantOpenNoBags", close = "merchantCloseBags", show = true},
	{shortlabel = "Trading", label = "Player Trading Frame", openAll = "tradeOpenBags", backpack = "tradeOpenBackpack", nobags = "tradeOpenNoBags", close = "tradeCloseBags", show = true},
	{shortlabel = "Void-Stg", label = "Void Storage", openAll = "voidOpenBags", backpack = "voidOpenBackpack", nobags = "voidOpenNoBags", close = "voidCloseBags", show = VoidStorageFrame_LoadUI},
	{shortlabel = "Obliterum", label = "Obliterum Forge (Legion)", openAll = "obliterumOpenBags", backpack = "obliterumOpenBackpack", nobags = "obliterumOpenNoBags", close = "obliterumCloseBags", show = ObliterumForgeFrame_LoadUI},
	{shortlabel = "Scrapping", label = "Scrapping Machine (BFA)", openAll = "scrappingOpenBags", backpack = "scrappingOpenBackpack", nobags = "scrappingOpenNoBags", close = "scrappingCloseBags", show = ScrappingMachineFrame_LoadUI},
};

--------------------------------------------
-- Minimap Handler

local sqrt, abs = sqrt, abs;
local function minimapMover(self)
	self:ClearAllPoints();
	
	local uiScale = UIParent:GetScale();
	local cX, cY = GetCursorPosition();
	local mX, mY = Minimap:GetCenter();
	if (uiScale == 0) then
		cX = 0;
		cY = 0;
	else
		cX = cX/uiScale;
		cY = cY/uiScale;
	end
	
	local width, height = (cX-mX), (cY-mY);
	local dist = sqrt(width^2 + height^2);
	if ( dist < 85 ) then
		-- Get angle
		local a;
		if (width == 0) then
			a = atan(0);
		else
			a = atan(height/width);
		end
		if ( width < 0 ) then
			a = a + 180;
		end
		self:SetClampedToScreen(false);
		self:SetPoint("CENTER", Minimap, "CENTER", 80*cos(a), 80*sin(a));
	else
		self:SetClampedToScreen(true);
		self:SetPoint("CENTER", nil, "BOTTOMLEFT", cX, cY);
	end
end

local minimapFrame;

local function minimapResetPosition()
	minimapFrame:ClearAllPoints();
	minimapFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
	minimapFrame:SetUserPlaced(true);
end

local minimapdropdown;
local function minimapFrameSkeleton()
	return "button#n:CT_MinimapButton#s:32:32#mid:bl:Minimap:15:15#st:LOW", {
		"texture#all#Interface\\Addons\\CT_Library\\Images\\minimapIcon",  
		
		["onclick"] = function(self, button)
			if (button == "LeftButton") then
				module:showControlPanel("toggle");
			end
			if (button == "RightButton") then
				if (not minimapdropdown) then
					minimapdropdown = CreateFrame("Frame", "CT_MinimapDropdown", CT_MinimapButton, "UIDropDownMenuTemplate"); --L_Create_UIDropDownMenu("CT_MinimapDropdown", CT_MinimapButton)
					UIDropDownMenu_Initialize(
						minimapdropdown,
						function()
							if (UIDROPDOWNMENU_MENU_LEVEL == 1) then
								for i, mod in module:iterateModules() do
									if (i>2) then
										local info = {};
										info.text = mod.name;


										info.notCheckable = 1;
										if (mod.externalDropDown_Initialize) then
											-- shows a custom dropdown provided by the module
											info.hasArrow = 1;
											info.value = mod.name;
										else
											-- opens the customOpenFunction() if it exists, or just opens the standard module options
											info.func = mod.customOpenFunction or function()
												mod:showModuleOptions();
											end;
										end
										UIDropDownMenu_AddButton(info);
									end
								end
							elseif (_G[UIDROPDOWNMENU_MENU_VALUE] and _G[UIDROPDOWNMENU_MENU_VALUE].externalDropDown_Initialize) then
								_G[UIDROPDOWNMENU_MENU_VALUE]:externalDropDown_Initialize(UIDROPDOWNMENU_MENU_LEVEL)
							end
						end,
						"MENU"  --causes it to be like a context menu
					);
				end
				ToggleDropDownMenu(1, nil, CT_MinimapDropdown, self, -100, 0);
			end
		end,
		
		["ondragstart"] = function(self)
			self:StartMoving();
			self:SetScript("OnUpdate", minimapMover);
		end,
		
		["ondragstop"] = function(self)
			self:StopMovingOrSizing();
			self:SetScript("OnUpdate", nil);
			
			local x, y = self:GetCenter();
			module:setOption("minimapX", x);
			module:setOption("minimapY", y);
		end,
		
		["onload"] = function(self)
			local highlight = self:CreateTexture(nil, "HIGHLIGHT");
			highlight:SetAllPoints(self);
			highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight");
			highlight:SetBlendMode("ADD");
			highlight:SetVertexColor(1, 1, 1, 0.5);
			
			self:RegisterForDrag("LeftButton");
			self:SetMovable(true);

			self:SetParent(Minimap);
			
			local x, y = module:getOption("minimapX"), module:getOption("minimapY");
			if ( x and y ) then
				self:ClearAllPoints();
				self:SetPoint("CENTER", nil, "BOTTOMLEFT", x, y);
				local mX, mY = Minimap:GetCenter();
				local width, height = (x-mX), (y-mY);
				local dist = sqrt(width^2 + height^2);
				if ( dist >= 85 ) then
					self:SetClampedToScreen(true);
				end
			end
			self:RegisterForClicks("LeftButtonUp", "RightButtonDown");
			self:SetScript("OnEnter",
				function()
					GameTooltip:SetOwner(self,"ANCHOR_LEFT");
					GameTooltip:SetText("Left-click for CTMod Options");
					GameTooltip:AddLine("Right-click for quick menu", .8, .8, .8);
					GameTooltip:AddLine("Drag to move", .8, .8, .8);
					GameTooltip:Show();
				end
			);
			self:SetScript("OnLeave",
				function()
					GameTooltip:Hide();
				end
			);
		end
	}
end

local function showMinimap(enable)
	if ( not enable ) then
		if ( minimapFrame ) then
			minimapFrame:Hide();
		end
		return;
	end
	
	if ( not minimapFrame ) then
		minimapFrame = module:getFrame(minimapFrameSkeleton);
	else
		minimapFrame:Show();
	end
end

-- commented out in WoW 8.0.1; this doesn't appear to be a recognized event in the API
--module:regEvent("CONTROL_PANEL_VISIBILITY", function(event, enabled)
--	if ( minimapFrame ) then
--		if ( enabled ) then
--			minimapFrame.enabled:Show();
--			minimapFrame.disabled:Hide();
--		else
--			minimapFrame.enabled:Hide();
--			minimapFrame.disabled:Show();
--		end
--	end
--end);

--------------------------------------------
-- Slash command.

local function slashCommand(msg)
	module:showModuleOptions();
end

module:setSlashCmd(slashCommand, "/ctcore");


--------------------------------------------
-- Options

module.update = function(self, optName, value)
	self:modupdate(optName, value);
	self:chatupdate(optName, value);
	if ( optName == "init" or optName == "minimapIcon" ) then
		showMinimap(self:getOption("minimapIcon") ~= false);
	end
	if (optName == "init") then
		-- sets default options for bag automation.  Refer to helper variable for adding further automation
		for i, bagevent in ipairs(bagAutomationEvents) do
			if (bagevent.openAll) then module:setOption(bagevent.openAll,module:getOption(bagevent.openAll) ~= false); end
			if (bagevent.backpack) then module:setOption(bagevent.backpack,not not module:getOption(bagevent.backpack)); end
			if (bagevent.nobags) then module:setOption(bagevent.nobags,not not module:getOption(bagevent.nobags)); end
			if (bagevent.bank) then module:setOption(bagevent.bank,module:getOption(bagevent.bank) ~= false); end
			if (bagevent.close) then module:setOption(bagevent.close,module:getOption(bagevent.close) ~= false); end
		end
	end
end


-- Options frame
local optionsFrameList;
local bookmarks;	--used to move the scroll bar to each section for convenience
local function optionsInit()
	optionsFrameList = module:framesInit();
	bookmarks = { };
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
local function optionsAddTooltip(text)
	module:framesAddScript(optionsFrameList, "onenter", function(obj) module:displayTooltip(obj, text, "CT_ABOVEBELOW", 0, 0, CTCONTROLPANEL) end)
end
local function optionsBeginFrame(offset, size, details, data)
	module:framesBeginFrame(optionsFrameList, offset, size, details, data);
end
local function optionsEndFrame()
	module:framesEndFrame(optionsFrameList);
end
local function optionsAddFromTemplate(offset, size, details, template)
	module:framesAddFromTemplate(optionsFrameList, offset, size, details, template)
end

local function optionsAddBookmark(title, frameName)
	tinsert(bookmarks, {["title"] = title, ["obj"] = frameName});
end


local function humanizeTime(timeValue)
	-- (single letter for hour/minute/second, and shows 2 values): 1h 35m / 35m 30s
	timeValue = ceil(timeValue);
	if ( timeValue >= 3600 ) then
		-- Hours & Minutes
		local hours = floor(timeValue / 3600);
		return format("%dh %dm", hours, floor((timeValue - hours * 3600) / 60));
	elseif ( timeValue >= 60 ) then
		-- Minutes & Seconds
		return format("%dm %.2ds", floor(timeValue / 60), timeValue % 60);
	else
		-- Seconds
		return format("%ds", timeValue);
	end
end

module.frame = function()
	local updateFunc = function(self, value)
		value = (value or self:GetValue());
		local timeValue = floor( value * 10 + 0.5 ) / 10;
		if ( timeValue < 0 ) then
			self.title:SetText("Default");
		else
			self.title:SetText(humanizeTime(timeValue));
		end
		local option = self.option;
		if ( option ) then
			module:setOption(option, value);
		end
	end;
	local updateFunc2 = function(self, value)
		value = (value or self:GetValue());
		local tempValue = floor( value * 100 + 0.5 ) / 100;
		if ( tempValue < 0 ) then
			self.title:SetText("Default");
		else
			self.title:SetText(tempValue);
		end
		local option = self.option;
		if ( option ) then
			module:setOption(option, value);
		end
	end;
	local updateFunc3 = function(self, value)
		value = (value or self:GetValue());
		local tempValue = value;
		if ( tempValue <= 0 ) then
			self.title:SetText("Default");
		else
			self.title:SetText(tempValue);
		end
		local option = self.option;
		if ( option ) then
			module:setOption(option, value);
		end
	end;

	local textColor1 = "0.9:0.9:0.9";
	local textColor2 = "0.7:0.7:0.7";
	local textColor3 = "0.9:0.72:0.0";
	local offset;

	optionsInit();

	-- Tips
	optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#Tips");
	optionsAddObject( -2, 2*14, "font#t:0:%y#s:0:%s#l:13:0#r#You can use /ctcore to open this options window directly.#" .. textColor2 .. ":l");
	optionsAddObject( -2, 2*14, "font#t:0:%y#s:0:%s#l:13:0#r#You can use /hail to hail your current target. A key binding is also available for this.#" .. textColor2 .. ":l");

-- Quick Navigation
	optionsBeginFrame(-20, 60, "frame#tl:0:%y#s:0:%s#r");
		optionsAddScript("onload",
			function(frame)
				local dropdown = CreateFrame("Frame", nil, frame, "UIDropDownMenuTemplate"); -- L_Create_UIDropDownMenu("", frame);
				dropdown:SetPoint("CENTER");
				UIDropDownMenu_SetWidth(dropdown, 120);
				UIDropDownMenu_SetText(dropdown, "Skip to section...");
				UIDropDownMenu_Initialize(dropdown, module.externalDropDown_Initialize);
			end
		);
	optionsEndFrame();

-- Alternate Power Bar
	if (module:getGameVersion() >= 8) then
		optionsAddBookmark("Alternate Power Bar", "AlternatePowerBarHeading")
		optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#Alternate Power Bar#i:AlternatePowerBarHeading")
		optionsAddObject( -2, 5*14, "font#t:0:%y#s:0:%s#l:13:0#r#The game sometimes uses this bar to show the status of a quest, or your status in a fight, etc. The bar can vary in size, and its default position is centered near the bottom of the screen.#" .. textColor2 .. ":l");
		optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:powerbaraltEnabled#Use a custom position for the bar")
		optionsBeginFrame(0, 0, "collapsible#tl:0:%y#br:tr:0:%b#o:powerbaraltEnabled#i:powerbaraltCollapsible")
			optionsAddObject(  0,   26, "checkbutton#tl:40:%y#o:powerbaraltMovable#Unlock the bar")
			optionsAddObject( -2,   15, "font#tl:70:%y#v:ChatFontNormal#Move key:")
			optionsAddObject( 14,   20, "dropdown#tl:145:%y#s:100:%s#n:CTCoreDropdownPowerBarAlt#o:powerbaraltModifier:1#None#Alt#Ctrl#Shift")
			optionsAddObject(  0,   26, "checkbutton#tl:40:%y#o:powerbaraltShowAnchor#Show anchor if bar hidden and unlocked")
			optionsBeginFrame( -10,   30, "button#t:0:%y#s:180:%s#n:CT_Core_ResetPowerBarAlt_Button#v:GameMenuButtonTemplate#Reset anchor position")
				optionsAddScript("onclick",
					function(self)
						module.powerbaralt_resetPosition()
					end
				);
			optionsEndFrame()
		optionsEndFrame()
	else
		optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#Alternate Power Bar");
		optionsAddObject( -2, 5*14, "font#t:0:%y#s:0:%s#l:13:0#r#The alternate power bar settings are disabled in WoW Classic#" .. textColor2 .. ":l");
	end

-- Auction house options
	optionsAddBookmark("Auction House", "AuctionHouseHeading");
	optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#Auction House#i:AuctionHouseHeading");
	optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:auctionAltClickItem#Alt left-click to add an item to the Auctions tab");

-- Bag automation
	optionsAddBookmark("Bag Automation", "BagAutomationHeading");
	optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#Bag automation options#i:BagAutomationHeading");
	optionsAddObject( -8, 2*13, "font#t:0:%y#s:0:%s#l:13:0#r#Disable bag automation if you have other bag management addons#" .. textColor2 .. ":l");	
	optionsBeginFrame( -3, 15, "checkbutton#tl:60:%y#o:disableBagAutomation#i:disableBagAutomation#|cFFFF6666Disable bag automation");
		optionsAddTooltip({"Disable bag automation#1:0.5:0.5","Prevents conflicts with other bag management addons#0.9:0.9:0.9"})
	optionsEndFrame();
	optionsBeginFrame(0, 0, "collapsible#tl:0:%y#br:tr:0:%b#i:bagAutomationCollapsible#o:~disableBagAutomation")
		-- refer to local variable bagAutomationEvents
		for i, bagevent in ipairs(bagAutomationEvents) do
			if (bagevent.show) then
				-- Show options for all bag automation, or just the vanilla/classic ones
				-- refer to the on-load script for the next frame
				optionsAddObject( -18, 15, "font#tl:25:%y#v:GameFontNormal#i:" .. bagevent.openAll .. "Label#" .. bagevent.label);
				optionsBeginFrame( -3, 15, "checkbutton#tl:60:%y#o:" .. bagevent.openAll .. "#i:" .. bagevent.openAll .. "#Open all bags");
					optionsAddScript("onenter",
						function(self)
							GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT", 120, -5);
							GameTooltip:SetText("|cFFCCCCCCWhen the |r" .. bagevent.label .. "|cFFCCCCCC opens, open |rall|cFFCCCCCC bags");
							GameTooltip:Show();
						end
					);
					optionsAddScript("onleave",
						function(self)
							GameTooltip:Hide();
						end
					);
				optionsEndFrame();
				optionsBeginFrame(  -3, 15, "checkbutton#tl:60:%y#o:" .. bagevent.backpack .. "#i:" .. bagevent.backpack .. "#Backpack only");
					optionsAddScript("onenter",
						function(self)
							GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT", 120, -5);
							GameTooltip:SetText("|cFFCCCCCCWhen the |r" .. bagevent.label .. "|cFFCCCCCC opens, open the |rbackpack|cFFCCCCCC only");
							GameTooltip:Show();
						end
					);
					optionsAddScript("onleave",
						function(self)
							GameTooltip:Hide();
						end
					);
				optionsEndFrame();
				optionsBeginFrame(  -3, 15, "checkbutton#tl:60:%y#o:" .. bagevent.nobags .. "#i:" .. bagevent.nobags .. "#Leave bags shut");
					optionsAddScript("onenter",
						function(self)
							GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT", 120, -5);
							GameTooltip:SetText("|cFFCCCCCCWhen the |r" .. bagevent.label .. "|cFFCCCCCC opens, |rshut|cFFCCCCCC all bags");
							GameTooltip:AddLine("|cFF888888This closes already-openned bags; leave unchecked to 'do nothing'");
							GameTooltip:Show();
						end
					);
					optionsAddScript("onleave",
						function(self)
							GameTooltip:Hide();
						end
					);
				optionsEndFrame();
				if (bagevent.bank) then
					optionsBeginFrame(  -8, 15, "checkbutton#tl:60:%y#o:" .. bagevent.bank .. "#i:" .. bagevent.bank .. "#...and open all bank slots");
						optionsAddScript("onenter",
							function(self)
								GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT", 120, -5);
								GameTooltip:SetText("|cFFCCCCCCWhen the |r" .. bagevent.label .. "|cFFCCCCCC opens, open all |rbank slots");
								GameTooltip:Show();
							end
						);
						optionsAddScript("onleave",
							function(self)
								GameTooltip:Hide();
							end
						);
					optionsEndFrame();
				end	
				if (bagevent.close) then
					optionsBeginFrame(  -8, 15, "checkbutton#tl:60:%y#o:" .. bagevent.close .. "#i:" .. bagevent.close .. "#...and close when finished");
						optionsAddScript("onenter",
							function(self)
								GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT", 120, -5);
								GameTooltip:SetText("|cFFCCCCCCWhen the " .. bagevent.label .. " |rcloses|cFFCCCCCC, shut all bags");
								GameTooltip:Show();
							end
						);
						optionsAddScript("onleave",
							function(self)
								GameTooltip:Hide();
							end
						);
					optionsEndFrame()
				end
			end
		end
	optionsEndFrame()
	optionsAddObject( -18, 1*13, "font#tl:25:%y#s:0:%s#l:13:0#r#Also see CT_MailMod for bag settings#" .. textColor2 .. ":l");	

-- Camera Max Distance
	optionsAddBookmark("Camera Max Distance", "CameraMaxDistanceHeading");
	optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#Camera Max Distance#i:CameraMaxDistanceHeading");
	optionsAddObject(  0, 4*13, "font#t:0:%y#s:0:%s#l:40:0#r#Since Legion (7.0.3) you can type \n/console cameraDistanceMaxZoomFactor\n to zoom the camera further out.#" .. textColor2 .. ":l");
	optionsAddObject(  0, 4*13, "font#t:0:%y#s:0:%s#l:40:0#r#The game default is 1.9, but players often increase it to 2.6 for better situational awareness in raid fights.#" .. textColor2 .. ":l");
	optionsBeginFrame( -15,   17, "slider#tl:75:%y#n:CTCore_CameraMaxDistanceSlider#Default 1.9:1.0:2.6#1:2.6:0.1")
		optionsAddScript("onload",
			function(slider)
				local GetCVar = (C_CVar and C_CVar.GetCVar) or GetCVar;		-- retail vs. classic
				local SetCVar = (C_CVar and C_CVar.SetCVar) or SetCVar;
				local value = tonumber(GetCVar("cameraDistanceMaxZoomFactor"));
				local round =
				(
					round 
					or function(value, decimalPlaces)
						for i=1, decimalPlaces, 1 do
							value = value * 10;
						end
						local base = floor(value);
						local trim = value - base;
						if trim > 0.5 then
							value = base + 1;
						else
							value = base;
						end
						for i=1, decimalPlaces, 1 do
							value = value / 10;
						end
						return value;
					end
				);
				if (value and value >= 1 and value <= 2.6) then
					slider:SetValue(value);
					_G[slider:GetName() .. "Text"]:SetText("Current: " .. round(value,1));
				end
				slider:SetScript("OnValueChanged",
					function()
						local value = slider:GetValue()
						SetCVar("cameraDistanceMaxZoomFactor", value);
						_G[slider:GetName() .. "Text"]:SetText("Current: " .. round(value,1));
						if value > 2.0 then
							module:setOption("cameraDistanceMaxZoomFactor", value)
						else
							module:setOption("cameraDistanceMaxZoomFactor", nil)
						end
					end
				);
				
			end
		);
		optionsAddTooltip({"Camera Max Distance", "Due to a bug in the default UI, reloading without addons will reset this value to no more than |cFFFFFFFF2.0|r"})
	optionsEndFrame();


-- Casting Bar options
	optionsAddBookmark("Casting Bar", "CastingBarHeading");
	optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#Casting Bar#i:CastingBarHeading")
	optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:castingTimers#Display casting bar timers")
	optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:castingbarEnabled#Use custom casting bar position")
	optionsBeginFrame(   0,    0, "collapsible#tl:0:%y#br:tr:0:%b#o:castingbarEnabled")
		optionsAddObject(  6,   26, "checkbutton#tl:40:%y#o:castingbarMovable#Unlock the casting bar")
	optionsEndFrame()

-- Chat options
	optionsAddBookmark("Chat Features", "ChatHeading");
	optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#Chat#i:ChatHeading");

	-- Chat frame timestamps
	--optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:chatTimestamp#Display timestamps");
	--optionsAddObject( -2,   15, "font#tl:60:%y#v:ChatFontNormal#Format:");
	--optionsAddObject( 14,   20, "dropdown#tl:100:%y#s:100:%s#o:chatTimestampFormat#n:CTCoreDropdown2#12:00#12:00:00#24:00#24:00:00");
	--optionsAddObject( -2,   15, "font#tl:60:%y#v:ChatFontNormal#Format:");
	--optionsAddObject( 14,   20, "dropdown#tl:100:%y#s:100:%s#o:chatTimestampFormatBase#n:CTCore_chatTimestampFormatBaseDropDown#None#03:27#03:27:32#03:27 PM#03:27:32 PM#15:27#15:27:32");

	optionsAddObject(-15, 1*13, "font#tl:15:%y#Chat Timestamps");
	optionsAddObject(-15, 2*13, "font#tl:15:%y#r#Change how timestamps appear in chat windows, overriding the default game setting#" .. textColor2 .. ":l");
	local currentTimestampButton;
	local function addTimestampButton(yOff, ySize, xOff, xSize, label, format)
		optionsBeginFrame(yOff, ySize, "button#v:GameMenuButtonTemplate#tl:" .. xOff .. ":%y#s:" .. xSize .. ":%s#" .. label)
			optionsAddScript("onclick", function(self)
				CHAT_TIMESTAMP_FORMAT = format
				SetCVar("showTimestamps", format)
				if (currentTimestampButton) then
					currentTimestampButton:GetFontString():SetTextColor(1,1,1)
					currentTimestampButton = self
					self:GetFontString():SetTextColor(1,1,0.5)
				end
			end)
			optionsAddScript("onshow", function(self)
				if (CHAT_TIMESTAMP_FORMAT == format) then
					self:GetFontString():SetTextColor(1,1,0.5)
					currentTimestampButton = self
				else
					self:GetFontString():SetTextColor(1,1,1)
				end
			end)
			optionsAddTooltip({"Chat Timestamps", "/console showTimestamps |cffffff99" .. (format and format:gsub(" ", "|cff666633_|r") or "") .. "|r", "/run CHAT_TIMESTAMP_FORMAT = " .. (format and ("\"|cffffff99" .. format:gsub(" ", "|cff666633_|r") .. "|r\"") or "|cffffff99nil|r")})
		optionsEndFrame();	
	end
	addTimestampButton(-5, 22,  120, 80, "None", nil);
	addTimestampButton(-5, 22,  30, 80, "03:27", "%I:%M ");
	addTimestampButton(22, 22, 120, 80, "03:27 -", "%I:%M - ");
	addTimestampButton(22, 22, 210, 80, "[03:27]", "[%I:%M] ");
	addTimestampButton(-5, 22,  30, 80, "03:27:32", "%I:%M:%S ");
	addTimestampButton(22, 22, 120, 80, "03:27:32 -", "%I:%M:%S - ");
	addTimestampButton(22, 22, 210, 80, "[03:27:32]", "[%I:%M:%S] ");
	addTimestampButton(-5, 22,  30, 80, "15:27", "%H:%M ");
	addTimestampButton(22, 22, 120, 80, "15:27 -", "%H:%M - ");
	addTimestampButton(22, 22, 210, 80, "[15:27]", "[%H:%M] ");
	addTimestampButton(-5, 22,  30, 80, "15:27:32", "%H:%M:%S ");
	addTimestampButton(22, 22, 120, 80, "15:27:32 -", "%H:%M:%S - ");
	addTimestampButton(22, 22, 210, 80, "[15:27:32]", "[%H:%M:%S] ");

	-- Chat frame buttons
	optionsAddObject( -2,   26, "checkbutton#tl:10:%y#o:chatArrows#Hide the chat buttons");
	if (module:getGameVersion() >= 8) then
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:friendsMicroButton#Hide the friends (social) button");
	end

	-- Chat frame moving
	optionsAddObject(-15,   15, "font#tl:13:%y#v:ChatFontNormal#Chat frame clamping:");
	optionsAddObject( 14,   20, "dropdown#tl:125:%y#s:140:%s#o:chatClamping#n:CTCoreDropdownClamp#Game default#Can move to edges#Can move off screen");

	-- Chat frame scrolling
	optionsAddObject(-10,   26, "checkbutton#tl:10:%y#o:chatScrolling#Enable Ctrl and Shift keys when scrolling");
	optionsAddObject(  0, 3*13, "font#t:0:%y#s:0:%s#l:40:0#r#Use Ctrl and the mouse wheel to scroll one page at a time.  Use Shift and the mouse wheel to scroll to the top/bottom.#" .. textColor2 .. ":l");
	optionsAddObject( -4, 3*13, "font#t:0:%y#s:0:%s#l:40:0#r#Mouse wheel scrolling can be enabled in the game's Interface options in the Social category.#" .. textColor2 .. ":l");

	-- Chat frame input box
	optionsAddObject(-15, 1*13, "font#tl:15:%y#Chat frame input box");
	optionsAddObject( -5,   26, "checkbutton#tl:35:%y#o:chatEditHideBorder#Hide the frame texture of the input box");
	optionsAddObject(  6,   26, "checkbutton#tl:35:%y#o:chatEditHideFocus#Hide the focus texture of the input box");
	optionsAddObject( -2,   26, "checkbutton#tl:35:%y#o:chatEditMove#Move the input box to the top");
	optionsAddFrame( -10,   17, "slider#tl:75:%y#o:chatEditPosition:0#Position = <value>:0:100#0:100:1");

	-- Chat frame text fading
	optionsAddObject(-20, 1*13, "font#tl:15:%y#Chat frame text fading");
	optionsAddObject( -7,   26, "checkbutton#tl:35:%y#o:chatDisableFading#Disable fading");
	optionsAddObject(-17,   15, "font#tl:39:%y#Time visible:#" .. textColor1);
	optionsBeginFrame(  18,   17, "slider#tl:150:%y#o:chatTimeVisible:-5#:Off:10 min.#-5:600:5");
		optionsAddScript("onvaluechanged", updateFunc);
		optionsAddScript("onload", updateFunc);
	optionsEndFrame();
	optionsAddObject(-23,   15, "font#tl:39:%y#Fade duration:#" .. textColor1);
	optionsBeginFrame(  18,   17, "slider#tl:150:%y#o:chatFadeDuration:-1#:Off:1 min.#-1:60:1");
		optionsAddScript("onvaluechanged", updateFunc);
		optionsAddScript("onload", updateFunc);
	optionsEndFrame();

	-- Chat frame opacity
	do
		optionsAddObject(-20, 1*13, "font#tl:15:%y#Chat frame opacity");
		for i, optTable in ipairs(module.optChatFrameOpacity) do
			local slideOffset = -20;
			for j, tbl in ipairs(optTable.sliders) do
				optionsAddObject(slideOffset,   15, "font#tl:39:%y#" .. tbl.label .. ":#" .. textColor1);
				optionsBeginFrame(  18,   17, "slider#tl:150:%y#o:" .. tbl.option .. ":" .. tbl.default .. "#:Off:1#-0.01:1:0.01");
					optionsAddScript("onvaluechanged", updateFunc2);
					optionsAddScript("onload", updateFunc2);
				optionsEndFrame();
				slideOffset = -26;
			end

			optionsAddObject( -14, 4*13, "font#t:0:%y#s:0:%s#l:40:0#r#The game uses the default chat frame opacity for new chat frames, when the mouse is over a chat frame, and when moving chat frames.#" .. textColor2 .. ":l");
		end
	end

	-- Chat frame tab opacity
	do
		local headOffset = -10;
		optionsAddObject(-20, 1*13, "font#tl:15:%y#Chat tab opacity");
		for i, optTable in ipairs(module.optChatTabOpacity) do
			optionsAddObject(headOffset, 1*13, "font#tl:35:%y#" .. optTable.heading .. "#" .. textColor1);
			local slideOffset = -20;
			for j, tbl in ipairs(optTable.sliders) do
				optionsAddObject(slideOffset,   15, "font#tl:60:%y#" .. tbl.label .. ":#" .. textColor1);
				optionsBeginFrame(  18,   17, "slider#tl:150:%y#o:" .. tbl.option .. ":" .. tbl.default .. "#:Off:1#-0.01:1:0.01");
					optionsAddScript("onvaluechanged", updateFunc2);
					optionsAddScript("onload", updateFunc2);
				optionsEndFrame();
				slideOffset = -26;
			end
			headOffset = -20;
		end
	end

	-- Chat frame resizing
	optionsAddObject(-20, 1*13, "font#tl:15:%y#Chat frame resizing");
	optionsAddObject( -7,   26, "checkbutton#tl:35:%y#o:chatResizeEnabled2#Enable top left resize button");
	optionsAddObject(  6,   26, "checkbutton#tl:35:%y#o:chatResizeEnabled1#Enable top right resize button");
	optionsAddObject(  6,   26, "checkbutton#tl:35:%y#o:chatResizeEnabled3#Enable bottom left resize button");
	optionsAddObject(  6,   26, "checkbutton#tl:35:%y#o:chatResizeEnabled4:true#Enable bottom right resize button");
	optionsAddObject(  6,   26, "checkbutton#tl:35:%y#o:chatResizeMouseover#Show resize buttons on mouseover only");
	optionsAddObject(  6,   26, "checkbutton#tl:35:%y#o:chatMinMaxSize#Override default resize limits");

	-- Chat frame sticky chat types
	do
		optionsAddObject(-20, 1*13, "font#tl:15:%y#Sticky chat types");
		optionsAddObject(-10, 3*13, "font#t:0:%y#s:0:%s#l:30:0#r#When you open a chat frame's input box, the game will default to the last sticky chat type that you used in that input box.#" .. textColor2 .. ":l");
		local cbOffset = -7;
		local num = #(module.chatStickyTypes);
		for i = 1, num, 2 do
			local stickyInfo = module.chatStickyTypes[i];
			optionsAddObject(cbOffset,   26, "checkbutton#tl:25:%y#o:chatSticky" .. stickyInfo.chatType .. ":" .. (ChatTypeInfo[stickyInfo.chatType].sticky == 1 and "true" or "false") .. "#" .. stickyInfo.label);
			if (i ~= num) then
				stickyInfo = module.chatStickyTypes[i+1];
				optionsAddObject(26,   26, "checkbutton#tl:155:%y#o:chatSticky" .. stickyInfo.chatType .. ":" .. (ChatTypeInfo[stickyInfo.chatType].sticky == 1 and "true" or "false") .. "#" .. stickyInfo.label);
			end
			cbOffset = 6;
		end
	end

-- Duel options
	optionsAddBookmark("Duels", "DuelsHeading");
	optionsAddObject(-25,   17, "font#tl:5:%y#v:GameFontNormalLarge#Duels#i:DuelsHeading");
	optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:blockDuels#Block all duels");
	optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:blockDuelsMessage#Show message when a duel is blocked");

-- Hide Gryphons
	if (not CT_BottomBar) then
		optionsAddBookmark("Hide Gryphons", "HideGryphonsHeading");
		optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#Hide Gryphons#iHideGryphonsHeading");
		optionsAddObject( -5,   26, "checkbutton#tl:10:%y#i:hideGryphons#o:hideGryphons#Hide the Main Bar gryphons");
	else
		optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#Hide Gryphons#" .. textColor2 .. ":l");
		optionsAddObject( -5,   26, "font#tl:0:%y#v:GameFontNormal#This feature is now in CT_BottomBar#" .. textColor2 .. ":l");
	end

-- LossOfControlFrame
	if (LossOfControlFrame) then
		optionsAddBookmark("Loss of Control", "LossOfControlFrameHeading");
		optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#Loss of Control#i:LossOfControlHeading");
		optionsAddObject( -5, 2*13, "font#t:0:%y#s:0:%s#l#r#Alerts when you are stunned, polymorphed or mind-controlled#" .. textColor2 .. ":l");
		optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:showLossOfControlFrame:true#Show the alert");
		optionsBeginFrame(  6,   26, "checkbutton#tl:40:%y#o:moveLossOfControlFrame#Display in a custom location");
			optionsAddTooltip({"Display in a custom location", "Move to anywhere on the screen, or leave in the middle (default)#" .. textColor2});
		optionsEndFrame()
		optionsBeginFrame(  6,   26, "checkbutton#tl:40:%y#o:dragLossOfControlFrame#Show the dragging anchor");
			optionsAddTooltip({"Show the dragging anchor", "Show the anchor to drag into a custom position, then hide the anchor to leave it there#" .. textColor2});
		optionsEndFrame()
	end


-- Merchant options
	optionsAddBookmark("Merchant", "MerchantHeading");
	optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#Merchant#i:MerchantHeading");
	optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:merchantAltClickItem:true#Alt click a merchant's item to buy a stack");

-- Minimap Options
	optionsAddBookmark("Minimap", "MinimapHeading");
	optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#Minimap #i:MinimapHeading"); -- Need the blank after "Minimap" otherwise the word won't appear on screen.
	optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:hideWorldMap#Hide the World Map minimap button");
	optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:minimapIcon:true#Show the CTMod minimap button");
	optionsBeginFrame(   0,   30, "button#t:0:%y#s:180:%s#n:CT_Core_ResetCTModPosition_Button#v:GameMenuButtonTemplate#Reset CTMod position");
		optionsAddScript("onclick",
			function(self)
				minimapResetPosition();
			end
		);
	optionsEndFrame();
	optionsAddObject(-5, 3*13, "font#t:0:%y#s:0:%s#l#r#Note: This will place the CTMod minimap button at the center of your screen. From there it can dragged anywhere on the screen.#" .. textColor2);

-- Quests
	optionsAddBookmark("Quests", "QuestsHeading");
	optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#Quests#i:QuestsHeading");

	-- Movable Objectives Tracker
	optionsAddObject(-20, 1*13, "font#tl:15:%y#Movable Objectives Tracker#i:MovableObjectivesHeading");
	optionsAddObject( -5,   26, "checkbutton#tl:10:%y#i:watchframeEnabled#o:watchframeEnabled#Enable these options");
	optionsAddObject(  4,   26, "checkbutton#tl:40:%y#i:watchframeLocked#o:watchframeLocked:true#Lock the game's Objectives window");
	optionsAddObject(  6,   26, "checkbutton#tl:40:%y#i:watchframeShowTooltip#o:watchframeShowTooltip:true#Show drag and resize tooltips");
	if (module:getGameVersion() == CT_GAME_VERSION_CLASSIC) then
		optionsAddObject(  6,   26, "checkbutton#tl:40:%y#i:watchframeAddMinimizeButton#o:watchframeAddMinimizeButton:true#Add a minimize button (like retail)");
	end
	optionsAddObject(  6,   26, "checkbutton#tl:40:%y#i:watchframeClamped#o:watchframeClamped:true#Keep the window on screen");
	optionsAddObject(  6,   26, "checkbutton#tl:40:%y#i:watchframeShowBorder#o:watchframeShowBorder#Show the border");
	optionsAddObject(  0,   16, "colorswatch#tl:45:%y#s:16:%s#o:watchframeBackground:0,0,0,0#true");
	optionsAddObject( 14,   14, "font#tl:69:%y#v:ChatFontNormal#Background color and opacity");
	optionsBeginFrame( -10,   30, "button#t:0:%y#s:180:%s#n:CT_Core_ResetObjectivesPosition_Button#v:GameMenuButtonTemplate#Reset window position");
		optionsAddScript("onclick",
			function(self)
				module.resetWatchFramePosition();
			end
		);
	optionsEndFrame();
	optionsAddFrame( -14,   17, "slider#tl:75:%y#n:CTCoreWatchFrameScaleSlider#o:CTCore_WatchFrameScale:100#Font Size = <value>%:90%:110%#90:110:5");
	optionsAddObject( -10,  26, "checkbutton#tl:40:%y#i:watchframeChangeWidth#o:watchframeChangeWidth#Can change width of window");

	optionsAddObject(  5, 5*13, "font#t:0:%y#s:0:%s#l:70:0#r#Note: To use a wider objectives window without enabling this option, you can enable the 'Wider objectives tracker' option in the game's Interface options.#" .. textColor2 .. ":l");

	--Quest Log
	optionsAddObject(-20, 1*13, "font#tl:15:%y#Quest Log");
	optionsBeginFrame(-5,   26, "checkbutton#tl:10:%y#o:questLevels:" .. (module:getGameVersion() < 7 and "true" or "false") .. "#Display quest levels in the Quest Log#i:QuestLogHeading");
		optionsAddScript("onenter",
			function(button)
				module:displayTooltip(button, {"|cFFCCCCCCAdds |r[1] |cFFCCCCCCor |r[60+] |cFFCCCCCCin front of the quest title","|cFF999999May not take effect until you close and open the quest log"}, "ANCHOR_RIGHT",30,0);
			end
		);
	optionsEndFrame();

-- Regen Rates
	do
		local function regenSubOptions(button)
			if (button:GetChecked()) then
				CTCoreTickModLockCheckButton:SetAlpha(1);
				CTCoreTickModFormatLabel:SetAlpha(1);
				CTCoreDropdown1:SetAlpha(1);
			else
				CTCoreTickModLockCheckButton:SetAlpha(0.5);
				CTCoreTickModFormatLabel:SetAlpha(0.5);
				CTCoreDropdown1:SetAlpha(0.5);				
			end
		end
		optionsAddBookmark("Regen Tracker", "RegenTrackerHeading");
		optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#Regen Rate Tracker#i:RegenTrackerHeading");
		optionsBeginFrame( 0,   26, "checkbutton#tl:10:%y#o:tickMod#Display health/mana regeneration rates");
			optionsAddScript("onload", function(button) button:HookScript("OnClick", regenSubOptions); end);
			optionsAddScript("onshow", regenSubOptions);
		optionsEndFrame();
		optionsAddObject( -2,   14, "font#tl:43:%y#v:ChatFontNormal#n:CTCoreTickModFormatLabel#Format:");
		optionsAddObject( 14,   20, "dropdown#tl:100:%y#s:125:%s#o:tickModFormat#n:CTCoreDropdown1#Health - Mana#HP/Tick - MP/Tick#HP - MP");
		optionsAddObject(  4,   26, "checkbutton#tl:40:%y#o:tickModLock#n:CTCoreTickModLockCheckButton#Lock the regen tracker");
	end
	
-- Tooltip Relocation
	local tooltipOptionsObjects = {};
	local tooltipOptionsValue = nil;

	optionsAddBookmark("Tooltip", "TooltipHeading");
	optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#Custom Tooltip Position#i:TooltipHeading");
	optionsAddObject( -8, 2*13, "font#tl:15:%y#r#s:0:%s#This allows you to change the place where the game's default tooltip appears.#" .. textColor2 .. ":l");

	optionsAddObject(-15,   15, "font#tl:15:%y#v:ChatFontNormal#Tooltip location:");
	optionsBeginFrame(14,   20, "dropdown#tl:110:%y#s:125:%s#o:tooltipRelocation#n:CTCoreDropdownTooltipRelocation#Default#On Mouse (stationary)#On Anchor#On Mouse (following)");
		optionsAddScript("onupdate",
			function(self)
				local value = UIDropDownMenu_GetSelectedValue(self);
				if (value and value ~= tooltipOptionsValue) then
					tooltipOptionsValue = value;
					for key, table in pairs(tooltipOptionsObjects) do
						if table[value] then
			--[[				if table.dropdown then UIDropDownMenu_EnableDropDown(table.dropdown); end
							if table.button then table.button:Enable(); end
							if table.text1 then table.text1:SetTextColor(1,1,1); end
							if table.text2 then table.text2:SetTextColor(1,1,1); end
							if table.text3 then table.text3:SetTextColor(1,1,1); end
							if table.text4 then table.text4:SetTextColor(1,1,1); end
			--]]
							if table.dropdown then table.dropdown:Show(); end
							if table.button then table.button:Show(); end
							if table.text1 then table.text1:Show(); end
							if table.text2 then table.text2:Show(); end
							if table.text3 then table.text3:Show(); end
							if table.text4 then table.text4:Show(); end

						else
							if table.dropdown then table.dropdown:Hide(); end
							if table.button then table.button:Hide(); end
							if table.text1 then table.text1:Hide(); end
							if table.text2 then table.text2:Hide(); end
							if table.text3 then table.text3:Hide(); end
							if table.text4 then table.text4:Hide(); end
						end
					end
				end
			end
		);
	optionsEndFrame();
	optionsAddObject( -6,   15, "font#tl:33:%y#v:ChatFontNormal#n:CTCoreTooltipAnchorDirectionLabel#Direction:");
	optionsBeginFrame(14,   20, "dropdown#tl:110:%y#s:125:%s#o:tooltipAnchor:5#n:CTCoreDropdownTooltipAnchor#Top right#Top left#Bottom right#Bottom left#Top#Bottom");
		optionsAddScript("onload",
			function(self)
				tinsert(tooltipOptionsObjects,
					{
						["dropdown"] = self;
						["text1"] = CTCoreTooltipAnchorDirectionLabel;
						[3] = true;
					}
				)
			end
		);
	optionsEndFrame();
	optionsBeginFrame( 0,   26, "checkbutton#tl:30:%y#o:tooltipAnchorUnlock#n:CTCoreCheckboxTooltipAnchorUnlock#Unlock the anchor");
		optionsAddScript("onload",
			function(self)
				tinsert(tooltipOptionsObjects,
					{
						["button"] = self;
						["text1"] = self.text;
						[3] = true;
					}
				)
			end
		);
	optionsEndFrame();
	optionsAddObject(  50,  15, "font#tl:39:%y#n:CTCoreTooltipDistanceDescript#Distance from cursor:#" .. textColor1);
	optionsBeginFrame(-10,  17, "slider#tl:75:%y#n:CTCoreTooltipDistance#o:tooltipDistance:0#Distance = <value>:Near:Far#0:60:1");
		optionsAddScript("onload",
			function(self)
				tinsert(tooltipOptionsObjects,
					{
						["button"] = self;
						["text1"] = CTCoreTooltipDistanceText;
						["text2"] = CTCoreTooltipDistanceLow;
						["text3"] = CTCoreTooltipDistanceHight;
						["text4"] = CTCoreTooltipDistanceDescript;
						[2] = true;
						[4] = true;
					}
				)
			end
		);
	optionsEndFrame();
	optionsBeginFrame( -5,  26, "checkbutton#tl:30:%y#o:tooltipDisableFade#Hide tooltip when game starts to fade it");
		optionsAddScript("onload",
			function(self)
				tinsert(tooltipOptionsObjects,
					{
						["button"] = self;
						["text1"] = self.text;
						[1] = true;
						[2] = true;
						[3] = true;
					}
				)
			end
		);
	optionsEndFrame();

-- Trading options
	optionsAddBookmark("Trading", "TradingHeading");
	optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#Trading#i:TradingHeading");
	optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:tradeAltClickOpen#Alt left-click an item to open trade with target");
	optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:tradeAltClickAdd#Alt left-click to add an item to the trade window");
	optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:blockBankTrades#Block trades while using bank or guild bank");

	-- Reset Options
	optionsAddBookmark("Reset All", "ResetFrame");
	optionsAddFromTemplate(-20, 0, "frame#tl:0:%y#br:tr:0:%b#i:ResetFrame", "ResetTemplate")

	return "frame#all", optionsGetData();
end

--------------------------------------------
-- Options

-- used by the minimap and titan-panel plugins
function module:externalDropDown_Initialize(level, addButtonFunc)		-- customAddButtonFunc allows integration with LibUIDropDownMenu used by Titan Panel
	addButtonFunc = addButtonFunc or UIDropDownMenu_AddButton
	level = level or UIDROPDOWNMENU_MENU_LEVEL
	local info = { };
	info.text = "CT_Core";
	info.isTitle = 1;
	info.justifyH = "CENTER";
	info.notCheckable = 1;
	addButtonFunc(info, level);
	
	if (not bookmarks) then
		module:frame();
	end
	
	for __, item in ipairs(bookmarks) do
		info = { };
		info.text = item.title;
		info.notCheckable = 1;
		info.func = function()
			module:showModuleOptions();
			local obj = module.frame[item.obj]		-- not to be confused with module.frame(), which ceases to exist and is replaced by a reference to the frame itself
			if (obj) then
				local yOff = select(5, obj:GetPoint(1))
				if (yOff) then
					CT_LibraryOptionsScrollFrameScrollBar:SetValue(-yOff);
				end
			end
		end
		addButtonFunc(info, level);
	end
	
end