local timber = require("timber")
local helper = require("tests.timber.helper")
local actions = require("timber.actions")

describe("elixir single log", function()
  before_each(function()
    timber.setup({
      log_templates = {
        default = {
          elixir = [[IO.inspect(%log_target, label: "%log_target")]],
        },
      },
    })
  end)

  describe("supports pattern matching", function()
    it("supports simple pattern matching", function()
      helper.assert_scenario({
        input = [[
          fo|o = "bar"
        ]],
        filetype = "elixir",
        action = function()
          actions.insert_log({ position = "below" })
          actions.insert_log({ position = "above" })
        end,
        expected = [[
          IO.inspect(foo, label: "foo")
          foo = "bar"
          IO.inspect(foo, label: "foo")
        ]],
      })
    end)

    it("supports complex pattern matching", function()
      helper.assert_scenario({
        input = [[
          %{foo: foo, bar: bar} = %{foo: 1, b|ar: 2}
        ]],
        filetype = "elixir",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          %{foo: foo, bar: bar} = %{foo: 1, bar: 2}
          IO.inspect(foo, label: "foo")
          IO.inspect(bar, label: "bar")
        ]],
      })
    end)

    it("supports pattern matching with pin operator", function()
      helper.assert_scenario({
        input = [[
          %{foo: ^foo, bar: bar} = %{foo: 1, b|ar: 2}
        ]],
        filetype = "elixir",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          %{foo: ^foo, bar: bar} = %{foo: 1, bar: 2}
          IO.inspect(foo, label: "foo")
          IO.inspect(bar, label: "bar")
        ]],
      })
    end)
  end)

  describe("supports function parameters", function()
    describe("supports def", function()
      it("supports normal parameter", function()
        helper.assert_scenario({
          input = [[
            defmodule Test do
              def greet(fo|o, bar) do
                nil
              end
            end
          ]],
          filetype = "elixir",
          action = function()
            vim.cmd("normal! V")
            actions.insert_log({ position = "below" })
          end,
          expected = [[
            defmodule Test do
              def greet(foo, bar) do
                IO.inspect(foo, label: "foo")
                IO.inspect(bar, label: "bar")
                nil
              end
            end
          ]],
        })
      end)

      it("supports parameter with pattern matching", function()
        helper.assert_scenario({
          input = [[
            defmodule Test do
              def greet({ fo|o }, %{bar: bar}, baz = "baz") do
                nil
              end
            end
          ]],
          filetype = "elixir",
          action = function()
            vim.cmd("normal! V")
            actions.insert_log({ position = "below" })
          end,
          expected = [[
            defmodule Test do
              def greet({ foo }, %{bar: bar}, baz = "baz") do
                IO.inspect(foo, label: "foo")
                IO.inspect(bar, label: "bar")
                IO.inspect(baz, label: "baz")
                nil
              end
            end
          ]],
        })
      end)

      it("supports parameter in function guard clauses", function()
        helper.assert_scenario({
          input = [[
            defmodule Test do
              def greet(fo|o)
                when is_list(foo)
                when is_binary(foo)
              do
                nil
              end
            end
          ]],
          filetype = "elixir",
          action = function()
            vim.cmd("normal! V2j")
            actions.insert_log({ position = "below" })
          end,
          expected = [[
            defmodule Test do
              def greet(foo)
                when is_list(foo)
                when is_binary(foo)
              do
                IO.inspect(foo, label: "foo")
                IO.inspect(foo, label: "foo")
                IO.inspect(foo, label: "foo")
                nil
              end
            end
          ]],
        })
      end)
    end)

    it("supports defp", function()
      helper.assert_scenario({
        input = [[
          defmodule Test do
            defp greet({ fo|o: foo })
              when is_list(foo)
              when is_binary(foo)
            do
              nil
            end
          end
        ]],
        filetype = "elixir",
        action = function()
          vim.cmd("normal! V2j")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          defmodule Test do
            defp greet({ foo: foo })
              when is_list(foo)
              when is_binary(foo)
            do
              IO.inspect(foo, label: "foo")
              IO.inspect(foo, label: "foo")
              IO.inspect(foo, label: "foo")
              nil
            end
          end
        ]],
      })
    end)

    it("supports defmacro", function()
      helper.assert_scenario({
        input = [[
          defmodule Test do
            defmacro greet({ fo|o: foo })
              when is_list(foo)
              when is_binary(foo)
            do
              nil
            end
          end
        ]],
        filetype = "elixir",
        action = function()
          vim.cmd("normal! V2j")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          defmodule Test do
            defmacro greet({ foo: foo })
              when is_list(foo)
              when is_binary(foo)
            do
              IO.inspect(foo, label: "foo")
              IO.inspect(foo, label: "foo")
              IO.inspect(foo, label: "foo")
              nil
            end
          end
        ]],
      })
    end)

    it("supports anonymous function", function()
      helper.assert_scenario({
        input = [[
          Enum.each(1..5, fn fo|o ->
            foo + 1
          end)
        ]],
        filetype = "elixir",
        action = function()
          vim.cmd("normal! vap")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          Enum.each(1..5, fn foo ->
            IO.inspect(foo, label: "foo")
            foo + 1
            IO.inspect(foo, label: "foo")
          end)
        ]],
      })

      helper.assert_scenario({
        input = [[
          Enum.each(1..5, fn
            fo|o ->
              foo + 1
            ^bar ->
              bar + 1
          end)
        ]],
        filetype = "elixir",
        action = function()
          vim.cmd("normal! vap")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          Enum.each(1..5, fn
            foo ->
              IO.inspect(foo, label: "foo")
              foo + 1
              IO.inspect(foo, label: "foo")
            ^bar ->
              IO.inspect(bar, label: "bar")
              bar + 1
              IO.inspect(bar, label: "bar")
          end)
        ]],
      })
    end)

    it("DOES NOT log unused parameters", function()
      helper.assert_scenario({
        input = [[
          def test(fo|o, _bar, _baz, baf) do
            nil
          end
        ]],
        filetype = "elixir",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          def test(foo, _bar, _baz, baf) do
            IO.inspect(foo, label: "foo")
            IO.inspect(baf, label: "baf")
            nil
          end
        ]],
      })
    end)
  end)

  it("supports if expression", function()
    helper.assert_scenario({
      input = [[
        if not fo|o > 1 and bar < baz do
          foo + bar
        else
          foo - baz
        end
      ]],
      filetype = "elixir",
      action = function()
        vim.cmd("normal! vap")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        if not foo > 1 and bar < baz do
          IO.inspect(foo, label: "foo")
          IO.inspect(bar, label: "bar")
          IO.inspect(baz, label: "baz")
          foo + bar
          IO.inspect(foo, label: "foo")
          IO.inspect(bar, label: "bar")
        else
          foo - baz
          IO.inspect(foo, label: "foo")
          IO.inspect(baz, label: "baz")
        end
      ]],
    })

    helper.assert_scenario({
      input = [[
        if not fo|o > 1 and bar < baz do
          foo + bar
        else
          foo - baz
        end
      ]],
      filetype = "elixir",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "above" })
      end,
      expected = [[
        IO.inspect(foo, label: "foo")
        IO.inspect(bar, label: "bar")
        IO.inspect(baz, label: "baz")
        if not foo > 1 and bar < baz do
          foo + bar
        else
          foo - baz
        end
      ]],
    })
  end)

  it("supports unless expression", function()
    helper.assert_scenario({
      input = [[
        unless not fo|o > 1 and bar < baz do
          foo + bar
        else
          foo - baz
        end
      ]],
      filetype = "elixir",
      action = function()
        vim.cmd("normal! vap")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        unless not foo > 1 and bar < baz do
          IO.inspect(foo, label: "foo")
          IO.inspect(bar, label: "bar")
          IO.inspect(baz, label: "baz")
          foo + bar
          IO.inspect(foo, label: "foo")
          IO.inspect(bar, label: "bar")
        else
          foo - baz
          IO.inspect(foo, label: "foo")
          IO.inspect(baz, label: "baz")
        end
      ]],
    })

    helper.assert_scenario({
      input = [[
        unless not fo|o > 1 and bar < baz do
          foo + bar
        else
          foo - baz
        end
      ]],
      filetype = "elixir",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "above" })
      end,
      expected = [[
        IO.inspect(foo, label: "foo")
        IO.inspect(bar, label: "bar")
        IO.inspect(baz, label: "baz")
        unless not foo > 1 and bar < baz do
          foo + bar
        else
          foo - baz
        end
      ]],
    })
  end)

  it("supports case expression", function()
    helper.assert_scenario({
      input = [[
        case fo|o do
          ^bar ->
            bar + 1
          baz ->
            baz - 1
        end
      ]],
      filetype = "elixir",
      action = function()
        actions.insert_log({ position = "above" })
        vim.cmd("normal! vap")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        IO.inspect(foo, label: "foo")
        case foo do
          ^bar ->
            IO.inspect(bar, label: "bar")
            bar + 1
            IO.inspect(bar, label: "bar")
          baz ->
            IO.inspect(baz, label: "baz")
            baz - 1
            IO.inspect(baz, label: "baz")
        end
        IO.inspect(foo, label: "foo")
      ]],
    })
  end)

  it("supports cond expression", function()
    helper.assert_scenario({
      input = [[
        cond fo|o do
          bar > 1 ->
            bar + 1
          baz > 1 ->
            baz - 1
        end
      ]],
      filetype = "elixir",
      action = function()
        actions.insert_log({ position = "above" })
        vim.cmd("normal! vap")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        IO.inspect(foo, label: "foo")
        cond foo do
          bar > 1 ->
            IO.inspect(bar, label: "bar")
            bar + 1
            IO.inspect(bar, label: "bar")
          baz > 1 ->
            IO.inspect(baz, label: "baz")
            baz - 1
            IO.inspect(baz, label: "baz")
        end
        IO.inspect(foo, label: "foo")
      ]],
    })
  end)

  it("supports with expression", function()
    helper.assert_scenario({
      input = [[
        with (
          %{bar: bar} <- fo|o,
          %{baz: baz} <- bar
        ) do
          nil
        else
          e ->
            raise 1
        end
      ]],
      filetype = "elixir",
      action = function()
        actions.insert_log({ position = "above" })
        vim.cmd("normal! vap")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        IO.inspect(foo, label: "foo")
        with (
          %{bar: bar} <- foo,
          %{baz: baz} <- bar
        ) do
          IO.inspect(bar, label: "bar")
          IO.inspect(foo, label: "foo")
          IO.inspect(baz, label: "baz")
          IO.inspect(bar, label: "bar")
          nil
        else
          e ->
            IO.inspect(e, label: "e")
            raise 1
        end
      ]],
    })
  end)

  describe("supports list comprehension", function()
    it("supports do block", function()
      helper.assert_scenario({
        input = [[
          for fo|o <- 1..5, bar <- 1..3, foo > 3 do
            foo + bar
          end
        ]],
        filetype = "elixir",
        action = function()
          actions.insert_log({ position = "above" })
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          IO.inspect(foo, label: "foo")
          for foo <- 1..5, bar <- 1..3, foo > 3 do
            IO.inspect(foo, label: "foo")
            IO.inspect(bar, label: "bar")
            IO.inspect(foo, label: "foo")
            foo + bar
          end
        ]],
      })
    end)

    it("DOES NOT support do keyword", function()
      helper.assert_scenario({
        input = [[
          for fo|o <- 1..5, bar <- 1..3, foo > 3, do: foo + bar
        ]],
        filetype = "elixir",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          for foo <- 1..5, bar <- 1..3, foo > 3, do: foo + bar
        ]],
      })
    end)
  end)

  describe("supports identifier nested in complex expressions", function()
    it("supports ternary operator", function()
      helper.assert_scenario({
        input = [[
          foo =
            if pre|dicate do
              bar
            else
              baz
            end
        ]],
        filetype = "elixir",
        action = function()
          vim.cmd("normal! vap")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          foo =
            if predicate do
              IO.inspect(predicate, label: "predicate")
              bar
              IO.inspect(bar, label: "bar")
            else
              baz
              IO.inspect(baz, label: "baz")
            end
            IO.inspect(foo, label: "foo")
        ]],
      })
    end)

    it("supports map constructor", function()
      helper.assert_scenario({
        input = [[
          if true do
            %{ bar: ba|r, baz: baz }
          end
        ]],
        filetype = "elixir",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          if true do
            %{ bar: bar, baz: baz }
            IO.inspect(bar, label: "bar")
            IO.inspect(baz, label: "baz")
          end
        ]],
      })
    end)
  end)

  describe("supports function call", function()
    it("logs the function arguments", function()
      helper.assert_scenario({
        input = [[
          if true do
            foo(ba|r, baz)
          end
        ]],
        filetype = "elixir",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          if true do
            foo(bar, baz)
            IO.inspect(bar, label: "bar")
            IO.inspect(baz, label: "baz")
          end
        ]],
      })

      helper.assert_scenario({
        input = [[
          if true do
            Foo.bar(ba|r, baz)
          end
        ]],
        filetype = "elixir",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          if true do
            Foo.bar(bar, baz)
            IO.inspect(bar, label: "bar")
            IO.inspect(baz, label: "baz")
          end
        ]],
      })

      helper.assert_scenario({
        input = [[
          if true do
            foo.(ba|r, baz)
          end
        ]],
        filetype = "elixir",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          if true do
            foo.(bar, baz)
            IO.inspect(bar, label: "bar")
            IO.inspect(baz, label: "baz")
          end
        ]],
      })
    end)

    it("DOES NOT log the function name", function()
      helper.assert_scenario({
        input = [[
          if true do
            fo|o(bar, baz)
          end
        ]],
        filetype = "elixir",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          if true do
            foo(bar, baz)
          end
        ]],
      })

      helper.assert_scenario({
        input = [[
          if true do
            Foo.ba|r(bar, baz)
          end
        ]],
        filetype = "elixir",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          if true do
            Foo.bar(bar, baz)
          end
        ]],
      })
    end)
  end)

  it("supports map access expression", function()
    helper.assert_scenario({
      input = [[
        foo = ba|r["bar"]
      ]],
      filetype = "elixir",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        foo = bar["bar"]
        IO.inspect(bar, label: "bar")
      ]],
    })

    helper.assert_scenario({
      input = [[
        foo = bar["baz"]["ba|f"]
      ]],
      filetype = "elixir",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        foo = bar["baz"]["baf"]
        IO.inspect(bar["baz"]["baf"], label: "bar["baz"]["baf"]")
      ]],
    })

    helper.assert_scenario({
      input = [[
        foo = ba|r[:bar]
      ]],
      filetype = "elixir",
      action = function()
        vim.cmd("normal! v$")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        foo = bar[:bar]
        IO.inspect(bar, label: "bar")
      ]],
    })

    helper.assert_scenario({
      input = [[
        foo = bar[:ba|r]
      ]],
      filetype = "elixir",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        foo = bar[:bar]
        IO.inspect(bar[:bar], label: "bar[:bar]")
      ]],
    })
  end)

  it("supports struct access expression", function()
    helper.assert_scenario({
      input = [[
        foo = ba|r.baz
      ]],
      filetype = "elixir",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        foo = bar.baz
        IO.inspect(bar, label: "bar")
      ]],
    })

    helper.assert_scenario({
      input = [[
        foo = bar.baz.ba|f
      ]],
      filetype = "elixir",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        foo = bar.baz.baf
        IO.inspect(bar.baz.baf, label: "bar.baz.baf")
      ]],
    })
  end)

  it("supports binary operator", function()
    helper.assert_scenario({
      input = [[
        def test do
          foo + bar - ba|z
        end
      ]],
      filetype = "elixir",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        def test do
          foo + bar - baz
          IO.inspect(foo, label: "foo")
          IO.inspect(bar, label: "bar")
          IO.inspect(baz, label: "baz")
        end
      ]],
    })
  end)
end)

describe("elixir batch log", function()
  it("supports batch log", function()
    timber.setup({
      batch_log_templates = {
        default = {
          elixir = [[IO.inspect({ %repeat<%log_target><, > })]],
        },
      },
    })

    helper.assert_scenario({
      input = [[
        fo|o = bar + baz
      ]],
      filetype = "elixir",
      action = function()
        vim.cmd("normal! V")
        actions.add_log_targets_to_batch()
        actions.insert_batch_log()
      end,
      expected = [[
        foo = bar + baz
        IO.inspect({ foo, bar, baz })
      ]],
    })
  end)
end)
