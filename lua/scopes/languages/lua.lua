--- Lua language configuration for scopes.nvim
--- Maps Treesitter node types to scope/symbol categories.

--- @type LangConfig
local M = {
  node_types = {
    function_declaration = { kind = "function", is_scope = true },
    function_definition = { kind = "function", is_scope = true },
    if_statement = { kind = "block", is_scope = true },
    for_statement = { kind = "block", is_scope = true },
    while_statement = { kind = "block", is_scope = true },
    do_statement = { kind = "block", is_scope = true },
    assignment_statement = { kind = "variable", is_scope = false },
    variable_declaration = { kind = "variable", is_scope = false },
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

    if node_type == "function_definition" then
      return "[anonymous]"
    end

    if node_type == "assignment_statement" or node_type == "variable_declaration" then
      -- For variable_declaration, drill into its inner assignment_statement
      local assign = node
      if node_type == "variable_declaration" then
        for child in node:iter_children() do
          if child:type() == "assignment_statement" then
            assign = child
            break
          end
        end
        if assign == node then
          return node_type
        end
      end
      -- assignment_statement has a variable_list child; return its full text
      for child in assign:iter_children() do
        if child:type() == "variable_list" then
          return vim.treesitter.get_node_text(child, source)
        end
      end
    end

    if node_type == "if_statement" then
      return "if"
    end

    if node_type == "for_statement" then
      return "for"
    end

    if node_type == "while_statement" then
      return "while"
    end

    if node_type == "do_statement" then
      return "do"
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
