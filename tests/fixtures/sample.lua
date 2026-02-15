local M = {}

-- Module-level constant
M.VERSION = "1.0.0"

-- Local helper variable
local default_opts = {
  enabled = true,
  timeout = 5000,
}

--- Create a new instance with options.
--- @param opts? table
--- @return table
function M.new(opts)
  opts = opts or {}
  local self = {
    name = opts.name or "default",
    items = {},
  }
  return self
end

--- Process items with nested control flow.
--- @param instance table
--- @param data table
function M.process(instance, data)
  if not data or #data == 0 then
    return nil, "no data"
  end

  local results = {}

  for i, item in ipairs(data) do
    if type(item) == "string" then
      results[i] = item:upper()
    elseif type(item) == "table" then
      if item.skip then
        -- skip this item
      else
        local transformed = M._transform(item)
        if transformed then
          results[i] = transformed
        end
      end
    end
  end

  return results
end

--- Internal transform helper.
--- @param item table
--- @return string|nil
function M._transform(item)
  if item.value then
    return tostring(item.value)
  end
  return nil
end

--- Run a callback for each item.
--- @param items table
--- @param callback fun(item: any, index: number)
function M.each(items, callback)
  for i, item in ipairs(items) do
    callback(item, i)
  end
end

--- Apply a mapping function and return results.
--- @param items table
--- @param fn fun(item: any): any
--- @return table
function M.map(items, fn)
  local result = {}
  for i, item in ipairs(items) do
    result[i] = fn(item)
  end
  return result
end

--- Demonstrates local function definitions.
local function setup_defaults()
  local merged = {}
  for k, v in pairs(default_opts) do
    merged[k] = v
  end
  return merged
end

--- Init function with nested callbacks.
function M.init()
  local defaults = setup_defaults()

  M.each(defaults, function(val, key)
    if type(val) == "boolean" then
      -- handle boolean config
    elseif type(val) == "number" then
      if val > 0 then
        -- handle positive number
      end
    end
  end)
end

return M
