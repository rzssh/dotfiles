{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

let
  dots = "/home/razen/projects/dotfiles";
  link = path: config.lib.file.mkOutOfStoreSymlink "${dots}/${path}";
  aiRun = "${lib.getExe pkgs.python3} ${dots}/bin/ai-run";
  localPkgs = import ../pkgs { inherit pkgs inputs; };
  system = pkgs.stdenv.hostPlatform.system;
  herdr = inputs.herdr.packages.${system}.default;
  hermes = pkgs.callPackage "${inputs.hermes-agent}/nix/hermes-agent.nix" {
    inherit (inputs.hermes-agent.inputs) uv2nix pyproject-nix pyproject-build-systems;
    npm-lockfile-fix = inputs.hermes-agent.inputs.npm-lockfile-fix.packages.${system}.default;
    rev = inputs.hermes-agent.rev or null;
  };
  openspec = inputs.openspec.packages.${system}.default.overrideAttrs (old: {
    pnpmDeps = pkgs.fetchPnpmDeps {
      inherit (old) pname version src;
      pnpm = pkgs.pnpm_10;
      fetcherVersion = 3;
      hash = "sha256-OUY6G8e6Xqi+0YCcDbpVF06V9pJc68jSSA9rtNg/Vrg=";
    };
    nativeBuildInputs = with pkgs; [
      nodejs_24
      npmHooks.npmInstallHook
      pnpmConfigHook
      pnpm_10
    ];
  });
  profileFiles = lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".env" name) (
    builtins.readDir ../secrets/ai-profiles
  );
  profileNames = map (lib.removeSuffix ".env") (builtins.attrNames profileFiles);
  profileArguments = lib.escapeShellArgs profileNames;
  profileSecrets = lib.mapAttrs' (
    file: _:
    let
      profile = lib.removeSuffix ".env" file;
    in
    lib.nameValuePair "ai-profiles/${profile}" {
      sopsFile = ../secrets/ai-profiles + "/${file}";
      format = "dotenv";
      mode = "0400";
      path = "${config.home.homeDirectory}/.local/share/ai/profiles/${profile}/env";
    }
  ) profileFiles;
  clients = {
    pi = {
      executable = lib.getExe localPkgs.pi-coding-agent;
      credentials = null;
      homes.PI_CODING_AGENT_DIR = "~/.pi/agent:pi";
    };
    codex = {
      executable = "${config.home.homeDirectory}/.local/bin/codex";
      credentials = [ "OPENAI_API_KEY" ];
      homes.CODEX_HOME = "~/.codex:codex";
    };
    claude = {
      executable = "${config.home.homeDirectory}/.local/bin/claude";
      credentials = [
        "ANTHROPIC_API_KEY"
        "ANTHROPIC_AUTH_TOKEN"
        "CLAUDE_CODE_OAUTH_TOKEN"
      ];
      homes.CLAUDE_CONFIG_DIR = "~/.claude:claude";
    };
    opencode = {
      executable = lib.getExe pkgs.opencode;
      credentials = null;
      homes = {
        XDG_CACHE_HOME = "~/.cache:opencode/cache";
        XDG_CONFIG_HOME = "~/.config:opencode/config";
        XDG_DATA_HOME = "~/.local/share:opencode/data";
        XDG_STATE_HOME = "~/.local/state:opencode/state";
      };
    };
    hermes = {
      executable = "${hermes}/bin/hermes";
      credentials = [ ];
      homes.HERMES_HOME = "~/.hermes:hermes";
    };
  };
  homeArgs =
    client:
    lib.concatStringsSep " " (
      lib.mapAttrsToList (name: value: "--home ${lib.escapeShellArg "${name}=${value}"}") client.homes
    );
  credentialArgs =
    client:
    if client.credentials == null then
      "--all-credentials"
    else
      lib.concatMapStringsSep " " (name: "--credential ${lib.escapeShellArg name}") client.credentials;
  clientArgs =
    client:
    lib.concatStringsSep " " [
      (credentialArgs client)
      (homeArgs client)
    ];
  releaseAgent = name: ''
    release_agent() {
      status=$?
      trap - EXIT
      if [ "''${HERDR_ENV:-}" = 1 ] && [ -n "''${HERDR_PANE_ID:-}" ] && [ -n "''${HERDR_SOCKET_PATH:-}" ]; then
        ${herdr}/bin/herdr pane release-agent "''${HERDR_PANE_ID}" --source "herdr:${name}" --agent "${name}" --seq "$(${pkgs.coreutils}/bin/date +%s%N)" >/dev/null 2>&1 || true
      fi
      exit "$status"
    }
    trap release_agent EXIT
  '';
  wrappers = lib.mapAttrs (
    name: client:
    pkgs.writeShellScript "ai-${name}" (
      if name == "pi" then
        ''
          profile="''${AI_PROFILE:-''${AI_DEFAULT_PROFILE:-personal}}"
          protection="${dots}/agents/pi/extensions/profile-protection.ts"
          protection_args=(--extension "$protection")
          case "''${1:-}" in
            install|remove|uninstall|update|list|config) protection_args=() ;;
          esac
          exec ${aiRun} ${clientArgs client} "$profile" -- ${client.executable} "''${protection_args[@]}" "$@"
        ''
      else if name == "claude" then
        ''
          profile="''${AI_PROFILE:-''${AI_DEFAULT_PROFILE:-personal}}"
          ${releaseAgent name}
          ${aiRun} ${clientArgs client} "$profile" -- ${client.executable} "$@"
        ''
      else
        ''
          profile="''${AI_PROFILE:-''${AI_DEFAULT_PROFILE:-personal}}"
          ${lib.optionalString (name == "codex") (releaseAgent name)}
          ${
            lib.optionalString (name != "codex") "exec "
          }${aiRun} ${clientArgs client} "$profile" -- ${client.executable} "$@"
        ''
    )
  ) clients;
  wrapperFiles = lib.mapAttrs' (
    name: source: lib.nameValuePair ".local/share/ai/bin/${name}" { inherit source; }
  ) wrappers;
in
{
  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  home.sessionPath = [
    "$HOME/.local/share/ai/bin"
    "$HOME/.local/bin"
  ];

  home.sessionVariables = {
    AI_DEFAULT_PROFILE = "personal";
    CAVEMAN_DEFAULT_MODE = "off";
    OPENSPEC_TELEMETRY = "0";
    PONYTAIL_DEFAULT_MODE = "off";
    SEARXNG_URL = "http://127.0.0.1:8888";
  };

  home.packages = [
    localPkgs.babysitter
    localPkgs.llama-cpp-cuda
    openspec
    pkgs.opencode
    pkgs.socat
    hermes
    herdr
  ];

  sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
  sops.secrets = profileSecrets;

  home.file = wrapperFiles // {
    ".local/bin/ai-run".source = link "bin/ai-run";
    ".local/bin/pi".source = wrappers.pi;
    ".local/bin/ai-workspace".source = link "bin/ai-workspace";
    ".local/bin/ai-workspace-picker".source = link "bin/ai-workspace-picker";
    ".claude/CLAUDE.md".source = link "agents/AGENTS.md";
    ".codex/AGENTS.md".source = link "agents/AGENTS.md";
    ".pi/agent/AGENTS.md".source = link "agents/AGENTS.md";
    ".pi/agent/extensions/web.ts".source = link "agents/pi/extensions/web.ts";
    ".pi/agent/lib/web.ts".source = link "agents/pi/lib/web.ts";
    ".config/opencode/AGENTS.md".source = link "agents/AGENTS.md";
    ".config/opencode/plugins/profile-protection.js".source =
      link "agents/opencode/plugins/profile-protection.js";
    ".agents/skills/delegate-work".source = link "agents/skills/delegate-work";
    ".agents/skills/herdr-agent-comms".source = link "agents/skills/herdr-agent-comms";
    ".agents/skills/herdr/SKILL.md".source = "${inputs.herdr}/SKILL.md";
    ".claude/skills/delegate-work".source = link "agents/skills/delegate-work";
    ".claude/skills/herdr-agent-comms".source = link "agents/skills/herdr-agent-comms";
    ".claude/skills/herdr/SKILL.md".source = "${inputs.herdr}/SKILL.md";
  };

  home.activation.agentProfiles = lib.hm.dag.entryAfter [ "linkGeneration" "sops-nix" ] ''
    umask 077

    json_overlay() {
      source=$1
      target=$2
      directory="$(${pkgs.coreutils}/bin/dirname "$target")"
      ${pkgs.coreutils}/bin/mkdir -p "$directory"
      ${pkgs.coreutils}/bin/chmod 700 "$directory"
      current="$(${pkgs.coreutils}/bin/mktemp "$directory/.current.XXXXXX")"
      merged="$(${pkgs.coreutils}/bin/mktemp "$directory/.merged.XXXXXX")"
      if [ -e "$target" ]; then
        ${pkgs.coreutils}/bin/cp -L "$target" "$current"
      else
        printf '{}\n' > "$current"
      fi
      ${pkgs.jq}/bin/jq -e 'type == "object"' "$current" >/dev/null
      ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$current" "$source" > "$merged"
      ${pkgs.coreutils}/bin/chmod 600 "$merged"
      ${pkgs.coreutils}/bin/mv -f "$merged" "$target"
      ${pkgs.coreutils}/bin/rm -f "$current"
    }

    yaml_overlay() {
      source=$1
      target=$2
      directory="$(${pkgs.coreutils}/bin/dirname "$target")"
      ${pkgs.coreutils}/bin/mkdir -p "$directory"
      ${pkgs.coreutils}/bin/chmod 700 "$directory"
      current="$(${pkgs.coreutils}/bin/mktemp "$directory/.current.XXXXXX")"
      current_json="$(${pkgs.coreutils}/bin/mktemp "$directory/.current-json.XXXXXX")"
      source_json="$(${pkgs.coreutils}/bin/mktemp "$directory/.source-json.XXXXXX")"
      merged_json="$(${pkgs.coreutils}/bin/mktemp "$directory/.merged-json.XXXXXX")"
      merged="$(${pkgs.coreutils}/bin/mktemp "$directory/.merged.XXXXXX")"
      if [ -e "$target" ]; then
        ${pkgs.coreutils}/bin/cp -L "$target" "$current"
      else
        printf '{}\n' > "$current"
      fi
      ${pkgs.yq-go}/bin/yq -o=json "$current" > "$current_json"
      ${pkgs.yq-go}/bin/yq -o=json "$source" > "$source_json"
      ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$current_json" "$source_json" > "$merged_json"
      ${pkgs.yq-go}/bin/yq -p=json -o=yaml -P "$merged_json" > "$merged"
      ${pkgs.coreutils}/bin/chmod 600 "$merged"
      ${pkgs.coreutils}/bin/mv -f "$merged" "$target"
      ${pkgs.coreutils}/bin/rm -f "$current" "$current_json" "$source_json" "$merged_json"
    }

    managed_link() {
      source=$1
      target=$2
      ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$target")"
      ${pkgs.coreutils}/bin/ln -sfnT "$source" "$target"
    }

    ${pkgs.coreutils}/bin/mkdir -p "$HOME/.local/share/ai/profiles"
    ${pkgs.coreutils}/bin/chmod 700 "$HOME/.local/share/ai" "$HOME/.local/share/ai/profiles"

    for profile in ${profileArguments}; do
      if [ "$profile" = personal ]; then
        claude="$HOME/.claude"
        codex="$HOME/.codex"
        gh="$HOME/.config/gh"
        hermes_home="$HOME/.hermes"
        opencode="$HOME/.config/opencode"
        pi="$HOME/.pi/agent"
      else
        root="$HOME/.local/share/ai/profiles/$profile"
        claude="$root/claude"
        codex="$root/codex"
        gh="$root/gh"
        hermes_home="$root/hermes"
        opencode="$root/opencode/config/opencode"
        pi="$root/pi"
      fi

      for directory in "$claude" "$codex" "$gh" "$hermes_home" "$opencode" "$pi"; do
        ${pkgs.coreutils}/bin/mkdir -p "$directory"
        ${pkgs.coreutils}/bin/chmod 700 "$directory"
      done

      if [ "$profile" != personal ]; then
        managed_link "${dots}/agents/AGENTS.md" "$claude/CLAUDE.md"
        managed_link "${dots}/agents/skills/delegate-work" "$claude/skills/delegate-work"
        managed_link "${dots}/agents/skills/herdr-agent-comms" "$claude/skills/herdr-agent-comms"
        managed_link "${inputs.herdr}/SKILL.md" "$claude/skills/herdr/SKILL.md"
        managed_link "${dots}/agents/AGENTS.md" "$codex/AGENTS.md"
        managed_link "${dots}/agents/AGENTS.md" "$pi/AGENTS.md"
        managed_link "${dots}/agents/pi/extensions/web.ts" "$pi/extensions/web.ts"
        managed_link "${dots}/agents/pi/lib/web.ts" "$pi/lib/web.ts"
        managed_link "${dots}/agents/AGENTS.md" "$opencode/AGENTS.md"
        managed_link "${dots}/agents/opencode/plugins/profile-protection.js" "$opencode/plugins/profile-protection.js"
        managed_link "${dots}/config/gh/config.yml" "$gh/config.yml"
      fi

      ${pkgs.coreutils}/bin/rm -f "$pi/extensions/profile-protection.ts" "$pi/extensions/workspace-sandbox.ts"

      json_overlay "${dots}/agents/claude/settings.json" "$claude/settings.json"
      json_overlay "${dots}/agents/pi/settings.json" "$pi/settings.json"
      yaml_overlay "${dots}/agents/hermes/config.yaml" "$hermes_home/config.yaml"

      ${aiRun} ${homeArgs clients.pi} "$profile" -- ${herdr}/bin/herdr integration install pi >/dev/null
      ${aiRun} ${homeArgs clients.claude} "$profile" -- ${herdr}/bin/herdr integration install claude >/dev/null
      ${aiRun} ${homeArgs clients.codex} "$profile" -- ${herdr}/bin/herdr integration install codex >/dev/null
      ${aiRun} ${homeArgs clients.opencode} "$profile" -- ${herdr}/bin/herdr integration install opencode >/dev/null
      ${aiRun} ${homeArgs clients.hermes} "$profile" -- ${herdr}/bin/herdr integration install hermes >/dev/null
    done
  '';
}
