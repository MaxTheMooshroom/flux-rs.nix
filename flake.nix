{
  description = "Refinement Types for Rust";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/26.05";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    mlib.url = "github:MaxTheMooshroom/mlib.nix";
    mlib.inputs.flake-parts.follows = "flake-parts";

    rust-overlay.url = "github:oxalica/rust-overlay/a6cb2224d975e16b5e67de688c6ad306f7203425";

    liquid-fixpoint = {
      flake = false;
      url = "github:ucsd-progsys/liquid-fixpoint/1ec005195bc93153b62983004c87632a9a1f8c31";
    };

    flux-src = {
      flake = false;
      url = "github:MaxTheMooshroom/flux-rs/flux-bin/get_cargo_path";
    };

    # nixdoc.url = "github:nix-community/nixdoc";

    toolchain2manifest = {
      url = "github:MaxTheMooshroom/rust-toolchain-to-manifest/squeeze-bin";
      inputs = {
        flake-parts.follows = "flake-parts";
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  outputs =
    {
      self,
      mlib,
      flake-parts,
      ...
    }@inputs:
    mlib.lib.mkFlake { inherit inputs; } (
      { lib, mlib, ... }:
      {
        systems = lib.systems.flakeExposed;

        imports = [
          flake-parts.flakeModules.flakeModules
          inputs.mlib.flakeModules.perSystem-packageSets
          ./flake-module.nix
        ];

        flake.flakeModules.default = self.flakeModules.perSystem-moduleArgs;

        flake.flakeModules.perSystem-moduleArgs = {
          perSystem =
            { system, ... }:
            {
              _module.args = {
                inherit (inputs.self.packageSets.${system})
                  fluxPackages
                  fluxPlatform
                  ;
              };
            };
        };

        perSystem =
          {
            inputs',
            self',
            pkgs,
            ...
          }:
          {
            formatter = pkgs.nixfmt-tree;

            packageSets = {
              fluxPackages = mlib.callPackageSetWith pkgs ./compiler {
                inherit (inputs)
                  flux-src
                  liquid-fixpoint
                  rust-overlay

                  nixpkgs
                  ;

                inherit (inputs')
                  toolchain2manifest
                  ;

                build-support = ./build-support;
              };

              inherit (self'.packageSets.fluxPackages)
                dependencies
                fluxPlatform
                ;
            };

            packages = {
              default = self'.packages.cargo;

              inherit (self'.packageSets.fluxPlatform)
                flux-driver
                flux
                cargo-flux
                cargo
                ;

              inherit (self'.packageSets.fluxPackages)
                flux-bins
                ;
            };

            devShells = {
              default = self'.devShells.build;

              build = pkgs.mkShell {
                name = "flux-build-shell";

                packages = with self'.packageSets.dependencies; [
                  rust-bins
                  liquid-fixpoint
                  z3
                ];
              };

              usage = pkgs.mkShell {
                name = "flux-use-shell";

                packages = [
                  self'.packages.default
                ];
              };
            };

            tests = (import ./tests.nix) {
              inherit
                pkgs
                self'
                inputs
                mlib
                ;
            };

            checks = lib.mapAttrs (pkgs.lib.const (builtins.getAttr "all")) self'.tests;
          };
      }
    );
}
