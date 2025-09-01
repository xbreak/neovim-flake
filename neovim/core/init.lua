-- Add custom runtime path where host-specific configuration lives
local config_home = os.getenv("XDG_CONFIG_HOME") or os.getenv("HOME") .. "/.config"
vim.opt.rtp:append(config_home .. "/nvim-xbreak")

-- Global Options
vim.o.showtabline = 0  -- Never show tabline
vim.o.timeoutlen = 500 -- Shorter to enter operator-pending mode faster

vim.opt.matchpairs:append "<:>"

-- Disabled for now as it's a bit too experimental
-- vim.go.cmdheight = 0

--Fixup the terminal colors not set by solarized theme
--@param colors solarized.palette
--@type solarized.color
local fixup_term_colors = function(colors, color)
  local g = vim.g
  -- black
  g.terminal_color_0 = colors.base02
  -- bright black
  g.terminal_color_8 = colors.base03

  -- red
  g.terminal_color_1 = colors.red
  -- bright red
  g.terminal_color_9 = colors.orange

  -- green
  g.terminal_color_2 = colors.green
  -- bright green
  g.terminal_color_10 = colors.base01

  -- yellow
  g.terminal_color_3 = colors.yellow
  -- bright yellow
  g.terminal_color_11 = colors.base00

  -- blue
  g.terminal_color_4 = colors.blue
  -- bright blue
  g.terminal_color_12 = colors.base0

  -- magenta
  g.terminal_color_5 = colors.magenta
  -- bright magenta
  g.terminal_color_13 = colors.violet

  -- cyan
  g.terminal_color_6 = colors.cyan
  -- bright cyan
  g.terminal_color_14 = colors.base1

  -- white
  g.terminal_color_7 = colors.base2
  -- bright white
  g.terminal_color_15 = colors.base3
end

--
-- Plugin configuration
--

-- Solarized
require('solarized').setup({
  transparent = {
    enabled = false,
    pmenu = true,
    normal = true,
    normalfloat = true,
    neotree = false,
    nvimtree = false,
    whichkey = true,
    telescope = true,
    lazy = true,
  },
  on_highlights = function(colors, color)
    -- Use colors from solarized to fixup terminal colors
    fixup_term_colors(colors, color)

    ---@type solarized.highlights
    local groups = {
      -- Builtin
      Keyword = { fg = colors.green },
      Statement = { fg = colors.green },
      Function = { fg = colors.blue },
      Parameter = { link = "Normal" },
      Boolean = { fg = colors.cyan },
      Delimiter = { fg = colors.blue },
      Visual = { fg = colors.base3, bg = colors.base1 },
      Search = { fg = colors.base3, bg = colors.red },
      IncSearch = { fg = colors.base3, bg = colors.yellow },
      LineNr = { fg = colors.base1, bg = colors.base2 },
      CursorLineNr = { fg = colors.base1, bg = colors.base3 },
      WinSeparator = { link = "Normal" },

      -- treesitter
      ["@lsp.type.namespace"] = { fg = colors.blue },
      ["@lsp.type.variable"] = { link = "@variable" },
      ["@operator"] = { fg = colors.base00 },
      ["@constant"] = { fg = colors.cyan },
      ["@keyword"] = { link = "Keyword" },
      ["@number"] = { fg = colors.cyan },
      ["@variable"] = { fg = colors.base00 },
      ["@variable.parameter"] = { link = "Parameter" },
      ["@keyword.import"] = { fg = colors.red },
      ["@punctuation"] = { fg = colors.red },
      ["@punctuation.bracket"] = { fg = colors.red },
      ["@punctuation.special"] = { fg = colors.red },

      -- NvimTree
      -- note: Linking between NvimTree groups caused nvim to randomly hang at startup!
      NvimTreeNormal = { link = "Normal" },
      NvimTreeGitFileNewHL = { fg = colors.red },
      NvimTreeGitNewIcon = { fg = colors.red },
      NvimTreeGitFileStagedHL = { fg = colors.green },
      NvimTreeGitStagedIcon = { fg = colors.green },

      NvimTreeGitFileDirtyHL = { fg = colors.yellow },
      NvimTreeGitDirtyIcon = {  fg = colors.yellow },
    }
    return groups
  end,
  on_colors = function(colors, color)
        local lighten = color.tint
        local darken = color.darken
        local shade = color.shade

        return {
            --default red is a bit too punchy
            red = darken(colors.red, 10),
        }
    end,
  palette = 'solarized', -- solarized (default) | selenized
  variant = 'spring', -- "spring" | "summer" | "autumn" | "winter" (default)
  error_lens = {
    text = false,
    symbol = false,
  },
  styles = {
    enabled = true,
    types = {},
    functions = {},
    parameters = {},
    comments = { italic = true, bold = false },
    strings = {},
    keywords = {},
    variables = {},
    constants = {},
  },
  plugins = {
    treesitter = true,
    lspconfig = true,
    navic = true,
    cmp = true,
    indentblankline = true,
    neotree = false,
    nvimtree = true,
    whichkey = true,
    dashboard = true,
    gitsigns = true,
    telescope = true,
    noice = true,
    hop = true,
    ministatusline = true,
    minitabline = false,
    ministarter = false,
    minicursorword = true,
    notify = true,
    rainbowdelimiters = true,
    bufferline = true,
    lazy = true,
    rendermarkdown = true,
    ale = true,
    coc = true,
    leap = true,
    alpha = true,
    yanky = true,
    gitgutter = true,
    mason = true,
    flash = true,
  },
})

local vim_cmd = vim.api.nvim_command
local lualine = require("lualine")

-- Better bdelete
-- Shorthand alias `Bd` -> `Bufdelete`
vim_cmd([[cnoreabbrev Bd Bdelete]])
vim_cmd([[cnoreabbrev Bd! Bdelete!]])

-- Toggle window maximization
vim.keymap.set("n", "<c-w>o", [[:ToggleOnly<cr>]],
               { silent = true, desc = "Toggle Window Maximization" })

-- Toggle normal/terminal mode with <C-]> for terminal buffers
function _G.set_terminal_keymaps()
  local opts = { buffer = 0, silent = true }
  vim.keymap.set("t", "<C-]>", [[<C-\><C-n>]], opts)
  vim.keymap.set("n", "<C-]>", [[:startinsert<cr>]], opts)
end

vim.cmd([[autocmd! TermOpen term://* lua set_terminal_keymaps()]])

-- Utility functions
local function mixed_indent()
  local space_pat = [[\v^ +]]
  local tab_pat = [[\v^\t+]]
  local space_indent = vim.fn.search(space_pat, "nwc")
  local tab_indent = vim.fn.search(tab_pat, "nwc")
  local mixed = (space_indent > 0 and tab_indent > 0)
  local mixed_same_line
  if not mixed then
    mixed_same_line = vim.fn.search([[\v^(\t+ | +\t)]], "nwc")
    mixed = mixed_same_line > 0
  end
  if not mixed then return "" end
  if mixed_same_line ~= nil and mixed_same_line > 0 then
    return "MI:" .. mixed_same_line
  end
  local space_indent_cnt = vim.fn.searchcount({ pattern = space_pat, max_count = 1e3 }).total
  local tab_indent_cnt = vim.fn.searchcount({ pattern = tab_pat, max_count = 1e3 }).total
  if space_indent_cnt > tab_indent_cnt then
    return "MI:" .. tab_indent
  else
    return "MI:" .. space_indent
  end
end

local function trailing_whitespace()
  local space = vim.fn.search([[\s\+$]], "nwc")
  return space ~= 0 and "TW:" .. space or ""
end

local function get_fg_color(group)
  return vim.fn.synIDattr(vim.fn.hlID(group), "fg", "gui")
end

-- fzf-lua setup
do
  local fzf = require "fzf-lua"
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
  -- Common operations get C-* mapping
  vim.keymap.set("n", "<c-p>", fzf.buffers, { desc = "Fzf Buffers" })
  vim.keymap.set("n", "<c-u>", fzf.files, { desc = "Fzf Files" })
  vim.keymap.set("n", "<c-o>", fzf.git_files, { desc = "Fzf Git Files" })
  -- Less common use <leader>f* mapping
  vim.keymap.set("n", "<leader>fb", fzf.blines, { desc = "Fzf Buffer Lines" })
  vim.keymap.set("n", "<leader>fr", fzf.resume, { desc = "Fzf Resume" })
  vim.keymap.set("n", "<leader>fg", fzf.live_grep_glob, { desc = "Fzf Grep" })
  vim.keymap.set("n", "<leader>fd", fzf.lsp_finder, { desc = "Fzf LSP" })

  -- Use fzf-lua for selections
  fzf.register_ui_select()
end

-- nvim-possession (session management)
-- note: uses fzf-lua
do
  local possession = require "nvim-possession"
  possession.setup({
    -- Defaults from fzf-lua
    fzf_winopts = {
      border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
      height = 0.85, -- window height
      width  = 0.80, -- window width
    }
  })
  vim.api.nvim_create_user_command(
    "Session",
    function(opts)
      -- opts.args string arguments
      -- opts.fargs map of arguments
      local cmd = opts.args
      if cmd == "" then
        cmd = "ls"
      end
      vim.pretty_print(cmd)
      cmds = {
        ["ls"] = function() possession.list() end,
        ["save-as"] = function() possession.new() end,
        ["save"] = function() possession.update() end,
      }
      local found = false
      for k, v in pairs(cmds) do
        if k == cmd then
          found = true
          v()
        end
      end
    end,
    {
      nargs = "?",
      complete = function(ArgLead, CmdLine, CursorPos)
        return { "ls", "save", "save-as" }
      end,
    })
end

-- Cmp
-- See https://github.com/hrsh7th/nvim-cmp/blob/main/lua/cmp/config/mapping.lua for presets
do
  local cmp = require("cmp")
  local format = require"lspkind".cmp_format {
    mode = "symbol_text",
    menu = {
      buffer = "[buf]",
      nvim_lsp = "[lsp]",
      nvim_lua = "[api]",
      path = "[path]",
      luasnip = "[snip]",
      cmdline_history = "[hist]",
    },
  }
  cmp.setup({
    confirmation = { default_behavior = cmp.ConfirmBehavior.Replace },
    formatting = {
      format = format
    },
    mapping = cmp.mapping.preset.insert({
      ["<C-b>"] = cmp.mapping.scroll_docs(-4),
      ["<C-f>"] = cmp.mapping.scroll_docs(4),
      ["<C-Space>"] = cmp.mapping.complete(),
      ["<C-e>"] = cmp.mapping.abort(),
      ["<CR>"] = cmp.mapping.confirm({ select = false }), -- <CR> shouldn't select any completion unless selected
      ["<C-y>"] = cmp.mapping.confirm({ select = true }), -- <C-y> is a shortcut for <C-n><C-R>
    }),
    snippet = {
      expand = function(args)
        luasnip.lsp_expand(args.body)
      end,
    },
    sources = {
      {
        name = "nvim_lsp",
        entry_filter = function(entry, ctx)
          return require "cmp".lsp.CompletionItemKind.Snippet ~= entry:get_kind()
        end
      },
      { name = "path" },
      { name = "nvim_lua" },
      { name = "buffer",                 keyword_length = 3 },
      { name = "luasnip" },
      { name = "nvim_lsp_signature_help" },
    },
    formatting = {
      format = format,
    },
    experimental = {
      native_menu = false,
      ghost_text = true,
    },
  })

  -- cmdline preset is broken will mess upp standard command line completion:
  -- https://github.com/hrsh7th/nvim-cmp/issues/1511
  --[[
  cmp.setup.cmdline({ "/", "?" }, {
    mapping = cmp.mapping.preset.cmdline(),
    formatting = {
      format = format,
    },
    sources = {
      { name = "buffer" },
      { name = "cmdline_history" },
      { name = "nvim_lsp_document_symbol" },
    },
  })
  --]]
end

-- lualine
do
  local lualine_toggleterm = {
    filetypes = { "toggleterm" },
    winbar = {},
    sections = {
      lualine_a = {
        "mode",
        function()
          return "ToggleTerm #" .. vim.b.toggle_number
        end
      },
    },
  }

  local solarized_palette = require 'solarized.palette'
  local colors = require('solarized.utils').get_colors()
  local foreground = colors.base02
  local theme = "solarized_light"
  if vim.o.background == 'dark' then
    foreground = colors.base2
    theme = "solarized_dark"
  end

  lualine.setup {
    options = {
      icons_enabled = true,
      theme = theme,
      component_separators = { left = "", right = "" },
      section_separators = { left = "", right = "" },
      disabled_filetypes = { "NvimTree" },
      always_divide_middle = true,
      -- Enable only for modifiable buffers
      cond = function() return vim.bo.modifiable or vim.bo.filetype == "toggleterm" end,
    },
    extensions = { lualine_toggleterm },
    sections = {
      lualine_a = { "mode" },
      lualine_b = { "branch", "diff" },
      lualine_c = {},
      lualine_x = {
        "diagnostics",
        "encoding",
        "fileformat",
        "filetype",
        -- note: Certain colorschemes do not specify the bg color for the highlight group I want to
        -- use, this leads to the separator < not showing, so I just set the fg color instead.
        { trailing_whitespace, color = { fg = get_fg_color("DiagnosticError") } },
        { mixed_indent,        color = { fg = get_fg_color("DiagnosticError") } },
      },
      lualine_y = {},
      lualine_z = { "location" }
    },
    winbar = {
      lualine_a = {
        { "filetype", icon_only = true },
        { "filename", path = 1 }
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
        { "filetype", icon_only = true },
        { "filename", path = 1 }
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

-- NvimTree
-- For git status mapping see:
-- https://github.com/nvim-tree/nvim-tree.lua/blob/master/lua/nvim-tree/renderer/decorator/git.lua
require "nvim-tree".setup {
  filters = {
    custom = { "^\\.git$" },
  },
  renderer = {
    group_empty = true,
    icons = {
      glyphs = {
        git = {
          unstaged = "\u{ea73}",
          staged = "\u{f00c}",
          unmerged = "",
          renamed = "➜",
          untracked = "?",
          deleted = "\u{f01b4}",
        }
      }
    }
  }
}

-- nvim-notify
do
  local notify = require "notify"
  notify.setup({
    stages = "static",
  })
  -- Hook up notify to be used by vim
  vim.notify = notify

  -- For some reason we cannot fix highlights immedately but have to
  -- schedule it (maybe notify itself sets up things lazily).
  vim.schedule(function()
    -- Fix up default highlight
    local link = function(from, to)
      -- To get the equivalent of `hi! link <from> <to>` we have to clear <from> first
      -- https://github.com/neovim/neovim/issues/20323
      vim.api.nvim_set_hl(0, from, {})
      vim.api.nvim_set_hl(0, from, { link = to })
    end
    link("NotifyERRORBorder", "DiagnosticError")
    link("NotifyERRORIcon", "DiagnosticError")
    link("NotifyERRORTitle", "DiagnosticError")

    link("NotifyWARNBorder", "DiagnosticWarn")
    link("NotifyWARNIcon", "DiagnosticWarn")
    link("NotifyWARNTitle", "DiagnosticWarn")

    link("NotifyINFOBorder", "DiagnosticInfo")
    link("NotifyINFOIcon", "DiagnosticInfo")
    link("NotifyINFOTitle", "DiagnosticInfo")

    link("NotifyDEBUGBorder", "DiagnosticHint")
    link("NotifyDEBUGIcon", "DiagnosticHint")
    link("NotifyDEBUGTitle", "DiagnosticHint")

    link("NotifyTRACEBorder", "Comment")
    link("NotifyTRACEIcon", "Comment")
    link("NotifyTRACETitle", "Comment")
  end)
end

-- easy-motion that doesn't modify buffer
require "hop".setup {
  case_insensitive = false,
  current_line_only = false,
  inclusive_jump = false
}

-- hop
vim.keymap.set("n", "s", function()
                 require "hop".hint_char1({})
               end,
               { desc = "Hop" })

vim.keymap.set("n", "gs", function()
                 require "hop".hint_char1({
                   multi_windows = true,
                 })
               end,
               { desc = "Hop Multi Windows" })

-- Operator pending mapping
vim.keymap.set("o", "s", function()
                 require "hop".hint_char1({
                   inclusive_jump = true
                 })
               end,
               { desc = "Hop" })

-- Tree-sitter
local function ts_disable(_, bufnr)
  return vim.api.nvim_buf_line_count(bufnr) > 5000
end

require "nvim-treesitter.configs".setup {
  -- Broken by https://github.com/nvim-treesitter/nvim-treesitter/pull/3250
  -- see also https://github.com/NixOS/nixpkgs/issues/189838
  -- one of "all", "language", or a list of languages
  -- ensure_installed = {"cpp", "python", "latex", "nix", "yaml", "json", "rst"},
  highlight = {
    enable = true, -- false will disable the whole extension
    disable = function(lang, bufnr)
      return ts_disable(lang, bufnr)
    end,
    custom_captures = {
      -- Highlight the @log4cplus.stmt capture group with the "Comment" highlight group to reduce "noise"
      ["log4cplus.stmt"] = "Comment",
    }
  },
  playground = {
    enable = true,
    disable = {},
    updatetime = 25,         -- Debounced time for highlighting nodes in the playground from source code
    persist_queries = false, -- Whether the query persists across vim sessions
    keybindings = {
      toggle_query_editor = "o",
      toggle_hl_groups = "i",
      toggle_injected_languages = "t",
      toggle_anonymous_nodes = "a",
      toggle_language_display = "I",
      focus_language = "f",
      unfocus_language = "F",
      update = "R",
      goto_node = "<cr>",
      show_help = "?",
    },
  }
}
--[[
-- custom_captures are deprecated
require"nvim-treesitter.highlight".set_custom_captures {
  -- Highlight the @log4cplus.stmt capture group with the "Comment" highlight group to reduce "noise"
  ["log4cplus.stmt"] = "Comment",
}
]]
require "treesitter-context".setup {
  enable = true,        -- Enable this plugin (Can be enabled/disabled later via commands)
  max_lines = 0,        -- How many lines the window should span. Values <= 0 mean no limit.
  trim_scope = "outer", -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
  patterns = {
    -- Match patterns for TS nodes. These get wrapped to match at word boundaries.
    cpp = {
      "namespace_definition",
    },
    javascript = {
      "object",
      "pair",
    },
    json = {
      "object",
      "pair",
    },
    yaml = {
      "block_mapping_pair",
      "block_sequence_item",
    },
    toml = {
      "table",
      "pair",
    },
    markdown = {
      "section",
    },
    -- note: rst is not really supported yet

    -- For all filetypes
    -- Note that setting an entry here replaces all other patterns for this entry.
    -- By setting the 'default' entry below, you can control which nodes you want to
    -- appear in the context window.
    default = {
      "class",
      "function",
      "method",
      "namespace",
      -- 'for', -- These won't appear in the context
      -- 'while',
      -- 'if',
      -- 'switch',
      -- 'case',
    },
  },
  exact_patterns = {
    -- Example for a specific filetype with Lua patterns
    -- Treat patterns.rust as a Lua pattern (i.e "^impl_item$" will
    -- exactly match "impl_item" only)
    -- rust = true,
  },

  -- [!] The options below are exposed but shouldn't require your attention,
  --     you can safely ignore them.

  zindex = 20,     -- The Z-index of the context window
  mode = "cursor", -- Line used to calculate context. Choices: 'cursor', 'topline'
  separator = nil, -- Separator between context and content. Should be a single character string, like '-'.
}

-- Toggle term
do
  local term = require "toggleterm.terminal"
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
        require "toggleterm".toggle(last_opened_closed)
      else
        -- If there was no terminal - do nothing for the moment
        -- as we'd want to take direction into account for example.
      end
    end
  end

  require "toggleterm".setup {
    -- Disable shading as this results in using white background with solarized light
    shade_terminals = false,
    on_open = function(t)
      if not t.__xbreak_first then
        t.__xbreak_first = true
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

  -- Predefine mappings for standard terminal layouts.
  -- In a later revision the idea is to allow the visible terminals to be toggled as a group.
  vim.keymap.set("n", "<leader>1", [[:2ToggleTerm direction=horizontal<cr>]],
                 { desc = "Toggle Horizontal Term 1" })
  vim.keymap.set("n", "<leader>2", [[:3ToggleTerm direction=horizontal<cr>]],
                 { desc = "Toggle Horizontal Term 2" })
  vim.keymap.set("n", "<leader>3", [[:4ToggleTerm direction=horizontal<cr>]],
                 { desc = "Toggle Horizontal Term 3" })

  vim.keymap.set("n", "<leader>5", [[:1ToggleTerm direction=float<cr>]],
                 { desc = "Toggle Floating Term" })

  vim.keymap.set("n", "<leader>6", [[:5ToggleTerm direction=vertical<cr>]],
                 { desc = "Toggle Vertical Term 1" })
  vim.keymap.set("n", "<leader>7", [[:6ToggleTerm direction=vertical<cr>]],
                 { desc = "Toggle Vertical Term 2" })
  vim.keymap.set("n", "<leader>8", [[:7ToggleTerm direction=vertical<cr>]],
                 { desc = "Toggle Vertical Term 3" })
  -- Toggle term with ctrl-space
  vim.keymap.set({ "n", "t" }, "<C-space>", toggle,
                { desc = "Toggle Current/Last Terminal" })
end

-- Set colorscheme to solarized
vim.cmd [[colorscheme solarized]]
