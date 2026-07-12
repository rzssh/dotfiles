return {
  {
    "bullets-vim/bullets.vim",
    ft = { "markdown", "text", "gitcommit", "scratch" },
    init = function()
      vim.g.bullets_delete_last_bullet_if_empty = 2
    end,
  },
  {
    "OXY2DEV/markview.nvim",
    ft = "markdown",
    cmd = "Markview",
    keys = {
      { "<leader>mt", "<cmd>Markview toggle<cr>", desc = "Toggle Markview" },
    },
    opts = {
      preview = {
        map_gx = false,
      },
    },
    config = function(_, opts)
      require("markview").setup(opts)

      local native_gx = vim.iter(vim.api.nvim_get_keymap("n")):find(function(map)
        return map.lhs == "gx"
      end).callback

      local markview_nodes = {
        "email_autolink",
        "image",
        "inline_link",
        "link_reference_definition",
        "shortcut_link",
        "uri_autolink",
        "url",
      }

      local function open_markdown_link()
        local node = vim.treesitter.get_node({ ignore_injections = false })

        while node do
          if vim.list_contains(markview_nodes, node:type()) then
            vim.cmd("Markview open")
            return
          end

          node = node:parent()
        end

        native_gx()
      end

      local function map_gx(args)
        vim.keymap.set("n", "gx", open_markdown_link, {
          buffer = args.buf,
          desc = "Open markdown link or URI",
        })
      end

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        callback = map_gx,
      })

      if vim.bo.filetype == "markdown" then
        map_gx({ buf = 0 })
      end
    end,
    init = function()
      require("which-key").add({
        { "<leader>m", group = "Markdown", icon = { icon = "", color = "green" } },
      })
    end,
  },
  {
    "HakonHarnes/img-clip.nvim",
    event = "LazyFile",
    ft = "markdown",
    opts = {
      default = {
        use_absolute_path = false,
        relative_to_current_file = true,
        dir_path = function()
          return vim.fn.expand("%:t:r") .. "-img"
        end,
        prompt_for_file_name = false,
        file_name = "%y%m%d-%H%M%S",
        extension = "png", -- or "webp", "avif", "jpg", etc.
        process_cmd = "convert - -quality 75 png:-", -- or webp:-, fng:-, jpg:-, etc.
        -- process_cmd = "convert - -quality 75 -resize 50% png:-",
        -- process_cmd = "convert - -sampling-factor 4:2:0 -strip -interlace JPEG -colorspace RGB -quality 75 jpg:-",
        -- process_cmd = "convert - -strip -interlace Plane -gaussian-blur 0.05 -quality 75 jpg:-",
      },
      filetypes = {
        markdown = {
          url_encode_path = true,
          template = "![$CURSOR]($FILE_PATH)",
          drag_and_drop = {
            download_images = false,
          },
        },
      },
    },
    keys = {
      { "<leader>ii", vim.cmd.PasteImage, desc = "Paste image from system clipboard" },
    },
    init = function()
      require("which-key").add({
        { "<leader>i", group = "Images", icon = { icon = "", color = "blue" } },
      })
    end,
  },
  {
    "brianhuster/live-preview.nvim",
    event = "VeryLazy",
    ft = { "html", "markdown", "adoc", "txt" },
    opts = {
      picker = "snacks.picker",
    },
    keys = {
      {
        "<leader>mp",
        function()
          local livepreview = require("livepreview")

          if livepreview.is_running() then
            vim.cmd("silent LivePreview close")
            vim.cmd("silent LivePreview start")
          else
            vim.cmd("silent LivePreview start")
          end
        end,
        desc = "Start LivePreview server",
      },
      {
        "<leader>ms",
        function()
          vim.cmd("silent LivePreview close")
        end,
        desc = "Stop LivePreview server",
      },
    },
    init = function()
      require("which-key").add({
        { "<leader>m", group = "Markdown", icon = { icon = "", color = "green" } },
      })
    end,
  },
}
