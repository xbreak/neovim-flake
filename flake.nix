{
  description = "xbreak Neovim config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "nixpkgs/nixos-22.05";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs-unstable {inherit system;};
    nvims = import ./neovim {inherit pkgs;};
  in {
    # Enables `nix fmt <file>`
    formatter.${system} = nixpkgs.legacyPackages.${system}.alejandra;

    # Neovim packages
    packages.${system} = {
      inherit (nvims) neovim neovim-qt;
      neovim-lsp = nvims.neovim-lsp-alias;
      neovim-qt-lsp = nvims.neovim-qt-lsp-alias;
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
