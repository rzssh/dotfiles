local map = vim.keymap.set

local M = {}

M.plugin = {
  "nvim-mini/mini.nvim",
  event = "LazyFile",
  config = function()
    local mini_align = require("mini.align")
    local mini_bracketed = require("mini.bracketed")
    local mini_ai = require("mini.ai")
    local mini_surround = require("mini.surround")
    local mini_splitjoin = require("mini.splitjoin")
    local mini_cursorword = require("mini.cursorword")
    local mini_diff = require("mini.diff")
    local mini_move = require("mini.move")
    local mini_jump = require("mini.jump")
    local mini_jump2d = require("mini.jump2d")

    mini_align.setup()
    mini_surround.setup({ n_lines = 9999 })
    mini_splitjoin.setup()
    mini_cursorword.setup()
    mini_jump.setup()
    mini_jump2d.setup({ labels = "shtaregyniwfdoblcuxmkvqpjz" })

    mini_diff.setup({
      view = { style = "sign" },
    })
    map("n", "<leader>=", function()
      mini_diff.toggle_overlay(0)
    end, { desc = "Toggle diff overlay" })
    map("n", "<leader>ga", function()
      MiniDiff.do_hunks(0, "apply")
    end, { desc = "Apply hunk (stage)" })
    map("n", "<leader>gr", function()
      MiniDiff.do_hunks(0, "reset")
    end, { desc = "Discard hunk" })
    map("x", "<leader>ga", function()
      MiniDiff.do_hunks(0, "apply", { selection = true })
    end, { desc = "Apply selected lines" })
    map("x", "<leader>gr", function()
      MiniDiff.do_hunks(0, "reset", { selection = true })
    end, { desc = "Discard selected lines" })

    mini_move.setup({
      mappings = {
        left = "H",
        down = "J",
        up = "K",
        right = "L",
      },
    })

    mini_ai.setup({
      n_lines = 9999,
      custom_textobjects = {
        ["|"] = mini_ai.gen_spec.pair("|", "|", { type = "balanced" }),
      },
    })

    mini_bracketed.setup({
      treesitter = { suffix = "" },
      diagnostic = { options = { float = false } },
    })
    vim.keymap.set("n", "u", function()
      vim.cmd("silent! undo")
      MiniBracketed.register_undo_state()
    end)
    vim.keymap.set("n", "<C-r>", function()
      vim.cmd("silent! redo")
      MiniBracketed.register_undo_state()
    end)
  end,
}

return M.plugin
