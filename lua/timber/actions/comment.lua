local M = {}

local config = require("timber.config")
local utils = require("timber.utils")
local log_statements = require("timber.actions.log_statements")

-- Using grep to search all files globally
local function toggle_comment_global(log_marker)
  local processed = {}

  for bufnr, lnum in log_statements.iter_global(log_marker) do
    vim.api.nvim_buf_call(bufnr, function()
      vim.api.nvim_win_set_cursor(0, { lnum, 0 })
      vim.cmd("normal gcc")
    end)

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

---@param opts {global: boolean}
function M.toggle_comment(opts)
  local log_marker = config.config.log_marker

  if not log_marker or log_marker == "" then
    utils.notify("config.log_marker is not configured", "warn")
    return
  end

  if opts.global then
    toggle_comment_global(log_marker)
  else
    for linenr in log_statements.iter_local(log_marker) do
      vim.api.nvim_win_set_cursor(0, { linenr, 0 })
      vim.cmd("normal gcc")
    end
  end
end

return M
