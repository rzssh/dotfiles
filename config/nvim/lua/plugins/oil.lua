local get_path_under_cursor = function(relative)
  local oil = require("oil")
  local entry = oil.get_cursor_entry()
  local dir = oil.get_current_dir()
  if not entry or not dir then
    error("Could not get path under cursor")
  end

  if relative then
    return vim.fn.fnamemodify(dir .. entry.name, ":.")
  end

  return dir .. entry.name
end

return {
  "stevearc/oil.nvim",
  cmd = "Oil",
  event = { "VimEnter */*,.*", "BufNew */*,.*", "VeryLazy" },
  dependencies = { "nvim-mini/mini.icons" },
  opts = {
    delete_to_trash = true,
    columns = {
      "icon",
      -- { "mtime", format = "|%d.%m|" },
    },
    view_options = {
      show_hidden = true,
    },
    keymaps = {
      ["<leader>yy"] = {
        desc = "Copy path of file under cursor",
        callback = function()
          vim.fn.setreg(vim.v.register, get_path_under_cursor())
        end,
      },
      ["<leader>yr"] = {
        desc = "Copy relative path of file under cursor",
        callback = function()
          vim.fn.setreg(vim.v.register, get_path_under_cursor(true))
        end,
      },
    },
  },
  keys = {
    { "-", vim.cmd.Oil, mode = "n", desc = "Open parent directory" },
  },
  init = function()
    vim.api.nvim_create_autocmd("User", {
      pattern = "OilActionsPost",
      callback = function(event)
        if #event.data.actions == 0 then
          return
        end

        if event.data.actions[1].type == "move" then
          Snacks.rename.on_rename_file(
            event.data.actions[1].src_url,
            event.data.actions[1].dest_url
          )
        end
      end,
    })
  end,
}
