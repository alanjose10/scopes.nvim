--- Treesitter backend for building ScopeTree from buffer parse trees.

local M = {}

--- @class ScopeNode
--- @field name string
--- @field kind string
--- @field range {start_row: number, start_col: number, end_row: number, end_col: number}
--- @field children ScopeNode[]
--- @field parent ScopeNode|nil
--- @field is_scope boolean
--- @field is_error boolean

--- @class ScopeTree
--- @field root ScopeNode
--- @field source "treesitter"|"lsp"
--- @field bufnr number
--- @field lang string

--- Known language configs by filetype.
--- @type table<string, scopes.LangConfig>
local lang_configs = {}

--- Load a language config, with caching.
--- @param lang string
--- @return scopes.LangConfig|nil
local function get_lang_config(lang)
  if lang_configs[lang] then
    return lang_configs[lang]
  end

  local ok, lang_mod = pcall(require, "scopes.languages." .. lang)
  if ok and lang_mod then
    lang_configs[lang] = lang_mod
    return lang_mod
  end

  return nil
end

--- Create a new ScopeNode.
--- @param name string
--- @param kind string
--- @param range {start_row: number, start_col: number, end_row: number, end_col: number}
--- @param is_scope boolean
--- @param is_error boolean
--- @return ScopeNode
local function make_node(name, kind, range, is_scope, is_error)
  return {
    name = name,
    kind = kind,
    range = range,
    children = {},
    parent = nil,
    is_scope = is_scope,
    is_error = is_error,
  }
end

--- Build a lookup set from a list of strings.
--- @param list string[]
--- @return table<string, boolean>
local function to_set(list)
  local set = {}
  for _, v in ipairs(list) do
    set[v] = true
  end
  return set
end

--- Recursively walk a Treesitter node and build ScopeNode tree.
--- @param ts_node any TSNode
--- @param parent_scope ScopeNode
--- @param lang_config scopes.LangConfig
--- @param source number bufnr
--- @param scope_set table<string, boolean>
--- @param symbol_set table<string, boolean>
local function walk_node(ts_node, parent_scope, lang_config, source, scope_set, symbol_set)
  for child in ts_node:iter_children() do
    local child_type = child:type()
    local start_row, start_col, end_row, end_col = child:range()
    local range = {
      start_row = start_row,
      start_col = start_col,
      end_row = end_row,
      end_col = end_col,
    }

    if child_type == "ERROR" then
      -- Include ERROR nodes with a flag
      local node = make_node("<error>", "error", range, false, true)
      node.parent = parent_scope
      table.insert(parent_scope.children, node)
      -- Still recurse into ERROR nodes to find valid children
      walk_node(child, parent_scope, lang_config, source, scope_set, symbol_set)
    elseif scope_set[child_type] then
      -- This is a scope node — container that can be drilled into
      local name = lang_config.get_name(child, source)
      local kind = lang_config.kind_map and lang_config.kind_map[child_type] or child_type
      local node = make_node(name, kind, range, true, false)
      node.parent = parent_scope
      table.insert(parent_scope.children, node)
      -- Recurse into scope node to find nested scopes/symbols
      walk_node(child, node, lang_config, source, scope_set, symbol_set)
    elseif symbol_set[child_type] then
      -- This is a symbol node — leaf item within a scope
      local name = lang_config.get_name(child, source)
      local kind = lang_config.kind_map and lang_config.kind_map[child_type] or child_type
      local node = make_node(name, kind, range, false, false)
      node.parent = parent_scope
      table.insert(parent_scope.children, node)
      -- Symbols can still contain scopes (e.g., variable holding a function literal)
      walk_node(child, node, lang_config, source, scope_set, symbol_set)
    else
      -- Not a scope or symbol — recurse through it transparently
      walk_node(child, parent_scope, lang_config, source, scope_set, symbol_set)
    end
  end
end

--- Build a ScopeTree from a buffer using Treesitter.
--- @param bufnr number
--- @param lang_config? scopes.LangConfig explicit language config (overrides auto-detection)
--- @return ScopeTree|nil tree
--- @return string|nil error
function M.build(bufnr, lang_config)
  local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })

  -- Determine language for Treesitter
  local lang = vim.treesitter.language.get_lang(ft) or ft

  -- Try to get parser
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, lang)
  if not ok or not parser then
    return nil, "no treesitter parser for " .. lang
  end

  -- Get or auto-detect language config
  if not lang_config then
    lang_config = get_lang_config(ft)
    if not lang_config then
      return nil, "no language config for " .. ft
    end
  end

  -- Parse the buffer
  local trees = parser:parse()
  if not trees or #trees == 0 then
    return nil, "treesitter parse returned no trees"
  end

  local tree = trees[1]
  local root_ts = tree:root()

  -- Create virtual root node representing file-level scope
  local start_row, start_col, end_row, end_col = root_ts:range()
  local root = make_node("<root>", "file", {
    start_row = start_row,
    start_col = start_col,
    end_row = end_row,
    end_col = end_col,
  }, true, false)

  -- Build lookup sets for efficient type checking
  local scope_set = to_set(lang_config.scope_types)
  local symbol_set = to_set(lang_config.symbol_types)

  -- Walk the tree
  walk_node(root_ts, root, lang_config, bufnr, scope_set, symbol_set)

  return {
    root = root,
    source = "treesitter",
    bufnr = bufnr,
    lang = lang,
  }, nil
end

return M
