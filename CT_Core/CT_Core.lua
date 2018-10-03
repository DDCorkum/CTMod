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
	{shortlabel = "AH", label = "Auction House", openAll = "auctionOpenBags", backpack = "auctionOpenBackpack", nobags = "auctionOpenNoBags", close = "auctionCloseBags"},
	{shortlabel = "Bank", label = "Player Bank", openAll = "bankOpenBags", backpack = "bankOpenBackpack", nobags = "bankOpenNoBags", bank = "bankOpenBankBags", close = "bankCloseBags"},
	{shortlabel = "G-Bank", label = "Guild Bank", openAll = "gbankOpenBags", backpack = "gbankOpenBackpack", nobags = "gbankOpenNoBags", close = "gbankCloseBags"},
	{shortlabel = "Merchant", label = "Merchant Frame", openAll =  "merchantOpenBags", backpack = "merchantOpenBackpack", nobags = "merchantOpenNoBags", close = "merchantCloseBags"},
	{shortlabel = "Trading", label = "Player Trading Frame", openAll = "tradeOpenBags", backpack = "tradeOpenBackpack", nobags = "tradeOpenNoBags", close = "tradeCloseBags"},
	{shortlabel = "Void-Stg", label = "Void Storage", openAll = "voidOpenBags", backpack = "voidOpenBackpack", nobags = "voidOpenNoBags", close = "voidCloseBags"},
	{shortlabel = "Obliterum", label = "Obliterum Forge (Legion)", openAll = "obliterumOpenBags", backpack = "obliterumOpenBackpack", nobags = "obliterumOpenNoBags", close = "obliterumCloseBags"},
	{shortlabel = "Scrapping", label = "Scrapping Machine (BFA)", openAll = "scrappingOpenBags", backpack = "scrappingOpenBackpack", nobags = "scrappingOpenNoBags", close = "scrappingCloseBags"},
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

local function minimapFrameSkeleton()
	return "button#n:CT_MinimapButton#s:32:32#mid:bl:Minimap:15:15#st:LOW", {
		"texture#all#i:disabled#Interface\\AddOns\\CT_Core\\Images\\minimapIcon",
		"texture#all#i:enabled#hidden#Interface\\AddOns\\CT_Core\\Images\\minimapIconHighlight",
		
		["onclick"] = function(self)
			module:showControlPanel("toggle");
		end,
		
		["ondragstart"] = function(self)
			self:StartMoving();
			self:SetScript("OnUpdate", minimapMover);
		end,
		
		["ondragstop"] = function(self)
			self:StopMovingOrSizing();
			self:SetScript("OnUpdate", nil);
			
			local x, y = self:GetCenter();
			module:setOption("minimapX", x, true);
			module:setOption("minimapY", y, true);
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
	module:showModuleOptions(module.name);
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
			if (bagevent.openAll) then module:setOption(bagevent.openAll,module:getOption(bagevent.openAll) ~= false, true); end
			if (bagevent.backpack) then module:setOption(bagevent.backpack,not not module:getOption(bagevent.backpack), true); end
			if (bagevent.nobags) then module:setOption(bagevent.nobags,not not module:getOption(bagevent.nobags), true); end
			if (bagevent.bank) then module:setOption(bagevent.bank,module:getOption(bagevent.bank) ~= false, true); end
			if (bagevent.close) then module:setOption(bagevent.close,module:getOption(bagevent.close) ~= false, true); end
		end
	end
end


-- Options frame
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
			module:setOption(option, value, true);
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
			module:setOption(option, value, true);
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
			module:setOption(option, value, true);
		end
	end;

	local textColor1 = "0.9:0.9:0.9";
	local textColor2 = "0.7:0.7:0.7";
	local textColor3 = "0.9:0.72:0.0";
	local offset;

	optionsInit();

	-- Tips
	optionsBeginFrame(-5, 0, "frame#tl:0:%y#r#i:section1");
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#Tips");
		optionsAddObject( -2, 2*14, "font#t:0:%y#s:0:%s#l:13:0#r#You can use /ctcore to open this options window directly.#" .. textColor2 .. ":l");
		optionsAddObject( -2, 2*14, "font#t:0:%y#s:0:%s#l:13:0#r#You can use /hail to hail your current target. A key binding is also available for this.#" .. textColor2 .. ":l");

	-- Alternate Power Bar
		optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#Alternate Power Bar");
		optionsAddObject( -2, 5*14, "font#t:0:%y#s:0:%s#l:13:0#r#The game sometimes uses this bar to show the status of a quest, or your status in a fight, etc. The bar can vary in size, and its default position is centered near the bottom of the screen.#" .. textColor2 .. ":l");
		optionsAddObject( -2, 3*14, "font#t:0:%y#s:0:%s#l:13:0#r#When the bar is unlocked, use left-click to move it, and right-click to reset its position.#" .. textColor2 .. ":l");
		optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:powerbaraltEnabled#Use a custom position for the bar");
		optionsAddObject(  0,   26, "checkbutton#tl:40:%y#o:powerbaraltMovable#Unlock the bar");
		optionsAddObject( -2,   15, "font#tl:70:%y#v:ChatFontNormal#Move key:");
		optionsAddObject( 14,   20, "dropdown#tl:145:%y#s:100:%s#n:CTCoreDropdownPowerBarAlt#o:powerbaraltModifier:1#None#Alt#Ctrl#Shift");
		optionsAddObject(  0,   26, "checkbutton#tl:40:%y#o:powerbaraltShowAnchor#Show anchor if bar hidden and unlocked");
		optionsBeginFrame( -10,   30, "button#t:0:%y#s:180:%s#n:CT_Core_ResetPowerBarAlt_Button#v:GameMenuButtonTemplate#Reset anchor position");
			optionsAddScript("onclick",
				function(self)
					module.powerbaralt_resetPosition();
				end
			);
		optionsEndFrame();

	-- Auction house options
		optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#Auction House");
		optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:auctionAltClickItem#Alt left-click to add an item to the Auctions tab");

	-- Bag automation
		optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#Bag automation options");
		optionsAddObject( -8, 2*13, "font#t:0:%y#s:0:%s#l:13:0#r#Disable bag automation if you have other bag management addons#" .. textColor2 .. ":l");	
		optionsBeginFrame( -3, 15, "checkbutton#tl:60:%y#o:disableBagAutomation#i:disableBagAutomation#|cFFFF6666Disable bag automation");
			optionsAddScript("onenter",
				function(self)
					GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT", 120, -5);
					GameTooltip:SetText("|rDisables|cFFCCCCCC all bag automation by CT_Core for compatibility with other addons.");
					GameTooltip:Show();
				end
			);
			optionsAddScript("onleave",
				function(self)
					GameTooltip:Hide();
				end
			);
			optionsAddScript("onclick",
				function(self)
					if (not self:GetChecked()) then
						module:setOption("disableBagAutomation",false,true);
						for i, bagevent in ipairs(bagAutomationEvents) do
							local labelobj = _G[bagevent.openAll.."Label"];
							labelobj:SetTextColor(1,.82,0);
							labelobj:SetText(strsub(labelobj:GetText(),1,strlen(labelobj:GetText())-17));
							_G[bagevent.openAll]:Enable();
							_G[bagevent.backpack]:Enable();
							_G[bagevent.nobags]:Enable();
							if (bagevent.bank) then _G[bagevent.bank]:Enable(); end
							if (bagevent.close) then _G[bagevent.close]:Enable(); end
						end
					else
						module:setOption("disableBagAutomation",true,true);
						for i, bagevent in ipairs(bagAutomationEvents) do
							local labelobj = _G[bagevent.openAll.."Label"];
							labelobj:SetTextColor(.5,.5,.5);
							labelobj:SetText(labelobj:GetText() .. " (disabled above)");
							_G[bagevent.openAll]:Disable();
							_G[bagevent.backpack]:Disable();
							_G[bagevent.nobags]:Disable();
							if (bagevent.bank) then _G[bagevent.bank]:Disable(); end
							if (bagevent.close) then _G[bagevent.close]:Disable(); end
						end
					end
				end
			);
		optionsEndFrame();
		-- refer to local variable bagAutomationEvents
		for i, bagevent in ipairs(bagAutomationEvents) do
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
				optionsAddScript("onload",
					function(self)
						if (module:getOption("disableBagAutomation")) then
							self:Disable();
							_G[bagevent.openAll .. "Label"]:SetTextColor(.5,.5,.5);
							_G[bagevent.openAll .. "Label"]:SetText(bagevent.label .. " (disabled above)");
						end
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
				optionsAddScript("onload",
					function(self)
						if (module:getOption("disableBagAutomation")) then self:Disable(); end
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
				optionsAddScript("onload",
					function(self)
						if (module:getOption("disableBagAutomation")) then self:Disable(); end
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
					optionsAddScript("onload",
						function(self)
							if (module:getOption("disableBagAutomation")) then self:Disable(); end
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
					optionsAddScript("onload",
						function(self)
							if (module:getOption("disableBagAutomation")) then self:Disable(); end
						end
					);
				optionsEndFrame();
			end	
		end
		optionsAddObject( -18, 1*13, "font#tl:25:%y#s:0:%s#l:13:0#r#Also see CT_MailMod for bag settings#" .. textColor2 .. ":l");	

	-- Casting Bar options
		optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#Casting Bar");
		optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:castingTimers#Display casting bar timers");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:castingbarEnabled#Use custom casting bar position");
		optionsAddObject(  6,   26, "checkbutton#tl:40:%y#o:castingbarMovable#Unlock the casting bar");

	-- Chat options
		optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#Chat");

		-- Chat frame timestamps
		optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:chatTimestamp#Display timestamps");
		optionsAddObject( -2,   15, "font#tl:60:%y#v:ChatFontNormal#Format:");
		optionsAddObject( 14,   20, "dropdown#tl:100:%y#s:100:%s#o:chatTimestampFormat#n:CTCoreDropdown2#12:00#12:00:00#24:00#24:00:00");

		-- Chat frame buttons
		optionsAddObject( -2,   26, "checkbutton#tl:10:%y#o:chatArrows#Hide the chat buttons");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:friendsMicroButton#Hide the friends (social) button");

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
				optionsAddObject(cbOffset,   26, "checkbutton#tl:25:%y#o:chatSticky" .. stickyInfo.chatType .. ":" .. stickyInfo.default .. "#" .. stickyInfo.label);
				if (i ~= num) then
					stickyInfo = module.chatStickyTypes[i+1];
					optionsAddObject(26,   26, "checkbutton#tl:155:%y#o:chatSticky" .. stickyInfo.chatType .. ":" .. stickyInfo.default .. "#" .. stickyInfo.label);
				end
				cbOffset = 6;
			end
		end

	-- Duel options
		optionsAddObject(-25,   17, "font#tl:5:%y#v:GameFontNormalLarge#Duels");
		optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:blockDuels#Block all duels");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:blockDuelsMessage#Show message when a duel is blocked");

	-- Hide Gryphons
		optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#Hide Gryphons");
		if (not CT_BottomBar) then
			optionsAddObject( -5,   26, "checkbutton#tl:10:%y#i:hideGryphons#o:hideGryphons#Hide the Main Bar gryphons");
		else
			optionsAddObject( -5,   26, "font#tl:0:%y#v:GameFontNormal#This feature is now in CT_BottomBar#" .. textColor2 .. ":1");
		end

	-- Merchant options
		optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#Merchant");
		optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:merchantAltClickItem:true#Alt click a merchant's item to buy a stack");

	-- Minimap Options
		optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#Minimap "); -- Need the blank after "Minimap" otherwise the word won't appear on screen.
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

	-- Objectives
		optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#Objectives");
		optionsAddObject( -5,   26, "checkbutton#tl:10:%y#i:watchframeEnabled#o:watchframeEnabled#Enable these options");
		optionsAddObject(  4,   26, "checkbutton#tl:40:%y#i:watchframeLocked#o:watchframeLocked:true#Lock the game's Objectives window");
		optionsAddObject(  6,   26, "checkbutton#tl:40:%y#i:watchframeShowTooltip#o:watchframeShowTooltip:true#Show drag and resize tooltips");
		optionsAddObject(  6,   26, "checkbutton#tl:40:%y#i:watchframeClamped#o:watchframeClamped:true#Keep the window on screen");
		optionsAddObject(  6,   26, "checkbutton#tl:40:%y#i:watchframeShowBorder#o:watchframeShowBorder#Show the border");
		optionsAddObject(  0,   16, "colorswatch#tl:45:%y#s:16:%s#o:watchframeBackground:0,0,0,0#true");
		optionsAddObject( 14,   14, "font#tl:69:%y#v:ChatFontNormal#Background color and opacity");
		optionsBeginFrame( -14,   30, "button#t:0:%y#s:180:%s#n:CT_Core_ResetObjectivesPosition_Button#v:GameMenuButtonTemplate#Reset window position");
			optionsAddScript("onclick",
				function(self)
					module.resetWatchFramePosition();
				end
			);
		optionsEndFrame();
		optionsAddObject(-10,10*13, "font#t:0:%y#s:0:%s#l:40:0#r#NOTE: Enabling the following Objectives options may result in 'action blocked by an addon' errors. This can occur while in combat if you have some quests tracked and you open / minimize / maximize the World Map when the 'show quest objectives' option is enabled. To prevent the following options from causing an error, disable them and then reload your UI (/reload).#" .. textColor3 .. ":l");
		optionsAddObject(  0,   26, "checkbutton#tl:40:%y#i:watchframeRestoreState#o:watchframeRestoreState#Remember collapsed/expanded state");
		optionsAddObject(  6,   26, "checkbutton#tl:40:%y#i:watchframeChangeWidth#o:watchframeChangeWidth#Can change width of window");

		optionsAddObject(  5, 5*13, "font#t:0:%y#s:0:%s#l:70:0#r#Note: To use a wider objectives window without enabling this option, you can enable the 'Wider objectives tracker' option in the game's Interface options.#" .. textColor2 .. ":l");

	-- Player Notes
		optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#Player Notes");
		optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:showFriendNotes:true#Enable notes in the Friends window");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:showIgnoreNotes:true#Enable notes in the Ignore window");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:showGuildNotes:true#Enable notes in the Guild window");

	-- Quests
		optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#Quests");
		optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:questLevels#Display quest levels in the Quest Log");

	-- Regen Rates
		optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#Regen Rates");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:tickMod#Display health/mana regeneration rates");
		optionsAddObject( -2,   14, "font#tl:60:%y#v:ChatFontNormal#Format:");
		optionsAddObject( 14,   20, "dropdown#tl:100:%y#s:125:%s#o:tickModFormat#n:CTCoreDropdown1#Health - Mana#HP/Tick - MP/Tick#HP - MP");

	-- Tooltip Relocation
		optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#Tooltip Relocation");

		optionsAddObject( -8, 2*13, "font#tl:15:%y#r#s:0:%s#This allows you to change the place where the game's default tooltip appears.#" .. textColor2 .. ":l");

		optionsAddObject(-15,   15, "font#tl:15:%y#v:ChatFontNormal#Tooltip location:");
		optionsAddObject( 14,   20, "dropdown#tl:110:%y#s:125:%s#o:tooltipRelocation#n:CTCoreDropdown3#Default#On Mouse (1)#On Anchor#On Mouse (2)");

		optionsAddObject(-10,   15, "font#tl:15:%y#v:ChatFontNormal#On Mouse (1)#" .. textColor3);
		optionsAddObject( -4, 3*13, "font#tl:33:%y#r#s:0:%s#The anchor point cannot be changed, and the tooltip immediately hides when no longer over an object.#" .. textColor2 .. ":l");

		optionsAddObject(-10,   15, "font#tl:15:%y#v:ChatFontNormal#On Mouse (2)#" .. textColor3);
		optionsAddObject( -6,   15, "font#tl:33:%y#v:ChatFontNormal#Anchor point:");
		optionsAddObject( 14,   20, "dropdown#tl:110:%y#s:125:%s#o:tooltipMouseAnchor:7#n:CTCoreDropdownTooltipMouseAnchor#Top left#Top right#Bottom right#Bottom left#Top#Right#Bottom#Left#Automatic");
		optionsAddObject(  0,   26, "checkbutton#tl:30:%y#o:tooltipMouseDisableFade#Hide tooltip when game starts to fade it");

		optionsAddObject(-10,   15, "font#tl:15:%y#v:ChatFontNormal#On Anchor#" .. textColor3);
		optionsAddObject( -6,   15, "font#tl:33:%y#v:ChatFontNormal#Anchor point:");
		optionsAddObject( 14,   20, "dropdown#tl:110:%y#s:125:%s#o:tooltipFrameAnchor:1#n:CTCoreDropdownTooltipFrameAnchor#Top left#Top right#Bottom right#Bottom left#Top#Right#Bottom#Left");
		optionsAddObject(  0,   26, "checkbutton#tl:30:%y#o:tooltipFrameDisableFade#Hide tooltip when game starts to fade it");
		optionsAddObject(  0,   26, "checkbutton#tl:30:%y#o:tooltipRelocationAnchor#Show the anchor frame");
		optionsAddObject( -4, 4*13, "font#tl:33:%y#r#s:0:%s#Drag the anchor frame to change where 'On Anchor' style tooltips are displayed. Right-click the anchor frame to change the tooltip's anchor point.#" .. textColor2 .. ":l");
		optionsBeginFrame(  -5,   30, "button#t:0:%y#s:180:%s#n:CT_Core_ResetAnchorPosition_Button#v:GameMenuButtonTemplate#Reset anchor position");
			optionsAddScript("onclick",
				function(self)
					CT_Core_ResetTooltipAnchor();
				end
			);
		optionsEndFrame();

	-- Trading options
		optionsAddObject(-20,   17, "font#tl:5:%y#v:GameFontNormalLarge#Trading");
		optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:tradeAltClickOpen#Alt left-click an item to open trade with target");
		optionsAddObject(  6,   26, "checkbutton#tl:10:%y#o:tradeAltClickAdd#Alt left-click to add an item to the trade window");
		optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:blockBankTrades#Block trades while using bank or guild bank");
	optionsEndFrame();

	-- Reset Options
	optionsBeginFrame(-20, 0, "frame#tl:0:%y#br:tr:0:%b");
		optionsAddObject(  0,   17, "font#tl:5:%y#v:GameFontNormalLarge#Reset Options");
		optionsAddObject( -5,   26, "checkbutton#tl:10:%y#o:resetAll#Reset options for all of your characters");
		optionsBeginFrame(   0,   30, "button#t:0:%y#s:120:%s#v:UIPanelButtonTemplate#Reset options");
			optionsAddScript("onclick",
				function(self)
					if (module:getOption("resetAll")) then
						CT_CoreOptions = {};
					else
						if (not CT_CoreOptions or not type(CT_CoreOptions) == "table") then
							CT_CoreOptions = {};
						else
							CT_CoreOptions[module:getCharKey()] = nil;
						end
					end
					ConsoleExec("RELOADUI");
				end
			);
		optionsEndFrame();
		optionsAddObject(  0, 3*13, "font#t:0:%y#s:0:%s#l#r#Note: This will reset the options to default and then reload your UI.#" .. textColor2);
	optionsEndFrame();

	return "frame#all", optionsGetData();
end