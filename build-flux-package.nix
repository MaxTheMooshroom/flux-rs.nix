{
  lib,

  cargo,
  rustPlatform,
}:
let
in
  lib.extendMkDerivation {
    constructDrv = rustPlatform.buildRustPackage;
    excludeDrvArgNames = [];
    extendDrvArgs = (finalArgs:
      {
        cargoManifestFile ? finalArgs.src.outPath + "/Cargo.toml",
        cargoManifestContents ? builtins.readFile cargoManifestFile,
        cargoManifestAttrs ? builtins.fromTOML cargoManifestContents,

        fluxEnabled ? cargoManifestAttrs.package.metadata.flux.enabled or true,

      }@prevArgs:
      {
        passthru = prevArgs.passthru or {} // { inherit fluxEnabled; };
      }
    );
    transformDrv = prev: prev // {
      checkPhase = ''
        ${prev.checkPhase or ""}

      '';
    };
  }
