local M = {}

local config = require("timber.config")
local utils = require("timber.utils")

function M.search()
  local log_marker = config.config.log_marker

  if not log_marker or log_marker == "" then
    utils.notify("config.log_marker is not configured", "warn")
    return
  end

  require("telescope.builtin").grep_string({
    search = log_marker,
    prompt_title = "Log Statements (timber.nvim)",
  })
end

return M
