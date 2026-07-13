return {
  dir = "/home/razen/projects/herdr-splits.nvim",
  name = "herdr-splits.nvim",
  opts = {},
  keys = {
    {
      "<M-Left>",
      function()
        require("herdr-splits").move_cursor_left()
      end,
      mode = { "n", "i", "x", "t" },
      desc = "Navigate left",
    },
    {
      "<M-Down>",
      function()
        require("herdr-splits").move_cursor_down()
      end,
      mode = { "n", "i", "x", "t" },
      desc = "Navigate down",
    },
    {
      "<M-Up>",
      function()
        require("herdr-splits").move_cursor_up()
      end,
      mode = { "n", "i", "x", "t" },
      desc = "Navigate up",
    },
    {
      "<M-Right>",
      function()
        require("herdr-splits").move_cursor_right()
      end,
      mode = { "n", "i", "x", "t" },
      desc = "Navigate right",
    },
  },
}
