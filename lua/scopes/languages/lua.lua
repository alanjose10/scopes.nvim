--- Lua language configuration for scopes.nvim
--- Maps Treesitter node types to scope/symbol categories.

--- @type LangConfig
local M = {
  scope_types = {
    "function_declaration",
    "function_definition",
    "if_statement",
    "for_statement",
    "while_statement",
    "do_statement",
  },

  symbol_types = {
    "assignment_statement",
    "variable_declaration",
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

return M
