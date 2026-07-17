#!/usr/bin/env bash
set -euo pipefail

REPO="git@github.com:rzssh/dotfiles.git"
DIR="$HOME/projects/dotfiles"
HOST="${1:-razen}"

command -v git >/dev/null 2>&1 || exec nix-shell -p git --run "bash $0 $*"

if [ ! -d "$DIR/.git" ]; then
  mkdir -p "$(dirname "$DIR")"
  git clone --branch nixos "$REPO" "$DIR"
fi

cd "$DIR"

if [ ! -f "hosts/$HOST/hardware-configuration.nix" ] || [ "${REGEN_HW:-0}" = "1" ]; then
  sudo nixos-generate-config --show-hardware-config > "hosts/$HOST/hardware-configuration.nix"
fi

sudo nixos-rebuild boot --flake "$DIR#$HOST" --accept-flake-config

echo "Done. Reboot into the new generation."
