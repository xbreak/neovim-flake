local vim_cmd = vim.api.nvim_command
local lualine = require('lualine')

local function mixed_indent()
  local space_pat = [[\v^ +]]
  local tab_pat = [[\v^\t+]]
  local space_indent = vim.fn.search(space_pat, 'nwc')
  local tab_indent = vim.fn.search(tab_pat, 'nwc')
  local mixed = (space_indent > 0 and tab_indent > 0)
  local mixed_same_line
  if not mixed then
    mixed_same_line = vim.fn.search([[\v^(\t+ | +\t)]], 'nwc')
    mixed = mixed_same_line > 0
  end
  if not mixed then return '' end
  if mixed_same_line ~= nil and mixed_same_line > 0 then
     return 'MI:'..mixed_same_line
  end
  local space_indent_cnt = vim.fn.searchcount({pattern=space_pat, max_count=1e3}).total
  local tab_indent_cnt =  vim.fn.searchcount({pattern=tab_pat, max_count=1e3}).total
  if space_indent_cnt > tab_indent_cnt then
    return 'MI:'..tab_indent
  else
    return 'MI:'..space_indent
  end
end

local function trailing_whitespace()
  local space = vim.fn.search([[\s\+$]], 'nwc')
  return space ~= 0 and "TW:"..space or ""
end

local function get_fg_color(group)
    return vim.fn.synIDattr(vim.fn.hlID(group), "fg", "gui" )
end

lualine.setup {
  options = {
    icons_enabled = true,
    theme = 'auto',
    component_separators = { left = '', right = ''},
    section_separators = { left = '', right = ''},
    disabled_filetypes = {'NvimTree'},
    always_divide_middle = true,
    -- Enable only for modifiable buffers
    cond = function() return  vim.bo.modifiable end,
  },
  sections = {
    lualine_a = {'mode'},
    lualine_b = {'branch', 'diff'},
    lualine_c = {
        {'filename', path=1},
    },
    lualine_x = {
      'diagnostics',
      'encoding',
      'fileformat',
      'filetype',
      -- note: Certain colorschemes do not specify the bg color for the highlight group I want to
      -- use, this leads to the separator < not showing, so I just set the fg color instead.
      {trailing_whitespace, color={fg=get_fg_color('DiagnosticError')}},
      {mixed_indent, color={fg=get_fg_color('DiagnosticError')}},
    },
    lualine_y = {},
    lualine_z = {'location'}
  },
  tabline = {},
  extensions = {}
}

-- nvim-tree
require'nvim-tree'.setup {}

-- easy-motion that doesn't modify buffer
require'hop'.setup {
    case_insensitive=false,
}
vim.api.nvim_set_keymap('n', 's', "<cmd>lua require'hop'.hint_char1({ current_line_only = false, inclusive_jump = false })<cr>", {})
-- Vim surround occupies "s" so we use <leader>s
vim.api.nvim_set_keymap('o', '<leader>s', "<cmd>lua require'hop'.hint_char1({ current_line_only = false, inclusive_jump = true })<cr>", {})

-- Also triggers autocmds from init.vim
vim_cmd('colorscheme solarized')
