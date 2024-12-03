local timber = require("timber")
local helper = require("tests.timber.helper")
local actions = require("timber.actions")

describe("cpp single log", function()
  before_each(function()
    timber.setup({
      log_templates = {
        default = {
          cpp = [[std::cout << "%log_target: " << %log_target << std::endl;]],
        },
      },
    })
  end)

  it("supports variable declaration", function()
    helper.assert_scenario({
      input = [[
        int fo|o = 42;
      ]],
      filetype = "cpp",
      action = function()
        actions.insert_log({ position = "above" })
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        std::cout << "foo: " << foo << std::endl;
        int foo = 42;
        std::cout << "foo: " << foo << std::endl;
      ]],
    })
  end)

  it("supports variable assignment", function()
    helper.assert_scenario({
      input = [[
        int foo;
        fo|o = 42;
      ]],
      filetype = "cpp",
      action = function()
        actions.insert_log({ position = "above" })
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        int foo;
        std::cout << "foo: " << foo << std::endl;
        foo = 42;
        std::cout << "foo: " << foo << std::endl;
      ]],
    })
  end)

  it("supports variable update expression", function()
    helper.assert_scenario({
      input = [[
        int foo = 42;
        fo|o++;
      ]],
      filetype = "cpp",
      action = function()
        actions.insert_log({ position = "above" })
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        int foo = 42;
        std::cout << "foo: " << foo << std::endl;
        foo++;
        std::cout << "foo: " << foo << std::endl;
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
        filetype = "cpp",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          void foo(int bar) {
            std::cout << "bar: " << bar << std::endl;
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
        filetype = "cpp",
        action = function()
          vim.cmd("normal! Vj")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          int calculate(
            int bar,
            float baz
          ) {
            std::cout << "bar: " << bar << std::endl;
            std::cout << "baz: " << baz << std::endl;
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
        filetype = "cpp",
        action = function()
          vim.cmd("normal! vap")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          if (foo > 1 && bar < baz) {
            std::cout << "foo: " << foo << std::endl;
            std::cout << "bar: " << bar << std::endl;
            std::cout << "baz: " << baz << std::endl;
            return;
          } else if (bar) {
            std::cout << "bar: " << bar << std::endl;
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
        filetype = "cpp",
        action = function()
          vim.cmd("normal! vap")
          actions.insert_log({ position = "above" })
        end,
        expected = [[
          std::cout << "foo: " << foo << std::endl;
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
        filetype = "cpp",
        action = function()
          actions.insert_log({ position = "below" })
          vim.cmd("normal! V")
          actions.insert_log({ position = "above" })
        end,
        expected = [[
          std::cout << "foo: " << foo << std::endl;
          std::cout << "bar: " << bar << std::endl;
          std::cout << "baz: " << baz << std::endl;
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
        filetype = "cpp",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        -- TODO: this is invalid C code. Better handle nested log containers
        expected = [[
          for (int i = 0; i < foo; i++)
          std::cout << "i: " << i << std::endl;
          {
            std::cout << "i: " << i << std::endl;
            std::cout << "foo: " << foo << std::endl;
            std::cout << "i: " << i << std::endl;
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
        filetype = "cpp",
        action = function()
          actions.insert_log({ position = "above" })
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          std::cout << "foo: " << foo << std::endl;
          while (foo > 0) {
            std::cout << "foo: " << foo << std::endl;
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
        filetype = "cpp",
        action = function()
          actions.insert_log({ position = "above" })
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          do {
            process(foo);
            std::cout << "foo: " << foo << std::endl;
          } while (foo > 0);
          std::cout << "foo: " << foo << std::endl;
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
        filetype = "cpp",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          int* ptr = &value;
          std::cout << "ptr: " << ptr << std::endl;
        ]],
      })
    end)

    it("supports pointer dereferencing", function()
      helper.assert_scenario({
        input = [[
          *pt|r = 42;
        ]],
        filetype = "cpp",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          *ptr = 42;
          std::cout << "ptr: " << ptr << std::endl;
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
        filetype = "cpp",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          int foo = bar.bar;
          std::cout << "bar: " << bar << std::endl;
        ]],
      })

      helper.assert_scenario({
        input = [[
          int foo = bar.ba|z.baf;
        ]],
        filetype = "cpp",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          int foo = bar.baz.baf;
          std::cout << "bar.baz: " << bar.baz << std::endl;
        ]],
      })

      helper.assert_scenario({
        input = [[
          in foo = ba|r.bar;
        ]],
        filetype = "cpp",
        action = function()
          vim.cmd("normal! v$")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          in foo = bar.bar;
          std::cout << "bar: " << bar << std::endl;
        ]],
      })

      helper.assert_scenario({
        input = [[
          int foo = ba|r.bar;
        ]],
        filetype = "cpp",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          int foo = bar.bar;
          std::cout << "foo: " << foo << std::endl;
          std::cout << "bar.bar: " << bar.bar << std::endl;
        ]],
      })
    end)

    it("supports arrow member access", function()
      helper.assert_scenario({
        input = [[
          int foo = ba|r->bar;
        ]],
        filetype = "cpp",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          int foo = bar->bar;
          std::cout << "bar: " << bar << std::endl;
        ]],
      })

      helper.assert_scenario({
        input = [[
          int foo = bar->ba|z->baf;
        ]],
        filetype = "cpp",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          int foo = bar->baz->baf;
          std::cout << "bar->baz: " << bar->baz << std::endl;
        ]],
      })

      helper.assert_scenario({
        input = [[
          int foo = ba|r->bar;
        ]],
        filetype = "cpp",
        action = function()
          vim.cmd("normal! v$")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          int foo = bar->bar;
          std::cout << "bar: " << bar << std::endl;
        ]],
      })

      helper.assert_scenario({
        input = [[
          int foo = ba|r->bar;
        ]],
        filetype = "cpp",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          int foo = bar->bar;
          std::cout << "foo: " << foo << std::endl;
          std::cout << "bar->bar: " << bar->bar << std::endl;
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
        filetype = "cpp",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          int result = calculate(foo);
          std::cout << "foo: " << foo << std::endl;
        ]],
      })
    end)

    it("supports nested function calls", function()
      helper.assert_scenario({
        input = [[
          int result = outer(inner(fo|o));
        ]],
        filetype = "cpp",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          int result = outer(inner(foo));
          std::cout << "foo: " << foo << std::endl;
        ]],
      })
    end)

    it("supports function call with multiple arguments", function()
      helper.assert_scenario({
        input = [[
          process(fo|o, bar, baz);
        ]],
        filetype = "cpp",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          process(foo, bar, baz);
          std::cout << "foo: " << foo << std::endl;
          std::cout << "bar: " << bar << std::endl;
          std::cout << "baz: " << baz << std::endl;
        ]],
      })
    end)

    it("DOES NOT support function name", function()
      helper.assert_scenario({
        input = [[
          int foo = proc|ess(bar, baz);
        ]],
        filetype = "cpp",
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
        filetype = "cpp",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          int foo = bar.process(baz);
          std::cout << "bar: " << bar << std::endl;
        ]],
      })

      helper.assert_scenario({
        input = [[
          int foo = bar.proc|ess(baz);
        ]],
        filetype = "cpp",
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
        filetype = "cpp",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "above" })
        end,
        expected = [[
          std::cout << "arr[foo]: " << arr[foo] << std::endl;
          std::cout << "arr[bar]: " << arr[bar] << std::endl;
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
        filetype = "cpp",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          int value = matrix[row][col];
          std::cout << "value: " << value << std::endl;
          std::cout << "matrix[row][col]: " << matrix[row][col] << std::endl;
        ]],
      })
    end)

    it("supports array access with expressions", function()
      helper.assert_scenario({
        input = [[
          int value = arr[i|dx + offset];
        ]],
        filetype = "cpp",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          int value = arr[idx + offset];
          std::cout << "idx: " << idx << std::endl;
        ]],
      })
    end)

    it("supports array access in assignments", function()
      helper.assert_scenario({
        input = [[
          arr[i|dx] = 42;
        ]],
        filetype = "cpp",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          arr[idx] = 42;
          std::cout << "arr[idx]: " << arr[idx] << std::endl;
        ]],
      })
    end)
  end)

  describe("supports try-catch blocks", function()
    it("supports basic try-catch", function()
      helper.assert_scenario({
        input = [[
          try {
            process();
          } catch (std::exception& e|x) {
            return;
          }
        ]],
        filetype = "cpp",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          try {
            process();
          } catch (std::exception& ex) {
            std::cout << "ex: " << ex << std::endl;
            return;
          }
        ]],
      })
    end)

    it("supports multiple catch blocks", function()
      helper.assert_scenario({
        input = [[
          try {
            riskyOperation();
          } catch (const CustomError& e|rr) {
            handleCustomError();
          } catch (const std::runtime_error& e) {
            handleRuntimeError();
          }
        ]],
        filetype = "cpp",
        action = function()
          vim.cmd("normal! vap")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          try {
            riskyOperation();
          } catch (const CustomError& err) {
            std::cout << "err: " << err << std::endl;
            handleCustomError();
          } catch (const std::runtime_error& e) {
            std::cout << "e: " << e << std::endl;
            handleRuntimeError();
          }
        ]],
      })
    end)
  end)

  describe("supports lambda functions", function()
    it("supports lambda with parameters", function()
      helper.assert_scenario({
        input = [[
          auto lambda = [](int x, int y|) {
            return x + y;
          };
        ]],
        filetype = "cpp",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          auto lambda = [](int x, int y) {
            std::cout << "x: " << x << std::endl;
            std::cout << "y: " << y << std::endl;
            return x + y;
          };
          std::cout << "lambda: " << lambda << std::endl;
        ]],
      })
    end)

    it("supports lambda with captures", function()
      helper.assert_scenario({
        input = [[
          auto lambda = [fo|o, bar, &baz]() {
            process(foo, bar, baz);
          };
        ]],
        filetype = "cpp",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          auto lambda = [foo, bar, &baz]() {
            std::cout << "foo: " << foo << std::endl;
            std::cout << "bar: " << bar << std::endl;
            std::cout << "baz: " << baz << std::endl;
            process(foo, bar, baz);
          };
          std::cout << "lambda: " << lambda << std::endl;
        ]],
      })
    end)

    it("supports lambda with mutable keyword", function()
      helper.assert_scenario({
        input = [[
          auto lambda = [cou|nt]() mutable {
            return ++count;
          };
        ]],
        filetype = "cpp",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          auto lambda = [count]() mutable {
            std::cout << "count: " << count << std::endl;
            return ++count;
          };
        ]],
      })
    end)

    it("supports lambdas with capture initialize", function()
      helper.assert_scenario({
        input = [[
          int outer_val = 0;
          auto outer = [inn|er_val = outer_val]() {
            return inner_val * 2;
          };
        ]],
        filetype = "cpp",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          int outer_val = 0;
          auto outer = [inner_val = outer_val]() {
            std::cout << "inner_val: " << inner_val << std::endl;
            std::cout << "outer_val: " << outer_val << std::endl;
            return inner_val * 2;
          };
          std::cout << "outer: " << outer << std::endl;
        ]],
      })
    end)
  end)
end)

describe("cpp batch log", function()
  it("supports batch log", function()
    timber.setup({
      batch_log_templates = {
        default = {
          cpp = [[std::cout %repeat<<< "%log_target: " << %log_target>< << "\n  " > << std::endl;]],
        },
      },
    })

    helper.assert_scenario({
      input = [[
        int fo|o = bar + baz;
      ]],
      filetype = "cpp",
      action = function()
        vim.cmd("normal! V")
        actions.add_log_targets_to_batch()
        actions.insert_batch_log()
      end,
      expected = [[
        int foo = bar + baz;
        std::cout << "foo: " << foo << "\n  " << "bar: " << bar << "\n  " << "baz: " << baz << std::endl;
      ]],
    })
  end)
end)
