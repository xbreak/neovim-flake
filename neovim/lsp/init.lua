local config_home = os.getenv("XDG_CONFIG_HOME") or os.getenv("HOME") .. "/.config"
local xbreak_config = config_home .. "/nvim-xbreak"

local lspconfig = require("lspconfig")

local ok, lspkind = pcall(require, "lspkind")
if not ok then
  return
end

-- Builtin
vim.diagnostic.config({
  -- Use the default configuration
  -- virtual_lines = true

  -- Alternatively, customize specific options
  virtual_lines = {
   -- Only show virtual line diagnostics for the current cursor line
   current_line = true,
  },
})

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client:supports_method('textDocument/completion') then
      vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
    end
  end,
})


local capabilities = require("cmp_nvim_lsp").default_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = false;

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
    -- Note: Some keymaps are setup with lspsaga.nvim below
    K = "lua vim.lsp.buf.hover()",
    ["="] = "lua vim.lsp.buf.format( { async = true })",
    ["[d"] = "lua vim.lsp.diagnostic.goto_prev()",
    ["]d"] = "lua vim.lsp.diagnostic.goto_next()",
    gd = "lua vim.lsp.buf.definition()",
    gt = "lua vim.lsp.buf.type_definition()",
    ge = "lua vim.lsp.diagnostic.show_line_diagnostics()", -- obsolete after virtual lines
    -- gr = "lua vim.lsp.buf.rename()",
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

-- vim.lsp setup
do
  -- Setup notifications from lsp to use vim.notify
  -- table from lsp severity to vim severity.
  local severity = {
    "error",
    "warn",
    "info",
    "info", -- map both hint and info to info?
  }
  vim.lsp.handlers["window/showMessage"] = function(err, method, params, client_id)
    vim.notify(method.message, severity[params.type])
  end
end

-- Luasnip
local luasnip = require("luasnip")
luasnip.config.set_config {
  -- Keep last snippet around -> can jump back in.
  history = true,
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
               end, { silent = true, desc = "Snippet Forward" })

-- Navigate backward
vim.keymap.set({ "i", "s" }, "<c-j>", function()
                 if luasnip.jumpable(-1) then
                   luasnip.jump(-1)
                 end
               end, { silent = true, desc = "Snippet Backward" })

-- Select an option
vim.keymap.set("i", "<c-l>", function()
                 -- If there's no active choice don't do anything
                 if not require "luasnip.session".active_choice_node then
                   return
                 end
                 if luasnip.choice_active() then
                   luasnip.change_choice(1)
                 end
               end, { desc = "Snippet Change Choice" })
vim.keymap.set("i", "<c-u>", require "luasnip.extras.select_choice", { desc = "Snippet Select Choice" })

-- LSP servers setup
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
  },
  on_attach = on_attach,
})

-- lua lsp
require "lspconfig".lua_ls.setup {
  cmd = { "@lua_language_server@/bin/lua-language-server" },
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


-- lspsaga.nvim
-- should be loaded after other lsp plugins
do
  require("lspsaga").setup({
    symbol_in_winbar = { enable = false },
  })
  local set = vim.keymap.set
  set("n", "<C-]>", "<cmd>Lspsaga peek_definition<CR>", { desc = "LSP Peek Definition" })
  set("n", "gr", "<cmd>Lspsaga lsp_finder<CR>", { desc = "LSP Finder" })
end

-- Set up clang-format

vim.cmd([[
  au FileType cpp setlocal
  \ equalprg=@clang_unwrapped@/bin/clang-format\ --style=file\ --fallback-style=none
  ]])
