-- Display the captured log output inside a window

local events = require("timber.events")
local config = require("timber.config")
local buffers = require("timber.buffers")
local watcher = require("timber.watcher")
local highlight = require("timber.highlight")
local utils = require("timber.utils")

---@class Timber.Summary.EntryRange
---@field placeholder_id Timber.Watcher.LogPlaceholderId
---@field start integer
---@field end integer

---@class Timber.Summary
---@field log_entries Timber.Watcher.LogEntry[]
---@field ranges Timber.Summary.EntryRange[] The range of lines for log entries, sorted ascending by start line
---@field highlight_placeholder string? The placeholder id currently being highlighted
---@field attach_winnr integer? Win ID which summary is attached to
---@field winnr integer? Summary win ID
---@field bufnr integer? Summary buf ID
local M = {
  log_entries = {},
  ranges = {},
  highlight_placeholder = nil,
  winnr = nil,
  bufnr = nil,
}

M.CURSOR_TRACKING_DEBOUNCE = 250

function M._clear_log_entry_highlight()
  vim.api.nvim_buf_clear_namespace(M.bufnr, M.summary_focus_ns, 0, -1)
  M.highlight_placeholder = nil
end

---@param placeholder_id string
---@param force boolean? Whether to highlight the header despite already highlighted. Defaults to `false`
function M._highlight_log_entry(placeholder_id, force)
  force = force or false

  if M.highlight_placeholder == placeholder_id and not force then
    return
  end

  -- If the placeholder is already highlighted, clear the highlight
  if M.highlight_placeholder and M.highlight_placeholder ~= placeholder_id then
    M._clear_log_entry_highlight()
  end

  if not M.bufnr then
    return
  end

  vim
    .iter(M.ranges)
    :filter(function(range)
      return range.placeholder_id == placeholder_id
    end)
    :each(function(range)
      vim.api.nvim_buf_set_extmark(M.bufnr, M.summary_focus_ns, range.start, 0, {
        end_row = range["end"] - 2,
        line_hl_group = "Timber.SummaryEntryBodyHighlighted",
      })
    end)

  M.highlight_placeholder = placeholder_id
end

---@param winnr integer
---@param placeholder_id string
function M._scroll_log_entry_into_view(winnr, placeholder_id)
  ---@type Timber.Summary.EntryRange?
  local range = vim.iter(M.ranges):find(function(range)
    return range.placeholder_id == placeholder_id
  end)

  if range then
    vim.api.nvim_win_set_cursor(winnr, { range.start, 0 })
    vim.cmd("normal! zz")
  end
end

function M._track_cursor_movement()
  local group = vim.api.nvim_create_augroup("timber.summary", { clear = true })
  local timer = vim.uv.new_timer()

  local autocmd_id = vim.api.nvim_create_autocmd("CursorMoved", {
    group = group,
    callback = function(metadata)
      if metadata.buf == M.bufnr then
        return
      end

      -- Debounce the cursor tracking callback
      if timer:is_active() then
        timer:stop()
      end

      timer:start(
        M.CURSOR_TRACKING_DEBOUNCE,
        0,
        vim.schedule_wrap(function()
          local placeholder_id = buffers.get_current_line_placeholder()

          if placeholder_id then
            M._highlight_log_entry(placeholder_id)
          else
            M._clear_log_entry_highlight()
          end
        end)
      )
    end,
  })

  return function()
    vim.api.nvim_del_autocmd(autocmd_id)
    timer:stop()
  end
end

---@param entry Timber.Watcher.LogEntry
---@param show_source_name boolean
function M._separator_line(entry, show_source_name)
  local source = watcher.get_source(entry.source_id)
  local source_name = source and source.name or "unknown"
  local result = watcher.MARKER .. entry.log_placeholder_id

  if show_source_name then
    result = result .. string.format(" (%s)", source_name)
  end

  return result
end

---Only show the source name if there are more than one sources
function M._should_show_source_name(entries)
  local source_count = 0
  local seen = {}
  for _, entry in ipairs(entries) do
    if not seen[entry.source_id] then
      seen[entry.source_id] = true
      source_count = source_count + 1
    end
  end

  return source_count > 1
end

function M._make_win(buf)
  local win_config = require("timber.config").config.log_summary.win

  local width = win_config.width
  if type(width) == "number" then
    width = { width }
  end

  local screen_width = vim.api.nvim_win_get_width(0)
  local smallest_width

  for _, w in ipairs(width) do
    local w1
    if w < 1 and w > 0 then
      w1 = screen_width * w
    else
      w1 = w
    end

    smallest_width = smallest_width and math.min(smallest_width, w1) or w1
  end

  local win = vim.api.nvim_open_win(buf, false, {
    width = math.floor(smallest_width),
    style = "minimal",
    split = win_config.position,
  })

  for option, value in pairs(win_config.opts) do
    vim.api.nvim_set_option_value(option, value, { win = win })
  end

  return win
end

function M._make_buffer(log_entries)
  local buf = vim.api.nvim_create_buf(false, true)

  local seen = {}
  local uniq_sources = {}

  for _, entry in ipairs(log_entries) do
    if not seen[entry.source_id] then
      seen[entry.source_id] = true
      table.insert(uniq_sources, entry.source_id)
    end
  end

  local opts = {
    modifiable = false,
    buftype = "nofile",
    swapfile = false,
  }

  -- If there's only one source, apply the source buffer opts
  -- to the summary buffer
  -- We optimize for this case because it's the most common path
  if #uniq_sources == 1 then
    local source = watcher.get_source(uniq_sources[1])
    if source and source.buffer then
      opts = vim.tbl_extend("force", opts, source.buffer)
    end
  end

  for option, value in pairs(opts) do
    vim.api.nvim_set_option_value(option, value, { buf = buf })
  end

  return buf
end

function M._temp_edit(buf, callback)
  vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
  callback()
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
end

---@param entries Timber.Watcher.LogEntry[]
---@return integer[] range The updated range of the buffer
function M._append_buffer(buf, entries)
  local lines = { "" }
  local separator_lines = {}
  local show_source_name = M._should_show_source_name(entries)
  local base_line = vim.api.nvim_buf_line_count(buf) - 1

  for _, entry in ipairs(entries) do
    local start_line = base_line + #lines + 1
    -- This is the separator line
    local separator_line = M._separator_line(entry, show_source_name)
    table.insert(lines, separator_line)
    table.insert(separator_lines, #lines)

    vim.list_extend(lines, vim.split(entry.payload, "\n"))
    table.insert(lines, "")

    table.insert(M.ranges, {
      placeholder_id = entry.log_placeholder_id,
      start = start_line,
      ["end"] = base_line + #lines,
    })
  end

  M._temp_edit(buf, function()
    vim.api.nvim_buf_set_lines(buf, base_line, -1, false, lines)
  end)

  -- Set up highlight for separator lines
  for _, line in ipairs(separator_lines) do
    vim.api.nvim_buf_set_extmark(buf, M.summary_ns, base_line + line - 1, 0, {
      line_hl_group = "Timber.SummarySeparator",
      priority = 100,
    })

    vim.api.nvim_buf_set_extmark(buf, M.summary_ns, base_line + line - 1, 0, {
      virt_text_win_col = #lines[line] - 1,
      virt_text = { { string.rep("-", vim.go.columns), "Timber.SummarySeparator" } },
      hl_mode = "combine",
      priority = 100,
    })
  end

  return { base_line, -1 }
end

---@param opts {jump: boolean} Whether to jump to the entry
function M._open_entry(opts)
  local row = vim.api.nvim_win_get_cursor(0)[1]

  local range = vim.iter(M.ranges):find(function(range)
    return range.start <= row and row <= range["end"]
  end)

  if not range then
    return
  end

  ---@type Timber.Watcher.LogEntry
  local entry = vim.iter(M.log_entries):find(function(entry)
    return entry.log_placeholder_id == range.placeholder_id
  end)

  local bufnr, line = buffers.get_placeholder_position(entry.log_placeholder_id)
  local jump_target = nil

  -- The placeholder is found in an open buffer
  if bufnr then
    vim.api.nvim_win_set_buf(M.attach_winnr, bufnr)
    jump_target = {
      winnr = M.attach_winnr,
      bufnr = bufnr,
      line = line,
    }
  else
    -- Use global search to find
    local pattern = string.format("%s%s", watcher.MARKER, entry.log_placeholder_id)

    vim.cmd(string.format("silent! grep! %s", pattern))

    local qf_list = vim.fn.getqflist()
    if #qf_list > 0 then
      local first_item = qf_list[1]
      vim.api.nvim_win_set_buf(M.attach_winnr, first_item.bufnr)
      jump_target = {
        winnr = M.attach_winnr,
        bufnr = first_item.bufnr,
        line = first_item.lnum - 1,
      }
    else
      utils.notify(string.format("Could not find log placeholder %s", entry.log_placeholder_id), "warn")
    end
  end

  if jump_target then
    if config.config.highlight.on_summary_show_entry then
      highlight.highlight_lines(
        jump_target.bufnr,
        jump_target.line,
        jump_target.line,
        "Timber.SummaryJumpToLine",
        false
      )
    end

    if opts.jump then
      vim.api.nvim_set_current_win(jump_target.winnr)
      vim.api.nvim_win_set_cursor(0, { jump_target.line + 1, 0 })
    end
  end
end

function M._scroll_to_next_entry()
  local current_line = vim.fn.getpos(".")[2]

  for i = 1, #M.ranges do
    local range = M.ranges[i]
    if range.start > current_line then
      vim.api.nvim_win_set_cursor(0, { range.start, 0 })
      highlight.highlight_lines(0, range.start - 1, range.start - 1, "Timber.SummaryJumpToLine", true)
      return
    end
  end
end

function M._scroll_to_prev_entry()
  local current_line = vim.fn.getpos(".")[2]

  for i = #M.ranges, 1, -1 do
    local range = M.ranges[i]
    if range["end"] < current_line then
      vim.api.nvim_win_set_cursor(0, { range.start, 0 })
      highlight.highlight_lines(0, range.start - 1, range.start - 1, "Timber.SummaryJumpToLine", true)
      return
    end
  end
end

---@param log_entry Timber.Watcher.LogEntry
function M._on_received_log_entry(log_entry)
  table.insert(M.log_entries, log_entry)

  -- If the summary window is open, update the buffer
  if M.bufnr then
    vim.schedule(function()
      M._append_buffer(M.bufnr, { log_entry })
      if M.highlight_placeholder then
        M._highlight_log_entry(M.highlight_placeholder, true)
      end
    end)
  end
end

---Similar to `open`, but if the window is already open, close it
---@return boolean opened, integer? winnr, integer? bufnr The opened status, window ID and buffer ID of the summary
function M.toggle(opts)
  if M.winnr then
    M.close()
    return false, nil, nil
  else
    local winnr, bufnr = M.open(opts)
    return true, winnr, bufnr
  end
end

---@class Timber.Summary.OpenOpts? opts
---@field focus boolean Whether to focus the window after opening

---@param opts Timber.Summary.OpenOpts?
---@return integer winnr, integer bufnr The window ID and buffer ID of the summary
function M.open(opts)
  opts = vim.tbl_deep_extend("force", { focus = true }, opts or {})

  table.sort(M.log_entries, function(a, b)
    if a.timestamp == b.timestamp then
      return a.sequence < b.sequence
    end

    return a.timestamp < b.timestamp
  end)

  -- Get the placeholder id before we change the buffer
  local placeholder_id = buffers.get_current_line_placeholder()

  -- Format and display log entries
  local buf = M._make_buffer(M.log_entries)
  M._append_buffer(buf, M.log_entries)

  local win = M._make_win(buf)
  M.attach_winnr = vim.api.nvim_get_current_win()
  M.winnr = win
  M.bufnr = buf

  -- Focus to the summary window
  if opts.focus then
    vim.api.nvim_set_current_win(win)
  end

  -- If the current line has a log placeholder, scroll the matching entry into view
  if placeholder_id then
    M._scroll_log_entry_into_view(M.winnr, placeholder_id)
    M._highlight_log_entry(placeholder_id, true)
  end

  local untrack = M._track_cursor_movement()
  require("timber.summary.keymaps")._setup_buffer_keymaps(buf)

  vim.api.nvim_create_autocmd("WinClosed", {
    callback = function(args)
      if tostring(M.winnr) == args.match then
        untrack()
        vim.api.nvim_del_autocmd(args.id)
        M.close()
      end
    end,
  })

  return M.winnr, M.bufnr
end

---Also delete the buffer
function M.close()
  if not M.bufnr then
    return
  end

  vim.api.nvim_buf_delete(M.bufnr, { force = true })
  M.bufnr = nil
  M.winnr = nil
end

function M.clear()
  M.log_entries = {}
  M.ranges = {}
  M.highlight_placeholder = nil

  -- Clear all extmarks
  if M.bufnr then
    vim.api.nvim_buf_clear_namespace(M.bufnr, M.summary_ns, 0, -1)
    vim.api.nvim_buf_clear_namespace(M.bufnr, M.summary_focus_ns, 0, -1)

    M._temp_edit(M.bufnr, function()
      vim.api.nvim_buf_set_lines(M.bufnr, 0, -1, false, {})
    end)
  end
end

function M.setup()
  M.summary_ns = vim.api.nvim_create_namespace("timber.summary")
  M.summary_focus_ns = vim.api.nvim_create_namespace("timber.summary_focus")

  local hl_info = vim.api.nvim_get_hl(0, { name = "FloatBorder" })
  vim.api.nvim_set_hl(0, "Timber.SummarySeparator", { fg = hl_info.fg, bg = "none" })
  vim.api.nvim_set_hl(0, "Timber.SummaryEntryBodyHighlighted", { link = "PmenuSel" })
  vim.api.nvim_set_hl(0, "Timber.SummaryJumpToLine", { link = "Search", default = true })

  events.on("watcher:new_log_entry", function(entry)
    M._on_received_log_entry(entry)
  end)
end

return M
