--- Shared test utilities for scopes.nvim specs.

local M = {}

--- Capture vim.notify calls during a test.
--- Returns three values:
---   warnings  — array of message strings received
---   restore   — call to restore the original vim.notify
---   clear     — call to empty the warnings array in-place
--- @return table, function, function
function M.capture_notify()
  local original = vim.notify
  local warnings = {}
  vim.notify = function(msg, _level)
    table.insert(warnings, msg)
  end
  local function restore()
    vim.notify = original
  end
  local function clear()
    for i = #warnings, 1, -1 do
      table.remove(warnings, i)
    end
  end
  return warnings, restore, clear
end

--- Create a scratch buffer, load a fixture file into it, set its filetype,
--- and start the Treesitter parser for that language.
--- @param fixture_path string  path relative to cwd (e.g. "tests/fixtures/sample.go")
--- @param lang string          language identifier (e.g. "go", "lua")
--- @return number bufnr
function M.make_buf(fixture_path, lang)
  local bufnr = vim.api.nvim_create_buf(false, true)
  local lines = vim.fn.readfile(fixture_path)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_set_option_value("filetype", lang, { buf = bufnr })
  vim.treesitter.start(bufnr, lang)
  return bufnr
end

--- Parse a raw code string into a buffer and return the Treesitter root node.
--- @param code string  source code
--- @param lang string  language identifier
--- @return TSNode root, number bufnr
function M.parse_code(code, lang)
  local bufnr = vim.api.nvim_create_buf(false, true)
  local lines = vim.split(code, "\n", { plain = true })
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_set_option_value("filetype", lang, { buf = bufnr })
  vim.treesitter.start(bufnr, lang)
  local parser = vim.treesitter.get_parser(bufnr, lang)
  local tree = parser:parse()[1]
  return tree:root(), bufnr
end

--- Delete a scratch buffer created by make_buf / parse_code.
--- @param bufnr number
function M.delete_buf(bufnr)
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end
end

--- Return a list of direct children's names from a ScopeNode.
--- @param node ScopeNode
--- @return string[]
function M.child_names(node)
  local names = {}
  for _, child in ipairs(node.children) do
    table.insert(names, child.name)
  end
  return names
end

--- Recursively find all ScopeNodes whose name equals `name`.
--- @param node ScopeNode  root to search from (inclusive)
--- @param name string
--- @return ScopeNode[]
function M.find_by_name(node, name)
  local results = {}
  if node.name == name then
    table.insert(results, node)
  end
  for _, child in ipairs(node.children) do
    for _, found in ipairs(M.find_by_name(child, name)) do
      table.insert(results, found)
    end
  end
  return results
end

--- Assert that every node's parent back-reference is correct.
--- Call for each direct child of root, passing the expected parent.
--- Recurses into grandchildren automatically.
--- @param node ScopeNode
--- @param expected_parent ScopeNode
function M.check_parents(node, expected_parent)
  assert.are.equal(expected_parent, node.parent, "wrong parent on node '" .. (node.name or "?") .. "'")
  for _, child in ipairs(node.children) do
    M.check_parents(child, node)
  end
end

--- Assert that every node in the subtree has a structurally valid range.
--- @param node ScopeNode
function M.check_ranges(node)
  local r = node.range
  assert.is_not_nil(r, "range is nil on node '" .. (node.name or "?") .. "'")
  assert.are.equal("number", type(r.start_row), "start_row not a number on '" .. (node.name or "?") .. "'")
  assert.are.equal("number", type(r.start_col), "start_col not a number on '" .. (node.name or "?") .. "'")
  assert.are.equal("number", type(r.end_row), "end_row not a number on '" .. (node.name or "?") .. "'")
  assert.are.equal("number", type(r.end_col), "end_col not a number on '" .. (node.name or "?") .. "'")
  assert.is_true(r.start_row <= r.end_row, "start_row > end_row on node '" .. (node.name or "?") .. "'")
  for _, child in ipairs(node.children) do
    M.check_ranges(child)
  end
end

--- Recursively find all Treesitter nodes of a given type.
--- @param root TSNode  Treesitter node to search from
--- @param node_type string
--- @return TSNode[]
function M.find_ts_nodes(root, node_type)
  local results = {}
  local function walk(node)
    if node:type() == node_type then
      table.insert(results, node)
    end
    for child in node:iter_children() do
      walk(child)
    end
  end
  walk(root)
  return results
end

--- Valid kind strings for all built-in language configs.
M.valid_kinds = {
  ["function"] = true,
  ["method"] = true,
  ["variable"] = true,
  ["type"] = true,
  ["const"] = true,
  ["block"] = true,
  ["class"] = true,
}

--- Assert structural invariants of a fully-built LangConfig.
--- @param cfg LangConfig
function M.assert_valid_lang_config(cfg)
  assert.are.equal("table", type(cfg.node_types), "node_types must be a table")
  assert.are.equal("table", type(cfg.scope_types), "scope_types must be a table")
  assert.are.equal("table", type(cfg.symbol_types), "symbol_types must be a table")
  assert.are.equal("table", type(cfg.kind_map), "kind_map must be a table")
  assert.are.equal("function", type(cfg.get_name), "get_name must be a function")

  -- Every entry in node_types has required fields with correct types
  for node_type, info in pairs(cfg.node_types) do
    assert.are.equal("string", type(info.kind), "kind missing or not string for " .. node_type)
    assert.are.equal("boolean", type(info.is_scope), "is_scope missing or not boolean for " .. node_type)
    assert.is_true(M.valid_kinds[info.kind], "invalid kind '" .. info.kind .. "' for node type '" .. node_type .. "'")
  end

  -- scope_types and symbol_types must not overlap
  for _, st in ipairs(cfg.scope_types) do
    assert.is_false(
      vim.tbl_contains(cfg.symbol_types, st),
      st .. " appears in both scope_types and symbol_types"
    )
  end

  -- kind_map entries must all be valid kind strings
  for node_type, kind in pairs(cfg.kind_map) do
    assert.is_true(M.valid_kinds[kind], "invalid kind '" .. kind .. "' in kind_map for node type '" .. node_type .. "'")
  end
end

return M
