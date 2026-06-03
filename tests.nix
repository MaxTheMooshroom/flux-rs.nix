{
  pkgs,
  self',
  inputs,
  mlib,
  ...
}:
let
  callTestPackageSet =
    test-set-name:
    let
      testPath = inputs.build-support.outPath + "/test/${test-set-name}";
    in
    mlib.callPackageSetWith pkgs testPath {
      inherit (inputs) flux-src nixpkgs;
      inherit (self'.packageSets) fluxPlatform fluxPackages;
    };
in
{
  importCargoLock = callTestPackageSet "import-cargo-lock";
  flux = callTestPackageSet "flux";
  buildFluxPackage = callTestPackageSet "build-flux-package";
}
