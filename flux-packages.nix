self:
{
  lib,
  mlib,

  pkgs,
  newScope,
  stdenvNoCC,

  z3,
  rustup,

  makeRustPlatform,
  runCommand,
  makeWrapper,
  wrapRustc,
  coreutils,

  # inputs
  flux-rs,
  packages-joined,

  # local products
  mkRustBins ? args.rust-overlay.lib.mkRustBin {} pkgs,

  rust-bins ?
    mkRustBins.fromRustupToolchainFile
      (flux-rs.outPath + "/rust-toolchain.toml"),

  ...
}@args:
let
  wrapCargo = self.callPackage ./wrap-cargo.nix {};
  mkFluxBins = self.callPackage ./make-flux-bins.nix {};

  # wrapAsFlux = wrapAsMainProgram "flux";
  # wrapAsMainProgram = mainProgram: drv: drv // {
  #   meta = drv.meta or {} // {
  #     inherit mainProgram;
  #   };
  # };

  stages = [
    # stage 0
    ({...}: {
      flux-bins = mkFluxBins (makeRustPlatform {
        rustc = rust-bins;
        cargo = rust-bins;
      });
    })

    # # stage 1
    # ({ flux-bins, ... }: rec {
    #   cargo = wrapCargo flux-bins;
    #
    #   rustPlatform = makeRustPlatform {
    #     inherit cargo;
    #     rustc = rust-bins;
    #     # rustc = wrapAsFlux flux-bins;
    #   };
    # })
    #
    # # stage 2
    # ({ flux-bins, rustPlatform, ... }: {
    #   flux-bins = self.callPackage ./packages-joined.nix {
    #     bins = flux-bins;
    #     inherit rustPlatform;
    #   };
    # })

    # stage 3
    ({ flux-bins, ... }: rec {
      cargo = wrapCargo flux-bins;

      rustPlatform = makeRustPlatform {
        inherit cargo;
        rustc = rust-bins;
        # rustc = wrapAsFlux flux-bins;
      };
    })

    # stage 4
    ({ flux-bins, ... }: {
      flux-driver = flux-bins;
      xtask       = flux-bins;
      flux        = flux-bins;
      cargo-flux  = flux-bins;

      # buildFluxPackage = self.callPackage ./build-flux-package.nix {};
    })
  ];

  stagePump = lib.flip (mlib.trivial.fanout lib.mergeAttrs);
  finalized = builtins.foldl' stagePump {} stages;
in
  finalized
