
##### [![FlakeHub](https://img.shields.io/endpoint?url=https://flakehub.com/f/MaxTheMooshroom/flux-rs/badge)](https://flakehub.com/flake/MaxTheMooshroom/flux-rs) [![autofix enabled](https://shields.io/badge/autofix.ci-yes-success?logo=data:image/svg+xml;base64,PHN2ZyBmaWxsPSIjZmZmIiB2aWV3Qm94PSIwIDAgMTI4IDEyOCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48cGF0aCB0cmFuc2Zvcm09InNjYWxlKDAuMDYxLC0wLjA2MSkgdHJhbnNsYXRlKC0yNTAsLTE3NTApIiBkPSJNMTMyNSAtMzQwcS0xMTUgMCAtMTY0LjUgMzIuNXQtNDkuNSAxMTQuNXEwIDMyIDUgNzAuNXQxMC41IDcyLjV0NS41IDU0djIyMHEtMzQgLTkgLTY5LjUgLTE0dC03MS41IC01cS0xMzYgMCAtMjUxLjUgNjJ0LTE5MSAxNjl0LTkyLjUgMjQxcS05MCAxMjAgLTkwIDI2NnEwIDEwOCA0OC41IDIwMC41dDEzMiAxNTUuNXQxODguNSA4MXExNSA5OSAxMDAuNSAxODAuNXQyMTcgMTMwLjV0MjgyLjUgNDlxMTM2IDAgMjU2LjUgLTQ2IHQyMDkgLTEyNy41dDEyOC41IC0xODkuNXExNDkgLTgyIDIyNyAtMjEzLjV0NzggLTI5OS41cTAgLTEzNiAtNTggLTI0NnQtMTY1LjUgLTE4NC41dC0yNTYuNSAtMTAzLjVsLTI0MyAtMzAwdi01MnEwIC0yNyAzLjUgLTU2LjV0Ni41IC01Ny41dDMgLTUycTAgLTg1IC00MS41IC0xMTguNXQtMTU3LjUgLTMzLjV6TTEzMjUgLTI2MHE3NyAwIDk4IDE0LjV0MjEgNTcuNXEwIDI5IC0zIDY4dC02LjUgNzN0LTMuNSA0OHY2NGwyMDcgMjQ5IHEtMzEgMCAtNjAgNS41dC01NCAxMi41bC0xMDQgLTEyM3EtMSAzNCAtMiA2My41dC0xIDU0LjVxMCA2OSA5IDEyM2wzMSAyMDBsLTExNSAtMjhsLTQ2IC0yNzFsLTIwNSAyMjZxLTE5IC0xNSAtNDMgLTI4LjV0LTU1IC0yNi41bDIxOSAtMjQydi0yNzZxMCAtMjAgLTUuNSAtNjB0LTEwLjUgLTc5dC01IC01OHEwIC00MCAzMCAtNTMuNXQxMDQgLTEzLjV6TTEyNjIgNjE2cS0xMTkgMCAtMjI5LjUgMzQuNXQtMTkzLjUgOTYuNWw0OCA2NCBxNzMgLTU1IDE3MC41IC04NXQyMDQuNSAtMzBxMTM3IDAgMjQ5IDQ1LjV0MTc5IDEyMXQ2NyAxNjUuNWg4MHEwIC0xMTQgLTc3LjUgLTIwNy41dC0yMDggLTE0OXQtMjg5LjUgLTU1LjV6TTgwMyA1OTVxODAgMCAxNDkgMjkuNXQxMDggNzIuNWwyMjEgLTY3bDMwOSA4NnE0NyAtMzIgMTA0LjUgLTUwdDExNy41IC0xOHE5MSAwIDE2NSAzOHQxMTguNSAxMDMuNXQ0NC41IDE0Ni41cTAgNzYgLTM0LjUgMTQ5dC05NS41IDEzNHQtMTQzIDk5IHEtMzcgMTA3IC0xMTUuNSAxODMuNXQtMTg2IDExNy41dC0yMzAuNSA0MXEtMTAzIDAgLTE5Ny41IC0yNnQtMTY5IC03Mi41dC0xMTcuNSAtMTA4dC00MyAtMTMxLjVxMCAtMzQgMTQuNSAtNjIuNXQ0MC41IC01MC41bC01NSAtNTlxLTM0IDI5IC01NCA2NS41dC0yNSA4MS41cS04MSAtMTggLTE0NSAtNzB0LTEwMSAtMTI1LjV0LTM3IC0xNTguNXEwIC0xMDIgNDguNSAtMTgwLjV0MTI5LjUgLTEyM3QxNzkgLTQ0LjV6Ii8+PC9zdmc+)](https://autofix.ci)

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

