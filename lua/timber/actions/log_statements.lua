local M = {}

---@param log_marker string
function M.iter_global(log_marker)
  vim.cmd(string.format("silent! grep! %s", log_marker))

  local qf_list = vim.fn.getqflist()

  -- Sort quickfix entries by buffer and line number (in reverse)
  table.sort(qf_list, function(a, b)
    if a.bufnr == b.bufnr then
      return a.lnum > b.lnum
    end
    return a.bufnr > b.bufnr
  end)

  -- Iterator function
  local i = 0
  return function()
    i = i + 1
    local item = qf_list[i]
    if item then
      return item.bufnr, item.lnum
    end
  end
end

---@param log_marker string
function M.iter_local(log_marker)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local lines_to_delete = {}

  for i, line in ipairs(lines) do
    if string.find(line, log_marker, 1, true) then
      table.insert(lines_to_delete, i)
    end
  end

  -- Iterator function
  local i = #lines_to_delete
  return function()
    if i > 0 then
      local item = lines_to_delete[i]
      i = i - 1
      return item
    end
  end
end

return M
