self:
{ lib, runCommand, ... }:
{
  all = lib.flip (runCommand "importCargoLock-all") "touch $out" {
    buildInputs = [
      self.basic
    ];
  };

  basic = self.callPackage ./basic { };
}
