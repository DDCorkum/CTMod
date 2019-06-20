local UnitName = CT_RA_UnitName;

CT_RA_ClassSpells = { };
CT_RA_ClassTalents = { };

CT_RA_HMark = nil;

function CT_RA_GetClassSpells()
	CT_RA_ClassSpells = { };
	CT_RA_HMark = nil;
	for i = 1, GetNumSpellTabs(), 1 do
		local name, texture, offset, numSpells = GetSpellTabInfo(i);
		for y = 1, numSpells, 1 do
			local spellName, rankName = GetSpellBookItemName(offset+y, BOOKTYPE_SPELL);
			local useless, useless, rank = string.find(rankName or "", "(%d+)");
			if (
				not CT_RA_ClassSpells[spellName] or
				(
					CT_RA_ClassSpells[spellName]["rank"] and
					tonumber(rank) and
					CT_RA_ClassSpells[spellName]["rank"] < tonumber(rank)
				)
			) then
				CT_RA_ClassSpells[spellName] = {
					["rank"] = tonumber(rank),
					["tab"] = i,
					["spell"] = y+offset,
				};
			end
			if ( not CT_RA_HMark and spellName == CT_RA_DEBUFF_HUNTERS_MARK ) then
				CT_RA_HMark = { y+offset, i+1 };
			end
		end
	end
end

function CT_RA_GetClassTalents()
	CT_RA_ClassTalents = { };
	local id, name, description, iconPath, background, role;
	local currentRank;
	for i = 1, GetNumSpecializations(), 1 do
		id, name, description, iconPath, background, role = GetSpecializationInfo(i);
		currentRank = 1;
		if (name and currentRank and currentRank > 0) then
			CT_RA_ClassTalents[name] = currentRank;
		end
	end
end

function CT_RA_ClassSpells_OnEvent(self, event, ...)
	if ( event == "SPELLS_CHANGED" ) then
		CT_RA_GetClassSpells();
	elseif ( event == "PLAYER_TALENT_UPDATE" ) then
		CT_RA_GetClassTalents();
	end
end
