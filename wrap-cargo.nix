{
  lib,
  stdenvNoCC,
  makeWrapper,

  cargo-unwrapped,
  rust-bins,
}:

flux-bins:
stdenvNoCC.mkDerivation (self': {
  name = "cargo-wrapper";
  src = rust-bins;

  buildInputs = [ flux-bins ];
  propagatedBuildInputs = [ flux-bins ];
  nativeBuildInputs = [ makeWrapper ];

  passthru.cargo-unwrapped = rust-bins;

  installPhase = ''
    mkdir -p $out/bin
    cp ./bin/cargo $out/bin/cargo
  '';

  postFixup = ''
    wrapProgram $out/bin/cargo                                  \
      --set RUSTC       ${lib.getExe' flux-bins "flux"}         \
      --set FLUX_DRIVER ${lib.getExe' flux-bins "flux-driver"}
  '';

  meta = {
    mainProgram = "cargo";
  };
})
