local wezterm = require("wezterm")
local act = wezterm.action

local config = wezterm.config_builder and wezterm.config_builder() or {}

-- Follow the macOS system appearance automatically.
-- Your Mac is currently in Light mode, so you get the light "Catppuccin Latte" theme.
-- Flip macOS to Dark and the terminal switches to "Catppuccin Mocha" on its own.
-- Want it ALWAYS light? Replace the next 8 lines with: config.color_scheme = "Catppuccin Latte"
local function scheme_for_appearance(appearance)
    if appearance:find("Dark") then
        return "Catppuccin Mocha" -- dark
    else
        return "Catppuccin Latte" -- light
    end
end
config.color_scheme = scheme_for_appearance(wezterm.gui.get_appearance())

config.font_size = 14
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.window_decorations = "RESIZE"
config.show_new_tab_button_in_tab_bar = false
config.window_background_opacity = 0.9
config.macos_window_background_blur = 70
config.text_background_opacity = 0.9
config.adjust_window_size_when_changing_font_size = false
config.window_padding = {
    left = 20,
    right = 20,
    top = 20,
    bottom = 5,
}

config.keys = {
    -- Make Option-Left equivalent to Alt-b which many line editors interpret as backward-word
    { key = "LeftArrow",  mods = "OPT", action = act.SendString("\x1bb") },
    -- Make Option-Right equivalent to Alt-f; forward-word
    { key = "RightArrow", mods = "OPT", action = act.SendString("\x1bf") },
    -- Make Command-Left equivalent to moving to the beginning of the line
    { key = "LeftArrow",  mods = "CMD", action = act.SendString("\x01") },
    -- Make Command-Right equivalent to moving to the end of the line
    { key = "RightArrow", mods = "CMD", action = act.SendString("\x05") },
}

-- ── Clickable links, even inside tmux ───────────────────────────────────────
-- tmux has `mouse on`, which normally swallows every click. Making CMD the
-- "bypass mouse reporting" modifier means a Cmd+click is handled by WezTerm
-- itself (not forwarded to tmux), so it can open the URL under the cursor.
--   • Cmd+click  on a link  -> open it in the browser
--   • Cmd+drag             -> native WezTerm text selection (copies to clipboard)
--   • plain click/drag      -> still goes to tmux as before
config.bypass_mouse_reporting_modifiers = "CMD"
config.mouse_bindings = {
    {
        event = { Up = { streak = 1, button = "Left" } },
        mods = "CMD",
        action = act.OpenLinkAtMouseCursor,
    },
}

return config
