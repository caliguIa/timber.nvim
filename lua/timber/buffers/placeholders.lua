-- A registry of log placeholders in buffers

local utils = require("timber.utils")

---@class Timber.Buffers.LogPlaceholderRegistry
---@field placeholders Timber.Buffers.LogPlaceholder[] List of log placeholders
local M = {}

function M.new()
  local o = {
    placeholders = {},
  }

  setmetatable(o, M)
  M.__index = M
  return o
end

---Find a log placeholder by id
---@param id Timber.Watcher.LogPlaceholderId
---@return Timber.Buffers.LogPlaceholder?
function M:get(id)
  for _, placeholder in ipairs(self.placeholders) do
    if placeholder.id == id then
      return placeholder
    end
  end
end

---Add a log placeholder to the registry. Noop if the placeholder already exists
---@param placeholder Timber.Buffers.LogPlaceholder
function M:add(placeholder)
  local existing = placeholder.id and self:get(placeholder.id) or nil
  if not existing then
    table.insert(self.placeholders, placeholder)
  end
end

---Remove a log placeholder
---@param id Timber.Watcher.LogPlaceholderId
function M:remove(id)
  self.placeholders = utils.array_filter(self.placeholders, function(placeholder)
    return placeholder.id ~= id
  end)
end

function M:clear()
  self.placeholders = {}
end

---Remove a log placeholder by extmark id. The extmark id is unique to a buffer so we need to pass in bufnr as well
---@param extmark_id integer
---@param bufnr integer
function M:remove_by_extmark_id(extmark_id, bufnr)
  self.placeholders = utils.array_filter(self.placeholders, function(placeholder)
    return placeholder.extmark_id ~= extmark_id or placeholder.bufnr ~= bufnr
  end)
end

---Return all log placeholders in a buffer
---@param bufnr integer
function M:buffer_placeholders(bufnr)
  return utils.array_filter(self.placeholders, function(placeholder)
    return placeholder.bufnr == bufnr
  end)
end

return M
