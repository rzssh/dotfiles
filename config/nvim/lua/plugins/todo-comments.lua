return {
  "folke/todo-comments.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  event = "VeryLazy",
  version = "*",
  opts = {
    search = {
      args = {
        "--color=never",
        "--no-heading",
        "--with-filename",
        "--line-number",
        "--column",
        "--hidden",
      },
    },
  },
  keys = {
    { "<leader>sX", vim.cmd.TodoQuickFix, desc = "Todo Quickfix" },
    {
      "<leader>st",
      function()
        Snacks.picker.todo_comments({ hidden = true })
      end,
      desc = "Todo",
    },
    {
      "<leader>sT",
      function()
        Snacks.picker.todo_comments({ keywords = { "TODO", "FIX", "FIXME" }, hidden = true })
      end,
      desc = "Todo/Fix/Fixme",
    },
    {
      "]T",
      function()
        require("todo-comments").jump_next()
      end,
      desc = "Next todo comment",
    },
    {
      "[T",
      function()
        require("todo-comments").jump_prev()
      end,
      desc = "Previous todo comment",
    },
  },
}
