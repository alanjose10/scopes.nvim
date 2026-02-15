--- @class scopes.LangConfig
--- @field scope_types string[]
--- @field symbol_types string[]
--- @field get_name fun(node: any, source: number): string

local M = {}

--- Treesitter node types that create scopes (containers that can be drilled into).
--- @type string[]
M.scope_types = {
  "function_declaration",
  "method_declaration",
  "func_literal",
  "if_statement",
  "for_statement",
  "select_statement",
}

--- Treesitter node types that appear as symbols (items within a scope).
--- @type string[]
M.symbol_types = {
  "var_spec",
  "const_spec",
  "short_var_declaration",
  "type_declaration",
}

--- Map from Treesitter node type to a display kind string.
--- @type table<string, string>
M.kind_map = {
  function_declaration = "function",
  method_declaration = "method",
  func_literal = "function",
  if_statement = "block",
  for_statement = "block",
  select_statement = "block",
  var_spec = "variable",
  const_spec = "const",
  short_var_declaration = "variable",
  type_declaration = "type",
}

--- Extract a display name from a Treesitter node.
--- @param node any TSNode
--- @param source number buffer number
--- @return string
function M.get_name(node, source)
  local node_type = node:type()

  -- For function/method declarations, look for the "name" field
  if node_type == "function_declaration" then
    local name_node = node:field("name")[1]
    if name_node then
      return vim.treesitter.get_node_text(name_node, source)
    end
  end

  if node_type == "method_declaration" then
    local name_node = node:field("name")[1]
    if name_node then
      local receiver_node = node:field("receiver")[1]
      local name = vim.treesitter.get_node_text(name_node, source)
      if receiver_node then
        -- Extract receiver type name from parameter_list
        local receiver_text = vim.treesitter.get_node_text(receiver_node, source)
        -- Strip parentheses and pointer prefix: (m *MyStruct) -> MyStruct
        local type_name = receiver_text:match("%*?(%w+)%s*%)") or receiver_text:match("(%w+)%s*%)")
        if type_name then
          return type_name .. "." .. name
        end
      end
      return name
    end
  end

  if node_type == "type_declaration" then
    local spec = node:named_child(0)
    if spec and spec:type() == "type_spec" then
      local name_node = spec:field("name")[1]
      if name_node then
        return vim.treesitter.get_node_text(name_node, source)
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

  if node_type == "func_literal" then
    return "<anonymous>"
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

  -- Fallback: use the first line of node text, truncated
  local text = vim.treesitter.get_node_text(node, source)
  local first_line = text:match("^([^\n]*)")
  if first_line and #first_line > 40 then
    first_line = first_line:sub(1, 37) .. "..."
  end
  return first_line or "<unknown>"
end

return M
