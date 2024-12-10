---@class Timber.Highlight.Module
---@field config Timber.Highlight.Config
---@field hl_insert integer
---@field hl_add_to_batch integer
---@field insert_hl_timer any
---@field add_to_batch_hl_timer any
local M = {}

---@param log_target TSNode
function M._highlight_add_to_batch(log_target)
  if not M.config.on_add_to_batch then
    return
  end

  local srow, scol, erow, ecol = log_target:range()
  vim.highlight.range(
    0,
    M.hl_add_to_batch,
    "Timber.AddToBatch",
    { srow, scol },
    { erow, ecol },
    { regtype = "v", inclusive = false }
  )

  M.add_to_batch_hl_timer:start(
    M.config.duration,
    0,
    vim.schedule_wrap(function()
      vim.api.nvim_buf_clear_namespace(0, M.hl_add_to_batch, 0, -1)
    end)
  )
end

---@param start_line_number number 0-indexed
---@param end_line_number? number 0-indexed
function M._highlight_insert(start_line_number, end_line_number)
  if not M.config.on_insert then
    return
  end

  vim.highlight.range(
    0,
    M.hl_insert,
    "Timber.Insert",
    { start_line_number, 0 },
    { end_line_number or start_line_number, 0 },
    { regtype = "V", inclusive = false }
  )

  M.insert_hl_timer:start(
    M.config.duration,
    0,
    vim.schedule_wrap(function()
      vim.api.nvim_buf_clear_namespace(0, M.hl_insert, 0, -1)
    end)
  )
end

function M._highlight_log_statement(line_number)
  vim.highlight.range(
    0,
    M.hl_log_statement,
    "Timber.LogStatement",
    { line_number, 0 },
    { line_number, 0 },
    { regtype = "V", inclusive = false }
  )
end

---@param opts Timber.Highlight.Config
function M.setup()
  M.config = require("timber.config").config.highlight

  M.hl_insert = vim.api.nvim_create_namespace("timber.insert_log")
  M.hl_add_to_batch = vim.api.nvim_create_namespace("timber.add_to_batch")
  M.hl_log_statement = vim.api.nvim_create_namespace("timber.log_statement")
  M.insert_hl_timer = vim.uv.new_timer()
  M.add_to_batch_hl_timer = vim.uv.new_timer()

  vim.api.nvim_set_hl(0, "Timber.Insert", { link = "Search", default = true })
  vim.api.nvim_set_hl(0, "Timber.AddToBatch", { link = "Search", default = true })

  local events = require("timber.events")
  events.on("actions:new_log_statement", function(log_statement)
    local inserted_rows = log_statement.inserted_rows
    for _, line in ipairs(inserted_rows) do
      M._highlight_log_statement(line)
    end

    M._highlight_insert(inserted_rows[1], inserted_rows[#inserted_rows])
  end)

  events.on("actions:add_to_batch", M._highlight_add_to_batch)
end

return M
