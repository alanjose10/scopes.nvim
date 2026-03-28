--- Python language node types for scopes.nvim
--- Maps Treesitter node types to scope/symbol categories.

return {
  -- Scoped types
  function_definition = {
    kind = "function",
    is_scope = true,
    name_getter = function(node, source)
      local name_node = node:field("name")[1]
      if name_node then
        return vim.treesitter.get_node_text(name_node, source)
      end
    end,
  },
  class_definition = {
    kind = "class",
    is_scope = true,
    name_getter = function(node, source)
      local name_node = node:field("name")[1]
      if name_node then
        return vim.treesitter.get_node_text(name_node, source)
      end
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
  with_statement = {
    kind = "block",
    is_scope = true,
    name_getter = function(_node, _source)
      return "with"
    end,
  },

  -- Non-scoped types
  assignment = {
    kind = "variable",
    is_scope = false,
    name_getter = function(node, source)
      local left = node:field("left")[1]
      if left then
        return vim.treesitter.get_node_text(left, source)
      end
    end,
  },
}
