local util = require("lsp_utils")
local lsp = vim.lsp
local map = vim.keymap.set
local autocmd = vim.api.nvim_create_autocmd

local diagnostic_err_alerted = false

return {
  on_attach = function(client, bufnr)
    util.on_attach(client, bufnr)

    vim.api.nvim_buf_create_user_command(bufnr, "LspEslintFixAll", function()
      client:request_sync("workspace/executeCommand", {
        command = "eslint.applyAllFixes",
        arguments = {
          {
            uri = vim.uri_from_bufnr(bufnr),
            version = lsp.util.buf_versions[bufnr],
          },
        },
      }, nil, bufnr)
    end, {})

    autocmd("BufWritePre", {
      buffer = bufnr,
      callback = function()
        if not vim.g.disable_autoformat then
          vim.cmd("LspEslintFixAll")
        end
      end,
    })

    map("n", "<leader>cl", vim.cmd.LspEslintFixAll, {
      desc = "Fix all ESLint issues",
      buffer = bufnr,
    })
  end,
  handlers = {
    ["textDocument/diagnostic"] = function(...)
      local data, _, evt, _ = ...

      if data and data.code and data.code < 0 then
        if not diagnostic_err_alerted then
          vim.notify(
            string.format("ESLint failed due to an error: \n%s", data.message),
            vim.log.levels.WARN,
            { title = "ESLint" }
          )
          diagnostic_err_alerted = true
        end

        return
      end

      return vim.lsp.diagnostic.on_diagnostic(...)
    end,
  },
}
