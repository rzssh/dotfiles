vim.keymap.set("x", "<leader>*", function()
  vim.cmd('normal! "xy')
  local text = vim.fn.getreg("x")

  local font_dir = vim.fn.system("figlet -I2"):gsub("%s+$", "")
  local fonts = {}
  local files = vim.fn.globpath(font_dir, "*.flf", false, true)
  for _, f in ipairs(files) do
    local name = vim.fn.fnamemodify(f, ":t:r")
    table.insert(fonts, { text = name, name = name })
  end

  Snacks.picker.pick({
    title = "Figlet Font",
    items = fonts,
    layout = {
      preset = "select",
      layout = { width = 30, min_width = 25 },
    },
    format = function(item)
      return { { item.name } }
    end,
    confirm = function(picker, item)
      picker:close()
      if item then
        local result = vim.fn.system("figlet -f " .. item.name, text)
        vim.cmd('normal! gv"_c')
        local lines = vim.split(result, "\n", { trimempty = true })

        vim.api.nvim_put(lines, "c", false, true)
      end
    end,
  })
end, { desc = "Turn to ASCII art" })

vim.keymap.set("x", "<leader>#", function()
  vim.cmd('normal! "xy')
  local text = vim.fn.getreg("x")
  local lines = vim.split(text, "\n", { trimempty = true })

  for i, line in ipairs(lines) do
    lines[i] = vim.trim(line)
  end

  local max_len = 0
  for _, line in ipairs(lines) do
    max_len = math.max(max_len, #line)
  end

  local function pad_line(line)
    return line .. string.rep(" ", max_len - #line)
  end

  local box_styles = {
    { name = "Triple Hash (###)", char = "#", count = 3 },
    { name = "Asterisks (***)", char = "*", count = 3 },
    { name = "Equals (===)", char = "=", count = 3 },
    { name = "ASCII Light (┌─┐)", type = "ascii_light" },
    { name = "ASCII Heavy (╔═╗)", type = "ascii_heavy" },
  }

  Snacks.picker.pick({
    title = "Box Style",
    items = box_styles,
    layout = {
      preset = "select",
      layout = { width = 30, min_width = 25 },
    },
    on_show = function()
      vim.cmd.stopinsert()
    end,
    format = function(item)
      return { { item.name } }
    end,
    confirm = function(picker, item)
      picker:close()
      if not item then
        return
      end

      local result = {}

      if item.type == "ascii_light" then
        table.insert(result, "┌" .. string.rep("─", max_len + 2) .. "┐")
        for _, line in ipairs(lines) do
          table.insert(result, "│ " .. pad_line(line) .. " │")
        end
        table.insert(result, "└" .. string.rep("─", max_len + 2) .. "┘")
      elseif item.type == "ascii_heavy" then
        table.insert(result, "╔" .. string.rep("═", max_len + 2) .. "╗")
        for _, line in ipairs(lines) do
          table.insert(result, "║ " .. pad_line(line) .. " ║")
        end
        table.insert(result, "╚" .. string.rep("═", max_len + 2) .. "╝")
      else
        local char = item.char
        local count = item.count
        local side = string.rep(char, count)
        local border_width = max_len + (count + 1) * 2

        table.insert(result, string.rep(char, border_width))
        for _, line in ipairs(lines) do
          table.insert(result, side .. " " .. pad_line(line) .. " " .. side)
        end
        table.insert(result, string.rep(char, border_width))
      end

      vim.cmd('normal! gv"_c')
      vim.api.nvim_put(result, "c", false, true)
    end,
  })
end, { desc = "Boxify selection" })
