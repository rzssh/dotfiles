{
  lib,
  buildNpmPackage,
  fetchurl,
  makeWrapper,
  nodejs,
}:

buildNpmPackage rec {
  pname = "agentmemory";
  version = "0.9.27";

  src = fetchurl {
    url = "https://registry.npmjs.org/@agentmemory/agentmemory/-/agentmemory-${version}.tgz";
    hash = "sha256-m5pgNaGo6+MEuvkrscWOIzfyRl147mO+vDZHU8D7KiU=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-fPM3fELWpygu2rQtyQ4gHcddVnkyhmRI4FuL36c/9ts=";

  dontNpmBuild = true;
  npmInstallFlags = [ "--ignore-scripts" ];
  npmRebuildFlags = [ "--ignore-scripts" ];

  postInstall = ''
    makeWrapper ${nodejs}/bin/node $out/bin/agentmemory-mcp \
      --add-flags "$out/lib/node_modules/@agentmemory/agentmemory/dist/standalone.mjs"
  '';

  nativeBuildInputs = [ makeWrapper ];

  meta = {
    description = "Persistent memory server and MCP shim for AI coding agents";
    homepage = "https://github.com/rohitg00/agentmemory";
    license = lib.licenses.asl20;
    mainProgram = "agentmemory";
  };
}
