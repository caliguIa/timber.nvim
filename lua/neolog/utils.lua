local M = {}

function M.array_includes(array, value)
  for _, v in ipairs(array) do
    if v == value then
      return true
    end
  end

  return false
end

function M.get_key_by_value(t, value)
  for k, v in pairs(t) do
    if v == value then
      return k
    end
  end

  return nil
end

return M
