--- Go language configuration for scopes.nvim
--- Maps Treesitter node types to scope/symbol categories.

--- @type LangConfig
local M = {
  node_types = {
    -- Scoped types
    function_declaration = {
      kind = "function",
      is_scope = true,
      name_getter = function(node, source)
        local name_node = node:field("name")[1]
        if name_node then
          return vim.treesitter.get_node_text(name_node, source)
        end
      end,
    },
    method_declaration = {
      kind = "method",
      is_scope = true,
      name_getter = function(node, source)
        local name_node = node:field("name")[1]
        if name_node then
          return vim.treesitter.get_node_text(name_node, source)
        end
      end,
    },
    func_literal = {
      kind = "function",
      is_scope = true,
      name_getter = function(_node, _source)
        return "[anonymous]"
      end,
    },
    if_statement = {
      kind = "block",
      is_scope = true,
      name_getter = function(_node, _source)
        return "if"
      end,
    },
    for_statement = {
      kind = "block",
      is_scope = true,
      name_getter = function(_node, _source)
        return "for"
      end,
    },
    select_statement = {
      kind = "block",
      is_scope = true,
      name_getter = function(_node, _source)
        return "select"
      end,
    },
    type_declaration = {
      kind = "type",
      is_scope = true,
      name_getter = function(node, source)
        -- type_declaration contains a type_spec child with the name
        for child in node:iter_children() do
          if child:type() == "type_spec" then
            local name_node = child:field("name")[1]
            if name_node then
              return vim.treesitter.get_node_text(name_node, source)
            end
          end
        end
      end,
    },
    import_declaration = {
      kind = "block",
      is_scope = true,
      name_getter = function(_node, _source)
        return "import"
      end,
    },

    -- Non scoped types
    var_spec = {
      kind = "variable",
      is_scope = false,
      name_getter = function(node, source)
        local name_node = node:field("name")[1]
        if name_node then
          return vim.treesitter.get_node_text(name_node, source)
        end
      end,
    },
    const_spec = {
      kind = "const",
      is_scope = false,
      name_getter = function(node, source)
        local name_node = node:field("name")[1]
        if name_node then
          return vim.treesitter.get_node_text(name_node, source)
        end
      end,
    },
    short_var_declaration = {
      kind = "variable",
      is_scope = false,
      name_getter = function(node, source)
        local left = node:field("left")[1]
        if left then
          return vim.treesitter.get_node_text(left, source)
        end
      end,
    },
    field_declaration = {
      kind = "variable",
      is_scope = false,
      name_getter = function(node, source)
        local field = node:field("name")[1]
        if field then
          return vim.treesitter.get_node_text(field, source)
        end
      end,
    },
    import_spec = {
      kind = "variable",
      is_scope = false,
      name_getter = function(node, source)
        local path_node = node:field("path")[1]
        if path_node then
          -- path is interpreted_string_literal; get the content child to strip quotes
          for child in path_node:iter_children() do
            if child:named() then
              return vim.treesitter.get_node_text(child, source)
            end
          end
          -- Fallback: return with quotes if no content child
          return vim.treesitter.get_node_text(path_node, source)
        end
      end,
    },
    call_expression = {
      kind = "function",
      is_scope = false,
      name_getter = function(node, source)
        local fun = node:field("function")[1]
        if fun then
          return vim.treesitter.get_node_text(fun, source)
        end
      end,
    },
  },
}

-- Derive scope_types, symbol_types, kind_map from node_types
M.scope_types = {}
M.symbol_types = {}
M.kind_map = {}
for node_type, info in pairs(M.node_types) do
  M.kind_map[node_type] = info.kind
  if info.is_scope then
    table.insert(M.scope_types, node_type)
  else
    table.insert(M.symbol_types, node_type)
  end
end

--- Extract a human-readable name from a Treesitter node.
--- @param node TSNode
--- @param source number buffer number
--- @return string
M.get_name = function(node, source)
  local node_type = node:type()
  local info = M.node_types[node_type]
  if info and info.name_getter then
    return info.name_getter(node, source)
  end
  return node_type
end

return M
