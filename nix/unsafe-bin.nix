{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;

  rust = let
    version = "${pkgs.rustc.version}.0";
  in
    pkgs.stdenv.mkDerivation {
      pname = "rust";
      inherit version;
      src = pkgs.fetchzip {
        name = "rust-${version}";
        url = let
          system' =
            {
              x86_64-linux = "x86_64-unknown-linux-gnu";
            }.${
              system
            };
        in "https://github.com/esp-rs/rust-build/releases/download/v${version}/rust-${version}-${system'}.tar.xz";
        hash =
          {
            x86_64-linux = "sha256-+XSHYwZRqzQmy2XEQVljvTcgwKkx8Y3ZKHQWgbRJ1pI=";
          }.${
            system
          };
      };
      patchPhase = "patchShebangs .";
      nativeBuildInputs = with pkgs; [autoPatchelfHook pkg-config];
      buildInputs = with pkgs; [stdenv.cc.cc zlib];
      # FIXME: do we really need `cargo` and others here? Isn’t just `rustc` with Xtensa enough?
      installPhase = ''
        mkdir -p $out
        ./install.sh --destdir=$out --prefix= --disable-ldconfig --without=rust-docs-json-preview,rust-docs
        chmod -R +w $out
        ln -s ${rust-src}/lib/rustlib/src $out/lib/rustlib/src
      '';
    };

  rust-src = let
    inherit (rust) version;
  in
    pkgs.stdenv.mkDerivation {
      pname = "rust-src";
      inherit version;
      src = pkgs.fetchzip {
        name = "rust-src-${version}";
        url = "https://github.com/esp-rs/rust-build/releases/download/v${version}/rust-src-${version}.tar.xz";
        hash =
          {
            x86_64-linux = "sha256-3p4K15Bnin7gptpB7ub1TaYvRdWhy4AECtrWxy3wS74=";
          }.${
            system
          };
      };
      patchPhase = "patchShebangs .";
      nativeBuildInputs = with pkgs; [autoPatchelfHook pkg-config];
      buildInputs = with pkgs; [stdenv.cc.cc zlib];
      installPhase = ''
        mkdir -p $out
        ./install.sh --destdir=$out --prefix= --disable-ldconfig
      '';
    };

  esp-gcc = let
    version = "15.2.0_20250920";
  in
    lib.genAttrs ["xtensa" "riscv32"] (target:
      pkgs.stdenv.mkDerivation {
        pname = "esp-gcc-${target}";
        inherit version;
        src = pkgs.fetchzip {
          name = "esp-gcc-${target}-${version}";
          url = let
            system' =
              {
                x86_64-linux = "x86_64-linux-gnu";
              }.${
                system
              };
          in "https://github.com/espressif/crosstool-NG/releases/download/esp-${version}/${target}-esp-elf-${version}-${system'}.tar.xz";
          hash =
            {
              x86_64-linux = {
                xtensa = "sha256-TMjkfwsm9xwPYIowTrOgU+/Cst5uKV0xJH8sbxcTIlc=";
                riscv32 = "sha256-or85yVifw/j09F7I4pOdgut7Wti88LL1ftnyprX0A9E=";
              };
            }.${
              system
            }.${
              target
            };
        };
        patchPhase = "patchShebangs .";
        nativeBuildInputs = with pkgs; [autoPatchelfHook pkg-config];
        buildInputs = with pkgs; [stdenv.cc.cc zlib];
        installPhase = "cp -r . $out";
      });

  esp-gdb = let
    version = "16.3_20250913";
    python = pkgs.python3;
    pythonVersion = lib.concatStringsSep "." (lib.take 2 (lib.splitVersion python.version));
  in
    lib.genAttrs ["xtensa" "riscv32"] (target:
      pkgs.stdenv.mkDerivation {
        pname = "esp-gdb-${target}";
        inherit version;
        src = pkgs.fetchzip {
          name = "esp-gdb-${target}-${version}";
          url = let
            system' =
              {
                x86_64-linux = "x86_64-linux-gnu";
              }.${
                system
              };
          in "https://github.com/espressif/binutils-gdb/releases/download/esp-gdb-v${version}/${target}-esp-elf-gdb-${version}-${system'}.tar.gz";
          hash =
            {
              x86_64-linux = {
                xtensa = "sha256-LLbllfc+QvPyuv1mqNwgKDVTCMdDI4fDm+yt7dj2q1A=";
                riscv32 = "sha256-XN0ED+rlOjrWLGpC4gBdPcGkPF5bQgiG1IyHjtmYKoI=";
              };
            }.${
              system
            }.${
              target
            };
        };
        patchPhase = "patchShebangs .";
        nativeBuildInputs = with pkgs; [autoPatchelfHook pkg-config];
        buildInputs = with pkgs; [stdenv.cc.cc zlib python3];
        installPhase = ''
          cp -r . $out
          chmod -R +w $out
          cd $out/bin
          ls ${target}-esp-elf-gdb-3.* | grep -vF ${pythonVersion} | xargs rm
        '';
      });
in {
  packages = {
    esp-rust-src = rust-src;
    unsafe-bin-esp-rust = rust;
    unsafe-bin-esp-gcc-xtensa = esp-gcc.xtensa;
    unsafe-bin-esp-gcc-riscv32 = esp-gcc.riscv32;
    unsafe-bin-esp-gdb-xtensa = esp-gdb.xtensa;
    unsafe-bin-esp-gdb-riscv32 = esp-gdb.riscv32;
  };
}
