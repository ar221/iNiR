-- Apollo preset — WezTerm colors
-- Hand-authored; deployed in place of ii-generator output when Apollo is active.

return {
  foreground = '#FFFBEE',
  background = '#0E0B08',

  cursor_bg = '#FFFBEE',
  cursor_fg = '#0E0B08',
  cursor_border = '#FFFBEE',

  selection_fg = '#0E0B08',
  selection_bg = '#FFFBEE',

  scrollbar_thumb = '#98876F',
  split = '#98876F',

  ansi = {
    '#0E0B08',  -- black
    '#FF5A4E',  -- red
    '#A8C97B',  -- green
    '#FFB648',  -- yellow
    '#6FC5C0',  -- blue
    '#D28BD8',  -- magenta
    '#8FE2DD',  -- cyan
    '#F2E3C6',  -- white
  },

  brights = {
    '#98876F',  -- bright black
    '#FF8274',  -- bright red
    '#C9E89B',  -- bright green
    '#FFD080',  -- bright yellow
    '#8FE2DD',  -- bright blue
    '#EBA9F0',  -- bright magenta
    '#A2F1E0',  -- bright cyan
    '#FFFBEE',  -- bright white
  },

  tab_bar = {
    background = '#0E0B08',
    active_tab = {
      bg_color = '#FFB648',
      fg_color = '#2B1F10',
    },
    inactive_tab = {
      bg_color = '#98876F',
      fg_color = '#F2E3C6',
    },
    inactive_tab_hover = {
      bg_color = '#98876F',
      fg_color = '#FFFBEE',
    },
  },
}
