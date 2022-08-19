# Neovim Nix Flake

This is xbreak's personal Neovim config as a Nix flake.

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

- fzf-vim
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

It also comes bundled with 

- clang (clangd, clang-format)
- python-lsp-server (with pylint)
- yaml-language-server
- black
- ripgrep
- bat

