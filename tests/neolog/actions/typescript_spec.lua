local neolog = require("neolog")
local helper = require("tests.neolog.helper")

describe("typescript", function()
  it("logs the identifier under the cursor", function()
    neolog.setup()
    local actions = require("neolog.actions")

    local input = [[
      const fo|o = "bar"
    ]]

    local expected = [[
      const foo = "bar"
      console.log("foo", foo)
    ]]

    helper.assert_scenario({
      input = input,
      filetype = "typescript",
      action = function()
        vim.api.nvim_win_set_cursor(0, { 1, 7 })
        actions.add_log("%identifier", "below")
      end,
      expected = expected,
    })
  end)
end)
