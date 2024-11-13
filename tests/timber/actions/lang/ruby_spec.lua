local timber = require("timber")
local helper = require("tests.timber.helper")
local actions = require("timber.actions")

describe("ruby single log", function()
  before_each(function()
    timber.setup({
      log_templates = {
        default = {
          ruby = [[puts("%identifier #{%identifier}")]],
        },
      },
    })
  end)

  describe("supports variable assignment", function()
    it("supports normal variable", function()
      local input = [[
        fo|o = "bar"
      ]]

      local expected = [[
        foo = "bar"
        puts("foo #{foo}")
      ]]

      helper.assert_scenario({
        input = input,
        filetype = "ruby",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = expected,
      })

      expected = [[
        puts("foo #{foo}")
        foo = "bar"
      ]]

      helper.assert_scenario({
        input = input,
        filetype = "ruby",
        action = function()
          actions.insert_log({ position = "above" })
        end,
        expected = expected,
      })
    end)

    it("supports global variable", function()
      local input = [[
        $fo|o = "bar"
      ]]

      local expected = [[
        $foo = "bar"
        puts("$foo #{$foo}")
      ]]

      helper.assert_scenario({
        input = input,
        filetype = "ruby",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = expected,
      })

      expected = [[
        puts("$foo #{$foo}")
        $foo = "bar"
      ]]

      helper.assert_scenario({
        input = input,
        filetype = "ruby",
        action = function()
          actions.insert_log({ position = "above" })
        end,
        expected = expected,
      })
    end)

    it("supports constant", function()
      local input = [[
        FO|O = "bar"
      ]]

      local expected = [[
        FOO = "bar"
        puts("FOO #{FOO}")
      ]]

      helper.assert_scenario({
        input = input,
        filetype = "ruby",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = expected,
      })

      expected = [[
        puts("FOO #{FOO}")
        FOO = "bar"
      ]]

      helper.assert_scenario({
        input = input,
        filetype = "ruby",
        action = function()
          actions.insert_log({ position = "above" })
        end,
        expected = expected,
      })
    end)

    it("supports parallel assignment", function()
      helper.assert_scenario({
        input = [[
          fo|o, foo1, foo2 = 1, 2, 3
        ]],
        filetype = "ruby",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          foo, foo1, foo2 = 1, 2, 3
          puts("foo #{foo}")
          puts("foo1 #{foo1}")
          puts("foo2 #{foo2}")
        ]],
      })
    end)

    it("supports instance variable assignment", function()
      helper.assert_scenario({
        input = [[
          class Test
            def initialize()
              @fo|o = 1
            end
          end
        ]],
        filetype = "ruby",
        action = function()
          actions.insert_log({ position = "below" })
          actions.insert_log({ position = "above" })
        end,
        expected = [[
          class Test
            def initialize()
              puts("@foo #{@foo}")
              @foo = 1
              puts("@foo #{@foo}")
            end
          end
        ]],
      })
    end)

    it("supports class variable assignment", function()
      helper.assert_scenario({
        input = [[
          class Test
            def initialize()
              @@fo|o = 1
            end
          end
        ]],
        filetype = "ruby",
        action = function()
          actions.insert_log({ position = "below" })
          actions.insert_log({ position = "above" })
        end,
        expected = [[
          class Test
            def initialize()
              puts("@@foo #{@@foo}")
              @@foo = 1
              puts("@@foo #{@@foo}")
            end
          end
        ]],
      })
    end)

    it("supports operator assignment", function()
      helper.assert_scenario({
        input = [[
          foo ||= ba/r
        ]],
        filetype = "ruby",
        input_cursor = "/",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          foo ||= bar
          puts("foo #{foo}")
          puts("bar #{bar}")
        ]],
      })
    end)
  end)

  describe("supports method parameters", function()
    describe("supports instance method", function()
      it("supports normal parameter", function()
        helper.assert_scenario({
          input = [[
            class Test
              def initialize(ba|r, baz)
                @bar = bar
                @baz = baz
              end
            end
          ]],
          filetype = "ruby",
          action = function()
            vim.cmd("normal! V")
            actions.insert_log({ position = "below" })
          end,
          expected = [[
            class Test
              def initialize(bar, baz)
                puts("bar #{bar}")
                puts("baz #{baz}")
                @bar = bar
                @baz = baz
              end
            end
          ]],
        })
      end)

      it("supports keyword parameter", function()
        helper.assert_scenario({
          input = [[
            class Test
              def initialize(ba|r:, baz: "baz")
                @bar = bar
                @baz = baz
              end
            end
          ]],
          filetype = "ruby",
          action = function()
            vim.cmd("normal! V")
            actions.insert_log({ position = "below" })
          end,
          expected = [[
            class Test
              def initialize(bar:, baz: "baz")
                puts("bar #{bar}")
                puts("baz #{baz}")
                @bar = bar
                @baz = baz
              end
            end
          ]],
        })
      end)

      it("supports splat operator", function()
        helper.assert_scenario({
          input = [[
            class Test
              def initialize(*fo|o)
                @foo = foo
              end
            end
          ]],
          filetype = "ruby",
          action = function()
            vim.cmd("normal! V")
            actions.insert_log({ position = "below" })
          end,
          expected = [[
            class Test
              def initialize(*foo)
                puts("foo #{foo}")
                @foo = foo
              end
            end
          ]],
        })

        helper.assert_scenario({
          input = [[
            class Test
              def initialize(**fo|o)
                @foo = foo
              end
            end
          ]],
          filetype = "ruby",
          action = function()
            vim.cmd("normal! V")
            actions.insert_log({ position = "below" })
          end,
          expected = [[
            class Test
              def initialize(**foo)
                puts("foo #{foo}")
                @foo = foo
              end
            end
          ]],
        })
      end)
    end)

    describe("supports class method", function()
      it("supports normal parameter", function()
        helper.assert_scenario({
          input = [[
            class Test
              def self.initialize(ba|r, baz)
                @bar = bar
                @baz = baz
              end
            end
          ]],
          filetype = "ruby",
          action = function()
            vim.cmd("normal! V")
            actions.insert_log({ position = "below" })
          end,
          expected = [[
            class Test
              def self.initialize(bar, baz)
                puts("bar #{bar}")
                puts("baz #{baz}")
                @bar = bar
                @baz = baz
              end
            end
          ]],
        })
      end)

      it("supports keyword parameter", function()
        helper.assert_scenario({
          input = [[
            class Test
              def self.initialize(ba|r:, baz: "baz")
                @bar = bar
                @baz = baz
              end
            end
          ]],
          filetype = "ruby",
          action = function()
            vim.cmd("normal! V")
            actions.insert_log({ position = "below" })
          end,
          expected = [[
            class Test
              def self.initialize(bar:, baz: "baz")
                puts("bar #{bar}")
                puts("baz #{baz}")
                @bar = bar
                @baz = baz
              end
            end
          ]],
        })
      end)

      it("supports splat operator", function()
        helper.assert_scenario({
          input = [[
            class Test
              def self.initialize(*fo|o)
                @foo = foo
              end
            end
          ]],
          filetype = "ruby",
          action = function()
            vim.cmd("normal! V")
            actions.insert_log({ position = "below" })
          end,
          expected = [[
            class Test
              def self.initialize(*foo)
                puts("foo #{foo}")
                @foo = foo
              end
            end
          ]],
        })

        helper.assert_scenario({
          input = [[
            class Test
              def self.initialize(**fo|o)
                @foo = foo
              end
            end
          ]],
          filetype = "ruby",
          action = function()
            vim.cmd("normal! V")
            actions.insert_log({ position = "below" })
          end,
          expected = [[
            class Test
              def self.initialize(**foo)
                puts("foo #{foo}")
                @foo = foo
              end
            end
          ]],
        })
      end)
    end)

    describe("supports module method", function()
      it("supports normal parameter", function()
        helper.assert_scenario({
          input = [[
            module Test
              def self.initialize(ba|r, baz)
                @bar = bar
                @baz = baz
              end
            end
          ]],
          filetype = "ruby",
          action = function()
            vim.cmd("normal! V")
            actions.insert_log({ position = "below" })
          end,
          expected = [[
            module Test
              def self.initialize(bar, baz)
                puts("bar #{bar}")
                puts("baz #{baz}")
                @bar = bar
                @baz = baz
              end
            end
          ]],
        })
      end)

      it("supports keyword parameter", function()
        helper.assert_scenario({
          input = [[
            module Test
              def self.initialize(ba|r:, baz: "baz")
                @bar = bar
                @baz = baz
              end
            end
          ]],
          filetype = "ruby",
          action = function()
            vim.cmd("normal! V")
            actions.insert_log({ position = "below" })
          end,
          expected = [[
            module Test
              def self.initialize(bar:, baz: "baz")
                puts("bar #{bar}")
                puts("baz #{baz}")
                @bar = bar
                @baz = baz
              end
            end
          ]],
        })
      end)

      it("supports splat operator", function()
        helper.assert_scenario({
          input = [[
            module Test
              def self.initialize(*fo|o)
                @foo = foo
              end
            end
          ]],
          filetype = "ruby",
          action = function()
            vim.cmd("normal! V")
            actions.insert_log({ position = "below" })
          end,
          expected = [[
            module Test
              def self.initialize(*foo)
                puts("foo #{foo}")
                @foo = foo
              end
            end
          ]],
        })

        helper.assert_scenario({
          input = [[
            module Test
              def self.initialize(**fo|o)
                @foo = foo
              end
            end
          ]],
          filetype = "ruby",
          action = function()
            vim.cmd("normal! V")
            actions.insert_log({ position = "below" })
          end,
          expected = [[
            module Test
              def self.initialize(**foo)
                puts("foo #{foo}")
                @foo = foo
              end
            end
          ]],
        })
      end)
    end)

    it("supports proc object", function()
      helper.assert_scenario({
        input = [[
          Proc.new { |na/me|
            puts "Hello, #{name}!"
            return nil
          }
        ]],
        filetype = "ruby",
        input_cursor = "/",
        action = function()
          actions.insert_log({ position = "below" })
          actions.insert_log({ position = "above" })
        end,
        expected = [[
          puts("name #{name}")
          Proc.new { |name|
            puts("name #{name}")
            puts "Hello, #{name}!"
            return nil
          }
        ]],
      })

      helper.assert_scenario({
        input = [[
          proc { |na/me|
            puts "Hello, #{name}!"
            return nil
          }
        ]],
        filetype = "ruby",
        input_cursor = "/",
        action = function()
          actions.insert_log({ position = "below" })
          actions.insert_log({ position = "above" })
        end,
        expected = [[
          puts("name #{name}")
          proc { |name|
            puts("name #{name}")
            puts "Hello, #{name}!"
            return nil
          }
        ]],
      })
    end)

    it("supports lambda object", function()
      helper.assert_scenario({
        input = [[
          ->(na|me) {
            puts "Hello, #{name}!"
            return nil
          }
        ]],
        filetype = "ruby",
        action = function()
          actions.insert_log({ position = "below" })
          actions.insert_log({ position = "above" })
        end,
        expected = [[
          puts("name #{name}")
          ->(name) {
            puts("name #{name}")
            puts "Hello, #{name}!"
            return nil
          }
        ]],
      })

      helper.assert_scenario({
        input = [[
          lambda { |na/me|
            puts "Hello, #{name}!"
            return nil
          }
        ]],
        filetype = "ruby",
        input_cursor = "/",
        action = function()
          actions.insert_log({ position = "below" })
          actions.insert_log({ position = "above" })
        end,
        expected = [[
          puts("name #{name}")
          lambda { |name|
            puts("name #{name}")
            puts "Hello, #{name}!"
            return nil
          }
        ]],
      })
    end)
  end)

  it("supports if statement", function()
    helper.assert_scenario({
      input = [[
        if not fo|o > 1 and bar < baz
          return nil
        elsif bar then
          return nil
        else
          return nil
        end
      ]],
      filetype = "ruby",
      action = function()
        vim.cmd("normal! vap")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        if not foo > 1 and bar < baz
          puts("foo #{foo}")
          puts("bar #{bar}")
          puts("baz #{baz}")
          return nil
        elsif bar then
          puts("bar #{bar}")
          return nil
        else
          return nil
        end
      ]],
    })
  end)

  it("supports if modifier", function()
    helper.assert_scenario({
      input = [[
        foo += 1 if bar
      ]],
      filetype = "ruby",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        foo += 1 if bar
        puts("foo #{foo}")
        puts("bar #{bar}")
      ]],
    })
  end)

  it("supports unless statement", function()
    helper.assert_scenario({
      input = [[
        unless not fo|o > 1 and bar < baz
          return nil
        else
          return nil
        end
      ]],
      filetype = "ruby",
      action = function()
        vim.cmd("normal! vap")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        unless not foo > 1 and bar < baz
          puts("foo #{foo}")
          puts("bar #{bar}")
          puts("baz #{baz}")
          return nil
        else
          return nil
        end
      ]],
    })
  end)

  it("supports unless modifier", function()
    helper.assert_scenario({
      input = [[
        foo += 1 unless bar
      ]],
      filetype = "ruby",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        foo += 1 unless bar
        puts("foo #{foo}")
        puts("bar #{bar}")
      ]],
    })
  end)

  it("supports for in loop statement", function()
    helper.assert_scenario({
      input = [[
        for fo|o in 1..5
          return nil
        end
      ]],
      filetype = "ruby",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        for foo in 1..5
          puts("foo #{foo}")
          return nil
        end
      ]],
    })
  end)

  it("supports while loop", function()
    helper.assert_scenario({
      input = [[
        foo = 1
        while fo|o <= 5
          foo += 1
        end
      ]],
      filetype = "ruby",
      action = function()
        actions.insert_log({ position = "below" })
        actions.insert_log({ position = "above" })
      end,
      expected = [[
        foo = 1
        puts("foo #{foo}")
        while foo <= 5
          puts("foo #{foo}")
          foo += 1
        end
      ]],
    })
  end)

  it("supports until loop", function()
    helper.assert_scenario({
      input = [[
        foo = 1
        until fo|o <= 5
          foo += 1
        end
      ]],
      filetype = "ruby",
      action = function()
        actions.insert_log({ position = "below" })
        actions.insert_log({ position = "above" })
      end,
      expected = [[
        foo = 1
        puts("foo #{foo}")
        until foo <= 5
          puts("foo #{foo}")
          foo += 1
        end
      ]],
    })
  end)

  it("supports yield statement", function()
    helper.assert_scenario({
      input = [[
        yield foo, ba|r
      ]],
      filetype = "ruby",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        yield foo, bar
        puts("foo #{foo}")
        puts("bar #{bar}")
      ]],
    })
  end)

  describe("supports identifier nested in complex expressions", function()
    it("supports ternary operator", function()
      helper.assert_scenario({
        input = [[
          foo =
            predicate ?
              ba|r :
              baz
        ]],
        filetype = "ruby",
        action = function()
          actions.insert_log({ position = "below" })
          actions.insert_log({ position = "above" })
        end,
        expected = [[
          puts("bar #{bar}")
          foo =
            predicate ?
              bar :
              baz
              puts("bar #{bar}")
        ]],
      })
    end)

    it("supports hash map constructor", function()
      helper.assert_scenario({
        input = [[
          { bar: b|ar, "baz" => baz }
        ]],
        filetype = "ruby",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          { bar: bar, "baz" => baz }
          puts("bar #{bar}")
          puts("baz #{baz}")
        ]],
      })
    end)

    it("supports function invocations", function()
      helper.assert_scenario({
        input = [[
          foo(ba|r, baz)
        ]],
        filetype = "ruby",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          foo(bar, baz)
          puts("bar #{bar}")
          puts("baz #{baz}")
        ]],
      })
    end)
  end)

  it("supports element reference expression", function()
    helper.assert_scenario({
      input = [[
        foo = ba|r["bar"]
      ]],
      filetype = "ruby",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        foo = bar["bar"]
        puts("bar #{bar}")
      ]],
    })

    helper.assert_scenario({
      input = [[
        foo = bar["baz"]["ba|f"]
      ]],
      filetype = "ruby",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        foo = bar["baz"]["baf"]
        puts("bar["baz"]["baf"] #{bar["baz"]["baf"]}")
      ]],
    })

    helper.assert_scenario({
      input = [[
        foo = ba|r[:bar]
      ]],
      filetype = "ruby",
      action = function()
        vim.cmd("normal! v$")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        foo = bar[:bar]
        puts("bar #{bar}")
      ]],
    })
  end)

  it("supports instance method access", function()
    helper.assert_scenario({
      input = [[
        bar.ba|z
      ]],
      filetype = "ruby",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        bar.baz
        puts("bar.baz #{bar.baz}")
      ]],
    })

    helper.assert_scenario({
      input = [[
        bar.baz.ba|f
      ]],
      filetype = "ruby",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        bar.baz.baf
        puts("bar.baz.baf #{bar.baz.baf}")
      ]],
    })
  end)

  it("supports binary operator", function()
    helper.assert_scenario({
      input = [[
        foo + bar - ba|z
      ]],
      filetype = "ruby",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        foo + bar - baz
        puts("foo #{foo}")
        puts("bar #{bar}")
        puts("baz #{baz}")
      ]],
    })

    helper.assert_scenario({
      input = [[
        foo << b|ar
      ]],
      filetype = "ruby",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        foo << bar
        puts("foo #{foo}")
        puts("bar #{bar}")
      ]],
    })
  end)
end)

describe("ruby batch log", function()
  it("supports batch log", function()
    timber.setup({
      batch_log_templates = {
        default = {
          ruby = [[puts("%repeat<%identifier: #{%identifier}><, >")]],
        },
      },
    })

    helper.assert_scenario({
      input = [[
        fo|o = bar + baz
      ]],
      filetype = "ruby",
      action = function()
        vim.cmd("normal! V")
        actions.add_log_targets_to_batch()
        actions.insert_batch_log()
      end,
      expected = [[
        foo = bar + baz
        puts("foo: #{foo}, bar: #{bar}, baz: #{baz}")
      ]],
    })
  end)
end)
