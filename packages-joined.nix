{
  lib,
  makeRustPlatform,

  rust-bins,
  flux-rs,

  makeWrapper,
  haskellPackages,
  z3,

  ...
}:
assert lib.assertMsg
  ((builtins.compareVersions z3.version "4.15") != -1)
  "flux requires at least version 4.15 of z3";
let
  rustPlatform = makeRustPlatform {
    rustc = rust-bins;
    cargo = rust-bins;
  };
in
rustPlatform.buildRustPackage (self: {
  name = "flux-rs";
  src = flux-rs;
  cargoHash = "sha256-i/9+q1Biz6sepLZCFvBNrIXsV8XfYvOThvB4ceExhi8=";

  nativeBuildInputs = [
    rust-bins
    haskellPackages.liquid-fixpoint
    z3

    makeWrapper
  ];

  buildInputs = [
    rust-bins
    haskellPackages.liquid-fixpoint
    z3
  ];

  propagatedBuildInputs = [ rust-bins ];

  cargoBuildType = "release";
  cargoBuildFlags = [ "--workspace" ];

  # postFixup = ''
  #   wrapProgram $out/bin/cargo-flux --set FLUX        $out/bin/flux
  #   wrapProgram $out/bin/flux       --set FLUX_DRIVER $out/bin/flux-driver
  # '';

  # Doesn't have cargo tests. Flux's tests are regression tests that
  # are run using `cargo xtask test`. Given that regression tests
  # are tests of the source and not tests of the validity of the build
  # artifact(s), I've opted not to include them in the main derivation,
  # but are available in `passthru.tests`.
  doCheck = false;

  meta = {
    description = "Refinement Types for Rust";
    homepage = "https://flux-rs.github.io";
    license = [ lib.licenses.mit ];
  };
})
