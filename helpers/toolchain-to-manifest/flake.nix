{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/25.11";
  };

  outputs = { self, flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } ({ lib, ... }: {
      systems = lib.systems.flakeExposed;

      imports = [];

      perSystem = { self', pkgs, ... }: {
        packages = {
          default = self'.packages.toolchain2manifest;

          toolchain2manifest = pkgs.rustPlatform.buildRustPackage (self': {
            pname = "toolchain-to-manifest";
            version = "0.1.0";

            src = self.outPath;
            # cargoHash = "";
            cargoHash = "sha256-zdBqi4d9/GY/i6/t6gRGmkTvm6dybNTiLSW/Gd5tlyI=";

            meta = {
              mainProgram = self'.pname;
              license = lib.licenses.mit;
            };
          });
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            cargo
          ];
        };
      };
    });
}
