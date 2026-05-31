{
  lib,

  rustPlatform,

  fluxHooks,
  importCargoLock,
  flux-bins,
}:
# TODO: Add cargoFluxHook to derivation
lib.extendMkDerivation {
  constructDrv = rustPlatform.buildRustPackage;
  extendDrvArgs =
    finalArgs:
    {
      env ? { },
      cargoDeps ? null,
      cargoLock ? null,
      nativeBuildInputs ? [ ],
      ...
    }:
    let
      env' = {
        FLUX_DRIVER = flux-bins;
      }
      // env;

      cargoDeps' =
        if !isNull cargoDeps then
          cargoDeps
        else if !isNull cargoLock then
          importCargoLock cargoLock
        else
          null;
    in
    {
      cargoDeps = cargoDeps';
      env = env';

      nativeBuildInputs = nativeBuildInputs ++ [
        flux-bins
        fluxHooks.cargoFluxHook
      ];
    };
}
