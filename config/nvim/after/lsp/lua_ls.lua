return {
  settings = {
    Lua = {
      diagnostics = { disable = { "missing-fields" } },
    },
  },
  on_attach = require("lsp_utils").on_attach,
}
