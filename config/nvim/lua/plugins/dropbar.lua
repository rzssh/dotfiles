return {
  "Bekaboo/dropbar.nvim",
  event = "LazyFile",
  config = function()
    local bar = require("dropbar.bar")
    local sources = require("dropbar.sources")
    local icons = require("icons")

    local function git_head(buf)
      local name = vim.api.nvim_buf_get_name(buf)
      local root = vim.fs.root(name ~= "" and name or vim.uv.cwd(), ".git")
      if not root then
        return nil
      end
      -- ponytail: reads .git/HEAD directly; won't resolve linked worktrees (.git file). Add gitdir follow if needed.
      local ok, lines = pcall(vim.fn.readfile, root .. "/.git/HEAD")
      if not ok or not lines[1] then
        return nil
      end
      local head = vim.trim(lines[1])
      return head:match("^ref: refs/heads/(.+)$") or head:sub(1, 7)
    end

    local git_branch = {
      get_symbols = function(buf, _, _)
        local head = git_head(buf)
        if not head or head == "" then
          return {}
        end
        return {
          bar.dropbar_symbol_t:new({
            icon = icons.branch .. " ",
            icon_hl = "Special",
            name = head,
            name_hl = "Special",
          }),
        }
      end,
    }

    local function file_icon(name)
      local ok, mi = pcall(require, "mini.icons")
      if ok then
        local icon, hl = mi.get("file", name)
        return icon, hl
      end
      return icons.file, "Normal"
    end

    local smart_path = {
      get_symbols = function(buf, _, _)
        local abs = vim.api.nvim_buf_get_name(buf)
        if abs == "" then
          return {}
        end

        local fname = vim.fn.fnamemodify(abs, ":t")
        local icon, ihl = file_icon(fname)

        local stats = {
          bar.dropbar_symbol_t:new({
            icon = icon .. " ",
            icon_hl = ihl,
            name = fname,
            name_hl = "Normal",
          }),
        }

        local base = vim.fs.root(abs, ".git") or vim.uv.cwd()
        local rel = vim.fs.relpath(base, abs)
        local dir
        if rel then
          dir = vim.fn.fnamemodify(rel, ":h")
          if dir == "." then
            dir = vim.fn.fnamemodify(base, ":t")
          end
        else
          dir = vim.fn.fnamemodify(abs, ":~:h")
        end
        if dir and dir ~= "." and dir ~= "" then
          table.insert(
            stats,
            bar.dropbar_symbol_t:new({
              icon = icons.folder .. " ",
              icon_hl = "Directory",
              name = dir,
              name_hl = "Comment",
            })
          )
        end

        return stats
      end,
    }

    local git_diff_stats = {
      get_symbols = function(buf, _, _)
        local summary = vim.b[buf].minidiff_summary
        if not summary then
          return {}
        end

        local stats = {}
        local function push(value, glyph, hl)
          if value and value > 0 then
            table.insert(
              stats,
              bar.dropbar_symbol_t:new({
                icon = glyph .. " ",
                icon_hl = hl,
                name = tostring(value),
                name_hl = hl,
              })
            )
          end
        end

        push(summary.add, icons.diff.add, "MiniDiffSignAdd")
        push(summary.change, icons.diff.change, "MiniDiffSignChange")
        push(summary.delete, icons.diff.delete, "MiniDiffSignDelete")
        return stats
      end,
    }

    local function diag_icon(severity, fallback)
      local cfg = vim.diagnostic.config() or {}
      local signs = cfg.signs
      if type(signs) == "table" and type(signs.text) == "table" and signs.text[severity] then
        return signs.text[severity]
      end
      return fallback
    end

    local diag_order = {
      { severity = vim.diagnostic.severity.ERROR, hl = "DiagnosticError", fallback = "E" },
      { severity = vim.diagnostic.severity.WARN, hl = "DiagnosticWarn", fallback = "W" },
      { severity = vim.diagnostic.severity.INFO, hl = "DiagnosticInfo", fallback = "I" },
      { severity = vim.diagnostic.severity.HINT, hl = "DiagnosticHint", fallback = "H" },
    }

    local lsp_diagnostics = {
      get_symbols = function(buf, _, _)
        local stats = {}
        for _, def in ipairs(diag_order) do
          local count = #vim.diagnostic.get(buf, { severity = def.severity })
          if count > 0 then
            table.insert(
              stats,
              bar.dropbar_symbol_t:new({
                icon = diag_icon(def.severity, def.fallback) .. " ",
                icon_hl = def.hl,
                name = tostring(count),
                name_hl = def.hl,
              })
            )
          end
        end
        return stats
      end,
    }

    require("dropbar").setup({
      icons = {
        enabled = true,
        ui = {
          bar = {
            separator = "  ",
            extends = "…",
          },
        },
      },
      bar = {
        sources = function(buf, _)
          if vim.bo[buf].buftype == "terminal" then
            return { sources.terminal }
          end
          return { git_branch, smart_path, git_diff_stats, lsp_diagnostics }
        end,
      },
    })
  end,
}
