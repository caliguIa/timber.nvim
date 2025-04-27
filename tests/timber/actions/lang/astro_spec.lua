local timber = require("timber")
local helper = require("tests.timber.helper")
local actions = require("timber.actions")

describe("astro single log", function()
  before_each(function()
    timber.setup({
      log_templates = {
        default = {
          astro = [[console.log("%log_target", %log_target)]],
        },
      },
    })
  end)

  it("supports Typescript code in frontmatter", function()
    local input = [[
      ---
      const fo|o = "foo"
      const bar = "bar"
      ---
      <!doctype html>
      <html lang="en">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>%title</title>
        </head>
        <body>
          <p>foo: {foo}</p>
          <p>bar: {bar}</p>
        </body>
      </html>
    ]]

    local expected = [[
      ---
      const foo = "foo"
      console.log("foo", foo)
      const bar = "bar"
      ---
      <!doctype html>
      <html lang="en">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>%title</title>
        </head>
        <body>
          <p>foo: {foo}</p>
          <p>bar: {bar}</p>
        </body>
      </html>
    ]]

    helper.assert_scenario({
      input = input,
      filetype = "astro",
      action = function()
        -- For some reason, we have to call treesitter.start() to properly initialize the parser
        vim.treesitter.start(0, "astro")
        helper.wait(20)
        actions.insert_log({ position = "below" })
      end,
      expected = expected,
    })
  end)
end)

describe("astro batch log", function()
  before_each(function()
    timber.setup({
      batch_log_templates = {
        default = {
          astro = [[console.log({ %repeat<"%log_target": %log_target><, > })]],
        },
      },
    })
  end)

  it("supports Typescript code in frontmatter", function()
    local input = [[
      ---
      const fo|o = "foo"
      const bar = "bar"
      ---
      <!doctype html>
      <html lang="en">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>%title</title>
        </head>
        <body>
          <p>foo: {foo}</p>
          <p>bar: {bar}</p>
        </body>
      </html>
    ]]

    local expected = [[
      ---
      const foo = "foo"
      const bar = "bar"
      console.log({ "foo": foo, "bar": bar })
      ---
      <!doctype html>
      <html lang="en">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>%title</title>
        </head>
        <body>
          <p>foo: {foo}</p>
          <p>bar: {bar}</p>
        </body>
      </html>
    ]]

    helper.assert_scenario({
      input = input,
      filetype = "astro",
      action = function()
        -- For some reason, we have to call treesitter.start() to properly initialize the parser
        vim.treesitter.start(0, "astro")
        helper.wait(20)
        vim.cmd("normal! Vj")
        actions.add_log_targets_to_batch()
        actions.insert_batch_log()
      end,
      expected = expected,
    })
  end)
end)
