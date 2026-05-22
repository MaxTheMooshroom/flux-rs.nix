{
  description = "Refinement Types for Rust";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/25.11";
    mlib.url = "github:MaxTheMooshroom/mlib.nix";

    rust-overlay.url  = "github:oxalica/rust-overlay/a6cb2224d975e16b5e67de688c6ad306f7203425";

    liquid-fixpoint = {
      flake = false;
      url = "github:ucsd-progsys/liquid-fixpoint/1ec005195bc93153b62983004c87632a9a1f8c31";
    };

    flux-rs = {
      flake = false;
      url = "github:MaxTheMooshroom/flux-rs/flux-bin/get_cargo_path";
    };

    # nixdoc.url = "github:nix-community/nixdoc";
    flake-module = { flake = false; url = ./flake-module.nix; };

    toolchain2manifest = {
      url = "github:MaxTheMooshroom/rust-toolchain-to-manifest";
      inputs = {
        flake-parts.follows = "flake-parts";
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  outputs = { self, flake-parts, mlib, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } ({ lib, ... }: {
      systems = lib.systems.flakeExposed;

      imports = [
        mlib.flakeModules.perSystem-packageSets
        (import inputs.flake-module)
      ];

      perSystem = { system, inputs', self', pkgs, mkRustBins, rust-bins, ... }: {
        _module.args = {
          mkRustBins = inputs.rust-overlay.lib.mkRustBin {} pkgs;

          rust-bins =
            mkRustBins.fromRustupToolchainFile
              (inputs.flux-rs.outPath + "/rust-toolchain.toml");
        };

        packageSets = {
          dependencies = lib.flip (mlib.lib.callPackageSetWith pkgs) {}
            (finalAttrs: { haskell, haskellPackages, fetchFromGitHub, ... }: {
              haskellLib = haskell.lib.compose;

              inherit (inputs'.toolchain2manifest.packages)
                toolchain2manifest
                ;

              liquid-fixpoint = finalAttrs.callPackage ({ haskellLib, ... }:
                lib.flip haskellLib.overrideCabal haskellPackages.liquid-fixpoint (prev: {
                  version = "nightly";
                  src = inputs.liquid-fixpoint;

                  libraryHaskellDepends = (prev.libraryHaskellDepends or []) ++ [
                    haskellPackages.gitrev
                  ];
                })
              ) {};
            });

          fluxPackages = mlib.lib.callPackageSetWith pkgs ./flux-packages.nix {
            inherit mkRustBins rust-bins;
            inherit (inputs) flux-rs packages-joined;

            inherit (self'.packageSets.dependencies)
              liquid-fixpoint
              toolchain2manifest
              ;

            cargo-unwrapped = pkgs.cargo;
            mlib = mlib.lib;
          };
        };

        packages = {
          inherit (self'.packageSets.fluxPackages)
            cargo-flux
            flux-driver
            flux
            ;

          default = self'.packageSets.fluxPackages.flux-bins;
        };

        devShells = {
          default = self'.devShells.build;

          build = pkgs.mkShell {
            name = "flux-build-shell";

            packages = [
              rust-bins
              self'.packageSets.dependencies.liquid-fixpoint
              pkgs.z3
            ];
          };

          usage = pkgs.mkShell {
            name = "flux-use-shell";

            packages = [
              self'.packageSets.fluxPackages.cargo
              self'.packageSets.fluxPackages.flux-bins

              self'.packageSets.dependencies.liquid-fixpoint
              pkgs.rustup
              pkgs.z3

              self'.packages.default
            ];
          };
        };
      };
    });
}
