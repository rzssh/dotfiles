return {
  "nvimtools/hydra.nvim",
  dependencies = { "herdr.nvim" },
  event = "VeryLazy",
  keys = {
    { "<leader>wr", desc = "Resize" },
  },
  config = function()
    local splits = require("herdr")
    require("hydra")({
      name = "Resize",
      mode = "n",
      body = "<leader>wr",
      config = {
        invoke_on_body = true,
        hint = { type = "statusline" },
      },
      heads = {
        { "<Left>", splits.resize_left },
        { "<Right>", splits.resize_right },
        { "<Down>", splits.resize_down },
        { "<Up>", splits.resize_up },
        { "=", "<C-w>=", { desc = "equal" } },
        { "q", nil, { exit = true } },
      },
    })
  end,
}
