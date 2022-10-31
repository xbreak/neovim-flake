# Neovim Nix Flake

This is xbreak's personal Neovim config as a Nix flake.

## Host Configuration

Certain plugins are configured to load host-specific configuration.

### Runtime Path

The following paths are added to the vim runtime path:

- `${XDG_CONFIG_HOME}/nvim-xbreak`

If `XDG_CONFIG_HOME` is not set it will default to `${HOME}/.config`.

### [lsp] Luasnip Snippets

- `${XDG_CONFIG_HOME}/nvim-xbreak/luasnip/<ft>.lua`
- `${XDG_CONFIG_HOME}/nvim-xbreak/luasnip/<ft>/*.lua`

And project-local snippets (relative current working directory)

- `.luasnip/<ft>.lua`
- `.luasnip/<ft>/*.lua`

See details below.

## Build & Run

Core edition `neovim` is the default so the following commands yield the same result:

```console
$ nix run github:xbreak/neovim-flake
$ nix run github:xbreak/neovim-flake#neovim
```

LSP Edition:

```console
$ nix run github:xbreak/neovim-flake#neovim-lsp
```

## Plugins

### Core

Navigation

- fzf-lua
- nvim-tree-lua
- hop-nvim
- vim-fswitch


Editing

- vim-repeat
- vim-repeat
- vim-surround
- vim-unimpaired
- vim-abolish

Git

- vim-fugitive
- gv-vim
- vim-gitgutter

File support

- vim-nix
- vim-rst
- robotframework-vim

Appearance

- lualine-nvim
- nvim-solarized-lua
- nord-vim
- nvim-web-devicons
- gruvbox-nvim

### LSP Edition

Same as core but in addition have the following plugins:

- nvim-lspconfig
- treesitter
- nvim-treesitter-context
- trouble-nvim
- lspkind-nvim
- luasnip
- lsp_signature-nvim

- nvim-cmp
- cmp-spell
- cmp-buffer
- cmp-nvim-lsp
- cmp-nvim-lsp-document-symbol
- cmp-nvim-lua
- cmp-path
- cmp_luasnip

It also comes bundled with:

- clang (clangd, clang-format)
- python-lsp-server (with pylint)
- yaml-language-server
- black
- ripgrep
- bat

## Luasnip


Globals injected by luasnip (as defined in
https://github.com/L3MON4D3/LuaSnip/blob/69cb81cf7490666890545fef905d31a414edc15b/lua/luasnip/config.lua#L82-L104):

```lua
s = require("luasnip.nodes.snippet").S,
sn = require("luasnip.nodes.snippet").SN,
t = require("luasnip.nodes.textNode").T,
f = require("luasnip.nodes.functionNode").F,
i = require("luasnip.nodes.insertNode").I,
c = require("luasnip.nodes.choiceNode").C,
d = require("luasnip.nodes.dynamicNode").D,
r = require("luasnip.nodes.restoreNode").R,
l = require("luasnip.extras").lambda,
rep = require("luasnip.extras").rep,
p = require("luasnip.extras").partial,
m = require("luasnip.extras").match,
n = require("luasnip.extras").nonempty,
dl = require("luasnip.extras").dynamic_lambda,
fmt = require("luasnip.extras.fmt").fmt,
fmta = require("luasnip.extras.fmt").fmta,
conds = require("luasnip.extras.expand_conditions"),
types = require("luasnip.util.types"),
events = require("luasnip.util.events"),
parse = require("luasnip.util.parser").parse_snippet,
ai = require("luasnip.nodes.absolute_indexer"),
```

Each snippet file must return one or two lists of snippets (either may be `nil`). First list are
regular snippets whereas the second are autosnippets.

See also https://github.com/L3MON4D3/LuaSnip/blob/master/DOC.md#snippets.

Example snippet (without auto-snippets):

```lua
return {
  -- LSP-snippet example:
  parse("lspsnippet", "$1 snippet $2"),

  -- luasnip example:
  -- note: index 0 is always the last one
  s("luasnip", {
    t({"Text node 1: "}),
    i(1),
    t({"Text node 2: "}),
    i(2),
    t({"Last text node: "}),
    i(0),
  }),
}
```
