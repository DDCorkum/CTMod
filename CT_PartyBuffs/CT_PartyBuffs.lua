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

local numBuffs, numDebuffs, numPetBuffs;

function CT_PartyBuffs_OnLoad(self)
	PetFrameDebuff1:SetPoint("TOPLEFT", PetFrame, "TOPLEFT", 48, -59);
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
				local _, bufftexture = UnitBuff("party" .. self:GetID(), i);
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
						local _, debufftexture, debuffApplications, debuffType = UnitDebuff("party" .. self:GetID(), i);
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

	return "frame#all", options;
end

module.update = function(self, type, value)
	if ( type == "init" ) then
		numBuffs = self:getOption("numBuffs") or 4;
		numDebuffs = self:getOption("numDebuffs") or 6;
		numPetBuffs = self:getOption("numPetBuffs") or 4;
	elseif ( type == "numBuffs" ) then
		numBuffs = value;
	elseif ( type == "numDebuffs" ) then
		numDebuffs = value;
	elseif ( type == "numPetBuffs" ) then
		numPetBuffs = value;
	end
end
