local timber = require("timber")
local helper = require("tests.timber.helper")
local actions = require("timber.actions")

describe("python single log", function()
  before_each(function()
    timber.setup({
      log_templates = {
        default = {
          python = [[print("%log_target", %log_target)]],
        },
      },
    })
  end)

  describe("supports variable assignment", function()
    it("supports single assignment", function()
      local input = [[
        fo|o = "bar"
      ]]

      helper.assert_scenario({
        input = input,
        filetype = "python",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          foo = "bar"
          print("foo", foo)
        ]],
      })

      helper.assert_scenario({
        input = input,
        filetype = "python",
        action = function()
          actions.insert_log({ position = "above" })
        end,
        expected = [[
          print("foo", foo)
          foo = "bar"
        ]],
      })
    end)

    it("supports multiple assignment", function()
      helper.assert_scenario({
        input = [[
          fo|o, *bar = "foo", "bar", "baz"
        ]],
        filetype = "python",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          foo, *bar = "foo", "bar", "baz"
          print("foo", foo)
          print("bar", bar)
        ]],
      })
    end)
  end)

  describe("supports function parameters", function()
    describe("supports function declaration", function()
      it("supports normal parameters", function()
        helper.assert_scenario({
          input = [[
            def foo(ba|r):
                return None
          ]],
          filetype = "python",
          action = function()
            actions.insert_log({ position = "below" })
          end,
          expected = [[
            def foo(bar):
                print("bar", bar)
                return None
          ]],
        })
      end)

      it("supports packed parameters", function()
        helper.assert_scenario({
          input = [[
            def foo(*ba|r):
                return None
          ]],
          filetype = "python",
          action = function()
            actions.insert_log({ position = "below" })
          end,
          expected = [[
            def foo(*bar):
                print("bar", bar)
                return None
          ]],
        })
      end)

      it("supports packed keyword parameters", function()
        helper.assert_scenario({
          input = [[
            def foo(**ba|r):
                return None
          ]],
          filetype = "python",
          action = function()
            actions.insert_log({ position = "below" })
          end,
          expected = [[
            def foo(**bar):
                print("bar", bar)
                return None
          ]],
        })
      end)

      it("supports parameters with type hint", function()
        helper.assert_scenario({
          input = [[
            def foo(ba|r: str) -> str:
                return "bar"
          ]],
          filetype = "python",
          action = function()
            actions.insert_log({ position = "below" })
          end,
          expected = [[
            def foo(bar: str) -> str:
                print("bar", bar)
                return "bar"
          ]],
        })
      end)
    end)

    it("supports class method", function()
      helper.assert_scenario({
        input = [[
          class MyClass:
              def method(self, ba|r, baz):
                  return None
        ]],
        filetype = "python",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          class MyClass:
              def method(self, bar, baz):
                  print("self", self)
                  print("bar", bar)
                  print("baz", baz)
                  return None
        ]],
      })
    end)

    it("supports lambda function", function()
      helper.assert_scenario({
        input = [[
          lambda fo|o, bar: (
              foo > bar
          )
        ]],
        filetype = "python",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          lambda foo, bar: (
              print("foo", foo)
              print("bar", bar)
              foo > bar
          )
        ]],
      })
    end)
  end)

  it("supports if statement", function()
    helper.assert_scenario({
      input = [[
        if fo|o > 1 and bar < baz:
            return None
        elif bar:
            return None
      ]],
      filetype = "python",
      action = function()
        vim.cmd("normal! vap")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        if foo > 1 and bar < baz:
            print("foo", foo)
            print("bar", bar)
            print("baz", baz)
            return None
        elif bar:
            print("bar", bar)
            return None
      ]],
    })
  end)

  it("supports match statement", function()
    helper.assert_scenario({
      input = [[
        match fo|o:
            case bar:
                print("bar")
            case baz:
                print("baz")
            case _:
                print("Other")
      ]],
      filetype = "python",
      action = function()
        vim.cmd("normal! vap")
        actions.insert_log({ position = "below" })
      end,
      -- TODO: this is not valid Python because of the indentation
      -- We may need a better indent algorithm
      expected = [[
        match foo:
            case bar:
                print("bar", bar)
                print("bar")
            case baz:
                print("baz", baz)
                print("baz")
            case _:
                print("Other")
                print("foo", foo)
      ]],
    })
  end)

  it("supports ternary expression", function()
    helper.assert_scenario({
      input = [[
        foo = "bar" if ba|r >= baz else "baz"
      ]],
      filetype = "python",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        foo = "bar" if bar >= baz else "baz"
        print("foo", foo)
        print("bar", bar)
        print("baz", baz)
      ]],
    })

    helper.assert_scenario({
      input = [[
        foo = (
            "bar" 
            if bar >= baz 
            else "baz"
        )
      ]],
      filetype = "python",
      action = function()
        vim.cmd("normal! vap")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        foo = (
            "bar" 
            if bar >= baz 
            else "baz"
        )
        print("foo", foo)
        print("bar", bar)
        print("baz", baz)
      ]],
    })
  end)

  it("supports for in loop statement", function()
    helper.assert_scenario({
      input = [[
        for ite|m in items:
            pass
      ]],
      filetype = "python",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        for item in items:
            print("item", item)
            print("items", items)
            pass
      ]],
    })

    helper.assert_scenario({
      input = [[
        for ite|m, index in enumerate(items):
            pass
      ]],
      filetype = "python",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        for item, index in enumerate(items):
            print("item", item)
            print("index", index)
            print("items", items)
            pass
      ]],
    })
  end)

  it("supports with statement", function()
    helper.assert_scenario({
      input = [[
        with open('input.txt', 'r') as inp|ut_file, \
             open('output.txt', 'w') as output_file:
            content = input_file.read()
            output_file.write(content.upper())
      ]],
      filetype = "python",
      action = function()
        vim.cmd("normal! Vj")
        actions.insert_log({ position = "below" })
      end,
      -- TODO: figure out how to handle nested containers
      expected = [[
        with open('input.txt', 'r') as input_file, \
             open('output.txt', 'w') as output_file:
             print("input_file", input_file)
             print("output_file", output_file)
            content = input_file.read()
            output_file.write(content.upper())
      ]],
    })
  end)

  describe("supports member access expression", function()
    it("supports dot member access", function()
      helper.assert_scenario({
        input = [[
          foo = ba|r.baz
        ]],
        filetype = "python",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          foo = bar.baz
          print("bar", bar)
        ]],
      })

      helper.assert_scenario({
        input = [[
          foo = bar.ba|z
        ]],
        filetype = "python",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          foo = bar.baz
          print("bar.baz", bar.baz)
        ]],
      })
    end)

    it("supports dictionary access", function()
      helper.assert_scenario({
        input = [[
          foo = ba|r["baz"]
        ]],
        filetype = "python",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          foo = bar["baz"]
          print("bar", bar)
        ]],
      })

      helper.assert_scenario({
        input = [[
          foo = bar["ba|z"]
        ]],
        filetype = "python",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          foo = bar["baz"]
          print("bar["baz"]", bar["baz"])
        ]],
      })
    end)
  end)

  it("supports while loop", function()
    helper.assert_scenario({
      input = [[
        foo = 0
        while fo|o < 5:
            foo += 1
        else:
            print("Loop completed")
      ]],
      filetype = "python",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        foo = 0
        while foo < 5:
            print("foo", foo)
            foo += 1
        else:
            print("Loop completed")
      ]],
    })
  end)

  describe("supports function call", function()
    it("support normal argument", function()
      helper.assert_scenario({
        input = [[
          foo(
              ba|r,
              baz
          )
        ]],
        filetype = "python",
        action = function()
          vim.cmd("normal! vap")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          foo(
              bar,
              baz
          )
          print("bar", bar)
          print("baz", baz)
        ]],
      })
    end)

    it("support keyword argument", function()
      helper.assert_scenario({
        input = [[
          foo(
              bar=ba|r,
              baz=baz
          )
        ]],
        filetype = "python",
        action = function()
          vim.cmd("normal! vap")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          foo(
              bar=bar,
              baz=baz
          )
          print("bar", bar)
          print("baz", baz)
        ]],
      })
    end)
  end)
end)

describe("python batch log", function()
  it("supports batch log", function()
    timber.setup({
      batch_log_templates = {
        default = {
          python = [[print(%repeat<"%log_target", %log_target><, >)]],
        },
      },
    })

    helper.assert_scenario({
      input = [[
        fo|o = bar + baz
      ]],
      filetype = "python",
      action = function()
        vim.cmd("normal! V")
        actions.add_log_targets_to_batch()
        actions.insert_batch_log()
      end,
      expected = [[
        foo = bar + baz
        print("foo", foo, "bar", bar, "baz", baz)
      ]],
    })
  end)
end)
