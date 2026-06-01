
# Flux for Nix

[Flux](https://flux-rs.github.io/flux/)
is a rustc extension for validation of
[refinement-type](https://en.wikipedia.org/wiki/Refinement_type)
predicates.

This flake packages flux as a wrapper around nixpkgs' `rustPlatform`
infrastructure, with additional toolchain orchestration aided by
[oxalica's rust-overlay](https://github.com/oxalica/rust-overlay).

Building your crate with this flake's infrastructure will build the
same as before, but provides the override for the flux-rs git repo
and runs `cargo flux check` at the end of the `checkPhase`
(as `postCheck`).

## Quickstart

`Cargo.toml`:
```toml
# ...

[dependencies]
    # ...

    flux-rs = { git = "https://github.com/flux-rs/flux.git" }

    # ...

```

`src/main.rs`:
```rust
use flux_rs::attrs::*;

// Refined type: integer >= 0
#[refined_by(n: int)]
#[invariant(n > 0)]
struct Nat(
    #[field(i32[n])]
    i32
);

impl Nat {
    #[sig(fn(n: i32{n > 0}) -> Self[n])]
    fn new(n: i32) -> Self {
        Self(n)
    }

    #[sig(fn(self: &Self[@n]) -> i32[n + 1])]
    fn successor(&self) -> i32 {
        self.0 + 1
    }
}

fn main() {
    let n = Nat::new(5);
    let x = n.successor();

    println!("n = {}", n.0);
    println!("succ = {}", x);
}
```

### With The Flake Module

`flake.nix`:
```nix
{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    flux-rs.url = "github:MaxTheMooshroom/flux-rs.nix";
  };

  outputs =
    { flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { lib, ... }:
      {
        systems = lib.systems.flakeExposed;

        imports = [ inputs.flux-rs.flakeModules.perSystem-moduleArgs ];

        perSystem =
          { fluxPlatform, ... }:
          {
            packages = {
              my-package = fluxPlatform.buildFluxPackage {
                name = "my-package";
                version = "0.1.0";

                src = ./.;

                cargoHash = "<sha256>";
              };
            };
          };
      }
    );
}
```

### Without The Flake Module

`flake.nix`:
```nix
{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    flux-rs.url = "github:MaxTheMooshroom/flux-rs.nix";
  };

  outputs =
    { flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { lib, ... }:
      {
        systems = lib.systems.flakeExposed;

        perSystem =
          { inputs', ... }:
          {
            packages = {
              # inputs.packageSets.${system}.fluxPlatform.buildFluxPackage
              my-package = inputs'.packageSets.fluxPlatform.buildFluxPackage (
                finalAttrs:
                {
                  name = "my-package";
                  version = "0.1.0";

                  src = ./.;

                  cargoHash = "<sha256>";
                }
              );
            };
          };
      }
    );
}
```

## Dev Shell Guide

The checkPhase integration is added via
`packageSets.<system>.fluxPlatform.fluxHooks.cargoFluxHook`,
and comes included with the `packages.<system>.cargo` output.

To get everything you need for developing with flux, add
the cargo output to your devshell:

```nix
{
  # ...
  perSystem =
    { fluxPlatform, pkgs, ... }:
    {
      devShells.default = pkgs.mkShell {
        packages = [
          fluxPlatform.cargo
        ];
      };
    };
  # ...
}
```

Afterwards you can run `nix develop` to have access to
standard rust/cargo infrastructure as well as being able
to run `cargo flux check`.

## buildFluxPackage Documentation

You can skip the `cargo flux check` command during building by
setting `dontCargoFlux` for `fluxPlatform.buildFluxPackage`.

If you need to vendor the sources, use `fluxPlatform.importCargoLock`
instead of `rustPlatform.importCargoLock` so that your `flux-rs` git
cargo dependency gets vendored properly.

```nix
fluxPlatform.buildFluxPackage (finalAttrs: {
  pname = "my-package";
  version = "0.1.0";

  src = ./.;

  dontCargoFlux = true; # skip the flux validation

  cargoDeps = fluxPlatform.importCargoLock {
    lockFile = ./Cargo.lock;
    outputHashes = { /* ... */ };
  };
})
```

