default:
    just --list

switch:
    nh os switch

boot:
    nh os boot

check:
    nix flake check

test: check

build:
    nix build .#nixosConfigurations.razen.config.system.build.toplevel

update:
    nix flake update

hm-build:
    nix build .#nixosConfigurations.razen.config.home-manager.users.razen.home.activationPackage -o result-home
