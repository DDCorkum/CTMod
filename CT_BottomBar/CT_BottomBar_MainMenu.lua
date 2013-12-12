------------------------------------------------
--               CT_BottomBar                 --
--                                            --
-- Breaks up the main menu bar into pieces,   --
-- allowing you to hide and move the pieces   --
-- independently of each other.               --
--                                            --
-- Please do not modify or otherwise          --
-- redistribute this without the consent of   --
-- the CTMod Team. Thank you.                 --
------------------------------------------------

--------------------------------------------
-- Initialization

local _G = getfenv(0);
local module = _G.CT_BottomBar;

local appliedOptions;
local frame_SetAlpha;
local frame_EnableMouse;

--------------------------------------------
-- Configure gryphons

local savedHideGryphons;

function module:configureGryphons()
	-- Gryphons
	--
	-- When CT_BottomBar and CT_Core are both loaded, we want CT_BottomBar's
	-- gryphon option to have priority over the CT_Core one when the addons
	-- are loading.
	--
	-- CT_Core's default is to not hide the gryphons. CT_BottomBar's default
	-- is to hide the gryphons.
	--
	-- Since CT_BottomBar loads before CT_Core, CT_BottomBar will apply its
	-- gryphon option first, but since CT_Core is not loaded CT_BottomBar
	-- cannot update CT_Core's option.
	--
	-- When CT_Core loads, it applies its gryphon option and updates the
	-- CT_BottomBar option since both addons are now loaded. We'll save
	-- the current CT_BottomBar option in a variable that we will later
	-- apply at PLAYER_LOGIN time so that we can override CT_Core's option.

	-- Save the state of the gryphons as defined by the CT_BottomBar option.
	savedHideGryphons = appliedOptions.hideGryphons;
	-- Hide/show the gryphons.
	module:toggleGryphons(appliedOptions.hideGryphons);
	-- Possibly show the lions instead of gryphons.
	module:showLions(appliedOptions.showLions);
end

function module:restoreGryphons()
	-- This will get called at PLAYER_LOGIN time so that we can override
	-- CT_Core's gryphons option.

	-- Hide/show the gryphons using the saved setting.
	module:toggleGryphons(savedHideGryphons);
	-- Possibly show the lions instead of gryphons.
	module:showLions(appliedOptions.showLions);
end

--------------------------------------------
-- Hide Gryphons

local gryphonLoop;

function module:toggleGryphons(hide)
	if (gryphonLoop) then
		-- Prevent infinite loop.
		gryphonLoop = nil;
		return;
	end
	-- Hide/Show the gryphons
	if ( hide ) then
		MainMenuBarLeftEndCap:Hide();
		MainMenuBarRightEndCap:Hide();
	else
		MainMenuBarLeftEndCap:Show();
		MainMenuBarRightEndCap:Show();
	end
	if (type(module.frame) == "table") then
		-- Change the checkbox in CT_BottomBar
		local cb = module.frame.general.hideGryphons;
		cb:SetChecked(hide);
	end
	if (CT_Core) then
		local opt = "hideGryphons";
		if (CT_Core:getOption(opt) ~= hide) then
			-- Change the same option in CT_Core
			gryphonLoop = true;
			CT_Core:setOption(opt, hide, true);
			gryphonLoop = nil;
		end
	end
end

--------------------------------------------
-- Show lions instead of gryphons

local shownLions;

function module:showLions(show)
	if (show) then
		MainMenuBarLeftEndCap:SetTexture("Interface\\MainMenuBar\\UI-MainMenuBar-EndCap-Human");
		MainMenuBarRightEndCap:SetTexture("Interface\\MainMenuBar\\UI-MainMenuBar-EndCap-Human");
		shownLions = true;
	else
		-- Only show the gryphons if we have previously shown the lions.
		if (not shownLions) then
			return;
		end
		MainMenuBarLeftEndCap:SetTexture("Interface\\MainMenuBar\\UI-MainMenuBar-EndCap-Dwarf");
		MainMenuBarRightEndCap:SetTexture("Interface\\MainMenuBar\\UI-MainMenuBar-EndCap-Dwarf");
		shownLions = false;
	end
end

--------------------------------------------
-- Hide Left Texture

local hidLeft;

function module:hideTexturesLeft(hide)
	-- Hide/Show the left textures

	-- MainMenuBarTexture0
	--	- Texture behind action buttons 1 to 6.
	-- MainMenuBarTexture1
	--	- Texture behind action buttons 7 to 12.

	if (hide) then
		MainMenuBarTexture0:Hide();
		MainMenuBarTexture1:Hide();
		hidLeft = true;
	else
		-- Only show the textures if we previously hid them.
		if (not hidLeft) then
			return;
		end
		MainMenuBarTexture0:Show();
		MainMenuBarTexture1:Show();
		hidLeft = false;
	end
end

--------------------------------------------
-- Hide Right Texture

local hidRight;

function module:hideTexturesRight(hide)
	-- Hide/Show the right textures

	-- MainMenuBarTexture2
	--	- Texture behind the action bar arrows, the action bar page number,
	--	  and all but the last three and 1/3 micro buttons.
	-- MainMenuBarTexture3
	--	- Texture behind part of the encounter journal micro button,
	--	  the raid micro button, the menu micro button, the help
	--	  micro button, the bag buttons, and the backpack button.

	if (hide) then
		MainMenuBarTexture2:Hide();
		MainMenuBarTexture3:Hide();
		hidRight = true;
	else
		-- Only show the textures if we previously hid them.
		if (not hidRight) then
			return;
		end
		MainMenuBarTexture2:Show();
		MainMenuBarTexture3:Show();
		hidRight = false;
	end
end

--------------------------------------------
-- Configure artwork

function module:configureArtwork()
	module:hideTexturesLeft(appliedOptions.hideTexturesLeft);
	module:hideTexturesRight(appliedOptions.hideTexturesRight);
end

--------------------------------------------
-- MainMenuBar animations.

local animFlag;

MainMenuBar.slideOut:HookScript("OnPlay",
	function(self)
		animFlag = true;
		module:animStarted();
	end
);
MainMenuBar.slideOut:HookScript("OnFinished",
	function(self)
		animFlag= false;
		module:animStopped();
	end
);

function module:isMainMenuBarAnimating()
	return animFlag;
end

--------------------------------------------
-- Disable action bar

local function hooked_SetAlpha(self, alpha)
	frame_SetAlpha(self, 0);
end

local function hooked_RegisterEvent(self, event)
	self:UnregisterEvent(event);
end

local function hooked_EnableMouse(self, enable)
	if (not InCombatLockdown()) then
		frame_EnableMouse(self, false);
	end
end

local function hooked_Show(self)
	if (not InCombatLockdown()) then
		self:Hide();
	end
end

function module:disableActionBar()
	-- Disable the action and bonus action bars.

	-- Disable and hide the ActionButton buttons.
	local name, obj;
	name = "ActionButton";
	for j = 1, 12 do
		obj = _G[name .. j];
		obj:UnregisterAllEvents();
		obj:EnableMouse(false);
		obj:SetAlpha(0);
		obj:Hide();

		-- Try to keep the alpha at zero.
		hooksecurefunc(obj, "SetAlpha", hooked_SetAlpha);

		-- Try to keep events from being re-registered.
		hooksecurefunc(obj, "RegisterEvent", hooked_RegisterEvent);

		-- Try to keep the mouse disabled.
		hooksecurefunc(obj, "EnableMouse", hooked_EnableMouse);

		-- Try to keep the frame hidden.
		hooksecurefunc(obj, "Show", hooked_Show);
		obj:SetAttribute("statehidden", true);
		RegisterStateDriver(obj, "visibility", "hide");
	end

	-- Because we are continuing to use Blizzard's own buttons for the various
	-- CT_BottomBar bars, we need to keep as much of the default UI active as
	-- possible, so that those bars and their buttons can be updated, shown, and
	-- hidden properly by the default UI.
	--
	-- This means that we can't disable the events on the MainMenuBar,
	-- or MainMenuBarArtFrame. We also don't want to hide these frame.
	-- We want Blizzard to continue to manipulate
	-- them.

	-- Don't disable or hide the MainMenuBar. It is used to support
	-- the other bars.

	-- Don't disable or hide the MainMenuBarArtFrame.
end

--------------------------------------------
-- Initialize

function module:mainmenuConfigure()
	-- MainMenuBar Gryphons
	module:configureGryphons();

	-- MainMenuBar artwork
	module:configureArtwork();
end

function module:initMainMenuBar()
	-- Initialize the main menu bar.
	frame_SetAlpha = module.frame_SetAlpha;
	frame_EnableMouse = module.frame_EnableMouse;

	-- Disable mouse in MainMenuBar
	MainMenuBar:EnableMouse(false);
end

function module:mainmenuInit()
	-- Initialize this lua file.
	appliedOptions = module.appliedOptions;
end
