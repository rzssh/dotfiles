{
  fetchFromGitHub,
  wl-kbptr,
}:

wl-kbptr.overrideAttrs (old: {
  version = "0.4.1-pr96-multiclick";

  src = fetchFromGitHub {
    owner = "kristijanribaric";
    repo = "wl-kbptr";
    rev = "c24236cd82cd446aa9f2a509e080d1ef5bff4c48";
    hash = "sha256-2H1hBa3ryLNGxZHBtscASCOgn25WVORF0uglFey6QiY=";
  };

  patches = (old.patches or [ ]) ++ [ ./multi-click.patch ];

  doCheck = true;
})
