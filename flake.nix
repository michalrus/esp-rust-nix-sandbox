{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixlint = {
      url = "github:michalrus/nixlint";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.devshell.flakeModule
        inputs.treefmt-nix.flakeModule
      ];

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem = {
        system,
        pkgs,
        ...
      }: {
        imports = [
          ./nix/unsafe-bin.nix
          ./nix/safe-bwrap.nix
          ./nix/help.nix
          ./nix/devshell.nix
        ];

        treefmt = {
          projectRootFile = "flake.nix";
          programs = {
            alejandra.enable = true; # Nix
            prettier.enable = true; # Markdown
            rustfmt.enable = true;
            shfmt.enable = true;
            taplo.enable = true; # TOML
            yamlfmt.enable = true;
          };
        };

        checks.nixlint = pkgs.runCommand "nixlint" {nativeBuildInputs = [inputs.nixlint.packages.${system}.nixlint];} ''
          cd ${inputs.self}
          nixlint .
          touch $out
        '';
      };
    };
}
