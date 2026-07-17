local M = {}

-- unpatched originals, stashed once, for callers that need to set a keymap
-- WITHOUT it being auto-mirrored (see mirror_keys below).
M.raw = {
  set = vim.keymap.set,
  set_keymap = vim.api.nvim_set_keymap,
  buf_set_keymap = vim.api.nvim_buf_set_keymap,
}

M.mirror_keys = function(aliases)
  local function replace_lhs(lhs)
    if type(lhs) ~= "string" or vim.startswith(lhs, "<Plug>") then return end
    for from, to in pairs(aliases) do
      if lhs == from then return to end
      if vim.endswith(lhs, from) then
        local prefix = lhs:sub(1, #lhs - #from)
        if not vim.endswith(prefix, "-") then
          return prefix .. to
        end
      end
    end
  end

  local fns = {
    { obj = vim.api, name = "nvim_buf_set_keymap", lhs_pos = 3 },
    { obj = vim.api, name = "nvim_set_keymap", lhs_pos = 2 },
    { obj = vim.keymap, name = "set", lhs_pos = 2 },
  }

  for _, fn in ipairs(fns) do
    local orig = fn.obj[fn.name]
    fn.obj[fn.name] = function(...)
      orig(...)
      local args = { ... }
      local new_lhs = replace_lhs(args[fn.lhs_pos])
      if new_lhs then
        args[fn.lhs_pos] = new_lhs
        orig(unpack(args))
      end
    end
  end
end

M.retire_keys = function(aliases)
  for from, to in pairs(aliases) do
    for _, mode in ipairs({ "n", "x" }) do
      pcall(vim.keymap.set, mode, to, from, { noremap = true, silent = true })
      pcall(vim.keymap.set, mode, from, "<Nop>", { noremap = true, silent = true })
    end
  end
end

return M
