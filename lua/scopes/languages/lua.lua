--- @type scopes.LangConfig

local M = {}

--- Treesitter node types that create scopes (containers that can be drilled into).
--- @type string[]
M.scope_types = {
  "function_declaration",
  "function_definition",
  "if_statement",
  "for_statement",
  "while_statement",
}

--- Treesitter node types that appear as symbols (items within a scope).
--- @type string[]
M.symbol_types = {
  "assignment_statement",
  "variable_declaration",
}

--- Map from Treesitter node type to a display kind string.
--- @type table<string, string>
M.kind_map = {
  function_declaration = "function",
  function_definition = "function",
  if_statement = "block",
  for_statement = "block",
  while_statement = "block",
  assignment_statement = "variable",
  variable_declaration = "variable",
}

--- Extract a display name from a Treesitter node.
--- @param node any TSNode
--- @param source number buffer number
--- @return string
function M.get_name(node, source)
  local node_type = node:type()

  -- function_declaration: `function foo()` or `local function foo()`
  if node_type == "function_declaration" then
    local name_node = node:field("name")[1]
    if name_node then
      return vim.treesitter.get_node_text(name_node, source)
    end
  end

  -- function_definition: anonymous function `function() ... end`
  if node_type == "function_definition" then
    return "<anonymous>"
  end

  -- assignment_statement: `M.foo = ...` or `x = ...`
  if node_type == "assignment_statement" then
    -- Get the variable list (left side)
    local vars = node:field("variables")
    if vars and vars[1] then
      return vim.treesitter.get_node_text(vars[1], source)
    end
    -- Fallback: first named child
    local first = node:named_child(0)
    if first then
      return vim.treesitter.get_node_text(first, source)
    end
  end

  -- variable_declaration: `local x = ...`
  if node_type == "variable_declaration" then
    -- Look for the variable name in the first assignment or name
    for i = 0, node:named_child_count() - 1 do
      local child = node:named_child(i)
      if child and child:type() == "assignment_statement" then
        local vars = child:field("variables")
        if vars and vars[1] then
          return vim.treesitter.get_node_text(vars[1], source)
        end
      elseif child and child:type() == "variable_list" then
        local name = child:named_child(0)
        if name then
          return vim.treesitter.get_node_text(name, source)
        end
      end
    end
    -- Try getting text of first child directly
    local first = node:named_child(0)
    if first then
      local text = vim.treesitter.get_node_text(first, source)
      local first_line = text:match("^([^\n]*)")
      if first_line and #first_line > 40 then
        first_line = first_line:sub(1, 37) .. "..."
      end
      return first_line or "<unknown>"
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

  -- Fallback
  local text = vim.treesitter.get_node_text(node, source)
  local first_line = text:match("^([^\n]*)")
  if first_line and #first_line > 40 then
    first_line = first_line:sub(1, 37) .. "..."
  end
  return first_line or "<unknown>"
end

return M
