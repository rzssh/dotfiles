# Dotfiles

## Tooling

| Layer      | Tooling                                                        |
| ---------- | -------------------------------------------------------------- |
| OS         | NixOS + CachyOS kernel                                         |
| Compositor | Hyprland                                                       |
| Shell      | DankMaterialShell                                              |
| Terminal   | Ghostty + herdr + fish                                         |
| Editor     | Neovim                                                         |
| Keyboard   | [Custom 34 keys alt layout](https://github.com/r4zendev/keebs) |

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/r4zendev/dotfiles/nixos/install.sh | bash
```

```sh
nh os switch            # rebuild (flake path preconfigured)
```

## Dev shells

```sh
nh init rust            # in any project: copies the template + direnv allow
```
