# How it works

This document describes the inner workings of `timber.nvim`. It is meant for users who wish to support more languages or
extend existing ones.

## Terminology

`timber.nvim` uses Treesitter to decide what to log and where to put the log statement. Here are some important terminology:

- `log target`: a Treesitter node that can be captured by the log statement (a.k.a the thing
  we want to log). For example, in the following snippet:

  ```lua
  local foo = bar + baz.baf
  ```

  `foo`, `bar`, `baz`, and `baz.baf` are all log targets.

- `log container`: a Treesitter node that may contains log targets. For example, in the following snippet:

  ```lua
  if foo > bar then
    return nil
  end

  foo(bar, baf)
  ```

  The condition `foo > bar` in the `if` statement is a log container. The arguments part of the function call `(bar,
  baf)` is also a log container.

- `logable range`: a range of lines which we can insert log statements. For example, in the following snippet:

  ```lua
  if foo > bar then
    foo = foo + 1
    bar = bar - 1
    return foo + bar
  end
  ```

  The `logable range` for the if statement is the statement body, from line 2 to 4.

## Algorithms

The algorithms consists of 2 steps:

1. Query a list of log containers using the Treesitter query [`timber-log-container`](#timber-log-container).
Then filter only nodes which intersect with the visual range (if users are in
visual mode) or contain the cursor (if users are in normal mode). This step
also determines the logable ranges, the areas that we can insert log statements,
for each container.

2. For each container found in step 1, query all log targets using the Treesitter query [`timber-log-target`](#timber-log-target).
After applying [heuristic to filter log targets](#heuristic) and [pick a logable range](#choose-logable-range),
insert a log statement for each log target.

### timber-log-container

This query has 2 purposes:

1. Find all `log containers`: use capture group `@log-container`

2. Determine the `logable range` for each container: use directive `#make-logable-range!`

`#make-logable-range` has this syntax: `#make-logable-range @node <range-type> <node-start-offset> <node-end-offset>`.
Here is the list of supported `range-type`:

1. `inner`: create a range equals to the given node's range.

  For example, given this query:
  ```query
  (if_statement
    condition: (_) @log_container
    consequence: (block) @a
    (#make-logable-range! @a "inner")
  )
  ```

  and this snippet:
  ```lua
  if foo > bar then
    foo += 1
    bar += 2
  end
  ```

  will produce one log container `foo > bar` with the logable range is the then block.

2. `before`: create a range from the start of file to the start of given node.
3. `after`: create a range from the the end of given node to the end of the file.

  For example, given this query:
  ```query
  (
    (variable_declaration) @log_container
    (#make-logable-range! @log_container "before")
    (#make-logable-range! @log_container "after")
  )
  ```

  and this snippet:
  ```lua
  local foo = bar + 1
  ```

  will produce one log container `local foo = bar + 1` with the two logable ranges: one is every lines above and one
  is every lines below.

4. `outer`: create two ranges using `before` and `after`.

  The above query can be shorten to:
  ```query
  (
    (variable_declaration) @log_container
    (#make-logable-range! @log_container "outer")
  )
  ```

### timber-log-target

This query searches for log targets inside a log container. Log targets are captured by `@log-target` group. For example,
this query captures variables in Lua.

  ```query
  (
    (identifier) @log_target
    (#not-has-parent? @log_target field)
    (#not-has-parent? @log_target dot_index_expression)
    (#not-has-parent? @log_target bracket_index_expression)
    (#not-eq? @log_target "_")
  )
  ```

## Heuristic

When there are ambiguities, `timber.nvim` tries to guess your itention using several heuristics.
Consider this case (`|` denotes the cursor position):

```
local foo = ba|r.baz.baf
```

We have three potential log targets: `bar`, `bar.baz`, and `bar.baz.baf`. Which one should we choose?

Consider the same case, but this time using visual mode (`|` denotes the visual selection boundaries):

```
local foo = |bar.baz.b|af
```

In both cases, we choose the target based on the user's selection range. In normal mode, this range is
a single point at the cursor position. The heuristic is:

1. Pick the largest node that fits entirely within the selection range
2. If no nodes are covered by the selection range, select the smallest available node

Let's put it into practice:

- In the visual mode example, the selection range covers `bar` and `bar.baz`. We pick `bar.baz`
since it's the larger node
- In the normal mode example, the selection range is too small and doesn't cover any nodes.
We pick `bar` as it's the smallest available node

> [!NOTE]
> Here's a quiz: what would we capture in this case?
> `local foo = bar.ba|z.baf`

## Choosing logable range

The logable range is chosen based on the position of the log action:

- `above`: choose the closest range above the cursor
- `below`: choose the closest range below the cursor
