self:
{
  system,

  toolchain2manifest,

  ...
}:
{
  toolchain2manifest = toolchain2manifest.packages.${system}.default;
}
