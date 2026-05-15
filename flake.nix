{
  description = "Refinement Types for Rust";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/25.11";
    mlib.url = "github:MaxTheMooshroom/mlib.nix";

    rust-overlay.url = "github:oxalica/rust-overlay/a6cb2224d975e16b5e67de688c6ad306f7203425";
    flux-rs         = { flake = false; url = "github:flux-rs/flux"; };

    # nixdoc.url = "github:nix-community/nixdoc";
    flake-module = { flake = false; url = ./flake-module.nix; };

    flux-bins       = { flake = false; url = ./flux-bins.nix;       };
    packages-joined = { flake = false; url = ./packages-joined.nix; };
  };

  outputs = { self, flake-parts, mlib, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } ({ lib, ... }: {
      systems = lib.systems.flakeExposed;

      imports = [
        mlib.flakeModules.perSystem-packageSets
        (import inputs.flake-module)
      ];

      perSystem = { self', pkgs, mkRustBins, rust-bins, ... }: {
        _module.args = {
          mkRustBins = inputs.rust-overlay.lib.mkRustBin {} pkgs;

          rust-bins =
            mkRustBins.fromRustupToolchainFile
              (inputs.flux-rs.outPath + "/rust-toolchain.toml");
        };

        packageSets = {
          flux-bins = mlib.lib.callPackageSetWith pkgs inputs.flux-bins {
            inherit mkRustBins rust-bins;
            inherit (inputs) flux-rs packages-joined;
          };
        };

        packages = {
          inherit (self'.packageSets.flux-bins)
            cargo-flux
            flux-driver
            flux
            ;

          default = self'.packages.cargo-flux;
        };

        devShells = {
          default = self'.devShells.build;

          build = pkgs.mkShell {
            name = "flux-build-shell";

            packages = [
              rust-bins
              pkgs.haskellPackages.liquid-fixpoint
              pkgs.z3
            ];
          };

          usage = pkgs.mkShell {
            name = "flux-use-shell";

            packages = [
              rust-bins

              pkgs.haskellPackages.liquid-fixpoint
              pkgs.rustup
              pkgs.z3

              self'.packages.default
            ];
          };
        };
      };
    });
}
