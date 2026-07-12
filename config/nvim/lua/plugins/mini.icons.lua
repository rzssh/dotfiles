local M = {}

M.plugin = {
  "nvim-mini/mini.icons",
  lazy = false,
  config = function()
    local mini_icons = require("mini.icons")
    mini_icons.setup({ file = M.file_icon_config })
    mini_icons.mock_nvim_web_devicons()
  end,
}

M.icons = {
  eslint = { glyph = "󰱺", hl = "MiniIconsPurple" },
  prettier = { glyph = "", hl = "MiniIconsPurple" },
  node = { glyph = "", hl = "MiniIconsGreen" },
  npm = { glyph = "", hl = "MiniIconsRed" },
  yarn = { glyph = "", hl = "MiniIconsBlue" },
  pnpm = { glyph = "", hl = "MiniIconsOrange" },
  tsconfig_json = { glyph = "", hl = "MiniIconsAzure" },
  env = { glyph = "", hl = "MiniIconsWhite" },
  vite = { glyph = "", hl = "MiniIconsPurple" },
  vitest = { glyph = "", hl = "MiniIconsYellow" },
  playwright = { glyph = "", hl = "MiniIconsCyan" },
  postcss = { glyph = "", hl = "MiniIconsRed" },
  tailwind = { glyph = "", hl = "MiniIconsAzure" },
}

M.file_icon_config = {
  [".eslintignore"] = M.icons.eslint,
  [".eslintrc.js"] = M.icons.eslint,
  [".eslintrc.cjs"] = M.icons.eslint,
  [".eslintrc.mjs"] = M.icons.eslint,

  ["eslint.config.js"] = M.icons.eslint,
  ["eslint.config.cjs"] = M.icons.eslint,
  ["eslint.config.mjs"] = M.icons.eslint,

  [".prettierignore"] = M.icons.prettier,
  [".prettierrc"] = M.icons.prettier,
  [".prettierrc.js"] = M.icons.prettier,
  [".prettierrc.cjs"] = M.icons.prettier,
  [".prettierrc.mjs"] = M.icons.prettier,

  ["prettier.config.js"] = M.icons.prettier,
  ["prettier.config.cjs"] = M.icons.prettier,
  ["prettier.config.mjs"] = M.icons.prettier,

  [".npmrc"] = M.icons.npm,
  [".node-version"] = M.icons.node,
  [".nvmrc"] = M.icons.node,
  ["package.json"] = M.icons.node,

  [".yarnrc.yml"] = M.icons.yarn,
  ["yarn.lock"] = M.icons.yarn,

  ["pnpm-lock.yaml"] = M.icons.pnpm,
  ["pnpm-workspace.yaml"] = M.icons.pnpm,

  ["tsconfig.json"] = M.icons.tsconfig_json,
  ["tsconfig.build.json"] = M.icons.tsconfig_json,

  [".env"] = M.icons.env,
  [".env.example"] = M.icons.env,
  [".env.development"] = M.icons.env,
  [".env.test"] = M.icons.env,
  [".env.production"] = M.icons.env,

  ["vite.config.ts"] = M.icons.vite,
  ["vite.config.js"] = M.icons.vite,

  ["vitest.config.ts"] = M.icons.vite,
  ["vitest.config.js"] = M.icons.vite,

  ["playwright.config.ts"] = M.icons.playwright,
  ["playwright.config.js"] = M.icons.playwright,

  ["postcss.config.js"] = M.icons.postcss,
  ["postcss.config.ts"] = M.icons.postcss,
  ["postcss.config.mjs"] = M.icons.postcss,
  ["postcss.config.cjs"] = M.icons.postcss,
  ["postcss.config.mts"] = M.icons.postcss,
  ["postcss.config.cts"] = M.icons.postcss,

  ["tailwind.config.js"] = M.icons.tailwind,
  ["tailwind.config.ts"] = M.icons.tailwind,
  ["tailwind.config.mjs"] = M.icons.tailwind,
  ["tailwind.config.cjs"] = M.icons.tailwind,
  ["tailwind.config.mts"] = M.icons.tailwind,
  ["tailwind.config.cts"] = M.icons.tailwind,
}

return M.plugin
