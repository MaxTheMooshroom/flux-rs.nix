{
  lib,
  stdenvNoCC,
  ...
}:
lib.extendMkDerivation {
  constructDrv = stdenvNoCC.mkDerivation;
  inheritFunctionArgs = false;
  excludeDrvArgNames = [
    "package"
    "bin-name"
    "drvAttrs"
  ];
  extendDrvArgs =
    finalArgs:
    {
      package,
      bin-name ? package.meta.mainProgram or package.pname or throw ''
        mkBinLink's source package must have meta.mainProgram or pname,
        or mkBinLink must be provided the bin's name.
      '',
      name ? "${bin-name}-linked",

      drvAttrs ? { },
      ...
    }:
    {
      inherit name;
      unpackPhase = "true";

      passthru.bin-name = bin-name;
      passthru."${bin-name}-unwrapped" = package;

      buildInputs = drvAttrs.buildInputs or [ ] ++ [ package ];
      nativeBuildInputs = drvAttrs.nativeBuildInputs or [ ] ++ [ package ];
      propagatedBuildInputs = drvAttrs.propagatedBuildInputs or [ ] ++ [ package ];

      buildPhase = ''
        runHook preBuild

        mkdir -p $out/bin
        ln -s ${lib.getExe' package bin-name} $out/bin/${bin-name}

        runHook postBuild
      '';

      meta = drvAttrs.meta or { } // {
        mainProgram = bin-name;
      };
    }
    // builtins.removeAttrs drvAttrs [
      "buildInputs"
      "nativeBuildInputs"
      "propagatedBuildInputs"
    ];
}
