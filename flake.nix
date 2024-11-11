{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    rust-overlay,
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
      cargoTOML = builtins.fromTOML (builtins.readFile ./Cargo.toml);
      name = cargoTOML.package.name;
      version = cargoTOML.package.version;
      target = (builtins.fromTOML (builtins.readFile ./.cargo/config.toml)).build.target;
      platform = pkgs.makeRustPlatform {
        cargo = toolchain;
        rustc = toolchain;
      };
    in
      platform.buildRustPackage {
        inherit name version;
        src = ./.;
        cargoLock.lockFile = ./Cargo.lock;
        buildPhase = ''
          cargo build --release
        '';
        installPhase = ''
          cp target/${target}/release/*.wasm $out
        '';
        doCheck = false;
      };
    apps.default = {
      type = "app";
      program =
        toString
          (pkgs.writeShellScript
            "run"
            "${pkgs.wasmtime}/bin/wasmtime ${self.packages.${system}.default}");
    };
  });
}
