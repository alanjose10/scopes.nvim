--- Go language configuration for scopes.nvim
--- Maps Treesitter node types to scope/symbol categories.

--- @type LangConfig
local M = {
  scope_types = {
    "function_declaration",
    "method_declaration",
    "func_literal",
    "if_statement",
    "for_statement",
    "select_statement",
    "type_declaration",
    "import_declaration",
  },

  symbol_types = {
    "var_spec",
    "const_spec",
    "short_var_declaration",
    "field_declaration",
    "import_spec",
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
      for child in node:iter_children() do
        if child:type() == "field_identifier" then
          return vim.treesitter.get_node_text(child, source)
        end
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

    return node_type
  end,
}

return M
