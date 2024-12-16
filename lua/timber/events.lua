-- A simple events pub-sub

---@class Timber.Events
---@field listeners table<string, fun(event: any)[]>
local M = { listeners = {} }

---@param event string
---@param listener fun(event: any)
function M.on(event, listener)
  if not M.listeners[event] then
    M.listeners[event] = {}
  end

  table.insert(M.listeners[event], listener)
end

---@param event string
function M.emit(event, ...)
  if not M.listeners[event] then
    return
  end

  for _, listener in ipairs(M.listeners[event]) do
    listener(...)
  end
end

function M.clear()
  M.listeners = {}
end

return M
