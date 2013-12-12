local module = CT_BuffMod;

BINDING_HEADER_CT_BUFFMOD = "CT_BuffMod";
BINDING_NAME_CT_BUFFMOD_RECASTBUFFS = "Recast Buffs";

module:setText("BUFFNAME_CHARGES", "%s (%d charges)");
module:setText("PRE_EXPIRATION_WARNING_KEYBINDING",
	"The |cFFFFFFFF%s|r buff will expire in |cFFFFFFFF%s|r. Press |cFFFFFFFF%s|r while out of combat to recast.");
module:setText("PRE_EXPIRATION_WARNING",
	"The |cFFFFFFFF%s|r buff will expire in |cFFFFFFFF%s|r.");
