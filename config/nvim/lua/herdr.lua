local api = vim.api

local M = { target = nil }

local function herdr(args)
  local cmd = { "herdr" }
  vim.list_extend(cmd, args)
  return vim.system(cmd, { text = true }):wait()
end

local function fail(res)
  vim.notify("herdr: " .. ((res.stderr or res.stdout or ""):gsub("%s+$", "")), vim.log.levels.ERROR)
end

local function panes()
  local args = { "pane", "list" }
  if vim.env.HERDR_WORKSPACE_ID then
    vim.list_extend(args, { "--workspace", vim.env.HERDR_WORKSPACE_ID })
  end
  local res = herdr(args)
  if res.code ~= 0 then
    fail(res)
    return nil
  end
  local ok, data = pcall(vim.json.decode, res.stdout or "")
  if not ok or type(data) ~= "table" or not data.result then
    vim.notify("herdr: unexpected response (server running?)", vim.log.levels.ERROR)
    return nil
  end
  return data.result.panes or {}
end

local function fleetpit(args)
  local cmd = { "fleetpit" }
  if vim.env.HERDR_WORKSPACE_ID then
    vim.list_extend(cmd, { "--workspace", vim.env.HERDR_WORKSPACE_ID })
  end
  vim.list_extend(cmd, args)
  local ok, res = pcall(function()
    return vim.system(cmd, { text = true }):wait()
  end)
  if not ok or res.code ~= 0 then
    return nil
  end
  local decoded, data = pcall(vim.json.decode, res.stdout or "")
  return decoded and data or nil
end

local function role_pane(role)
  local data = fleetpit({ "role", "get", role, "--json" })
  if type(data) == "table" and type(data.pane_id) == "string" and data.pane_id ~= "" then
    return data.pane_id
  end
  return nil
end

local function agent_panes()
  local all = panes()
  if not all then
    return nil
  end
  local self_id = vim.env.HERDR_PANE_ID
  local list = vim.tbl_filter(function(p)
    return type(p.agent) == "string" and p.pane_id ~= self_id
  end, all)
  local roles = fleetpit({ "role", "list", "--json" })
  if type(roles) == "table" then
    local by_pane = {}
    for _, r in ipairs(roles) do
      if type(r.pane_id) == "string" and r.pane_id ~= "" then
        by_pane[r.pane_id] = r.role
      end
    end
    for _, p in ipairs(list) do
      p.fleet_role = by_pane[p.pane_id]
    end
  end
  return list
end

local function label(p)
  return ("%s  [%s]  %s  %s"):format(
    p.fleet_role or (type(p.agent) == "string" and p.agent) or "?",
    p.agent_status or "?",
    vim.fn.fnamemodify(p.cwd or "?", ":t"),
    p.pane_id
  )
end

local function select_pane(prompt, cb)
  local list = agent_panes()
  if not list or #list == 0 then
    vim.notify("herdr: no panes (is a session running?)", vim.log.levels.WARN)
    return
  end
  vim.ui.select(list, { prompt = prompt, format_item = label }, function(choice)
    if choice then
      M.target = choice.pane_id
      cb(choice.pane_id)
    end
  end)
end

local function resolve(cb)
  local list = agent_panes()
  if not list or #list == 0 then
    vim.notify("herdr: no panes (is a session running?)", vim.log.levels.WARN)
    return
  end
  if M.target then
    for _, p in ipairs(list) do
      if p.pane_id == M.target then
        return cb(M.target)
      end
    end
  end
  if #list == 1 then
    M.target = list[1].pane_id
    return cb(M.target)
  end
  select_pane("herdr agent", cb)
end

local function submit(pane, text)
  local res = herdr({ "pane", "send-text", pane, text })
  if res.code ~= 0 then
    fail(res)
    return false
  end
  herdr({ "pane", "send-keys", pane, "enter" })
  return true
end

local function read_float(pane)
  local res = herdr({ "pane", "read", pane, "--source", "recent-unwrapped" })
  if res.code ~= 0 then
    fail(res)
    return
  end
  local buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(res.stdout or "", "\n"))
  vim.bo[buf].filetype = "markdown"
  local w = math.min(math.floor(vim.o.columns * 0.8), 120)
  local h = math.min(math.floor(vim.o.lines * 0.8), 40)
  api.nvim_open_win(buf, true, {
    relative = "editor",
    width = w,
    height = h,
    col = math.floor((vim.o.columns - w) / 2),
    row = 2,
    border = "single",
    title = " herdr " .. pane .. " ",
  })
end

local function wait_for(pane, status, timeout, cb)
  vim.system(
    { "herdr", "wait", "agent-status", pane, "--status", status, "--timeout", tostring(timeout) },
    { text = true },
    vim.schedule_wrap(function(r)
      cb(r)
    end)
  )
end

function M.send(text)
  if not text or text == "" then
    return
  end
  resolve(function(pane)
    if submit(pane, text) then
      vim.notify("herdr → " .. pane, vim.log.levels.INFO)
    end
  end)
end

function M.send_role(role, text)
  if not text or text == "" then
    return
  end
  local pane = role_pane(role)
  if not pane then
    vim.notify("herdr: role not active: " .. role, vim.log.levels.WARN)
    return
  end
  if submit(pane, text) then
    vim.notify("herdr → " .. role .. " (" .. pane .. ")", vim.log.levels.INFO)
  end
end

function M.send_wait(text)
  if not text or text == "" then
    return
  end
  resolve(function(pane)
    if not submit(pane, text) then
      return
    end
    vim.notify("herdr → " .. pane .. " (working…)", vim.log.levels.INFO)
    wait_for(pane, "working", 4000, function()
      wait_for(pane, "idle", 600000, function()
        read_float(pane)
      end)
    end)
  end)
end

local function visual_text()
  local mode = vim.fn.mode()
  local a, b = vim.fn.getpos("v"), vim.fn.getpos(".")
  local text = table.concat(vim.fn.getregion(a, b, { type = mode }), "\n")
  local l1, l2 = math.min(a[2], b[2]), math.max(a[2], b[2])
  return ("%s:%d-%d\n```%s\n%s\n```"):format(vim.fn.expand("%:."), l1, l2, vim.bo.filetype, text)
end

local function buffer_text()
  local name = vim.fn.expand("%:.")
  local body = table.concat(api.nvim_buf_get_lines(0, 0, -1, false), "\n")
  return ("%s:\n```%s\n%s\n```"):format(name, vim.bo.filetype, body)
end

local function diagnostics_text()
  local out = {}
  for _, d in ipairs(vim.diagnostic.get(0)) do
    out[#out + 1] = ("L%d: %s"):format(d.lnum + 1, d.message)
  end
  if #out == 0 then
    vim.notify("herdr: no diagnostics", vim.log.levels.INFO)
    return nil
  end
  return "Fix these diagnostics in " .. vim.fn.expand("%:.") .. ":\n" .. table.concat(out, "\n")
end

function M.read()
  resolve(read_float)
end

function M.setup()
  local map = vim.keymap.set
  map("v", "<leader>Hs", function() M.send(visual_text()) end, { desc = "Send selection" })
  map("v", "<leader>Hw", function() M.send_wait(visual_text()) end, { desc = "Send selection + await reply" })
  map("v", "<leader>Hb", function() M.send_role("build", visual_text()) end, { desc = "Send selection to build role" })
  map("v", "<leader>Hl", function() M.send_role("lead", visual_text()) end, { desc = "Send selection to lead role" })
  map("n", "<leader>Hf", function() M.send(buffer_text()) end, { desc = "Send file" })
  map("n", "<leader>HD", function() M.send(diagnostics_text()) end, { desc = "Send diagnostics" })
  map("n", "<leader>Hr", M.read, { desc = "Read agent output" })
  map("n", "<leader>Ha", function()
    select_pane("herdr agent", function(pane)
      vim.notify("herdr → " .. pane, vim.log.levels.INFO)
    end)
  end, { desc = "Pick agent" })

  local wk_ok, wk = pcall(require, "which-key")
  if wk_ok then
    wk.add({ { "<leader>H", group = "Herdr", icon = { icon = "󰙴", color = "green" } } })
  end
end

return M
