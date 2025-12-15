local wezterm = require("wezterm")
local act = wezterm.action
-- Some empty tables for later use
local config = {}
local mouse_bindings = {}
local launch_menu = {}
-- config.term = "wezterm"
-- config.term = "iterm2, iTerm2.app"
config.color_scheme = "Tokyo Night"
config.default_prog = { "pwsh.exe", "-NoLogo" }

table.insert(launch_menu, {
	label = "GitBash",
	args = { "C:\\Program Files\\Git\\bin\\bash.exe" },
})
table.insert(launch_menu, {
	label = "PowerShell",
	args = { "powershell.exe", "-NoLogo" },
})
table.insert(launch_menu, {
	label = "Pwsh",
	args = { "pwsh.exe", "-NoLogo" },
})

--- Disable defaul keys and set some minimum ones for now.
--- This helps with conflicting keys in pwsh
local keys = {
	{ key = "Tab", mods = "CTRL", action = act.ActivateTabRelative(1) },
	{ key = "Tab", mods = "SHIFT|CTRL", action = act.ActivateTabRelative(-1) },
	{ key = "PageUp", mods = "SHIFT", action = act.ScrollByPage(-1) },
	{ key = "PageUp", mods = "CTRL", action = act.ActivateTabRelative(-1) },
	{ key = "PageUp", mods = "SHIFT|CTRL", action = act.MoveTabRelative(-1) },
	{ key = "PageDown", mods = "SHIFT", action = act.ScrollByPage(1) },
	{ key = "PageDown", mods = "CTRL", action = act.ActivateTabRelative(1) },
	{ key = "PageDown", mods = "SHIFT|CTRL", action = act.MoveTabRelative(1) },

	{ key = "%", mods = "ALT|CTRL", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "%", mods = "SHIFT|ALT|CTRL", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = '"', mods = "ALT|CTRL", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = '"', mods = "SHIFT|ALT|CTRL", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "'", mods = "SHIFT|ALT|CTRL", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

	{ key = "1", mods = "CTRL", action = act.ActivateTab(0) },
	{ key = "2", mods = "CTRL", action = act.ActivateTab(1) },
	{ key = "3", mods = "CTRL", action = act.ActivateTab(2) },
	{ key = "4", mods = "CTRL", action = act.ActivateTab(3) },
	{ key = "5", mods = "CTRL", action = act.ActivateTab(4) },
	{ key = "6", mods = "CTRL", action = act.ActivateTab(5) },
	{ key = "7", mods = "CTRL", action = act.ActivateTab(6) },
	{ key = "8", mods = "CTRL", action = act.ActivateTab(7) },
	{ key = "9", mods = "CTRL", action = act.ActivateTab(8) },
	{ key = "0", mods = "CTRL", action = act.ActivateTab(-1) },

	{ key = "+", mods = "SHIFT|CTRL", action = act.IncreaseFontSize },
	{ key = "_", mods = "SHIFT|CTRL", action = act.DecreaseFontSize },

	{ key = "F", mods = "CTRL", action = act.Search("CurrentSelectionOrEmptyString") },
	{ key = "K", mods = "CTRL", action = act.ClearScrollback("ScrollbackOnly") },
	-- { key = "L", mods = "CTRL", action = act.ShowDebugOverlay },
	{ key = "M", mods = "CTRL", action = act.Hide },
	-- { key = "N", mods = "CTRL", action = act.SpawnWindow },
	{ key = "P", mods = "CTRL", action = act.ActivateCommandPalette },
	{ key = "R", mods = "CTRL", action = act.ReloadConfiguration },
	{ key = "T", mods = "CTRL", action = act.ShowLauncher },
	{
		key = "U",
		mods = "CTRL",
		action = act.CharSelect({ copy_on_select = true, copy_to = "ClipboardAndPrimarySelection" }),
	},

	{ key = "W", mods = "CTRL", action = act.CloseCurrentTab({ confirm = true }) },
	--Toggles between showing all the panes in tab to only the active one
	{ key = "Z", mods = "CTRL", action = act.TogglePaneZoomState },

	{ key = "X", mods = "CTRL", action = act.ActivateCopyMode },
	{ key = "C", mods = "CTRL", action = act.CopyTo("Clipboard") },
	{ key = "V", mods = "CTRL", action = act.PasteFrom("Clipboard") },
	-- { key = "phys:Space", mods = "SHIFT|CTRL", action = act.QuickSelect },
	{ key = "LeftArrow", mods = "SHIFT|ALT|CTRL", action = act.AdjustPaneSize({ "Left", 1 }) },
	-- Turning these off so I can use pwsh keys
	-- { key = 'LeftArrow', mods = 'SHIFT|CTRL', action = act.ActivatePaneDirection 'Left' },
	-- { key = 'RightArrow', mods = 'SHIFT|CTRL', action = act.ActivatePaneDirection 'Right' },
	-- Add these to allow quick moving between prompts
	{ key = "UpArrow", mods = "SHIFT", action = act.ScrollToPrompt(-1) },
	{ key = "DownArrow", mods = "SHIFT", action = act.ScrollToPrompt(1) },
	{ key = "RightArrow", mods = "SHIFT|ALT|CTRL", action = act.AdjustPaneSize({ "Right", 1 }) },
	{ key = "UpArrow", mods = "SHIFT|CTRL", action = act.ActivatePaneDirection("Up") },
	{ key = "UpArrow", mods = "SHIFT|ALT|CTRL", action = act.AdjustPaneSize({ "Up", 1 }) },
	{ key = "DownArrow", mods = "SHIFT|CTRL", action = act.ActivatePaneDirection("Down") },
	{ key = "DownArrow", mods = "SHIFT|ALT|CTRL", action = act.AdjustPaneSize({ "Down", 1 }) },
	{ key = "Insert", mods = "SHIFT", action = act.PasteFrom("PrimarySelection") },
	{ key = "Insert", mods = "CTRL", action = act.CopyTo("PrimarySelection") },
	{ key = "F11", mods = "NONE", action = act.ToggleFullScreen },
	{ key = "Copy", mods = "NONE", action = act.CopyTo("Clipboard") },
	{ key = "Paste", mods = "NONE", action = act.PasteFrom("Clipboard") },
}

-- Mousing bindings
mouse_bindings = {
	-- Change the default click behavior so that it only selects
	-- text and doesn't open hyperlinks
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "NONE",
		action = act.CompleteSelection("ClipboardAndPrimarySelection"),
	},

	-- and make CTRL-Click open hyperlinks
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "CTRL",
		action = act.OpenLinkAtMouseCursor,
	},
	{
		event = { Down = { streak = 3, button = "Left" } },
		action = wezterm.action.SelectTextAtMouseCursor("SemanticZone"),
		mods = "NONE",
	},
}

--- Default config settings
config.scrollback_lines = 7000
config.hyperlink_rules = wezterm.default_hyperlink_rules()
-- config.hide_tab_bar_if_only_one_tab = true
config.font = wezterm.font_with_fallback({
	{
		family = "JetBrains Mono",
	},
	{
		family = "FiraMono Nerd Font",
	},
	{
		family = "IosevkaTerm NFM",
	},
	{
		family = "Hack Nerd Font",
	},
})

config.font_size = 12
config.launch_menu = launch_menu
config.default_cursor_style = "BlinkingBar"
config.disable_default_key_bindings = true
config.keys = keys
config.mouse_bindings = mouse_bindings
return config
