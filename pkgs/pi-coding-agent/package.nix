{
  lib,
  buildNpmPackage,
  fetchurl,
  fd,
  ripgrep,
  runCommand,
}:

let
  version = "0.80.3";
  srcWithLock = runCommand "pi-coding-agent-src-with-lock" { } ''
    mkdir -p $out
    tar -xzf ${
      fetchurl {
        url = "https://registry.npmjs.org/@earendil-works/pi-coding-agent/-/pi-coding-agent-${version}.tgz";
        hash = "sha256-FVxYABNMuN9sR62z6rVkFej6d0bgscumaHE0E3xFHZA=";
      }
    } -C $out --strip-components=1
    rm -f $out/npm-shrinkwrap.json
    cp ${./package-lock.json} $out/package-lock.json
  '';
in
buildNpmPackage {
  pname = "pi-coding-agent";
  inherit version;
  src = srcWithLock;

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-mCu0S8IBNlP1l3EuWRi0StxcmYIBS1SskyYQ41vARgw=";
  makeCacheWritable = true;

  dontNpmBuild = true;

  postInstall = ''
    wrapProgram $out/bin/pi \
      --prefix PATH : ${lib.makeBinPath [ fd ripgrep ]} \
      --set PI_SKIP_VERSION_CHECK 1 \
      --set PI_TELEMETRY 0
  '';

  meta = {
    description = "Minimal terminal coding agent harness";
    homepage = "https://pi.dev";
    license = lib.licenses.mit;
    mainProgram = "pi";
  };
}
