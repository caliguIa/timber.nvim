local watcher = require("timber.watcher")
local utils = require("timber.utils")

local M = {}

---@param entries Timber.Buffers.LogPlaceholderEntries[]
---@return string[] lines
---@return integer[] separators 0-indexed line numbers of separator lines
---@return string title
---@return string footer
local function win_content(entries)
  local entry_lines = {}
  for _, content in ipairs(entries) do
    table.insert(entry_lines, vim.split(content.body, "\n"))
  end

  -- Get the max width of the content
  local max_width = 20
  for _, lines in ipairs(entry_lines) do
    for _, line in ipairs(lines) do
      max_width = math.max(max_width, #line)
    end
  end

  local buf_content = {}
  local separators = {}
  local line_count = 0

  for i, lines in ipairs(entry_lines) do
    vim.list_extend(buf_content, lines)
    line_count = line_count + #lines

    if i < #entries then
      table.insert(buf_content, "")
      table.insert(separators, line_count)
      line_count = line_count + 1
    end
  end

  -- TODO: handle multiple sources
  local source_id = entries[1].source_id
  local source = watcher.get_source(source_id)
  assert(source, string.format("Unrecognized watcher source '%s'", source_id))

  local title = source.name
  local footer = #entries > 1 and string.format("%d entries", #entries) or ""

  return buf_content, separators, title, footer
end

local function close_win(winnr, bufnrs)
  vim.schedule(function()
    -- exit if we are in one of ignored buffers
    if bufnrs and vim.list_contains(bufnrs, vim.api.nvim_get_current_buf()) then
      return
    end

    local augroup = "preview_window_" .. winnr
    pcall(vim.api.nvim_del_augroup_by_name, augroup)
    pcall(vim.api.nvim_win_close, winnr, true)
  end)
end

local function win_sizes(lines)
  local screen_width = vim.api.nvim_win_get_width(0)
  local screen_height = vim.api.nvim_win_get_height(0)
  local max_width = math.floor(screen_width * 0.8)
  local max_height = math.floor(screen_height * 0.8)

  local width = 0
  for _, line in ipairs(lines) do
    local line_width = vim.api.nvim_strwidth(line)
    width = math.max(width, line_width)
  end

  local height = math.min(#lines, max_height)
  width = math.min(width, max_width)

  return width, height
end

local function win_options(width, height)
  local anchor = ""
  local row, col

  local lines_above = vim.fn.winline() - 1
  local lines_below = vim.fn.winheight(0) - lines_above

  local anchor_below = lines_below > lines_above

  local border_height = 1
  if anchor_below then
    anchor = anchor .. "N"
    height = math.max(math.min(lines_below - border_height, height), 0)
    row = 1
  else
    anchor = anchor .. "S"
    height = math.max(math.min(lines_above - border_height, height), 0)
    row = 0
  end

  local wincol = vim.fn.wincol()

  if wincol + width <= vim.o.columns then
    anchor = anchor .. "W"
    col = 0
  else
    anchor = anchor .. "E"
    col = 1
  end

  return {
    anchor = anchor,
    row = row,
    col = col,
    width = width,
    height = height,
    focusable = true,
    relative = "cursor",
    style = "minimal",
    border = "single",
    zindex = 50,
  }
end
---@param lines string[]
---@param window_opts table
---@param buffer_opts table?
---@return integer floating_winnr
---@return integer floating_bufnr
local function open_win(lines, window_opts, buffer_opts)
  buffer_opts = vim.tbl_extend(
    "force",
    { modifiable = false, readonly = true, bufhidden = "delete", swapfile = false },
    buffer_opts or {}
  )

  -- Create buffer for main content
  local floating_bufnr = vim.api.nvim_create_buf(false, true)
  local floating_winnr = vim.api.nvim_open_win(floating_bufnr, false, window_opts)
  vim.api.nvim_buf_set_lines(floating_bufnr, 0, -1, true, lines)

  for option, value in pairs(buffer_opts) do
    vim.api.nvim_set_option_value(option, value, { buf = floating_bufnr })
  end

  -- q to close the floating window
  vim.api.nvim_buf_set_keymap(
    floating_bufnr,
    "n",
    "q",
    "<cmd>bdelete<cr>",
    { silent = true, noremap = true, nowait = true }
  )

  local augroup = vim.api.nvim_create_augroup("preview_window_" .. floating_winnr, {
    clear = true,
  })

  -- close the preview window when entered a buffer that is not
  -- the floating window buffer or the buffer that spawned it
  local current_bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_create_autocmd("BufEnter", {
    group = augroup,
    callback = function()
      close_win(floating_bufnr, { current_bufnr, floating_bufnr })
    end,
  })

  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "InsertCharPre" }, {
    group = augroup,
    buffer = current_bufnr,
    callback = function()
      close_win(floating_winnr)
    end,
  })

  return floating_bufnr, floating_winnr
end

---Render a floating window showing placeholder content
---@param placeholder Timber.Buffers.LogPlaceholder
---@param opts? { silent?: boolean }
function M.open(placeholder, opts)
  opts = vim.tbl_extend("force", { silent = false }, opts or {})

  if not placeholder.entries or #placeholder.entries == 0 then
    if not opts.silent then
      utils.notify("Log placeholder has no content", "warn")
    end

    return
  end

  local lines, separators, title, footer = win_content(placeholder.entries)
  local width, height = win_sizes(lines)
  local window_opts = win_options(width, height)
  window_opts = vim.tbl_extend("force", window_opts, {
    width = math.max(window_opts.width, #title + 2),
    title = title,
    title_pos = "center",
    footer = footer,
    footer_pos = "right",
  })

  -- TODO: handle multiple sources
  local source_id = placeholder.entries[1].source_id
  local source = require("timber.watcher").get_source(source_id)
  assert(source, string.format("Unrecognized watcher source '%s'", source_id))

  local bufnr, winnr = open_win(lines, window_opts, source.buffer)
  vim.api.nvim_win_set_hl_ns(winnr, M.highlight_ns)

  for _, i in ipairs(separators) do
    vim.api.nvim_buf_set_extmark(bufnr, M.highlight_ns, i, 0, {
      virt_text_win_col = -1,
      virt_text = { { string.rep("-", vim.go.columns), "Timber.FloatingWindowEntrySeparator" } },
      priority = 100,
    })
  end
end

function M.setup()
  M.highlight_ns = vim.api.nvim_create_namespace("timber.buffers.win")

  vim.api.nvim_set_hl(M.highlight_ns, "FloatFooter", { link = "CursorLineNr", force = true })
  vim.api.nvim_set_hl(M.highlight_ns, "Timber.FloatingWindowEntrySeparator", { link = "FloatBorder" })
end

return M
