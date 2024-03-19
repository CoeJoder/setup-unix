-- Pull in the wezterm API
local wezterm = require 'wezterm'
local mux = wezterm.mux

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- This is where you actually apply your config choices
wezterm.on('gui-startup', function(cmd)
  local tab, pane, window = mux.spawn_window(cmd or {})
  window:gui_window():maximize()
end)
config.check_for_updates = false
config.audible_bell = "Disabled"
config.enable_wayland = false
config.window_decorations = "RESIZE"
config.hide_tab_bar_if_only_one_tab = true
--config.window_background_opacity = 0.89
--config.text_background_opacity = 1.0
--config.color_scheme = 'Default (dark) (terminal.sexy)'
config.color_scheme = 'Digerati (terminal.sexy)'
config.font = wezterm.font 'FiraMono Nerd Font Mono'
--config.default_cursor_style = 'BlinkingBar'
config.background = {
  {
    source = {
      Color = 'black',
    },
    width = "100%",
    height = "100%",
    opacity = 0.8,
  },
  {
    source = {
      File = './Pictures/terry-a-davis-terry-davis.gif'
    },
    hsb = { brightness = 0.09 },
    opacity = 0.1,
  },
}
config.window_frame = {
  border_left_width = '0.15cell',
  border_right_width = '0.15cell',
  border_bottom_height = '0.07cell',
  border_top_height = '0.07cell',
  border_left_color = 'black',
  border_right_color = 'black',
  border_bottom_color = 'black',
  border_top_color = 'black',
}

-- and finally, return the configuration to wezterm
return config

