local api = vim.api

local M = {}
local state = { win = nil, group = nil, buffers = {} }

local function note_path(file)
  return M.dir .. "/" .. file
end

local function float_config(file)
  local width = math.min(math.floor(vim.o.columns * 0.8), 100)
  local height = math.min(math.floor(vim.o.lines * 0.8), math.max(vim.o.lines - 4, 1))

  return {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = 2,
    border = "single",
    title = " " .. vim.fn.fnamemodify(file, ":t") .. " ",
  }
end

function M.close()
  for buf in pairs(state.buffers) do
    if api.nvim_buf_is_valid(buf) and vim.bo[buf].modified then
      api.nvim_buf_call(buf, function()
        vim.cmd.write()
      end)
    end
  end

  if state.win and api.nvim_win_is_valid(state.win) then
    api.nvim_win_close(state.win, true)
  end

  if state.group then
    pcall(api.nvim_del_augroup_by_id, state.group)
  end

  state.win = nil
  state.group = nil
  state.buffers = {}
end

local function bind_close(buf)
  vim.keymap.set("n", "q", M.close, { buffer = buf, silent = true, desc = "Close Note" })
end

function M.open_float(file)
  M.close()

  local path = note_path(file)
  local buf = vim.fn.bufadd(path)
  vim.fn.bufload(buf)
  vim.bo[buf].buflisted = false

  state.win = api.nvim_open_win(buf, true, float_config(file))
  state.group = api.nvim_create_augroup("NotesFloat", { clear = true })
  state.buffers[buf] = true
  bind_close(buf)

  api.nvim_create_autocmd("BufEnter", {
    group = state.group,
    callback = function()
      if api.nvim_get_current_win() == state.win then
        local current = api.nvim_get_current_buf()
        state.buffers[current] = true
        bind_close(current)
      end
    end,
  })

  api.nvim_create_autocmd("WinClosed", {
    group = state.group,
    pattern = tostring(state.win),
    callback = M.close,
    once = true,
  })

  api.nvim_create_autocmd("VimResized", {
    group = state.group,
    callback = function()
      if state.win and api.nvim_win_is_valid(state.win) then
        api.nvim_win_set_config(state.win, float_config(file))
      end
    end,
  })
end

function M.toggle_float(file)
  if state.win and api.nvim_win_is_valid(state.win) then
    M.close()
    return
  end

  M.open_float(file or M.float_file)
end

function M.edit(file)
  vim.cmd.edit(vim.fn.fnameescape(note_path(file)))
end

function M.find()
  Snacks.picker.files({ cwd = M.dir })
end

function M.grep()
  Snacks.picker.grep({ cwd = M.dir })
end

function M.setup(opts)
  opts = opts or {}
  M.dir = vim.fn.expand(opts.dir or "~/notes")
  M.float_file = opts.float_file or "inbox.md"

  api.nvim_create_user_command("NotesInbox", function()
    M.toggle_float("inbox.md")
  end, {})

  vim.keymap.set("n", "<leader>ni", function()
    M.toggle_float()
  end, { desc = "Toggle Inbox", silent = true })
  vim.keymap.set("n", "<leader>nn", function()
    M.edit("index.md")
  end, { desc = "Notes Index", silent = true })
  vim.keymap.set("n", "<leader>nt", function()
    M.edit("todo.md")
  end, { desc = "Notes Todo", silent = true })
  vim.keymap.set("n", "<leader>nf", M.find, { desc = "Find Notes", silent = true })
  vim.keymap.set("n", "<leader>ng", M.grep, { desc = "Search Notes", silent = true })
end

return M
