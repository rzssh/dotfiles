{
  wl-kbptr,
  src,
}:

wl-kbptr.overrideAttrs (old: {
  version = "0.4.1-unstable-${src.shortRev}";
  inherit src;

  patches = (old.patches or [ ]) ++ [
    ./multi-click.patch
    ./fit-labels.patch
  ];

  doCheck = true;
})
