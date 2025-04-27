local timber = require("timber")
local helper = require("tests.timber.helper")
local actions = require("timber.actions")

describe("vue single log", function()
  before_each(function()
    timber.setup({
      log_templates = {
        default = {
          vue = [[console.log("%log_target", %log_target)]],
        },
      },
    })
  end)

  it("supports Javascript code in script tags", function()
    helper.assert_scenario({
      input = [[
        <script>
          const fo|o = "foo"
        </script>
      ]],
      filetype = "vue",
      action = function()
        -- For some reason, we have to call treesitter.start() to properly initialize the parser
        vim.treesitter.start(0, "vue")
        helper.wait(20)
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        <script>
          const foo = "foo"
          console.log("foo", foo)
        </script>
      ]],
    })
  end)

  it("supports Typescript code in script tags", function()
    helper.assert_scenario({
      input = [[
        <script lang="ts">
          const fo|o: string = "foo"
        </script>
      ]],
      filetype = "vue",
      action = function()
        -- For some reason, we have to call treesitter.start() to properly initialize the parser
        vim.treesitter.start(0, "vue")
        helper.wait(20)
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        <script lang="ts">
          const foo: string = "foo"
          console.log("foo", foo)
        </script>
      ]],
    })
  end)

  it("supports multiple script tags", function()
    helper.assert_scenario({
      input = [[
        <script>
          const fo|o = "foo"
        </script>

        <script lang="ts">
          const bar: string = "bar"
        </script>
      ]],
      filetype = "vue",
      action = function()
        -- For some reason, we have to call treesitter.start() to properly initialize the parser
        vim.treesitter.start(0, "vue")
        helper.wait(20)
        actions.insert_log({ position = "below" })
        vim.cmd("normal! 5j")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        <script>
          const foo = "foo"
          console.log("foo", foo)
        </script>

        <script lang="ts">
          const bar: string = "bar"
          console.log("bar", bar)
        </script>
      ]],
    })
  end)
end)

describe("vue batch log", function()
  before_each(function()
    helper.wait(20)

    timber.setup({
      batch_log_templates = {
        default = {
          vue = [[console.log({ %repeat<"%log_target": %log_target><, > })]],
        },
      },
    })
  end)

  it("supports Javascript code in script tags", function()
    helper.assert_scenario({
      input = [[
        <script>
          const fo|o = "foo"
          const bar = "bar"
        </script>
      ]],
      filetype = "vue",
      action = function()
        -- For some reason, we have to call treesitter.start() to properly initialize the parser
        vim.treesitter.start(0, "vue")
        helper.wait(20)
        vim.cmd("normal! Vj")
        actions.add_log_targets_to_batch()
        actions.insert_batch_log()
      end,
      expected = [[
        <script>
          const foo = "foo"
          const bar = "bar"
          console.log({ "foo": foo, "bar": bar })
        </script>
      ]],
    })
  end)

  it("supports Typescript code in script tags", function()
    helper.assert_scenario({
      input = [[
        <script lang="ts">
          const fo|o: string = "foo"
          const bar: string = "bar"
        </script>
      ]],
      filetype = "vue",
      action = function()
        -- For some reason, we have to call treesitter.start() to properly initialize the parser
        vim.treesitter.start(0, "vue")
        helper.wait(20)
        vim.cmd("normal! Vj")
        actions.add_log_targets_to_batch()
        actions.insert_batch_log()
      end,
      expected = [[
        <script lang="ts">
          const foo: string = "foo"
          const bar: string = "bar"
          console.log({ "foo": foo, "bar": bar })
        </script>
      ]],
    })
  end)
end)
