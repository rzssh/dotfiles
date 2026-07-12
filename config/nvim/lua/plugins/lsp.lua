local servers = {
  "vtsls",
  -- "ts_ls",
  -- "tsgo",
  "biome",
  "eslint",
  "tailwindcss",
  "prismals",
  "graphql",
  "astro",
  "svelte",

  "html",
  "cssls",

  "marksman",
  "jsonls",
  "yamlls",
  "fish_lsp",
  "hyprls",

  "pyright",

  "lua_ls",
  "nixd",

  "typos_lsp",
  "tinymist",

  "zls",
  "gopls",
  "bashls",
  "clangd",
}

return {
  {
    "neovim/nvim-lspconfig",
    event = "VeryLazy",
    dependencies = { "b0o/schemastore.nvim" },
    config = function()
      for _, name in ipairs(servers) do
        local cfg = vim.lsp.config[name]
        local cmd = cfg and cfg.cmd
        if type(cmd) == "function" or (type(cmd) == "table" and vim.fn.executable(cmd[1]) == 1) then
          vim.lsp.enable(name)
        end
      end
    end,
  },

  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        { path = "snacks.nvim", words = { "Snacks" } },
        { path = "mini.nvim", words = { "Mini" } },
        { path = "oklch-color-picker.nvim", words = { "oklch" } },
        { path = "wezterm-types", mods = { "wezterm" } },
        { path = "yazi.nvim", words = { "YaziConfig" } },
      },
    },
  },

  {
    "smjonas/inc-rename.nvim",
    cmd = "IncRename",
    opts = {},
  },
}
