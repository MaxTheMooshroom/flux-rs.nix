{
  rust-bins,
  mkBinLink,
}:
mkBinLink {
  package = rust-bins;
  bin-name = "cargo";
}
