local timber = require("timber")
local helper = require("tests.timber.helper")
local actions = require("timber.actions")

describe("csharp single log", function()
  before_each(function()
    timber.setup({
      log_templates = {
        default = {
          c_sharp = [[Console.WriteLine($"%log_target: {%log_target}");]],
        },
      },
    })
  end)

  it("supports variable declaration", function()
    helper.assert_scenario({
      input = [[
        var fo|o = "bar";
      ]],
      filetype = "cs",
      action = function()
        actions.insert_log({ position = "below" })
        actions.insert_log({ position = "above" })
      end,
      expected = [[
        Console.WriteLine($"foo: {foo}");
        var foo = "bar";
        Console.WriteLine($"foo: {foo}");
      ]],
    })
  end)

  it("supports variable assignment", function()
    helper.assert_scenario({
      input = [[
        var foo = "bar";
        fo|o = "baz";
      ]],
      filetype = "cs",
      action = function()
        actions.insert_log({ position = "below" })
        actions.insert_log({ position = "above" })
      end,
      expected = [[
        var foo = "bar";
        Console.WriteLine($"foo: {foo}");
        foo = "baz";
        Console.WriteLine($"foo: {foo}");
      ]],
    })
  end)

  it("supports foreach loop", function()
    helper.assert_scenario({
      input = [[
        foreach (var ite|m in items)
        {
          return;
        }
      ]],
      filetype = "cs",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        foreach (var item in items)
        {
          Console.WriteLine($"item: {item}");
          Console.WriteLine($"items: {items}");
          return;
        }
      ]],
    })
  end)

  describe("supports member access expression", function()
    it("supports dot member access", function()
      helper.assert_scenario({
        input = [[
          var foo = ba|r.baz;
        ]],
        filetype = "cs",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          var foo = bar.baz;
          Console.WriteLine($"bar: {bar}");
        ]],
      })

      helper.assert_scenario({
        input = [[
          var foo = bar.ba|z.baf;
        ]],
        filetype = "cs",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          var foo = bar.baz.baf;
          Console.WriteLine($"bar.baz: {bar.baz}");
        ]],
      })

      helper.assert_scenario({
        input = [[
          var foo = ba|r.bar;
        ]],
        filetype = "cs",
        action = function()
          vim.cmd("normal! v$")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          var foo = bar.bar;
          Console.WriteLine($"bar: {bar}");
        ]],
      })

      helper.assert_scenario({
        input = [[
          var foo = ba|r.bar;
        ]],
        filetype = "cs",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          var foo = bar.bar;
          Console.WriteLine($"foo: {foo}");
          Console.WriteLine($"bar.bar: {bar.bar}");
        ]],
      })
    end)

    it("supports bracket member access", function()
      helper.assert_scenario({
        input = [[
          var foo = ba|r["bar"];
        ]],
        filetype = "cs",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          var foo = bar["bar"];
          Console.WriteLine($"bar: {bar}");
        ]],
      })

      helper.assert_scenario({
        input = [[
          var foo = bar["ba|z"]["baf"];
        ]],
        filetype = "cs",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          var foo = bar["baz"]["baf"];
          Console.WriteLine($"bar["baz"]: {bar["baz"]}");
        ]],
      })

      helper.assert_scenario({
        input = [[
          var foo = ba|r["bar"];
        ]],
        filetype = "cs",
        action = function()
          vim.cmd("normal! v$")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          var foo = bar["bar"];
          Console.WriteLine($"bar: {bar}");
        ]],
      })

      helper.assert_scenario({
        input = [[
          var foo = ba|r["bar"];
        ]],
        filetype = "cs",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          var foo = bar["bar"];
          Console.WriteLine($"foo: {foo}");
          Console.WriteLine($"bar["bar"]: {bar["bar"]}");
        ]],
      })
    end)
  end)

  it("supports if-else statement", function()
    helper.assert_scenario({
      input = [[
        if (fo|o > bar)
        {
          return true;
        }
        else if (foo < 20)
        {
          return false;
        }
      ]],
      filetype = "cs",
      action = function()
        vim.cmd("normal! vap")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        if (foo > bar)
        {
          Console.WriteLine($"foo: {foo}");
          Console.WriteLine($"bar: {bar}");
          return true;
        }
        else if (foo < 20)
        {
          Console.WriteLine($"foo: {foo}");
          return false;
        }
      ]],
    })
  end)

  it("supports while loop", function()
    helper.assert_scenario({
      input = [[
        while (coun|t < max)
        {
          count++;
        }
      ]],
      filetype = "cs",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        while (count < max)
        {
          Console.WriteLine($"count: {count}");
          Console.WriteLine($"max: {max}");
          count++;
        }
      ]],
    })
  end)

  it("supports do-while loop", function()
    helper.assert_scenario({
      input = [[
        do
        {
          count++;
        } while (co|unt < max);
      ]],
      filetype = "cs",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "above" })
      end,
      expected = [[
        do
        {
          count++;
          Console.WriteLine($"count: {count}");
          Console.WriteLine($"max: {max}");
        } while (count < max);
      ]],
    })
  end)

  it("supports try-catch block", function()
    helper.assert_scenario({
      input = [[
        try
        {
          result = Process();
        }
        catch (Exception e|x)
        {
          HandleError(ex);
        }
      ]],
      filetype = "cs",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        try
        {
          result = Process();
        }
        catch (Exception ex)
        {
          Console.WriteLine($"ex: {ex}");
          HandleError(ex);
        }
      ]],
    })
  end)

  it("supports switch-case statement", function()
    helper.assert_scenario({
      input = [[
        switch (val|ue)
        {
          case foo:
            DoSomething();
            break;
          case bar:
            DoSomethingElse();
            break;
          default:
            DoDefault();
            break;
        }
      ]],
      filetype = "cs",
      action = function()
        vim.cmd("normal! vap")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        switch (value)
        {
          case foo:
            Console.WriteLine($"foo: {foo}");
            DoSomething();
            break;
          case bar:
            Console.WriteLine($"bar: {bar}");
            DoSomethingElse();
            break;
          default:
            DoDefault();
            break;
        }
        Console.WriteLine($"value: {value}");
      ]],
    })
  end)

  describe("supports function invocation", function()
    it("supports function arguments", function()
      helper.assert_scenario({
        input = [[
          foo(bar, ba|z);
        ]],
        filetype = "cs",
        action = function()
          vim.cmd("normal! vi(")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          foo(bar, baz);
          Console.WriteLine($"bar: {bar}");
          Console.WriteLine($"baz: {baz}");
        ]],
      })
    end)

    it("DOES NOT support function name", function()
      helper.assert_scenario({
        input = [[
          fo|o(bar, baz);
        ]],
        filetype = "cs",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          foo(bar, baz);
        ]],
      })
    end)
  end)
end)

describe("cs batch log", function()
  it("supports batch log", function()
    timber.setup({
      batch_log_templates = {
        default = {
          c_sharp = [[Console.WriteLine($"%repeat<%log_target: {%log_target}><, >");]],
        },
      },
    })

    helper.assert_scenario({
      input = [[
        var fo|o = bar + baz;
      ]],
      filetype = "cs",
      action = function()
        vim.cmd("normal! V")
        actions.add_log_targets_to_batch()
        actions.insert_batch_log()
      end,
      expected = [[
        var foo = bar + baz;
        Console.WriteLine($"foo: {foo}, bar: {bar}, baz: {baz}");
      ]],
    })
  end)
end)
