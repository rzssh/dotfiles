local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action

local theme_path = wezterm.home_dir .. "/.cache/matugen/colors.json"
wezterm.add_to_config_reload_watch_list(theme_path)

local theme_file = io.open(theme_path, "r")
if theme_file then
  local theme = wezterm.json_parse(theme_file:read("*a"))
  theme_file:close()

  config.colors = {
    foreground = theme.special.foreground,
    background = theme.special.background,
    cursor_bg = theme.special.cursor,
    cursor_fg = theme.special.background,
    cursor_border = theme.special.cursor,
    selection_bg = theme.material.primary_container,
    selection_fg = theme.material.on_primary_container,
    ansi = {
      theme.colors.color0,
      theme.colors.color1,
      theme.colors.color2,
      theme.colors.color3,
      theme.colors.color4,
      theme.colors.color5,
      theme.colors.color6,
      theme.colors.color7,
    },
    brights = {
      theme.colors.color8,
      theme.colors.color9,
      theme.colors.color10,
      theme.colors.color11,
      theme.colors.color12,
      theme.colors.color13,
      theme.colors.color14,
      theme.colors.color15,
    },
  }
end

local font = wezterm.font_with_fallback({
  {
    family = "Monaspace Argon",
    weight = "Medium",
    harfbuzz_features = { "calt", "ss01", "ss02", "ss03", "ss04" },
  },
  { family = "JetBrainsMono Nerd Font Mono", weight = "Medium" },
})

config.default_prog = { "fish" }
config.term = "xterm-256color"
config.font = font
config.font_rules = { { italic = true, font = font } }
config.font_size = 16
config.adjust_window_size_when_changing_font_size = false
config.window_padding = { left = 12, right = 12, top = 8, bottom = 8 }
config.window_decorations = "NONE"
config.window_close_confirmation = "NeverPrompt"
config.window_background_opacity = 0.75
config.enable_tab_bar = false
config.scrollback_lines = 3000
config.default_cursor_style = "SteadyBlock"
config.hide_mouse_cursor_when_typing = true
config.audible_bell = "Disabled"
config.notification_handling = "SuppressFromFocusedWindow"
config.enable_wayland = true
config.enable_kitty_keyboard = true
config.enable_csi_u_key_encoding = true
config.disable_default_key_bindings = true
config.check_for_updates = false
config.keys = {
  { key = "mapped:v", mods = "CTRL", action = act.DisableDefaultAssignment },
  { key = "Backspace", mods = "CTRL", action = act.SendString("\x17") },
  {
    key = "Paste",
    mods = "NONE",
    action = wezterm.action_callback(function(window, pane)
      local ok, types = wezterm.run_child_process({ "wl-paste", "--list-types" })
      local paste = act.PasteFrom("Clipboard")
      if ok and types:find("image/", 1, true) then
        paste = act.SendKey({ key = "v", mods = "CTRL" })
      end
      window:perform_action(paste, pane)
    end),
  },
}

return config
