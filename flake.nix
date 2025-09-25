{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
    nvchad-starter = {
      url = "github:NvChad/starter";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, systems, nvchad-starter, ... }: let
    eachSystem = nixpkgs.lib.genAttrs (import systems);
  in {
    homeManagerModules.nvnix = (import ./module.nix) { starterRepo = nvchad-starter; };
    packages = eachSystem (system: { nvchad = nixpkgs.legacyPackages.${system}.callPackage ./package.nix { starterConfig = nvchad-starter; }; });
    checks = eachSystem (system: self.packages.${system});
  };
}
