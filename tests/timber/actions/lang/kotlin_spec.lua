local timber = require("timber")
local helper = require("tests.timber.helper")
local actions = require("timber.actions")

describe("kotlin single log", function()
  before_each(function()
    timber.setup({
      log_templates = {
        default = {
          kotlin = [[println("%log_target: ${%log_target}")]],
        },
      },
    })
  end)

  it("supports variable declaration", function()
    helper.assert_scenario({
      input = [[
        val fo|o = "bar"
      ]],
      filetype = "kotlin",
      action = function()
        actions.insert_log({ position = "above" })
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        println("foo: ${foo}")
        val foo = "bar"
        println("foo: ${foo}")
      ]],
    })
  end)

  it("supports this keyword", function()
    helper.assert_scenario({
      input = [[
        class Student(name: String, age: Int) {
          init {
            thi|s.name = name
            this.age = age
          }
        }
      ]],
      filetype = "kotlin",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        class Student(name: String, age: Int) {
          init {
            this.name = name
            println("this: ${this}")
            this.age = age
          }
        }
      ]],
    })
  end)

  it("supports function declaration", function()
    helper.assert_scenario({
      input = [[
        fun foo(ba|r: String, baz: Int) {
          return
        }
      ]],
      filetype = "kotlin",
      action = function()
        actions.insert_log({ position = "above" })
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        fun foo(bar: String, baz: Int) {
          println("bar: ${bar}")
          println("baz: ${baz}")
          return
        }
      ]],
    })
  end)

  describe("supports loop statements", function()
    it("supports for loop", function()
      helper.assert_scenario({
        input = [[
          for (item in ite|ms) {
            continue
          }
        ]],
        filetype = "kotlin",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          for (item in items) {
            println("item: ${item}")
            println("items: ${items}")
            continue
          }
        ]],
      })
    end)

    it("supports while loop", function()
      helper.assert_scenario({
        input = [[
          while (fo|o > 1 && bar < baz) {
            break
          }
        ]],
        filetype = "kotlin",
        action = function()
          actions.insert_log({ position = "above" })
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          println("foo: ${foo}")
          while (foo > 1 && bar < baz) {
            println("foo: ${foo}")
            println("bar: ${bar}")
            println("baz: ${baz}")
            break
          }
        ]],
      })
    end)

    it("supports do while loop", function()
      helper.assert_scenario({
        input = [[
          do {
            number++
          } while (nu|mber < 3)
        ]],
        filetype = "kotlin",
        action = function()
          actions.insert_log({ position = "above" })
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          do {
            number++
            println("number: ${number}")
          } while (number < 3)
          println("number: ${number}")
        ]],
      })
    end)
  end)

  it("supports if-else statement", function()
    helper.assert_scenario({
      input = [[
        if (fo|o > 1 && bar < baz) {
          return true
        } else if (qux) {
          return false
        } else {
          return null
        }
      ]],
      filetype = "kotlin",
      action = function()
        vim.cmd("normal! vap")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        if (foo > 1 && bar < baz) {
          println("foo: ${foo}")
          println("bar: ${bar}")
          println("baz: ${baz}")
          return true
        } else if (qux) {
          println("qux: ${qux}")
          return false
        } else {
          return null
        }
      ]],
    })
  end)

  it("supports when expression", function()
    helper.assert_scenario({
      input = [[
        val result = when (fo|o) {
          1 -> "one"
          bar == 2 -> {
            "two"
          }
          else -> "other"
        }
      ]],
      filetype = "kotlin",
      action = function()
        vim.cmd("normal! vap")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        val result = when (foo) {
          1 -> "one"
          bar == 2 -> {
            println("bar: ${bar}")
            "two"
          }
          else -> "other"
        }
        println("result: ${result}")
        println("foo: ${foo}")
      ]],
    })
  end)

  it("supports function invocations", function()
    helper.assert_scenario({
      input = [[
        someObject.doSomething(fo|o, bar)
      ]],
      filetype = "kotlin",
      action = function()
        vim.cmd("normal! vi(")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        someObject.doSomething(foo, bar)
        println("foo: ${foo}")
        println("bar: ${bar}")
      ]],
    })
  end)

  it("supports member access expression", function()
    helper.assert_scenario({
      input = [[
        val foo = ba|r.bar
      ]],
      filetype = "kotlin",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        val foo = bar.bar
        println("bar: ${bar}")
      ]],
    })

    helper.assert_scenario({
      input = [[
        val foo = bar.ba|z.baf
      ]],
      filetype = "kotlin",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        val foo = bar.baz.baf
        println("bar.baz: ${bar.baz}")
      ]],
    })

    helper.assert_scenario({
      input = [[
        val foo = ba|r.bar
      ]],
      filetype = "kotlin",
      action = function()
        vim.cmd("normal! v$")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        val foo = bar.bar
        println("bar: ${bar}")
      ]],
    })

    helper.assert_scenario({
      input = [[
        val foo = ba|r.bar
      ]],
      filetype = "kotlin",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        val foo = bar.bar
        println("foo: ${foo}")
        println("bar.bar: ${bar.bar}")
      ]],
    })
  end)

  it("supports lambda expressions", function()
    helper.assert_scenario({
      input = [[
        list.forEach { ite|m ->
          process(item)
        }
      ]],
      filetype = "kotlin",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        list.forEach { item ->
          println("item: ${item}")
          process(item)
        }
      ]],
    })
  end)

  it("supports try-catch block", function()
    helper.assert_scenario({
      input = [[
        try {
          process(foo)
        } catch (e|: Exception) {
          handleError(e)
        }
      ]],
      filetype = "kotlin",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        try {
          process(foo)
        } catch (e: Exception) {
          println("e: ${e}")
          handleError(e)
        }
      ]],
    })
  end)
end)

describe("kotlin batch log", function()
  it("supports batch log", function()
    timber.setup({
      batch_log_templates = {
        default = {
          kotlin = [[println("%repeat<%log_target=${%log_target}><, >")]],
        },
      },
    })

    helper.assert_scenario({
      input = [[
        val fo|o = bar + baz
      ]],
      filetype = "kotlin",
      action = function()
        vim.cmd("normal! V")
        actions.add_log_targets_to_batch()
        actions.insert_batch_log()
      end,
      expected = [[
        val foo = bar + baz
        println("foo=${foo}, bar=${bar}, baz=${baz}")
      ]],
    })
  end)
end)
