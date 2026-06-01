{
  # packageSet::callPackage
  callPackage,

  lib,

  git,

  runCommand,
  makeWrapper,
  stdenvNoCC,

  flux-src,
  z3,
  liquid-fixpoint,
  rust-bins,
}:
assert lib.assertMsg (
  (builtins.compareVersions z3.version "4.15") != -1
) "flux requires at least version 4.15 of z3";
let
  manifest = callPackage ./get-rustup-manifest.nix { };

  cargo_version =
    let
      cargo_version-raw = manifest.pkg.cargo.version;

      cargo_version-matcher = "([a-zA-Z0-9_-]|\\.)+ (\\(.*\\))";

      cargo_version-parts = builtins.match cargo_version-matcher cargo_version-raw;
    in
    assert lib.assertMsg (!isNull cargo_version-parts) ''
      Contents of the version string do not match the expected shape!
      '${cargo_version-raw}' != '${lib.escapeRegex cargo_version-matcher}'
    '';
    builtins.elemAt cargo_version-parts 1;
in
rustPlatform:
let
  result = rustPlatform.buildRustPackage (self: {
    name = "flux-rs";
    src = flux-src;
    # cargoHash = "";
    cargoHash = "sha256-hlxkZNNubQi3Xt4q/c9i+Ee9Tx+9QaJY6F4O6ZSVjjM=";

    CARGO_NET_OFFLINE = "true";
    FLUX_TOOLCHAIN_CARGO_VERSION_OVERRIDE = cargo_version;

    nativeBuildInputs = [
      git
      makeWrapper
    ];

    buildInputs = [
      liquid-fixpoint
      z3
    ];

    propagatedBuildInputs = [
      rust-bins
      liquid-fixpoint
      z3
    ];

    cargoBuildType = "release";
    cargoBuildFlags = [ "--workspace" ];

    postFixup = ''
      wrapProgram $out/bin/cargo-flux           \
        --set FLUX $out/bin/flux                \
        --set FLUX_DRIVER $out/bin/flux-driver
      wrapProgram $out/bin/flux --set FLUX_DRIVER $out/bin/flux-driver
    '';

    # Doesn't have cargo tests. Flux's tests are regression tests that
    # are run using `cargo xtask test`. Given that regression tests are
    # tests of the source and not necessarily tests of the validity of
    # the build artifact(s), I've opted not to include them in the
    # main derivation, but are available in `passthru.tests`.
    doCheck = false;

    # passthru.tests.xtask-regression = stdenvNoCC.mkDerivation (self': {
    #   name = "flux-test-xtask-regression";
    #   src = self.src.outPath;
    #
    #   SANDBOXED = 1;
    #   FLUX_TOOLCHAIN_CARGO_VERSION_OVERRIDE = cargo_version;
    #
    #   doCheck = false;
    #
    #   buildInputs = [ rust-bins result ];
    #   buildPhase = ''
    #     xtask --offline test
    #   '';
    #
    #   installPhase = "touch $out";
    # });

    meta = {
      description = "Refinement Types for Rust";
      homepage = "https://flux-rs.github.io";
      license = [ lib.licenses.mit ];
    };

    passthru = {
      inherit (self)
        FLUX_TOOLCHAIN_CARGO_VERSION_OVERRIDE
        CARGO_NET_OFFLINE
        cargoHash
        ;
    };
  });
in
result
