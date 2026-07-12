return {
  {
    "rachartier/tiny-code-action.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "folke/snacks.nvim",
    },
    event = "LspAttach",
    opts = {
      -- "vim", "delta", "difftastic", "diffsofancy"
      backend = "difftastic",
      -- "telescope", "snacks", "select", "buffer", "fzf-lua"
      picker = "snacks",
      resolve_timeout = nil,
      notify = { enabled = true, on_empty = true },
    },
  },

  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "LspAttach",
    opts = {
      preset = "powerline",
      options = {
        use_icons_from_diagnostic = true,
        set_arrow_to_diag_color = true,
        override_open_float = true,

        add_messages = { display_count = true },
        multilines = { enabled = true },

        -- These two seem to be conflicting but somehow enabling both of them results exactly in the view I want
        show_all_diags_on_cursorline = true,
        show_diags_only_under_cursor = true,
      },
    },
  },
}
