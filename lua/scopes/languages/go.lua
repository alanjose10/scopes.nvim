--- Go language configuration for scopes.nvim
--- Maps Treesitter node types to scope/symbol categories.

--- @type LangConfig
local M = {
  node_types = {
    -- Scoped types
    function_declaration = { kind = "function", is_scope = true },
    method_declaration = { kind = "method", is_scope = true },
    func_literal = { kind = "function", is_scope = true },
    if_statement = { kind = "block", is_scope = true },
    for_statement = { kind = "block", is_scope = true },
    select_statement = { kind = "block", is_scope = true },
    type_declaration = { kind = "type", is_scope = true },
    import_declaration = { kind = "block", is_scope = true },

    -- Non scoped types
    var_spec = { kind = "variable", is_scope = false },
    const_spec = { kind = "const", is_scope = false },
    short_var_declaration = { kind = "variable", is_scope = false },
    field_declaration = { kind = "variable", is_scope = false },
    import_spec = { kind = "variable", is_scope = false },
    call_expression = { kind = "function", is_scope = false },
  },

  --- Extract a human-readable name from a Treesitter node.
  --- @param node TSNode
  --- @param source number buffer number
  --- @return string
  get_name = function(node, source)
    local node_type = node:type()

    if node_type == "function_declaration" then
      local name_node = node:field("name")[1]
      if name_node then
        return vim.treesitter.get_node_text(name_node, source)
      end
    end

    if node_type == "method_declaration" then
      local name_node = node:field("name")[1]
      if name_node then
        return vim.treesitter.get_node_text(name_node, source)
      end
    end

    if node_type == "func_literal" then
      return "[anonymous]"
    end

    if node_type == "type_declaration" then
      -- type_declaration contains a type_spec child with the name
      for child in node:iter_children() do
        if child:type() == "type_spec" then
          local name_node = child:field("name")[1]
          if name_node then
            return vim.treesitter.get_node_text(name_node, source)
          end
        end
      end
    end

    if node_type == "var_spec" or node_type == "const_spec" then
      local name_node = node:field("name")[1]
      if name_node then
        return vim.treesitter.get_node_text(name_node, source)
      end
    end

    if node_type == "short_var_declaration" then
      local left = node:field("left")[1]
      if left then
        return vim.treesitter.get_node_text(left, source)
      end
    end

    if node_type == "field_declaration" then
      local field = node:field("name")[1]
      if field then
        return vim.treesitter.get_node_text(field, source)
      end
    end

    if node_type == "import_declaration" then
      return "import"
    end

    if node_type == "import_spec" then
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
    end

    if node_type == "if_statement" then
      return "if"
    end

    if node_type == "for_statement" then
      return "for"
    end

    if node_type == "select_statement" then
      return "select"
    end

    if node_type == "call_expression" then
      local fun = node:field("function")[1]
      if fun then
        return vim.treesitter.get_node_text(fun, source)
      end
    end

    return node_type
  end,
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

return M
