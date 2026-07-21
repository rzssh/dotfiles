{ pkgs, ... }:

{
  xdg.mimeApps =
    let
      defaults = {
        "application/x-extension-htm" = "zen-beta.desktop";
        "application/x-extension-html" = "zen-beta.desktop";
        "application/x-extension-shtml" = "zen-beta.desktop";
        "application/x-extension-xht" = "zen-beta.desktop";
        "application/x-extension-xhtml" = "zen-beta.desktop";
        "application/xhtml+xml" = "zen-beta.desktop";
        "text/html" = "zen-beta.desktop";
        "x-scheme-handler/chrome" = "zen-beta.desktop";
        "x-scheme-handler/http" = "zen-beta.desktop";
        "x-scheme-handler/https" = "zen-beta.desktop";
        "x-scheme-handler/about" = "zen-beta.desktop";
        "x-scheme-handler/unknown" = "zen-beta.desktop";
        "image/bmp" = "qimgv.desktop";
        "image/gif" = "qimgv.desktop";
        "image/jpeg" = "qimgv.desktop";
        "image/png" = "qimgv.desktop";
        "image/webp" = "qimgv.desktop";
        "image/avif" = "qimgv.desktop";
        "image/svg+xml" = "org.gnome.Loupe.desktop";
        "video/mp4" = "vlc.desktop";
        "video/webm" = "vlc.desktop";
        "video/x-matroska" = "vlc.desktop";
        "video/avi" = "vlc.desktop";
        "video/mkv" = "vlc.desktop";
        "application/pdf" = "org.kde.okular.desktop";
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = "writer.desktop";
        "application/json" = "nvim.desktop";
        "text/plain" = "nvim.desktop";
        "application/zip" = "org.kde.ark.desktop";
        "application/x-tar" = "org.kde.ark.desktop";
        "application/x-compressed-tar" = "org.kde.ark.desktop";
        "application/x-bzip-compressed-tar" = "org.kde.ark.desktop";
        "application/x-xz-compressed-tar" = "org.kde.ark.desktop";
        "application/gzip" = "org.kde.ark.desktop";
        "application/x-gzip" = "org.kde.ark.desktop";
        "application/x-bzip" = "org.kde.ark.desktop";
        "application/x-7z-compressed" = "org.kde.ark.desktop";
        "application/vnd.rar" = "org.kde.ark.desktop";
        "application/x-rar" = "org.kde.ark.desktop";
        "application/x-archive" = "org.kde.ark.desktop";
        "application/x-bittorrent" = "org.qbittorrent.qBittorrent.desktop";
        "x-scheme-handler/magnet" = "org.qbittorrent.qBittorrent.desktop";
        "x-scheme-handler/discord" = "vesktop.desktop";
        "x-scheme-handler/mailto" = "mailspring.desktop";
        "x-scheme-handler/mailspring" = "mailspring.desktop";
        "inode/directory" = "org.kde.dolphin.desktop";
        "x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
      };
    in
    {
      enable = true;
      associations.added = defaults;
      defaultApplications = defaults;
    };

  xdg.desktopEntries.nvim = {
    name = "Neovim";
    exec = "ghostty --class=ghostty.nvim -e nvim %F";
    terminal = false;
    mimeType = [
      "text/plain"
      "text/english"
      "text/x-makefile"
      "text/x-c++src"
      "text/x-csrc"
      "text/x-java"
      "text/x-tex"
      "application/x-shellscript"
      "text/x-c"
      "text/x-c++"
    ];
  };

  xdg.desktopEntries.mailspring = {
    name = "Mailspring";
    genericName = "Email Client";
    exec = "${pkgs.mailspring}/bin/mailspring --password-store=gnome-libsecret %U";
    icon = "mailspring";
    terminal = false;
    categories = [
      "Network"
      "Email"
    ];
    mimeType = [
      "x-scheme-handler/mailto"
      "x-scheme-handler/mailspring"
    ];
  };

  xdg.desktopEntries.Zoom = {
    name = "Zoom Workplace";
    comment = "Zoom Video Conference";
    exec = "env QT_QPA_PLATFORM=wayland ${pkgs.zoom-us}/bin/zoom %U";
    icon = "Zoom";
    terminal = false;
    categories = [ "Network" ];
    mimeType = [
      "x-scheme-handler/zoommtg"
      "x-scheme-handler/zoomus"
      "x-scheme-handler/tel"
      "x-scheme-handler/callto"
      "x-scheme-handler/zoomphonecall"
      "x-scheme-handler/zoomphonesms"
      "x-scheme-handler/zoomcontactcentercall"
      "application/x-zoom"
    ];
    settings = {
      StartupWMClass = "zoom";
      X-KDE-Protocols = "zoommtg;zoomus;tel;callto;zoomphonecall;zoomphonesms;zoomcontactcentercall;";
    };
  };

  xdg.desktopEntries.claude-code-url-handler = {
    name = "Claude Code URL Handler";
    exec = "/home/razen/.local/share/ai/bin/claude --handle-uri %u";
    noDisplay = true;
    mimeType = [ "x-scheme-handler/claude-cli" ];
  };

  xdg.desktopEntries."org.telegram.desktop" = {
    name = "Telegram";
    exec = "Telegram -scale 110 -- %U";
    icon = "org.telegram.desktop";
    terminal = false;
    categories = [
      "Chat"
      "Network"
      "InstantMessaging"
    ];
    mimeType = [
      "x-scheme-handler/tg"
      "x-scheme-handler/tonsite"
    ];
    settings.StartupWMClass = "TelegramDesktop";
  };

  xdg.desktopEntries.BambuStudio = {
    name = "BambuStudio";
    exec = "env GDK_BACKEND=x11 WEBKIT_DISABLE_DMABUF_RENDERER=1 WEBKIT_DISABLE_COMPOSITING_MODE=1 __GLX_VENDOR_LIBRARY_NAME=mesa __EGL_VENDOR_LIBRARY_FILENAMES=/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json MESA_LOADER_DRIVER_OVERRIDE=zink GALLIUM_DRIVER=zink bambu-studio %U";
    icon = "BambuStudio";
    terminal = false;
    categories = [
      "Graphics"
      "3DGraphics"
      "Engineering"
    ];
    mimeType = [
      "model/stl"
      "model/3mf"
      "application/vnd.ms-3mfdocument"
      "application/prs.wavefront-obj"
      "application/x-amf"
      "x-scheme-handler/bambustudio"
    ];
  };

  xdg.desktopEntries."org.freecad.FreeCAD" = {
    name = "FreeCAD";
    exec = "env QT_QPA_PLATFORM=xcb FreeCAD - --single-instance %F";
    icon = "org.freecad.FreeCAD";
    terminal = false;
    categories = [
      "Graphics"
      "Engineering"
    ];
    mimeType = [ "application/x-extension-fcstd" ];
  };

  xdg.desktopEntries."com.github.th_ch.youtube_music" = {
    name = "Pear Desktop";
    exec = "pear-desktop --force-device-scale-factor=1.10 %U";
    icon = "pear-desktop";
    terminal = false;
    categories = [ "AudioVideo" ];
  };
}
