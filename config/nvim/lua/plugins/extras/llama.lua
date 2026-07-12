return {
  "ggml-org/llama.vim",
  event = "InsertEnter",
  cmd = { "LlamaEnable", "LlamaDisable", "LlamaToggle" },
  init = function()
    vim.g.llama_config = {
      endpoint_fim = "http://127.0.0.1:8012/infill",
      auto_fim = true,
      keymap_fim_accept_full = "<Tab>",
      keymap_fim_accept_line = "<S-Tab>",
      keymap_fim_accept_word = "",
      keymap_fim_trigger = "",
      -- keymap_fim_accept_line = "<C-l>",
      -- keymap_fim_accept_word = "<C-w>",
      enable_at_startup = vim.g.llama_enabled == nil or vim.g.llama_enabled,
      show_info = 0,
    }

    vim.api.nvim_set_hl(0, "llama_hl_fim_hint", { link = "Comment" })
  end,
}
