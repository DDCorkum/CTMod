------------------------------------------------
--                CT_PartyBuffs               --
--                                            --
-- Simple addon to display buffs and debuffs  --
-- of party members at their party portraits. --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
------------------------------------------------

--------------------------------------------
-- Initialization

local module = select(2, ...);
local _G = getfenv(0);

local MODULE_NAME = "CT_PartyBuffs";
local MODULE_VERSION = strmatch(GetAddOnMetadata(MODULE_NAME, "version"), "^([%d.]+)");

module.name = MODULE_NAME;
module.version = MODULE_VERSION;

CT_Library:registerModule(module);
_G[MODULE_NAME] = module;


--------------------------------------------
-- Buttons

local CT_MAX_PARTY_BUFFS = 14;
local CT_MAX_PARTY_DEBUFFS = 6;
local CT_MAX_PET_BUFFS = 9;

local buffPool = CreateFramePool("Button", nil, "CT_PartyBuffButtonTemplate")
local debuffPool = CreateFramePool("Button", nil, "CT_PartyDebuffButtonTemplate")

local partyFrames = {}	-- populated by OnLoad() funcs below
local petFrame

local numBuffs, numDebuffs, numPetBuffs, layout		-- options used in createAndAnchorButtons() and its helper, anchorFirstBuffAndDebuff()

-- Helper intended only for use in createAndAnchorButtons(); accepts nil if there are no buttons of a given kind
local function anchorFirstBuffAndDebuff(buff, debuff)
	if (buff) then
		if (layout == 1 or layout == 3) then
			buff:SetPoint("TOPLEFT", 0, 0)
		else
			buff:SetPoint("TOPLEFT", 75, 38)
		end
	end
	if (debuff) then
		if (layout == 1) then
			debuff:SetPoint("TOPLEFT", 75, 38)
		elseif (layout == 2 or layout == 3 and not buff) then
			debuff:SetPoint("TOPLEFT", 0, 0)
		else
			debuff:SetPoint("TOPLEFT", 0, -18)
		end
	end
end

-- Acquires/releases buttons and anchors them
local function createAndAnchorButtons()

	for __, frame in ipairs(partyFrames) do
		
		-- Acquire buff buttons, and anchor all but the first
		local count = #frame.buffs
		while (count < numBuffs and count < CT_MAX_PARTY_BUFFS) do
			local btn = buffPool:Acquire()
			btn:SetParent(frame)
			if (count > 0) then
				btn:SetPoint("LEFT", frame.buffs[count], "RIGHT", 2, 0)
			end
			count = count + 1
			btn.id = count
			btn.unit = frame.unit
			frame.buffs[count] = btn
		end
		while (count > numBuffs) do
			buffPool:Release(tremove(frame.buffs))
			count = count - 1
		end
		
		-- Acquire debuff buttons, and anchor all but the first
		count = #frame.debuffs
		while (count < numDebuffs and count < CT_MAX_PARTY_DEBUFFS) do
			local btn = debuffPool:Acquire()
			btn:SetParent(frame)
			if (count > 0) then
				btn:SetPoint("LEFT", frame.debuffs[count], "RIGHT", 2, 0)
			end
			count = count + 1
			btn.id = count
			btn.unit = frame.unit
			frame.debuffs[count] = btn
		end
		while (count > numDebuffs) do
			debuffPool:Release(tremove(frame.debuffs))
			count = count - 1
		end
		
		-- Anchor the first buff and debuff buttons
		anchorFirstBuffAndDebuff(frame.buffs[1], frame.debuffs[1])
	end
	
	-- Pet
	do
		-- Acquire buff buttons, and anchor all but the first
		local count = #petFrame.buffs
		while (count < numPetBuffs and count < CT_MAX_PET_BUFFS) do
			local btn = buffPool:Acquire()
			btn:SetParent(petFrame)
			if (count > 0) then
				btn:SetPoint("LEFT", petFrame.buffs[count], "RIGHT", 2, 0)
			end
			count = count + 1
			btn.id = count
			btn.unit = "pet"
			petFrame.buffs[count] = btn
		end
		while (count > numPetBuffs) do
			buffPool:Release(tremove(petFrame.buffs))
			count = count - 1
			if (count == 0 and PetFrameDebuff1) then
				-- put the Blizzard frame back where it belongs
				PetFrameDebuff1:SetPoint("TOPLEFT", petFrame, "TOPLEFT", 0, 0)
			end
		end
		
		-- Anchor the first buff button and the default Blizzard debuff button
		anchorFirstBuffAndDebuff(petFrame.buffs[1], PetFrameDebuff1)
	end
end

local function setBuffSize(size)
	size = size + 15
	for btn in buffPool:EnumerateActive() do
		btn:SetSize(size, size)
	end
	for __, btn in buffPool:EnumerateInactive() do
		btn:SetSize(size, size)
	end	
end

local function setDebuffSize(size)
	size = size + 15
	for btn in debuffPool:EnumerateActive() do
		btn:SetSize(size, size)
	end
	for __, btn in debuffPool:EnumerateInactive() do
		btn:SetSize(size, size)
	end
	
	if (PetFrameDebuff1 and PetFrameDebuff2 and PetFrameDebuff3 and PetFrameDebuff4) then
		PetFrameDebuff1:SetSize(size, size)
		PetFrameDebuff2:SetSize(size, size)
		PetFrameDebuff3:SetSize(size, size)
		PetFrameDebuff4:SetSize(size, size)
	end
end

local function setDebuffBorder(show)
	for btn in debuffPool:EnumerateActive() do
		btn.Border:SetShown(show)
	end
	for __, btn in debuffPool:EnumerateInactive() do
		btn.Border:SetShown(show)
	end
end


--------------------------------------------
-- Aura Manager

local buffFilter, debuffFilter		-- filters used in refreshBuffs() and object handlers 

local ticker				-- calls refreshBuffs() every 0.25 sec while either the pet frame or party frames are shown
local triggers = {}			-- list of party frames requiring an update since the last call

local function refreshBuffs()
	for frame in pairs(triggers) do
		for i, button in ipairs(frame.buffs) do
			local name, icon = UnitAura(frame.unit, i, buffFilter)
			if (name) then
				button.Icon:SetTexture(icon)
				button:Show()
			else
				button:Hide()
			end
		end

		for i, button in ipairs(frame.debuffs) do
			local name, icon, count, debuffType = UnitAura(frame.unit, i, debuffFilter)
			if (name) then
				button.Icon:SetTexture(icon)
				button.Count:SetText(count > 1 and count or "")
				local color = DebuffTypeColor[debuffType or "none"]
				button.Border:SetVertexColor(color.r, color.g, color.b)
				button:Show()
			else
				button:Hide()
			end
		end
	end
	wipe(triggers)
end

local function triggerNextUpdate(self)
	triggers[self] = true
end

local function refreshAllBuffs()
	for __, frame in ipairs(partyFrames) do
		if (frame:IsVisible()) then
			triggers[frame] = true
		end
	end
	if (petFrame:IsVisible()) then
		triggers[petFrame] = true
	end
	refreshBuffs()
end

local function setBuffFilter(value)
	buffFilter = value == 1 and "HELPFUL" or "HELPFUL|RAID"
end

local function setDebuffFilter(value)
	debuffFilter = value == 1 and "HARMFUL" or "HARMFUL|RAID"
end

--------------------------------------------
-- Handlers

function CT_PartyMemberFrame_OnLoad(self)
	local id = self:GetID();
	partyFrames[id] = self
	self.unit = "party" .. self:GetID()
	self:SetScript("OnEvent", triggerNextUpdate)
	self.buffs = {}
	self.debuffs = {}
end

function CT_PartyMemberFrame_OnShow(self)
	triggerNextUpdate(self)
	refreshBuffs()
	ticker = ticker or C_Timer.NewTicker(0.25, refreshBuffs) 
	self:RegisterUnitEvent("UNIT_AURA", self.unit)
end

function CT_PartyMemberFrame_OnHide(self)
	triggers[self] = nil
	if (ticker and not PetFrame:IsVisible() and not PartyMemberFrame1:IsVisible()) then
		ticker:Cancel()
		ticker = nil
	end
	self:UnregisterEvent("UNIT_AURA")
end

function CT_PartyPetFrame_OnLoad(self)
	petFrame = self
	self.unit = "party" .. self:GetID() .. "pet"
	self.isPet = true
	self:SetScript("OnEvent", CT_PartyBuffs_TriggerNextUpdate)
	self.buffs = {}
	self.debuffs = {} -- The addon doesn't create pet debuff icons; however, this empty table is necessary for refreshBuffs()
	
	CT_PetBuffFrame:SetPoint("TOPLEFT", PetFrame, "TOPLEFT", 48, -42)
end

-- the code is exactly the same
CT_PartyPetFrame_OnShow = CT_PartyMemberFrame_OnShow
CT_PartyPetFrame_OnHide = CT_PartyMemberFrame_OnHide


function CT_PartyBuffButton_OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetUnitBuff(self.unit, self.id, self.isBuff and buffFilter or debuffFilter)
end

function CT_PartyDebuffButton_OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetUnitBuff(self.unit, self.id, debuffFilter)
end


--------------------------------------------
-- Hide the default buff tooltip when icons are already present

hooksecurefunc("PartyMemberBuffTooltip_Update", function(self)
	if ( ( self.unit == "pet" and numPetBuffs > 0 ) or ( self.unit ~= "pet" and numBuffs > 0 ) ) then
		PartyMemberBuffTooltip:Hide();
	end
end)

--------------------------------------------
-- Slash command.

local function slashCommand(msg)
	module:showModuleOptions(module.name);
end

module:setSlashCmd(slashCommand, "/ctpb", "/ctparty", "/ctpartybuffs");


--------------------------------------------
-- Options Panel

function module:frame()
	local options = {};
	local yoffset = 5;
	local ysize;

	-- Tips
	ysize = 70;
	options["frame#tl:0:-" .. yoffset .. "#br:tr:0:-".. (yoffset + ysize)] = {
		"font#tl:5:0#v:GameFontNormalLarge#Tips",
		"font#t:0:-25#s:0:30#l:13:0#r#You can use /ctpb, /ctparty, or /ctpartybuffs to open this option window directly.#0.6:0.6:0.6:l",
	};
	yoffset = yoffset + ysize;

	-- General Options
	ysize = 160;
	options["frame#tl:0:-" .. yoffset .. "#br:tr:0:-".. (yoffset + ysize)] = {
		"font#tl:5:0#v:GameFontNormalLarge#General Options",
		"slider#t:0:-45#s:190:17#o:numBuffs:4#Buffs Displayed - <value>#0:" .. CT_MAX_PARTY_BUFFS .. ":1",
		"slider#t:0:-80#s:190:17#o:numDebuffs:6#Debuffs Displayed - <value>#0:" .. CT_MAX_PARTY_DEBUFFS .. ":1",
		"slider#t:0:-115#s:190:17#o:numPetBuffs:4#Pet Buffs Displayed - <value>#0:" .. CT_MAX_PET_BUFFS .. ":1"
	};
	yoffset = yoffset + ysize;

	-- What to show?
	ysize = 90;
	options["frame#tl:0:-" .. yoffset .. "#br:tr:0:-".. (yoffset + ysize)] = {
		"font#tl:5:0#v:GameFontNormalLarge#What to show?",
		"font#tr:tl:60:-30#v:GameFontNormal#Buffs: #0.9:0.9:0.9:l",
		"font#tr:tl:60:-60#v:GameFontNormal#Debuffs: #0.9:0.9:0.9:l",
		"dropdown#tl:tl:60:-30#s:95:17#o:buffType:1#n:CT_PartyBuffs_BuffTypeDropdown#All buffs#Buffs I can cast",
		"dropdown#tl:tl:60:-60#s:95:17#o:debuffType:1#n:CT_PartyBuffs_DebuffTypeDropdown#All debuffs#Debuffs I can remove",
		["checkbutton#tl:tl:210:-60#s:17:17#o:debuffBorder:true#Borders"] = { onshow = function(btn) module:displayTooltip(btn, {"Borders", "Adds a border to indicate a |cFF9600FFcurse|r, |cFF966400disease|r, |cFF3296FFmagic|r, |cFF009600poison|r or |cFFC80000other|r type."}, "CT_ABOVEBELOW", 0, 0, CTCONTROLPANEL) end }
	};
	yoffset = yoffset + ysize;

	-- Position of the buffs and debuffs
	ysize = 70;
	options["frame#tl:0:-" .. yoffset .. "#br:tr:0:-".. (yoffset + ysize)] = {
		"font#tl:5:0#v:GameFontNormalLarge#Layout",
		"dropdown#t:0:-30#s:190:17#o:layout:1#n:CT_PartyBuffs_LayoutDropdown#Buffs underneath, and debuffs in the top-right#Debuffs underneath, and buffs in the top-right#Both buffs and debuffs underneath",
	};
	yoffset = yoffset + ysize;
	
	-- Size
	ysize = 80;
	options["frame#tl:0:-" .. yoffset .. "#br:tr:0:-".. (yoffset + ysize)] = {
		"font#tl:5:0#v:GameFontNormalLarge#Size",
		"slider#tr:t:-20:-45#s:120:17#o:buffSize:0#Buffs:" .. SMALL .. ":" .. LARGE .. "#-1:1:1",
		"slider#tl:t:20:-45#s:120:17#o:debuffSize:0#Debuffs:" .. SMALL .. ":" .. LARGE .. "#-1:1:1",
	};
	yoffset = yoffset + ysize;


	return "frame#all", options;
end

--------------------------------------------
-- Options Management

function module:update(type, value)
	if ( type == "init" ) then
	
		-- Create the right number of buff/debuff buttons
		numBuffs = module:getOption("numBuffs") or 4
		numDebuffs = module:getOption("numDebuffs") or 6
		numPetBuffs = module:getOption("numPetBuffs") or 4
		buffType = module:getOption("buffType") or 1
		debufftype = module:getOption("debuffType") or 1
		layout = module:getOption("layout") or 1
		createAndAnchorButtons()
		
		-- Set the size for each frame
		setBuffSize(module:getOption("buffSize") or 0)
		setDebuffSize(module:getOption("debuffSize") or 0)
		
		-- Hide the filter if the user has turned it off
		setDebuffBorder(module:getOption("debuffBorder") ~= false)
		
		-- Set the filters
		setBuffFilter(module:getOption("buffType") or 1)
		setDebuffFilter(module:getOption("debuffType") or 1)
						
	elseif ( type == "numBuffs" ) then
		numBuffs = value
		createAndAnchorButtons()
		refreshAllBuffs()
	elseif ( type == "numDebuffs" ) then
		numDebuffs = value
		createAndAnchorButtons()
		refreshAllBuffs()
	elseif ( type == "numPetBuffs" ) then
		numPetBuffs = value
		createAndAnchorButtons()
		refreshAllBuffs()
	elseif ( type == "layout" ) then
		layout = value
		createAndAnchorButtons()
	elseif ( type == "buffSize" ) then
		setBuffSize(value)
	elseif (type == "debuffSize" ) then
		setDebuffSize(value)
	elseif (type == "debuffBorder" ) then
		setDebuffBorder(value)
		refreshAllBuffs()
	elseif ( type == "buffType" ) then
		setBuffFilter(value)
		refreshAllBuffs()
	elseif ( type == "debuffType" ) then
		setDebuffFilter(value)
		refreshAllBuffs()
	end
end
