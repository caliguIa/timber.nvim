local timber = require("timber")
local helper = require("tests.timber.helper")
local actions = require("timber.actions")

describe("luau single log", function()
  before_each(function()
    timber.setup({
      log_templates = {
        default = {
          luau = [[print("%log_target", %log_target)]],
        },
      },
    })
  end)

  it("supports variable declaration", function()
    local input = [[
      local fo|o: string = "bar"
    ]]

    local expected = [[
      local foo: string = "bar"
      print("foo", foo)
    ]]

    helper.assert_scenario({
      input = input,
      filetype = "luau",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = expected,
    })

    expected = [[
      print("foo", foo)
      local foo: string = "bar"
    ]]

    helper.assert_scenario({
      input = input,
      filetype = "luau",
      action = function()
        actions.insert_log({ position = "above" })
      end,
      expected = expected,
    })
  end)

  it("supports variable assignment", function()
    local input = [[
      local foo: Array<string> = {"bar"}
      fo|o = "baz"
    ]]

    local expected = [[
      local foo: Array<string> = {"bar"}
      foo = "baz"
      print("foo", foo)
    ]]

    helper.assert_scenario({
      input = input,
      filetype = "luau",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = expected,
    })

    expected = [[
      local foo: Array<string> = {"bar"}
      print("foo", foo)
      foo = "baz"
    ]]

    helper.assert_scenario({
      input = input,
      filetype = "luau",
      action = function()
        actions.insert_log({ position = "above" })
      end,
      expected = expected,
    })
  end)

  it("supports return statement", function()
    helper.assert_scenario({
      input = [[
        function foo(): string
          return bar + b|az
        end
      ]],
      filetype = "luau",
      action = function()
        actions.insert_log({ position = "below" })
        vim.cmd("normal! V")
        actions.insert_log({ position = "above" })
      end,
      expected = [[
        function foo(): string
          print("bar", bar)
          print("baz", baz)
          return bar + baz
        end
      ]],
    })
  end)

  describe("supports function parameters", function()
    it("supports function declaration", function()
      helper.assert_scenario({
        input = [[
          function foo(ba|r: string): number?
            return nil
          end
        ]],
        filetype = "luau",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          function foo(bar: string): number?
            print("bar", bar)
            return nil
          end
        ]],
      })

      helper.assert_scenario({
        input = [[
          local function foo(
            ba|r: string,
            baz: string,
          ): string?
            return nil
          end
        ]],
        filetype = "luau",
        action = function()
          vim.cmd("normal! Vj")
          actions.insert_log({ position = "above" })
        end,
        expected = [[
          local function foo(
            bar: string,
            baz: string,
          ): string?
            return nil
          end
        ]],
      })
    end)

    it("supports function definition", function()
      helper.assert_scenario({
        input = [[
          local foo = {
            bar = function(ba|z: string, baf: Baf)
              return nil
            end,
          }
        ]],
        filetype = "luau",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          local foo = {
            bar = function(baz: string, baf: Baf)
              print("baz", baz)
              print("baf", baf)
              return nil
            end,
          }
        ]],
      })
    end)

    it("DOES NOT support ignored parameters", function()
      helper.assert_scenario({
        input = [[
          function foo(ba|r: number, _)
            return nil
          end
        ]],
        filetype = "luau",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          function foo(bar: number, _)
            print("bar", bar)
            return nil
          end
        ]],
      })
    end)
  end)

  it("DOES NOT support function name in function call", function()
    helper.assert_scenario({
      input = [[
        foo.bar(ba|z)
      ]],
      filetype = "luau",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        foo.bar(baz)
        print("baz", baz)
      ]],
    })

    helper.assert_scenario({
      input = [[
        if not (foo.bar or foo.baz)(ba|z) then
          return nil
        end
      ]],
      filetype = "luau",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        if not (foo.bar or foo.baz)(baz) then
          print("baz", baz)
          return nil
        end
      ]],
    })
  end)

  it("supports if statement", function()
    helper.assert_scenario({
      input = [[
        if not fo|o > 1 and bar < baz then
          return nil
        elseif bar then
          return nil
        elseif baz then
          return nil
        end
      ]],
      filetype = "luau",
      action = function()
        vim.cmd("normal! vap")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        if not foo > 1 and bar < baz then
          print("foo", foo)
          print("bar", bar)
          print("baz", baz)
          return nil
        elseif bar then
          print("bar", bar)
          return nil
        elseif baz then
          print("baz", baz)
          return nil
        end
      ]],
    })

    helper.assert_scenario({
      input = [[
        if fo|o > 1 then
          return nil
        elseif bar then
          return nil
        end
      ]],
      filetype = "luau",
      action = function()
        vim.cmd("normal! vap")
        actions.insert_log({ position = "above" })
      end,
      expected = [[
        print("foo", foo)
        print("bar", bar)
        if foo > 1 then
          return nil
        elseif bar then
          return nil
        end
      ]],
    })
  end)

  describe("supports for loop statement", function()
    it("supports for loop numeric", function()
      helper.assert_scenario({
        input = [[
          for fo|o: number = 1, 10, 1 do
            return nil
          end
        ]],
        filetype = "luau",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          for foo: number = 1, 10, 1 do
            print("foo", foo)
            return nil
          end
        ]],
      })
    end)

    it("supports for loop pairs", function()
      helper.assert_scenario({
        input = [[
          for ke|y: string, value: any in pairs(t) do
            return nil
          end
        ]],
        filetype = "luau",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          for key: string, value: any in pairs(t) do
            print("key", key)
            print("value", value)
            print("t", t)
            return nil
          end
        ]],
      })
    end)

    it("supports for loop ipairs", function()
      helper.assert_scenario({
        input = [[
          for ke|y: number, value: any in ipairs(t) do
            return nil
          end
        ]],
        filetype = "luau",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          for key: number, value: any in ipairs(t) do
            print("key", key)
            print("value", value)
            print("t", t)
            return nil
          end
        ]],
      })
    end)
  end)

  it("supports while loop", function()
    helper.assert_scenario({
      input = [[
        while fo|o > 1 and bar < baz do
          return nil
        end
      ]],
      filetype = "luau",
      action = function()
        actions.insert_log({ position = "above" })
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        print("foo", foo)
        while foo > 1 and bar < baz do
          print("foo", foo)
          print("bar", bar)
          print("baz", baz)
          return nil
        end
      ]],
    })
  end)

  it("supports repeat until loop", function()
    helper.assert_scenario({
      input = [[
        repeat
          return nil
        until fo|o > 1 and bar < baz
      ]],
      filetype = "luau",
      action = function()
        actions.insert_log({ position = "below" })
        vim.cmd("normal! V")
        actions.insert_log({ position = "above" })
      end,
      expected = [[
        repeat
          return nil
          print("foo", foo)
          print("bar", bar)
          print("baz", baz)
        until foo > 1 and bar < baz
        print("foo", foo)
      ]],
    })
  end)

  describe("supports identifier nested in complex expressions", function()
    it("supports ternary operator", function()
      local input = [[
        local foo: boolean =
          predicate and
            ba|r or
            baz
      ]]

      local expected1 = [[
        local foo: boolean =
          predicate and
            bar or
            baz
            print("bar", bar)
      ]]

      local expected2 = [[
        print("bar", bar)
        local foo: boolean =
          predicate and
            bar or
            baz
      ]]

      helper.assert_scenario({
        input = input,
        filetype = "luau",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = expected1,
      })

      helper.assert_scenario({
        input = input,
        filetype = "luau",
        action = function()
          actions.insert_log({ position = "above" })
        end,
        expected = expected2,
      })
    end)

    it("supports table constructor", function()
      helper.assert_scenario({
        input = [[
          local foo: {[string]: string} = { bar = b|ar }
        ]],
        filetype = "luau",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          local foo: {[string]: string} = { bar = bar }
          print("bar", bar)
        ]],
      })

      helper.assert_scenario({
        input = [[
          local foo: {[string]: string} = { b|ar = bar }
        ]],
        filetype = "luau",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          local foo: {[string]: string} = { bar = bar }
        ]],
      })
    end)

    it("supports function invocations", function()
      helper.assert_scenario({
        input = [[
          foo(ba|r, baz)
        ]],
        filetype = "luau",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          foo(bar, baz)
          print("bar", bar)
        ]],
      })

      helper.assert_scenario({
        input = [[
          foo(ba|r, baz)
        ]],
        filetype = "luau",
        action = function()
          actions.insert_log({ position = "above" })
        end,
        expected = [[
          print("bar", bar)
          foo(bar, baz)
        ]],
      })

      helper.assert_scenario({
        input = [[
          foo(ba|r, baz)
        ]],
        filetype = "luau",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          foo(bar, baz)
          print("bar", bar)
          print("baz", baz)
        ]],
      })
    end)
  end)

  describe("supports member access expression", function()
    it("supports dot member access", function()
      helper.assert_scenario({
        input = [[
          local foo: any = ba|r.bar
        ]],
        filetype = "luau",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          local foo: any = bar.bar
          print("bar", bar)
        ]],
      })

      helper.assert_scenario({
        input = [[
          local foo: any = bar.ba|z.baf
        ]],
        filetype = "luau",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          local foo: any = bar.baz.baf
          print("bar.baz", bar.baz)
        ]],
      })

      helper.assert_scenario({
        input = [[
          local foo: any = ba|r.bar
        ]],
        filetype = "luau",
        action = function()
          vim.cmd("normal! v$")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          local foo: any = bar.bar
          print("bar", bar)
        ]],
      })

      helper.assert_scenario({
        input = [[
          local foo: any = ba|r.bar
        ]],
        filetype = "luau",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          local foo: any = bar.bar
          print("foo", foo)
          print("bar.bar", bar.bar)
        ]],
      })
    end)

    it("supports bracket member access", function()
      helper.assert_scenario({
        input = [[
          local foo: string = ba|r["bar"]
        ]],
        filetype = "luau",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          local foo: string = bar["bar"]
          print("bar", bar)
        ]],
      })

      helper.assert_scenario({
        input = [[
          local foo: string = bar["ba|z"]["baf"]
        ]],
        filetype = "luau",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          local foo: string = bar["baz"]["baf"]
          print("bar["baz"]", bar["baz"])
        ]],
      })

      helper.assert_scenario({
        input = [[
          local foo: string = ba|r["bar"]
        ]],
        filetype = "luau",
        action = function()
          vim.cmd("normal! v$")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          local foo: string = bar["bar"]
          print("bar", bar)
        ]],
      })

      helper.assert_scenario({
        input = [[
          local foo: string = ba|r["bar"]
        ]],
        filetype = "luau",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          local foo: string = bar["bar"]
          print("foo", foo)
          print("bar["bar"]", bar["bar"])
        ]],
      })
    end)
  end)

  describe("supports visual selection log", function()
    it("supports variable declaration", function()
      helper.assert_scenario({
        input = [[
          local a = b| + c
        ]],
        filetype = "luau",
        action = function()
          vim.cmd("normal! v$")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          local a = b + c
          print("b", b)
          print("c", c)
        ]],
      })

      helper.assert_scenario({
        input = [[
          local a = b| + c
        ]],
        filetype = "luau",
        action = function()
          vim.cmd("normal! v$")
          actions.insert_log({ position = "above" })
        end,
        expected = [[
          print("b", b)
          print("c", c)
          local a = b + c
        ]],
      })

      helper.assert_scenario({
        input = [[
          local a = b + c
          local a1 = {b = b|1, c = c1}
        ]],
        filetype = "luau",
        action = function()
          vim.cmd("normal! Vk")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          local a = b + c
          print("a", a)
          print("b", b)
          print("c", c)
          local a1 = {b = b1, c = c1}
          print("a1", a1)
          print("b1", b1)
          print("c1", c1)
        ]],
      })

      helper.assert_scenario({
        input = [[
          local a = b + c
          local a1 = {b = b|1, c = c1}
        ]],
        filetype = "luau",
        action = function()
          vim.cmd("normal! Vk")
          actions.insert_log({ position = "above" })
        end,
        expected = [[
          print("a", a)
          print("b", b)
          print("c", c)
          local a = b + c
          print("a1", a1)
          print("b1", b1)
          print("c1", c1)
          local a1 = {b = b1, c = c1}
        ]],
      })
    end)

    it("supports function parameters", function()
      helper.assert_scenario({
        input = [[
          function foo(a, b|, c)
            return nil
          end
        ]],
        filetype = "luau",
        action = function()
          vim.cmd("normal! vi)")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          function foo(a, b, c)
            print("a", a)
            print("b", b)
            print("c", c)
            return nil
          end
        ]],
      })
    end)
  end)
end)

describe("luau batch log", function()
  it("supports batch log", function()
    timber.setup({
      batch_log_templates = {
        default = {
          luau = [[print(`%repeat<%log_target={%log_target}><, >`)]],
        },
      },
    })

    helper.assert_scenario({
      input = [[
        local fo|o: string = bar + baz
      ]],
      filetype = "luau",
      action = function()
        vim.cmd("normal! V")
        actions.add_log_targets_to_batch()
        actions.insert_batch_log()
      end,
      expected = [[
        local foo: string = bar + baz
        print(`foo={foo}, bar={bar}, baz={baz}`)
      ]],
    })
  end)
end)
