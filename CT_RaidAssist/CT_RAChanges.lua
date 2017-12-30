local UnitName = CT_RA_UnitName;

tinsert(UISpecialFrames, "CT_RA_ChangelogFrame");
CT_RACHANGES_HEIGHT = 500;
function CT_RAChanges_DisplayDialog()
	CT_RA_ChangelogFrame:SetHeight(CT_RACHANGES_HEIGHT+25);
	-- Initialize dialog
		-- Set title
	CT_RA_ChangelogFrameTitle:SetText(CT_RA_Changes["title"]);

		-- Show sections
	local section, totalHeight = 1, 0;
	while ( CT_RA_Changes["section" .. section] ) do
		local objSection = _G["CT_RA_ChangelogFrameScrollFrameSection" .. section];
		local part, partHeights = 1, 0;

			-- Show section
		objSection:Show();

			-- Set section title
		_G[objSection:GetName() .. "Title"]:SetText(CT_RA_Changes["section" .. section]["title"]);

			-- Show parts
		while ( CT_RA_Changes["section" .. section][part] ) do
			local objPart = _G["CT_RA_ChangelogFrameScrollFrameSection" .. section .. "Part" .. part];

				-- Show part
			objPart:Show();

				-- Set part stuff
			_G[objPart:GetName() .. "Text"]:SetText(CT_RA_Changes["section" .. section][part][2]);
			_G[objPart:GetName() .. "Text"]:SetHeight(CT_RA_Changes["section" .. section][part][1]);
			objPart:SetHeight(CT_RA_Changes["section" .. section][part][1]);
			partHeights = partHeights + CT_RA_Changes["section" .. section][part][1] + 5;
			part = part + 1;
		end
		local addedHeight = ( CT_RA_Changes["section" .. section]["addedHeight"] or 0);
		objSection:SetHeight(partHeights+35+addedHeight);
		totalHeight = totalHeight + partHeights+35+addedHeight;
		section = section + 1;
	end
	CT_RA_ChangelogFrameScrollFrameSection:SetHeight(totalHeight);
	ShowUIPanel(CT_RA_ChangelogFrame);
	CT_RA_ChangelogFrameScrollFrame:UpdateScrollChildRect();
	local minVal, maxVal = CT_RA_ChangelogFrameScrollFrameScrollBar:GetMinMaxValues();
	if ( maxVal == 0 ) then
		CT_RA_ChangelogFrameScrollFrameScrollBar:Hide();
	else
		CT_RA_ChangelogFrameScrollFrameScrollBar:Show();
	end
	CT_RA_ChangelogFrameScrollFrame:SetHeight(CT_RACHANGES_HEIGHT-75);
end

-- Add slash command
CT_RA_RegisterSlashCmd("/ralog", "Shows the changelog for this version.", 15, "RALOG", CT_RAChanges_DisplayDialog, "/ralog");


-- List of changes
--
-- |bxxxx|eb (yellow text)
-- |gxxxx|eg (red text)
--
CT_RA_Changes = {};
CT_RA_Changes["title"] = "CT_RaidAssist Update History (4.02 to 5.3)";
local sections = {
	{
		["title"] = "Version 5.3",
		{ 30, "Updated for the WoW 5.3 patch." },
		["addedHeight"] = 10,
	},
	{
		["title"] = "Version 5.2",
		{ 30, "Updated for the WoW 5.2 patch." },
		["addedHeight"] = 10,
	},
	{
		["title"] = "Version 5.0101",
		{ 30, "Updated for the WoW 5.1 patch." },
		["addedHeight"] = 10,
	},
	{
		["title"] = "Version 5.0004",
		{ 30, "Bug fix: Fixed an error when entering the game." },
		["addedHeight"] = 10,
	},
	{
		["title"] = "Version 5.0003",
		{ 30, "Bug fix: Changed when dropdown menus are initialized to avoid tainting CompactRaidFrame1 when it gets created." },
		{ 30, "Bug fix: Declared some variables as local." },
		{ 30, "Bug fix: An error could occur when selecting or unselecting individual buffs in the CT_RaidAssist 'Buff Options' window." },
		["addedHeight"] = 10,
	},
	{
		["title"] = "Version 5.0002",
		{ 30, "Release version for WoW 5." },
		{ 30, "Added support for the Monk class." },
		{ 30, "Removed spells that are no longer in the game." },
		{ 30, "Updated spells that have changed." },
		["addedHeight"] = 10,
	},
	{
		["title"] = "Version 5.0001",
		{ 30, "Beta version for WoW 5." },
		["addedHeight"] = 10,
	},
	{
		["title"] = "Version 4.0301",
		{ 30, "Updated to work with the WoW 4.3 patch." },
		{ 30, "Now shortens health and max health values shown on raid frames when they are over 10,000." },
		{ 30, "Fixed a bug that caused raid frames to be incorrectly positioned when 'Show groups horizontally' was toggled." },
		["addedHeight"] = 10,
	},
	{
		["title"] = "Version 4.0201",
		{ 30, "Fixed Emergency Monitor positioning issues when its scale was not 100%." },
		["addedHeight"] = 10,
	},
	{
		["title"] = "Version 4.0200",
		{ 30, "Updated for the WoW 4.2 patch." },
		["addedHeight"] = 10,
	},
	-- Max 10 sections.
};
local sectNum = 0;
for i, section in ipairs(sections) do
	sectNum = sectNum + 1;
	if (sectNum > 10) then
		break;
	end
	CT_RA_Changes["section" .. sectNum] = section;
end
for k, v in pairs(CT_RA_Changes) do
	if ( type(v) == "table" ) then
		for key, val in pairs(v) do
			if ( type(val) == "table" ) then
				while ( string.find(val[2], "|[bg].-|e[bg]") ) do
					CT_RA_Changes[k][key][2] = string.gsub(val[2], "^(.*)|b(.-)|eb(.*)$", "%1|c00FFD100%2|r%3");
					CT_RA_Changes[k][key][2] = string.gsub(CT_RA_Changes[k][key][2], "^(.*)|g(.-)|eg(.*)$", "%1|c00FF0000%2|r%3");
				end
			end
		end
	end
end
