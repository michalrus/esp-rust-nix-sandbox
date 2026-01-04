{
  config,
  lib,
  pkgs,
  ...
}: {
  packages = {
    bwrap-rustc = pkgs.writeShellApplication {
      name = "rustc";
      meta.description = "Pre-built Rust compiler fork for ESP32 (xtensa, riscv32) in a Bubblewrap sandbox";
      text = ''
        mkdir -p "$PRJ_ROOT/target/tmp"
        bwrap_opts=(
          --unshare-all
          --die-with-parent
          --proc /proc
          --dev /dev
          --clearenv
          --setenv PATH ${lib.makeBinPath [
          config.packages.unsafe-bin-esp-gcc-xtensa
          config.packages.unsafe-bin-esp-gcc-riscv32
          pkgs.stdenv.cc # needed for `build.rs` scripts which run on the host
        ]}
          --ro-bind /nix/store /nix/store
          --bind "$PRJ_ROOT" "$PRJ_ROOT"
          --bind "$PRJ_ROOT/target/tmp" /tmp
        )
        for k in $(env | cut -d= -f1); do
          case "$k" in
            CARGO|CARGO_*|ESP_*|OUT_DIR)
              bwrap_opts+=(--setenv "$k" "''${!k}")
              ;;
          esac
        done
        exec bwrap "''${bwrap_opts[@]}" -- ${config.packages.unsafe-bin-esp-rust}/bin/rustc "$@"
      '';
    };

    bwrap-cargo = pkgs.cargo.overrideAttrs (old: {
      # Don’t force the non-forked compiler onto Cargo’s `PATH`:
      postInstall =
        old.postInstall
        + ''
          sed -r 's#${old.passthru.rustc}#${pkgs.emptyDirectory}#g' -i $out/bin/cargo
        '';
    });
  };
}
