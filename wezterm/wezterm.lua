local wezterm = require 'wezterm';

return {
  color_scheme = "Dracula",
  window_background_opacity = 0.9,
  hide_tab_bar_if_only_one_tab = true,
  font = wezterm.font("JetBrains Mono"),
  font_size = 20,
  harfbuzz_features = {"calt=0", "clig=0", "liga=0"},
  default_cursor_style = "SteadyUnderline",
  send_composed_key_when_left_alt_is_pressed = true,
  send_composed_key_when_right_alt_is_pressed = false,
  keys = {
    {key="LeftArrow", mods="CMD", action=wezterm.action{ActivateTabRelative=-1}},
    {key="RightArrow", mods="CMD", action=wezterm.action{ActivateTabRelative=1}},
  }
}
