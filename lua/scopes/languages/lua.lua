--- Lua language node types for scopes.nvim
--- Maps Treesitter node types to scope/symbol categories.

return {
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
  function_definition = {
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
  while_statement = {
    kind = "block",
    is_scope = true,
    name_getter = function(_node, _source)
      return "while"
    end,
  },
  do_statement = {
    kind = "block",
    is_scope = true,
    name_getter = function(_node, _source)
      return "do"
    end,
  },
  assignment_statement = {
    kind = "variable",
    is_scope = false,
    name_getter = function(node, source)
      -- assignment_statement has a variable_list child; return its full text
      for child in node:iter_children() do
        if child:type() == "variable_list" then
          return vim.treesitter.get_node_text(child, source)
        end
      end
    end,
  },
  variable_declaration = {
    kind = "variable",
    is_scope = false,
    name_getter = function(node, source)
      -- variable_declaration wraps an inner assignment_statement
      for child in node:iter_children() do
        if child:type() == "assignment_statement" then
          for grandchild in child:iter_children() do
            if grandchild:type() == "variable_list" then
              return vim.treesitter.get_node_text(grandchild, source)
            end
          end
        end
      end
    end,
  },
}
