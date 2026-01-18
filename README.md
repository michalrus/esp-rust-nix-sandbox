# esp-rust-nix-sandbox

Nix devshell for Rust on ESP/ESP32. Pre-built compiler runs in a strict [Bubblewrap](https://github.com/containers/bubblewrap) sandbox.

Supports Xtensa (ESP32) and RISC-V 32-bit (ESP32-C3 / ESP32-C2 / ESP32-C6 / ESP32-H2 / …).

## Rationale

The ESP Rust toolchain story is a bit unusual, because the Xtensa architecture support is not yet available in the mainline Rust:
* The [`esp-rs/rust`](https://github.com/esp-rs/rust) fork ships pre-built `rustc`/`rustdoc` binaries.
* It’s similar with Espressif ESP GCC toolchain.
* Those binaries are big, powerful, and hard to audit.
* At the same time, fully rebuilding the forked compiler from source in every project is slow, fragile, and requires lots of RAM. Not to mention reading the actual changes made to mainline Rust.

So this repo aims for a pragmatic middle ground:
* Treat pre-built compilers as untrusted binary blobs.
* Constrain them heavily so they can only see:
  * their own Nix store closure (read-only), and
  * `$PRJ_ROOT` (your devshell root).
* Remove ambient authority:
  * no inherited environment,
  * no access to your home directory, SSH keys, GnuPG, etc.,
  * no network access,
  * no random host filesystem access,
  * `CARGO_HOME` is separate and lives inside `$PRJ_ROOT`, so dependency state is project-local and doesn’t leak into global caches.
* Everything else is kept “normal” and reproducible: Cargo, `espflash`, `rustfmt`, `clippy`, etc. come from Nixpkgs and are built from source (and run outside the sandbox).

We use [Bubblewrap](https://github.com/containers/bubblewrap) for this which is a “low-level unprivileged sandboxing tool used by Flatpak and similar projects.” 

In effect: you can use the convenient upstream pre-builts for `rustc`/`rustdoc` (and the ESP GCC/GDB toolchain), without giving them almost any access to your machine.

**Warning**: in theory, the binary blob compiler _could_ still add something malicious to your firmware that would later run on the target ESP device.

## How to use

1. Install [Nix](https://nixos.org/download/).
1. Install [direnv](https://direnv.net/), preferably with `nix-direnv`.
1. Enter the directory, and type in `direnv allow`.
1. You’ll get further instructions there:

```
❯ cd esp-rust-nix-sandbox

🔨 Welcome to esp-rust-nix-sandbox-devshell

Untrusted binary blobs (pre-built Rust and GCC compilers) are run in a strict Bubblewrap
(bwrap) sandbox with access only to /home/m/Work/esp-rust-nix-sandbox.

The other tools (Cargo, espflash, etc.) are source-based and come from regular Nixpkgs.

[[general commands]]

  cargo         - Downloads your Rust project's dependencies and builds your project
  clippy        - Bunch of lints to catch common mistakes and improve your Rust code
  espflash      - Serial flasher utility for Espressif SoCs and modules based on esptool.py
  menu          - prints this menu
  picocom       - Minimal dumb-terminal emulation program
  rust-analyzer - Language server for the Rust language
  rustc         - Pre-built Rust compiler fork for ESP32 (xtensa, riscv32) in a Bubblewrap sandbox (rustc)
  rustfmt       - Tool for formatting Rust code according to style guidelines

You can now run:
  • cd embassy_hello_world
  • cargo build --features esp32 --target xtensa-esp32-none-elf --release
  • cargo doc   --features esp32 --target xtensa-esp32-none-elf --release --open
  • espflash save-image --chip esp32 target/xtensa-esp32-none-elf/release/embassy-hello-world out.bin

To flash, and monitor output:
  • cargo espflash flash --monitor --features esp32 --target xtensa-esp32-none-elf --release
  • cargo run --release (alias of ^)
  • picocom --baud=115200 --imap lfcrlf /dev/ttyUSB0
```

You have to set up `bwrap` yourself, as it needs to be `setuid`. On NixOS:

```nix
{
  security.wrappers = {
    # Low-level unprivileged sandboxing tool, see <https://github.com/containers/bubblewrap>.
    bwrap = {
      owner = "root";
      group = "root";
      source = "${pkgs.bubblewrap}/bin/bwrap";
      setuid = true;
    };
  };
}
```

Feel free to copy the Nix bits into your own project. Or depend on this repo.

## Further work

### GDB

GDB is missing (`rust-gdb` over OpenOCD and JTAG). I personally mostly run host-based tests, so I didn’t need to wire this up yet. Feel free to open an issue.

### Sandboxing on macOS

On macOS (`aarch64-darwin`) there’s no Bubblewrap sandbox equivalent, so the pre-built compilers run directly on the host. Support for Darwin has only been added for completeness, but you do not get the “untrusted compiler in a strict jail” guarantee. It works, but you run it on your own responsibility!
