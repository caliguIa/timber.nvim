local timber = require("timber")
local helper = require("tests.timber.helper")
local actions = require("timber.actions")

describe("bash single log", function()
  before_each(function()
    timber.setup({
      log_templates = {
        default = {
          bash = [[echo "%log_target: ${%log_target}"]],
        },
      },
    })
  end)

  it("supports variable declaration", function()
    helper.assert_scenario({
      input = [[
        va|r="value"
      ]],
      filetype = "sh",
      action = function()
        actions.insert_log({ position = "above" })
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        echo "var: ${var}"
        var="value"
        echo "var: ${var}"
      ]],
    })
  end)

  it("supports if statement", function()
    helper.assert_scenario({
      input = [[
        if [ "$fo|o" -gt 1 ] && [ "$bar" -lt "$baz" ]; then
          exit 1
        elif [ "$bar" = true ]; then
          exit 2
        fi
      ]],
      filetype = "bash",
      action = function()
        actions.insert_log({ position = "above" })
        vim.cmd("normal! vG")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        echo "foo: ${foo}"
        if [ "$foo" -gt 1 ] && [ "$bar" -lt "$baz" ]; then
          echo "foo: ${foo}"
          echo "bar: ${bar}"
          echo "baz: ${baz}"
          exit 1
        elif [ "$bar" = true ]; then
          echo "bar: ${bar}"
          exit 2
        fi
      ]],
    })
  end)

  it("supports for loop", function()
    helper.assert_scenario({
      input = [[
        for i|tem in "${items[@]}"; do
          echo "$item"
        done
      ]],
      filetype = "bash",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        for item in "${items[@]}"; do
          echo "item: ${item}"
          echo "items[@]: ${items[@]}"
          echo "$item"
        done
      ]],
    })
  end)

  it("supports function parameters", function()
    helper.assert_scenario({
      input = [[
        function test_func() {
          local param1="$1|"
          local param2="$2"
          echo "test"
        }
      ]],
      filetype = "bash",
      action = function()
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        function test_func() {
          local param1="$1"
          echo "1: ${1}"
          local param2="$2"
          echo "test"
        }
      ]],
    })
  end)

  it("supports case statement", function()
    helper.assert_scenario({
      input = [[
        case "$opti/on" in
          "a")
            echo "Option A"
            ;;
          "b"|"B")
            echo "Option B"
            ;;
          *)
            echo "Default option"
            ;;
        esac
      ]],
      filetype = "bash",
      input_cursor = "/",
      action = function()
        actions.insert_log({ position = "above" })
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        echo "option: ${option}"
        case "$option" in
          "a")
            echo "Option A"
            ;;
          "b"|"B")
            echo "Option B"
            ;;
          *)
            echo "Default option"
            ;;
        esac
        echo "option: ${option}"
      ]],
    })
  end)

  it("supports whil statement", function()
    helper.assert_scenario({
      input = [[
        while [ "$cou|nter" -lt 10 ]; do
          ((counter++))
          echo "$counter"
        done
      ]],
      filetype = "bash",
      action = function()
        actions.insert_log({ position = "above" })
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        echo "counter: ${counter}"
        while [ "$counter" -lt 10 ]; do
          echo "counter: ${counter}"
          ((counter++))
          echo "$counter"
        done
      ]],
    })
  end)

  it("supports special variables", function()
    helper.assert_scenario({
      input = [[
        ec|ho "$@"
        echo "$*"
        echo "$#"
        echo "$$"
        echo "$?"
        echo "$!"
        echo "$-"
      ]],
      filetype = "bash",
      action = function()
        vim.cmd("normal! vap")
        actions.insert_log({ position = "below" })
      end,
      expected = [[
        echo "$@"
        echo "@: ${@}"
        echo "$*"
        echo "*: ${*}"
        echo "$#"
        echo "#: ${#}"
        echo "$$"
        echo "$: ${$}"
        echo "$?"
        echo "?: ${?}"
        echo "$!"
        echo "!: ${!}"
        echo "$-"
        echo "-: ${-}"
      ]],
    })
  end)
end)

describe("bash batch log", function()
  it("supports batch log", function()
    timber.setup({
      batch_log_templates = {
        default = {
          bash = [[echo "%repeat<%log_target: ${%log_target}><, >"]],
        },
      },
    })

    helper.assert_scenario({
      input = [[
        va|r1="test"
        var2="example"
      ]],
      filetype = "bash",
      action = function()
        vim.cmd("normal! vap")
        actions.add_log_targets_to_batch()
        actions.insert_batch_log()
      end,
      expected = [[
        var1="test"
        var2="example"
        echo "var1: ${var1}, var2: ${var2}"
      ]],
    })
  end)
end)
