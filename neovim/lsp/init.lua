local cmp = require("cmp")
local lspconfig = require("lspconfig")
local luasnip = require("luasnip")


local capabilities = require("cmp_nvim_lsp").update_capabilities(
  vim.lsp.protocol.make_client_capabilities()
)

local function on_attach(_, buf)
  local map = {
    K = "lua vim.lsp.buf.hover()",
    ["<space>d"] = "Trouble document_diagnostics",
    ["<space>e"] = "Trouble workspace_diagnostics",
    ["="] = "lua vim.lsp.buf.formatting()",
    ["<space>r"] = "Trouble lsp_references",
    ["[d"] = "lua vim.lsp.diagnostic.goto_prev()",
    ["]d"] = "lua vim.lsp.diagnostic.goto_next()",
    ga = "CodeActionMenu",
    gd = "lua vim.lsp.buf.definition()",
    ge = "lua vim.lsp.diagnostic.show_line_diagnostics()",
    gr = "lua vim.lsp.buf.rename()",
    gt = "lua vim.lsp.buf.type_definition()",
  }

  for k, v in pairs(map) do
    vim.api.nvim_buf_set_keymap(
      buf,
      "n",
      k,
      "<cmd>" .. v .. "<cr>",
      { noremap = true }
    )
  end

  vim.api.nvim_buf_set_keymap(
    buf,
    "v",
    "<space>f",
    "<cmd>lua vim.lsp.buf.range_formatting()<cr>",
    { noremap = true }
  )

  vim.api.nvim_buf_set_keymap(
    buf,
    "v",
    "ga",
    "<cmd>CodeActionMenu<cr>",
    { noremap = true }
  )
  -- Show all diagnostics on current line in floating window
  vim.api.nvim_set_keymap(
    'n', '<Leader>do', '<cmd>lua vim.diagnostic.open_float()<CR>',
    { noremap = true, silent = true }
  )
  
  -- lsp_signature
  require "lsp_signature".on_attach({
    handler_opts = {
      border = "none"
    }
  }, buf)
end
--
-- Tree-sitter
require'nvim-treesitter.configs'.setup {
  ensure_installed = {"cpp", "python", "latex", "nix", "yaml", "json", "rst"},     -- one of "all", "language", or a list of languages
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

-- require("vim.treesitter.query").set_query("cpp", "log4cplus", [[
-- (expression_statement
--   (call_expression
--     function:
--       (identifier) @log4cplus.macro
--       (#lua-match? @log4cplus.macro "^LOG4CPLUS_[A-Z_]+")
--   )
--   @log4cplus.stmt)
-- ]])


cmp.setup({
  confirmation = { default_behavior = cmp.ConfirmBehavior.Replace },
  formatting = {
    format = require("lspkind").cmp_format({ with_text = false }),
  },
  mapping = {
    ["<C-e>"] = function(fallback)
      cmp.close()
      fallback()
    end,
    ['<C-n>'] = cmp.mapping(cmp.mapping.select_next_item(), {'i','c'}),
    ['<C-p>'] = cmp.mapping(cmp.mapping.select_prev_item(), {'i','c'}),
    ["<cr>"] = cmp.mapping.confirm(),
    ["<m-cr>"] = cmp.mapping.confirm({ select = true }),
    ["<S-Tab>"] = cmp.mapping({
      i = function(fallback)
        if not cmp.select_prev_item() and not luasnip.jump(-1) then
          fallback()
        end
      end,
      c = cmp.mapping.select_prev_item(),
    }),
    ["<Tab>"] = cmp.mapping({
      i = function(fallback)
        if not cmp.select_next_item() and not luasnip.jump(1) then
          fallback()
        end
      end,
      c = cmp.mapping.select_next_item(),
    }),
  },
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  sources = {
    { name = "nvim_lsp" },
    { name = "path" },
    -- { name = "luasnip" },
    { name = "buffer", keyword_length = 3 },
  },
})

cmp.setup.cmdline("/", {
  sources = {
    { name = "nvim_lsp_document_symbol" },
    { name = "buffer" },
  },
})

cmp.setup.cmdline(":", {
  completion = { autocomplete = false },
  mapping = cmp.mapping.preset.cmdline({}),
  sources = cmp.config.sources({
    { name = "cmdline" },
    { name = "path" },
  }),
})

lspconfig.pylsp.setup({
  capabilities = capabilities,
  cmd = { "@python_lsp_server@/bin/pylsp" },
  on_attach = on_attach,
    settings = {
    pylsp = {
      plugins =  {
        pycodestyle = {
          maxLineLength = 100,
        },
      },
    },
  },

})

lspconfig.yamlls.setup({
  capabilities = capabilities,
  cmd = { "@yaml_language_server@/bin/yaml-language-server", "--stdio" },
  on_attach = on_attach,
})

lspconfig.clangd.setup({
  capabilities = capabilities,
  cmd = {
    "@clang_unwrapped@/bin/clangd",
    "--background-index",
    "--log=info",
    "--resource-dir=@clang@/resource-root",
    "--query-driver=**/g++,**/gcc"
  },
  on_attach = on_attach,
})

require("trouble").setup()


-- Set up clang-format

vim.cmd([[
  au FileType cpp setlocal
  \ equalprg=@clang_unwrapped@/bin/clang-format\ --style=file\ --fallback-style=none
  ]])
