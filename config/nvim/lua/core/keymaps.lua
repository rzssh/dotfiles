vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("utils").mirror_keys({
  ["<C-h>"] = "<C-Left>",
  ["<C-j>"] = "<C-Down>",
  ["<C-k>"] = "<C-Up>",
  ["<C-l>"] = "<C-Right>",
  ["h"] = "<Left>",
  ["j"] = "<Down>",
  ["k"] = "<Up>",
  ["l"] = "<Right>",
  ["H"] = "<S-Left>",
  ["J"] = "<S-Down>",
  ["K"] = "<S-Up>",
  ["L"] = "<S-Right>",
})

local map = vim.keymap.set

map("i", "jk", "<Esc>", { desc = "Exit insert mode with jk" })
map("n", "<2-LeftMouse>", "<LeftMouse>viw", { noremap = true, silent = true })

map({ "n", "v" }, "<leader>cj", ":%!jq '.'<cr>", { desc = "Format JSON" })

map({ "n", "v" }, "<C-u>", "<C-u>zz", { noremap = true, silent = true })
map({ "n", "v" }, "<C-d>", "<C-d>zz", { noremap = true, silent = true })

map("v", ">", ">gv", { noremap = true, silent = true })
map("v", "<", "<gv", { noremap = true, silent = true })

map("n", "x", '"_x', { noremap = true, silent = true })

map("n", "<M-->", "<C-x>", { noremap = true, silent = true })
map("n", "<M-=>", "<C-a>", { noremap = true, silent = true })
map("v", "<M-->", "<C-x>gv", { noremap = true, silent = true })
map("v", "<M-=>", "<C-a>gv", { noremap = true, silent = true })
map("v", "g<M-=>", "g<C-a>gv", { noremap = true, silent = true, desc = "Sequential increment" })
map("v", "g<M-->", "g<C-x>gv", { noremap = true, silent = true, desc = "Sequential decrement" })
map({ "n", "v" }, "<C-a>", "<Nop>", { noremap = true, silent = true })

map("n", "<leader>pp", '"_cgn<C-r>"<Esc>', { desc = "Change next match with clipboard" }) -- (dot-repeatable)

map("n", "<leader>yy", ':let @+ = expand("%:p")<CR>', { desc = "Copy buffer's path" })
map("n", "<leader>yr", ':let @+ = expand("%:.")<CR>', { desc = "Copy relative path" })

map("n", "<leader>wv", "<C-w>v", { desc = "Split window vertically" })
map("n", "<leader>wh", "<C-w>s", { desc = "Split window horizontally" })

map("n", "<leader>wx", "<cmd>close<CR>", { desc = "Close split" })
map("n", "<leader>wm", "<cmd>tab split<CR>", { desc = "Maximize split" })

map("n", "<leader>w=", "<C-w>=", { desc = "Make splits equal size" })
map("n", "<leader>wj", "<C-w>_", { desc = "Maximize split vertically" })
map("n", "<leader>wk", "<C-w>|", { desc = "Maximize split horizontally" })

map("n", "<leader>wH", "<C-w>H", { desc = "Move split to left" })
map("n", "<leader>wJ", "<C-w>J", { desc = "Move split to bottom" })
map("n", "<leader>wK", "<C-w>K", { desc = "Move split to top" })
map("n", "<leader>wL", "<C-w>L", { desc = "Move split to right" })

map("n", "gp", "`[v`]", { desc = "Select previous paste" })

-- move in wrapped line, useful when vim.opt.wrap is set to true.
map({ "n", "v" }, "k", function()
  return vim.v.count == 0 and "gk" or "k"
end, { expr = true })
map({ "n", "v" }, "j", function()
  return vim.v.count == 0 and "gj" or "j"
end, { expr = true })
map({ "n", "v" }, "<Up>", function()
  return vim.v.count == 0 and "gk" or "k"
end, { expr = true })
map({ "n", "v" }, "<Down>", function()
  return vim.v.count == 0 and "gj" or "j"
end, { expr = true })

vim.keymap.set("x", "<leader>=", function()
  vim.cmd('normal! "xy')

  local expr = vim.fn.getreg("x")
  local ok, result = pcall(function()
    return load("return " .. expr)()
  end)

  if ok then
    vim.cmd('normal! gv"_c' .. result)
  else
    vim.notify("Invalid expression", vim.log.levels.ERROR)
  end
end, { desc = "Evaluate selection as Lua" })
