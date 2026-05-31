self:
{
  lib,
  makeRustPlatform,

  build-support,

  cargo',
  flux-bins,
  mkBinLink,

  dependencies,

  ...
}:
let
  extractRustBin =
    bin-name:
    mkBinLink {
      package = flux-bins;
      inherit bin-name;
    };

  callBuildSupportItem = x: self.callPackage "${build-support}/${x}";
in
{
  rustPlatform = makeRustPlatform {
    rustc = dependencies.rust-bins;
    cargo = self.cargo;
  };

  cargo = callBuildSupportItem "wrap-cargo.nix" {
    cargo = cargo';
  };

  flux-driver = extractRustBin "flux-driver";
  flux = extractRustBin "flux";
  cargo-flux = extractRustBin "cargo-flux";

  importCargoLock = callBuildSupportItem "import-cargo-lock.nix" { };

  fluxHooks = callBuildSupportItem "hooks" { };

  buildFluxPackage = callBuildSupportItem "build-flux-package" { };
}
