self:
{
  lib,

  z3,

  haskell,
  haskellPackages,
  makeRustPlatform,

  liquid-fixpoint ? haskellPackages.liquid-fixpoint,
  toolchain2manifest,

  nixpkgs,
}:
let
  overrideCabal' = lib.flip self.haskellLib.overrideCabal;
  callPackage' = lib.flip self.callPackage { };
in
{
  inherit z3;

  haskellLib = haskell.lib.compose;

  toolchain2manifest = toolchain2manifest.packages.toolchain2manifest;

  liquid-fixpoint = callPackage' (
    { haskellLib, ... }:

    overrideCabal' haskellPackages.liquid-fixpoint (prev: {
      version = "nightly";
      src = liquid-fixpoint;

      libraryHaskellDepends = (prev.libraryHaskellDepends or [ ]) ++ [
        haskellPackages.gitrev
      ];
    })
  );

  rust-bins = callPackage' (
    {
      pkgs,
      rust-overlay,
      flux-src,
    }:
    let
      mkRustBins = rust-overlay.lib.mkRustBin { } pkgs;
      toolchain-file = flux-src.outPath + "/rust-toolchain.toml";
    in
    mkRustBins.fromRustupToolchainFile toolchain-file
  );

  rustPlatform = makeRustPlatform {
    rustc = self.rust-bins;
    cargo = self.rust-bins;
  };

  rust-lib = callPackage' (nixpkgs.outPath + "/pkgs/build-support/rust/lib");

  mkBinLink = callPackage' ./make-bin-link.nix;
}
