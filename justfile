default:
    just --list

switch:
    nh os switch

boot:
    nh os boot

check:
    python3 tests/test_update.py
    python3 tests/test_focus_notify.py
    python3 tests/test_niri_startup.py
    just --justfile "$HOME/projects/agents/justfile" check
    nix flake check

test: check

build:
    nix build .#nixosConfigurations.razen.config.system.build.toplevel

update:
    nix shell --inputs-from . nixpkgs#nix-update nixpkgs#nodejs_24 nixpkgs#python3 nixpkgs#prefetch-npm-deps -c bash ./bin/update

hm-build:
    nix build .#nixosConfigurations.razen.config.home-manager.users.razen.home.activationPackage -o result-home

hm-switch: hm-build
    ./result-home/activate
