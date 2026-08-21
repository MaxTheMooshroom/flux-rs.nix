{
  runCommand,

  dependencies,
  flux-src,
}:
let
  manifest_url =
    let
      toml = builtins.fromTOML (builtins.readFile (flux-src.outPath + "/rust-toolchain.toml"));
      channel = toml.toolchain.channel;
    in
    runCommand "get-manifest-url" { buildInputs = [ dependencies.toolchain2manifest ]; } ''
      toolchain-to-manifest ${channel} > $out
    '';

  manifest_raw = builtins.fetchurl {
    name = "rust-toolchain-manifest.toml";
    url = builtins.readFile manifest_url;
    sha256 = "1imy60c8agif74i39ccsa581lnzbx3qx0fkapqdhp0pfwq8ya45y";
  };
in
builtins.fromTOML (builtins.readFile manifest_raw)
