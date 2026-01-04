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
  };

  outputs = inputs: let
    inherit (inputs.nixpkgs) lib;
  in
    inputs.flake-parts.lib.mkFlake {inherit inputs;} ({config, ...}: {
      imports = [
        inputs.devshell.flakeModule
        inputs.treefmt-nix.flakeModule
      ];

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      perSystem = {
        system,
        pkgs,
        ...
      }: rec {
        imports = [
          ./nix/unsafe-bin.nix
          ./nix/safe-bwrap.nix
          ./nix/help.nix
          ./nix/devshell.nix
        ];

        treefmt = {pkgs, ...}: {
          projectRootFile = "flake.nix";
          programs = {
            alejandra.enable = true; # Nix
            rustfmt.enable = true;
            shfmt.enable = true;
            taplo.enable = true; # TOML
          };
        };
      };
    });
}
