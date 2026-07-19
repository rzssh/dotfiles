{
  description = "razen system, home, and dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    herdr = {
      url = "github:ogulcancelik/herdr";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms-plugins = {
      url = "github:AvengeMedia/dms-plugins/f4583449f12920e0a2f16808b00a860c27f0173d";
      flake = false;
    };

    dank-calendar = {
      url = "github:AvengeMedia/dankcalendar";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-bambu.url = "github:NixOS/nixpkgs/00fa9a692bafc08a86061886f888b843bf7fbdb0";

    nixpkgs-llamacpp.url = "github:NixOS/nixpkgs/a799d3e3886da994fa307f817a6bc705ae538eeb";

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helium = {
      url = "github:oxcl/nix-flake-helium-browser";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hermes-agent.url = "github:NousResearch/hermes-agent";

    pi-coding-agent-src = {
      url = "https://registry.npmjs.org/@earendil-works/pi-coding-agent/-/pi-coding-agent-0.80.10.tgz";
      flake = false;
    };

    openspec = {
      url = "github:Fission-AI/OpenSpec";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ nixpkgs, home-manager, ... }:
    let
      vars = import ./hosts/razen/variables.nix;
      shellTemplate = name: {
        path = ./dev-shells/${name};
        description = "${name} dev shell with direnv and dotenv layering";
      };
    in
    {
      templates = {
        node = shellTemplate "node";
        bun = shellTemplate "bun";
        go = shellTemplate "go";
        rust = shellTemplate "rust";
        python = shellTemplate "python";
        zig = shellTemplate "zig";
        c = shellTemplate "c";
        empty = shellTemplate "empty";
        default = shellTemplate "empty";
      };

      nixosConfigurations.${vars.hostname} = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs vars; };
        modules = [
          ./hosts/razen
          inputs.sops-nix.nixosModules.sops
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "hmbak";
            home-manager.extraSpecialArgs = { inherit inputs vars; };
            home-manager.users.${vars.username} = import ./home/razen.nix;
          }
        ];
      };
    };
}
