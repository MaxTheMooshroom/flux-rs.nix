self:
{
  pkgs,

  lib,
  newScope,
  stdenvNoCC,

  z3,
  rustup,

  makeRustPlatform,
  runCommand,
  makeWrapper,
  wrapRustc,
  coreutils,

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
let
  inherit rust-bins;

  staged = {
    rustPlatform = {
      stage0 = makeRustPlatform {
        rustc = rust-bins;
        cargo = rust-bins;
      };

      stage1 = makeRustPlatform {
        rustc = rust-bins;
        cargo = self.cargo;
      };
    };
  };

  cargo = stdenvNoCC.mkDerivation (self': {
    name = "cargo-wrapper";
    src = rust-bins;

    buildInputs = [ self.flux-bins ];
    propagatedBuildInputs = [ self.flux-bins ];
    nativeBuildInputs = [ makeWrapper ];

    installPhase = ''
      mkdir -p $out/bin
      cp ./bin/cargo $out/bin/cargo
    '';

    postFixup = ''
      wrapProgram $out/bin/cargo                                      \
        --set RUSTC       ${lib.getExe' self.flux-bins "flux"}        \
        --set FLUX_DRIVER ${lib.getExe' self.flux-bins "flux-driver"}
    '';

    meta = {
      mainProgram = "cargo";
    };
  });
in
{
  inherit cargo;

  flux-bins = self.callPackage ./packages-joined.nix {
    rustPlatform = staged.rustPlatform.stage0;
  };

  flux-driver = self.flux-bins;
  xtask       = self.flux-bins;
  flux        = self.flux-bins;
  cargo-flux  = self.flux-bins;

  rustPlatform = staged.rustPlatform.stage1;
}
