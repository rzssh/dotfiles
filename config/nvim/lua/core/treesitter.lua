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
  "odin",
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

vim.keymap.set("n", "<c-space>", function()
  vim.cmd.normal({ "v", bang = true })
  vim.treesitter.select("parent")
end, { desc = "Select treesitter node" })

vim.keymap.set("x", "<c-space>", function()
  vim.treesitter.select("parent")
end, { desc = "Increment selection" })

vim.keymap.set("x", "<bs>", function()
  vim.treesitter.select("child")
end, { desc = "Decrement selection" })
