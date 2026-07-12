return {
  "folke/flash.nvim",
  enabled = not vim.list_contains(vim.v.argv, "+Man!"),
  event = "VeryLazy",
  specs = {
    -- Quick item selection with flash
    {
      "folke/snacks.nvim",
      opts = {
        picker = {
          win = {
            input = {
              keys = {
                ["<c-o>"] = { "flash", mode = { "n", "i" } },
                ["s"] = { "flash" },
              },
            },
          },
          actions = {
            flash = function(picker)
              require("flash").jump({
                pattern = "^",
                label = { after = { 0, 0 } },
                search = {
                  mode = "search",
                  exclude = {
                    function(win)
                      return vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "snacks_picker_list"
                    end,
                  },
                },
                action = function(match)
                  local idx = picker.list:row2idx(match.pos[1])
                  picker.list:_move(idx, true, true)
                end,
              })
            end,
          },
        },
      },
    },
  },
  ---@type Flash.Config
  opts = {
    search = {
      multi_window = false,
      exclude = {
        "oil",
        "blink-cmp-menu",
        "qf",
        -- Defaults
        "notify",
        "cmp_menu",
        "noice",
        "flash_prompt",
        function(win)
          -- exclude non-focusable windows
          return not vim.api.nvim_win_get_config(win).focusable
        end,
      },
    },
    modes = {
      char = {
        multi_line = true,
        jump_labels = false,
      },
      search = {
        enabled = true,
      },
    },
  },
  -- stylua: ignore
  keys = {
    { "<CR>", mode = { "n", "x", "o" }, function()
      if vim.bo.buftype == "nofile" or vim.bo.buftype == "quickfix" or vim.bo.filetype == "vim" then
        return vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "n", false)
      end
      require("flash").jump()
    end, desc = "Flash" },
    { "<leader>S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
    { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
    { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
    { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
  },
}
