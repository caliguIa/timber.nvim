local M = {}

local config = require("timber.config")
local utils = require("timber.utils")

-- Using grep to search all files globally
local function clear_global(log_marker)
  vim.cmd(string.format("silent! grep! %s", log_marker))

  local qf_list = vim.fn.getqflist()
  local processed = {}

  -- Sort quickfix entries by buffer and line number (in reverse)
  table.sort(qf_list, function(a, b)
    if a.bufnr == b.bufnr then
      return a.lnum > b.lnum
    end
    return a.bufnr > b.bufnr
  end)

  -- Delete lines (starting from bottom to preserve line numbers)
  for _, item in ipairs(qf_list) do
    local bufnr = item.bufnr
    local lnum = item.lnum

    -- Delete the line
    vim.api.nvim_buf_set_lines(bufnr, lnum - 1, lnum, false, {})

    -- Mark buffer as modified
    if not processed[bufnr] then
      processed[bufnr] = true
    end
  end

  -- Save all modified buffers
  for bufnr, _ in pairs(processed) do
    vim.api.nvim_buf_call(bufnr, function()
      vim.cmd("silent! write")
    end)
  end
end

local function clear_local(log_marker)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local lines_to_delete = {}

  for i, line in ipairs(lines) do
    -- Escape all non-word characters
    if string.find(line, log_marker, 1, true) then
      table.insert(lines_to_delete, i)
    end
  end

  -- Delete lines from bottom to top
  -- We don't want the line number shifting
  for i = #lines_to_delete, 1, -1 do
    local line_num = lines_to_delete[i]
    vim.api.nvim_buf_set_lines(0, line_num - 1, line_num, false, {})
  end
end

---@param opts {global: boolean}
function M.clear(opts)
  local log_marker = config.config.log_marker

  if not log_marker or log_marker == "" then
    utils.notify("config.log_marker is not configured", "warn")
    return
  end

  if opts.global then
    clear_global(log_marker)
  else
    clear_local(log_marker)
  end
end

return M
