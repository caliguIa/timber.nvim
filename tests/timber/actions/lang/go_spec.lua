local timber = require("timber")
local helper = require("tests.timber.helper")
local actions = require("timber.actions")

describe("go single log", function()
  before_each(function()
    timber.setup({
      log_templates = {
        default = {
          go = [[log.Printf("%identifier: %v\n", %identifier)]],
        },
      },
    })
  end)

  it("supports variable declaration", function()
    helper.assert_scenario({
      input = [[
        var fo|o string = "bar"
      ]],
      filetype = "go",
      action = function()
        actions.insert_log({ position = "below" })
        actions.insert_log({ position = "above" })
      end,
      expected = [[
        log.Printf("foo: %v\n", foo)
        var foo string = "bar"
        log.Printf("foo: %v\n", foo)
      ]],
    })

    helper.assert_scenario({
      input = [[
        var fo|o, bar, baz int = 1, 2, 3
      ]],
      filetype = "go",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        var foo, bar, baz int = 1, 2, 3
        log.Printf("foo: %v\n", foo)
        log.Printf("bar: %v\n", bar)
        log.Printf("baz: %v\n", baz)
      ]],
    })
  end)

  it("supports variable shorthand declaration", function()
    helper.assert_scenario({
      input = [[
        func test() {
          fo|o := "bar"
        }
      ]],
      filetype = "go",
      action = function()
        actions.insert_log({ position = "below" })
        actions.insert_log({ position = "above" })
      end,
      expected = [[
        func test() {
          log.Printf("foo: %v\n", foo)
          foo := "bar"
          log.Printf("foo: %v\n", foo)
        }
      ]],
    })

    helper.assert_scenario({
      input = [[
        func test() {
          fo|o, bar := 1, 2
        }
      ]],
      filetype = "go",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        func test() {
          foo, bar := 1, 2
          log.Printf("foo: %v\n", foo)
          log.Printf("bar: %v\n", bar)
        }
      ]],
    })
  end)

  it("supports variable assignment", function()
    helper.assert_scenario({
      input = [[
        var foo string = "bar"
        fo|o = "baz"
      ]],
      filetype = "go",
      action = function()
        actions.insert_log({ position = "below" })
        actions.insert_log({ position = "above" })
      end,
      expected = [[
        var foo string = "bar"
        log.Printf("foo: %v\n", foo)
        foo = "baz"
        log.Printf("foo: %v\n", foo)
      ]],
    })
  end)

  describe("supports function parameters", function()
    it("supports named function", function()
      helper.assert_scenario({
        input = [[
          func foo(ba|r int, baz string) int {
            return bar
          }
        ]],
        filetype = "go",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          func foo(bar int, baz string) int {
            log.Printf("bar: %v\n", bar)
            log.Printf("baz: %v\n", baz)
            return bar
          }
        ]],
      })
    end)

    it("supports anonymous function", function()
      helper.assert_scenario({
        input = [[
          var sum = func(fo|o int, bar int) int {
            return foo + bar
          }
        ]],
        filetype = "go",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          var sum = func(foo int, bar int) int {
            log.Printf("foo: %v\n", foo)
            log.Printf("bar: %v\n", bar)
            return foo + bar
          }
          log.Printf("sum: %v\n", sum)
        ]],
      })
    end)

    it("supports method function", function()
      helper.assert_scenario({
        input = [[
          func (fo|o *Foo) Sum(bar int) int {
            return foo + bar
          }
        ]],
        filetype = "go",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          func (foo *Foo) Sum(bar int) int {
            log.Printf("foo: %v\n", foo)
            log.Printf("bar: %v\n", bar)
            return foo + bar
          }
        ]],
      })
    end)

    it("DOES NOT support ignored parameters", function()
      helper.assert_scenario({
        input = [[
          func sum(fo|o int, bar int, _) int {
            return foo + bar
          }
        ]],
        filetype = "go",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          func sum(foo int, bar int, _) int {
            log.Printf("foo: %v\n", foo)
            log.Printf("bar: %v\n", bar)
            return foo + bar
          }
        ]],
      })
    end)

    it("DOES NOT support identifier in type declaration", function()
      helper.assert_scenario({
        input = [[
          func sum(callback func(a int, b int) int, c int, d int) int {
            return callback(c, d)
          }
        ]],
        filetype = "go",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          func sum(callback func(a int, b int) int, c int, d int) int {
            log.Printf("callback: %v\n", callback)
            log.Printf("c: %v\n", c)
            log.Printf("d: %v\n", d)
            return callback(c, d)
          }
        ]],
      })
    end)
  end)

  it("DOES NOT support single function name", function()
    helper.assert_scenario({
      input = [[
        foo := ba|r(1)
      ]],
      filetype = "go",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        foo := bar(1)
      ]],
    })

    helper.assert_scenario({
      input = [[
        foo := bar.ba|z(1)
      ]],
      filetype = "go",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        foo := bar.baz(1)
      ]],
    })

    helper.assert_scenario({
      input = [[
        foo := ba|r.baz(1)
      ]],
      filetype = "go",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        foo := bar.baz(1)
        log.Printf("bar: %v\n", bar)
      ]],
    })
  end)

  it("supports function return statement", function()
    helper.assert_scenario({
      input = [[
        func test() {
          foo := 1
          return fo|o + 1
        }
      ]],
      filetype = "go",
      action = function()
        actions.insert_log({ position = "below" })
        actions.insert_log({ position = "above" })
      end,
      expected = [[
        func test() {
          foo := 1
          log.Printf("foo: %v\n", foo)
          return foo + 1
          log.Printf("foo: %v\n", foo)
        }
      ]],
    })

    helper.assert_scenario({
      input = [[
        foo := bar.ba|z(1)
      ]],
      filetype = "go",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        foo := bar.baz(1)
      ]],
    })
  end)

  it("supports if statement", function()
    helper.assert_scenario({
      input = [[
        if fo|o < 0 {
          fmt.Println("Number is negative")
        } else if foo == 0 {
          fmt.Println("Number is zero")
        } else {
          fmt.Println("Number is positive")
        }
      ]],
      filetype = "go",
      action = function()
        vim.cmd("normal! vap")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        if foo < 0 {
          log.Printf("foo: %v\n", foo)
          fmt.Println("Number is negative")
        } else if foo == 0 {
          log.Printf("foo: %v\n", foo)
          fmt.Println("Number is zero")
        } else {
          fmt.Println("Number is positive")
        }
      ]],
    })
  end)

  it("supports switch statement", function()
    helper.assert_scenario({
      input = [[
        switch fo|o {
        case a, b:
          return foo + 1
        case c:
          return foo + 2
        default:
          return foo + 3
        }
      ]],
      filetype = "go",
      action = function()
        actions.insert_log({ position = "above" })
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        log.Printf("foo: %v\n", foo)
        switch foo {
        log.Printf("foo: %v\n", foo)
        case a, b:
          return foo + 1
        case c:
          return foo + 2
        default:
          return foo + 3
        }
      ]],
    })

    helper.assert_scenario({
      input = [[
        switch fo|o {
        case a|, b:
          return foo + 1
        case c:
          return foo + 2
        default:
          return foo + 3
        }
      ]],
      filetype = "go",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        switch foo {
        case a, b:
          log.Printf("a: %v\n", a)
          log.Printf("b: %v\n", b)
          return foo + 1
        case c:
          return foo + 2
        default:
          return foo + 3
        }
      ]],
    })
  end)

  it("supports for loop statement", function()
    helper.assert_scenario({
      input = [[
        for i| := 0; i < 5; i++ {
          fmt.Printf("Count: %d\n", i)
        }
      ]],
      filetype = "go",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        for i := 0; i < 5; i++ {
          log.Printf("i: %v\n", i)
          log.Printf("i: %v\n", i)
          log.Printf("i: %v\n", i)
          fmt.Printf("Count: %d\n", i)
        }
      ]],
    })
  end)

  it("supports while loop", function()
    helper.assert_scenario({
      input = [[
        count := 0
        for co|unt < 3 {
          count++
        }
      ]],
      filetype = "go",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        count := 0
        for count < 3 {
          log.Printf("count: %v\n", count)
          count++
        }
      ]],
    })
  end)

  it("supports range loop", function()
    helper.assert_scenario({
      input = [[
        numbers := []int{1, 2, 3, 4, 5}
        for ind|ex, value := range numbers {
          return nil
        }
      ]],
      filetype = "go",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        numbers := []int{1, 2, 3, 4, 5}
        for index, value := range numbers {
          log.Printf("index: %v\n", index)
          log.Printf("value: %v\n", value)
          log.Printf("numbers: %v\n", numbers)
          return nil
        }
      ]],
    })
  end)

  it("supports select statement", function()
    helper.assert_scenario({
      input = [[
        select {
        case fo|o := <-ch1:
          return
        case <-ch2:
          return
        }
      ]],
      filetype = "go",
      action = function()
        vim.cmd("normal! vap")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        select {
        case foo := <-ch1:
          log.Printf("foo: %v\n", foo)
          log.Printf("ch1: %v\n", ch1)
          return
        case <-ch2:
          log.Printf("ch2: %v\n", ch2)
          return
        }
      ]],
    })
  end)

  it("supports defer loop", function()
    helper.assert_scenario({
      input = [[
        func test() {
          foo := 1
          defer fo|o + 1
        }
      ]],
      filetype = "go",
      action = function()
        actions.insert_log({ position = "above" })
      end,
      expected = [[
        func test() {
          foo := 1
          log.Printf("foo: %v\n", foo)
          defer foo + 1
        }
      ]],
    })
  end)

  describe("supports identifier nested in complex expressions", function()
    it("supports struct constructor", function()
      helper.assert_scenario({
        input = [[
          var animal Animal = Dog{Breed: na|me}
        ]],
        filetype = "go",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          var animal Animal = Dog{Breed: name}
          log.Printf("name: %v\n", name)
        ]],
      })
    end)

    it("supports function invocations", function()
      helper.assert_scenario({
        input = [[
          foo(ba|r, baz)
        ]],
        filetype = "go",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          foo(bar, baz)
          log.Printf("bar: %v\n", bar)
          log.Printf("baz: %v\n", baz)
        ]],
      })
    end)
  end)

  it("supports member access expression", function()
    helper.assert_scenario({
      input = [[
        foo := ba|r.baz
      ]],
      filetype = "go",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        foo := bar.baz
        log.Printf("bar: %v\n", bar)
      ]],
    })

    helper.assert_scenario({
      input = [[
        foo := bar.ba|z.baf
      ]],
      filetype = "go",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        foo := bar.baz.baf
        log.Printf("bar.baz: %v\n", bar.baz)
      ]],
    })

    helper.assert_scenario({
      input = [[
        foo := ba|r.bar
      ]],
      filetype = "go",
      action = function()
        vim.cmd("normal! v$")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        foo := bar.bar
        log.Printf("bar: %v\n", bar)
      ]],
    })

    helper.assert_scenario({
      input = [[
        foo := ba|r.bar
      ]],
      filetype = "go",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        foo := bar.bar
        log.Printf("foo: %v\n", foo)
        log.Printf("bar.bar: %v\n", bar.bar)
      ]],
    })
  end)
end)

describe("go batch log", function()
  it("supports batch log", function()
    timber.setup({
      batch_log_templates = {
        default = {
          go = [[log.Printf("%repeat<%identifier: %v><, >\n", %repeat<%identifier><, >)]],
        },
      },
    })

    helper.assert_scenario({
      input = [[
        var fo|o int = bar + baz
      ]],
      filetype = "go",
      action = function()
        vim.cmd("normal! V")
        actions.add_log_targets_to_batch()
        actions.insert_batch_log()
      end,
      expected = [[
        var foo int = bar + baz
        log.Printf("foo: %v, bar: %v, baz: %v\n", foo, bar, baz)
      ]],
    })
  end)
end)
