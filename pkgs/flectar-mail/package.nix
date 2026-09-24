{
  lib,
  appimageTools,
  fetchurl,
}:

let
  pname = "flectar-mail";
  version = "0.1.0-alpha.6";

  src = fetchurl {
    url = "https://github.com/flectar/mail/releases/download/v${version}/flectar-mail-${version}-linux-x64.AppImage";
    hash = "sha256-t/DwKHPA6Frzgi5N6XA3J6GvACEOUCca5Nz9Vn5d5mM=";
  };

  appimageContents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -Dm444 ${appimageContents}/com.flectar.mail.desktop \
      $out/share/applications/com.flectar.mail.desktop
    cp -r ${appimageContents}/usr/share/icons $out/share
    install -Dm444 ${appimageContents}/usr/share/metainfo/com.flectar.mail.metainfo.xml \
      $out/share/metainfo/com.flectar.mail.metainfo.xml
  '';

  meta = {
    description = "Lightweight native email, calendar, and contacts client";
    homepage = "https://flectar.com/mail/";
    license = lib.licenses.agpl3Only;
    mainProgram = "flectar-mail";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
