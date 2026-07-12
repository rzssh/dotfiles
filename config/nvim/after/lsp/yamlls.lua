local schemastore_ok, schemastore = pcall(require, "schemastore")
if not schemastore_ok then
  vim.notify("schemastore plugin not found, cannot apply schemas.", vim.log.levels.WARN)
  schemastore = nil
end

local settings = {
  redhat = { telemetry = { enabled = false } },
}

if schemastore then
  settings.yaml = {
    schemas = schemastore.yaml.schemas(),
    schemaStore = { enable = false, url = "" },
  }
end

return {
  settings = settings,
}
