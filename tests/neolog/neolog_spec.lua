local neolog = require("neolog")
local helper = require("tests.neolog.helper")

describe("neolog", function()
  it("provides default config", function()
    neolog.setup()
    local actions = require("neolog.actions")

    helper.assert_scenario({
      input = [[
        const fo|o = "bar"
      ]],
      filetype = "typescript",
      action = function()
        actions.add_log("%identifier", "below")
      end,
      expected = [[
        const foo = "bar"
        console.log("foo", foo)
      ]],
    })
  end)

  it("allows customize log templates", function()
    neolog.setup({
      log_templates = { typescript = [[console.log("%label bar 123", %identifier)]] },
    })
    local actions = require("neolog.actions")

    helper.assert_scenario({
      input = [[
        const fo|o = "bar"
      ]],
      filetype = "typescript",
      action = function()
        actions.add_log("%identifier", "below")
      end,
      expected = [[
        const foo = "bar"
        console.log("foo bar 123", foo)
      ]],
    })
  end)
end)

describe("neolog.actions", function()
  describe("label template", function()
    it("supports %line_number", function()
      neolog.setup()
      local actions = require("neolog.actions")

      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = "bar"
        ]],
        filetype = "typescript",
        action = function()
          actions.add_log("%line_number %identifier", "below")
        end,
        expected = [[
          // Comment
          const foo = "bar"
          console.log("2 foo", foo)
        ]],
      })
    end)
  end)
end)
