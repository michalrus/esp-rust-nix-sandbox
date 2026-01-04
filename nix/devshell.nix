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
      name = "rust-esp32-devshell";

      commands = [
        {package = packages.help-bwrap;}
        {package = packages.bwrap-rustc;}
        {package = packages.bwrap-cargo;}
        {package = pkgs.rustfmt;}
        {package = pkgs.rust-analyzer;}
        {package = pkgs.clippy;}
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
      ];

      devshell = {
        packages = [
          pkgs.unixtools.xxd
        ];

        motd = ''

          {202}🔨 Welcome to ${config.name}{reset}

          ${lib.trim packages.help-bwrap.meta.longDescription}
          $(menu)

          You can now run:
            • {bold}cd embassy_hello_world{reset}
            • {bold}cargo build --features esp32 --target xtensa-esp32-none-elf --release{reset}
        '';

        startup.check-bubblewrap.text = ''
          # TODO
        '';
      };
    };
}
