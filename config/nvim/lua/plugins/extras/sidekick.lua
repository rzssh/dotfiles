return {
  "folke/sidekick.nvim",
  dependencies = { "folke/snacks.nvim" },
  event = "VeryLazy",
  opts = {
    nes = { enabled = false },
    signs = { enabled = false },
    copilot = { status = { enabled = false } },
    cli = {
      picker = "snacks",
      mux = {
        backend = "tmux",
        enabled = true,
        create = "split",
      },
      prompts = {
        refactor = "Refactor {this} to be more idiomatic and clean",
        types = "Add type annotations to {this}",
      },
    },
  },
    -- stylua: ignore start
    keys = {
      { "<leader>Ac", function() require("sidekick.cli").toggle({ name = "claude", focus = true }) end, desc = "Claude" },
      { "<leader>Ao", function() require("sidekick.cli").toggle({ name = "opencode", focus = true }) end, desc = "OpenCode" },
      { "<leader>Av", function() require("sidekick.cli").send({ type = "visual" }) end, mode = "v", desc = "Send selection" },
      { "<leader>Af", function() require("sidekick.cli").send({ type = "file" }) end, desc = "Send file" },
      { "<leader>Ae", function() require("sidekick.cli").send({ prompt = "explain" }) end, mode = "v", desc = "Explain" },
      { "<leader>Ax", function() require("sidekick.cli").send({ prompt = "fix" }) end, mode = "v", desc = "Fix" },
      { "<leader>Ar", function() require("sidekick.cli").send({ prompt = "review" }) end, desc = "Review file" },
      { "<leader>At", function() require("sidekick.cli").send({ prompt = "tests" }) end, mode = "v", desc = "Write tests" },
      { "<leader>AD", function() require("sidekick.cli").send({ prompt = "diagnostics" }) end, desc = "Fix diagnostics" },
      { "<leader>Ap", function() require("sidekick.cli").prompts() end, desc = "Prompts" },
      { "<leader>As", function() require("sidekick.cli").select() end, desc = "Select tool" },
      { "<leader>Ad", function() require("sidekick.cli").detach() end, desc = "Detach" },
    },
  -- stylua: ignore end
  init = function()
    require("which-key").add({
      { "<leader>A", group = "Sidekick", icon = { icon = "", color = "cyan" } },
    })
  end,
}
