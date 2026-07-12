local schemastore_ok, schemastore = pcall(require, "schemastore")
if not schemastore_ok then
  vim.notify("schemastore plugin not found, cannot apply schemas.", vim.log.levels.WARN)
  schemastore = nil
end

local settings = {
  redhat = { telemetry = { enabled = false } },
}

if schemastore then
  settings.json = {
    schemas = schemastore.json.schemas(),
    validate = { enable = true },
  }
end

return {
  init_options = {
    provideFormatter = false,
  },
  settings = settings,
}
