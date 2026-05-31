
cargoXtaskTestHook() {
  runHook preCheck

  echo "Executing cargoXtaskTestHook"

  # fixpoint --version
  # z3 --version
  # false

  if [ -n "${buildAndTestSubdir-}" ]; then
    pushd "${buildAndTestSubdir}"
  fi

  local flagsArray=("--offline")

  export RUST_TEST_THREADS=$NIX_BUILD_CORES
  if [ -n ${dontUseCargoParallelTests-} ]; then
    RUST_TEST_THREADS=1
  fi

  concatTo flagsArray cargoXtaskTestFlags

  echoCmd 'cargoCheckHook flags' "${flagsArray[@]} ${testFlags[@]}"
  @setEnv@ cargo xtask test "${flagsArray[@]}" "${testFlags[@]}"

  if [ -n "${buildAndTestSubdir-}" ]; then
    popd
  fi

  echo "Finished cargoXtaskTestHook"

  runHook postCheck
}

if [ -z "${dontCargoCheck-}" ]; then
  checkPhase=cargoXtaskTestHook
fi

