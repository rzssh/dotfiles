local api, fs, uv = vim.api, vim.fs, vim.uv
local state = { pinned = false, version = 0, win = nil }

local function project_root()
  local cwd = uv.cwd()
  return fs.root(cwd, ".git") or cwd
end

local function canonical(path)
  if not vim.startswith(path, "/") then
    path = project_root() .. "/" .. path
  end
  return uv.fs_realpath(path) or fs.normalize(path)
end

local function list()
  return require("harpoon"):list()
end

local function current_index(items)
  local current = api.nvim_buf_get_name(0)
  if current == "" then
    return
  end

  current = canonical(current)
  for index = 1, items:length() do
    local item = items:get(index)
    if item and canonical(item.value) == current then
      return index
    end
  end
end

local function close()
  if state.win and api.nvim_win_is_valid(state.win) then
    api.nvim_win_close(state.win, true)
  end
  state.win = nil
end

local function render()
  state.version = state.version + 1
  close()

  local items = list()
  local selected = current_index(items)
  local lines = {}
  local selected_line

  for index = 1, items:length() do
    local item = items:get(index)
    if item then
      lines[#lines + 1] = string.format("[%d] %s", index, fs.basename(item.value))
      selected_line = index == selected and #lines or selected_line
    end
  end

  if #lines == 0 then
    return
  end

  local width = 1
  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line))
  end

  local buf = api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  state.win = api.nvim_open_win(buf, false, {
    relative = "editor",
    anchor = "NE",
    col = vim.o.columns - 1,
    row = 1,
    width = math.min(width + 2, math.max(1, vim.o.columns - 2)),
    height = math.min(#lines, math.max(1, vim.o.lines - 3)),
    focusable = false,
    style = "minimal",
  })

  for line = 1, #lines do
    local highlight = line == selected_line and "HarpoonSelectedOptionHL" or "HarpoonOptionHL"
    api.nvim_buf_add_highlight(buf, -1, highlight, line - 1, 0, -1)
  end
end

local function show()
  render()
  local version = state.version
  if not state.pinned then
    vim.defer_fn(function()
      if version == state.version and not state.pinned then
        close()
      end
    end, 1200)
  end
end

local function toggle()
  state.pinned = not state.pinned
  if state.pinned then
    render()
  else
    show()
  end
end

local function menu()
  local harpoon = require("harpoon")
  harpoon.ui:toggle_quick_menu(harpoon:list())
end

local function select_slot(index)
  return function()
    list():select(index)
  end
end

local keys = {
  {
    "<leader>a",
    function()
      local items = list()
      if current_index(items) then
        items:remove()
      else
        items:add()
      end
    end,
    desc = "Harpoon: Toggle file",
  },
  { "<leader>h", menu, desc = "Harpoon: Menu" },
  { "<leader>uh", toggle, desc = "Harpoon: Pin list" },
}

for index = 1, 9 do
  keys[#keys + 1] = {
    "<C-" .. index .. ">",
    select_slot(index),
    desc = "Harpoon: Go to " .. index,
  }
end

return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  event = "VeryLazy",
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = keys,
  config = function()
    local harpoon = require("harpoon")
    harpoon:setup({
      settings = { key = project_root },
      default = { get_root_dir = project_root },
    })

    local extensions = require("harpoon.extensions").builtins
    harpoon:extend(extensions.highlight_current_file())
    harpoon:extend(extensions.navigate_with_number())
    harpoon:extend(extensions.command_on_nav("normal! zz"))
    harpoon:extend({ ADD = show, REMOVE = show, LIST_CHANGE = show })

    local function show_current()
      vim.schedule(function()
        if current_index(harpoon:list()) then
          show()
        end
      end)
    end

    api.nvim_create_autocmd("BufEnter", {
      group = api.nvim_create_augroup("HarpoonGlimmer", { clear = true }),
      callback = show_current,
    })
    show_current()
  end,
}
