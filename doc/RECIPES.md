# Recipes

The purpose of this document is to showcase some common use cases of `timber.nvim`.

## Advanced logging use cases

### Log current line

<details>
<summary>Show config</summary>

```lua
vim.keymap.set("n", "gll", function()
  return require("timber.actions").insert_log({ position = "below", operator = true }) .. "_"
end, {
  desc = "[G]o [L]og: Insert below log statements the current line",
  expr = true,
})
```

</details>

### Plain log statements

<details>
<summary>Show config</summary>

```lua
vim.keymap.set("n", "glo", function()
  require("timber.actions").insert_log({ template = "plain", position = "below" })
end, { desc = "[G]o [L]og: Insert a plain log statement below the current line" })

vim.keymap.set("n", "gl<S-o>", function()
  require("timber.actions").insert_log({ template = "plain", position = "above" })
end, { desc = "[G]o [L]og: Insert a plain log statement above the current line" })
```
</details>

### Surround log statements

<details>
<summary>Show config</summary>

```lua
vim.keymap.set("n", "gls", function()
  require("timber.actions").insert_log({
    templates = { before = "default", after = "default" },
    position = "surround",
  })
end, { desc = "[G]o [L]og [S]urround: Insert surround log statements below the current line" })
```

This will insert two log statements, one above and one below for the target at the cursor. This is useful in scenarios when functions mutate the variables and you want to track the changes:

```lua
-- "|" denotes the cursor position

-- Before
mutate_foo(fo|o)

-- After
print("foo", foo)
mutate_foo(fo|o)
print("foo", foo)
```
</details>

### Time log statements

<details>
<summary>Show config</summary>

```lua
require("timber").setup({
  log_templates = {
    time_start = {
      lua = [[local _start = os.time()]],
    },
    time_end = {
      lua = [[print("Elapsed time: " .. tostring(os.time() - _start) .. " seconds")]],
    },
  },
})

vim.keymap.set("n", "glt", function()
  require("timber.actions").insert_log({
    templates = { before = "time_start", after = "time_end" },
    position = "surround",
  })
end, {
  desc = "[G]o [L]og [T]ime: Insert a time log statement surround the cursor position",
})
```

This is useful when you want to measure execution time of a code segment.

```lua
-- "|" denotes the cursor position

-- Before
long_operation(fo|o)

-- After
local _start = os.time()
long_operation(fo|o)
print("Elapsed time: " .. tostring(os.time() - _start) .. " seconds")
```

</details>

## Pretty captured log buffer

![image](https://github.com/user-attachments/assets/e2ea2765-f43d-4ca2-91b5-a02d07f9a4ce)

You can add syntax highlighting the captured log buffer:

1. Config a custom filetype for the log buffer

```lua
-- After
opts = {
    watcher = {
        sources = {
            enabled = true,
            javascript_log = {
                type = "filesystem",
                name = "Log file",
                path = "/tmp/debug.log",
                buffer = {
                    filetype = "javascriptconsole",
                }
            }
        }
    }
}
```

2. Write a syntax file for the filetype, then put it in the runtime path. For example, in your config root, `syntax/javascriptconsole.vim`

### Examples

<details>
<summary>Javascript (console.log)</summary>

```vim
if exists("b:current_syntax")
  finish
endif

" Special patterns for console.log output
syntax match consoleLogFunction "\<\[Function.*\]\>" contained

syntax sync fromstart

" Special characters
syntax match consoleLogBrace "[{}[\]]" contained
syntax region consoleLogObject start="{" end="}" fold transparent contains=ALL

" Keywords
syntax keyword consoleLogBoolean true false
syntax keyword consoleLogKeyword null undefined NaN Infinity
syntax match consoleLogSpecial "\V\([Array]\|[Object]\|[Promise]\|[Function]\|[Reference]\|[Circular]\)"
syntax match consoleLogSpecial "\[Array(\d\+)\]"
syntax match consoleLogSpecial "Symbol(.\+)"

" Numbers
syntax match consoleLogNumber "\<\d\+\>"
syntax match consoleLogFloat "\<\d\+\.\d\+\>"

" Strings
syntax region consoleLogString start=/'/ end=/'/ skip=/\\'/ contains=@Spell

" Object keys
syntax match consoleLogObjectKey "\<\w\+\>:" contained contains=consoleLogColon
syntax match consoleLogColon ":" contained

" Define highlighting
highlight default link consoleLogBoolean Boolean
highlight default link consoleLogKeyword Keyword
highlight default link consoleLogSpecial Type
highlight default link consoleLogNumber Number
highlight default link consoleLogFloat Float
highlight default link consoleLogString String
highlight default link consoleLogObjectKey Identifier
highlight default link consoleLogColon Operator
highlight default link consoleLogBrace Delimiter
highlight default link consoleLogFunction Function

let b:current_syntax = "javascriptconsole"
```

</details>

