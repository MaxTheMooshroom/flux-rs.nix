{
  lib,
  runCommand,
  toolchain2manifest,

  rustPlatform,

  rust-bins,
  flux-rs,

  makeWrapper,
  liquid-fixpoint,
  z3,

  # stdenvNoCC,

  ...
}:
assert lib.assertMsg
  ((builtins.compareVersions z3.version "4.15") != -1)
  "flux requires at least version 4.15 of z3";
let
  manifest_url =
    runCommand "get-manifest-url" { buildInputs = [ toolchain2manifest ]; } ''
      ${lib.getExe toolchain2manifest} file ${flux-rs}/rust-toolchain.toml > $out
    '';

  manifest_raw = builtins.fetchurl {
    name = "toolchain-manifest.toml";
    url = builtins.readFile manifest_url;
    sha256 = "0ymc7bqaclk99ivcyh06s3qas0a1hk1vgjv12b9x6f47ajb6w46x";
  };

  manifest = builtins.fromTOML (builtins.readFile manifest_raw);

  cargo_version =
    let
      cargo_version-raw = manifest.pkg.cargo.version;

      cargo_version-matcher =
        "([a-zA-Z0-9_-]|\\.)+ (\\(.*\\))";

      cargo_version-parts =
        builtins.match cargo_version-matcher cargo_version-raw;
    in
      assert lib.assertMsg
        (!isNull cargo_version-parts)
        ''
          The contents of the version string do not match the expected shape!
          '${cargo_version-raw}' != '${lib.escapeRegex cargo_version-matcher}'
        '';
      builtins.elemAt cargo_version-parts 1;
in
  rustPlatform.buildRustPackage (self: {
    name = "flux-rs";
    src = flux-rs;
    # cargoHash = "";
    cargoHash = "sha256-AKbttV9C0GNj+/OS6ABDpOBUXoMFcM5dyrLHyRtKgzo=";

    SANDBOXED = 1;
    FLUX_TOOLCHAIN_CARGO_VERSION_OVERRIDE = cargo_version;

    nativeBuildInputs = [
      makeWrapper
    ];

    buildInputs = [
      liquid-fixpoint
      z3
    ];

    propagatedBuildInputs = [ rust-bins ];

    cargoBuildType = "release";
    cargoBuildFlags = [ "--workspace" ];

    postFixup = ''
      wrapProgram $out/bin/cargo-flux --set FLUX        $out/bin/flux
      wrapProgram $out/bin/flux       --set FLUX_DRIVER $out/bin/flux-driver
    '';

    # Doesn't have cargo tests. Flux's tests are regression tests that
    # are run using `cargo xtask test`. Given that regression tests are
    # tests of the source and not tests of the validity of the build
    # artifact(s), I've opted not to include them in the main derivation,
    # but are available in `passthru.tests`.
    doCheck = false;

    # passthru.tests.xtask-regression = stdenvNoCC.mkDerivation (self': {
    #   name = "flux-test-xtask-regression";
    #   src = self.outPath;
    #
    #   buildInputs = [ self ];
    #
    #   buildPhase = ''
    #     xtask test
    #   '';
    # });

    meta = {
      description = "Refinement Types for Rust";
      homepage = "https://flux-rs.github.io";
      license = [ lib.licenses.mit ];
    };
  })
