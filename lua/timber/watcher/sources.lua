---Manage sources for watcher
---Sources are data sources that can output log result. Supported sources are:
---  1. Filesystem
---  2. Neotest

---@alias Timber.Watcher.SourceSpec (Timber.Watcher.Sources.FilesystemSpec | Timber.Watcher.Sources.NeotestSpec)

---@class Timber.Watcher.Sources.FilesystemSpec
---@field name string
---@field path string
---@field buffer table<string, any>? A table of buffer options to apply to the float buffer.
---@field type "filesystem"

---@class Timber.Watcher.Sources.NeotestSpec
---@field name string
---@field buffer table<string, any>? A table of buffer options to apply to the float buffer.
---@field type "neotest"

---@alias source_id string

---@class Timber.Watcher.Sources.Opts
---@field sources table<source_id, Timber.Watcher.SourceSpec>
---@field on_log_capture fun(log_entry: Timber.Watcher.LogEntry)

local M = {
  sources = {},
  source_sequences = vim.defaulttable(function()
    return 0
  end),
}

---@param opts Timber.Watcher.Sources.Opts
function M.setup(opts)
  for source_id, source in pairs(opts.sources) do
    local source_module = require("timber.watcher.sources." .. source.type)
    local source_instance = source_module.new(source, function(placeholder_id, payload)
      opts.on_log_capture({
        log_placeholder_id = placeholder_id,
        payload = payload,
        source_id = source_id,
        timestamp = os.time(),
        sequence = M.source_sequences[source_id],
      })

      M.source_sequences[source_id] = M.source_sequences[source_id] + 1
    end)

    source_instance:start()
    table.insert(M.sources, source_instance)
  end

  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = M.stop,
  })
end

function M.stop()
  for _, source in ipairs(M.sources) do
    source:stop()
  end
end

return M
