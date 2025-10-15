--- This class represents a range of TSNode, spans from start_node to end_node
--- For some languages (like Dart), due to the syntax of the parser, some log targets can't be represented by a single TSNode. Consider this example:
---   ```
---   var foo = bar.baf;
---   ```
--- We want to capture `bar.baf`, but there's no single TSNode that represents it. The `bar` node (idenfiter) and `baf` node (selector) are two sibling nodes, with no parent node that includes them. In another word, there's no node similar to `member_expression` in Javascript or `dot_index_expression` in Lua
--- This class acts as a `virtual` node that represents the range of the two nodes. We implement a minimal interface of TSNode to make it work with the rest of the code.

local M = {}

---@class Timber.Actions.Treesitter.TSNodeRange
---@field start_node TSNode
---@field end_node TSNode
local TSNodeRange = {}

function TSNodeRange:id()
  return self.start_node:id() .. "-" .. self.end_node:id()
end

function TSNodeRange:range()
  local srow, scol, _, _ = self.start_node:range()
  local _, _, erow, ecol = self.end_node:range()
  return srow, scol, erow, ecol
end

function TSNodeRange:start()
  return self.start_node:start()
end

function TSNodeRange:end_()
  return self.end_node:end_()
end

---@param start_node TSNode
---@param end_node TSNode
function M.new(start_node, end_node)
  local o = {
    start_node = start_node,
    end_node = end_node,
  }

  setmetatable(o, TSNodeRange)
  TSNodeRange.__index = TSNodeRange
  return o
end

return M
