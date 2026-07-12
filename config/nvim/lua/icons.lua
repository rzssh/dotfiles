local nr = vim.fn.nr2char

return {
  branch = nr(0xe0a0),
  folder = nr(0xeaf7),
  file = nr(0xf016),
  diff = {
    add = nr(0xf457),
    change = nr(0xf459),
    delete = nr(0xf458),
  },
}
