local watcher = require("timber.watcher")
local utils = require("timber.utils")

---@class Timber.Buffers.LogPlaceholderEntries
---@field body string
---@field source_id string
---@field timestamp integer

---@class Timber.Buffers.LogPlaceholder
---@field id Timber.Watcher.LogPlaceholderId The log placeholder id.
---@field bufnr number
---@field line number 0-indexed line number. The line number is only correct when the placeholder is newly created. Overtime, after updates, the real line number will be shifted.
---@field content string
---@field extmark_id? integer
---@field entries Timber.Buffers.LogPlaceholderEntries[]

---@class Timber.Buffers
---@field log_placeholders Timber.Buffers.LogPlaceholderRegistry
---@field seen_buffers integer[] Buffers has been opened and processed
---@field attached_buffers integer[] Buffers currently being attached to
---@field pending_log_entries Timber.Watcher.LogEntry[] Log entries that didn't have a corresponding placeholder. They will be processed once the placeholder is created
---@field placeholder_render_timer any Timer to keep updating the placeholder snippet
local M = {
  log_placeholders = require("timber.buffers.placeholders").new(),
  seen_buffers = {},
  attached_buffers = {},
  pending_log_entries = {},
}

---@param line string
---@return string? placeholder_id
function M._parse_log_placeholder(line)
  local pattern = string.format("🪵(%s)", string.rep("[A-Z0-9]", 3))
  return string.match(line, pattern)
end

function M._attach_buffer(bufnr)
  if vim.list_contains(M.attached_buffers, bufnr) then
    return
  end

  vim.api.nvim_buf_attach(bufnr, false, {
    on_lines = M._on_lines,
    on_reload = function()
      M._process_buffer(bufnr)
    end,
  })

  table.insert(M.attached_buffers, bufnr)
end

function M._detach_buffer(bufnr)
  local index = utils.array_find_index(M.attached_buffers, function(v)
    return v == bufnr
  end)

  -- There's no API to detach a buffer. We will return false in the next on_lines callback
  if index then
    table.remove(M.attached_buffers, index)
  end
end

---@param content string
---@param bufnr integer
---@param line integer 0-indexed line number
---@return Timber.Watcher.LogPlaceholderId? placeholder_id
function M._process_line(content, bufnr, line)
  local placeholder_id = M._parse_log_placeholder(content)

  if placeholder_id and not M.log_placeholders:get(placeholder_id) then
    vim.schedule(function()
      M._new_log_placeholder({ id = placeholder_id, bufnr = bufnr, line = line, content = content, entries = {} })
    end)

    return placeholder_id
  end
end

---@param bufnr number
---@return boolean found_any_placeholders
function M._process_buffer(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local found_any = false

  for i, line in ipairs(lines) do
    local placeholder_id = M._process_line(line, bufnr, i - 1)
    if placeholder_id then
      found_any = true
    end
  end

  return found_any
end

function M._on_lines(_, bufnr, _, first_line, last_line, new_last_line, _)
  -- Process each line in the changed region
  for lnum = first_line, new_last_line - 1 do
    local line = vim.api.nvim_buf_get_lines(bufnr, lnum, lnum + 1, false)[1]
    M._process_line(line, bufnr, lnum)
  end

  -- Handle deleted lines
  if last_line > new_last_line then
    -- The deleted line may shifted some placeholders to the next line.
    -- The algorithm is as follows:
    --   1. Get the placeholder of the next line by parsing the content
    --   2. Get all placeholders on the next line by getting extmarks
    --   3. Subtract 2 to 1, we get the extmarks that are deleted
    local line_content = vim.api.nvim_buf_get_lines(bufnr, last_line - 1, last_line, false)[1]

    local line_placeholder = line_content and M._parse_log_placeholder(line_content)
    local marks = vim.api.nvim_buf_get_extmarks(
      bufnr,
      M.log_placeholder_ns,
      { new_last_line, 0 },
      { new_last_line, -1 },
      {}
    )

    marks = utils.array_filter(marks, function(mark)
      if line_placeholder == nil then
        return true
      end

      return mark[1] ~= M.log_placeholders:get(line_placeholder).extmark_id
    end)

    for _, mark in ipairs(marks) do
      local mark_id = mark[1]

      vim.schedule(function()
        vim.api.nvim_buf_del_extmark(bufnr, M.log_placeholder_ns, mark_id)
        M.log_placeholders:remove_by_extmark_id(mark_id, bufnr)

        local remaining = M.log_placeholders:buffer_placeholders(bufnr)
        if #remaining == 0 then
          M._detach_buffer(bufnr)
        end
      end)
    end
  end
end

---@param log_placeholder Timber.Buffers.LogPlaceholder
---@return integer? line_offset, integer? start_col_offset, integer? end_col_offset
function M._find_marker_position(log_placeholder)
  local marker_pattern = watcher.MARKER .. log_placeholder.id
  local lines = vim.split(log_placeholder.content, "\n")

  for i, line in ipairs(lines) do
    local marker_index = line:find(marker_pattern)
    if marker_index then
      return i - 1, marker_index - 1, marker_index - 1 + #marker_pattern
    end
  end

  return nil, nil
end

---@param log_placeholder Timber.Buffers.LogPlaceholder
function M._new_log_placeholder(log_placeholder)
  if not log_placeholder.id then
    return
  end

  if log_placeholder.id and M.log_placeholders:get(log_placeholder.id) then
    return
  end

  local line_offset, start_col_offset, end_col_offset = M._find_marker_position(log_placeholder)
  if not line_offset or not start_col_offset or not end_col_offset then
    return
  end

  local extmark_id = vim.api.nvim_buf_set_extmark(
    log_placeholder.bufnr,
    M.log_placeholder_ns,
    log_placeholder.line + line_offset,
    start_col_offset,
    { end_col = end_col_offset }
  )

  log_placeholder.extmark_id = extmark_id
  M.log_placeholders:add(log_placeholder)
  M._attach_buffer(log_placeholder.bufnr)

  -- Check the pending log entries and process ones targeting this placeholder
  for _, entry in ipairs(M.pending_log_entries) do
    if entry.log_placeholder_id == log_placeholder.id then
      M._receive_log_entry(entry)
    end
  end

  M.pending_log_entries = utils.array_filter(M.pending_log_entries, function(entry)
    return entry.log_placeholder_id ~= log_placeholder.id
  end)
end

---@param timestamp integer
function M._relative_time(timestamp)
  local current_time = os.time()
  local elapsed = current_time - timestamp

  local breakpoints = {
    { elapsed = 30, text = "Just now" },
    { elapsed = 300, text = ">30 seconds ago" },
    { elapsed = 900, text = ">5 minutes ago" },
  }

  for _, breakpoint in ipairs(breakpoints) do
    if elapsed < breakpoint.elapsed then
      return breakpoint.text
    end
  end

  return ">15 minutes ago"
end

---@param log_placeholder Timber.Buffers.LogPlaceholder
function M._render_placeholder_snippet(log_placeholder)
  local content = log_placeholder.entries[#log_placeholder.entries]
  if not content then
    return
  end

  local is_loaded = vim.api.nvim_buf_is_loaded(log_placeholder.bufnr)
  if not is_loaded then
    return
  end

  local preview_snippet_length = require("timber.config").config.log_watcher.preview_snippet_length
  local snippet = content.body

  if #snippet > preview_snippet_length then
    snippet = string.sub(content.body, 1, preview_snippet_length) .. "..."
  end

  local mark =
    vim.api.nvim_buf_get_extmark_by_id(log_placeholder.bufnr, M.log_placeholder_ns, log_placeholder.extmark_id, {})

  if mark and #mark > 0 then
    ---@type integer, integer
    local row, col = unpack(mark, 1, 2)

    vim.api.nvim_buf_set_extmark(log_placeholder.bufnr, M.log_placeholder_ns, row, col, {
      id = log_placeholder.extmark_id,
      virt_text = {
        { "■ " .. snippet, "Timber.LogPlaceholderSnippet" },
        { " " .. M._relative_time(content.timestamp), "Timber.LogPlaceholderTime" },
      },
      virt_text_pos = "eol",
    })
  end
end

---@param log_placeholder Timber.Buffers.LogPlaceholder
function M._remove_placeholder_snippet(log_placeholder)
  local is_loaded = vim.api.nvim_buf_is_loaded(log_placeholder.bufnr)
  if not is_loaded then
    return
  end

  local mark =
    vim.api.nvim_buf_get_extmark_by_id(log_placeholder.bufnr, M.log_placeholder_ns, log_placeholder.extmark_id, {})

  if mark and #mark > 0 then
    ---@type integer, integer
    local row, col = unpack(mark, 1, 2)

    vim.api.nvim_buf_set_extmark(log_placeholder.bufnr, M.log_placeholder_ns, row, col, {
      id = log_placeholder.extmark_id,
    })
  end
end

---Callback for log entry received
--- @param entry Timber.Watcher.LogEntry
function M._receive_log_entry(entry)
  local log_placeholder = M.log_placeholders:get(entry.log_placeholder_id)

  if log_placeholder then
    table.insert(
      log_placeholder.entries,
      { body = entry.payload, source_id = entry.source_id, timestamp = entry.timestamp }
    )

    vim.schedule(function()
      M._render_placeholder_snippet(log_placeholder)
    end)
  else
    -- Save the log entry for later
    table.insert(M.pending_log_entries, entry)
  end
end

---@class Timber.Buffers.OpenFloatOpts
---@field silent? boolean Whether to show a notification when no log placeholder is found. Defaults to `false`
---@field sort? "newest_first" | "oldest_first" The sort order by timestamp. Defaults to `oldest_first`

---@param opts Timber.Buffers.OpenFloatOpts?
---@return integer? floating_bufnr
function M.open_float(opts)
  opts = vim.tbl_extend("force", { silent = false, sort = "oldest_first" }, opts or {})

  local current_line = vim.fn.getline(".")
  local placeholder_id = M._parse_log_placeholder(current_line)

  if not placeholder_id then
    if not opts.silent then
      utils.notify("No log placeholder found", "warn")
    end

    return
  end

  local placeholder = M.log_placeholders:get(placeholder_id)
  if placeholder then
    return require("timber.buffers.win").open(placeholder, opts)
  else
    error(string.format("Log placeholder %s does not exist", placeholder_id))
  end
end

function M._update_placeholders_snippet()
  for _, i in pairs(M.log_placeholders.placeholders) do
    M._render_placeholder_snippet(i)
  end
end

---Get all log statement line numbers in the current buffer or all buffers
---@param bufnr number? Buffer number. If not provided, return results for all buffers
---@return table<integer, integer[]> lines_per_bufnr 0-indexed line numbers grouped by buffers
function M.get_log_statement_lines(bufnr)
  local grouped = utils.array_group_by(M.log_placeholders.placeholders, function(placeholder)
    return placeholder.bufnr
  end)

  local to_lines = function(items)
    local lines = {}
    for _, placeholder in ipairs(items) do
      local pos =
        vim.api.nvim_buf_get_extmark_by_id(placeholder.bufnr, M.log_placeholder_ns, placeholder.extmark_id, {})
      table.insert(lines, pos[1])
    end

    return lines
  end

  if bufnr then
    return grouped[bufnr] and { [bufnr] = to_lines(grouped[bufnr]) } or {}
  else
    local result = {}
    for _bufnr, _placeholders in pairs(grouped) do
      result[_bufnr] = to_lines(_placeholders)
    end

    return result
  end
end

---Clear all captured log results in all buffers
function M.clear_captured_logs()
  for _, log_placeholder in pairs(M.log_placeholders.placeholders) do
    log_placeholder.entries = {}
    M._remove_placeholder_snippet(log_placeholder)
  end
end

---@return string?
function M.get_current_line_placeholder()
  local line_content = vim.fn.getline(".")
  return M._parse_log_placeholder(line_content)
end

---@return integer? bufnr, integer? line Returns nil if the placeholder is not found
function M.get_placeholder_position(placeholder_id)
  local placeholder = M.log_placeholders:get(placeholder_id)

  if not placeholder then
    return nil
  end

  local mark = vim.api.nvim_buf_get_extmark_by_id(placeholder.bufnr, M.log_placeholder_ns, placeholder.extmark_id, {})

  return placeholder.bufnr, mark[1]
end

function M.setup()
  M.log_placeholder_ns = vim.api.nvim_create_namespace("timber.log_placeholder")

  vim.api.nvim_set_hl(0, "Timber.LogPlaceholderSnippet", { link = "DiagnosticVirtualTextInfo", default = true })
  vim.api.nvim_set_hl(0, "Timber.LogPlaceholderTime", { italic = true })

  vim.api.nvim_create_autocmd("BufRead", {
    callback = function(args)
      local bufnr = args.buf
      if vim.list_contains(M.seen_buffers, bufnr) then
        return
      end

      -- We only attach to the buffer if it contains a log placeholder
      local found_any_placeholders = M._process_buffer(bufnr)
      if found_any_placeholders then
        M._attach_buffer(bufnr)
      end

      table.insert(M.seen_buffers, bufnr)
    end,
  })

  vim.api.nvim_create_autocmd("BufDelete", {
    callback = function(args)
      M._detach_buffer(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd("BufWipeout", {
    callback = function(args)
      M._detach_buffer(args.buf)
    end,
  })

  -- Timer loop to keep updating the placeholder snippets
  M.placeholder_render_timer = vim.uv.new_timer()
  M.placeholder_render_timer:start(0, 10000, vim.schedule_wrap(M._update_placeholders_snippet))

  require("timber.buffers.win").setup()
  require("timber.events").on("watcher:new_log_entry", M._receive_log_entry)
  require("timber.events").on("actions:new_log_statement", function(log_statement)
    M._new_log_placeholder({
      id = log_statement.placeholder_id,
      bufnr = vim.api.nvim_get_current_buf(),
      -- TODO: support multi line log statements
      line = log_statement.inserted_rows[1],
      content = log_statement.content,
      entries = {},
    })
  end)
end

return M
