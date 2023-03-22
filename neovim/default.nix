{pkgs ? import <nixpkgs> {}}: let
  core-init-vim = substitutePackages ./core/init.vim {
    inherit
      (pkgs)
      bat
      black
      fzf
      ripgrep
      ;
  };
  lib = pkgs.lib;
  substitutePackages = src: substitutions:
    pkgs.substituteAll ({inherit src;}
      // lib.mapAttrs'
      (k: lib.nameValuePair (builtins.replaceStrings ["-"] ["_"] k))
      substitutions);

  # My own config
  dotplug = pkgs.vimUtils.buildVimPluginFrom2Nix {
    pname = "dotplug";
    version = "latest";
    src = ./dotplug;
  };

  corePlugins = with pkgs.vimPlugins;
  with pkgs.neovimPlugins; [
    # My config as plugin
    dotplug

    # Navigation
    fzf-lua
    nvim-tree-lua
    lualine-nvim
    hop-nvim
    vim-fswitch
    nvim-maximize-window-toggle
    bufdelete-nvim
    nvim-possession

    # Terminal support
    toggleterm-nvim

    # Text editing
    vim-repeat
    vim-surround
    vim-unimpaired
    vim-abolish

    # Git
    vim-fugitive
    gv-vim
    vim-gitgutter

    # File specific support
    vim-nix
    vim-rst
    robotframework-vim

    # Themes/visualization
    nvim-notify
    nvim-solarized-lua
    nord-vim
    nvim-web-devicons
    gruvbox-nvim

    # tree-sitter
    (nvim-treesitter.withPlugins (p: [
      p.tree-sitter-bash
      p.tree-sitter-c
      p.tree-sitter-cmake
      p.tree-sitter-comment
      p.tree-sitter-cpp
      p.tree-sitter-css
      p.tree-sitter-dockerfile
      p.tree-sitter-html
      p.tree-sitter-javascript
      p.tree-sitter-json
      p.tree-sitter-latex
      p.tree-sitter-lua
      p.tree-sitter-make
      p.tree-sitter-markdown
      p.tree-sitter-nix
      p.tree-sitter-python
      p.tree-sitter-query
      p.tree-sitter-rst
      p.tree-sitter-vim
      p.tree-sitter-yaml
    ]))
    playground
    # An alternative to this could be nvim-navic, which use winbar and lsp
    # https://github.com/SmiteshP/nvim-navic
    nvim-treesitter-context

  ];

  neovim = pkgs.neovim.override {
    configure = {
      customRC = ''
        source ${core-init-vim}
        luafile ${./core/init.lua}
      '';
      packages.myVimPackage = with pkgs.vimPlugins; {
        start = corePlugins;
        # opt that dependency will always be added to start to avoid confusion.
        opt = [];
      };
    };
  };

  neovim-qt = pkgs.neovim-qt.override {
    inherit neovim;
  };

  neovim-qt-lsp = pkgs.neovim-qt.override {
    neovim = neovim-lsp;
  };

  neovim-lsp = pkgs.neovim.override {
    configure = {
      customRC = ''
        source ${core-init-vim}
        luafile ${./core/init.lua}
        luafile ${
          substitutePackages ./lsp/init.lua {
            inherit
              (pkgs)
              shellcheck
              yaml-language-server
              lua-language-server
              ;
            inherit
              (pkgs.llvmPackages_latest)
              clang
              clang-unwrapped
              ;
            python-lsp-server =
              (pkgs.python3.override {
                packageOverrides = _: super: {
                  python-lsp-server = super.python-lsp-server.override {
                  };
                };
              })
              .withPackages
              (ps: with ps; [pyls-isort python-lsp-black python-lsp-server]);
          }
        }
      '';
      packages.myVimPackage = with pkgs.vimPlugins; {
        start =
          corePlugins
          ++ [
            nvim-lspconfig
            trouble-nvim
            lspkind-nvim
            luasnip
            # Overlaps with cmp-nvim-lsp-signature-help which is being evaluated.
            # lsp_signature-nvim

            # nvim-cmp and completion sources
            nvim-cmp
            cmp-spell
            cmp-buffer
            cmp-nvim-lsp
            cmp-nvim-lsp-document-symbol
            cmp-nvim-lsp-signature-help
            cmp-nvim-lua
            cmp-path
            cmp_luasnip
          ];
      };
    };
  };
in {
  inherit
    neovim
    neovim-qt
    ;
  # Alias program for lsp
  neovim-lsp = pkgs.writeShellScriptBin "nvim-lsp" ''
    exec ${neovim-lsp}/bin/nvim "$@"
  '';
  # Alias program for lsp
  neovim-qt-lsp = pkgs.writeShellScriptBin "nvim-qt-lsp" ''
    exec ${neovim-qt-lsp}/bin/nvim-qt "$@"
  '';
}
