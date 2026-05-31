self:
{ lib, runCommand, ... }:
{
  all = lib.flip (runCommand "flux-all") "touch $out" {
    buildInputs = [
      # self.cargoXtaskTest
    ];
  };

  # cargoXtaskTest = self.callPackage ./cargo-xtask-test { };
}
