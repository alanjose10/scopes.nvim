--- TypeScript language node types for scopes.nvim.
--- Maps Treesitter node types to scope/symbol categories.
--- Requires the nvim-treesitter typescript parser.

return {
  -- Scoped types -------------------------------------------------------

  function_declaration = {
    kind = "function",
    is_scope = true,
    name_getter = function(node, source)
      local name_node = node:field("name")[1]
      return name_node and vim.treesitter.get_node_text(name_node, source) or nil
    end,
  },

  -- Arrow functions have no "name" field; their name lives in the enclosing
  -- variable_declarator. Parent traversal is not used elsewhere and is fragile
  -- (arrow functions appear as callbacks, object values, etc.). Return
  -- "[anonymous]" consistently — the same pattern as Go's func_literal.
  arrow_function = {
    kind = "function",
    is_scope = true,
    name_getter = function(_node, _source)
      return "[anonymous]"
    end,
  },

  class_declaration = {
    kind = "class",
    is_scope = true,
    name_getter = function(node, source)
      local name_node = node:field("name")[1]
      return name_node and vim.treesitter.get_node_text(name_node, source) or nil
    end,
  },

  method_definition = {
    kind = "method",
    is_scope = true,
    name_getter = function(node, source)
      local name_node = node:field("name")[1]
      return name_node and vim.treesitter.get_node_text(name_node, source) or nil
    end,
  },

  -- interface_declaration is included as a scope so that property_signature
  -- children are shown in context (drilled into) rather than flattened at the
  -- file root with no enclosing type information.
  interface_declaration = {
    kind = "type",
    is_scope = true,
    name_getter = function(node, source)
      local name_node = node:field("name")[1]
      return name_node and vim.treesitter.get_node_text(name_node, source) or nil
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

  -- Non-scoped types ---------------------------------------------------

  -- variable_declarator is reached transparently through the unregistered
  -- lexical_declaration wrapper (const / let / var).
  variable_declarator = {
    kind = "variable",
    is_scope = false,
    name_getter = function(node, source)
      local name_node = node:field("name")[1]
      return name_node and vim.treesitter.get_node_text(name_node, source) or nil
    end,
  },

  property_signature = {
    kind = "variable",
    is_scope = false,
    name_getter = function(node, source)
      local name_node = node:field("name")[1]
      return name_node and vim.treesitter.get_node_text(name_node, source) or nil
    end,
  },

  type_alias_declaration = {
    kind = "type",
    is_scope = false,
    name_getter = function(node, source)
      local name_node = node:field("name")[1]
      return name_node and vim.treesitter.get_node_text(name_node, source) or nil
    end,
  },
}
