---@class Timber.Highlight.Module
---@field config Timber.Highlight.Config
---@field flash_hl_ns integer
---@field insert_hl_timer any
---@field add_to_batch_hl_timer any
local M = {}

---@param log_target TSNode
function M._highlight_add_to_batch(log_target)
  if not M.config.on_add_to_batch then
    return
  end

  local srow, scol, erow, ecol = log_target:range()

  vim.api.nvim_buf_set_extmark(0, M.flash_hl_ns, srow, scol, {
    hl_group = "Timber.AddToBatch",
    end_row = erow,
    end_col = ecol,
    priority = 100,
  })

  M.add_to_batch_hl_timer:start(
    M.config.duration,
    0,
    vim.schedule_wrap(function()
      vim.api.nvim_buf_clear_namespace(0, M.flash_hl_ns, 0, -1)
    end)
  )
end

---@param bufnr integer
---@param start_line_number number 0-indexed
---@param end_line_number? number 0-indexed
---@param hl_group string
---@param all_line boolean Whether to highlight all line, or just to the final character
function M.highlight_lines(bufnr, start_line_number, end_line_number, hl_group, all_line)
  if not M.config.on_insert then
    return
  end

  if all_line then
    vim.api.nvim_buf_set_extmark(bufnr, M.flash_hl_ns, start_line_number, 0, {
      line_hl_group = hl_group,
      end_row = end_line_number,
      priority = 500,
    })
  else
    end_line_number = end_line_number or start_line_number
    local line_text = vim.api.nvim_buf_get_lines(bufnr, end_line_number, end_line_number + 1, false)[1]
    vim.api.nvim_buf_set_extmark(bufnr, M.flash_hl_ns, start_line_number, 0, {
      hl_group = hl_group,
      end_row = end_line_number,
      end_col = line_text and #line_text or 0,
      priority = 200,
    })
  end

  M.insert_hl_timer:start(
    M.config.duration,
    0,
    vim.schedule_wrap(function()
      vim.api.nvim_buf_clear_namespace(bufnr, M.flash_hl_ns, 0, -1)
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

function M.setup()
  M.config = require("timber.config").config.highlight

  M.flash_hl_ns = vim.api.nvim_create_namespace("timber.flash_highlight")
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

    M.highlight_lines(0, inserted_rows[1], inserted_rows[#inserted_rows], "Timber.Insert", false)
  end)

  events.on("actions:add_to_batch", M._highlight_add_to_batch)
end

return M
