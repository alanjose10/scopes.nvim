--- Treesitter backend for scopes.nvim
--- Walks a buffer's Treesitter parse tree using language configs
--- and produces a ScopeTree.

local tree_mod = require("scopes.tree")
local ScopeNode = tree_mod.ScopeNode
local ScopeTree = tree_mod.ScopeTree

local M = {}

--- Convert a list of strings to a lookup set for O(1) checks.
--- @param list string[]
--- @return table<string, boolean>
local function to_set(list)
  local set = {}
  for _, v in ipairs(list) do
    set[v] = true
  end
  return set
end

--- Extract range from a Treesitter node.
--- @param ts_node TSNode
--- @return {start_row: number, start_col: number, end_row: number, end_col: number}
local function get_range(ts_node)
  local start_row, start_col, end_row, end_col = ts_node:range()
  return {
    start_row = start_row,
    start_col = start_col,
    end_row = end_row,
    end_col = end_col,
  }
end

--- Recursively walk the Treesitter tree and build ScopeNodes.
--- @param ts_node TSNode
--- @param parent_scope ScopeNode
--- @param scope_set table<string, boolean>
--- @param symbol_set table<string, boolean>
--- @param lang_config LangConfig
--- @param bufnr number
local function walk(ts_node, parent_scope, scope_set, symbol_set, lang_config, bufnr)
  for child in ts_node:iter_children() do
    local child_type = child:type()

    -- TODO: Need to handle case where a node may or may not be scoped (like nested structs in go)
    if child_type == "ERROR" then
      local error_node = ScopeNode.new({
        name = "[error]",
        kind = "block",
        range = get_range(child),
        is_error = true,
      })
      parent_scope:add_child(error_node)
      walk(child, error_node, scope_set, symbol_set, lang_config, bufnr)
    elseif scope_set[child_type] then
      local scope_node = ScopeNode.new({
        name = lang_config.get_name(child, bufnr),
        kind = lang_config.kind_map and lang_config.kind_map[child_type] or child_type,
        range = get_range(child),
      })
      parent_scope:add_child(scope_node)
      walk(child, scope_node, scope_set, symbol_set, lang_config, bufnr)
    elseif symbol_set[child_type] then
      local symbol_node = ScopeNode.new({
        name = lang_config.get_name(child, bufnr),
        kind = lang_config.kind_map and lang_config.kind_map[child_type] or child_type,
        range = get_range(child),
      })
      parent_scope:add_child(symbol_node)
    else
      -- Transparent pass-through: recurse without creating a node
      walk(child, parent_scope, scope_set, symbol_set, lang_config, bufnr)
    end
  end
end

--- Build a ScopeTree from a buffer's Treesitter parse tree.
--- @param bufnr number
--- @param lang_config? LangConfig Optional language config override. If nil, auto-detected from parser language.
--- @return ScopeTree|nil
function M.build(bufnr, lang_config)
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
  if not ok or not parser then
    vim.notify("scopes.nvim: no treesitter parser for buffer " .. bufnr, vim.log.levels.WARN)
    return nil
  end

  local lang = parser:lang()

  if not lang_config then
    local config_ok, config = pcall(require, "scopes.languages." .. lang)
    if not config_ok then
      vim.notify("scopes.nvim: no language config for '" .. lang .. "'", vim.log.levels.WARN)
      -- TODO: implement generic fallback heuristics for unsupported languages
      return nil
    end
    lang_config = config
  end

  local parse_ok, trees = pcall(parser.parse, parser)
  if not parse_ok or not trees or not trees[1] then
    vim.notify("scopes.nvim: treesitter parse failed for buffer " .. bufnr, vim.log.levels.WARN)
    return nil
  end

  local ts_root = trees[1]:root()

  -- Get buffer name for root node display
  local buf_name = vim.api.nvim_buf_get_name(bufnr)
  local file_name = vim.fn.fnamemodify(buf_name, ":t")
  if file_name == "" then
    file_name = "[unnamed]"
  end

  local root = ScopeNode.new({
    name = file_name,
    kind = "module",
    range = get_range(ts_root),
  })

  local scope_set = to_set(lang_config.scope_types)
  local symbol_set = to_set(lang_config.symbol_types)

  walk(ts_root, root, scope_set, symbol_set, lang_config, bufnr)

  return ScopeTree.new({
    root = root,
    source = "treesitter",
    bufnr = bufnr,
    lang = lang,
  })
end

return M
