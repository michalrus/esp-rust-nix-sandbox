{
  config,
  lib,
  pkgs,
  ...
}: {
  packages.help-bwrap = let
    name = "help-bwrap";
  in
    pkgs.writeShellApplication {
      inherit name;
      meta = {
        description = "Shows how to set up Bubblewrap on NixOS";
        longDescription = ''
          Untrusted binary blobs (pre-built Rust and GCC compilers) are run in a
          Bubblewrap ({bold}bwrap{reset}) sandbox. Set it up yourself (see {bold}${name}{reset}), because
          it needs to be setuid.
        '';
      };
      text = ''
        # shellcheck disable=SC2016
        cat <<<${lib.escapeShellArg (lib.trim ''
          Add the following fragment to your NixOS configuration:

            security.wrappers = {
              # Low-level unprivileged sandboxing tool, see <https://github.com/containers/bubblewrap>.
              bwrap = {
                owner = "root";
                group = "root";
                source = "''${pkgs.bubblewrap}/bin/bwrap";
                setuid = true;
              };
            };
        '')}
      '';
    };
}
