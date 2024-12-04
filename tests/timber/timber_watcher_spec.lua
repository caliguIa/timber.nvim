local assert = require("luassert")
local spy = require("luassert.spy")
local watcher = require("timber.watcher")
local utils = require("timber.utils")
local helper = require("tests.timber.helper")

local function create_temp_file()
  -- Get the system's temporary directory
  local temp_dir = vim.fn.tempname():match("(.*[/\\])")
  local filename = temp_dir .. "timber_test_" .. os.time()

  -- Create the file
  local file = io.open(filename, "w")
  if file then
    file:close()
  else
    error("Failed to create file: " .. filename)
  end

  return filename
end

local function write_to_file(filename, content)
  local file = io.open(filename, "a")
  if file then
    file:write(content)
    file:close()
    return true
  else
    return false
  end
end

describe("timber.watcher.sources.setup", function()
  describe("supports filesystem source", function()
    after_each(function()
      require("timber.watcher.sources").stop()
    end)

    it("supports single line log", function()
      local file_path = create_temp_file()
      local specs = {
        timber_test = {
          name = "Test log file",
          type = "filesystem",
          path = file_path,
        },
      }

      local received_log_entry = nil

      require("timber.watcher.sources").setup({
        sources = specs,
        on_log_capture = function(log_entry)
          received_log_entry = log_entry
        end,
      })

      helper.wait(20)
      write_to_file(file_path, "Plain text\n")
      assert.is.Nil(received_log_entry)

      helper.wait(20)
      local start, end_, marker_id = watcher.generate_marker_pairs()
      write_to_file(file_path, string.format("%sHello World%s\n", start, end_))
      helper.wait(20)

      assert.is.Not.Nil(received_log_entry)

      ---@cast received_log_entry -nil
      assert.equals(marker_id, received_log_entry.log_placeholder_id)
      assert.equals("Hello World", received_log_entry.payload)
      assert.equals("timber_test", received_log_entry.source_id)
    end)

    it("supports multi line log", function()
      local file_path = create_temp_file()
      local specs = {
        timber_test = {
          name = "Test log file",
          type = "filesystem",
          path = file_path,
        },
      }

      local received_log_entry = nil

      require("timber.watcher.sources").setup({
        sources = specs,
        on_log_capture = function(log_entry)
          received_log_entry = log_entry
        end,
      })

      helper.wait(20)
      write_to_file(file_path, "Plain text\n")
      assert.is.Nil(received_log_entry)

      helper.wait(20)
      local start, end_, marker_id = watcher.generate_marker_pairs()
      write_to_file(file_path, string.format("%sHello World\nThis is the second line\nGoodbye World%s\n", start, end_))
      helper.wait(20)

      assert.is.Not.Nil(received_log_entry)

      ---@cast received_log_entry -nil
      assert.equals(marker_id, received_log_entry.log_placeholder_id)
      assert.are.same(
        { "Hello World", "This is the second line", "Goodbye World" },
        vim.split(received_log_entry.payload, "\n")
      )
      assert.equals("timber_test", received_log_entry.source_id)
    end)
  end)

  describe("supports neotest source", function()
    after_each(function()
      require("timber.watcher.sources").stop()
    end)

    it("supports single line log", function()
      local specs = {
        timber_test = {
          name = "Test neotest",
          type = "neotest",
        },
      }

      local received_log_entries = {}
      require("timber.watcher.sources").setup({
        sources = specs,
        on_log_capture = function(log_entry)
          table.insert(received_log_entries, log_entry)
        end,
      })

      local file_path = create_temp_file()
      local mock_neotest_result = {
        test_file = {
          status = "passed",
          output = file_path,
          errors = {},
        },
      }

      local start_1, end_1, marker_id_1 = watcher.generate_marker_pairs()
      write_to_file(file_path, string.format("%sHello World%s\n", start_1, end_1))

      local start_2, end_2, marker_id_2 = watcher.generate_marker_pairs()
      write_to_file(file_path, string.format("%sHello World again%s\n", start_2, end_2))
      helper.wait(20)

      local neotest_consumer = require("timber.watcher.sources.neotest").consumer
      local mock_client = { listeners = {} }
      neotest_consumer(mock_client)
      mock_client.listeners.results(nil, mock_neotest_result)

      assert.equals(received_log_entries[1].log_placeholder_id, marker_id_1)
      assert.are.same({ "Hello World" }, vim.split(received_log_entries[1].payload, "\n"))
      assert.equals("timber_test", received_log_entries[1].source_id)

      assert.equals(received_log_entries[2].log_placeholder_id, marker_id_2)
      assert.are.same({ "Hello World again" }, vim.split(received_log_entries[2].payload, "\n"))
      assert.equals("timber_test", received_log_entries[2].source_id)
    end)

    it("supports multi line log", function()
      local specs = {
        timber_test = {
          name = "Test neotest",
          type = "neotest",
        },
      }

      local received_log_entries = {}
      require("timber.watcher.sources").setup({
        sources = specs,
        on_log_capture = function(log_entry)
          table.insert(received_log_entries, log_entry)
        end,
      })

      local file_path = create_temp_file()
      local mock_neotest_result = {
        test_file = {
          status = "passed",
          output = file_path,
          errors = {},
        },
      }

      local start_1, end_1, marker_id_1 = watcher.generate_marker_pairs()
      write_to_file(
        file_path,
        string.format("%sHello World\nThis is the second line\nGoodbye World%s\n", start_1, end_1)
      )

      local start_2, end_2, marker_id_2 = watcher.generate_marker_pairs()
      write_to_file(
        file_path,
        string.format("%sHello World\nThis is the second line again\nGoodbye World%s\n", start_2, end_2)
      )
      helper.wait(20)

      local neotest_consumer = require("timber.watcher.sources.neotest").consumer
      local mock_client = { listeners = {} }
      neotest_consumer(mock_client)
      mock_client.listeners.results(nil, mock_neotest_result)

      assert.equals(marker_id_1, received_log_entries[1].log_placeholder_id)
      assert.are.same(
        { "Hello World", "This is the second line", "Goodbye World" },
        vim.split(received_log_entries[1].payload, "\n")
      )
      assert.equals("timber_test", received_log_entries[1].source_id)

      assert.equals(marker_id_2, received_log_entries[2].log_placeholder_id)
      assert.are.same(
        { "Hello World", "This is the second line again", "Goodbye World" },
        vim.split(received_log_entries[2].payload, "\n")
      )
      assert.equals("timber_test", received_log_entries[2].source_id)
    end)

    it("notifies when neotest source is not specified", function()
      local received_log_entries = {}
      require("timber.watcher.sources").setup({
        sources = {},
        on_log_capture = function(log_entry)
          table.insert(received_log_entries, log_entry)
        end,
      })
      local notify_spy = spy.on(utils, "notify")

      local file_path = create_temp_file()
      local mock_neotest_result = {
        test_file = {
          status = "passed",
          output = file_path,
          errors = {},
        },
      }

      local start, end_ = watcher.generate_marker_pairs()
      write_to_file(file_path, string.format("%sHello World%s\n", start, end_))
      helper.wait(20)

      local neotest_consumer = require("timber.watcher.sources.neotest").consumer
      local mock_client = { listeners = {} }
      neotest_consumer(mock_client)
      mock_client.listeners.results(nil, mock_neotest_result)
      helper.wait(20)

      assert.spy(notify_spy).was_called(1)
      assert
        .spy(notify_spy)
        .was_called_with("Neotest source is not started. Please add neotest source to the watcher config", "warn")
      assert.is.equal(0, #received_log_entries)
      notify_spy:clear()
    end)
  end)
end)
