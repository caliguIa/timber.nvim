---@class NeologActions
--- @field log_templates NeologLogTemplates
local M = {}

local utils = require("neolog.utils")
local ts_utils = require("nvim-treesitter.ts_utils")

--- Build the log label from template. Support special placeholers:
---   %identifier: the identifier text
---   %fn_name: the enclosing function name. If there's none, replaces with empty string
---   %line_number: the line_number number
---@param label_template string
---@param log_target_node TSNode
---@return string
local function build_log_label(label_template, log_target_node)
  local label = label_template

  if string.find(label, "%%identifier") then
    local bufnr = vim.api.nvim_get_current_buf()
    local identifier_text = vim.treesitter.get_node_text(log_target_node, bufnr)
    label = string.gsub(label, "%%identifier", identifier_text)
  end

  if string.find(label, "%%line_number") then
    local start_row = log_target_node:start()
    label = string.gsub(label, "%%line_number", start_row + 1)
  end

  return label
end

---@param label_text string
---@param identifier_text string
---@return string
local function build_log_statement(label_text, identifier_text)
  local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
  local template = M.log_templates[lang]

  template = string.gsub(template, "%%label", label_text)
  template = string.gsub(template, "%%identifier", identifier_text)

  return template
end

---@param line_number number
local function indent_line_number(line_number)
  local current_pos = vim.api.nvim_win_get_cursor(0)
  vim.api.nvim_win_set_cursor(0, { line_number, 0 })
  vim.cmd("normal! ==")
  vim.api.nvim_win_set_cursor(0, current_pos)
end

---@alias log_placement "inner" | "outer"
---@param label_template string
---@param log_target_node TSNode
---@param container_node TSNode
---@param position "above" | "below"
---@param log_placement log_placement
local function insert_log_statement(label_template, log_target_node, container_node, position, log_placement)
  local bufnr = vim.api.nvim_get_current_buf()
  local identifier_text = vim.treesitter.get_node_text(log_target_node, bufnr)

  local insert_line
  if log_placement == "inner" then
    insert_line = container_node:start() + 1
  else
    insert_line = position == "above" and container_node:start() or container_node:end_() + 1
  end

  local log_label = build_log_label(label_template, log_target_node)

  vim.api.nvim_buf_set_lines(
    bufnr,
    insert_line,
    insert_line,
    false,
    { build_log_statement(log_label, identifier_text) }
  )

  indent_line_number(insert_line + 1)
end

---@param query vim.treesitter.Query
---@param target_log_node TSNode
---@param match TSNode
---@return TSNode?
local function get_container_node(query, target_log_node, match, metadata)
  local container_capture = match[utils.get_key_by_value(query.captures, "container")]

  if container_capture then
    return container_capture
  else
    -- comma separated list of container types
    local container_types = vim.split(metadata.container_type, ",")

    -- Traverse up the tree to find the container node
    ---@type TSNode?
    local current = target_log_node
    repeat
      current = current and current:parent()
    until current == nil or utils.array_includes(container_types, current:type())

    return current
  end
end

local LANGUAGE_SPEC = {
  typescript = {
    identifier = "identifier",
    container = { "lexical_declaration", "return_statement", "expression_statement" },
  },
  tsx = {
    identifier = "identifier",
    container = { "lexical_declaration", "return_statement", "expression_statement" },
  },
}

--- Traverse up the tree from the current node to find the container node
---@return boolean, {[1]: TSNode, [2]: TSNode, [3]: log_placement}?
function M.get_container_node_fallback()
  local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
  local spec = LANGUAGE_SPEC[lang]
  if not spec then
    return false
  end

  local current_node = ts_utils.get_node_at_cursor()

  if current_node:type() ~= spec.identifier then
    return false
  end

  local log_target_node = current_node

  -- Traverse up the tree to find the container node
  ---@type TSNode?
  local log_container_node = current_node
  repeat
    log_container_node = log_container_node and log_container_node:parent()
  until log_container_node == nil or require("custom.utils").array_includes(spec.container, log_container_node:type())

  return true, { log_target_node, log_container_node, "outer" }
end

--- Add log statement for the current identifier at the cursor
--- @param label_template string
--- @param position "above" | "below"
function M.add_log(label_template, position)
  local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
  if not lang then
    vim.notify("Cannot determine language for current buffer", vim.log.levels.ERROR)
    return
  end

  local query = vim.treesitter.query.get(lang, "neolog")
  if not query then
    vim.notify(string.format("logging_framework doesn't support %s language", lang), vim.log.levels.ERROR)
    return
  end

  local template = M.log_templates[lang]
  if not template then
    vim.notify(string.format("Log template for %s language is not found", lang), vim.log.levels.ERROR)
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local parser = vim.treesitter.get_parser(bufnr, lang)
  local tree = parser:parse()[1]
  local root = tree:root()

  local cursor_pos = vim.api.nvim_win_get_cursor(0)

  local log_target_node
  local log_container_node
  local log_placement

  for _, match, metadata in query:iter_matches(root, bufnr, 0, -1) do
    local log_target_capture = match[utils.get_key_by_value(query.captures, "log_target")]

    if log_target_capture then
      local cursor_range = { cursor_pos[1] - 1, cursor_pos[2], cursor_pos[1] - 1, cursor_pos[2] }

      if vim.treesitter.node_contains(log_target_capture, cursor_range) then
        log_container_node = get_container_node(query, log_target_capture, match, metadata)
        log_placement = metadata.log_placement or "outer"
        log_target_node = log_target_capture

        break
      end
    end
  end

  if not log_container_node then
    local success, result = M.get_container_node_fallback()
    if success and result then
      log_target_node = result[1]
      log_container_node = result[2]
      log_placement = result[3]
    end
  end

  if log_container_node and log_placement then
    insert_log_statement(label_template, log_target_node, log_container_node, position, log_placement)
  else
    vim.notify("Cursor is not inside a valid log target", vim.log.levels.INFO)
  end
end

---@param templates NeologLogTemplates
function M.setup(templates)
  M.log_templates = templates
end

return M
