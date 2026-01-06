{
  config,
  lib,
  pkgs,
  ...
}: {
  devshells.default = let
    inherit (config) packages;
  in
    {config, ...}: {
      name = "esp-rust-nix-sandbox-devshell";

      commands = [
        {package = packages.bwrap-rustc;}
        {package = packages.bwrap-cargo;}
        {package = pkgs.rustfmt;}
        {package = pkgs.rust-analyzer;}
        {package = pkgs.clippy;}
        {package = pkgs.espflash;}
        {package = pkgs.picocom;}
      ];

      env = [
        {
          name = "RUSTC";
          value = lib.getExe packages.bwrap-rustc;
        }
        {
          name = "CARGO_HOME";
          # We need it to be under $PRJ_ROOT, so that the sandboxed `rustc` has
          # access to it.
          eval = ''"$PRJ_ROOT"/target/cargo-home'';
        }
        {
          name = "RUST_SRC_PATH";
          value = "${packages.esp-rust-src}/lib/rustlib/src/rust/library";
        }
        {
          name = "ESPFLASH_SKIP_UPDATE_CHECK";
          value = "true";
        }
      ];

      devshell = {
        packages = [
          pkgs.unixtools.xxd
          packages.bwrap-rustdoc
        ];

        motd = ''

          {202}🔨 Welcome to ${config.name}{reset}

          Untrusted binary blobs (pre-built Rust and GCC compilers) are run in a strict Bubblewrap
          ({bold}bwrap{reset}) sandbox with access only to {bold}$PRJ_ROOT{reset}.

          The other tools (Cargo, espflash, etc.) are source-based and come from regular Nixpkgs.
          $(menu)

          You can now run:
            • {bold}cd embassy_hello_world{reset}
            • {bold}cargo build --features esp32 --target xtensa-esp32-none-elf --release{reset}
            • {bold}cargo doc   --features esp32 --target xtensa-esp32-none-elf --release --open{reset}
            • {bold}espflash save-image --chip esp32 target/xtensa-esp32-none-elf/release/embassy-hello-world out.bin{reset}

          To flash, and monitor output:
            • {bold}cargo espflash flash --monitor --features esp32 --target xtensa-esp32-none-elf --release{reset}
            • {bold}cargo run --release{reset} (alias of ^)
            • {bold}picocom --baud=115200 --imap lfcrlf /dev/ttyUSB0{reset}
        '';

        startup.verify-bwrap.text = lib.getExe packages.verify-bwrap;
      };
    };
}
