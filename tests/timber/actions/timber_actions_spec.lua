local assert = require("luassert")
local match = require("luassert.match")
local spy = require("luassert.spy")
local timber = require("timber")
local config = require("timber.config")
local actions = require("timber.actions")
local utils = require("timber.utils")
local events = require("timber.events")
local helper = require("tests.timber.helper")

local function write_buf_file(bufnr, filename)
  vim.api.nvim_buf_set_name(bufnr, filename)
  vim.api.nvim_set_option_value("buftype", "", { buf = bufnr })
  vim.api.nvim_set_current_buf(bufnr)
  vim.cmd("write")
end

describe("timber.actions.insert_log", function()
  describe("supports log templates", function()
    it("supports %log_target in log template", function()
      timber.setup({
        log_templates = {
          testing = {
            javascript = [[console.log("%log_target", %log_target)]],
          },
        },
      })

      helper.assert_scenario({
        input = [[
        // Comment
        const fo|o = "bar"
      ]],
        filetype = "javascript",
        action = function()
          actions.insert_log({ template = "testing", position = "below" })
        end,
        expected = [[
        // Comment
        const foo = "bar"
        console.log("foo", foo)
      ]],
      })
    end)

    it("supports %line_number in log template", function()
      timber.setup({
        log_templates = {
          testing = {
            javascript = [[console.log("%line_number", %log_target)]],
          },
        },
      })

      helper.assert_scenario({
        input = [[
        // Comment
        const fo|o = "bar"
      ]],
        filetype = "javascript",
        action = function()
          actions.insert_log({ template = "testing", position = "below" })
        end,
        expected = [[
        // Comment
        const foo = "bar"
        console.log("2", foo)
      ]],
      })
    end)

    it("supports %filename in log template", function()
      vim.fn.system({ "rm", "-rf", "test_sandbox.actions" })
      vim.fn.mkdir("test_sandbox.actions")

      timber.setup({
        log_templates = {
          testing = {
            javascript = [[console.log("%filename:%line_number", %log_target)]],
          },
        },
      })

      local bufnr1 = helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = "bar"
        ]],
        filetype = "javascript",
      })

      write_buf_file(bufnr1, "test_sandbox.actions/filename_placeholder")
      actions.insert_log({ template = "testing", position = "below" })

      helper.assert_buf_content(
        bufnr1,
        [[
          // Comment
          const foo = "bar"
          console.log("filename_placeholder:2", foo)
        ]]
      )

      vim.fn.system({ "rm", "-rf", "test_sandbox.actions" })
    end)

    describe("supports %insert_cursor in log template", function()
      describe("move the the %insert_cursor placeholder and go to insert mode after inserting the log", function()
        it("supports single line template", function()
          timber.setup({
            log_templates = {
              testing = {
                javascript = [[console.log("%log_marker %log_target %insert_cursor", %log_target)]],
              },
            },
            log_marker = "🪵",
          })

          helper.assert_scenario({
            input = [[
              const fo|o = "bar"
              const bar = "foo"
            ]],
            filetype = "javascript",
            action = function()
              actions.insert_log({
                template = "testing",
                position = "below",
              })

              vim.defer_fn(function()
                vim.api.nvim_feedkeys("abc", "n", false)
              end, 0)
            end,
            expected = function()
              helper.wait(20)

              local mode = vim.api.nvim_get_mode().mode
              assert.are.same("i", mode)

              local output = vim.api.nvim_buf_get_lines(0, 0, -1, false)
              local expected = {
                [[const foo = "bar"]],
                [[console.log("🪵 foo abc", foo)]],
                [[const bar = "foo"]],
              }
              assert.are.same(expected, output)
            end,
          })

          -- Wait for Neovim to actually stop insert mode
          vim.cmd("stopinsert")
          helper.wait(20)
        end)

        it("supports single line template", function()
          timber.setup({
            log_templates = {
              testing = {
                javascript = [[
                  // Comment above
                  console.log("%log_target %insert_cursor", %log_target)
                  // Comment below
                ]],
              },
            },
          })

          helper.assert_scenario({
            input = [[
              const fo|o = "bar"
              const bar = "foo"
            ]],
            filetype = "javascript",
            action = function()
              actions.insert_log({
                template = "testing",
                position = "below",
              })

              vim.defer_fn(function()
                vim.api.nvim_feedkeys("abc", "n", false)
              end, 0)
            end,
            expected = function()
              helper.wait(20)

              local mode = vim.api.nvim_get_mode().mode
              assert.are.same("i", mode)

              local output = vim.api.nvim_buf_get_lines(0, 0, -1, false)
              local expected = {
                [[const foo = "bar"]],
                [[// Comment above]],
                [[console.log("foo abc", foo)]],
                [[// Comment below]],
                [[const bar = "foo"]],
              }
              assert.are.same(expected, output)
            end,
          })

          -- Wait for Neovim to actually stop insert mode
          vim.cmd("stopinsert")
          helper.wait(20)
        end)
      end)

      it("chooses the first statement if there are multiple", function()
        timber.setup({
          log_templates = {
            testing = {
              javascript = [[console.log("%log_target %insert_cursor", %log_target)]],
            },
          },
        })

        helper.assert_scenario({
          input = [[
            const fo|o = bar + baz
          ]],
          filetype = "javascript",
          action = function()
            vim.cmd("normal! V")
            actions.insert_log({
              template = "testing",
              position = "below",
            })

            vim.defer_fn(function()
              vim.api.nvim_feedkeys("abc", "n", false)
            end, 0)
          end,
          expected = function()
            helper.wait(20)

            local mode = vim.api.nvim_get_mode().mode
            assert.are.same("i", mode)

            local output = vim.api.nvim_buf_get_lines(0, 0, -1, false)
            local expected = {
              [[const foo = bar + baz]],
              [[console.log("foo abc", foo)]],
              [[console.log("bar ", bar)]],
              [[console.log("baz ", baz)]],
            }
            assert.are.same(expected, output)
          end,
        })

        -- Wait for Neovim to actually stop insert mode
        vim.cmd("stopinsert")
        helper.wait(20)
      end)
    end)

    it("supports custom placeholder in log template", function()
      timber.setup({
        log_templates = {
          testing = {
            javascript = [[console.log("%hello", %log_target)]],
          },
        },
        template_placeholders = {
          hello = function(ctx)
            local line = ctx.log_target:start()
            return string.format("Hello World %s line %s", ctx.log_position, line)
          end,
        },
      })

      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = "bar"
        ]],
        filetype = "javascript",
        action = function()
          actions.insert_log({ template = "testing", position = "below" })
        end,
        expected = [[
          // Comment
          const foo = "bar"
          console.log("Hello World below line 1", foo)
        ]],
      })
    end)
  end)

  describe("supports log template that doesn't contain %log_target", function()
    it("inserts the log statement at the above line if position is 'above'", function()
      timber.setup({
        log_templates = {
          plain = {
            javascript = [[console.log("Custom log %line_number")]],
          },
        },
      })

      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = "bar"
        ]],
        filetype = "javascript",
        action = function()
          actions.insert_log({ template = "plain", position = "below" })
        end,
        expected = [[
          // Comment
          const foo = "bar"
          console.log("Custom log 3")
        ]],
      })
    end)
    it("inserts the log statement at the above line if position is 'above'", function()
      timber.setup({
        log_templates = {
          plain = {
            javascript = [[console.log("Custom log %line_number")]],
          },
        },
      })

      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = "bar"
        ]],
        filetype = "javascript",
        action = function()
          actions.insert_log({ template = "plain", position = "above" })
        end,
        expected = [[
          // Comment
          console.log("Custom log 2")
          const foo = "bar"
        ]],
      })
    end)
  end)

  describe("a log target belongs to multiple log containers", function()
    it("chooses the deepest container", function()
      timber.setup({
        log_templates = {
          testing = {
            javascript = [[console.log("Testing", %log_target)]],
          },
        },
      })

      local input = [[
        const foo = {
          bar: () => {
            const ba|z = 123
          },
        };
      ]]

      helper.assert_scenario({
        input = input,
        filetype = "javascript",
        action = function()
          actions.insert_log({ template = "testing", position = "below" })
        end,
        expected = [[
          const foo = {
            bar: () => {
              const baz = 123
              console.log("Testing", baz)
            },
          };
        ]],
      })

      helper.assert_scenario({
        input = input,
        filetype = "javascript",
        action = function()
          vim.cmd("normal! Vap")
          actions.insert_log({ template = "testing", position = "below" })
        end,
        expected = [[
          const foo = {
            bar: () => {
              const baz = 123
              console.log("Testing", baz)
            },
          };
          console.log("Testing", foo)
        ]],
      })
    end)
  end)

  it("supports %log_marker in log template", function()
    timber.setup({
      log_templates = {
        testing = {
          javascript = [[console.log("%log_marker", %log_target)]],
        },
      },
      log_marker = "🪵",
    })

    helper.assert_scenario({
      input = [[
        // Comment
        const fo|o = "bar"
      ]],
      filetype = "javascript",
      action = function()
        actions.insert_log({ template = "testing", position = "below" })
      end,
      expected = [[
        // Comment
        const foo = "bar"
        console.log("🪵", foo)
      ]],
    })
  end)

  it("emits actions:new_log_statement event", function()
    timber.setup()

    local events_spy = spy.on(events, "emit")

    helper.assert_scenario({
      input = [[
        // Comment
        const fo|o = "foo"
      ]],
      filetype = "javascript",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = function()
        assert.spy(events_spy).was_called(1)
        assert.spy(events_spy).was_called_with("actions:new_log_statement", match.is_table())
      end,
    })

    events_spy:clear()

    helper.assert_scenario({
      input = [[
        // Comment
        const fo|o = bar + baz
      ]],
      filetype = "javascript",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = function()
        assert.spy(events_spy).was_called(3)
        assert.spy(events_spy).was_called_with("actions:new_log_statement", match.is_table())
      end,
    })

    events_spy:clear()
  end)

  it("supports dot repeat", function()
    helper.assert_scenario({
      input = [[
        // Comment
        const fo|o = bar + baz
      ]],
      filetype = "javascript",
      action = function()
        actions.insert_log({ position = "below" })
        vim.cmd("normal! 2w.2w.")
      end,
      expected = [[
        // Comment
        const foo = bar + baz
        console.log("baz", baz)
        console.log("bar", bar)
        console.log("foo", foo)
      ]],
    })
  end)

  describe("handles user errors", function()
    it("notifies when the log template is not found", function()
      timber.setup()
      local notify_spy = spy.on(utils, "notify")

      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = bar + baz
        ]],
        filetype = "javascript",
        action = function()
          actions.insert_log({ template = "unknown", position = "below" })
        end,
        expected = function()
          assert.spy(notify_spy).was_called(1)
          assert.spy(notify_spy).was_called_with("Log template 'unknown' is not found", "error")
          notify_spy:clear()
        end,
      })
    end)

    it("notifies when the log template does not include the language", function()
      timber.setup({
        log_templates = {
          testing = {},
        },
      })
      local notify_spy = spy.on(utils, "notify")

      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = bar + baz
        ]],
        filetype = "javascript",
        action = function()
          actions.insert_log({ template = "testing", position = "below" })
        end,
        expected = function()
          assert.spy(notify_spy).was_called(1)
          assert
            .spy(notify_spy)
            .was_called_with("Log template 'testing' does not have 'javascript' language template", "error")
          notify_spy:clear()
        end,
      })
    end)

    it("notifies when no logable ranges is found", function()
      timber.setup({
        log_templates = {
          default = {
            javascript = [[console.log("%log_target", %log_target)]],
          },
        },
      })
      local notify_spy = spy.on(utils, "notify")

      helper.assert_scenario({
        input = [[
          function foo(ba|r, baz) {
            return null
          }
        ]],
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "above" })
        end,
        expected = function()
          assert.spy(notify_spy).was_called(1)
          assert.spy(notify_spy).was_called_with("No logable ranges above the log target", "warn")
          notify_spy:clear()
        end,
      })
    end)
  end)

  describe("preserves the cursor position after inserting", function()
    it("supports single line template", function()
      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = "foo"
          const bar = "bar"
        ]],
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "below" })
          helper.wait(20)
        end,
        expected = function()
          local cursor_position = vim.fn.getpos(".")
          assert.are.same({ 2, 8 }, vim.list_slice(cursor_position, 2, 3))
        end,
      })

      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = "foo"
          const bar = "bar"
        ]],
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "above" })
          helper.wait(20)
        end,
        expected = function()
          local cursor_position = vim.fn.getpos(".")
          assert.are.same({ 3, 8 }, vim.list_slice(cursor_position, 2, 3))
        end,
      })
    end)

    it("supports multi line template", function()
      timber.setup({
        log_templates = {
          default = {
            javascript = [[
              console.group("Test")
              console.log("FOO")
              console.log("%log_target", %log_target)
              console.groupEnd()
            ]],
          },
        },
      })

      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = "foo"
          const bar = "bar"
        ]],
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "below" })
        end,
        expected = function()
          local cursor_position = vim.fn.getpos(".")
          assert.are.same({ 2, 8 }, vim.list_slice(cursor_position, 2, 3))
        end,
      })

      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = "foo"
          const bar = "bar"
        ]],
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "above" })
        end,
        expected = function()
          local cursor_position = vim.fn.getpos(".")
          assert.are.same({ 6, 8 }, vim.list_slice(cursor_position, 2, 3))
        end,
      })
    end)
  end)

  it("supports multi lines template", function()
    timber.setup({
      log_templates = {
        default = {
          javascript = [[
            console.group("Test")
            console.log("FOO")
            console.log("%log_target", %log_target)
            console.groupEnd()
          ]],
        },
      },
    })

    helper.assert_scenario({
      input = [[
        // Comment
        const fo|o = "foo"
        const bar = "bar"
      ]],
      filetype = "javascript",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        // Comment
        const foo = "foo"
        console.group("Test")
        console.log("FOO")
        console.log("foo", foo)
        console.groupEnd()
        const bar = "bar"
      ]],
    })
  end)

  describe("supports surround log", function()
    it("specifies before and after templates", function()
      timber.setup({
        log_templates = {
          testing1 = {
            javascript = [[console.log("Testing")]],
          },
          testing2 = {
            javascript = [[console.log("%log_target", %log_target)]],
          },
        },
      })

      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = "foo"
          const bar = "bar"
        ]],
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "surround", templates = { before = "testing1", after = "testing2" } })
        end,
        expected = [[
          // Comment
          console.log("Testing")
          const foo = "foo"
          console.log("foo", foo)
          const bar = "bar"
        ]],
      })
    end)

    it("defaults to `default` if not specified before and after templates", function()
      timber.setup({
        log_templates = {
          default = {
            javascript = [[console.log("%log_target", %log_target)]],
          },
        },
      })

      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = "foo"
          const bar = "bar"
        ]],
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "surround", templates = {} })
        end,
        expected = [[
          // Comment
          console.log("foo", foo)
          const foo = "foo"
          console.log("foo", foo)
          const bar = "bar"
        ]],
      })

      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = "foo"
          const bar = "bar"
        ]],
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "surround", templates = { after = "default" } })
        end,
        expected = [[
          // Comment
          console.log("foo", foo)
          const foo = "foo"
          console.log("foo", foo)
          const bar = "bar"
        ]],
      })

      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = "foo"
          const bar = "bar"
        ]],
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "surround", templates = { before = "default" } })
        end,
        expected = [[
          // Comment
          console.log("foo", foo)
          const foo = "foo"
          console.log("foo", foo)
          const bar = "bar"
        ]],
      })
    end)

    it("notifies when templates is used with position other than 'surround'", function()
      timber.setup()

      local notify_spy = spy.on(utils, "notify")
      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = "foo"
          const bar = "bar"
        ]],
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "above", templates = { before = "default", after = "default" } })
        end,
        expected = function()
          assert.spy(notify_spy).was_called(1)
          assert.spy(notify_spy).was_called_with("'templates' can only be used with position 'surround'", "warn")
          notify_spy:clear()
        end,
      })
    end)

    it("notifies when position is 'surround' but DOES NOT specify templates", function()
      timber.setup()

      local notify_spy = spy.on(utils, "notify")
      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = "foo"
          const bar = "bar"
        ]],
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "surround" })
        end,
        expected = function()
          assert.spy(notify_spy).was_called(1)
          assert.spy(notify_spy).was_called_with("'templates' must be specified when position is 'surround'", "error")
          notify_spy:clear()
        end,
      })
    end)
  end)

  it("supports operator mode", function()
    require("timber.config").reset_default_key_mappings()
    timber.setup({
      default_keymaps_enabled = false,
    })

    vim.keymap.set("n", "gl", function()
      return actions.insert_log({ operator = true, position = "below" })
    end, { expr = true })

    helper.assert_scenario({
      input = [[
        function foo(ba|r, baz) {
          return null
        }
      ]],
      filetype = "javascript",
      action = function()
        vim.cmd("normal gli(")
      end,
      expected = [[
        function foo(bar, baz) {
          console.log("bar", bar)
          console.log("baz", baz)
          return null
        }
      ]],
    })

    helper.assert_scenario({
      input = [[
        const foo = "foo"
        const bar = "ba|r"
      ]],
      filetype = "javascript",
      action = function()
        vim.cmd("normal glk")
      end,
      expected = [[
        const foo = "foo"
        console.log("foo", foo)
        const bar = "bar"
        console.log("bar", bar)
      ]],
    })
  end)

  describe("supports languages without Treesitter parsers", function()
    it("captures the current word under cursor", function()
      timber.setup({
        log_templates = {
          default = {
            timber = [[timber.log("%log_target", %log_target)]],
          },
        },
      })

      helper.assert_scenario({
        input = [[
          function foo(ba|r, baz) {
            return null
          }
        ]],
        filetype = "timber",
        action = function()
          actions.insert_log({ position = "above" })
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          timber.log("bar", bar)
          function foo(bar, baz) {
            timber.log("bar", bar)
            return null
          }
        ]],
      })
    end)

    it("captures the selection range", function()
      timber.setup({
        log_templates = {
          default = {
            timber = [[timber.log("%log_target", %log_target)]],
          },
        },
      })

      helper.assert_scenario({
        input = [[
          function foo(ba|r, baz) {
            return null
          }
        ]],
        filetype = "timber",
        action = function()
          vim.cmd("normal! v4l")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          function foo(bar, baz) {
            timber.log("ar, b", ar, b)
            return null
          }
        ]],
      })
    end)
  end)

  describe("supports auto_import", function()
    it("inserts the import line at the top of the file", function()
      timber.setup({
        log_templates = {
          testing = {
            javascript = {
              [[log("Testing")]],
              auto_import = [[import { log } from "some-package"]],
            },
          },
        },
      })

      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = "foo"
          const bar = "bar"
        ]],
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "below", template = "testing" })
        end,
        expected = [[
          import { log } from "some-package"
          // Comment
          const foo = "foo"
          log("Testing")
          const bar = "bar"
        ]],
      })
    end)

    it("DO NOT insert the import line if the line already exists", function()
      timber.setup({
        log_templates = {
          testing = {
            javascript = {
              [[log(%log_target)]],
              auto_import = [[import { log } from "some-package"]],
            },
          },
        },
      })

      helper.assert_scenario({
        input = [[
          import { log } from "some-package"
          // Comment
          const fo|o = "foo"
          const bar = "bar"
        ]],
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "below", template = "testing" })
        end,
        expected = [[
          import { log } from "some-package"
          // Comment
          const foo = "foo"
          log(foo)
          const bar = "bar"
        ]],
      })
    end)
  end)
end)

describe("timber.actions.insert_batch_log", function()
  before_each(function()
    timber.setup({
      log_templates = {
        default = {
          javascript = [[console.log("%log_target", %log_target)]],
        },
      },
    })
    actions.clear_batch()
  end)

  it("supports adding log targets to the batch, getting batch size, and clearing batch", function()
    local input = [[
      // Comment
      const fo|o = "foo"
      const bar = "bar"
      const baz = "baz"
    ]]

    helper.assert_scenario({
      input = input,
      filetype = "javascript",
      action = function()
        actions.add_log_targets_to_batch()
      end,
      expected = function()
        assert.are.same(1, actions.get_batch_size())
        actions.clear_batch()
        assert.are.same(0, actions.get_batch_size())
      end,
    })

    helper.assert_scenario({
      input = input,
      filetype = "javascript",
      action = function()
        vim.cmd("normal! V2j")
        actions.add_log_targets_to_batch()
      end,
      expected = function()
        assert.are.same(3, actions.get_batch_size())
        actions.clear_batch()
        assert.are.same(0, actions.get_batch_size())
      end,
    })
  end)

  it("supports insert batch log with auto_add", function()
    helper.assert_scenario({
      input = [[
        // Comment
        const foo = "foo"
        const bar = "bar"
        const ba|z = "baz"
      ]],
      filetype = "javascript",
      action = function()
        vim.cmd("normal! V2k")
        actions.insert_batch_log({ auto_add = true })
      end,
      expected = [[
        // Comment
        const foo = "foo"
        const bar = "bar"
        const baz = "baz"
        console.log({ "foo": foo, "bar": bar, "baz": baz })
      ]],
    })

    helper.assert_scenario({
      input = [[
        function foo(bar, ba|z) {
          return null
        }
      ]],
      filetype = "javascript",
      action = function()
        vim.cmd("normal! V")
        actions.insert_batch_log({ auto_add = true })
      end,
      expected = [[
        function foo(bar, baz) {
          console.log({ "bar": bar, "baz": baz })
          return null
        }
      ]],
    })
  end)

  it("exits Visual mode after adding targets to the batch", function()
    local input = [[
      // Comment
      const fo|o = "foo"
    ]]

    helper.assert_scenario({
      input = input,
      filetype = "javascript",
      action = function()
        vim.cmd("normal! V")
        actions.add_log_targets_to_batch()
      end,
      expected = function()
        local mode = vim.api.nvim_get_mode().mode
        assert.are.same("n", mode)
      end,
    })
  end)

  it("clears log batch after insert the log", function()
    local input = [[
      // Comment
      const fo|o = "foo"
    ]]

    helper.assert_scenario({
      input = input,
      filetype = "javascript",
      action = function()
        vim.cmd("normal! V")
        actions.add_log_targets_to_batch()
        actions.insert_batch_log()
      end,
      expected = function()
        assert.are.same(0, actions.get_batch_size())
      end,
    })
  end)

  it("notifies when batch is empty", function()
    local input = [[
      // Comment
      const fo|o = "foo"
    ]]

    local notify_spy = spy.on(utils, "notify")

    helper.assert_scenario({
      input = input,
      filetype = "javascript",
      action = function()
        actions.insert_batch_log()
      end,
      expected = function()
        assert.spy(notify_spy).was_called(1)
        assert.spy(notify_spy).was_called_with("Log batch is empty", "warn")
      end,
    })

    notify_spy:clear()
  end)

  it("only supports %log_target inside %repeat", function()
    timber.setup({
      batch_log_templates = {
        default = {
          javascript = [[console.log("%log_target", { %repeat<"%log_target": %log_target><, > })]],
        },
      },
    })

    local input = [[
      const fo|o = "foo"
      const bar = "bar"
      const baz = "baz"
    ]]

    local notify_spy = spy.on(utils, "notify")

    helper.assert_scenario({
      input = input,
      filetype = "javascript",
      action = function()
        vim.cmd("normal! V2j")
        actions.add_log_targets_to_batch()
        actions.insert_batch_log()
      end,
      expected = function()
        assert.spy(notify_spy).was_called(1)
        assert
          .spy(notify_spy)
          .was_called_with("Cannot use %log_target placeholder outside %repeat placeholder", "error")
        notify_spy:clear()
      end,
    })
  end)

  it("supports dot repeat", function()
    local input = [[
      // Comment
      const fo|o = "foo"
    ]]

    local notify_spy = spy.on(utils, "notify")

    helper.assert_scenario({
      input = input,
      filetype = "javascript",
      action = function()
        actions.add_log_targets_to_batch()
        actions.insert_batch_log()
      end,
      expected = [[
        // Comment
        const foo = "foo"
        console.log({ "foo": foo })
      ]],
    })

    -- Dot repeat the action. Now the batch is empty, it should notify the user
    vim.cmd("normal! .")
    assert.spy(notify_spy).was_called(1)
    assert.spy(notify_spy).was_called_with("Log batch is empty", "warn")
    notify_spy:clear()
  end)

  describe("handles user errors", function()
    it("notifies when the filetype is not recognized", function()
      local notify_spy = spy.on(utils, "notify")

      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = bar + baz
        ]],
        filetype = "unknown",
        action = function()
          actions.add_log_targets_to_batch()
        end,
        expected = function()
          assert.spy(notify_spy).was_called(1)
          assert.spy(notify_spy).was_called_with("Treesitter parser for unknown language is not found", "error")
          notify_spy:clear()
        end,
      })
    end)

    it("notifies when the log template is not found", function()
      local notify_spy = spy.on(utils, "notify")

      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = bar + baz
        ]],
        filetype = "javascript",
        action = function()
          actions.add_log_targets_to_batch()
          actions.insert_batch_log({ template = "unknown" })
        end,
        expected = function()
          assert.spy(notify_spy).was_called(1)
          assert.spy(notify_spy).was_called_with("Log template 'unknown' is not found", "error")
          notify_spy:clear()
        end,
      })
    end)

    it("notifies when the filetype is not recognized", function()
      local notify_spy = spy.on(utils, "notify")

      timber.setup({
        batch_log_templates = {
          testing = {},
        },
      })
      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = bar + baz
        ]],
        filetype = "javascript",
        action = function()
          actions.add_log_targets_to_batch()
          actions.insert_batch_log({ template = "testing" })
        end,
        expected = function()
          assert.spy(notify_spy).was_called(1)
          assert
            .spy(notify_spy)
            .was_called_with("Batch log template 'testing' does not have 'javascript' language template", "error")
          notify_spy:clear()
        end,
      })
    end)
  end)

  it("supports operator mode", function()
    require("timber.config").reset_default_key_mappings()
    timber.setup({
      default_keymaps_enabled = false,
    })

    vim.keymap.set("n", "gl", function()
      return actions.insert_batch_log({ operator = true })
    end, { expr = true })

    helper.assert_scenario({
      input = [[
        function foo(ba|r, baz) {
          return null
        }
      ]],
      filetype = "javascript",
      action = function()
        vim.cmd("normal gli(")
      end,
      expected = [[
        function foo(bar, baz) {
          console.log({ "bar": bar, "baz": baz })
          return null
        }
      ]],
    })

    helper.assert_scenario({
      input = [[
        const foo = "foo"
        const bar = "ba|r"
        const baz = "baz"
      ]],
      filetype = "javascript",
      action = function()
        vim.cmd("normal glip")
      end,
      expected = [[
        const foo = "foo"
        const bar = "bar"
        const baz = "baz"
        console.log({ "foo": foo, "bar": bar, "baz": baz })
      ]],
    })
  end)

  describe("supports auto_import", function()
    it("inserts the import line at the top of the file", function()
      timber.setup({
        batch_log_templates = {
          testing = {
            javascript = {
              [[log({ %repeat<"%log_target": %log_target><, > })]],
              auto_import = [[import { log } from 'some-package']],
            },
          },
        },
      })

      helper.assert_scenario({
        input = [[
          // Comment
          const foo = "foo"
          const bar = "bar"
          const ba|z = "baz"
        ]],
        filetype = "javascript",
        action = function()
          vim.cmd("normal! V2k")
          actions.insert_batch_log({ auto_add = true, template = "testing" })
        end,
        expected = [[
          import { log } from 'some-package'
          // Comment
          const foo = "foo"
          const bar = "bar"
          const baz = "baz"
          log({ "foo": foo, "bar": bar, "baz": baz })
        ]],
      })
    end)

    it("inserts the import line at the top of the file", function()
      timber.setup({
        batch_log_templates = {
          testing = {
            javascript = {
              [[log({ %repeat<"%log_target": %log_target><, > })]],
              auto_import = [[import { log } from 'some-package']],
            },
          },
        },
      })

      helper.assert_scenario({
        input = [[
          import { log } from 'some-package'
          // Comment
          const foo = "foo"
          const bar = "bar"
          const ba|z = "baz"
        ]],
        filetype = "javascript",
        action = function()
          vim.cmd("normal! V2k")
          actions.insert_batch_log({ auto_add = true, template = "testing" })
        end,
        expected = [[
          import { log } from 'some-package'
          // Comment
          const foo = "foo"
          const bar = "bar"
          const baz = "baz"
          log({ "foo": foo, "bar": bar, "baz": baz })
        ]],
      })
    end)

    it("DO NOT insert the import line if the line already exists", function()
      timber.setup({
        log_templates = {
          testing = {
            javascript = {
              [[log(%log_target)]],
              auto_import = [[import { log } from "some-package"]],
            },
          },
        },
      })

      helper.assert_scenario({
        input = [[
          import { log } from "some-package"
          // Comment
          const fo|o = "foo"
          const bar = "bar"
        ]],
        filetype = "javascript",
        action = function()
          actions.insert_log({ position = "below", template = "testing" })
        end,
        expected = [[
          import { log } from "some-package"
          // Comment
          const foo = "foo"
          log(foo)
          const bar = "bar"
        ]],
      })
    end)
  end)
end)

describe("timber.actions.add_log_targets_to_batch", function()
  before_each(function()
    timber.setup()
    actions.clear_batch()
  end)

  it("emits actions:add_to_batch for each target", function()
    local events_spy = spy.on(events, "emit")

    helper.assert_scenario({
      input = [[
        // Comment
        const fo|o = "foo"
        const bar = "bar"
      ]],
      filetype = "javascript",
      action = function()
        vim.cmd("normal! Vj")
        actions.add_log_targets_to_batch()
      end,
      expected = function()
        assert.spy(events_spy).was_called(2)
        assert.spy(events_spy).was_called_with("actions:add_to_batch", match.is_userdata())
      end,
    })

    events_spy:clear()
  end)

  it("preserves the cursor position after adding in visual mode", function()
    helper.assert_scenario({
      input = [[
        // Comment
        const fo|o = "foo"
        const bar = "bar"
      ]],
      filetype = "javascript",
      action = function()
        vim.cmd("normal! Vj")
        actions.add_log_targets_to_batch()
      end,
      expected = function()
        assert.are.same(2, actions.get_batch_size())

        local cursor_position = vim.fn.getpos(".")
        assert.are.same({ 3, 8 }, vim.list_slice(cursor_position, 2, 3))
      end,
    })
  end)

  it("supports dot repeat", function()
    helper.assert_scenario({
      input = [[
        // Comment
        const fo|o = "foo"
        const bar = "bar"
      ]],
      filetype = "javascript",
      action = function()
        actions.add_log_targets_to_batch()
        vim.cmd("normal! j.")
      end,
      expected = function()
        assert.are.same(2, actions.get_batch_size())
      end,
    })
  end)

  describe("handles user errors", function()
    it("notifies when the filetype is not recognized", function()
      local notify_spy = spy.on(utils, "notify")

      helper.assert_scenario({
        input = [[
          // Comment
          const fo|o = bar + baz
        ]],
        filetype = "unknown",
        action = function()
          actions.add_log_targets_to_batch()
        end,
        expected = function()
          assert.spy(notify_spy).was_called(1)
          assert.spy(notify_spy).was_called_with("Treesitter parser for unknown language is not found", "error")
          notify_spy:clear()
        end,
      })
    end)
  end)

  it("supports operator mode", function()
    require("timber.config").reset_default_key_mappings()
    timber.setup({
      default_keymaps_enabled = false,
    })

    vim.keymap.set("n", "gl", function()
      return actions.add_log_targets_to_batch({ operator = true })
    end, { expr = true })

    helper.assert_scenario({
      input = [[
        const fo|oooo = "foo"
        const barrrrr = "bar"
        const bazzzzz = "baz"
      ]],
      filetype = "javascript",
      action = function()
        vim.cmd("normal glip")
      end,
      expected = function()
        assert.are.same(3, actions.get_batch_size())
      end,
    })
  end)
end)

describe("timber.actions.clear_log_statements", function()
  describe("given the global opts is false", function()
    before_each(function()
      timber.setup({
        log_templates = {
          default = {
            lua = [[print("%log_marker %log_target", %log_target)]],
          },
        },
        log_marker = "🪵-TIMBER",
      })
    end)

    it("clears all statements ONLY in the current buffer", function()
      local bufnr1 = helper.assert_scenario({
        input = [[
          local fo|o = "foo"
          local bar = "bar"
          print("foo", foo)
        ]],
        filetype = "lua",
        action = function()
          vim.cmd("normal! vj")
          actions.insert_log({ position = "below" })
        end,
      })

      local bufnr2 = helper.assert_scenario({
        input = [[
          local fo|o = "foo"
          local bar = "bar"
        ]],
        filetype = "lua",
        action = function()
          vim.cmd("normal! vj")
          actions.insert_log({ position = "below" })
        end,
      })

      vim.api.nvim_set_current_buf(bufnr1)
      actions.clear_log_statements({ global = false })

      helper.assert_buf_content(
        bufnr1,
        [[
          local foo = "foo"
          local bar = "bar"
          print("foo", foo)
        ]]
      )

      helper.assert_buf_content(
        bufnr2,
        [[
          local foo = "foo"
          print("🪵-TIMBER foo", foo)
          local bar = "bar"
          print("🪵-TIMBER bar", bar)
        ]]
      )
    end)
  end)

  describe("given the global opts is true", function()
    before_each(function()
      vim.fn.system({ "rm", "-rf", "test_sandbox.actions" })
      vim.fn.mkdir("test_sandbox.actions")
      local random = math.random(1000)

      timber.setup({
        log_templates = {
          default = {
            lua = [[print("%log_marker %log_target", %log_target)]],
          },
        },
        log_marker = "🪵-" .. random,
      })
    end)

    after_each(function()
      vim.fn.system({ "rm", "-rf", "test_sandbox.actions" })
    end)

    it("clears all statements in ALL buffers", function()
      local bufnr1 = helper.assert_scenario({
        input = [[
          local fo|o = "foo"
          local bar = "bar"
          print("foo", foo)
        ]],
        filetype = "lua",
        action = function()
          vim.cmd("normal! vj")
          actions.insert_log({ position = "below" })
        end,
      })

      local bufnr2 = helper.assert_scenario({
        input = [[
          local fo|o = "foo"
          local bar = "bar"
          print("foo", foo)
        ]],
        filetype = "lua",
        action = function()
          vim.cmd("normal! vj")
          actions.insert_log({ position = "below" })
        end,
      })

      write_buf_file(bufnr1, "test_sandbox.actions/clear1")
      write_buf_file(bufnr2, "test_sandbox.actions/clear2")

      helper.wait(20)
      actions.clear_log_statements({ global = true })

      helper.assert_buf_content(
        bufnr1,
        [[
          local foo = "foo"
          local bar = "bar"
          print("foo", foo)
        ]]
      )

      helper.assert_buf_content(
        bufnr2,
        [[
          local foo = "foo"
          local bar = "bar"
          print("foo", foo)
        ]]
      )
    end)
  end)

  describe("given the config.log_marker is not set or empty", function()
    before_each(function()
      timber.setup({
        log_templates = {
          default = {
            lua = [[print("%log_marker %log_target", %log_target)]],
          },
        },
        log_marker = "",
      })
    end)

    it("DOES NOT clear any statements and notifies the user", function()
      local notify_spy = spy.on(utils, "notify")

      local bufnr = helper.assert_scenario({
        input = [[
          local fo|o = "foo"
          local bar = "bar"
        ]],
        filetype = "lua",
        action = function()
          vim.cmd("normal! vap")
          actions.insert_log({ position = "below" })
        end,
        expected = [[
          local foo = "foo"
          print(" foo", foo)
          local bar = "bar"
          print(" bar", bar)
        ]],
      })

      vim.api.nvim_set_current_buf(bufnr)
      actions.clear_log_statements({ global = false })

      helper.assert_buf_content(
        bufnr,
        [[
          local foo = "foo"
          print(" foo", foo)
          local bar = "bar"
          print(" bar", bar)
        ]]
      )

      assert.spy(notify_spy).was_called(1)
      assert.spy(notify_spy).was_called_with("config.log_marker is not configured", "warn")
      notify_spy:clear()
    end)
  end)
end)

describe("timber.actions.toggle_comment_log_statements", function()
  describe("given the global opts is false", function()
    before_each(function()
      timber.setup({
        log_templates = {
          default = {
            lua = [[print("%log_marker %log_target", %log_target)]],
          },
        },
        log_marker = "🪵-TIMBER",
      })
    end)

    it("toggles comment all statements ONLY in the current buffer", function()
      local bufnr1 = helper.assert_scenario({
        input = [[
          local fo|o = "foo"
          local bar = "bar"
          print("foo", foo)
        ]],
        filetype = "lua",
        action = function()
          vim.cmd("normal vj")
          actions.insert_log({ position = "below" })
        end,
      })

      local bufnr2 = helper.assert_scenario({
        input = [[
          local fo|o = "foo"
          local bar = "bar"
        ]],
        filetype = "lua",
        action = function()
          vim.cmd("normal! vj")
          actions.insert_log({ position = "below" })
        end,
      })

      vim.api.nvim_set_current_buf(bufnr1)
      -- Comment
      actions.toggle_comment_log_statements({ global = false })

      helper.assert_buf_content(
        bufnr1,
        [[
          local foo = "foo"
          -- print("🪵-TIMBER foo", foo)
          local bar = "bar"
          -- print("🪵-TIMBER bar", bar)
          print("foo", foo)
        ]]
      )

      helper.assert_buf_content(
        bufnr2,
        [[
          local foo = "foo"
          print("🪵-TIMBER foo", foo)
          local bar = "bar"
          print("🪵-TIMBER bar", bar)
        ]]
      )

      -- Uncomment
      actions.toggle_comment_log_statements({ global = false })
      helper.assert_buf_content(
        bufnr1,
        [[
          local foo = "foo"
          print("🪵-TIMBER foo", foo)
          local bar = "bar"
          print("🪵-TIMBER bar", bar)
          print("foo", foo)
        ]]
      )
    end)
  end)

  describe("given the global opts is true", function()
    before_each(function()
      vim.fn.system({ "rm", "-rf", "test_sandbox" })
      vim.fn.mkdir("test_sandbox")
      local random = math.random(1000)

      timber.setup({
        log_templates = {
          default = {
            lua = [[print("%log_marker %log_target", %log_target)]],
          },
        },
        log_marker = "🪵-" .. random,
      })
    end)

    after_each(function()
      vim.fn.system({ "rm", "-rf", "test_sandbox" })
    end)

    it("comments all statements in ALL buffers", function()
      local log_marker = config.config.log_marker
      local bufnr1 = helper.assert_scenario({
        input = [[
          local fo|o = "foo"
          local bar = "bar"
          print("foo", foo)
        ]],
        filetype = "lua",
        action = function()
          vim.cmd("normal! vj")
          actions.insert_log({ position = "below" })
        end,
      })

      local bufnr2 = helper.assert_scenario({
        input = [[
          local fo|o = "foo"
          local bar = "bar"
          print("foo", foo)
        ]],
        filetype = "lua",
        action = function()
          vim.cmd("normal! vj")
          actions.insert_log({ position = "below" })
        end,
      })

      write_buf_file(bufnr1, "test_sandbox/comment1")
      write_buf_file(bufnr2, "test_sandbox/comment2")

      -- Comment
      actions.toggle_comment_log_statements({ global = true })

      helper.assert_buf_content(
        bufnr1,
        string.format(
          [[
            local foo = "foo"
            -- print("%s foo", foo)
            local bar = "bar"
            -- print("%s bar", bar)
            print("foo", foo)
          ]],
          log_marker,
          log_marker
        )
      )

      helper.assert_buf_content(
        bufnr2,
        string.format(
          [[
            local foo = "foo"
            -- print("%s foo", foo)
            local bar = "bar"
            -- print("%s bar", bar)
            print("foo", foo)
          ]],
          log_marker,
          log_marker
        )
      )

      -- Uncomment
      actions.toggle_comment_log_statements({ global = true })

      helper.assert_buf_content(
        bufnr1,
        string.format(
          [[
            local foo = "foo"
            print("%s foo", foo)
            local bar = "bar"
            print("%s bar", bar)
            print("foo", foo)
          ]],
          log_marker,
          log_marker
        )
      )

      helper.assert_buf_content(
        bufnr2,
        string.format(
          [[
            local foo = "foo"
            print("%s foo", foo)
            local bar = "bar"
            print("%s bar", bar)
            print("foo", foo)
          ]],
          log_marker,
          log_marker
        )
      )
    end)
  end)

  describe("given the config.log_marker is not set or empty", function()
    before_each(function()
      timber.setup({
        log_templates = {
          default = {
            lua = [[print("%log_marker %log_target", %log_target)]],
          },
        },
        log_marker = "",
      })
    end)

    it("DOES NOT comment any statements and notifies the user", function()
      local notify_spy = spy.on(utils, "notify")

      local bufnr = helper.assert_scenario({
        input = [[
          local fo|o = "foo"
          local bar = "bar"
        ]],
        filetype = "lua",
        action = function()
          vim.cmd("normal! vap")
          actions.insert_log({ position = "below" })
        end,
      })

      vim.api.nvim_set_current_buf(bufnr)
      actions.toggle_comment_log_statements({ global = false })

      helper.assert_buf_content(
        bufnr,
        [[
          local foo = "foo"
          print(" foo", foo)
          local bar = "bar"
          print(" bar", bar)
        ]]
      )

      assert.spy(notify_spy).was_called(1)
      assert.spy(notify_spy).was_called_with("config.log_marker is not configured", "warn")
      notify_spy:clear()
    end)
  end)
end)

describe("timber.actions.search_log_statements", function()
  it("calls telescope.builtin.grep_string with the log_marker", function()
    timber.setup({ log_marker = "foo" })

    local telescope = require("telescope.builtin")
    local telescope_spy = spy.on(telescope, "grep_string")

    actions.search_log_statements()
    vim.cmd("close!")

    assert.spy(telescope_spy).was_called(1)
    assert.spy(telescope_spy).was_called_with({ search = "foo", prompt_title = "Log Statements (timber.nvim)" })
  end)
end)
