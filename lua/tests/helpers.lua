--- Shared test helpers for scopes.nvim tests.
--- Require as: local helpers = require("tests.helpers")

local M = {}

--- Recursively find all ScopeNodes with a given name.
--- @param node ScopeNode
--- @param name string
--- @return ScopeNode[]
function M.find_by_name(node, name)
  local found = {}
  if node.name == name then
    table.insert(found, node)
  end
  for _, child in ipairs(node.children) do
    for _, match in ipairs(M.find_by_name(child, name)) do
      table.insert(found, match)
    end
  end
  return found
end

--- Collect names of a ScopeNode's direct children.
--- @param node ScopeNode
--- @return string[]
function M.child_names(node)
  local names = {}
  for _, child in ipairs(node.children) do
    table.insert(names, child.name)
  end
  return names
end

--- Recursively assert that parent back-references are correct.
--- @param node ScopeNode
--- @param expected_parent ScopeNode|nil
function M.check_parents(node, expected_parent)
  assert.are.equal(expected_parent, node.parent, "parent mismatch for node '" .. node.name .. "'")
  for _, child in ipairs(node.children) do
    M.check_parents(child, node)
  end
end

--- Recursively assert that all ranges are valid (start <= end).
--- @param node ScopeNode
function M.check_ranges(node)
  local r = node.range
  assert.is_truthy(r, "node '" .. node.name .. "' has no range")
  local ok = r.start_row < r.end_row or (r.start_row == r.end_row and r.start_col <= r.end_col)
  assert.is_true(ok, "invalid range for node '" .. node.name .. "'")
  for _, child in ipairs(node.children) do
    M.check_ranges(child)
  end
end

--- Recursively find all Treesitter nodes of a given type.
--- @param root TSNode
--- @param node_type string
--- @return TSNode[]
function M.find_ts_nodes(root, node_type)
  local found = {}
  local function walk(node)
    if node:type() == node_type then
      table.insert(found, node)
    end
    for child in node:iter_children() do
      walk(child)
    end
  end
  walk(root)
  return found
end

--- Create a scratch buffer loaded with a fixture file and a live TS parser.
--- The caller is responsible for calling helpers.delete_buf(bufnr) in after_each.
--- @param fixture_path string  e.g. "tests/fixtures/sample.go"
--- @param lang string          e.g. "go"
--- @return number  bufnr
function M.make_buf(fixture_path, lang)
  local bufnr = vim.api.nvim_create_buf(false, true)
  local lines = vim.fn.readfile(fixture_path)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_set_option_value("filetype", lang, { buf = bufnr })
  vim.treesitter.start(bufnr, lang)
  vim.treesitter.get_parser(bufnr, lang):parse()
  return bufnr
end

--- Safely delete a scratch buffer. No-op if bufnr is nil or already invalid.
--- @param bufnr number|nil
function M.delete_buf(bufnr)
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end
end

--- Create a scratch buffer from a code string and return the TS root and bufnr.
--- The caller must delete the buffer via helpers.delete_buf(bufnr).
---
--- Usage:
---   local root, bufnr = helpers.parse_code("package main\n", "go")
---
--- To keep the outer bufnr variable updated (for shared after_each cleanup),
--- define a thin wrapper in the spec file:
---   local function parse_go(code)
---     local root
---     root, bufnr = helpers.parse_code(code, "go")
---     return root
---   end
---
--- @param code string
--- @param lang string
--- @return TSNode, number  root, bufnr
function M.parse_code(code, lang)
  local bufnr = vim.api.nvim_create_buf(false, true)
  local lines = vim.split(code, "\n")
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_set_option_value("filetype", lang, { buf = bufnr })
  vim.treesitter.start(bufnr, lang)
  local parser = vim.treesitter.get_parser(bufnr, lang)
  parser:parse()
  local root = parser:parse()[1]:root()
  return root, bufnr
end

--- Replace vim.notify with a WARN-capture stub.
--- Returns the captured warnings table and a restore function.
---
--- Usage in before_each / after_each:
---   local warnings, restore_notify
---   before_each(function() warnings, restore_notify = helpers.capture_notify() end)
---   after_each(function() restore_notify() end)
---
--- Usage inline within a single test:
---   local warnings, restore = helpers.capture_notify()
---   -- ... call code that may warn ...
---   restore()
---
--- @return string[], fun(), fun()
function M.capture_notify()
  local warnings = {}
  local orig = vim.notify
  vim.notify = function(msg, level)
    if level == vim.log.levels.WARN then
      table.insert(warnings, msg)
    end
  end
  local function clear()
    for i = #warnings, 1, -1 do
      warnings[i] = nil
    end
  end
  return warnings, function()
    vim.notify = orig
  end, clear
end

--- Assert language-agnostic structural invariants on a built LangConfig.
--- Replaces the repeated "structural checks" describe block in language spec files.
--- @param cfg LangConfig
function M.assert_valid_lang_config(cfg)
  assert.is_true(#cfg.scope_types > 0, "scope_types is empty")
  assert.is_true(#cfg.symbol_types > 0, "symbol_types is empty")
  assert.are.equal("function", type(cfg.get_name), "get_name is not a function")
  for _, st in ipairs(cfg.scope_types) do
    assert.are.equal("string", type(st), "scope_types entry is not a string: " .. tostring(st))
  end
  for _, st in ipairs(cfg.symbol_types) do
    assert.are.equal("string", type(st), "symbol_types entry is not a string: " .. tostring(st))
  end
  for _, st in ipairs(cfg.scope_types) do
    assert.is_false(
      vim.tbl_contains(cfg.symbol_types, st),
      st .. " is in both scope_types and symbol_types"
    )
  end
end

return M
