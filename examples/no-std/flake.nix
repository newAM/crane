{
  description = "Build a cargo project with for a no_std target";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
  };

  outputs = {
    self,
    nixpkgs,
    crane,
    flake-utils,
    rust-overlay,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [(import rust-overlay)];
      };

      rustWithArmTarget = pkgs.rust-bin.stable.latest.default.override {
        targets = ["thumbv6m-none-eabi"];
      };

      # NB: we don't need to overlay our custom toolchain for the *entire*
      # pkgs (which would require rebuidling anything else which uses rust).
      # Instead, we just want to update the scope that crane will use by appending
      # our specific toolchain there.
      craneLib = (crane.mkLib pkgs).overrideToolchain rustWithArmTarget;

      commonArgs = {
        src = ./.;

        # This defaults to --all-targets which includes --benches and --tests
        # that require the standard library
        cargoCheckExtraArgs = "--lib --bins --examples";

        cargoExtraArgs = "--target thumbv6m-none-eabi";

        # The default test harness requires std
        doCheck = false;
      };

      cargoArtifacts = craneLib.buildDepsOnly commonArgs;
    in {
      packages.default = craneLib.buildPackage (commonArgs
        // {
          inherit cargoArtifacts;
        });

      checks = {
        pkg = self.packages.${system}.default;
      };
    });
}
