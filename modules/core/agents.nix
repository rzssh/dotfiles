{ config, ... }:

{
  environment.etc."codex/config.toml".text = ''
    model = "gpt-5.6-sol"
    model_reasoning_effort = "max"
    plan_mode_reasoning_effort = "max"
    default_permissions = "developer"

    [shell_environment_policy]
    inherit = "all"
    ignore_default_excludes = true
    exclude = ["OPENAI_API_KEY", "AI_PROFILE_KEYS"]

    [permissions.developer]
    description = "Read system, write projects, use network without prompts."
    extends = ":workspace"

    [permissions.developer.filesystem]
    ":root" = "read"
    "~/projects" = "write"
    "~/notes" = "write"

    [permissions.developer.network]
    enabled = true
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
