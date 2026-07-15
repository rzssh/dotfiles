return {
  "r4zendev/herdr.nvim",
  event = "VeryLazy",
  opts = {
    agent_workspace_only = true,
  },
  keys = {
    {
      "<leader>Hs",
      function()
        require("herdr.agent").append(require("herdr.context").selection())
      end,
      mode = "x",
      desc = "Append selection",
    },
    {
      "<leader>Hs",
      function()
        return require("herdr.agent").operator()
      end,
      mode = "n",
      expr = true,
      desc = "Append motion",
    },
    {
      "<leader>Hf",
      function()
        require("herdr.agent").append(require("herdr.context").file())
      end,
      desc = "Append file",
    },
    {
      "<leader>HD",
      function()
        require("herdr.agent").append(require("herdr.context").diagnostics())
      end,
      desc = "Append diagnostics",
    },
    {
      "<leader>Hq",
      function()
        require("herdr.agent").append(require("herdr.context").quickfix())
      end,
      desc = "Append quickfix",
    },
    {
      "<leader>Ha",
      function()
        require("herdr.agent").focus()
      end,
      desc = "Focus agent",
    },
    {
      "<leader>Hp",
      function()
        require("herdr.agent").select()
      end,
      desc = "Select agent",
    },
  },
}
