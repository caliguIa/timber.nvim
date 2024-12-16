local assert = require("luassert")
local spy = require("luassert.spy")
local events = require("timber.events")
local timber = require("timber")
local summary = require("timber.summary")
local watcher = require("timber.watcher")
local helper = require("tests.timber.helper")
local utils = require("timber.utils")

local function get_line_hl_groups(line, bufnr)
  bufnr = bufnr or 0

  local extmarks = vim.api.nvim_buf_get_extmarks(
    bufnr,
    summary.summary_focus_ns,
    { line, 0 },
    { line, -1 },
    { details = true }
  )

  return vim
    .iter(extmarks)
    :map(function(i)
      return i[4].line_hl_group
    end)
    :totable()
end

describe("timber.summary.open", function()
  before_each(function()
    timber.setup()
  end)

  after_each(function()
    summary.clear()
    summary.close()
    events.clear()
  end)

  it("returns the window and buffer IDs", function()
    events.emit("watcher:new_log_entry", {
      log_placeholder_id = "ABC",
      payload = "Hello world\nGood bye world",
      source_id = "timber_test",
      timestamp = os.time(),
    })

    local winnr, bufnr = summary.open()
    local content = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    assert.is.True(vim.api.nvim_win_is_valid(winnr))
    assert.is.True(vim.api.nvim_win_is_valid(winnr))
    assert.equals("Hello world", content[3])
    assert.equals("Good bye world", content[4])
  end)

  it("sorts the log entries by timestamp", function()
    events.emit("watcher:new_log_entry", {
      log_placeholder_id = "ABC",
      payload = "After",
      source_id = "timber_test",
      timestamp = os.time(),
    })

    events.emit("watcher:new_log_entry", {
      log_placeholder_id = "DEF",
      payload = "Before",
      source_id = "timber_test",
      timestamp = os.time() - 20,
    })

    local _, bufnr = summary.open()

    helper.assert_buf_content(
      bufnr,
      [[

        🪵DEF
        Before

        🪵ABC
        After
      ]],
      false
    )
  end)

  it("returns the window and buffer IDs", function()
    events.emit("watcher:new_log_entry", {
      log_placeholder_id = "ABC",
      payload = "Hello world\nGood bye world",
      source_id = "timber_test",
      timestamp = os.time(),
    })

    local winnr, bufnr = summary.open()
    local content = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    assert.is.True(vim.api.nvim_win_is_valid(winnr))
    assert.equals(bufnr, vim.api.nvim_win_get_buf(winnr))
    assert.equals("Hello world", content[3])
    assert.equals("Good bye world", content[4])
  end)

  it("focuses the window if focus is true", function()
    events.emit("watcher:new_log_entry", {
      log_placeholder_id = "ABC",
      payload = "Hello world\nGood bye world",
      source_id = "timber_test",
      timestamp = os.time(),
    })

    local winnr, _ = summary.open({ focus = true })

    assert.equals(winnr, vim.api.nvim_get_current_win())
  end)

  describe("given the current line has a log placeholder", function()
    it("scrolls to the first corresponding log entries header", function()
      local id1 = watcher.generate_unique_id()
      local id2 = watcher.generate_unique_id()

      helper.assert_scenario({
        input = string.format(
          [[
            print("%s%s|")
            print("%s%s|")
          ]],
          watcher.MARKER,
          id1,
          watcher.MARKER,
          id2
        ),
        input_cursor = false,
        filetype = "lua",
        action = function()
          events.emit("watcher:new_log_entry", {
            log_placeholder_id = id1,
            payload = "First",
            source_id = "timber_test",
            timestamp = os.time(),
          })

          events.emit("watcher:new_log_entry", {
            log_placeholder_id = id2,
            payload = "Second",
            source_id = "timber_test",
            timestamp = os.time(),
          })

          -- Move cursor to the second line
          vim.cmd("normal! 2G")
          summary.open()
        end,
        expected = function()
          local current_line = vim.api.nvim_get_current_line()
          assert.equals(watcher.MARKER .. id2, current_line)
        end,
      })
    end)

    it("highlights ALL the matching log entries header", function()
      local id1 = watcher.generate_unique_id()
      local id2 = watcher.generate_unique_id()

      helper.assert_scenario({
        input = string.format(
          [[
            print("%s%s|")
            print("%s%s|")
            print("%s%s|")
          ]],
          watcher.MARKER,
          id1,
          watcher.MARKER,
          id2,
          watcher.MARKER,
          id1
        ),
        input_cursor = false,
        filetype = "lua",
        action = function()
          events.emit("watcher:new_log_entry", {
            log_placeholder_id = id1,
            payload = "First",
            source_id = "timber_test",
            timestamp = os.time(),
          })

          events.emit("watcher:new_log_entry", {
            log_placeholder_id = id2,
            payload = "Second",
            source_id = "timber_test",
            timestamp = os.time() + 1,
          })

          events.emit("watcher:new_log_entry", {
            log_placeholder_id = id1,
            payload = "First again",
            source_id = "timber_test",
            timestamp = os.time() + 2,
          })

          -- Move cursor to the third line
          vim.cmd("normal! 3G")
          summary.open({ focus = true })
        end,
        expected = function()
          local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

          for i, line in ipairs(lines) do
            if line:match("🪵" .. id1) then
              local hl_extmars = get_line_hl_groups(i - 1)
              assert.is.True(vim.list_contains(hl_extmars, "Timber.SummarySeparatorHighlighted"))
            else
              local hl_extmars = get_line_hl_groups(i - 1)
              assert.is.False(vim.list_contains(hl_extmars, "Timber.SummarySeparatorHighlighted"))
            end
          end
        end,
      })
    end)

    it("highlights NEW matching log entries header", function()
      local id1 = watcher.generate_unique_id()
      local id2 = watcher.generate_unique_id()

      local assert_highlight_group = function()
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

        for i, line in ipairs(lines) do
          if line:match("🪵" .. id1) then
            local hl_extmars = get_line_hl_groups(i - 1)
            assert.is.True(vim.list_contains(hl_extmars, "Timber.SummarySeparatorHighlighted"))
          else
            local hl_extmars = get_line_hl_groups(i - 1)
            assert.is.False(vim.list_contains(hl_extmars, "Timber.SummarySeparatorHighlighted"))
          end
        end
      end

      helper.assert_scenario({
        input = string.format(
          [[
            print("%s%s|")
            print("%s%s|")
            print("%s%s|")
          ]],
          watcher.MARKER,
          id1,
          watcher.MARKER,
          id2,
          watcher.MARKER,
          id1
        ),
        input_cursor = false,
        filetype = "lua",
        action = function()
          events.emit("watcher:new_log_entry", {
            log_placeholder_id = id1,
            payload = "First",
            source_id = "timber_test",
            timestamp = os.time(),
          })

          events.emit("watcher:new_log_entry", {
            log_placeholder_id = id2,
            payload = "Second",
            source_id = "timber_test",
            timestamp = os.time() + 1,
          })

          events.emit("watcher:new_log_entry", {
            log_placeholder_id = id1,
            payload = "First again",
            source_id = "timber_test",
            timestamp = os.time() + 2,
          })

          vim.defer_fn(function()
            events.emit("watcher:new_log_entry", {
              log_placeholder_id = id1,
              payload = "First again again",
              source_id = "timber_test",
              timestamp = os.time() + 3,
            })
          end, 100)

          -- Move cursor to the third line
          vim.cmd("normal! 3G")
          summary.open()
        end,
        expected = function()
          assert_highlight_group()

          -- Wait for the new log entry to come
          helper.wait(200)
          assert_highlight_group()
        end,
      })
    end)
  end)

  it("tracks the cursor and highlights matching headers in the current line", function()
    local id1 = watcher.generate_unique_id()
    local id2 = watcher.generate_unique_id()

    local assert_highlight_header = function(bufnr, placeholder_id)
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

      for i, line in ipairs(lines) do
        if line:match("🪵" .. placeholder_id) then
          local hl_extmars = get_line_hl_groups(i - 1, bufnr)
          assert.is.True(vim.list_contains(hl_extmars, "Timber.SummarySeparatorHighlighted"))
        else
          local hl_extmars = get_line_hl_groups(i - 1, bufnr)
          assert.is.False(vim.list_contains(hl_extmars, "Timber.SummarySeparatorHighlighted"))
        end
      end
    end

    helper.assert_scenario({
      input = string.format(
        [[
          print("%s%s|")
          print("%s%s|")
        ]],
        watcher.MARKER,
        id1,
        watcher.MARKER,
        id2
      ),
      input_cursor = false,
      filetype = "lua",
      action = function()
        events.emit("watcher:new_log_entry", {
          log_placeholder_id = id1,
          payload = "First",
          source_id = "timber_test",
          timestamp = os.time(),
        })

        events.emit("watcher:new_log_entry", {
          log_placeholder_id = id2,
          payload = "Second",
          source_id = "timber_test",
          timestamp = os.time(),
        })

        -- Move cursor to the second line
        vim.cmd("normal! 2G")
      end,
      expected = function()
        local _, bufnr = summary.open({ focus = false })
        assert_highlight_header(bufnr, id2)

        -- Move cursor to the first line
        vim.cmd("normal! 1G")
        -- Wait for the debounce timer
        helper.wait(summary.CURSOR_TRACKING_DEBOUNCE + 25)
        assert_highlight_header(bufnr, id1)
      end,
    })
  end)

  it("DOES NOT focus the window if focus is false", function()
    events.emit("watcher:new_log_entry", {
      log_placeholder_id = "ABC",
      payload = "Hello world\nGood bye world",
      source_id = "timber_test",
      timestamp = os.time(),
    })

    local winnr, _ = summary.open({ focus = false })

    assert.Not.equals(winnr, vim.api.nvim_get_current_win())
  end)

  it("setups buffer keymaps for the summary window", function()
    local id = watcher.generate_unique_id()
    local open_entry_spy = spy.on(summary, "_open_entry")
    local scroll_to_next_entry_spy = spy.on(summary, "_scroll_to_next_entry")
    local scroll_to_prev_entry_spy = spy.on(summary, "_scroll_to_prev_entry")

    helper.assert_scenario({
      input = string.format(
        [[
          -- Dummy comment
          print("%s%s|")
        ]],
        watcher.MARKER,
        id
      ),
      input_cursor = false,
      filetype = "lua",
      action = function()
        events.emit("watcher:new_log_entry", {
          log_placeholder_id = id,
          payload = "First",
          source_id = "timber_test",
          timestamp = os.time(),
        })
      end,
      expected = function()
        local winnr, _ = summary.open({ focus = true })

        -- Focus to the summary window
        assert.equals(winnr, vim.api.nvim_get_current_win())

        -- o: open
        vim.api.nvim_feedkeys("o", "m", false)
        helper.wait(20)
        assert.spy(open_entry_spy).was_called(1)
        assert.spy(open_entry_spy).was_called_with({ jump = false })

        open_entry_spy:clear()

        -- CR: open and jump
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, true, true), "m", false)
        helper.wait(20)
        assert.spy(open_entry_spy).was_called(1)
        assert.spy(open_entry_spy).was_called_with({ jump = true })

        -- ]]: scroll to next entry
        vim.api.nvim_feedkeys("]]", "m", false)
        helper.wait(20)
        assert.spy(scroll_to_next_entry_spy).was_called(1)

        -- [[: scroll to next entry
        vim.api.nvim_feedkeys("[[", "m", false)
        helper.wait(20)
        assert.spy(scroll_to_prev_entry_spy).was_called(1)

        -- q: close
        vim.api.nvim_feedkeys("q", "m", false)
        helper.wait(20)
        assert.is.False(vim.api.nvim_win_is_valid(winnr))
      end,
    })

    open_entry_spy:clear()
  end)

  it("updates the buffer in real time", function()
    events.emit("watcher:new_log_entry", {
      log_placeholder_id = "ABC",
      payload = "First",
      source_id = "timber_test",
      timestamp = os.time(),
    })

    vim.defer_fn(function()
      events.emit("watcher:new_log_entry", {
        log_placeholder_id = "DEF",
        payload = "Second",
        source_id = "timber_test",
        timestamp = os.time() + 100,
      })
    end, 100)

    local _, bufnr = summary.open()

    helper.assert_buf_content(
      bufnr,
      [[

        🪵ABC
        First
      ]],
      false
    )

    helper.wait(200)

    helper.assert_buf_content(
      bufnr,
      [[

        🪵ABC
        First

        🪵DEF
        Second
      ]],
      false
    )
  end)
end)

describe("timber.summary.toggle", function()
  before_each(function()
    timber.setup()
  end)

  after_each(function()
    summary.clear()
    summary.close()
    events.clear()
  end)

  describe("given the window is already open", function()
    it("closes the window", function()
      local winnr, _ = summary.open()
      local opened = summary.toggle()

      assert.is.False(opened)
      assert.is.False(vim.api.nvim_win_is_valid(winnr))
    end)
  end)

  describe("given the window is NOT already open", function()
    it("opens the window", function()
      local opened, winnr, _ = summary.toggle()

      assert.is.True(opened)
      ---@cast winnr integer
      assert.is.True(vim.api.nvim_win_is_valid(winnr))
    end)
  end)
end)

describe("timber.summary._open_entry", function()
  before_each(function()
    timber.setup()
  end)

  after_each(function()
    summary.clear()
    summary.close()
    events.clear()
  end)

  describe("given the jump opts is true", function()
    it("moves the cursor to the log placeholder", function()
      local id = watcher.generate_unique_id()

      helper.assert_scenario({
        input = string.format(
          [[
            -- Dummy comment
            print("%s%s|")
          ]],
          watcher.MARKER,
          id
        ),
        input_cursor = false,
        filetype = "lua",
        action = function()
          helper.wait(20)

          events.emit("watcher:new_log_entry", {
            log_placeholder_id = id,
            payload = "First",
            source_id = "timber_test",
            timestamp = os.time(),
          })

          vim.cmd("normal! 2G")
          summary.open({ focus = true })
          summary._open_entry({ jump = true })
        end,
        expected = function()
          local current_line = vim.fn.getline(".")
          assert.equals(string.format([[print("🪵%s|")]], id), current_line)
        end,
      })
    end)
  end)

  describe("given the jump opts is false", function()
    it("DOES NOT move the cursor to the log placeholder", function()
      local id = watcher.generate_unique_id()
      local cursor = nil

      helper.assert_scenario({
        input = string.format(
          [[
            -- Dummy comment
            print("%s%s|")
          ]],
          watcher.MARKER,
          id
        ),
        input_cursor = false,
        filetype = "lua",
        action = function()
          helper.wait(20)

          events.emit("watcher:new_log_entry", {
            log_placeholder_id = id,
            payload = "First",
            source_id = "timber_test",
            timestamp = os.time(),
          })

          vim.cmd("normal! 2G")
          summary.open({ focus = true })
          cursor = vim.api.nvim_win_get_cursor(0)
          summary._open_entry({ jump = false })
        end,
        expected = function()
          local after_cursor = vim.api.nvim_win_get_cursor(0)
          assert.same(cursor, after_cursor)
        end,
      })
    end)
  end)

  describe("given the log placeholder is NOT in a loaded buffer", function()
    before_each(function()
      vim.fn.system({ "rm", "-rf", "test_sandbox.summary" })
      vim.fn.mkdir("test_sandbox.summary")
    end)

    after_each(function()
      vim.fn.system({ "rm", "-rf", "test_sandbox.summary" })
    end)

    it("opens the buffer and jump to the line", function()
      local id = watcher.generate_unique_id()
      local file_content = string.format([[print("%s%s| Hello world")]], watcher.MARKER, id)

      local file = io.open("test_sandbox.summary/open_entry1", "w")
      ---@cast file -nil
      file:write(file_content)
      file:close()

      events.emit("watcher:new_log_entry", {
        log_placeholder_id = id,
        payload = "First",
        source_id = "timber_test",
        timestamp = os.time(),
      })

      summary.open({ focus = true })
      vim.cmd("normal! 2G")
      summary._open_entry({ jump = true })

      local current_line = vim.api.nvim_get_current_line()
      assert.equals(string.format([[print("🪵%s| Hello world")]], id), current_line)
    end)
  end)

  describe("given the log placeholder DOES NOT exist", function()
    it("notifies users with a warning message", function()
      local id = watcher.generate_unique_id()
      local notify_spy = spy.on(utils, "notify")

      helper.assert_scenario({
        input = string.format(
          [[
            -- Dummy comment
            print("%sZZZ|")
          ]],
          watcher.MARKER
        ),
        input_cursor = false,
        filetype = "lua",
        action = function()
          helper.wait(20)

          events.emit("watcher:new_log_entry", {
            log_placeholder_id = id,
            payload = "First",
            source_id = "timber_test",
            timestamp = os.time(),
          })

          summary.open({ focus = true })
          vim.cmd("normal! 2G")
          summary._open_entry({ jump = true })
        end,
        expected = function()
          assert.spy(notify_spy).was_called(1)
          assert.spy(notify_spy).was_called_with(string.format("Could not find log placeholder %s", id), "warn")
          notify_spy:clear()
        end,
      })
    end)
  end)
end)

describe("timber.summary._scroll_to_next_entry", function()
  before_each(function()
    timber.setup()
  end)

  after_each(function()
    summary.clear()
    summary.close()
    events.clear()
  end)

  it("moves the cursor to the next entry", function()
    local id1 = watcher.generate_unique_id()
    local id2 = watcher.generate_unique_id()
    local id3 = watcher.generate_unique_id()

    events.emit("watcher:new_log_entry", {
      log_placeholder_id = id1,
      payload = "First",
      source_id = "timber_test",
      timestamp = os.time(),
    })

    events.emit("watcher:new_log_entry", {
      log_placeholder_id = id2,
      payload = "Second",
      source_id = "timber_test",
      timestamp = os.time() + 10,
    })

    events.emit("watcher:new_log_entry", {
      log_placeholder_id = id3,
      payload = "Third",
      source_id = "timber_test",
      timestamp = os.time() + 20,
    })

    summary.open({ focus = true })
    -- Move to the first entry
    vim.cmd("normal! 2G")
    summary._scroll_to_next_entry()
    local current_line = vim.api.nvim_get_current_line()
    assert.equals(string.format([[🪵%s]], id2), current_line)

    summary._scroll_to_next_entry()
    current_line = vim.api.nvim_get_current_line()
    assert.equals(string.format([[🪵%s]], id3), current_line)

    -- There's no next entry, do nothing
    local before_linenr = vim.api.nvim_win_get_cursor(0)[1]
    summary._scroll_to_next_entry()
    local after_linenr = vim.api.nvim_win_get_cursor(0)[1]
    assert.equals(before_linenr, after_linenr)
  end)
end)

describe("timber.summary._scroll_to_prev_entry", function()
  before_each(function()
    timber.setup()
  end)

  after_each(function()
    summary.clear()
    summary.close()
    events.clear()
  end)

  it("moves the cursor to the prev entry", function()
    local id1 = watcher.generate_unique_id()
    local id2 = watcher.generate_unique_id()
    local id3 = watcher.generate_unique_id()

    events.emit("watcher:new_log_entry", {
      log_placeholder_id = id1,
      payload = "First",
      source_id = "timber_test",
      timestamp = os.time(),
    })

    events.emit("watcher:new_log_entry", {
      log_placeholder_id = id2,
      payload = "Second",
      source_id = "timber_test",
      timestamp = os.time() + 10,
    })

    events.emit("watcher:new_log_entry", {
      log_placeholder_id = id3,
      payload = "Third",
      source_id = "timber_test",
      timestamp = os.time() + 20,
    })

    summary.open({ focus = true })
    -- Move to the last entry
    vim.cmd("normal! G")
    summary._scroll_to_prev_entry()
    local current_line = vim.api.nvim_get_current_line()
    assert.equals(string.format([[🪵%s]], id2), current_line)

    summary._scroll_to_prev_entry()
    current_line = vim.api.nvim_get_current_line()
    assert.equals(string.format([[🪵%s]], id1), current_line)

    -- There's no next entry, do nothing
    local before_linenr = vim.api.nvim_win_get_cursor(0)[1]
    summary._scroll_to_prev_entry()
    local after_linenr = vim.api.nvim_win_get_cursor(0)[1]
    assert.equals(before_linenr, after_linenr)
  end)
end)

describe("timber.summary.clear", function()
  before_each(function()
    summary.setup()
  end)

  after_each(function()
    summary.clear()
    summary.close()
    events.clear()
  end)

  it("clears the summary window content", function()
    local id = watcher.generate_unique_id()

    events.emit("watcher:new_log_entry", {
      log_placeholder_id = id,
      payload = "First",
      source_id = "timber_test",
      timestamp = os.time(),
    })

    summary.open({ focus = true })

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.equals(4, #lines)

    summary.clear()

    lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.equals(1, #lines)
    assert.equals("", lines[1])
  end)
end)

describe("timber.summary.close", function()
  before_each(function()
    timber.setup()
  end)

  after_each(function()
    summary.clear()
    summary.close()
    events.clear()
  end)

  it("closes the summary window", function()
    local id = watcher.generate_unique_id()

    events.emit("watcher:new_log_entry", {
      log_placeholder_id = id,
      payload = "First",
      source_id = "timber_test",
      timestamp = os.time(),
    })

    local winnr = summary.open({ focus = true })

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.equals(4, #lines)

    summary.close()
    assert.is.False(vim.api.nvim_win_is_valid(winnr))
  end)
end)

describe("timber.summary custom keymaps", function()
  before_each(function()
    timber.setup({
      log_summary = {
        keymaps = {
          show_entry = "<C-o>",
        },
      },
    })
  end)

  after_each(function()
    summary.clear()
    summary.close()
    events.clear()
  end)

  it("allows customize keymaps", function()
    local id = watcher.generate_unique_id()
    local open_entry_spy = spy.on(summary, "_open_entry")

    helper.assert_scenario({
      input = string.format(
        [[
          -- Dummy comment
          print("%s%s|")
        ]],
        watcher.MARKER,
        id
      ),
      input_cursor = false,
      filetype = "lua",
      action = function()
        events.emit("watcher:new_log_entry", {
          log_placeholder_id = id,
          payload = "First",
          source_id = "timber_test",
          timestamp = os.time(),
        })
      end,
      expected = function()
        summary.open({ focus = true })

        -- CR: open and jump
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-o>", true, true, true), "m", false)
        helper.wait(20)
        assert.spy(open_entry_spy).was_called(1)
        assert.spy(open_entry_spy).was_called_with({ jump = false })

        open_entry_spy:clear()
      end,
    })

    open_entry_spy:clear()
  end)
end)
