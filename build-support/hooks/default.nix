{
  lib,

  stdenv,
  makeSetupHook,

  rust-lib,

  ...
}:
let
  makeSetupHook' = lib.flip makeSetupHook;
in
{
  cargoFluxHook = makeSetupHook' ./cargo-flux-hook.sh {
    name = "cargo-flux-hook.sh";
    substitutions = {
      inherit (stdenv.targetPlatform.rust) rustcTargetSpec;
      inherit (rust-lib.envVars) setEnv;
    };
  };
}
