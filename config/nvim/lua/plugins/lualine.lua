return {
  "nvim-lualine/lualine.nvim",
  event = "LazyFile",
  dependencies = {
    "nvim-mini/mini.nvim",
  },
  config = function()
    local function get_theme()
      for key in pairs(package.loaded) do
        if key:match("^lualine%.themes%.") then
          package.loaded[key] = nil
        end
      end

      local cs = require("core.colorscheme")
      if cs.matugen_data and vim.g.colors_name == "matugen" then
        local bg = cs.matugen_data.special.background
        local fg = cs.matugen_data.special.foreground
        local c = cs.matugen_data.colors
        local m = cs.matugen_data.material or {}
        vim.api.nvim_set_hl(0, "StatusLine", { bg = "NONE" })
        return {
          normal = {
            a = { bg = c.color4, fg = bg, gui = "bold" },
            b = { bg = m.primary_container or c.color0, fg = m.on_primary_container or fg },
            c = { bg = "None", fg = fg },
          },
          insert = { a = { bg = c.color2, fg = bg, gui = "bold" } },
          visual = { a = { bg = c.color5, fg = bg, gui = "bold" } },
          replace = { a = { bg = c.color1, fg = bg, gui = "bold" } },
          command = { a = { bg = c.color3, fg = bg, gui = "bold" } },
          inactive = {
            a = { bg = bg, fg = c.color8, gui = "bold" },
            b = { bg = bg, fg = c.color8 },
            c = { bg = bg, fg = c.color8 },
          },
        }
      end

      local theme = require("lualine.themes.auto")
      theme.normal.c.bg = "None"
      vim.api.nvim_set_hl(0, "StatusLine", { bg = "NONE" })
      return theme
    end

    vim.api.nvim_create_autocmd("ColorScheme", {
      callback = function()
        require("lualine").setup({ options = { theme = get_theme() } })
      end,
    })

    vim.api.nvim_create_autocmd({ "RecordingEnter", "RecordingLeave" }, {
      callback = function()
        require("lualine").refresh()
      end,
    })

    require("lualine").setup({
      options = {
        theme = get_theme(),
      },
      sections = {
        lualine_c = {
        },
        lualine_x = (function()
          local components = {
            { "overseer" },
            { "encoding" },
            { "fileformat" },
            { "filetype" },
          }

          local ecolog_ok = pcall(require, "ecolog")
          if ecolog_ok then
            table.insert(components, 1, require("ecolog.integrations.statusline").lualine())
          end

          local noice_ok, noice = pcall(require, "noice")
          if noice_ok then
            table.insert(components, 1, {
              noice.api.status.mode.get,
              cond = noice.api.status.mode.has,
              color = { fg = "#ff6b6b" },
            })
          else
            table.insert(components, 1, {
              function()
                return "recording @" .. vim.fn.reg_recording()
              end,
              cond = function()
                return vim.fn.reg_recording() ~= ""
              end,
              color = { fg = "#ff6b6b" },
            })
          end

          return components
        end)(),
      },
    })

    if vim.env.TMUX then
      vim.api.nvim_create_autocmd({ "FocusGained", "ColorScheme" }, {
        callback = function()
          vim.defer_fn(function()
            vim.opt.laststatus = 0
          end, 0)
        end,
      })

      vim.o.laststatus = 0
    end
  end,
}
