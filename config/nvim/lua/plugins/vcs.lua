local codediff_walk = function(picker, item)
  picker:close()
  if item.commit then
    local current_commit = item.commit

    vim.fn.setreg("+", current_commit)
    vim.notify("Copied: " .. current_commit)
    -- get parent / previous commit
    local parent_commit = vim.trim(vim.fn.system("git rev-parse --short " .. current_commit .. "^"))
    parent_commit = parent_commit:match("[a-f0-9]+")
    -- Check if command failed (e.g., Initial commit has no parent)
    if vim.v.shell_error ~= 0 then
      vim.notify("Cannot find parent (Root commit?)", vim.log.levels.WARN)
      parent_commit = ""
    end
    local cmd = string.format("CodeDiff %s %s", parent_commit, current_commit)
    vim.notify("Diffing: " .. parent_commit .. " -> " .. current_commit)
    vim.cmd(cmd)
  end
end

local codediff_pickaxe = function(opts)
  opts = opts or {}
  local is_global = opts.global or false
  local current_file = vim.api.nvim_buf_get_name(0)
  -- Force global if current buffer is invalid
  if not is_global and (current_file == "" or current_file == nil) then
    vim.notify("Buffer is not a file, switching to global search", vim.log.levels.WARN)
    is_global = true
  end

  local title_scope = (is_global and "Global")
    or (current_file and vim.fn.fnamemodify(current_file, ":t"))
  vim.ui.input({ prompt = "Git Search (-G) in " .. title_scope .. ": " }, function(query)
    if not query or query == "" then
      return
    end

    -- set keyword highlight within Snacks.picker
    vim.fn.setreg("/", query)
    local old_hl = vim.opt.hlsearch
    vim.opt.hlsearch = true

    local args = {
      "log",
      "-G" .. query,
      "-i",
      "--pretty=format:%C(yellow)%h%Creset %s %C(green)(%cr)%Creset %C(blue)<%an>%Creset",
      "--abbrev-commit",
      "--date=short",
    }

    if not is_global then
      table.insert(args, "--")
      table.insert(args, current_file)
    end

    Snacks.picker({
      title = 'Git Log: "' .. query .. '" (' .. title_scope .. ")",
      finder = "proc",
      cmd = "git",
      args = args,

      transform = function(item)
        local clean_text = item.text:gsub("\27%[[0-9;]*m", "")
        local hash = clean_text:match("^%S+")
        if hash then
          item.commit = hash
          if not is_global then
            item.file = current_file
          end
        end
        return item
      end,

      preview = "git_show",
      confirm = codediff_walk,
      format = "text",

      on_close = function()
        -- remove keyword highlight
        vim.opt.hlsearch = old_hl
        vim.cmd("noh")
      end,
    })
  end)
end

return {
  {
    "FabijanZulj/blame.nvim",
    cmd = "BlameToggle",
    opts = {},
    keys = {
      { "<leader>gB", "<cmd>BlameToggle window<cr>", desc = "Blame buffer (window)" },
      { "<leader>tb", "<cmd>BlameToggle virtual<cr>", desc = "Toggle inline blame" },
    },
  },

  {
    "julienvincent/hunk.nvim",
    cmd = "DiffEditor",
    dependencies = { "MunifTanjim/nui.nvim" },
    opts = {
      keys = {
        global = {
          quit = { "q" },
          accept = { "<leader><Cr>" },
          focus_tree = { "<leader>e" },
        },
        tree = {
          expand_node = { "l", "<Right>" },
          collapse_node = { "h", "<Left>" },
          open_file = { "<Cr>" },
          toggle_file = { "a" },
        },
        diff = {
          toggle_line = { "a" },
          toggle_hunk = { "A" },
        },
      },
    },
  },

  {
    "rafikdraoui/jj-diffconflicts",
    cmd = "JJDiffConflicts",
  },

  {
    "avm99963/vim-jjdescription",
    lazy = false,
  },

  {
    "pwntester/octo.nvim",
    cmd = "Octo",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      picker = "snacks",
      use_local_fs = false,
      enable_builtin = true,
    },
    keys = {
      { "<leader>Op", "<cmd>Octo pr list<cr>", desc = "Octo: PR list" },
      { "<leader>Oi", "<cmd>Octo issue list<cr>", desc = "Octo: issue list" },
      { "<leader>Or", "<cmd>Octo review start<cr>", desc = "Octo: start review" },
    },
    init = function()
      require("which-key").add({
        { "<leader>O", group = "GitHub (Octo)" },
      })
    end,
  },

  {
    "esmuellert/codediff.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    cmd = "CodeDiff",
    keys = {
      { "<leader>gd", vim.cmd.CodeDiff, desc = "Show VSCode Git Status" },
    },
    init = function()
      -- Keymaps
      vim.keymap.set("n", "<leader>gss", function()
        codediff_pickaxe({ global = false })
      end, { desc = "Git Search (Buffer)" })

      vim.keymap.set("n", "<leader>gsS", function()
        codediff_pickaxe({ global = true })
      end, { desc = "Git Search (Global)" })

      vim.keymap.set({ "n", "t" }, "<leader>gsl", function()
        Snacks.picker.git_log_file({
          confirm = codediff_walk,
        })
      end, { desc = "find_git_log_file" })

      vim.keymap.set({ "n", "t" }, "<leader>gsL", function()
        Snacks.picker.git_log({
          confirm = codediff_walk,
        })
      end, { desc = "find_git_log" })
    end,
  },
}
