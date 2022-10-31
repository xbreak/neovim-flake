local config_home = os.getenv("XDG_CONFIG_HOME") or os.getenv("HOME") .. '/.config'
local xbreak_config = config_home .. "/nvim-xbreak"

local cmp = require("cmp")
local lspconfig = require("lspconfig")

local ok, lspkind = pcall(require, "lspkind")
if not ok then
  return
end

local capabilities = require("cmp_nvim_lsp").update_capabilities(
vim.lsp.protocol.make_client_capabilities(),
    {
      -- Disable snippet support to avoid getting "helpful" snippets from clangd
      -- (doesn't seem to work as cmp still presents [lsp] sourced snippets)
      snippetSupport = false
    }
)

-- Accepts a table of paths that are filtered based on if they exist
local function filter_existing_dirs(dirs)
  local filtered = {}
  for _, d in ipairs(dirs) do
    if vim.fn.isdirectory(vim.fn.expand(d)) ~= 0 then
      table.insert(filtered, d)
    end
  end
  return filtered
end

local function on_attach(_, buf)
  local map = {
    K = "lua vim.lsp.buf.hover()",
    ["<space>dd"] = "Trouble document_diagnostics",
    ["<space>dw"] = "Trouble workspace_diagnostics",
    ["="] = "lua vim.lsp.buf.format( { async = true })",
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
    "n", "<Leader>df", "<cmd>lua vim.diagnostic.open_float()<CR>",
    { noremap = true, silent = true }
  )

  -- Disabled while evaluating using cmp-nvim-lsp-signature-help only.
  -- lsp_signature
  -- require "lsp_signature".on_attach({
  --   handler_opts = {
  --     border = "none"
  --   }
  -- }, buf)
end

-- Luasnip
local luasnip = require("luasnip")
luasnip.config.set_config {
  -- Keep last snippet around -> can jump back in.
  history = true;
}

-- Note: Luasnip doesn't handle non-exiting directories
require("luasnip.loaders.from_lua").lazy_load({
  paths = filter_existing_dirs({ xbreak_config .. "/luasnip", ".luasnip" })
})

-- Navigate forward/expand snippet
vim.keymap.set({ "i", "s" }, "<c-k>", function()
  if luasnip.expand_or_jumpable() then
    luasnip.expand_or_jump()
  end
end, { silent = true })

-- Navigate backward
vim.keymap.set({ "i", "s" }, "<c-j>", function()
  if luasnip.jumpable(-1) then
    luasnip.jump(-1)
  end
end, { silent = true })

-- Select an option
vim.keymap.set("i", "<c-l>", function()
  -- If there's no active choice don't do anything
  if not require "luasnip.session".active_choice_node then
    return
  end
  if luasnip.choice_active() then
    luasnip.change_choice(1)
  end
end)
vim.keymap.set("i", "<c-u>", require "luasnip.extras.select_choice")


-- Cmp
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

    ["<C-n>"] = cmp.mapping.select_next_item { behavior = cmp.SelectBehavior.Insert },
    ["<C-p>"] = cmp.mapping.select_prev_item { behavior = cmp.SelectBehavior.Insert },
    ["<C-d>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-e>"] = cmp.mapping.abort(),
    ["<cr>"] = cmp.mapping.confirm(),
    ["<c-y>"] = cmp.mapping(
      cmp.mapping.confirm {
        behavior = cmp.ConfirmBehavior.Insert,
        select = true,
      },
      { "i", "c" }
    ),
    ["<c-space>"] = cmp.mapping {
      i = cmp.mapping.complete(),
      c = function(
        _ --[[fallback]]
      )
        if cmp.visible() then
          if not cmp.confirm { select = true } then
            return
          end
        else
          cmp.complete()
        end
      end,
    },
  },
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  sources = {
    { name = "nvim_lsp" },
    { name = "path" },
    { name = "buffer", keyword_length = 3 },
    { name = "luasnip" },
    { name = "nvim_lsp_signature_help" },
  },
  formatting = {
    format = lspkind.cmp_format {
      with_text = true,
      menu = {
        buffer = "[buf]",
        nvim_lsp = "[lsp]",
        nvim_lua = "[api]",
        path = "[path]",
        luasnip = "[snip]",
      },
    },
  },
  experimental = {
    native_menu = false,
    ghost_text = true,
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
      plugins = {
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
    "--query-driver=**/g++,**/gcc",
    "--all-scopes-completion",
  },
  on_attach = on_attach,
})

-- lua lsp
require "lspconfig".sumneko_lua.setup {
  cmd = { "@sumneko_lua_language_server@/bin/lua-language-server" },
  on_attach = on_attach,
  capabilities = capabilities,
  settings = {
    Lua = {
      runtime = {
        -- Tell the language server which version of Lua you're using
        -- (most likely LuaJIT in the case of Neovim)
        version = "LuaJIT",
      },
      format = {
        enable = true,
        defaultConfig = {
          -- c.f. https://github.com/CppCXY/EmmyLuaCodeStyle/blob/master/lua.template.editorconfig
          indent_style = "space",
          indent_size = "2",
          quote_style = "double",
          max_line_length = "120",
          align_call_args = "true",
        },
      },
      diagnostics = {
        -- Get the language server to recognize the `vim` global
        globals = { "vim" },
      },
      workspace = {
        -- Make the server aware of Neovim runtime files
        library = vim.api.nvim_get_runtime_file("", true),
      },
      -- Do not send telemetry data containing a randomized but unique identifier
      telemetry = {
        enable = false,
      },
    },
  },
}

require("trouble").setup()


-- Set up clang-format

vim.cmd([[
  au FileType cpp setlocal
  \ equalprg=@clang_unwrapped@/bin/clang-format\ --style=file\ --fallback-style=none
  ]])
