-- Courier preset — WezTerm colors
-- Hand-authored; deployed in place of ii-generator output when Courier is active.

return {
  foreground = '#F0D29E',
  background = '#0E0B06',

  cursor_bg = '#F0D29E',
  cursor_fg = '#0E0B06',
  cursor_border = '#F0D29E',

  selection_fg = '#0E0B06',
  selection_bg = '#F0D29E',

  scrollbar_thumb = '#8A9A72',
  split = '#8A9A72',

  ansi = {
    '#0E0B06',  -- black
    '#C85A38',  -- red
    '#6E8E50',  -- green
    '#C98A2E',  -- yellow
    '#74A39A',  -- blue
    '#9E7AA6',  -- magenta
    '#74A39A',  -- cyan
    '#D7B56D',  -- white
  },

  brights = {
    '#8A9A72',  -- bright black
    '#E89A6E',  -- bright red
    '#7A9A60',  -- bright green
    '#E8B54A',  -- bright yellow
    '#92BEB4',  -- bright blue
    '#B89BC0',  -- bright magenta
    '#92BEB4',  -- bright cyan
    '#F0D29E',  -- bright white
  },

  tab_bar = {
    background = '#0E0B06',
    active_tab = {
      bg_color = '#C98A2E',
      fg_color = '#0E0B06',
    },
    inactive_tab = {
      bg_color = '#8A9A72',
      fg_color = '#D7B56D',
    },
    inactive_tab_hover = {
      bg_color = '#8A9A72',
      fg_color = '#F0D29E',
    },
  },
}
