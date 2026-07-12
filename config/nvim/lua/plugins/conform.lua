local util = require("lsp_utils")

return {
  "stevearc/conform.nvim",
  event = "LazyFile",
  opts = {
    formatters = {
      prettierd = {
        condition = function()
          local fname = vim.api.nvim_buf_get_name(0)

          if vim.bo.filetype == "markdown" then
            return true
          end

          local prettier_root_file = {
            -- https://prettier.io/docs/en/configuration.html
            ".prettierrc",
            ".prettierrc.json",
            ".prettierrc.yml",
            ".prettierrc.yaml",
            ".prettierrc.json5",
            ".prettierrc.js",
            ".prettierrc.cjs",
            ".prettierrc.mjs",
            ".prettierrc.toml",
            "prettier.config.js",
            "prettier.config.cjs",
            "prettier.config.mjs",
          }

          prettier_root_file = util.insert_package_json(prettier_root_file, "prettier", fname)
          return vim.fs.find(prettier_root_file, { path = vim.fs.dirname(fname), upward = true })[1] ~= nil
        end,
      },
    },
    formatters_by_ft = {
      javascript = { "prettierd" },
      typescript = { "prettierd" },
      javascriptreact = { "prettierd" },
      typescriptreact = { "prettierd" },
      svelte = { "prettierd" },
      css = { "prettierd" },
      html = { "prettierd" },
      json = { "prettierd" },
      yaml = { "prettierd" },
      graphql = { "prettierd" },
      markdown = { "prettierd" },
      lua = { "stylua" },
      -- python = { "isort", "black" },
      c = { "clang_format" },
      cpp = { "clang_format" },
      go = { "gofmt" },
      rust = { "rustfmt" },
      zig = { "zigfmt" },
    },

    format_on_save = function(bufnr)
      -- Disable with a global or buffer-local variable
      if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
        return
      end

      -- {lsp_format}       `nil|conform.LspFormatOpts`    Defaults to "never".
      --     `"never"`    never use the LSP for formatting (default)
      --     `"fallback"` LSP formatting is used when no other formatters are available
      --     `"prefer"`   use only LSP formatting when available
      --     `"first"`    LSP formatting is used when available and then other formatters
      --     `"last"`     other formatters are used then LSP formatting when available
      -- {stop_after_first} `nil|boolean` Only run the first available formatter in the list. Defaults to false.
      -- {filter}           `nil|fun(client: table): boolean` Passed to |vim.lsp.buf.format| when using LSP formatting
      return {
        timeout_ms = 1500,
        lsp_format = "fallback",
        filter = function(client)
          -- Disable native vtsls formatter
          return client.name ~= "vtsls"
        end,
      }
    end,
  },
  keys = {
    {
      "<leader>cf",
      function()
        require("conform").format({
          lsp_fallback = true,
          async = false,
          timeout_ms = 1000,
        })
      end,
      mode = { "n", "v" },
      desc = "Format file or range (in visual mode)",
    },
    {
      "<leader>ct",
      function()
        if vim.g.disable_autoformat or vim.b.disable_autoformat then
          vim.cmd("FormatEnable")
          vim.notify("Autoformat enabled", vim.log.levels.INFO, { title = "Conform" })
        else
          vim.cmd("FormatDisable")
          vim.notify("Autoformat disabled", vim.log.levels.INFO, { title = "Conform" })
        end
      end,
      mode = { "n", "v" },
      desc = "Toggle formatting",
    },
  },
  init = function()
    vim.api.nvim_create_user_command("FormatDisable", function(args)
      if args.bang then
        -- FormatDisable! will disable formatting just for this buffer
        vim.b.disable_autoformat = true
      else
        vim.g.disable_autoformat = true
      end
    end, { desc = "Disable autoformat-on-save", bang = true })

    vim.api.nvim_create_user_command("FormatEnable", function()
      vim.b.disable_autoformat = false
      vim.g.disable_autoformat = false
    end, { desc = "Re-enable autoformat-on-save" })
  end,
}
