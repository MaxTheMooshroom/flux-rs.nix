{ inputs, config, ... }:
{
  imports = [
    ({ ... }: {
      config = {
        flake.overlays.extractions = final: prev:
          let
            inherit (prev) lib;

            derivations = {
              /**
                Extract an executable from a derivation and optionally wrap it
                with environment variables required during runtime.
              */
              extractBinFrom =
                drv: { name, drv, mainProgram ? name, bin-env ? null }:
                  prev.stdenvNoCC.mkDerivation (finalAttrs: {
                    inherit name;

                    src = drv;
                    outputs = [ "out" ];

                    meta = { inherit mainProgram; };

                    installPhase = ''
                      mkdir -p $out/bin
                      cp ./bin/${mainProgram} $out/bin/${mainProgram}
                    '';
                  } // lib.optionalAttrs (!isNull bin-env && bin-env != {}) {
                    buildInputs = [ prev.makeWrapper ];
                    postFixup = ''
                      wrapProgram ./bin/${mainProgram} ${
                        builtins.concatStringsSep
                          " "
                          (lib.mapAttrsToList (n: v: "--set \"${n}\" \"${v}\"") bin-env)
                      }
                    '';
                  });

              /** Extract binaries from a derivation */
              extractBinsFrom = drv: opts':
                lib.mapAttrsToList
                  (name: v: final.lib.extractBinFrom drv (v // { inherit name; }))
                  opts';
          };
        in
        {
          inherit derivations;

          inherit (derivations)
            extractBinFrom
            extractBinsFrom
            ;
        };
      };
    })
  ];

  config = {
    perSystem = { system, lib, ... }: {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = builtins.attrValues config.flake.overlays;
      };
    };
  };
}
