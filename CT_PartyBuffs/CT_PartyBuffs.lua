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

local numBuffs, numDebuffs, numPetBuffs, buffType, debuffType;

function CT_PartyBuffs_OnLoad(self)
	if (module:getGameVersion() == CT_GAME_VERSION_RETAIL) then
		-- this was causing errors in classic; more investigation required
		PetFrameDebuff1:SetPoint("TOPLEFT", PetFrame, "TOPLEFT", 48, -59);
	end
end

function CT_PartyBuffs_PetFrame_OnLoad(self)
	CT_PetBuffFrame:SetPoint("TOPLEFT", PetFrame, "TOPLEFT", 48, -42);
end

function CT_PartyBuffs_RefreshBuffs(self, elapsed)
	self.update = self.update + elapsed;
	if ( self.update > 0.5 ) then
		self.update = 0.5 - self.update;
		local name = self:GetName();
			local i;
			
		if ( numBuffs == 0 ) then
			for i = 1, CT_NUM_PARTY_BUFFS, 1 do
				_G[name .. "Buff" .. i]:Hide();
			end
			return;
		end
		for i = 1, CT_NUM_PARTY_BUFFS, 1 do
			if ( i > numBuffs ) then
				_G[name .. "Buff" .. i]:Hide();
			else
				local _, bufftexture = UnitBuff("party" .. self:GetID(), i, (buffType == 2 and "RAID") or "");
				if ( bufftexture ) then
					_G[name .. "Buff" .. i .. "Icon"]:SetTexture(bufftexture);
					_G[name .. "Buff" .. i]:Show();
				else
					_G[name .. "Buff" .. i]:Hide();
				end
				
				if ( i <= 4 ) then
					_G["PartyMemberFrame" .. self:GetID() .. "Debuff" .. i]:Hide();
				end
				if ( i <= CT_NUM_PARTY_DEBUFFS ) then
					if ( i > numDebuffs ) then
						_G[name .. "Debuff" .. i]:Hide();
					else
						local _, debufftexture, debuffApplications, debuffType = UnitDebuff("party" .. self:GetID(), i, (debuffType == 2 and "RAID") or "");
						if ( debufftexture ) then
							local color;
							if ( debuffApplications > 1 ) then
								_G[name .. "Debuff" .. i .. "Count"]:SetText(debuffApplications);
							else
								_G[name .. "Debuff" .. i .. "Count"]:SetText("");
							end
							if ( debuffType ) then
								color = DebuffTypeColor[debuffType];
							else
								color = DebuffTypeColor["none"];
							end
							_G[name .. "Debuff" .. i .. "Icon"]:SetTexture(debufftexture);
							_G[name .. "Debuff" .. i]:Show();
							_G[name .. "Debuff" .. i .. "Border"]:SetVertexColor(color.r, color.g, color.b);
						else
							_G[name .. "Debuff" .. i]:Hide();
						end
					end
				end
			end
		end
	end
end

function CT_PartyBuffs_RefreshPetBuffs(self, elapsed)
	self.update = self.update + elapsed;
	if ( self.update > 0.5 ) then
		self.update = 0.5 - self.update
		local i;
		if ( numPetBuffs == 0 ) then
			for i = 1, CT_NUM_PET_BUFFS, 1 do
				_G[self:GetName() .. "Buff" .. i]:Hide();
			end
			return;
		end
		local _, _, bufftexture;
		for i = 1, CT_NUM_PET_BUFFS, 1 do
			if ( i > numPetBuffs ) then
				_G[self:GetName() .. "Buff" .. i]:Hide();
			else
				_, bufftexture = UnitBuff("pet", i);
				if ( bufftexture ) then
					_G[self:GetName() .. "Buff" .. i .. "Icon"]:SetTexture(bufftexture);
					_G[self:GetName() .. "Buff" .. i]:Show();
				else
					_G[self:GetName() .. "Buff" .. i]:Hide();
				end
			end
		end
	end
end

function CT_PartyMemberBuffTooltip_Update(pet)
	if ( ( pet and numPetBuffs > 0 ) or ( not pet and numBuffs > 0 ) ) then
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
module.frame = function()
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

	-- Position of the buffs and debuffs
	ysize = 70;
	options["frame#tl:0:-" .. yoffset .. "#br:tr:0:-".. (yoffset + ysize)] = {
		"font#tl:5:0#v:GameFontNormalLarge#Layout",
		"dropdown#t:0:-30#s:190:17#o:layout:1#n:CT_PartyBuffs_LayoutDropdown#Buffs under the mana bar; Debuffs to the side in the top-right#Buffs to the side in the top-right; Debuffs under the mana bar",
	};
	yoffset = yoffset + ysize;

	-- Position of the buffs and debuffs
	ysize = 70;
	options["frame#tl:0:-" .. yoffset .. "#br:tr:0:-".. (yoffset + ysize)] = {
		"font#tl:5:0#v:GameFontNormalLarge#What to show?",
		"font#tr:t:-30:-30#v:GameFontNormal#Buffs: #0.9:0.9:0.9:l",
		"font#tr:t:-30:-60#v:GameFontNormal#Debuffs: #0.9:0.9:0.9:l",
		"dropdown#tl:t:-28:-30#s:95:17#o:buffType:1#n:CT_PartyBuffs_BuffTypeDropdown#All buffs#Buffs I can cast",
		"dropdown#tl:t:-28:-60#s:95:17#o:debuffType:1#n:CT_PartyBuffs_DebuffTypeDropdown#All Debuffs#Debuffs I can remove",
	};
	return "frame#all", options;
end

local function updateLayout(value)
	if (value == 2) then
		CT_PartyBuffFrame1Buff1:SetPoint("TOPLEFT", 75, 38);
		CT_PartyBuffFrame2Buff1:SetPoint("TOPLEFT", 75, 38);
		CT_PartyBuffFrame3Buff1:SetPoint("TOPLEFT", 75, 38);
		CT_PartyBuffFrame4Buff1:SetPoint("TOPLEFT", 75, 38);
		CT_PartyBuffFrame1Debuff1:SetPoint("TOPLEFT", 0, 0);
		CT_PartyBuffFrame2Debuff1:SetPoint("TOPLEFT", 0, 0);
		CT_PartyBuffFrame3Debuff1:SetPoint("TOPLEFT", 0, 0);
		CT_PartyBuffFrame4Debuff1:SetPoint("TOPLEFT", 0, 0);			
	else	-- value == 1 or nil, default
		CT_PartyBuffFrame1Buff1:SetPoint("TOPLEFT", 0, 0);
		CT_PartyBuffFrame2Buff1:SetPoint("TOPLEFT", 0, 0);
		CT_PartyBuffFrame3Buff1:SetPoint("TOPLEFT", 0, 0);
		CT_PartyBuffFrame4Buff1:SetPoint("TOPLEFT", 0, 0);
		CT_PartyBuffFrame1Debuff1:SetPoint("TOPLEFT", 75, 38);
		CT_PartyBuffFrame2Debuff1:SetPoint("TOPLEFT", 75, 38);
		CT_PartyBuffFrame3Debuff1:SetPoint("TOPLEFT", 75, 38);
		CT_PartyBuffFrame4Debuff1:SetPoint("TOPLEFT", 75, 38);
	end
end

module.update = function(self, type, value)
	if ( type == "init" ) then
		numBuffs = self:getOption("numBuffs") or 4;
		numDebuffs = self:getOption("numDebuffs") or 6;
		numPetBuffs = self:getOption("numPetBuffs") or 4;
		buffType = self:getOption("buffType");
		debuffType = self:getOption("debuffType");
		updateLayout(self:getOption("layout"));
	elseif ( type == "numBuffs" ) then
		numBuffs = value;
	elseif ( type == "numDebuffs" ) then
		numDebuffs = value;
	elseif ( type == "numPetBuffs" ) then
		numPetBuffs = value;
	elseif ( type == "buffType" ) then
		buffType = value;
	elseif ( type == "debuffType" ) then
		debuffType = value;
	elseif ( type == "layout" ) then
		updateLayout(value);
	end
end
