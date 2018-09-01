-- This is the first file to get loaded, so some stuff will get set here to be sure its available elsewhere.

CT_RA_NumGroups = 8;  -- When sorting by group this is 8, when sorting by class this is the number of classes in the game.
CT_RA_MaxGroups = 12;  -- This is the maximum number of possible groups (when sorting by group or class).

-- Ensure the ClickCastFrames table exists, since we'll be using adding some of our frames to it.
ClickCastFrames = ClickCastFrames or { };

-- Upper case english versions of the class names.
-- These match the 2nd return value from UnitClass().
-- Do not localize.
-- Note: When adding a new class, see also CT_RAMenu.xml which has some class objects.
-- Also adjust the value of CT_RA_MaxGroups.
-- Also add a new CT_RAGroup frame in CT_RaidAssist.xml
-- Also add a new CT_RAGroupDrag frame in CT_RaidAssist.xml
-- Also add a new CT_RAOptions2ClassCB frame in CT_RAOptions.xml
CT_RA_CLASS_DRUID_EN = "DRUID";
CT_RA_CLASS_HUNTER_EN = "HUNTER";
CT_RA_CLASS_MAGE_EN = "MAGE";
CT_RA_CLASS_PALADIN_EN = "PALADIN";
CT_RA_CLASS_PRIEST_EN = "PRIEST";
CT_RA_CLASS_ROGUE_EN = "ROGUE";
CT_RA_CLASS_SHAMAN_EN = "SHAMAN";
CT_RA_CLASS_WARLOCK_EN = "WARLOCK";
CT_RA_CLASS_WARRIOR_EN = "WARRIOR";
CT_RA_CLASS_DEATHKNIGHT_EN = "DEATHKNIGHT";
CT_RA_CLASS_MONK_EN = "MONK";
CT_RA_CLASS_DEMONHUNTER_EN = "DEMONHUNTER";


function CT_RA_UnitName(unit)
	local name, realm = UnitName(unit);
	if (name and realm and realm ~= "") then
		return name .. "-" .. realm;
	end
	return name;
end

function CT_RA_GetNumRaidMembers()
	if (IsInRaid()) then
		return GetNumGroupMembers();
	else
		return 0;
	end
end

function CT_RA_GetNumPartyMembers()
	return GetNumSubgroupMembers();
end

-- Inner cache metatable 
local subMeta = { 
-- Given a name, append it to the parent frame name, and then return
-- the result (cache it if it's found) 
	__index = function(t, name)
		local tn = type(name);
		if (tn == "string" or tn == "number") then
			local realName = t._frameName .. name;
			local realFrame = _G[realName];
			if (realFrame) then
				t[name] = realFrame;
			end return realFrame;
		end
	end 
};

local topMeta = { 
	-- Given a frame or a frame name, create (or return) the subcache
	-- for that frame.
	__index = function(t, frame)
		local tf = type(frame);
		if (tf == "string") then
			-- If we're passed a frame name, look up the frame behind
			-- it and if it's found, get its subcache
			local realFrame = _G[frame];
			-- Prevent infinite looping
			if (type(realFrame)=="table") then
				local ret = t[realFrame];
				if (ret) then
					t[frame] = ret;
				end
				return ret;
			end
		elseif (tf == "table") then 
			-- Must create a new caching subtable if frame is an
			-- actual Frame.
			local gn = frame.GetName;
			if (gn) then
				local ret = {};
				ret._frame = frame;
				ret._frameName = gn(frame);
				setmetatable(ret, subMeta);
				t[frame] = ret;
				return ret;
			end
		end 
	end
};
 -- Create a fresh subframe cache and return it.
local function CreateSubframeCache()
	local ret = {};
	setmetatable(ret, topMeta);
	return ret;
end

CT_RA_Cache = CreateSubframeCache();
