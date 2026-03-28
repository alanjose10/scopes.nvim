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
  import_statement = {
    kind = "const",
    is_scope = false,
    -- For plain imports: return the module name text.
    -- For aliased imports (`import X as Y`): return X (the module), not Y (the alias).
    -- For multi-module imports (`import a, b`): return all names joined with ", ".
    name_getter = function(node, source)
      local name_nodes = node:field("name")
      local parts = {}
      for _, name_node in ipairs(name_nodes) do
        if name_node:type() == "aliased_import" then
          local module_node = name_node:field("name")[1]
          if module_node then
            table.insert(parts, vim.treesitter.get_node_text(module_node, source))
          end
        else
          if name_node then
            table.insert(parts, vim.treesitter.get_node_text(name_node, source))
          end
        end
      end
      return #parts > 0 and table.concat(parts, ", ") or nil
    end,
  },
  import_from_statement = {
    kind = "const",
    is_scope = false,
    -- Returns the module being imported from.
    -- `from os import path`     → "os"
    -- `from os.path import join` → "os.path"
    -- `from . import something`  → "."
    name_getter = function(node, source)
      local module_node = node:field("module_name")[1]
      return module_node and vim.treesitter.get_node_text(module_node, source) or nil
    end,
  },
}
