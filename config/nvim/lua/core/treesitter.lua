local fts = {
  "bash",
  "c",
  "cmake",
  "cpp",
  "css",
  "dockerfile",
  "fish",
  "ghostty",
  "gitignore",
  "go",
  "graphql",
  "haskell",
  "html",
  "javascript",
  "javascriptreact",
  "jsdoc",
  "json",
  "kdl",
  "lua",
  "markdown",
  "prisma",
  "query",
  "rust",
  "sh",
  "supercollider",
  "svelte",
  "tidal",
  "tmux",
  "tsx",
  "typescript",
  "typescriptreact",
  "vim",
  "yaml",
  "zig",
}

vim.api.nvim_create_autocmd("FileType", {
  pattern = fts,
  callback = function()
    pcall(vim.treesitter.start)
  end,
})

vim.filetype.add({
  extension = {
    mdc = "markdown",
    kbd = "lisp",
    conf = "conf",
    tiltfile = "tiltfile",
    Tiltfile = "tiltfile",
    tidal = "tidal",
  },
  filename = {
    ["tsconfig.json"] = "jsonc",
    [".yamlfmt"] = "yaml",
  },
  pattern = {
    [".*/ghostty/.*"] = "ghostty",
    [".*/mako/config"] = "ghostty",
    [".env.*"] = "sh",
  },
})

-- Custom incremental selection
_G.selected_nodes = {}

local function select_node(node)
  if not node then
    return
  end
  local start_row, start_col, end_row, end_col = node:range()
  vim.fn.setpos("'<", { 0, start_row + 1, start_col + 1, 0 })
  vim.fn.setpos("'>", { 0, end_row + 1, end_col, 0 })
  vim.cmd("normal! gv")
end

vim.keymap.set({ "n" }, "<c-space>", function()
  _G.selected_nodes = {}

  local current_node = vim.treesitter.get_node()
  if not current_node then
    return
  end

  table.insert(_G.selected_nodes, current_node)
  select_node(current_node)
end, { desc = "Select treesitter node" })

vim.keymap.set("x", "<c-space>", function()
  if #_G.selected_nodes == 0 then
    return
  end

  local current_node = _G.selected_nodes[#_G.selected_nodes]

  if not current_node then
    return
  end

  local parent = current_node:parent()
  if parent then
    table.insert(_G.selected_nodes, parent)
    select_node(parent)
  end
end, { desc = "Increment selection" })

vim.keymap.set("x", "<bs>", function()
  table.remove(_G.selected_nodes)
  local current_node = _G.selected_nodes[#_G.selected_nodes]
  if current_node then
    select_node(current_node)
  end
end, { desc = "Decrement selection" })
