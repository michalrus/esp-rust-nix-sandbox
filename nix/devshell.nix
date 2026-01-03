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
        {package = packages.bwrap-rustc;}
        {package = packages.help-bwrap;}
      ];

      devshell = {
        packages = [
          pkgs.unixtools.xxd
          pkgs.clippy
        ];

        motd = ''

          {202}🔨 Welcome to ${config.name}{reset}

          ${lib.trim packages.help-bwrap.meta.longDescription}
          $(menu)

          You can now run ‘{bold}???{reset}’.
        '';

        startup.check-bubblewrap.text = ''
          # TODO
        '';
      };
    };
}
