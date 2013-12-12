local UnitName = CT_RA_UnitName;

CT_RA_RegisterSlashCmd("/raloot", "Sets the default loot method: ffa, freeforall, rr, roundrobin, m, master, g, group, nbg, or needbeforegreed.",
	30, "RALOOT", function(msg)
		msg = string.lower(msg);
		local lootCommand = {
			{ 1, "Free For All", {"ffa", "freeforall"} },
			{ 2, "Round Robin", {"rr", "roundrobin"} },
			{ 3, "Master Looter", {"m", "master"} },
			{ 4, "Group Loot", {"g", "group"} },
			{ 5, "Need Before Greed", {"nbg", "needbeforegreed"} },
		};
		local lootType;
		for i, v in ipairs(lootCommand) do
			for j, k in ipairs(v[3]) do
				if (msg == k) then
					CT_RATab_DefaultLootMethod = v[1];
					lootType = v[2];
					break;
				end
			end
			if (lootType) then
				break;
			end
		end
		if (not lootType) then
			local text = "";
			for i, v in ipairs(lootCommand) do
				for j, k in ipairs(v[3]) do
					if (#text > 0) then
						text = text .. "/";
					end
					text = text .. "|c00FFFFFF" .. k .. "|r";
				end
			end
			CT_RA_Print("<CTRaid> Usage: /raloot " .. text .. ".");
			return;
		end
		CT_RA_Print("<CTRaid> Default loot type has been set to: |c00FFFFFF".. lootType .. "|r.", 1, 0.5, 0);
	end, "/raloot");

function CT_RATab_AutoPromote_OnClick(self)
	local name, rank = GetRaidRosterInfo(self.value);
	CT_RATab_AutoPromotions[name] = not CT_RATab_AutoPromotions[name];
	if ( CT_RA_Level and CT_RA_Level >= 2 and CT_RATab_AutoPromotions[name] and rank < 1 ) then
		PromoteToAssistant(name);
		CT_RA_Print("<CTRaid> Auto-Promoted |c00FFFFFF" .. name .. "|r.", 1, 0.5, 0);
	end
end
