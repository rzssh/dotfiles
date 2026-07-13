{ pkgs, ... }:
let
  ruTranslit = pkgs.symlinkJoin {
    name = "ibus-engine-m17n-ru";
    paths = [ pkgs.ibus-engines.m17n pkgs.m17n_db ];
    meta.isIbusEngine = true;
  };
in
{
  i18n.inputMethod = {
    enable = true;
    type = "ibus";
    ibus.engines = [ ruTranslit ];
    ibus.waylandFrontend = true;
  };
}
