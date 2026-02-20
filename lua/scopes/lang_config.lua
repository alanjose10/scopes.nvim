--- LangConfig builder for scopes.nvim.
--- Derives scope_types, symbol_types, kind_map, and get_name from a raw node_types table.

local M = {}

--- Build a full LangConfig from a raw node_types table.
--- @param node_types table<string, {kind: string, is_scope: boolean, name_getter: fun(node: TSNode, source: number): string|nil}>
--- @return LangConfig
function M.build(node_types)
  local config = {
    node_types = node_types,
    scope_types = {},
    symbol_types = {},
    kind_map = {},
  }
  for node_type, info in pairs(node_types) do
    config.kind_map[node_type] = info.kind
    if info.is_scope then
      table.insert(config.scope_types, node_type)
    else
      table.insert(config.symbol_types, node_type)
    end
  end
  config.get_name = function(node, source)
    local info = node_types[node:type()]
    if info and info.name_getter then
      return info.name_getter(node, source)
    end
    return node:type()
  end
  return config
end

--- Load and build a LangConfig for the given language name.
--- Returns nil (with a warning) if no language file exists.
--- @param lang string  e.g. "go", "lua"
--- @return LangConfig|nil
function M.load(lang)
  local ok, node_types = pcall(require, "scopes.languages." .. lang)
  if not ok then
    vim.notify("scopes.nvim: no language config for '" .. lang .. "'", vim.log.levels.WARN)
    return nil
  end
  return M.build(node_types)
end

return M
