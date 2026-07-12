return {
  "cursortab/cursortab.nvim",
  event = "VeryLazy",
  build = "cd server && go build",
  opts = {
    provider = {
      type = "zeta-2",
      url = "http://127.0.0.1:8000",
      max_tokens = 128,
    },
    keymaps = {
      accept = "<Tab>",
      partial_accept = "<S-Tab>",
    },
  },
}
