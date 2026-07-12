{ pkgs, ... }:

let
  ts = pkgs.vimPlugins.nvim-treesitter;
  ghosttyGrammar = pkgs.tree-sitter.buildGrammar {
    language = "ghostty";
    version = "0-unstable-2026";
    src = pkgs.fetchFromGitHub {
      owner = "bezhermoso";
      repo = "tree-sitter-ghostty";
      rev = "1f47dfd4da0faab5321b47518ce2faa4be163580";
      hash = "sha256-tpTm4e3f+hjy9Mi91fSm1qojJLB6A8KsN/iEsiOdxsw=";
    };
  };
  ghosttyParser = pkgs.runCommandLocal "ghostty-parser" { } ''
    mkdir -p $out/parser
    cp ${ghosttyGrammar}/parser $out/parser/ghostty.so
  '';
  tsParsers = pkgs.symlinkJoin {
    name = "nvim-ts-parsers";
    paths = (with ts.grammarPlugins; [
      bash c cmake cpp css dockerfile fish gitignore go graphql haskell
      html javascript jsdoc json kdl lua markdown markdown_inline prisma
      query rust supercollider svelte tmux tsx typescript vim yaml zig
    ]) ++ [ ghosttyParser ];
  };
  tsQueries = pkgs.symlinkJoin {
    name = "nvim-ts-queries";
    paths = [ "${ts}/runtime/queries" "${ghosttyGrammar}/queries" ];
  };
in
{
  xdg.dataFile."nvim/site/parser".source = "${tsParsers}/parser";
  xdg.dataFile."nvim/site/queries".source = "${tsQueries}";
}
