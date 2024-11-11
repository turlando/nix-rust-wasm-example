{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    crate2nix.url = "github:nix-community/crate2nix";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    rust-overlay,
    crate2nix
  }:
  flake-utils.lib.eachDefaultSystem (system: let
    pkgs = import nixpkgs {
      inherit system;
      overlays = [ rust-overlay.overlays.default ];
    };
    toolchain = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
  in {
    devShells.default = pkgs.mkShell {
      packages = [ toolchain ];
    };
    packages.default = let
      name = (builtins.fromTOML (builtins.readFile ./Cargo.toml)).package.name;
      buildRustCrateForPkgs =
        crate:
        pkgs.buildRustCrate.override {
          rustc = toolchain;
          cargo = toolchain;
        };
      generatedCargoNix = crate2nix.tools.${system}.generatedCargoNix {
        inherit name;
        src = ./.;
      };
      cargoNix = import generatedCargoNix {
        inherit pkgs buildRustCrateForPkgs;
      };
    in
      cargoNix.rootCrate.build;
  });
}
