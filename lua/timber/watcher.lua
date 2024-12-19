---@class Timber.Watcher.LogEntry
---@field log_placeholder_id string
---@field payload string
---@field source_id string
---@field timestamp integer
---@field sequence integer Auto-incremented sequence number. This is used to determine the order of a log entries from a same source

---@alias Timber.Watcher.LogPlaceholderId string

local sources = require("timber.watcher.sources")
local events = require("timber.events")

local M = { MARKER = "🪵", ID_LENGTH = 3, sources = {} }

function M.generate_unique_id()
  local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  local id = ""

  for _ = 1, M.ID_LENGTH, 1 do
    local random_index = math.random(1, #chars)
    id = id .. string.sub(chars, random_index, random_index)
  end

  return id
end

---Generate marker start and end strings
---@return string start_marker, string end_marker, string marker_id
function M.generate_marker_pairs()
  local id = M.generate_unique_id()
  local start = M.MARKER .. id
  local end_ = id
  return start, end_, id
end

---@param source_specs table<string, Timber.Watcher.SourceSpec>
function M.setup(source_specs)
  math.randomseed(os.time())

  M.sources = source_specs
  sources.setup({
    sources = source_specs,
    on_log_capture = function(log_entry)
      events.emit("watcher:new_log_entry", log_entry)
    end,
  })
end

---Get a source by name
---@param id string
---@return Timber.Watcher.SourceSpec? source
function M.get_source(id)
  return M.sources[id]
end

return M
