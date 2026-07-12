return {
  "nvimtools/hydra.nvim",
  event = "VeryLazy",
  keys = {
    { "<leader>wr", desc = "Resize" },
  },
  config = function()
    require("hydra")({
      name = "Resize",
      mode = "n",
      body = "<leader>wr",
      config = {
        invoke_on_body = true,
        hint = { type = "statusline" },
      },
      heads = {
        { "<Left>", "5<C-w><" },
        { "<Right>", "5<C-w>>" },
        { "<Down>", "5<C-w>-" },
        { "<Up>", "5<C-w>+" },
        -- { "h", "5<C-w><" },
        -- { "l", "5<C-w>>" },
        -- { "j", "5<C-w>-" },
        -- { "k", "5<C-w>+" },
        { "=", "<C-w>=", { desc = "equal" } },
        { "q", nil, { exit = true } },
      },
    })
  end,
}
