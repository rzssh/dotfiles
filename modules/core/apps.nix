{ pkgs, vars, ... }:

{
  nixpkgs.overlays = [
    (_: previous: {
      mailspring = previous.mailspring.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ../../patches/mailspring-system-notification-sound.patch ];
      });
    })
  ];

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ vars.username ];
  };

  environment.etc."1password/custom_allowed_browsers" = {
    text = "zen\n";
    mode = "0755";
  };

  programs.kdeconnect.enable = true;

  programs.ydotool.enable = true;

  users.users.${vars.username}.extraGroups = [ "ydotool" ];

  services.mullvad-vpn = {
    enable = true;
    package = pkgs.mullvad-vpn;
  };
}
