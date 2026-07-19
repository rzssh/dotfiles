local opt = vim.opt

opt.cmdheight = 0
opt.updatetime = 100
opt.timeout = true
opt.timeoutlen = 500

opt.list = false
opt.listchars = "tab:▸ ,lead:·,trail:·,nbsp:␣,extends:▶,precedes:◀,eol:↲" -- bigger dot if desired: •

opt.relativenumber = true
opt.number = true

opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true

opt.wrap = true

opt.ignorecase = true
opt.smartcase = true
opt.inccommand = "split"

opt.cursorline = true

-- vim.opt.showtabline = 2 -- required for bufferline (tab) plugins to work properly (tabby / bufferline / etc)
opt.showtabline = 0
opt.title = false
opt.conceallevel = 0

opt.termguicolors = true
opt.background = "dark"
opt.backspace = "indent,eol,start"
opt.clipboard:append("unnamedplus")

opt.splitright = true
opt.splitbelow = true

opt.swapfile = false
opt.undofile = true
opt.autoread = true
opt.exrc = true

-- Handled by snacks.statuscolumn
opt.signcolumn = "yes:1"
opt.foldcolumn = "1"

opt.foldenable = true
opt.foldlevel = 99
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldtext = ""
opt.fillchars:append({
  fold = " ",
  foldclose = "▶",
  foldopen = "▼",
  foldsep = " ",
})

vim.diagnostic.config({
  virtual_text = false,
  severity_sort = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "",
      [vim.diagnostic.severity.WARN] = "",
      [vim.diagnostic.severity.INFO] = "",
      [vim.diagnostic.severity.HINT] = "󰠠",
    },
  },
})
