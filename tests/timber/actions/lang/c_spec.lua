local timber = require("timber")
local helper = require("tests.timber.helper")
local actions = require("timber.actions")

describe("c single log", function()
  before_each(function()
    timber.setup({
      log_templates = {
        default = {
          c = [[printf("%log_target: %s\n", %log_target);]],
        },
      },
    })
  end)

  it("supports variable declaration", function()
    helper.assert_scenario({
      input = [[
        int fo|o = 42;
      ]],
      filetype = "c",
      action = function()
        actions.insert_log({ position = "above" })
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        printf("foo: %s\n", foo);
        int foo = 42;
        printf("foo: %s\n", foo);
      ]],
    })
  end)

  it("supports variable assignment", function()
    helper.assert_scenario({
      input = [[
        int foo;
        fo|o = 42;
      ]],
      filetype = "c",
      action = function()
        actions.insert_log({ position = "above" })
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        int foo;
        printf("foo: %s\n", foo);
        foo = 42;
        printf("foo: %s\n", foo);
      ]],
    })
  end)

  it("supports variable update expression", function()
    helper.assert_scenario({
      input = [[
        int foo = 42;
        fo|o++;
      ]],
      filetype = "c",
      action = function()
        actions.insert_log({ position = "above" })
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        int foo = 42;
        printf("foo: %s\n", foo);
        foo++;
        printf("foo: %s\n", foo);
      ]],
    })
  end)

  describe("supports function parameters", function()
    it("supports function declaration", function()
      helper.assert_scenario({
        input = [[
          void foo(int ba|r) {
            return;
          }
        ]],
        filetype = "c",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          void foo(int bar) {
            printf("bar: %s\n", bar);
            return;
          }
        ]],
      })
    end)

    it("supports multiple parameters", function()
      helper.assert_scenario({
        input = [[
          int calculate(
            int ba|r,
            float baz
          ) {
            return 0;
          }
        ]],
        filetype = "c",
        action = function()
          vim.cmd("normal! Vj")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          int calculate(
            int bar,
            float baz
          ) {
            printf("bar: %s\n", bar);
            printf("baz: %s\n", baz);
            return 0;
          }
        ]],
      })
    end)
  end)

  describe("supports if statement", function()
    it("supports if statement with compound statement body", function()
      helper.assert_scenario({
        input = [[
          if (fo|o > 1 && bar < baz) {
            return;
          } else if (bar) {
            return;
          }
        ]],
        filetype = "c",
        action = function()
          vim.cmd("normal! vap")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          if (foo > 1 && bar < baz) {
            printf("foo: %s\n", foo);
            printf("bar: %s\n", bar);
            printf("baz: %s\n", baz);
            return;
          } else if (bar) {
            printf("bar: %s\n", bar);
            return;
          }
        ]],
      })

      helper.assert_scenario({
        input = [[
          if (fo|o > 1) {
            return;
          } else if (bar) {
            return;
          }
        ]],
        filetype = "c",
        action = function()
          vim.cmd("normal! vap")
          actions.insert_log({ position = "above" })
        end,
        expected = [[
          printf("foo: %s\n", foo);
          if (foo > 1) {
            return;
          } else if (bar) {
            return;
          }
        ]],
      })
    end)

    it("supports if statement with single statement body", function()
      helper.assert_scenario({
        input = [[
          if (fo|o > 1 && bar < baz) return nil;
        ]],
        filetype = "c",
        action = function()
          actions.insert_log({ position = "below" })
          vim.cmd("normal! V")
          actions.insert_log({ position = "above" })
        end,
        expected = [[
          printf("foo: %s\n", foo);
          printf("bar: %s\n", bar);
          printf("baz: %s\n", baz);
          if (foo > 1 && bar < baz) return nil;
        ]],
      })
    end)
  end)

  describe("supports loop statements", function()
    it("supports for loop", function()
      helper.assert_scenario({
        input = [[
          for (int i = 0; i < fo|o; i++)
          {
            process(i);
          }
        ]],
        filetype = "c",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        -- TODO: this is invalid C code. Better handle nested log containers
        expected = [[
          for (int i = 0; i < foo; i++)
          printf("i: %s\n", i);
          {
            printf("i: %s\n", i);
            printf("foo: %s\n", foo);
            printf("i: %s\n", i);
            process(i);
          }
        ]],
      })
    end)

    it("supports while loop", function()
      helper.assert_scenario({
        input = [[
          while (fo|o > 0) {
            foo--;
          }
        ]],
        filetype = "c",
        action = function()
          actions.insert_log({ position = "above" })
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          printf("foo: %s\n", foo);
          while (foo > 0) {
            printf("foo: %s\n", foo);
            foo--;
          }
        ]],
      })
    end)

    it("supports do-while loop", function()
      helper.assert_scenario({
        input = [[
          do {
            process(foo);
          } while (fo|o > 0);
        ]],
        filetype = "c",
        action = function()
          actions.insert_log({ position = "above" })
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          do {
            process(foo);
            printf("foo: %s\n", foo);
          } while (foo > 0);
          printf("foo: %s\n", foo);
        ]],
      })
    end)
  end)

  describe("supports pointer operations", function()
    it("supports pointer declaration", function()
      helper.assert_scenario({
        input = [[
          int* pt|r = &value;
        ]],
        filetype = "c",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          int* ptr = &value;
          printf("ptr: %s\n", ptr);
        ]],
      })
    end)

    it("supports pointer dereferencing", function()
      helper.assert_scenario({
        input = [[
          *pt|r = 42;
        ]],
        filetype = "c",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          *ptr = 42;
          printf("ptr: %s\n", ptr);
        ]],
      })
    end)
  end)

  describe("supports member access expression", function()
    it("supports dot member access", function()
      helper.assert_scenario({
        input = [[
          int foo = ba|r.bar;
        ]],
        filetype = "c",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          int foo = bar.bar;
          printf("bar: %s\n", bar);
        ]],
      })

      helper.assert_scenario({
        input = [[
          int foo = bar.ba|z.baf;
        ]],
        filetype = "c",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          int foo = bar.baz.baf;
          printf("bar.baz: %s\n", bar.baz);
        ]],
      })

      helper.assert_scenario({
        input = [[
          in foo = ba|r.bar;
        ]],
        filetype = "c",
        action = function()
          vim.cmd("normal! v$")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          in foo = bar.bar;
          printf("bar: %s\n", bar);
        ]],
      })

      helper.assert_scenario({
        input = [[
          int foo = ba|r.bar;
        ]],
        filetype = "c",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          int foo = bar.bar;
          printf("foo: %s\n", foo);
          printf("bar.bar: %s\n", bar.bar);
        ]],
      })
    end)

    it("supports arrow member access", function()
      helper.assert_scenario({
        input = [[
          int foo = ba|r->bar;
        ]],
        filetype = "c",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          int foo = bar->bar;
          printf("bar: %s\n", bar);
        ]],
      })

      helper.assert_scenario({
        input = [[
          int foo = bar->ba|z->baf;
        ]],
        filetype = "c",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          int foo = bar->baz->baf;
          printf("bar->baz: %s\n", bar->baz);
        ]],
      })

      helper.assert_scenario({
        input = [[
          int foo = ba|r->bar;
        ]],
        filetype = "c",
        action = function()
          vim.cmd("normal! v$")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          int foo = bar->bar;
          printf("bar: %s\n", bar);
        ]],
      })

      helper.assert_scenario({
        input = [[
          int foo = ba|r->bar;
        ]],
        filetype = "c",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          int foo = bar->bar;
          printf("foo: %s\n", foo);
          printf("bar->bar: %s\n", bar->bar);
        ]],
      })
    end)
  end)

  describe("supports function calls", function()
    it("supports single function call", function()
      helper.assert_scenario({
        input = [[
          int result = calculate(fo|o);
        ]],
        filetype = "c",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          int result = calculate(foo);
          printf("foo: %s\n", foo);
        ]],
      })
    end)

    it("supports nested function calls", function()
      helper.assert_scenario({
        input = [[
          int result = outer(inner(fo|o));
        ]],
        filetype = "c",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          int result = outer(inner(foo));
          printf("foo: %s\n", foo);
        ]],
      })
    end)

    it("supports function call with multiple arguments", function()
      helper.assert_scenario({
        input = [[
          process(fo|o, bar, baz);
        ]],
        filetype = "c",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          process(foo, bar, baz);
          printf("foo: %s\n", foo);
          printf("bar: %s\n", bar);
          printf("baz: %s\n", baz);
        ]],
      })
    end)

    it("DOES NOT support function name", function()
      helper.assert_scenario({
        input = [[
          int foo = proc|ess(bar, baz);
        ]],
        filetype = "c",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          int foo = process(bar, baz);
        ]],
      })

      helper.assert_scenario({
        input = [[
          int foo = ba|r.process(baz);
        ]],
        filetype = "c",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          int foo = bar.process(baz);
          printf("bar: %s\n", bar);
        ]],
      })

      helper.assert_scenario({
        input = [[
          int foo = bar.proc|ess(baz);
        ]],
        filetype = "c",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          int foo = bar.process(baz);
        ]],
      })
    end)
  end)

  describe("supports array access", function()
    it("supports single array access", function()
      helper.assert_scenario({
        input = [[
          if (arr[foo] != arr[ba|r])
          {
            return false;
          }
        ]],
        filetype = "c",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "above" })
        end,
        expected = [[
          printf("arr[foo]: %s\n", arr[foo]);
          printf("arr[bar]: %s\n", arr[bar]);
          if (arr[foo] != arr[bar])
          {
            return false;
          }
        ]],
      })
    end)

    it("supports multi-dimensional array access", function()
      helper.assert_scenario({
        input = [[
          int value = matrix[ro|w][col];
        ]],
        filetype = "c",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          int value = matrix[row][col];
          printf("value: %s\n", value);
          printf("matrix[row][col]: %s\n", matrix[row][col]);
        ]],
      })
    end)

    it("supports array access with expressions", function()
      helper.assert_scenario({
        input = [[
          int value = arr[i|dx + offset];
        ]],
        filetype = "c",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          int value = arr[idx + offset];
          printf("idx: %s\n", idx);
        ]],
      })
    end)

    it("supports array access in assignments", function()
      helper.assert_scenario({
        input = [[
          arr[i|dx] = 42;
        ]],
        filetype = "c",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          arr[idx] = 42;
          printf("arr[idx]: %s\n", arr[idx]);
        ]],
      })
    end)
  end)
end)

describe("c batch log", function()
  it("supports batch log", function()
    timber.setup({
      batch_log_templates = {
        default = {
          c = [[printf("%repeat<%log_target: %s><, >\n", %repeat<%log_target><, >);]],
        },
      },
    })

    helper.assert_scenario({
      input = [[
        int fo|o = bar + baz;
      ]],
      filetype = "c",
      action = function()
        vim.cmd("normal! V")
        actions.add_log_targets_to_batch()
        actions.insert_batch_log()
      end,
      expected = [[
        int foo = bar + baz;
        printf("foo: %s, bar: %s, baz: %s\n", foo, bar, baz);
      ]],
    })
  end)
end)
