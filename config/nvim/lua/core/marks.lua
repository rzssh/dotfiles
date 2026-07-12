local ns = vim.api.nvim_create_namespace("r4zen/marks")
local map = vim.keymap.set

local USE_UPPERCASE_FOR_LOWERCASE = true

---@param bufnr integer
---@param mark vim.fn.getmarklist.ret.item
local function decor_mark(bufnr, mark)
  pcall(vim.api.nvim_buf_set_extmark, bufnr, ns, mark.pos[2] - 1, 0, {
    sign_text = mark.mark:sub(2),
    sign_hl_group = "DiagnosticSignOk",
  })
end

local function redraw_all_windows()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    vim.api.nvim__redraw({ win = win, range = { 0, -1 } })
  end
end

vim.api.nvim_set_decoration_provider(ns, {
  on_win = function(_, _, bufnr, top_row, bot_row)
    if vim.api.nvim_buf_get_name(bufnr) == "" then
      return
    end

    vim.api.nvim_buf_clear_namespace(bufnr, ns, top_row, bot_row)
    local current_file = vim.api.nvim_buf_get_name(bufnr)

    for _, mark in ipairs(vim.fn.getmarklist()) do
      if mark.mark:match("^.[a-zA-Z]$") then
        local mark_file = vim.fn.fnamemodify(mark.file, ":p:a")
        if current_file == mark_file then
          decor_mark(bufnr, mark)
        end
      end
    end

    for _, mark in ipairs(vim.fn.getmarklist(bufnr)) do
      if mark.mark:match("^.[a-zA-Z]$") then
        decor_mark(bufnr, mark)
      end
    end
  end,
})

vim.on_key(function(_, typed)
  if typed:sub(1, 1) ~= "m" then
    return
  end

  vim.schedule(function()
    if typed:sub(2):match("[A-Z]") then
      redraw_all_windows()
    else
      vim.api.nvim__redraw({ range = { 0, -1 } })
    end
  end)
end, ns)

map("n", "dm", function()
  local char = vim.fn.getcharstr()

  if USE_UPPERCASE_FOR_LOWERCASE and char:match("[a-z]") then
    char = char:upper()
  end

  if char == " " or char == "<leader>" then
    local all_marks = {}

    for _, mark in ipairs(vim.fn.getmarklist()) do
      if mark.mark:match("^'[A-Z]$") then
        table.insert(all_marks, mark.mark:sub(2))
      end
    end

    for _, mark in ipairs(vim.fn.getmarklist(vim.api.nvim_get_current_buf())) do
      if mark.mark:match("^'[a-z]$") then
        table.insert(all_marks, mark.mark:sub(2))
      end
    end

    if #all_marks > 0 then
      vim.cmd("delmarks " .. table.concat(all_marks, " "))
      vim.notify("Deleted " .. #all_marks .. " marks")
      redraw_all_windows()
    else
      vim.notify("No marks to delete")
    end
  elseif char:match("[a-zA-Z]") then
    vim.cmd("delmarks " .. char)
    vim.notify("Deleted mark '" .. char .. "'")
    if char:match("[A-Z]") then
      redraw_all_windows()
    else
      vim.api.nvim__redraw({ range = { 0, -1 } })
    end
  else
    vim.notify("Invalid mark: " .. char, vim.log.levels.WARN)
  end
end, { desc = "Delete mark" })

if USE_UPPERCASE_FOR_LOWERCASE then
  for char in string.gmatch("abcdefghijklmnopqrstuvwxyz", ".") do
    local upper = char:upper()
    map("n", "m" .. char, "m" .. upper, { desc = "Set mark " .. upper })
    map("n", "'" .. char, "'" .. upper, { desc = "Jump to mark " .. upper })
    map("n", "`" .. char, "`" .. upper, { desc = "Jump to mark " .. upper .. " (exact)" })
  end
end

---@param filter_to_cwd boolean
---@return table[]
local function build_picker_items(filter_to_cwd)
  local marks = vim.fn.getmarklist()
  local bufname = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
  local cwd = filter_to_cwd and vim.fn.getcwd() or nil
  local items = {}

  for i = #marks, 1, -1 do
    local mark = marks[i]
    local label = mark.mark:sub(2, 2)
    if label:match("[A-Z]") then
      local file = mark.file or bufname
      local buf = mark.pos[1] and mark.pos[1] > 0 and mark.pos[1] or nil

      if filter_to_cwd then
        local file_path = vim.fn.fnamemodify(file, ":p")
        if not vim.startswith(file_path, cwd) then
          goto continue
        end
      end

      local line_content = ""
      if buf and mark.pos[2] > 0 and vim.api.nvim_buf_is_valid(buf) then
        local ok, lines =
          pcall(vim.api.nvim_buf_get_lines, buf, mark.pos[2] - 1, mark.pos[2], false)
        if ok and lines[1] then
          line_content = lines[1]:gsub("^%s+", "")
        end
      end

      local file_display = vim.fn.fnamemodify(file, filter_to_cwd and ":~:." or ":~")
      table.insert(items, {
        text = string.format("[%s] %s %s", label, file_display, line_content),
        label = label,
        file = file,
        pos = mark.pos[2] > 0 and { mark.pos[2], math.max(0, (mark.pos[3] or 1) - 1) } or nil,
        buf = buf,
        line = line_content,
      })

      ::continue::
    end
  end

  return items
end

---@param filter_to_cwd boolean
local function create_marks_picker(filter_to_cwd)
  local prompt = filter_to_cwd and "Marks (Project) " or "Marks (All) "

  ---@param picker snacks.Picker
  local function delete_marks_action(picker)
    local items = picker:selected({ fallback = true })
    local marks_to_delete = {}
    for _, item in ipairs(items) do
      table.insert(marks_to_delete, item.label)
    end

    if #marks_to_delete > 0 then
      vim.cmd("delmarks " .. table.concat(marks_to_delete, " "))
      vim.notify("Deleted marks: " .. table.concat(marks_to_delete, ", "))
      redraw_all_windows()
      picker:refresh()
    end
  end

  ---@param picker snacks.Picker
  local function delete_all_marks_action(picker)
    local marks = build_picker_items(filter_to_cwd)
    local marks_to_delete = {}
    for _, mark in ipairs(marks) do
      table.insert(marks_to_delete, mark.label)
    end

    if #marks_to_delete > 0 then
      vim.cmd("delmarks " .. table.concat(marks_to_delete, " "))
      vim.notify(filter_to_cwd and "Deleted all marks in project" or "Deleted all marks")
      redraw_all_windows()
      picker:refresh()
    end
  end

  require("snacks").picker.pick({
    finder = function()
      return build_picker_items(filter_to_cwd)
    end,
    prompt = prompt,
    format = "file",
    preview = "file",
    jump = { close = true },
    on_show = function()
      vim.cmd.stopinsert()
    end,
    confirm = function(picker, item)
      picker:close()
      if item and item.file then
        vim.schedule(function()
          vim.cmd("edit " .. vim.fn.fnameescape(item.file))
          if item.pos then
            vim.api.nvim_win_set_cursor(0, item.pos)
          end
        end)
      end
    end,
    actions = {
      delete = delete_marks_action,
      delete_all = delete_all_marks_action,
    },
    win = {
      input = {
        keys = {
          ["<c-x>"] = "delete",
          ["<c-d>"] = "delete_all",
        },
      },
      list = {
        keys = {
          ["<c-x>"] = "delete",
          ["<c-d>"] = "delete_all",
        },
      },
    },
  })
end

map("n", "<leader>sm", function()
  create_marks_picker(true)
end, { desc = "Marks (Project)" })

map("n", "<leader>sM", function()
  create_marks_picker(false)
end, { desc = "Marks (All)" })
