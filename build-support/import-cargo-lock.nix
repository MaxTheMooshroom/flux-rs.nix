{
  rustPlatform,
  flux-dep-hash ? "sha256-F3z+PCEm3j0OlOy2AaobF7o+V/OoJiimskOpDLNB8ZQ=",
}:
{
  outputHashes ? { },
  ...
}@args:
rustPlatform.importCargoLock (
  args
  // {
    outputHashes = outputHashes // {
      "flux-rs-0.1.0" = flux-dep-hash;
    };
  }
)
