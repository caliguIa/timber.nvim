# Recipes

The purpose of this document is to showcase some common use cases of `timber.nvim`.

## Log current line

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

## Plain log statements

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

## Surround log statements

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

## Time log statements

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
