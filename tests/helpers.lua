--- Test helpers for scopes.nvim tests.
--- Provides utilities for building test trees without Treesitter dependency.

local M = {}

--- Create a ScopeNode for testing.
--- @param name string
--- @param kind string
--- @param range {start_row: number, start_col: number, end_row: number, end_col: number}
--- @param is_scope boolean
--- @param is_error? boolean
--- @return ScopeNode
function M.make_node(name, kind, range, is_scope, is_error)
  return {
    name = name,
    kind = kind,
    range = range,
    children = {},
    parent = nil,
    is_scope = is_scope,
    is_error = is_error or false,
  }
end

--- Add a child node to a parent, setting the parent back-reference.
--- @param parent ScopeNode
--- @param child ScopeNode
function M.add_child(parent, child)
  child.parent = parent
  table.insert(parent.children, child)
end

--- Build a test ScopeTree that mimics a Go file structure:
---
--- <root> (file, rows 0-30)
---   ├── MaxRetries (const, row 2)
---   ├── MyStruct (type, rows 5-8, scope)
---   │   └── Name (variable, row 6)
---   ├── NewMyStruct (function, rows 10-15, scope)
---   │   └── s (variable, row 11)
---   └── HandleRequest (method, rows 17-30, scope)
---       ├── if (block, rows 18-20, scope)
---       └── for (block, rows 22-29, scope)
---           └── if (block, rows 23-26, scope)
---
--- @return ScopeTree
function M.make_test_tree()
  local root = M.make_node("<root>", "file", { start_row = 0, start_col = 0, end_row = 30, end_col = 0 }, true)

  -- Top-level const
  local max_retries = M.make_node("MaxRetries", "const", { start_row = 2, start_col = 0, end_row = 2, end_col = 20 }, false)
  M.add_child(root, max_retries)

  -- MyStruct type (scope)
  local my_struct = M.make_node("MyStruct", "type", { start_row = 5, start_col = 0, end_row = 8, end_col = 1 }, true)
  M.add_child(root, my_struct)

  local name_field = M.make_node("Name", "variable", { start_row = 6, start_col = 1, end_row = 6, end_col = 12 }, false)
  M.add_child(my_struct, name_field)

  -- NewMyStruct function (scope)
  local new_struct = M.make_node("NewMyStruct", "function", { start_row = 10, start_col = 0, end_row = 15, end_col = 1 }, true)
  M.add_child(root, new_struct)

  local s_var = M.make_node("s", "variable", { start_row = 11, start_col = 1, end_row = 11, end_col = 10 }, false)
  M.add_child(new_struct, s_var)

  -- HandleRequest method (scope)
  local handle_req = M.make_node("HandleRequest", "method", { start_row = 17, start_col = 0, end_row = 30, end_col = 1 }, true)
  M.add_child(root, handle_req)

  local if_block = M.make_node("if", "block", { start_row = 18, start_col = 1, end_row = 20, end_col = 2 }, true)
  M.add_child(handle_req, if_block)

  local for_block = M.make_node("for", "block", { start_row = 22, start_col = 1, end_row = 29, end_col = 2 }, true)
  M.add_child(handle_req, for_block)

  local nested_if = M.make_node("if", "block", { start_row = 23, start_col = 2, end_row = 26, end_col = 3 }, true)
  M.add_child(for_block, nested_if)

  return {
    root = root,
    source = "treesitter",
    bufnr = 0,
    lang = "go",
  }
end

--- Create a buffer with the contents of a fixture file.
--- @param fixture_path string
--- @return number bufnr
function M.load_fixture(fixture_path)
  local bufnr = vim.api.nvim_create_buf(false, true)
  local lines = vim.fn.readfile(fixture_path)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  return bufnr
end

return M
