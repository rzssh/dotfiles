return {
  {
    "folke/ts-comments.nvim",
    version = "*",
    ft = { "html", "typescript", "typescriptreact", "javascript", "javascriptreact" },
    opts = {},
  },
  {
    "windwp/nvim-ts-autotag",
    event = "LazyFile",
    opts = {
      opts = {
        enable_close_on_slash = true,
      },
    },
  },
  {
    "andymass/vim-matchup",
    event = "LazyFile",
    init = function()
      vim.g.loaded_matchparen = 1
      vim.g.matchup_matchparen_enabled = 1

      vim.g.matchup_motion_enabled = 1
      vim.g.matchup_text_obj_enabled = 0
      vim.g.matchup_surround_enabled = 1

      -- This is the only way to make matchparen work but fallback to default nvim hl
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "*",
        callback = function()
          local enabled = { "rust", "zig" }
          vim.b.matchup_matchparen_enabled = vim.tbl_contains(enabled, vim.bo.filetype)
        end,
      })
    end,
  },
  {
    "windwp/nvim-autopairs",
    event = { "InsertEnter" },
    opts = {
      map_cr = true,
      check_ts = true,
      ts_config = {
        lua = { "string" }, -- avoid pairs in lua strings
        javascript = { "template_string" }, -- don't add pairs in js template_strings
      },
    },
    config = function(_, opts)
      local Rule = require("nvim-autopairs.rule")
      local npairs = require("nvim-autopairs")
      npairs.setup(opts)

      npairs.add_rule(Rule("|", "|", { "zig", "rust" }))
    end,
  },
}
