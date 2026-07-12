return {
  "mrcjkb/rustaceanvim",
  version = "^6",
  lazy = false,
  keys = {
    { "<leader>rd", "<cmd>RustLsp debuggables<cr>", desc = "Rust debuggables", ft = "rust" },
    { "<leader>rr", "<cmd>RustLsp runnables<cr>", desc = "Rust runnables", ft = "rust" },
    { "<leader>rt", "<cmd>RustLsp testables<cr>", desc = "Rust testables", ft = "rust" },
    { "<leader>re", "<cmd>RustLsp expandMacro<cr>", desc = "Expand macro", ft = "rust" },
    { "<leader>rc", "<cmd>RustLsp openCargo<cr>", desc = "Open Cargo.toml", ft = "rust" },
    { "<leader>rp", "<cmd>RustLsp parentModule<cr>", desc = "Parent module", ft = "rust" },
  },
  init = function()
    vim.g.rustaceanvim = {
      dap = {
        adapter = {
          type = "server",
          port = "${port}",
          executable = {
            command = "codelldb",
            args = { "--port", "${port}" },
          },
        },
      },
    }
  end,
}
