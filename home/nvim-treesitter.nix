{ pkgs, ... }:

let
  ts = pkgs.vimPlugins.nvim-treesitter;
  tsParsers = pkgs.symlinkJoin {
    name = "nvim-ts-parsers";
    paths = with ts.grammarPlugins; [
      bash
      c
      cmake
      cpp
      css
      dockerfile
      fish
      gitignore
      go
      graphql
      haskell
      html
      javascript
      jsdoc
      json
      kdl
      lua
      markdown
      markdown_inline
      prisma
      odin
      query
      rust
      supercollider
      svelte
      tsx
      typescript
      vim
      yaml
      zig
    ];
  };
  tsQueries = pkgs.symlinkJoin {
    name = "nvim-ts-queries";
    paths = [ "${ts}/runtime/queries" ];
  };
in
{
  xdg.dataFile."nvim/site/parser".source = "${tsParsers}/parser";
  xdg.dataFile."nvim/site/queries".source = "${tsQueries}";
}
