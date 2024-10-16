local assert = require("luassert")
local neolog = require("neolog")

local function setup_buffer(input, filetype)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("filetype", filetype, { buf = buf })
  vim.api.nvim_command("buffer " .. buf)
  vim.api.nvim_buf_set_lines(0, 0, -1, true, vim.split(input, "\n"))
end

local assert_buf_output = function(expected)
  local output = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  assert.are.same(vim.split(expected, "\n"), output)
end

describe("neolog", function()
  it("provides default config", function()
    neolog.setup()
    local actions = require("neolog.actions")

    local input = [[
const foo = "bar"
]]

    local expected = [[
const foo = "bar"
console.log("foo", foo)
]]

    setup_buffer(input, "typescript")

    vim.api.nvim_win_set_cursor(0, { 1, 7 })
    actions.add_log("%identifier", "below")

    assert_buf_output(expected)
  end)

  it("allows customize log templates", function()
    neolog.setup({
      log_templates = { typescript = [[console.log("%label bar 123", %identifier)]] },
    })
    local actions = require("neolog.actions")

    local input = [[
const foo = "bar"
]]

    local expected = [[
const foo = "bar"
console.log("foo bar 123", foo)
]]

    setup_buffer(input, "typescript")

    vim.api.nvim_win_set_cursor(0, { 1, 7 })
    actions.add_log("%identifier", "below")

    assert_buf_output(expected)
  end)
end)

describe("neolog.actions", function()
  describe("label template", function()
    it("supports %line_number", function()
      neolog.setup()
      local actions = require("neolog.actions")

      local input = [[
// Comment
const foo = "bar"
]]

      local expected = [[
// Comment
const foo = "bar"
console.log("2 foo", foo)
]]

      setup_buffer(input, "typescript")
      vim.api.nvim_win_set_cursor(0, { 2, 7 })
      actions.add_log("%line_number %identifier", "below")
      assert_buf_output(expected)
    end)
  end)

  describe("typescript", function()
    it("logs the identifier under the cursor", function()
      local actions = require("neolog.actions")

      local input = [[
const foo = "bar"
]]

      local expected = [[
const foo = "bar"
console.log("foo", foo)
]]

      setup_buffer(input, "typescript")
      vim.api.nvim_win_set_cursor(0, { 1, 7 })
      actions.add_log("%identifier", "below")
      assert_buf_output(expected)
    end)
  end)
end)
