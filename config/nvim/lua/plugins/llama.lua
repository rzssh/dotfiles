return {
  "ggml-org/llama.vim",
  event = "InsertEnter",
  keys = {
    {
      "<leader>ua",
      function()
        local enabled = vim.fn.exists("#llama#InsertLeavePre") == 1
        vim.cmd(enabled and "LlamaDisable" or "LlamaEnable")
        vim.notify("AI completion " .. (enabled and "disabled" or "enabled"))
      end,
      desc = "Toggle AI completion",
    },
  },
  init = function()
    vim.g.llama_config = {
      endpoint_fim = "http://127.0.0.1:8012/infill",
      keymap_fim_accept_word = "",
      keymap_fim_trigger = "",
      show_info = 0,
    }
  end,
}
