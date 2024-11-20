local timber = require("timber")
local helper = require("tests.timber.helper")
local actions = require("timber.actions")

describe("rust single log", function()
  before_each(function()
    timber.setup({
      log_templates = {
        default = {
          rust = [[println!("%identifier: {:#?}", %identifier);]],
        },
      },
    })
  end)

  describe("supports variable declaration", function()
    it("supports let declaration", function()
      helper.assert_scenario({
        input = [[
          let fo|o = "bar"
        ]],
        filetype = "rust",
        action = function()
          actions.insert_log({ position = "below" })
          actions.insert_log({ position = "above" })
        end,
        expected = [[
          println!("foo: {:#?}", foo);
          let foo = "bar"
          println!("foo: {:#?}", foo);
        ]],
      })

      helper.assert_scenario({
        input = [[
          let fo|o: &str = "bar"
        ]],
        filetype = "rust",
        action = function()
          actions.insert_log({ position = "below" })
          actions.insert_log({ position = "above" })
        end,
        expected = [[
          println!("foo: {:#?}", foo);
          let foo: &str = "bar"
          println!("foo: {:#?}", foo);
        ]],
      })
    end)

    it("supports let mut declaration", function()
      helper.assert_scenario({
        input = [[
          let mut fo|o: &str = "bar"
        ]],
        filetype = "rust",
        action = function()
          actions.insert_log({ position = "below" })
          actions.insert_log({ position = "above" })
        end,
        expected = [[
          println!("foo: {:#?}", foo);
          let mut foo: &str = "bar"
          println!("foo: {:#?}", foo);
        ]],
      })
    end)

    it("supports const declaration", function()
      helper.assert_scenario({
        input = [[
          const P|I: f64 = 3.14159;
        ]],
        filetype = "rust",
        action = function()
          actions.insert_log({ position = "below" })
          actions.insert_log({ position = "above" })
        end,
        expected = [[
          println!("PI: {:#?}", PI);
          const PI: f64 = 3.14159;
          println!("PI: {:#?}", PI);
        ]],
      })
    end)
  end)

  it("supports variable assignment", function()
    helper.assert_scenario({
      input = [[
        let mut foo: i32 = 42
        fo|o = 43
      ]],
      filetype = "rust",
      action = function()
        actions.insert_log({ position = "below" })
        actions.insert_log({ position = "above" })
      end,
      expected = [[
        let mut foo: i32 = 42
        println!("foo: {:#?}", foo);
        foo = 43
        println!("foo: {:#?}", foo);
      ]],
    })
  end)

  it("supports pattern matching", function()
    helper.assert_scenario({
      input = [[
        let Point { x|, y: y1 } = p;
      ]],
      filetype = "rust",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        let Point { x, y: y1 } = p;
        println!("x: {:#?}", x);
        println!("y1: {:#?}", y1);
        println!("p: {:#?}", p);
      ]],
    })

    helper.assert_scenario({
      input = [[
        match p {
          Point { x|, y } => {
            return nil;
          }
        }
      ]],
      filetype = "rust",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        match p {
          Point { x, y } => {
            println!("x: {:#?}", x);
            println!("y: {:#?}", y);
            return nil;
          }
        }
      ]],
    })

    helper.assert_scenario({
      input = [[
        if let Point { x|: 0, y } = p {
          return nil;
        }
      ]],
      filetype = "rust",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        if let Point { x: 0, y } = p {
          println!("y: {:#?}", y);
          println!("p: {:#?}", p);
          return nil;
        }
      ]],
    })
  end)

  describe("supports function parameters", function()
    it("supports function", function()
      helper.assert_scenario({
        input = [[
          fn test(fo|o: i32, bar: i32) -> bool {
            foo > bar
          }
        ]],
        filetype = "rust",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          fn test(foo: i32, bar: i32) -> bool {
            println!("foo: {:#?}", foo);
            println!("bar: {:#?}", bar);
            foo > bar
          }
        ]],
      })
    end)

    it("supports method", function()
      helper.assert_scenario({
        input = [[
          impl Foo {
            fn test(fo|o: i32, bar: i32) -> bool {
              foo > bar
            }
          }
        ]],
        filetype = "rust",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          impl Foo {
            fn test(foo: i32, bar: i32) -> bool {
              println!("foo: {:#?}", foo);
              println!("bar: {:#?}", bar);
              foo > bar
            }
          }
        ]],
      })

      helper.assert_scenario({
        input = [[
          impl Foo for Bar {
            fn test(fo|o: i32, bar: i32) -> bool {
              foo > bar
            }
          }
        ]],
        filetype = "rust",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          impl Foo for Bar {
            fn test(foo: i32, bar: i32) -> bool {
              println!("foo: {:#?}", foo);
              println!("bar: {:#?}", bar);
              foo > bar
            }
          }
        ]],
      })
    end)

    it("supports lambda expression", function()
      helper.assert_scenario({
        input = [[
          let add = |fo/o: i32, bar: i32| -> i32 {
            foo + bar
          };
        ]],
        filetype = "rust",
        input_cursor = "/",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          let add = |foo: i32, bar: i32| -> i32 {
            println!("foo: {:#?}", foo);
            println!("bar: {:#?}", bar);
            foo + bar
          };
          println!("add: {:#?}", add);
        ]],
      })
    end)

    it("DOES NOT support ignored parameters", function()
      helper.assert_scenario({
        input = [[
          fn test(fo|o: i32, _bar: i32) -> bool {
            true
          }
        ]],
        filetype = "rust",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          fn test(foo: i32, _bar: i32) -> bool {
            println!("foo: {:#?}", foo);
            true
          }
        ]],
      })
    end)
  end)

  it("DOES NOT support single function name", function()
    helper.assert_scenario({
      input = [[
        let foo = ba|r(1)
      ]],
      filetype = "rust",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        let foo = bar(1)
      ]],
    })

    helper.assert_scenario({
      input = [[
        let foo = bar.ba|z(1)
      ]],
      filetype = "rust",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        let foo = bar.baz(1)
      ]],
    })

    helper.assert_scenario({
      input = [[
        let foo = ba|r.baz(1)
      ]],
      filetype = "rust",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        let foo = bar.baz(1)
        println!("bar: {:#?}", bar);
      ]],
    })
  end)

  it("DOES NOT support variant constructor", function()
    helper.assert_scenario({
      input = [[
        let foo = Som|e(1)
      ]],
      filetype = "rust",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        let foo = Some(1)
      ]],
    })
  end)

  it("DOES NOT support module identifier", function()
    helper.assert_scenario({
      input = [[
        let foo = Ba|r::foo(1)
      ]],
      filetype = "rust",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        let foo = Bar::foo(1)
      ]],
    })

    helper.assert_scenario({
      input = [[
        fn test(error: i|o::Error) -> i32 {
          return 1;
        }
      ]],
      filetype = "rust",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        fn test(error: io::Error) -> i32 {
          return 1;
        }
      ]],
    })
  end)

  it("supports function return statement", function()
    helper.assert_scenario({
      input = [[
        fn test(foo: i32) -> i32 {
          return fo|o + 1
        }
      ]],
      filetype = "rust",
      action = function()
        actions.insert_log({ position = "above" })
      end,
      expected = [[
        fn test(foo: i32) -> i32 {
          println!("foo: {:#?}", foo);
          return foo + 1
        }
      ]],
    })
  end)

  it("supports if statement", function()
    helper.assert_scenario({
      input = [[
        if fo|o > 0 {
          println!("Positive");
        } else if foo < 0 {
          println!("Negative");
        } else {
          println!("Zero");
        }
      ]],
      filetype = "rust",
      action = function()
        vim.cmd("normal! vap")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        if foo > 0 {
          println!("foo: {:#?}", foo);
          println!("Positive");
        } else if foo < 0 {
          println!("foo: {:#?}", foo);
          println!("Negative");
        } else {
          println!("Zero");
        }
      ]],
    })
  end)

  it("supports switch statement", function()
    helper.assert_scenario({
      input = [[
        match (fo|o, bar) {
          (0, _) => println!("foo is 0"),
          (_, 0) => println!("bar is 0"),
          (a, b) => {
            println!("Both is not zero");
          },
          _ => println!("Other")
        }
      ]],
      filetype = "rust",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "above" })
        vim.cmd("normal! vG")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        println!("foo: {:#?}", foo);
        println!("bar: {:#?}", bar);
        match (foo, bar) {
          (0, _) => println!("foo is 0"),
          (_, 0) => println!("bar is 0"),
          (a, b) => {
            println!("a: {:#?}", a);
            println!("b: {:#?}", b);
            println!("Both is not zero");
          },
          _ => println!("Other")
        }
        println!("foo: {:#?}", foo);
        println!("bar: {:#?}", bar);
      ]],
    })

    helper.assert_scenario({
      input = [[
        match (foo, bar) {
          (a, _) if a| > 1 => {
            return nil;
          },
          _ => println!("Other")
        }
      ]],
      filetype = "rust",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        match (foo, bar) {
          (a, _) if a > 1 => {
            println!("a: {:#?}", a);
            println!("a: {:#?}", a);
            return nil;
          },
          _ => println!("Other")
        }
      ]],
    })
  end)

  it("supports for loop statement", function()
    helper.assert_scenario({
      input = [[
        for fo|o in 0..5 {
          return nil;
        }
      ]],
      filetype = "rust",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        for foo in 0..5 {
          println!("foo: {:#?}", foo);
          return nil;
        }
      ]],
    })

    helper.assert_scenario({
      input = [[
        for (i, valu|e) in nums.iter().enumerate() {
          return nil;
        }
      ]],
      filetype = "rust",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        for (i, value) in nums.iter().enumerate() {
          println!("i: {:#?}", i);
          println!("value: {:#?}", value);
          println!("nums: {:#?}", nums);
          return nil;
        }
      ]],
    })
  end)

  it("supports while loop", function()
    helper.assert_scenario({
      input = [[
        while i| < 5 {
          i += 1;
        }
      ]],
      filetype = "rust",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        while i < 5 {
          println!("i: {:#?}", i);
          i += 1;
        }
      ]],
    })

    helper.assert_scenario({
      input = [[
        while let Some(i) = option|al {
          if i > 3 {
            optional = None;
          }
          optional = Some(i + 1);
        }
      ]],
      filetype = "rust",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        while let Some(i) = optional {
          println!("i: {:#?}", i);
          println!("optional: {:#?}", optional);
          if i > 3 {
            optional = None;
          }
          optional = Some(i + 1);
        }
      ]],
    })
  end)

  describe("supports identifier nested in complex expressions", function()
    it("supports struct constructor", function()
      helper.assert_scenario({
        input = [[
          let foo = Point { x|: x, y: y };
        ]],
        filetype = "rust",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          let foo = Point { x: x, y: y };
          println!("foo: {:#?}", foo);
          println!("x: {:#?}", x);
          println!("y: {:#?}", y);
        ]],
      })

      helper.assert_scenario({
        input = [[
          let fo|o = Color(r, g, b);
        ]],
        filetype = "rust",
        action = function()
          vim.cmd("normal! vi(")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          let foo = Color(r, g, b);
          println!("r: {:#?}", r);
          println!("g: {:#?}", g);
          println!("b: {:#?}", b);
        ]],
      })
    end)

    it("supports function invocations", function()
      helper.assert_scenario({
        input = [[
          foo(ba|r, baz);
        ]],
        filetype = "rust",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          foo(bar, baz);
          println!("bar: {:#?}", bar);
          println!("baz: {:#?}", baz);
        ]],
      })
    end)
  end)

  it("supports member access expression", function()
    helper.assert_scenario({
      input = [[
        let foo = ba|r.baz;
      ]],
      filetype = "rust",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        let foo = bar.baz;
        println!("bar: {:#?}", bar);
      ]],
    })

    helper.assert_scenario({
      input = [[
        let foo = bar.ba|z.baf;
      ]],
      filetype = "rust",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        let foo = bar.baz.baf;
        println!("bar.baz: {:#?}", bar.baz);
      ]],
    })

    helper.assert_scenario({
      input = [[
        let foo = ba|r.bar;
      ]],
      filetype = "rust",
      action = function()
        vim.cmd("normal! v$")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        let foo = bar.bar;
        println!("bar: {:#?}", bar);
      ]],
    })

    helper.assert_scenario({
      input = [[
        let foo = ba|r.bar;
      ]],
      filetype = "rust",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        let foo = bar.bar;
        println!("foo: {:#?}", foo);
        println!("bar.bar: {:#?}", bar.bar);
      ]],
    })
  end)
end)

describe("rust batch log", function()
  it("supports batch log", function()
    timber.setup({
      batch_log_templates = {
        default = {
          rust = [[println!("%repeat<%identifier: {:#?}><, >", %repeat<%identifier><, >);]],
        },
      },
    })

    helper.assert_scenario({
      input = [[
        let fo|o: i32 = bar + baz;
      ]],
      filetype = "rust",
      action = function()
        vim.cmd("normal! V")
        actions.add_log_targets_to_batch()
        actions.insert_batch_log()
      end,
      expected = [[
        let foo: i32 = bar + baz;
        println!("foo: {:#?}, bar: {:#?}, baz: {:#?}", foo, bar, baz);
      ]],
    })
  end)
end)
