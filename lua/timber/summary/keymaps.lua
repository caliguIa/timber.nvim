local summary = require("timber.summary")
local config = require("timber.config")
local utils = require("timber.utils")

local M = {}

local ACTIONS = {
  show_entry = {
    desc = "Show the buffer contains the log entry",
    callback = function()
      summary._open_entry({ jump = false })
    end,
  },
  jump_to_entry = {
    desc = "Show the buffer contains the log entry and move the cursor to it",
    callback = function()
      summary._open_entry({ jump = true })
    end,
  },
  next_entry = {
    desc = "Jump to the next log entry in the summary window",
    callback = function()
      summary._scroll_to_next_entry()
    end,
  },
  prev_entry = {
    desc = "Jump to the prev log entry in the summary window",
    callback = function()
      summary._scroll_to_prev_entry()
    end,
  },
  show_help = {
    desc = "Show the keymaps for the summary window",
    callback = function()
      M._show_keymaps_help()
    end,
  },
  close = {
    desc = "Close the summary window",
    callback = function()
      summary.close()
    end,
  },
}

function M._show_keymaps_help()
  local col_left = {}
  local col_desc = {}

  local max_lhs = 1
  for action_key, action_spec in pairs(ACTIONS) do
    local key = config.config.log_summary.keymaps[action_key]

    if key ~= false then
      ---@cast key string
      table.insert(col_left, key)
      table.insert(col_desc, action_spec.desc)
      max_lhs = math.max(max_lhs, vim.api.nvim_strwidth(key))
    end
  end

  local lines = {}
  local highlights = {}
  local max_line = 1
  for i = 1, #col_left do
    local left = col_left[i]
    local desc = col_desc[i]
    local line = string.format(" %s   %s", utils.str_pad_right(left, max_lhs), desc)
    max_line = math.max(max_line, vim.api.nvim_strwidth(line))
    table.insert(lines, line)

    local keywidth = vim.api.nvim_strwidth(left)
    table.insert(highlights, { "Special", i - 1, 1, keywidth + 1 })
  end

  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, lines)
  local ns = vim.api.nvim_create_namespace("Timber.SummaryKeymaps")

  for _, hl in ipairs(highlights) do
    local hl_group, lnum, start_col, end_col = unpack(hl)
    vim.api.nvim_buf_set_extmark(bufnr, ns, lnum, start_col, {
      end_col = end_col,
      hl_group = hl_group,
    })
  end

  vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = bufnr, nowait = true })
  vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = bufnr })

  local editor_width = vim.o.columns
  local editor_height = vim.o.lines - vim.o.cmdheight
  local winid = vim.api.nvim_open_win(bufnr, true, {
    relative = "editor",
    row = math.max(0, (editor_height - #lines) / 2),
    col = math.max(0, (editor_width - max_line - 1) / 2),
    width = math.min(editor_width, max_line + 1),
    height = math.min(editor_height, #lines),
    zindex = 150,
    style = "minimal",
    border = "rounded",
  })

  local function close()
    if vim.api.nvim_win_is_valid(winid) then
      vim.api.nvim_win_close(winid, true)
    end
  end

  vim.api.nvim_create_autocmd("BufLeave", {
    callback = close,
    once = true,
    nested = true,
    buffer = bufnr,
  })

  vim.api.nvim_create_autocmd("WinLeave", {
    callback = close,
    once = true,
    nested = true,
  })
end

function M._setup_buffer_keymaps(buf)
  local keymaps = config.config.log_summary.keymaps

  for action_key, action_spec in pairs(ACTIONS) do
    local key = keymaps[action_key]

    if key ~= false then
      ---@cast key string
      vim.keymap.set(
        "n",
        key,
        action_spec.callback,
        { silent = true, noremap = true, buffer = buf, desc = action_spec.desc }
      )
    end
  end
end

return M
