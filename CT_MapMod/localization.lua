local module = CT_MapMod
module.text = { };

module.text.Name = "Name";
module.text.Description = "Description";
module.text.Type = "Type";
module.text.Icon = "Icon";

module.text.Okay = "Okay";
module.text.Cancel = "Cancel";
module.text.Delete = "Delete";
module.text.mouseover =
{
	[1] = "Shift-Click to Edit";
	[2] = "Right-Click to Drag";
};


CT_MAPMOD_SETS = { };

CT_MAPMOD_SETS[1] = "General";
CT_MAPMOD_SETS[2] = "NPCs";
CT_MAPMOD_SETS[3] = "Mobs";
CT_MAPMOD_SETS[4] = "Locations";
CT_MAPMOD_SETS[5] = "Items";
CT_MAPMOD_SETS[6] = "Misc";
CT_MAPMOD_SETS[7] = "Herbs";
CT_MAPMOD_SETS[8] = "Minerals";



if (GetLocale() == "frFR") then

	-- Original translation contributed by Sasmira
	-- Changes made by DDCorkum in 2019 for version 8.2
	
	module.text.Name = "Nom";
	module.text.Description = "Description";
	module.text.Type = "Type";
	module.text.Icon = "Icône";
	
	module.text.Okay = "OK";
	module.text.Cancel = "Annuler";
	module.text.Delete = "Supprimer";
	-- module.text.mouseover[1] = "<Maj>-Click to Edit";
	-- module.text.mouseover[2] = "Right-Click to Drag";
	
	CT_MAPMOD_SETS[1] = "G\195\169n\195\169ral";
	CT_MAPMOD_SETS[2] = "PNJs";
	CT_MAPMOD_SETS[3] = "Montres";
	CT_MAPMOD_SETS[4] = "Locations";
	CT_MAPMOD_SETS[5] = "Objets";
	CT_MAPMOD_SETS[6] = "Divers";
	
end

if (GetLocale() == "deDE") then

	-- Original translation contributed by Hjörvarör
	-- Changes made by DDCorkum in 2019 for version 8.2

	module.text.Name = "Name";
	module.text.Description = "Beschreibung";
	module.text.Type = "Art";
	module.text.Icon = "Symbol";
	
	module.text.Okay = "Ok";
	module.text.Cancel = "Abbrechen";
	module.text.Delete = "L\195\182schen";   -- \195\182 = ö
	-- module.text.mouseover[1] = "Shift-Click to Edit";
	-- module.text.mouseover[2] = "Right-Click to Drag";

	CT_MAPMOD_SETS[1] = "Allgemeines";
	CT_MAPMOD_SETS[2] = "NSC";
	CT_MAPMOD_SETS[3] = "Monster";
	CT_MAPMOD_SETS[4] = "Orte";
	CT_MAPMOD_SETS[5] = "Gegenst\195\164nde";
	CT_MAPMOD_SETS[6] = "Verschiedenes";

end