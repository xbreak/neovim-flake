{pkgs ? import <nixpkgs> {}}: let
  core-init-vim = substitutePackages ./core/init.vim {
    inherit
      (pkgs)
      bat
      black
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
    fzf-vim
    nvim-tree-lua
    lualine-nvim
    hop-nvim
    vim-fswitch

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
    NeoSolarized
    nord-vim
    nvim-web-devicons
    gruvbox-nvim
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
                    withAutopep8 = false;
                    withFlake8 = false;
                    withMccabe = false;
                    withPyflakes = false;
                    withPylint = true;
                    withYapf = false;
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
            # tree-sitter
            (nvim-treesitter.withPlugins (p: [
              p.tree-sitter-c
              p.tree-sitter-cpp
              p.tree-sitter-python
              p.tree-sitter-json
              p.tree-sitter-yaml
              p.tree-sitter-bash
              p.tree-sitter-nix
              p.tree-sitter-latex
              p.tree-sitter-markdown
              p.tree-sitter-rst
            ]))
            playground
            nvim-treesitter-context

            trouble-nvim
            lspkind-nvim
            luasnip
            lsp_signature-nvim

            # nvim-cmp and completion sources
            nvim-cmp
            cmp-spell
            cmp-buffer
            cmp-nvim-lsp
            cmp-nvim-lsp-document-symbol
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
