{
  description = "xbreak Neovim config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";

    # Neovim Plugins
    nvim-tree-lua = {
      url = "github:kyazdani42/nvim-tree.lua";
      flake = false;
    };
    fzf-lua = {
      url = "github:ibhagwan/fzf-lua";
      flake = false;
    };
    robotframework-vim = {
      url = "github:rasjani/robotframework-vim";
      flake = false;
    };
    vim-fswitch = {
      url = "github:xbreak/vim-fswitch";
      flake = false;
    };
    vim-rst = {
      url = "github:habamax/vim-rst";
      flake = false;
    };
    nvim-maximize-window-toggle = {
      url = "github:caenrique/nvim-maximize-window-toggle";
      flake = false;
    };
    nvim-possession = {
      url = "github:gennaro-tedesco/nvim-possession";
      flake = false;
    };
    lspsaga-nvim = {
      url = "github:glepnir/lspsaga.nvim";
      flake = false;
    };
    cmp-nvim-lsp-document-symbol = {
      url = "github:xbreak/cmp-nvim-lsp-document-symbol";
      flake = false;
    };
    nvim-treesitter-context = {
      url = "github:xbreak/nvim-treesitter-context";
      flake = false;
    };
  };
  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    ...
  } @ inputs: let
    plugins = [
      "nvim-tree-lua"
      "fzf-lua"
      "robotframework-vim"
      "vim-fswitch"
      "vim-rst"
      "nvim-maximize-window-toggle"
      "nvim-possession"
      "lspsaga-nvim"
      "cmp-nvim-lsp-document-symbol"
      "nvim-treesitter-context"
    ];
    system = "x86_64-linux";
    pkgs = import nixpkgs-unstable {
      inherit system;
      overlays = [pluginOverlay];
    };
    nvims = import ./neovim {inherit pkgs;};

    pluginOverlay = top: last: let
      buildPlug = name:
        top.vimUtils.buildVimPlugin {
          pname = name;
          version = "flake";
          src = builtins.getAttr name inputs;
        };
    in {
      neovimPlugins = builtins.listToAttrs (map (name: {
          inherit name;
          value = buildPlug name;
        })
        plugins);
    };
  in {
    # Enables `nix fmt <file>`
    formatter.${system} = nixpkgs.legacyPackages.${system}.alejandra;

    # Neovim packages
    packages.${system} = {
      inherit (nvims) neovim neovim-lsp neovim-qt neovim-qt-lsp;
      default = nvims.neovim;
    };

    # Expose packages as applications to enable use with `nix run`
    # Runnable as `nix run` (vanilla nvim) or `nix run .#neovim-lsp`.
    apps.${system} = {
      neovim = {
        type = "app";
        program = "${self.packages.${system}.neovim}/bin/nvim";
      };
      neovim-lsp = {
        type = "app";
        program = "${self.packages.${system}.neovim-lsp}/bin/nvim-lsp";
      };
      default = self.apps.${system}.neovim;
    };
  };
}
