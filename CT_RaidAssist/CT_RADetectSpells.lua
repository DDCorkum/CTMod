local UnitName = CT_RA_UnitName;

function CT_RADetectSpells_OnLoad(self)
	self:RegisterEvent("UNIT_SPELLCAST_SENT");
	self:RegisterEvent("UNIT_SPELLCAST_STOP");
	self:RegisterEvent("UNIT_SPELLCAST_FAILED");
	self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED");
end

function CT_RADetectSpells_OnEvent(self, event, ...)
	if ( event == "UNIT_SPELLCAST_SENT" ) then
		-- UNIT_SPELLCAST_SENT events only show up for unit == "player"
		-- 1 == Unit, 2 == Spell, 3 == Rank, 4 == Target or ""
		-- "player", "Flash Heal", "Rank 9", "Dargen"
		CT_RA_SpellStartCast(select(2, ...), select(4, ...));
	elseif (
			event == "UNIT_SPELLCAST_STOP" or
			event == "UNIT_SPELLCAST_FAILED" or
			event == "UNIT_SPELLCAST_INTERRUPTED"
	) then
		-- 1 == Unit, 2 == Spell, 3 == Rank, 4 == A number
		-- "player", "Flash Heal", "Rank 9", 23
		CT_RA_SpellEndCast(select(1, ...));
	end
end