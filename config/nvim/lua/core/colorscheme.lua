local M = {}

local function hex_to_rgb(hex)
  return tonumber(hex:sub(2, 3), 16), tonumber(hex:sub(4, 5), 16), tonumber(hex:sub(6, 7), 16)
end

local function int_to_rgb(c)
  return bit.rshift(bit.band(c, 0xFF0000), 16),
    bit.rshift(bit.band(c, 0x00FF00), 8),
    bit.band(c, 0x0000FF)
end

local function rgb_to_hex(r, g, b)
  return string.format(
    "#%02x%02x%02x",
    math.min(255, math.max(0, math.floor(r))),
    math.min(255, math.max(0, math.floor(g))),
    math.min(255, math.max(0, math.floor(b)))
  )
end

local function lighten(hex, amount)
  local r, g, b = hex_to_rgb(hex)
  return rgb_to_hex(r + (255 - r) * amount, g + (255 - g) * amount, b + (255 - b) * amount)
end

local function blend_int(fg_int, bg_int, alpha)
  local fr, fg, fb = int_to_rgb(fg_int)
  local br, bg, bb = int_to_rgb(bg_int)
  return rgb_to_hex(
    fr * alpha + br * (1 - alpha),
    fg * alpha + bg * (1 - alpha),
    fb * alpha + bb * (1 - alpha)
  )
end

local function transparent_winbar()
  vim.api.nvim_set_hl(0, "WinBar", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "WinBarNC", { bg = "NONE" })
end

local function transparent_float()
  vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "FloatBorder", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "FloatTitle", { bg = "NONE" })
end

local function transparent_neotree()
  vim.api.nvim_set_hl(0, "NeoTreeNormal", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "NeoTreeNormalNC", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "NeoTreeFloatBorder", { bg = "NONE" })
end

local function transparent_statusline()
  vim.api.nvim_set_hl(0, "StatusLine", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "NONE" })
end

local function default_harpoon()
  vim.api.nvim_set_hl(0, "HarpoonOptionHL", { fg = "#89DDFF" })
  vim.api.nvim_set_hl(0, "HarpoonSelectedOptionHL", { fg = "#5DE4C7" })
end

local function minicursorword()
  local cl = vim.api.nvim_get_hl(0, { name = "CursorLine" })
  local func = vim.api.nvim_get_hl(0, { name = "Function" })
  if not cl.bg or not func.fg then
    return
  end
  local word_bg = blend_int(func.fg, cl.bg, 0.25)
  vim.api.nvim_set_hl(0, "MiniCursorword", { bg = word_bg })
  vim.api.nvim_set_hl(0, "MiniCursorwordCurrent", { bg = word_bg })
end

local function ts_context()
  vim.api.nvim_set_hl(
    0,
    "TreesitterContext",
    { bg = vim.api.nvim_get_hl(0, { name = "CursorLine" }).bg }
  )
  vim.api.nvim_set_hl(0, "TreesitterContextBottom", { underline = false })
end

local function flash_search()
  vim.api.nvim_set_hl(0, "FlashCurrent", { link = "CurSearch" })
  vim.api.nvim_set_hl(0, "FlashMatch", { link = "Search" })
end

local function mini_diff_overlay()
  vim.api.nvim_set_hl(0, "MiniDiffOverAdd", { bg = "#1e3a2f", fg = "#a6e3a1" })
  vim.api.nvim_set_hl(0, "MiniDiffOverDelete", { bg = "#3a1e1e", fg = "#f38ba8" })
  vim.api.nvim_set_hl(0, "MiniDiffOverChange", { bg = "#3a351e", fg = "#f9e2af" })
  vim.api.nvim_set_hl(0, "MiniDiffOverContext", { fg = "#6c7086" })
end

local function diagnostics()
  local diagnostic_underline = vim.api.nvim_get_hl(0, { name = "DiagnosticUnderline" })
  diagnostic_underline.underline = true
  vim.api.nvim_set_hl(0, "DiagnosticUnderlineHint", diagnostic_underline)
end

---@param disable? boolean If true, removes bold styling from selected nodes instead
local function ts_lsp_bold_nodes(disable)
  local nodes = {
    "@lsp.type.function",
    "@function",
    "Function",
    "Green",
  }
  for _, node in ipairs(nodes) do
    vim.api.nvim_set_hl(
      0,
      node,
      vim.tbl_extend("force", vim.api.nvim_get_hl(0, { name = node }), { bold = not disable })
    )
  end
end

M.matugen_data = nil
M._matugen_raw = nil

local function read_colors()
  local file = io.open(vim.fn.expand("~/.cache/matugen/colors.json"), "r")
  if not file then
    return nil
  end
  local content = file:read("*all")
  file:close()
  return content
end

local function load_matugen_data()
  local content = read_colors()
  if not content then
    vim.notify("matugen: No colors at ~/.cache/matugen/colors.json", vim.log.levels.WARN)
    return nil
  end

  local ok, data = pcall(vim.json.decode, content)
  if not ok or not data then
    return nil
  end
  M._matugen_raw = content
  M.matugen_data = data
  return data
end

local function apply_matugen(variant)
  variant = variant or "ansi"
  local data = load_matugen_data()
  if not data then
    return false
  end

  vim.cmd("hi clear")
  vim.g.colors_name = "matugen"
  vim.o.background = "dark"

  local bg = data.special.background
  local fg = data.special.foreground
  local c = data.colors
  local accent = data.special.cursor or c.color4
  local m = data.material or {}
  local pri = m.primary or accent
  local sec = m.secondary or c.color6
  local ter = m.tertiary or c.color5
  local selection_bg = m.primary_container or c.color0
  local selection_fg = m.on_primary_container or fg

  local syn
  if variant == "rich" then
    syn = { kw = pri, fn = accent, str = c.color2, typ = sec, const = ter, spec = c.color6, op = c.color7, num = c.color5 }
  else
    syn = { kw = c.color1, fn = accent, str = c.color2, typ = c.color3, const = c.color5, spec = c.color6, op = c.color6, num = c.color5 }
  end

  local subtle = lighten(bg, 0.1)

  local hi = vim.api.nvim_set_hl
  hi(0, "Normal", { fg = fg, bg = "NONE" })
  hi(0, "NormalFloat", { fg = fg, bg = "NONE" })
  hi(0, "FloatBorder", { fg = c.color8, bg = "NONE" })
  hi(0, "CursorLine", { bg = subtle })
  hi(0, "Visual", { fg = selection_fg, bg = selection_bg })
  hi(0, "LineNr", { fg = c.color8 })
  hi(0, "CursorLineNr", { fg = accent, bold = true })
  hi(0, "Search", { fg = bg, bg = c.color3 })
  hi(0, "IncSearch", { fg = bg, bg = c.color5 })
  hi(0, "Comment", { fg = c.color8, italic = true })
  hi(0, "String", { fg = syn.str })
  hi(0, "Function", { fg = syn.fn, bold = true })
  hi(0, "Keyword", { fg = syn.kw })
  hi(0, "Type", { fg = syn.typ })
  hi(0, "Constant", { fg = syn.const })
  hi(0, "Identifier", { fg = fg })
  hi(0, "Special", { fg = syn.spec })
  hi(0, "Statement", { fg = syn.kw })
  hi(0, "PreProc", { fg = syn.typ })
  hi(0, "Operator", { fg = syn.op })
  hi(0, "Pmenu", { fg = fg, bg = c.color0 })
  hi(0, "PmenuSel", { fg = selection_fg, bg = selection_bg, bold = true })
  hi(0, "PmenuSbar", { bg = c.color0 })
  hi(0, "PmenuThumb", { bg = c.color8 })

  hi(0, "Number", { fg = syn.num })
  hi(0, "Boolean", { fg = syn.num })
  hi(0, "Title", { fg = accent, bold = true })
  hi(0, "Directory", { fg = accent })
  hi(0, "MatchParen", { fg = c.color3, bold = true })
  hi(0, "WinSeparator", { fg = c.color8 })
  hi(0, "ErrorMsg", { fg = c.color1 })
  hi(0, "WarningMsg", { fg = c.color3 })

  hi(0, "StatusLine", { fg = fg, bg = c.color0 })
  hi(0, "StatusLineNC", { fg = c.color8, bg = c.color0 })
  hi(0, "WinBar", { fg = fg, bg = "NONE" })
  hi(0, "WinBarNC", { fg = c.color8, bg = "NONE" })
  hi(0, "TabLine", { fg = c.color8, bg = c.color0 })
  hi(0, "TabLineSel", { fg = bg, bg = accent })
  hi(0, "TabLineFill", { bg = c.color0 })

  hi(0, "DiagnosticError", { fg = c.color1 })
  hi(0, "DiagnosticWarn", { fg = c.color3 })
  hi(0, "DiagnosticInfo", { fg = c.color4 })
  hi(0, "DiagnosticHint", { fg = c.color6 })
  hi(0, "DiagnosticOk", { fg = c.color2 })

  hi(0, "DiffAdd", { fg = c.color2, bg = "NONE" })
  hi(0, "DiffChange", { fg = c.color3, bg = "NONE" })
  hi(0, "DiffDelete", { fg = c.color1, bg = "NONE" })
  hi(0, "GitSignsAdd", { fg = c.color2 })
  hi(0, "GitSignsChange", { fg = c.color3 })
  hi(0, "GitSignsDelete", { fg = c.color1 })

  -- Modern nvim no longer links these to base groups by default, so set them explicitly.
  local ts = {
    ["@variable"] = "Identifier",
    ["@variable.builtin"] = "Statement",
    ["@variable.parameter"] = "Identifier",
    ["@variable.member"] = "Special",
    ["@property"] = "Special",
    ["@field"] = "Special",
    ["@function"] = "Function",
    ["@function.call"] = "Function",
    ["@function.builtin"] = "Function",
    ["@function.method"] = "Function",
    ["@function.method.call"] = "Function",
    ["@constructor"] = "Type",
    ["@parameter"] = "Identifier",
    ["@keyword"] = "Keyword",
    ["@keyword.function"] = "Keyword",
    ["@keyword.return"] = "Keyword",
    ["@conditional"] = "Keyword",
    ["@repeat"] = "Keyword",
    ["@string"] = "String",
    ["@string.escape"] = "Special",
    ["@number"] = "Number",
    ["@boolean"] = "Boolean",
    ["@constant"] = "Constant",
    ["@constant.builtin"] = "Constant",
    ["@type"] = "Type",
    ["@type.builtin"] = "Type",
    ["@operator"] = "Operator",
    ["@punctuation"] = "Identifier",
    ["@punctuation.bracket"] = "Identifier",
    ["@punctuation.delimiter"] = "Identifier",
    ["@punctuation.special"] = "Special",
    ["@comment"] = "Comment",
    ["@tag"] = "Keyword",
    ["@tag.attribute"] = "Function",
    ["@tag.delimiter"] = "Identifier",
    ["@namespace"] = "Type",
    ["@module"] = "Type",
    ["@lsp.type.variable"] = "@variable",
    ["@lsp.type.parameter"] = "@parameter",
    ["@lsp.type.property"] = "@property",
    ["@lsp.type.function"] = "@function",
    ["@lsp.type.method"] = "@function.method",
    ["@lsp.type.class"] = "@type",
    ["@lsp.type.namespace"] = "@namespace",
  }
  for from, to in pairs(ts) do
    hi(0, from, { link = to })
  end

  hi(0, "SignColumn", { bg = "NONE" })
  hi(0, "FoldColumn", { fg = c.color8, bg = "NONE" })
  hi(0, "Folded", { fg = c.color8, bg = subtle })
  hi(0, "NonText", { fg = c.color8 })
  hi(0, "Whitespace", { fg = subtle })
  hi(0, "EndOfBuffer", { fg = bg })
  hi(0, "ColorColumn", { bg = subtle })
  hi(0, "CursorColumn", { bg = subtle })
  hi(0, "QuickFixLine", { fg = selection_fg, bg = selection_bg, bold = true })
  hi(0, "Underlined", { underline = true })
  hi(0, "Error", { fg = c.color1 })
  hi(0, "Todo", { fg = bg, bg = c.color3, bold = true })
  hi(0, "FloatTitle", { fg = accent, bold = true })
  hi(0, "Substitute", { fg = bg, bg = c.color5 })
  hi(0, "SpellBad", { sp = c.color1, undercurl = true })
  hi(0, "SpellCap", { sp = c.color3, undercurl = true })
  hi(0, "SpellRare", { sp = c.color6, undercurl = true })
  hi(0, "SpellLocal", { sp = c.color2, undercurl = true })

  hi(0, "DiagnosticUnderlineError", { sp = c.color1, undercurl = true })
  hi(0, "DiagnosticUnderlineWarn", { sp = c.color3, undercurl = true })
  hi(0, "DiagnosticUnderlineInfo", { sp = c.color4, undercurl = true })
  hi(0, "DiagnosticUnderlineHint", { sp = c.color6, undercurl = true })
  hi(0, "DiagnosticVirtualTextError", { fg = c.color1, bg = "NONE" })
  hi(0, "DiagnosticVirtualTextWarn", { fg = c.color3, bg = "NONE" })
  hi(0, "DiagnosticVirtualTextInfo", { fg = c.color4, bg = "NONE" })
  hi(0, "DiagnosticVirtualTextHint", { fg = c.color6, bg = "NONE" })
  hi(0, "LspInlayHint", { fg = c.color8, bg = "NONE", italic = true })
  hi(0, "LspReferenceText", { bg = subtle })
  hi(0, "LspReferenceRead", { bg = subtle })
  hi(0, "LspReferenceWrite", { bg = subtle, bold = true })

  hi(0, "BlinkCmpMenu", { fg = fg, bg = c.color0 })
  hi(0, "BlinkCmpMenuBorder", { fg = c.color8, bg = "NONE" })
  hi(0, "BlinkCmpMenuSelection", { fg = selection_fg, bg = selection_bg, bold = true })
  hi(0, "BlinkCmpLabelMatch", { fg = accent, bold = true })
  hi(0, "BlinkCmpLabelDetail", { fg = c.color8 })
  hi(0, "BlinkCmpLabelDescription", { fg = c.color8 })
  hi(0, "BlinkCmpKind", { fg = c.color5 })
  hi(0, "BlinkCmpSource", { fg = c.color8 })
  hi(0, "BlinkCmpGhostText", { fg = c.color8, italic = true })
  hi(0, "BlinkCmpDoc", { fg = fg, bg = "NONE" })
  hi(0, "BlinkCmpDocBorder", { fg = c.color8, bg = "NONE" })

  hi(0, "SnacksPicker", { fg = fg, bg = "NONE" })
  hi(0, "SnacksPickerBorder", { fg = c.color8, bg = "NONE" })
  hi(0, "SnacksPickerTitle", { fg = accent, bold = true })
  hi(0, "SnacksPickerMatch", { fg = accent, bold = true })
  hi(0, "SnacksPickerCursorLine", { bg = subtle })
  hi(0, "SnacksPickerListCursorLine", { bg = subtle })
  hi(0, "SnacksPickerPrompt", { fg = c.color5, bold = true })
  hi(0, "SnacksPickerDir", { fg = c.color8 })
  hi(0, "SnacksIndent", { fg = subtle })
  hi(0, "SnacksIndentScope", { fg = c.color8 })
  hi(0, "SnacksNotifierInfo", { fg = c.color4 })
  hi(0, "SnacksNotifierWarn", { fg = c.color3 })
  hi(0, "SnacksNotifierError", { fg = c.color1 })
  hi(0, "SnacksInputBorder", { fg = accent })
  hi(0, "SnacksInputTitle", { fg = accent, bold = true })

  hi(0, "FlashLabel", { fg = bg, bg = c.color5, bold = true })
  hi(0, "FlashMatch", { fg = bg, bg = c.color4 })
  hi(0, "FlashCurrent", { fg = bg, bg = c.color3 })
  hi(0, "FlashBackdrop", { fg = c.color8 })

  hi(0, "WhichKey", { fg = accent, bold = true })
  hi(0, "WhichKeyGroup", { fg = c.color5 })
  hi(0, "WhichKeyDesc", { fg = fg })
  hi(0, "WhichKeySeparator", { fg = c.color8 })
  hi(0, "WhichKeyNormal", { bg = "NONE" })
  hi(0, "WhichKeyBorder", { fg = c.color8, bg = "NONE" })

  hi(0, "AerialLine", { bg = subtle })
  hi(0, "DropBarMenuCurrentContext", { bg = subtle })
  hi(0, "DropBarMenuHoverEntry", { fg = selection_fg, bg = selection_bg })

  hi(0, "OilDir", { fg = accent, bold = true })
  hi(0, "OilFile", { fg = fg })

  return true
end

M.themes = {
  {
    name = "System (matugen)",
    colorscheme = "matugen",
    custom_apply = function() return apply_matugen("ansi") end,
    after = function()
      transparent_winbar()
      transparent_float()
      transparent_neotree()
    end,
  },
  {
    name = "System (rich)",
    colorscheme = "matugen",
    custom_apply = function() return apply_matugen("rich") end,
    after = function()
      transparent_winbar()
      transparent_float()
      transparent_neotree()
    end,
  },
}

vim.g.THEME = vim.g.THEME or "System (matugen)"

function M.get_theme(name)
  for _, theme in ipairs(M.themes) do
    if theme.name == name then
      return theme
    end
  end
  return nil
end

function M.apply(name)
  local theme = M.get_theme(name)
  if not theme then
    return false
  end

  vim.g.THEME = name

  local ok
  if theme.custom_apply then
    ok = theme.custom_apply()
  else
    ok = pcall(vim.cmd.colorscheme, theme.colorscheme)
  end

  if ok then
    if theme.after then
      theme.after()
    end

    minicursorword()
    ts_context()
    mini_diff_overlay()
    flash_search()
    ts_lsp_bold_nodes()
    default_harpoon()
    transparent_statusline()
    diagnostics()

    if theme.custom_apply then
      vim.cmd("doautocmd ColorScheme " .. (theme.colorscheme or ""))
    end

    if theme.colorscheme == "matugen" then
      vim.schedule(function()
        if vim.g.colors_name ~= "matugen" then
          return
        end
        local hi = vim.api.nvim_set_hl
        hi(0, "DiagnosticError", { fg = "#f38ba8" })
        hi(0, "DiagnosticWarn", { fg = "#f9e2af" })
        hi(0, "DiagnosticInfo", { fg = "#89b4fa" })
        hi(0, "DiagnosticHint", { fg = "#a6e3a1" })
        hi(0, "GitSignsAdd", { fg = "#a6e3a1" })
        hi(0, "GitSignsChange", { fg = "#f9e2af" })
        hi(0, "GitSignsDelete", { fg = "#f38ba8" })
        hi(0, "DiffAdd", { fg = "#a6e3a1", bg = "NONE" })
        hi(0, "DiffChange", { fg = "#f9e2af", bg = "NONE" })
        hi(0, "DiffDelete", { fg = "#f38ba8", bg = "NONE" })
        hi(0, "llama_hl_fim_hint", { link = "Comment" })
        transparent_statusline()
      end)
    end
  end
  return ok
end

local group = vim.api.nvim_create_augroup("CoreColorscheme", { clear = true })

vim.api.nvim_create_autocmd("VimEnter", {
  group = group,
  nested = true,
  callback = function()
    M.apply(vim.g.THEME)
  end,
})

local function refresh_matugen()
  if not tostring(vim.g.THEME):match("^System %(") then
    return
  end
  local content = read_colors()
  if not content or #content == 0 or content == M._matugen_raw then
    return
  end
  M.apply(vim.g.THEME)
end

vim.api.nvim_create_autocmd("FocusGained", {
  group = group,
  callback = refresh_matugen,
})

function M.pick()
  local prev = vim.g.THEME
  local confirmed = false

  local items = {}
  local current_theme_item = nil

  for _, theme in ipairs(M.themes) do
    if theme.name == vim.g.THEME then
      current_theme_item = { text = theme.name, theme = theme }
      table.insert(items, current_theme_item)
      break
    end
  end

  for _, theme in ipairs(M.themes) do
    if theme.name ~= vim.g.THEME then
      table.insert(items, { text = theme.name, theme = theme })
    end
  end

  Snacks.picker.pick({
    title = "Colorschemes",
    items = items,
    preview = nil,
    layout = {
      preset = "select",
      layout = {
        height = #M.themes + 2,
        width = 20,
        min_width = 20,
      },
    },
    format = function(item)
      return { { item.theme.name } }
    end,
    confirm = function(picker, item)
      confirmed = true
      if item then
        M.apply(item.theme.name)
      end
      picker:close()
    end,
    on_show = function()
      vim.cmd.stopinsert()
    end,
    on_change = function(_, item)
      if item then
        M.apply(item.theme.name)
      end
    end,
    on_close = function()
      if not confirmed then
        M.apply(prev)
      end
    end,
  })
end

vim.keymap.set("n", "<leader>uc", M.pick, { desc = "Colorscheme picker" })

local matugen_watcher = vim.uv.new_fs_event()
if matugen_watcher then
  matugen_watcher:start(vim.fn.expand("~/.cache/matugen"), {}, vim.schedule_wrap(function(err, fname)
    if err or fname ~= "colors.json" then
      return
    end
    refresh_matugen()
  end))
end

return M
