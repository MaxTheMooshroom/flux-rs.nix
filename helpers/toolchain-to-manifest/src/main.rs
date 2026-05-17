
use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(version, about)]
struct Cli {
    #[command(subcommand)]
    subcommand: CliSubcommand,
}

#[derive(Subcommand)]
enum CliSubcommand {
    /// The `toolchain.channel` value of a `rust-toolchain.toml` file.
    String {
        /// The `toolchain.channel` value of a `rust-toolchain.toml` file.
        toolchain_string: String
    },
    /// A path to a `rust-toolchain.toml` file.
    File {
        /// A path to a `rust-toolchain.toml` file.
        toolchain_file: std::path::PathBuf,
    }
}

fn read_manifest_channel(s: &std::path::Path) -> String {
    #[derive(serde::Deserialize)]
    pub struct ToolchainToml {
        toolchain: ToolchainSpec,
    }

    #[derive(serde::Deserialize)]
    pub struct ToolchainSpec {
        channel: String,
    }

    let contents = std::fs::read_to_string(s).unwrap();
    let toolchain_file: ToolchainToml = toml::from_str(&contents)
        .expect("Failed to parse channel from rust-toolchain.toml");

    toolchain_file.toolchain.channel
}

fn channel_to_manifest_url(channel: &str) -> String {
    use rustup_toolchain_manifest::Toolchain;

    use std::str::FromStr;

    Toolchain::from_str(channel)
        .unwrap_or_else(|_| panic!("Invalid toolchain channel string: {}", channel))
        .manifest_url()
}

fn main() {
    let toolchain_str = match Cli::parse().subcommand {
        CliSubcommand::String { toolchain_string }
            => toolchain_string,
        CliSubcommand::File { toolchain_file }
            => read_manifest_channel(&toolchain_file),
    };

    print!("{}", channel_to_manifest_url(&toolchain_str));
}
