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

local module = { };
local _G = getfenv(0);

local MODULE_NAME = "CT_PartyBuffs";
local MODULE_VERSION = strmatch(GetAddOnMetadata(MODULE_NAME, "version"), "^([%d.]+)");

module.name = MODULE_NAME;
module.version = MODULE_VERSION;

_G[MODULE_NAME] = module;
CT_Library:registerModule(module);

--------------------------------------------
-- General Mod Code (recode imminent!)
CT_NUM_PARTY_BUFFS = 14;
CT_NUM_PARTY_DEBUFFS = 6;
CT_NUM_PET_BUFFS = 9;

local numBuffs, numDebuffs, numPetBuffs, buffType, debuffType = 4, 6, 4, 1, 1	-- options

local ticker			-- calls CT_PartyBuffs_RefreshBuffs every 0.25 sec while either the pet frame or party frames are shown
local triggers = {}		-- list of party frames requiring an update since the last call

local function CT_PartyBuffs_RefreshBuffs()
	for frame in pairs(triggers) do
		if (frame.isPet) then
			local numShown
			for i=1, numPetBuffs do
				local button = frame["Buffs" .. i]
				local name, icon = UnitBuff(frame.unit, i, buffType == 2 and "RAID" or "")
				if (name) then
					button.Icon:SetTexture(icon)
					button:Show()
				else
					numShown = i-1
					break
				end
			end
			
			for i=numShown+1, CT_NUM_PET_BUFFS do
				frame["Buff" .. i]:Hide()
			end
		else
			local numShown
			for i=1, numBuffs do
				local button = frame["Buffs" .. i]
				local name, icon = UnitBuff(frame.unit, i, buffType == 2 and "RAID" or "")
				if (name) then
					button.Icon:SetTexture(icon)
					button:Show()
				else
					numShown = i-1
					break
				end
			end

			for i=numShown+1, CT_NUM_PARTY_BUFFS do
				frame["Buff" .. i]:Hide()
			end

			for i=1, numDebuffs do
				local button = frame["Buffs" .. i]
				local name, icon, count, debuffType = UnitBuff(frame.unit, i, debuffType == 2 and "RAID" or "")
				if (name) then
					button.Icon:SetTexture(icon)
					button.Count:SetText(count)
					local color = DebuffTypeColor[debuffType or "none"]
					button.Border:SetVertexColor(color.r, color.g, color.b)
					button:Show()
				else
					numShown = i-1
				end
			end

			for i=numShown+1, CT_NUM_PARTY_DEBUFFS do
				frame["Debuff" .. i]:Hide()
			end
		end
	end
	wipe(triggers)
end

local function CT_PartyBuffs_TriggerNextUpdate(self)
	triggers[self] = true
end

function CT_PartyMemberFrame_OnLoad(self)
	self.unit = "party" .. self:GetID()
	self:SetScript("OnEvent", CT_PartyBuffs_TriggerNextUpdate)
end

function CT_PartyMemberFrame_OnShow(self)
	triggers[self] = true
	CT_PartyBuffs_RefreshBuffs()
	ticker = ticker or C_Timer.NewTicker(0.25, CT_PartyBuffs_RefreshBuffs) 
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
	self.unit = "party" .. self:GetID() .. "pet"
	self.isPet = true
	self:SetScript("OnEvent", CT_PartyBuffs_TriggerNextUpdate)
	
	CT_PetBuffFrame:SetPoint("TOPLEFT", PetFrame, "TOPLEFT", 48, -42)
	if (module:getGameVersion() >= 8) then
		-- this was causing errors in classic; more investigation required
		PetFrameDebuff1:SetPoint("TOPLEFT", PetFrame, "TOPLEFT", 48, -59)
	end
end

-- the code is exactly the same
CT_PartyPetFrame_OnShow = CT_PartyMemberFrame_OnShow
CT_PartyPetFrame_OnHide = CT_PartyMemberFrame_OnHide
	

function CT_PartyMemberBuffTooltip_Update(isPet)
		if ( ( isPet and numPetBuffs > 0 ) or ( not isPet and numBuffs > 0 ) ) then
			PartyMemberBuffTooltip:Hide();
		end
	end

hooksecurefunc("PartyMemberBuffTooltip_Update", CT_PartyMemberBuffTooltip_Update);

--------------------------------------------
-- Slash command.

local function slashCommand(msg)
	module:showModuleOptions(module.name);
end

module:setSlashCmd(slashCommand, "/ctpb", "/ctparty", "/ctpartybuffs");

--------------------------------------------
-- Options Frame Code
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
		"slider#t:0:-45#s:190:17#o:numBuffs:4#Buffs Displayed - <value>#0:14:1",
		"slider#t:0:-80#s:190:17#o:numDebuffs:6#Debuffs Displayed - <value>#0:6:1",
		"slider#t:0:-115#s:190:17#o:numPetBuffs:4#Pet Buffs Displayed - <value>#0:14:1"
	};
	yoffset = yoffset + ysize;

	-- What to show?
	ysize = 70;
	options["frame#tl:0:-" .. yoffset .. "#br:tr:0:-".. (yoffset + ysize)] = {
		"font#tl:5:0#v:GameFontNormalLarge#What to show?",
		"font#tr:t:-30:-30#v:GameFontNormal#Buffs: #0.9:0.9:0.9:l",
		"font#tr:t:-30:-60#v:GameFontNormal#Debuffs: #0.9:0.9:0.9:l",
		"dropdown#tl:t:-28:-30#s:95:17#o:buffType:1#n:CT_PartyBuffs_BuffTypeDropdown#All buffs#Buffs I can cast",
		"dropdown#tl:t:-28:-60#s:95:17#o:debuffType:1#n:CT_PartyBuffs_DebuffTypeDropdown#All Debuffs#Debuffs I can remove",
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

local function initLayout()
	for i=1, 4 do
		local frame = _G["CT_PartyBuffFrame"..i]
		
		local frame0 = frame.Buff1
		for j=2, CT_NUM_PARTY_BUFFS do
			local framei = frame["Buff"..j]
			framei:SetPoint("LEFT", frame0, "RIGHT", 2, 0)
			frame0 = framei
		end
		
		frame0 = frame.Debuff1
		for j=2, CT_NUM_PARTY_DEBUFFS do
			local framei = frame["Debuff"..j]
			framei:SetPoint("LEFT", frame0, "RIGHT", 2, 0)
			frame0 = framei
		end
	end
	
	-- same thing on a smaller scale for the pet frame
	local frame = CT_PetBuffFrame
	frame0 = frame.Buff1
	frame0:SetPoint("TOPLEFT", 0, 0) -- this is set once only, unlike the party buffs/debuffs that change in updateLayout()
	for j=2, CT_NUM_PET_BUFFS do
		local framei = frame["Buff"..j]
		framei:SetPoint("LEFT", frame0, "RIGHT", 2, 0)
		frame0 = framei
	end
end

local function updateLayout(value)
	if (value == 2) then
		CT_PartyBuffFrame1.Buff1:SetPoint("TOPLEFT", 75, 38);
		CT_PartyBuffFrame2.Buff1:SetPoint("TOPLEFT", 75, 38);
		CT_PartyBuffFrame3.Buff1:SetPoint("TOPLEFT", 75, 38);
		CT_PartyBuffFrame4.Buff1:SetPoint("TOPLEFT", 75, 38);
		CT_PartyBuffFrame1.Debuff1:SetPoint("TOPLEFT", 0, 0);
		CT_PartyBuffFrame2.Debuff1:SetPoint("TOPLEFT", 0, 0);
		CT_PartyBuffFrame3.Debuff1:SetPoint("TOPLEFT", 0, 0);
		CT_PartyBuffFrame4.Debuff1:SetPoint("TOPLEFT", 0, 0);
	elseif (value == 3) then
		CT_PartyBuffFrame1.Buff1:SetPoint("TOPLEFT", 0, 0);
		CT_PartyBuffFrame2.Buff1:SetPoint("TOPLEFT", 0, 0);
		CT_PartyBuffFrame3.Buff1:SetPoint("TOPLEFT", 0, 0);
		CT_PartyBuffFrame4.Buff1:SetPoint("TOPLEFT", 0, 0);
		CT_PartyBuffFrame1.Debuff1:SetPoint("TOPLEFT", 0, -18);
		CT_PartyBuffFrame2.Debuff1:SetPoint("TOPLEFT", 0, -18);
		CT_PartyBuffFrame3.Debuff1:SetPoint("TOPLEFT", 0, -18);
		CT_PartyBuffFrame4.Debuff1:SetPoint("TOPLEFT", 0, -18);
	else	-- value == 1 or nil, default
		CT_PartyBuffFrame1.Buff1:SetPoint("TOPLEFT", 0, 0);
		CT_PartyBuffFrame2.Buff1:SetPoint("TOPLEFT", 0, 0);
		CT_PartyBuffFrame3.Buff1:SetPoint("TOPLEFT", 0, 0);
		CT_PartyBuffFrame4.Buff1:SetPoint("TOPLEFT", 0, 0);
		CT_PartyBuffFrame1.Debuff1:SetPoint("TOPLEFT", 75, 38);
		CT_PartyBuffFrame2.Debuff1:SetPoint("TOPLEFT", 75, 38);
		CT_PartyBuffFrame3.Debuff1:SetPoint("TOPLEFT", 75, 38);
		CT_PartyBuffFrame4.Debuff1:SetPoint("TOPLEFT", 75, 38);
	end
end

local function setBuffSize(value)
	if (value) then			-- value is nil if just using default; in which case no actions should be taken.
		local size = 15 + value
		for i=1, 4 do
			local frame = _G["CT_PartyBuffFrame" .. i]
			for j=1, CT_NUM_PARTY_BUFFS do
				frame["Buff" .. j]:SetSize(size, size)
			end
		end
		for j=1, CT_NUM_PET_BUFFS do
			CT_PetBuffFrame["Buff" .. j]:SetSize(size, size)
		end
	end
end

local function setDebuffSize(value)
	if (value) then			-- value is nil if just using default; in which case no actions should be taken.
		local size = 15 + value
		for i=1, 4 do
			local frame = _G["CT_PartyBuffFrame" .. i]
			for j=1, CT_NUM_PARTY_DEBUFFS do
				frame["Debuff" .. j]:SetSize(size, size)
			end
		end
	end
end

function module:update(type, value)
	if ( type == "init" ) then
		initLayout()
		updateLayout()
		for opt, val in self:enumerateOptions() do
			self:update(opt, val)
		end
	elseif ( type == "numBuffs" ) then
		numBuffs = value
	elseif ( type == "numDebuffs" ) then
		numDebuffs = value
	elseif ( type == "numPetBuffs" ) then
		numPetBuffs = value
	elseif ( type == "buffType" ) then
		buffType = value
	elseif ( type == "debuffType" ) then
		debuffType = value
	elseif ( type == "layout" ) then
		updateLayout(value)
	elseif ( type == "buffSize" ) then
		setBuffSize(value)
	elseif (type == "debuffSize" ) then
		setDebuffSize(value)
	end
end
