local function annotate(line)
  local path = vim.api.nvim_buf_get_name(0)
  if path ~= "" and vim.fs.root(path, ".jj") then
    vim.cmd("J " .. (line and "annotate_line" or "annotate"))
  else
    vim.cmd("BlameToggle " .. (line and "virtual" or "window"))
  end
end

return {
  {
    "FabijanZulj/blame.nvim",
    cmd = "BlameToggle",
    opts = {},
    init = function()
      vim.keymap.set("n", "<leader>gB", function()
        annotate(false)
      end, { desc = "File attribution" })
      vim.keymap.set("n", "<leader>ub", function()
        annotate(true)
      end, { desc = "Line attribution" })
    end,
  },

  {
    "NicolasGB/jj.nvim",
    version = "*",
    cmd = "J",
    keys = {
      { "<leader>jl", "<cmd>J log<cr>", desc = "JJ: Log" },
      { "<leader>js", "<cmd>J status<cr>", desc = "JJ: Status" },
    },
    opts = {
      diff = { backend = "codediff" },
    },
  },

  {
    "julienvincent/hunk.nvim",
    cmd = "DiffEditor",
    dependencies = { "MunifTanjim/nui.nvim" },
    opts = {},
  },

  {
    "rafikdraoui/jj-diffconflicts",
    cmd = "JJDiffConflicts",
  },

  {
    "pwntester/octo.nvim",
    cmd = "Octo",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      picker = "snacks",
      use_local_fs = false,
      enable_builtin = true,
    },
    keys = {
      { "<leader>Op", "<cmd>Octo pr list<cr>", desc = "Octo: PR list" },
      { "<leader>Oi", "<cmd>Octo issue list<cr>", desc = "Octo: issue list" },
      { "<leader>Or", "<cmd>Octo review start<cr>", desc = "Octo: start review" },
    },
    init = function()
      require("which-key").add({
        { "<leader>O", group = "GitHub (Octo)" },
      })
    end,
  },

  {
    "esmuellert/codediff.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    cmd = "CodeDiff",
    keys = {
      { "<leader>gd", "<cmd>CodeDiff<cr>", desc = "Git changes" },
      { "<leader>gh", "<cmd>CodeDiff history %<cr>", desc = "File history" },
      { "<leader>gH", "<cmd>CodeDiff history<cr>", desc = "Repository history" },
      {
        "<leader>gh",
        function()
          vim.cmd("'<,'>CodeDiff history")
        end,
        mode = "x",
        desc = "Selection history",
      },
    },
  },
}
