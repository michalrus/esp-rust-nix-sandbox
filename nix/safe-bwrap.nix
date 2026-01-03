{
  config,
  lib,
  pkgs,
  ...
}: {
  packages = {
    bwrap-rustc = pkgs.writeShellApplication {
      name = "rustc";
      meta.description = "pre-built Rust compiler fork for ESP32 (xtensa, riscv32) in a Bubblewrap sandbox";
      text = ''
        echo TODO: unimplemented
        exit 1
      '';
    };
  };
}
