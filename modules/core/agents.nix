{ config, ... }:

{
  environment.etc."codex/config.toml".text = ''
    model = "gpt-5.6-sol"
    model_reasoning_effort = "max"
    plan_mode_reasoning_effort = "max"
    default_permissions = "profile-protected"

    [shell_environment_policy]
    inherit = "all"
    ignore_default_excludes = false
    exclude = ["*_API_KEY", "*_TOKEN", "*_SECRET", "AI_PROFILE_KEYS"]

    [permissions.profile-protected]
    description = "Workspace access without profile or authentication files."
    extends = ":workspace"

    [permissions.profile-protected.filesystem]
    glob_scan_max_depth = 4
    "~/.local/share/ai/profiles" = "deny"
    "~/.config/sops" = "deny"
    "~/.codex/auth.json" = "deny"
    "~/.claude/.credentials.json" = "deny"
    "~/.pi/agent/auth.json" = "deny"
    "~/.hermes/auth.json" = "deny"
    "~/.local/share/opencode/auth.json" = "deny"
    "~/.config/gh/hosts.yml" = "deny"
    "~/.git-credentials" = "deny"
    "~/.netrc" = "deny"

    [permissions.profile-protected.filesystem.":workspace_roots"]
    "**/*.env" = "deny"
    "secrets" = "deny"
  '';

  sops = {
    defaultSopsFile = ../../secrets/system.env;
    defaultSopsFormat = "dotenv";
    age.keyFile = "/home/razen/.config/sops/age/keys.txt";
    secrets.SEARX_SECRET_KEY = { };
    templates."searx.env".content = ''
      SEARX_SECRET_KEY=${config.sops.placeholder.SEARX_SECRET_KEY}
    '';
  };

  services.searx = {
    enable = true;
    environmentFile = config.sops.templates."searx.env".path;
    settings = {
      general.instance_name = "local";
      search.formats = [
        "html"
        "json"
      ];
      server = {
        bind_address = "127.0.0.1";
        port = 8888;
        secret_key = "$SEARX_SECRET_KEY";
        limiter = false;
      };
    };
  };
}
