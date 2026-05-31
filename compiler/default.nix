self:
{
  lib,
  mlib,

  pkgs,
  stdenvNoCC,
  makeWrapper,
  makeRustPlatform,

  flux-src,

  ...
}:
{
  dependencies = self.callPackageSet ./dependencies { };

  makeFluxBins = self.dependencies.callPackage ./make-flux-bins.nix { };

  flux-bins = self.makeFluxBins self.dependencies.rustPlatform;

  cargo' = self.dependencies.callPackage ./cargo.nix { };

  mkFluxPlatform = self.dependencies.callPackageSet ./flux-platform.nix;

  fluxPlatform = self.mkFluxPlatform { };
}
