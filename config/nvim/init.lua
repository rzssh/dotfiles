require("core.init")

local uv = vim.uv or vim.loop
local uname = uv.os_uname().sysname
vim.g.is_linux = uname == "Linux"

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

local Event = require("lazy.core.handler.event")
Event.mappings.LazyFile =
  { id = "LazyFile", event = { "BufReadPost", "BufNewFile", "BufWritePre" } }
Event.mappings["User LazyFile"] = Event.mappings.LazyFile

require("lazy").setup({
  { import = "plugins" },
  { import = "plugins.themes" },
}, {
  checker = { enabled = true, notify = false },
  change_detection = { notify = false },
  defaults = { lazy = true },
})

require("notes").setup({
  dir = "~/notes",
  float_file = "inbox.md",
})

require("herdr").setup()
