
cargoFluxHook() {
  echo "Executing cargoFluxHook"

  if [ -n "${buildAndTestSubdir}" ]; then
    pushd "${buildAndTestSubdir}"
  fi

  local flagsArray=("-j" "${NIX_BUILD_CORES}")

  export RUST_TEST_THREADS=${NIX_BUILD_CORES}
  if [ ! -z "${dontUseCargoParallelTests-}"]; then
    RUST_TEST_THREADS=1
  fi

  if [ -n "${cargoCheckNoDefaultFeatures-}" ]; then
    flagsArray+=("--no-default-features")
  fi

  if [ -n "${cargoCheckFeatures-}" ]; then
    flagsArray+=("--features=$(concatStringsSep "," cargoCheckFeatures)")
  fi

  flagsArray+=(
    "--target" "@rustcTargetSpec@"
    "--offline"
  )

  concatTo flagsArray cargoFluxFlags

  echoCmd 'cargoFluxHook flags' "${flagsArray[@]}"
  @setEnv@ cargo flux check "${flagsArray[@]}"

  if [ -n "${buildAndTestSubdir-}" ]; then
    popd
  fi

  echo "Finished cargoFluxHook"
}

if [ -z "${dontCargoFlux-}" ] && [ -z "${checkPhase-}" ]; then
  postCheck=cargoFluxHook
fi

