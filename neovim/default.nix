{ pkgs ? import <nixpkgs> {} }:
let
  core-init-vim = substitutePackages ./core/init.vim {
            inherit (pkgs)
              bat
              black
              ripgrep;
          };
  lib = pkgs.lib;
  substitutePackages = src: substitutions:
    pkgs.substituteAll ({ inherit src; } // lib.mapAttrs'
      (k: lib.nameValuePair (builtins.replaceStrings [ "-" ] [ "_" ] k))
      substitutions);

  nvim-tree-lua-master = pkgs.vimUtils.buildVimPluginFrom2Nix {
    pname = "nvim-tree-lua";
    version = "2022-05-09";
    src = pkgs.fetchFromGitHub {
      owner = "kyazdani42";
      repo = "nvim-tree.lua";
      rev = "47732b6dbfda4a343f6062f8254080e75e00c8b3";
      sha256 = "1yd1ycb3d09z47cngvpaxh4b78n747lhgxrl92xrcyd8b88hd9a7";
    };
    meta.homepage = "https://github.com/kyazdani42/nvim-tree.lua/";
  };

  vim-rst = pkgs.vimUtils.buildVimPluginFrom2Nix {
    pname = "vim-rst";
    version = "2022-01-07";
    src = pkgs.fetchFromGitHub {
      owner = "habamax";
      repo = "vim-rst";
      rev = "fb9a37bf9f873e2c90fca9e0fd1ebf7e0782fb73";
      sha256 = "0zbllwm044bxjx6is7cyjzrrihzhj26lppa72hx15p2v52kh6idc";
    };
  };

  vim-fswitch = pkgs.vimUtils.buildVimPluginFrom2Nix {
    pname = "vim-fswitch";
    version = "2022-01-09";
    src = pkgs.fetchFromGitHub {
      owner = "derekwyatt";
      repo = "vim-fswitch";
      rev = "94acdd8bc92458d3bf7e6557df8d93b533564491";
      sha256 = "13nk3qwbijzx8pwsm5303dm3dd7xhr2jhchkxmfs10i962v6khrc";
    };
  };

  robotframework-vim = pkgs.vimUtils.buildVimPluginFrom2Nix {
    pname = "robotframework-vim";
    version = "2019-05-08";
    src = pkgs.fetchFromGitHub {
      owner = "rasjani";
      repo = "robotframework-vim";
      rev = "bc2156daf6e35dfa5b11001ab2acf0df286b1e6f";
      sha256 = "0hfcw3ampkx2hcxpq580ypi6mmi0aydrjgwcgbjxxw1sypmwxvl4";
    };
  };
  
  fzf-lua = pkgs.vimUtils.buildVimPluginFrom2Nix {
    pname = "fzf-lua";
    version = "2022-05-18";
    src = pkgs.fetchFromGitHub {
      owner = "ibhagwan";
      repo = "fzf-lua";
      rev = "eb3d2d121f480471a9571b6d9138b4c49a5ed3e0";
      sha256 = "1r4kb93l1m204p0jng20aa974vqvkcqkfkkasdn0h2yp8wl8jsj3";
    };
  };

  # My own config
  dotplug = pkgs.vimUtils.buildVimPluginFrom2Nix {
    pname = "dotplug";
    version = "latest";
    src = ./dotplug;
  };

  corePlugins = with pkgs.vimPlugins; [
    # My config as plugin
    dotplug

    # Navigation
    fzf-vim
    nvim-tree-lua-master
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
        opt = [ ];
      };
    };
  };

  neovim-qt = pkgs.neovim-qt.override {
    inherit neovim;
  };

  neovim-qt-lsp = pkgs.neovim-qt.override {
    neovim=neovim-lsp;
  };

  neovim-lsp = pkgs.neovim.override {
    configure = {
      customRC = ''
        source ${core-init-vim}
        luafile ${./core/init.lua}
        luafile ${
          substitutePackages ./lsp/init.lua {
            inherit (pkgs)
              shellcheck
              yaml-language-server;
            inherit (pkgs.llvmPackages_latest)
              clang
              clang-unwrapped;
            python-lsp-server = (pkgs.python3.override {
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
            }).withPackages
              (ps: with ps; [ pyls-isort python-lsp-black python-lsp-server ]);
          }
        }
      '';
      packages.myVimPackage = with pkgs.vimPlugins; {
        start = corePlugins ++ [
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

  # Alias program for lsp
  neovim-lsp-alias = pkgs.writeShellScriptBin "nvim-lsp" ''
    exec ${neovim-lsp}/bin/nvim "$@"
  '';
  # Alias program for lsp
  neovim-qt-lsp-alias = pkgs.writeShellScriptBin "nvim-qt-lsp" ''
    exec ${neovim-qt-lsp}/bin/nvim-qt "$@"
  '';
in
  {
    inherit
      neovim
      neovim-qt
      neovim-lsp neovim-lsp-alias
      neovim-qt-lsp
      neovim-qt-lsp-alias
      ;
  }
