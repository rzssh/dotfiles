return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "helix",
    filter = function(mapping)
      local lhs = mapping.lhs or ""
      local prefer_arrows = vim.g.whichkey_prefer_arrows
      if prefer_arrows == nil then
        prefer_arrows = vim.fn.has("linux") == 1
      end
      if prefer_arrows then
        return not (lhs:match("[hjklHJKL]$") or lhs:match("<C%-[hjklHJKL]>$"))
      else
        return not (lhs:find("<.*Left>") or lhs:find("<.*Right>") or lhs:find("<.*Up>") or lhs:find("<.*Down>"))
      end
    end,
    icons = {
      rules = {
        { pattern = "window", icon = " ", color = "blue" },
        { pattern = "grep", icon = "", color = "red" },
        { pattern = "find", icon = "", color = "blue" },
        { pattern = "flash", icon = "⚡" },
        { pattern = "tasks", icon = "", color = "orange" },
      },
    },
    spec = {
      { "<leader>c", group = "LSP/Format", icon = { icon = "", color = "blue" } },
      { "<leader>e", group = "Explorers", icon = { icon = "", color = "blue" } },
      { "<leader>f", group = "Files", icon = { icon = "󰈔", color = "blue" } },
      { "<leader>g", group = "Git", icon = { icon = "󰊢", color = "orange" } },
      { "<leader>p", group = "Pick/Put", icon = { icon = "󰒉", color = "orange" } },
      { "<leader>u", group = "Undotree/Toggles", icon = { icon = "←", color = "red" } },
      { "<leader>w", group = "Splits", icon = { icon = "", color = "blue" } },
      { "<leader>y", group = "Path", icon = { icon = "", color = "yellow" } },
    },
  },
}
