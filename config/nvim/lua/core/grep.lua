vim.opt.grepprg = "rg --hidden --vimgrep --smart-case"
vim.opt.grepformat = "%f:%l:%c:%m"

vim.api.nvim_create_user_command("Grep", function(opts)
  if opts.args == "" then
    vim.notify("Grep: missing pattern", vim.log.levels.WARN)
    return
  end

  local root = vim.fs.root(0, { ".git" }) or vim.uv.cwd()

  vim.fn.setqflist({})
  local cmd = string.format(
    "cd %s && %s -- %s",
    vim.fn.shellescape(root),
    vim.o.grepprg,
    vim.fn.shellescape(opts.args)
  )
  local output = vim.fn.system(cmd)

  vim.fn.setqflist({}, "a", {
    lines = vim.split(output, "\n", { trimempty = true }),
    efm = vim.o.grepformat,
  })

  if vim.fn.getqflist({ size = 0 }).size > 0 then
    vim.cmd("copen")
  else
    vim.notify("Grep: no matches", vim.log.levels.INFO)
  end
end, { nargs = "+", desc = "ripgrep from workspace root" })

vim.keymap.set("n", "<leader>G", function()
  vim.ui.input({ prompt = "Grep pattern: " }, function(input)
    if input and input ~= "" then
      vim.cmd("Grep " .. input)
    end
  end)
end, { desc = "Grep with input" })

vim.keymap.set("x", "<leader>G", function()
  vim.cmd('noautocmd normal! "vy')
  local text = vim.fn.getreg("v")

  text = text:gsub("%s+", " "):match("^%s*(.-)%s*$")
  if text == "" then
    return
  end

  vim.cmd("Grep " .. text)
end, { desc = "Grep selection" })
