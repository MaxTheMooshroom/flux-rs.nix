{
  lib,

  stdenvNoCC,
  makeWrapper,
  runtimeShell,

  rust-bins,
  cargo,
  flux-bins,
}:
# Based on pkgs.writeShellScriptBin and pkgs.writeTextFile
stdenvNoCC.mkDerivation (self: {
  name = "cargo-linked";

  pos = builtins.unsafeGetAttrPos "name" self;
  meta.mainProgram = "cargo";

  # passAsFile = [ "text" ];
  # text = ''
  #   #!${runtimeShell}
  #
  #   echo "ENV=$(env)"
  #   echo "PATH=$PATH"
  #   echo "ARGS=$*"
  #
  #   ${lib.getExe' cargo "cargo"} "$@"
  # '';

  buildInputs = [
    rust-bins
    cargo
    flux-bins
  ];
  nativeBuildInputs = [ makeWrapper ];

  buildPhase = ''
    mkdir -p $out/bin

    if [ "''${textPath+x}" = x ]; then
      mv "$textPath" "$out/bin/cargo"
      chmod +x "$out/bin/cargo"
    else
      ln -s ${lib.getExe' cargo "cargo"} $out/bin/cargo
    fi
  '';

  fixupPhase = ''
    runHook preFixup

    echo "Wrapping cargo"
    wrapProgram $out/bin/cargo \
      --set FLUX_DRIVER ${lib.getExe' flux-bins "flux-driver"} \
      --set FLUX ${lib.getExe' flux-bins "flux"} \
      --prefix PATH : ${
        lib.makeBinPath [
          rust-bins
          flux-bins
        ]
      }

    runHook postFixup
  '';

  # Used instead of settings `src`.
  # See: https://github.com/NixOS/nixpkgs/issues/23099
  unpackPhase = "true";
})
