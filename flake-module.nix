{ inputs, config, ... }:
{
  imports = [
    ({ _module.args.mlib = inputs.mlib.lib; })

    (
      {
        lib,
        mlib,
        flake-parts-lib,
        ...
      }:
      flake-parts-lib.mkTransposedPerSystemModule {
        name = "tests";
        option = lib.mkOption {
          type = lib.types.lazyAttrsOf mlib.types.packageSet;
          default = { };
          description = ''
            A set of package-sets, which are sets of tests and/or nested
            package-sets of tests.
          '';
        };
        file = ./flake-module.nix;
      }
    )
  ];

  config = {
    perSystem =
      { system, lib, ... }:
      {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = builtins.attrValues config.flake.overlays;
        };
      };
  };
}
