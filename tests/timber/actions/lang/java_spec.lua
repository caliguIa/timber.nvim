local timber = require("timber")
local helper = require("tests.timber.helper")
local actions = require("timber.actions")

describe("java single log", function()
  before_each(function()
    timber.setup({
      log_templates = {
        default = {
          java = [[System.out.println("%log_target: " + %log_target);]],
        },
      },
    })
  end)

  it("supports variable declaration", function()
    local input = [[
      String fo|o = "bar";
    ]]

    local expected = [[
      String foo = "bar";
      System.out.println("foo: " + foo);
    ]]

    helper.assert_scenario({
      input = input,
      filetype = "java",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = expected,
    })

    expected = [[
      System.out.println("foo: " + foo);
      String foo = "bar";
    ]]

    helper.assert_scenario({
      input = input,
      filetype = "java",
      action = function()
        actions.insert_log({ position = "above" })
      end,
      expected = expected,
    })
  end)

  it("supports constructor declaration", function()
    helper.assert_scenario({
      input = [[
        public class Student {
            public Student(String na|me, int age) {
                this.name = name;
                this.age = age;
            }
        }
      ]],
      filetype = "java",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        public class Student {
            public Student(String name, int age) {
                System.out.println("name: " + name);
                System.out.println("age: " + age);
                this.name = name;
                this.age = age;
            }
        }
      ]],
    })
  end)

  it("supports method declaration", function()
    helper.assert_scenario({
      input = [[
        public void foo(String ba|r, int baz) {
          return;
        }
      ]],
      filetype = "java",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        public void foo(String bar, int baz) {
          System.out.println("bar: " + bar);
          System.out.println("baz: " + baz);
          return;
        }
      ]],
    })
  end)

  describe("supports loop statements", function()
    it("supports for loop", function()
      helper.assert_scenario({
        input = [[
          for (int i = 0; i < fo|o.length; i++) {
            continue;
          }
        ]],
        filetype = "java",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          for (int i = 0; i < foo.length; i++) {
            System.out.println("i: " + i);
            System.out.println("i: " + i);
            System.out.println("foo.length: " + foo.length);
            System.out.println("i: " + i);
            continue;
          }
        ]],
      })
    end)

    it("supports enhanced for loop", function()
      helper.assert_scenario({
        input = [[
          for (String ite|m : items) {
            continue;
          }
        ]],
        filetype = "java",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          for (String item : items) {
            System.out.println("item: " + item);
            System.out.println("items: " + items);
            continue;
          }
        ]],
      })
    end)

    it("supports while loop", function()
      helper.assert_scenario({
        input = [[
          while (fo|o > 1 && bar < baz) {
            break;
          }
        ]],
        filetype = "java",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          while (foo > 1 && bar < baz) {
            System.out.println("foo: " + foo);
            System.out.println("bar: " + bar);
            System.out.println("baz: " + baz);
            break;
          }
        ]],
      })
    end)
  end)

  it("supports if-else statement", function()
    helper.assert_scenario({
      input = [[
        if (fo|o > 1 && bar < baz) {
          return true;
        } else if (qux) {
          return false;
        } else {
          return null;
        }
      ]],
      filetype = "java",
      action = function()
        vim.cmd("normal! vap")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        if (foo > 1 && bar < baz) {
          System.out.println("foo: " + foo);
          System.out.println("bar: " + bar);
          System.out.println("baz: " + baz);
          return true;
        } else if (qux) {
          System.out.println("qux: " + qux);
          return false;
        } else {
          return null;
        }
      ]],
    })
  end)

  it("supports ternary operator", function()
    helper.assert_scenario({
      input = [[
        String result = fo|o > bar ? "greater" : "lesser";
      ]],
      filetype = "java",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        String result = foo > bar ? "greater" : "lesser";
        System.out.println("result: " + result);
        System.out.println("foo: " + foo);
        System.out.println("bar: " + bar);
      ]],
    })
  end)

  describe("supports method invocations", function()
    it("supports method calls with parameters", function()
      helper.assert_scenario({
        input = [[
          someObject.doSomething(fo|o, bar.getValue());
        ]],
        filetype = "java",
        action = function()
          vim.cmd("normal! vi(")
          actions.insert_log({ position = "below" })
        end,
        -- TODO: it should've also log bar.getValue()
        expected = [[
          someObject.doSomething(foo, bar.getValue());
          System.out.println("foo: " + foo);
        ]],
      })
    end)

    it("supports method chaining", function()
      helper.assert_scenario({
        input = [[
          fo|o.getBar(bar).getBaz(baz).process();
        ]],
        filetype = "java",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          foo.getBar(bar).getBaz(baz).process();
          System.out.println("foo: " + foo);
        ]],
      })

      helper.assert_scenario({
        input = [[
          foo.getBar(bar).get|Baz(baz).process();
        ]],
        filetype = "java",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          foo.getBar(bar).getBaz(baz).process();
          System.out.println("foo.getBar(bar).getBaz(baz): " + foo.getBar(bar).getBaz(baz));
        ]],
      })
    end)
  end)

  describe("supports object field access", function()
    it("supports direct field access", function()
      helper.assert_scenario({
        input = [[
          this.fo|o.bar = value;
        ]],
        filetype = "java",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          this.foo.bar = value;
          System.out.println("this.foo: " + this.foo);
        ]],
      })
    end)

    it("supports nested field access", function()
      helper.assert_scenario({
        input = [[
          person.addre|ss.city = "New York";
        ]],
        filetype = "java",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          person.address.city = "New York";
          System.out.println("person.address: " + person.address);
        ]],
      })
    end)
  end)

  it("supports single parameter lambda", function()
    helper.assert_scenario({
      input = [[
        list.forEach(ite|m -> {
          process(item);
        });
      ]],
      filetype = "java",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        list.forEach(item -> {
          System.out.println("item: " + item);
          process(item);
        });
      ]],
    })
  end)

  it("supports try-catch block", function()
    helper.assert_scenario({
      input = [[
        try {
          process(foo);
        } catch (Exception e|) {
          handleError(e);
        }
      ]],
      filetype = "java",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        try {
          process(foo);
        } catch (Exception e) {
          System.out.println("e: " + e);
          handleError(e);
        }
      ]],
    })
  end)

  it("supports try-with-resources block", function()
    helper.assert_scenario({
      input = [[
        try (Resource re|s = new Resource()) {
          process(res);
        }
      ]],
      filetype = "java",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        try (Resource res = new Resource()) {
          System.out.println("res: " + res);
          process(res);
        }
      ]],
    })
  end)
end)

describe("java batch log", function()
  it("supports batch log", function()
    timber.setup({
      batch_log_templates = {
        default = {
          java = [[System.out.printf("%repeat<%log_target=%s><, >%n", %repeat<%log_target><, >);]],
        },
      },
    })

    helper.assert_scenario({
      input = [[
        String fo|o = bar + baz;
      ]],
      filetype = "java",
      action = function()
        vim.cmd("normal! V")
        actions.add_log_targets_to_batch()
        actions.insert_batch_log()
      end,
      expected = [[
        String foo = bar + baz;
        System.out.printf("foo=%s, bar=%s, baz=%s%n", foo, bar, baz);
      ]],
    })
  end)
end)
