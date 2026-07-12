local map = vim.keymap.set
local M = {}
local iswin = vim.uv.os_uname().version:match("Windows")

M.on_attach = function(_, bufnr)
  local opts = function(desc)
    return { desc = desc, noremap = true, silent = true, buffer = bufnr }
  end

  local tiny_code_action_ok, tiny_code_action = pcall(require, "tiny-code-action")
  if tiny_code_action_ok then
    map(
      { "n", "v" },
      "<leader>ca",
      tiny_code_action.code_action,
      opts("See available code actions")
    )
  else
    map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts("See available code actions"))
  end

  if pcall(require, "inc_rename") then
    map("n", "<leader>cn", function()
      return ":IncRename " .. vim.fn.expand("<cword>")
    end, vim.tbl_extend("force", opts("Smart rename"), { expr = true }))
  else
    map("n", "<leader>cn", vim.lsp.buf.rename, opts("Smart rename"))
  end
  map("n", "<leader>cd", function()
    vim.diagnostic.open_float()
    vim.diagnostic.open_float()
  end, opts("Go inside diagnostic window"))
  map({ "n", "v" }, "<leader>cq", function()
    vim.diagnostic.setqflist()
  end, opts("Populate qflist with diagnostics"))
end

M.lsp_action = setmetatable({}, {
  __index = function(_, action)
    return function()
      vim.lsp.buf.code_action({
        apply = true,
        context = {
          only = { action },
          diagnostics = {},
        },
      })
    end
  end,
})

function M.apply_action_sync(client, bufnr, action_name, timeout_ms)
  timeout_ms = timeout_ms or 3000
  local params = {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
    range = {
      start = { line = 0, character = 0 },
      ["end"] = { line = vim.api.nvim_buf_line_count(bufnr), character = 0 },
    },
    context = {
      only = { action_name },
      diagnostics = {},
    },
  }

  local results = vim.lsp.buf_request_sync(bufnr, "textDocument/codeAction", params, timeout_ms)
  if not results then
    return
  end

  for _, res in pairs(results) do
    for _, action in pairs(res.result or {}) do
      if action.edit then
        vim.lsp.util.apply_workspace_edit(action.edit, "utf-16")
      end
      if action.command then
        client:request_sync("workspace/executeCommand", action.command, timeout_ms, bufnr)
      end
    end
  end
end

function M.execute_command(opts)
  local params = {
    command = opts.command,
    arguments = opts.arguments,
  }

  local trouble_ok, _ = pcall(require, "trouble")

  if opts.open and trouble_ok then
    return require("trouble").open({ mode = "lsp_command", params = params })
  end

  return vim.lsp.buf_request(0, "workspace/executeCommand", params, opts.handler)
end

M.execute_system_cmd_and_sync_buf = function(cmd)
  vim.system(cmd, { detach = true }, function(obj)
    vim.notify(obj.stdout, vim.log.levels.INFO)
    vim.schedule(function()
      -- vim.cmd("silent! checktime")
      vim.cmd("silent! e!")
    end)
  end)
end

-- NOTE: Below are functions that I need in my lsp setup copied from `lspconfig.util`
-- https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/util.lua

function M.insert_package_json(config_files, field, fname)
  local path = vim.fn.fnamemodify(fname, ":h")
  local root_with_package =
    vim.fs.dirname(vim.fs.find("package.json", { path = path, upward = true })[1])

  if root_with_package then
    -- only add package.json if it contains field parameter
    local path_sep = iswin and "\\" or "/"
    for line in io.lines(root_with_package .. path_sep .. "package.json") do
      if line:find(field) then
        config_files[#config_files + 1] = "package.json"
        break
      end
    end
  end
  return config_files
end

return M
