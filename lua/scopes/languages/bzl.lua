--- Starlark/BUILD language node types for scopes.nvim
--- Covers Bazel BUILD files and the Please build system (thought-machine/please),
--- both of which use Starlark syntax (tree-sitter parser: bzl / starlark).
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
  call = {
    kind = "function",
    is_scope = true,
    name_getter = function(node, source)
      -- Try to extract the `name` keyword argument, which is the build target name.
      local args = node:field("arguments")[1]
      if args then
        for child in args:iter_children() do
          if child:type() == "keyword_argument" then
            local key_node = child:field("name")[1]
            if key_node and vim.treesitter.get_node_text(key_node, source) == "name" then
              local val_node = child:field("value")[1]
              if val_node then
                local text = vim.treesitter.get_node_text(val_node, source)
                -- Strip surrounding quotes from the string literal.
                if text:sub(1, 1) == '"' or text:sub(1, 1) == "'" then
                  return text:sub(2, -2)
                end
                return text
              end
            end
          end
        end
      end
      -- Fall back to the function/rule name (e.g. "glob", "select").
      local func_node = node:field("function")[1]
      if func_node then
        return vim.treesitter.get_node_text(func_node, source)
      end
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
