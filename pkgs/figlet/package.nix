{ figlet, fonts }:

figlet.overrideAttrs (old: {
  postInstall = ''
    ${old.postInstall or ""}
    cp --remove-destination ${fonts}/*.{flc,flf} $out/share/figlet/
  '';
})
