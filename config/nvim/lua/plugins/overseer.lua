return {
  "stevearc/overseer.nvim",
  event = "VeryLazy",
  cmd = { "OverseerRun", "OverseerToggle", "OverseerTaskList", "OverseerInfo" },
  keys = {
    { "<leader>or", "<cmd>OverseerRun<cr>", desc = "Run task" },
    { "<leader>ot", "<cmd>OverseerToggle<cr>", desc = "Task list" },
    { "<leader>ol", "<cmd>OverseerTaskAction<cr>", desc = "Task action" },
    { "<leader>b", desc = "Build" },
  },
  opts = {
    strategy = "terminal",
    templates = { "builtin", "user" },
    task_list = { direction = "bottom", min_height = 10, max_height = 20, default_detail = 1 },
    disable_template_modules = { "overseer.template.npm" },
    dap = false,
  },
  config = function(_, opts)
    local overseer = require("overseer")
    overseer.setup(opts)

    local uv = vim.uv or vim.loop
    local files = require("overseer.files")

    overseer.register_template({
      name = "npm",
      priority = 60,
      generator = function(search_opts)
        local root_pkg = vim.fs.find("package.json", { upward = true, path = vim.fn.getcwd() })[1]
        if not root_pkg or root_pkg:match("node_modules") then
          return "No package.json found"
        end

        local root_dir = vim.fs.dirname(root_pkg)
        local bin = (uv.fs_stat(root_dir .. "/pnpm-lock.yaml") and "pnpm")
          or (uv.fs_stat(root_dir .. "/yarn.lock") and "yarn")
          or ((uv.fs_stat(root_dir .. "/bun.lockb") or uv.fs_stat(root_dir .. "/bun.lock")) and "bun")
          or "npm"

        local ret = {}
        local function add_scripts(pkg_path, prefix)
          local dir, data = vim.fs.dirname(pkg_path), files.load_json_file(pkg_path)
          for k in pairs((data and data.scripts) or {}) do
            table.insert(ret, {
              name = ("%s%s %s (%s)"):format(bin, prefix, k, data.name or "root"),
              builder = function()
                return { cmd = { bin, "run", k }, cwd = dir }
              end,
            })
          end
        end

        add_scripts(root_pkg, "")
        local current_pkg =
          vim.fs.find("package.json", { upward = true, path = search_opts.dir, stop = root_dir })[1]
        if current_pkg and vim.fs.dirname(current_pkg) ~= root_dir then
          add_scripts(current_pkg, "[ws] ")
        end

        return ret
      end,
    })

    local function exists(p)
      return uv.fs_stat(p) ~= nil
    end

    local function run(name)
      vim.fn.setqflist({})
      overseer.run_task({ name = name }, function(task)
        if task then
          task:subscribe("on_complete", function()
            if (vim.fn.getqflist({ size = 0 }).size or 0) > 0 then
              vim.cmd("copen")
            end
          end)
        end
      end)
    end

    local function smart_build()
      local ft = vim.bo.filetype
      if ft == "go" then
        return run("go build")
      end
      if ft == "c" then
        return run("gcc build")
      end
      if ft == "cpp" then
        return run("c++ build")
      end
      if ft == "zig" then
        return run("zig build")
      end

      local r = vim.fs.root(0, { ".git" }) or vim.uv.cwd()
      if exists(r .. "/Cargo.toml") then
        return run("cargo build")
      end
      if exists(r .. "/go.mod") then
        return run("go build")
      end
      if exists(r .. "/build.zig") then
        return run("zig build")
      end
      if exists(r .. "/tsconfig.json") or exists(r .. "/package.json") then
        return run("tsc")
      end

      vim.notify("No build for " .. ft, vim.log.levels.WARN)
    end

    vim.keymap.set("n", "<leader>b", smart_build, { desc = "Build" })
  end,
  init = function()
    require("which-key").add({
      { "<leader>o", group = "Overseer (Tasks)" },
      { "<leader>b", group = "Build", icon = { icon = "", color = "green" } },
    })
  end,
}
