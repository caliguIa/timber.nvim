local utils = require("timber.utils")

---@class Timber.Highlight.Config
---@field on_insert? boolean Whether to highlight the log target when inserting the log. Defaults to `true`
---@field on_add_to_batch? boolean Whether to highlight the log target when adding to the batch. Defaults to `true`
---@field duration number The timeout in ms for highlighting

---@class Timber.Watcher.Config
---@field enabled? boolean Whether to enable log watcher. Defaults to `false`
---@field sources table<string, Timber.Watcher.SourceSpec> The sources to watch
---@field preview_snippet_length? integer The length of the preview snippet display as extmarks. Defaults to `32`

---@class Timber.Config
---@field log_templates { [string]: Timber.LogTemplates }
---@field batch_log_templates { [string]: Timber.LogTemplates }
---@field highlight Timber.Highlight.Config
---@field keymaps { [Timber.Action | Timber.Operator]: string }
---@field default_keymaps_enabled boolean Whether to enable default keymaps. Defaults to `true`
---@field log_watcher Timber.Watcher.Config

---@type Timber.Config
local default_config = {
  log_templates = {
    default = {
      javascript = [[console.log("%log_target", %log_target)]],
      typescript = [[console.log("%log_target", %log_target)]],
      jsx = [[console.log("%log_target", %log_target)]],
      tsx = [[console.log("%log_target", %log_target)]],
      lua = [[print("%log_target", %log_target)]],
      ruby = [[puts("%log_target #{%log_target}")]],
      elixir = [[IO.inspect(%log_target, label: "%log_target")]],
      go = [[log.Printf("%log_target: %v\n", %log_target)]],
      rust = [[println!("%log_target: {:#?}", %log_target);]],
      python = [[print("%log_target", %log_target)]],
      c = [[printf("%log_target: %s\n", %log_target);]],
      cpp = [[std::cout << "%log_target: " << %log_target << std::endl;]],
    },
  },
  batch_log_templates = {
    default = {
      javascript = [[console.log({ %repeat<"%log_target": %log_target><, > })]],
      typescript = [[console.log({ %repeat<"%log_target": %log_target><, > })]],
      jsx = [[console.log({ %repeat<"%log_target": %log_target><, > })]],
      tsx = [[console.log({ %repeat<"%log_target": %log_target><, > })]],
      lua = [[print(string.format("%repeat<%log_target=%s><, >", %repeat<%log_target><, >))]],
      ruby = [[puts("%repeat<%log_target: #{%log_target}><, >")]],
      elixir = [[IO.inspect({ %repeat<%log_target><, > })]],
      go = [[log.Printf("%repeat<%log_target: %v><, >\n", %repeat<%log_target><, >)]],
      rust = [[println!("%repeat<%log_target: {:#?}><, >", %repeat<%log_target><, >);]],
      python = [[print(%repeat<"%log_target", %log_target><, >)]],
      c = [[printf("%repeat<%log_target: %s><, >\n", %repeat<%log_target><, >);]],
      cpp = [[std::cout %repeat<<< "%log_target: " << %log_target>< << "\n  " > << std::endl;]],
    },
  },
  highlight = {
    on_insert = true,
    on_add_to_batch = true,
    duration = 500,
  },
  keymaps = {
    insert_log_below = "glj",
    insert_log_above = "glk",
    insert_batch_log = "glb",
    add_log_targets_to_batch = "gla",
    insert_log_below_operator = "g<S-l>j",
    insert_log_above_operator = "g<S-l>k",
    insert_batch_log_operator = "g<S-l>b",
    add_log_targets_to_batch_operator = "g<S-l>a",
  },
  default_keymaps_enabled = true,
  log_watcher = {
    enabled = false,
    sources = {},
    preview_snippet_length = 32,
  },
}

---@class TimberConfigModule
---@field config Timber.Config
local M = {}

---@param template_set string
---@param kind "single" | "batch"
---@return string?, string?
function M.get_lang_log_template(template_set, kind)
  local lang = utils.get_lang(vim.bo.filetype)
  if not lang then
    utils.notify(string.format("Treesitter parser for %s language is not found", vim.bo.filetype), "error")
    return
  end

  local log_template_set = (kind == "single" and M.config.log_templates or M.config.batch_log_templates)[template_set]
  if not log_template_set then
    utils.notify(string.format("Log template '%s' is not found", template_set), "error")
    return
  end

  local log_template_lang = log_template_set[lang]
  if not log_template_lang then
    utils.notify(
      string.format(
        "%s '%s' does not have '%s' language template",
        kind == "single" and "Log template" or "Batch log template",
        template_set,
        lang
      ),
      "error"
    )
    return
  end

  return log_template_lang, lang
end

local function setup_keymap(name, rhs, opts)
  local keymaps = M.config.keymaps

  local user_keymap = keymaps[name]

  -- If keymap is disabled by user, skip it
  if not user_keymap then
    return
  end

  local mode = opts.mode
  opts.mode = nil
  vim.keymap.set(mode, user_keymap, rhs, opts)
end

local function setup_keymaps()
  setup_keymap("insert_log_below", function()
    require("timber.actions").insert_log({
      position = "below",
    })
  end, { mode = { "n", "v" }, desc = "Insert log statement below" })

  setup_keymap("insert_log_above", function()
    require("timber.actions").insert_log({
      position = "above",
    })
  end, { mode = { "n", "v" }, desc = "Insert log statement above" })

  setup_keymap("insert_batch_log", function()
    require("timber.actions").insert_batch_log()
  end, { mode = "n" })

  setup_keymap("insert_batch_log", function()
    require("timber.actions").insert_batch_log({ auto_add = true })
  end, { mode = "v", desc = "Insert batch log statement below" })

  setup_keymap("add_log_targets_to_batch", function()
    require("timber.actions").add_log_targets_to_batch()
  end, { mode = { "n", "v" }, desc = "Add log targets to batch" })

  setup_keymap("insert_log_below_operator", function()
    return require("timber.actions").insert_log({
      position = "below",
      operator = true,
    })
  end, { mode = "n", expr = true, desc = "Insert log statement below operator" })

  setup_keymap("insert_log_above_operator", function()
    return require("timber.actions").insert_log({
      position = "above",
      operator = true,
    })
  end, { mode = "n", expr = true, desc = "Insert log statement above operator" })

  setup_keymap("insert_batch_log_operator", function()
    return require("timber.actions").insert_batch_log({
      operator = true,
    })
  end, { mode = "n", expr = true, desc = "Insert batch log statement below operator" })

  setup_keymap("add_log_targets_to_batch_operator", function()
    return require("timber.actions").insert_batch_log({
      operator = true,
    })
  end, { mode = "n", expr = true, desc = "Add log targets to batch operator" })
end

-- Test C++ logging templates
function M.test_cpp_templates()
  local single_template = M.config.log_templates.default.cpp
  local batch_template = M.config.batch_log_templates.default.cpp

  -- Test cases
  local test_cases = {
    { input = "count", expected = [[printf("count: %s\n", count);]] },
    { input = "x + y", expected = [[printf("x + y: %s\n", x + y);]] },
  }

  -- Test single log template
  for _, case in ipairs(test_cases) do
    local result = single_template:gsub("%%log_target", case.input)
    assert(
      result == case.expected,
      string.format("Single template failed for '%s'\nExpected: %s\nGot: %s", case.input, case.expected, result)
    )
  end

  -- Test batch template
  local batch_input = { "x", "y", "z" }
  local batch_expected = [[printf("x: %s, y: %s, z: %s\n", x, y, z);]]
  local batch_result = batch_template:gsub("%%repeat<(.-)><(.-)>", function(template, sep)
    local parts = {}
    for _, var in ipairs(batch_input) do
      local part = template:gsub("%%log_target", var)
      table.insert(parts, part)
    end
    return table.concat(parts, sep)
  end)

  assert(
    batch_result == batch_expected,
    string.format("Batch template failed\nExpected: %s\nGot: %s", batch_expected, batch_result)
  )

  return true
end

-- This function is used during testing
function M.reset_default_key_mappings()
  local reset_keymap = function(lhs, modes)
    for _, mode in ipairs(modes) do
      if vim.fn.maparg(lhs, mode) ~= "" then
        vim.keymap.del(mode, lhs)
      end
    end
  end

  reset_keymap("glj", { "n", "v" })
  reset_keymap("glk", { "n", "v" })
  reset_keymap("gla", { "n", "v" })
  reset_keymap("glb", { "n", "v" })
  reset_keymap("g<S-l>j", { "n" })
  reset_keymap("g<S-l>k", { "n" })
  reset_keymap("g<S-l>a", { "n" })
  reset_keymap("g<S-l>b", { "n" })
end

---@param config Timber.InitConfig?
function M.setup(config)
  local base_config = vim.deepcopy(default_config)
  local user_config = config or {}
  local default_keymaps_enabled = user_config.default_keymaps_enabled == nil and base_config.default_keymaps_enabled
    or user_config.default_keymaps_enabled

  if not default_keymaps_enabled then
    base_config.keymaps = {}
  end

  M.config = vim.tbl_deep_extend("force", base_config, user_config)
  setup_keymaps()
end

return M
