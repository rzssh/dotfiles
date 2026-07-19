{
  fetchFromGitHub,
  figlet,
}:

let
  fonts = fetchFromGitHub {
    owner = "xero";
    repo = "figlet-fonts";
    rev = "417429ef36ab039cbf192a4424c60aa23fc32de8";
    hash = "sha256-QogGNQ772bcYLOzgO0i6ydbzxjn5jnXNav72vW/SXm8=";
  };
in
figlet.overrideAttrs (old: {
  postInstall = ''
    ${old.postInstall or ""}
    cp --remove-destination ${fonts}/*.{flc,flf} $out/share/figlet/
  '';
})
