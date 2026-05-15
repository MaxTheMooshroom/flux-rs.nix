self:
{
  pkgs,

  lib,
  newScope,
  stdenvNoCC,

  makeRustPlatform,
  haskellPackages,
  z3,

  runCommand,
  makeWrapper,

  # inputs
  flux-rs,
  packages-joined,

  # local products
  mkRustBins ? args.rust-overlay.lib.mkRustBin {} pkgs,

  rust-bins ?
    mkRustBins.fromRustupToolchainFile
      (flux-rs.outPath + "/rust-toolchain.toml"),

  ...
}@args:
{
  packagesJoined = self.callPackage packages-joined {};

  xtask = stdenvNoCC.mkDerivation {
    name = "flux-xtask";
    src = self.packagesJoined;

    installPhase = ''
      mkdir -p $out/bin
      cp ./bin/xtask $out/bin/xtask
    '';

    meta = self.packagesJoined.meta // {
      mainProgram = "xtask";
    };
  };

  flux-driver = stdenvNoCC.mkDerivation {
    name = "flux-driver";
    src = self.packagesJoined;

    # outputs = [ "out" "bin" ];

    installPhase = ''
      mkdir -p $out/bin
      cp ./bin/flux-driver $out/bin/flux-driver
    '';

    meta = self.packagesJoined.meta // {
      mainProgram = "flux-driver";
    };
  };

  flux = stdenvNoCC.mkDerivation {
    name = "flux";
    src = self.packagesJoined;

    nativeBuildInputs = [ makeWrapper ];
    # outputs = [ "out" "bin" ];

    installPhase = ''
      mkdir -p $out/bin
      cp ./bin/flux $out/bin/flux
    '';

    postFixup = ''
      wrapProgram $out/bin/flux --set FLUX_DRIVER ${self.flux-driver}/bin/flux-driver
    '';

    meta = self.packagesJoined.meta // {
      mainProgram = "flux-driver";
    };
  };

  cargo-flux = stdenvNoCC.mkDerivation {
    name = "cargo-flux";
    src = self.packagesJoined;

    nativeBuildInputs = [ makeWrapper ];
    # outputs = [ "out" "bin" ];

    installPhase = ''
      mkdir -p $out/bin
      cp ./bin/cargo-flux $out/bin/cargo-flux
    '';

    postFixup = ''
      wrapProgram $out/bin/cargo-flux --set FLUX ${self.flux}/bin/flux
    '';

    meta = self.packagesJoined.meta // {
      mainProgram = "cargo-flux";
    };
  };

  rustPlatform = makeRustPlatform {
    rustc = self.flux;

    # no change to cargo needed for flux
    cargo = rust-bins.overrideAttrs {  };
  };

  # tests = lib.flip callPackage {} ({ stdenv, packagesJoined, xtask, ... }: {
  #   # Normally I'd run this with something like
  #   # ```
  #   # cargo run --package xtask                     \
  #   #   --profile <...> --target <...>              \
  #   #   [--no-default-features] [--features <...>]  \
  #   #   --offline                                   \
  #   #   --                                          \
  #   #   test [<flags...>]
  #   # ```
  #   # However, this would use cargo, require reusing the source, and
  #   # probably rebuilding the xtask binary, whenxtask was already built
  #   # by the package. So, we can just call it directly. This does mean
  #   # that the args used to build xtask are locked to the same onesn used
  #   # to build the package. But, I don't think that's a bad thing.
  #   regression = stdenv .mkDerivation {
  #     name = "flux-tests-regression";
  #     src = packagesJoined.src;
  #
  #     nativeBuildInputs = [ rust-bins ];
  #     buildInputs = [ xtask ];
  #
  #     checkPhase = ''
  #       ${xtask} test
  #     '';
  #   };
  # });
}
