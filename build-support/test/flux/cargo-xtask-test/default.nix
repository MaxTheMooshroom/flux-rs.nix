{
  lib,
  stdenvNoCC,
  makeSetupHook,

  fluxPackages,

  ...
}:
let
  inherit (fluxPackages) dependencies;

  cargo-xtask-test-hook = lib.flip makeSetupHook ./cargo-xtask-test-hook.sh {
    name = "cargo-xtask-test-hook.sh";
    substitutions = {
      inherit (stdenvNoCC.targetPlatform.rust) rustcTargetSpec;
      inherit (dependencies.rust-lib.envVars) setEnv;
    };
  };
in
  fluxPackages.flux-bins.overrideAttrs (
    final: prev:
    {
      name = "flux-source-cargo-xtask-test";

      doCheck = true;
      dontCargoBuild = true;
      dontCargoInstall = true;

      nativeBuildInputs = prev.nativeBuildInputs or [] ++ [
        cargo-xtask-test-hook
        fluxPackages.dependencies.z3
        fluxPackages.dependencies.liquid-fixpoint
      ];
    }
  )
