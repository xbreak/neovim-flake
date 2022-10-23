-- Global Options
vim.o.showtabline = 0  -- Never show tabline
vim.o.timeoutlen = 500  -- Shorter to enter operator-pending mode faster

-- Disabled for now as it's a bit too experimental
-- vim.go.cmdheight = 0


-- Plugin configuration

local vim_cmd = vim.api.nvim_command
local lualine = require('lualine')

-- Better bdelete
-- Shorthand alias `Bd` -> `Bufdelete`
vim_cmd([[cnoreabbrev Bd Bdelete]])
vim_cmd([[cnoreabbrev Bd! Bdelete!]])

-- Toggle window maximization
vim.keymap.set("n", "<c-w>o", [[:ToggleOnly<cr>]], { silent = true })

-- Toggle normal/terminal mode with <C-]> for terminal buffers
function _G.set_terminal_keymaps()
  local opts = {buffer = 0, silent = true}
  vim.keymap.set('t', '<C-]>', [[<C-\><C-n>]], opts)
  vim.keymap.set('n', '<C-]>', [[:startinsert<cr>]], opts)
end
vim.cmd([[autocmd! TermOpen term://* lua set_terminal_keymaps()]])

-- Utility functions
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

-- fzf-lua setup
do
  local fzf = require'fzf-lua'
  fzf.setup {
    winopts = {
      preview = {
        -- default preview delay of 100ms feels a tad laggy
        delay = 10,
      },
    },
    files = {
     -- Follow symbolic links and prune dot directories
      find_opts = [[-type d -path \*/\.* -prune -o -not -name .\*  -follow -type f -print]],
    },
  }
  -- fzf-lua mappings
  vim.keymap.set("n", "<c-p>", fzf.buffers, {})
  vim.keymap.set("n", "<c-u>", fzf.files, {})
  vim.keymap.set("n", "<c-o>", fzf.git_files, {})
  vim.keymap.set("n", "<c-y>", fzf.blines, {})
  vim.keymap.set("n", "<leader>gg", fzf.live_grep_glob, {})
end

-- lualine
do
  local lualine_toggleterm = {
    filetypes = { "toggleterm" },
    winbar = { },
    sections = {
      lualine_a = {
        'mode',
        function()
          return 'ToggleTerm #' .. vim.b.toggle_number
        end
      },
    },
  }

  lualine.setup {
    options = {
      icons_enabled = true,
      -- TODO: Patch solarized to make TERMINAL mode prominent
      --       this needs to take colorscheme switching into account though.
      --       see https://github.com/nvim-lualine/lualine.nvim#customizing-themes
      theme = 'auto',
      component_separators = { left = '', right = ''},
      section_separators = { left = '', right = ''},
      disabled_filetypes = {'NvimTree'},
      always_divide_middle = true,
      -- Enable only for modifiable buffers
      cond = function() return vim.bo.modifiable or vim.bo.filetype == "toggleterm" end,
    },
    extensions = { lualine_toggleterm },
    sections = {
      lualine_a = {'mode'},
      lualine_b = {'branch', 'diff'},
      lualine_c = {},
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
    winbar = {
      lualine_a = {
        {'filetype', icon_only = true},
        {'filename', path=1}
      },
      lualine_b = {},
      lualine_c = {},
      lualine_x = {},
      lualine_y = {},
      lualine_z = {
        function()
          -- Indicate if window is maximized via ToggleOnly
          if vim.b.maximized_window_id then
            return "Maximized"
          end
          return ""
        end
      }
    },
    inactive_winbar = {
      lualine_a = {
        {'filetype', icon_only = true},
        {'filename', path=1}
      },
      lualine_b = {},
      lualine_c = {},
      lualine_x = {},
      lualine_y = {},
      lualine_z = {}
    },
    tabline = {},
  }
end

-- nvim-tree
require'nvim-tree'.setup {
  renderer = {
    icons = {
      glyphs = {
        git = {
          unstaged = "ﯽ", -- ",
          staged = "",
          unmerged = "",
          renamed = "➜",
          untracked = "ﬤ",
          deleted = "ﮁ",
        }
      }
    }
  }
}

-- easy-motion that doesn't modify buffer
require"hop".setup {
    case_insensitive=false,
    current_line_only = false,
    inclusive_jump = false
}

-- hop
vim.keymap.set("n", "s", function()
    require"hop".hint_char1({})
  end, {})

vim.keymap.set("n", "gs", function()
    require"hop".hint_char1({
      multi_windows = true,
      })
  end, {})

-- Operator pending mapping
vim.keymap.set("o", "s", function()
    require"hop".hint_char1({
        inclusive_jump = true
      })
  end, {})

-- Tree-sitter
require'nvim-treesitter.configs'.setup {
  -- Broken by https://github.com/nvim-treesitter/nvim-treesitter/pull/3250
  -- see also https://github.com/NixOS/nixpkgs/issues/189838
  -- one of "all", "language", or a list of languages
  -- ensure_installed = {"cpp", "python", "latex", "nix", "yaml", "json", "rst"},
  highlight = {
    enable = true,              -- false will disable the whole extension
  },
  playground = {
    enable = true,
    disable = {},
    updatetime = 25, -- Debounced time for highlighting nodes in the playground from source code
    persist_queries = false, -- Whether the query persists across vim sessions
    keybindings = {
      toggle_query_editor = 'o',
      toggle_hl_groups = 'i',
      toggle_injected_languages = 't',
      toggle_anonymous_nodes = 'a',
      toggle_language_display = 'I',
      focus_language = 'f',
      unfocus_language = 'F',
      update = 'R',
      goto_node = '<cr>',
      show_help = '?',
    },
  }
}

require"nvim-treesitter.highlight".set_custom_captures {
  -- Highlight the @log4cplus.stmt capture group with the "Comment" highlight group to reduce "noise"
  ["log4cplus.stmt"] = "Comment",
}

require'treesitter-context'.setup{
    enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
    max_lines = 0, -- How many lines the window should span. Values <= 0 mean no limit.
    trim_scope = 'outer', -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
    patterns = { -- Match patterns for TS nodes. These get wrapped to match at word boundaries.
        -- For all filetypes
        -- Note that setting an entry here replaces all other patterns for this entry.
        -- By setting the 'default' entry below, you can control which nodes you want to
        -- appear in the context window.
        default = {
            'class',
            'function',
            'method',
            'namespace',
            -- 'for', -- These won't appear in the context
            -- 'while',
            -- 'if',
            -- 'switch',
            -- 'case',
        },
        -- Example for a specific filetype.
        -- If a pattern is missing, *open a PR* so everyone can benefit.
        --   rust = {
        --       'impl_item',
        --   },
    },
    exact_patterns = {
        -- Example for a specific filetype with Lua patterns
        -- Treat patterns.rust as a Lua pattern (i.e "^impl_item$" will
        -- exactly match "impl_item" only)
        -- rust = true,
    },

    -- [!] The options below are exposed but shouldn't require your attention,
    --     you can safely ignore them.

    zindex = 20, -- The Z-index of the context window
    mode = 'cursor',  -- Line used to calculate context. Choices: 'cursor', 'topline'
    separator = nil, -- Separator between context and content. Should be a single character string, like '-'.
}

-- Toggle term
do
  local term = require"toggleterm.terminal"
  -- Local state to support reopen last terminal when no terminal is focused
  local last_opened_closed = nil

  --- Closes if current window is a toggleterm
  --- Opens last opened toggleterm otherwise
  local function toggle()
    if vim.bo.filetype == "toggleterm" then
      -- Current buffer is a toggle terminal
      -- -> close it.
      for _, t in ipairs(term.get_all()) do
        if t:is_focused() then
          t:close()
          return
        end
      end
    else
      -- Toggle last terminal
      -- TODO: reopen in last position?
      if last_opened_closed then
        require"toggleterm".toggle(last_opened_closed)
      else
        -- If there was no terminal - do nothing for the moment
        -- as we'd want to take direction into account for example.
      end
    end
  end

  require"toggleterm".setup {
    -- Disable shading as this results in using white background with solarized light
    shade_terminals = false,
    on_open = function(t)
      if not t.__xbreak_first then
        t.__xbreak_first = true
        -- Set simplified PS1 when first entering terminal
        -- NOTE: This assumes that it's an interactive shell, so will
        -- randomly fail otherwise.
        t:send([[ set +o history; unset PROMPT_COMMAND; export PS1="\w$ "; clear; set -o history]])
      end
      last_opened_closed = t.id
    end,
    on_close = function(t)
      last_opened_closed = t.id
    end,
    size = function(term)
      if term.direction == "horizontal" then
        return 30
      elseif term.direction == "vertical" then
        return vim.o.columns * 0.5
      end
    end,
  }


  vim.keymap.set("n", "<leader>1", [[:1ToggleTerm direction=float<cr>]], {})

  vim.keymap.set("n", "<leader>2", [[:2ToggleTerm direction=horizontal<cr>]], {})
  vim.keymap.set("n", "<leader>3", [[:3ToggleTerm direction=horizontal<cr>]], {})
  vim.keymap.set("n", "<leader>4", [[:4ToggleTerm direction=horizontal<cr>]], {})

  vim.keymap.set("n", "<leader>5", [[:5ToggleTerm direction=vertical<cr>]], {})
  vim.keymap.set("n", "<leader>6", [[:6ToggleTerm direction=vertical<cr>]], {})
  vim.keymap.set("n", "<leader>7", [[:7ToggleTerm direction=vertical<cr>]], {})
  -- Toggle term with ctrl-space
  vim.keymap.set({"n", "t"}, "<C-space>", toggle, {})
end

-- Also triggers autocmds from init.vim
vim_cmd('colorscheme solarized')
