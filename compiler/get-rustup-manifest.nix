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
    sha256 = "0ymc7bqaclk99ivcyh06s3qas0a1hk1vgjv12b9x6f47ajb6w46x";
  };
in
builtins.fromTOML (builtins.readFile manifest_raw)
