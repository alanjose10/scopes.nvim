--- @class ScopeNode
--- @field name string
--- @field kind string
--- @field range {start_row: number, start_col: number, end_row: number, end_col: number}
--- @field children ScopeNode[]
--- @field parent ScopeNode|nil
--- @field is_error boolean
local ScopeNode = {}
ScopeNode.__index = ScopeNode

--- Validate that a range table has the required structure and logical consistency.
--- @param range table
--- @param label string -- context label for warning messages
--- @return boolean
local function validate_range(range, label)
  local valid = true
  if type(range) ~= "table" then
    vim.notify("scopes.nvim: " .. label .. ": range must be a table", vim.log.levels.WARN)
    return false
  end
  for _, key in ipairs({ "start_row", "start_col", "end_row", "end_col" }) do
    local v = range[key]
    if type(v) ~= "number" or v < 0 or v ~= math.floor(v) then
      vim.notify(
        "scopes.nvim: " .. label .. ": range." .. key .. " must be a non-negative integer",
        vim.log.levels.WARN
      )
      valid = false
    end
  end
  if valid then
    if range.start_row > range.end_row then
      vim.notify("scopes.nvim: " .. label .. ": start_row > end_row", vim.log.levels.WARN)
      valid = false
    elseif range.start_row == range.end_row and range.start_col > range.end_col then
      vim.notify("scopes.nvim: " .. label .. ": start_col > end_col on same row", vim.log.levels.WARN)
      valid = false
    end
  end
  return valid
end

--- Create a new ScopeNode.
--- @param opts {name: string, kind: string, range: table, children?: ScopeNode[], parent?: ScopeNode, is_error?: boolean}
--- @return ScopeNode
function ScopeNode.new(opts)
  -- TODO: revisit validation strategy (warn vs return nil vs error)
  if type(opts) ~= "table" then
    vim.notify("scopes.nvim: ScopeNode.new(): opts must be a table", vim.log.levels.WARN)
    opts = {}
  end
  if type(opts.name) ~= "string" then
    vim.notify("scopes.nvim: ScopeNode.new(): name must be a string", vim.log.levels.WARN)
  end
  if type(opts.kind) ~= "string" then
    vim.notify("scopes.nvim: ScopeNode.new(): kind must be a string", vim.log.levels.WARN)
  end
  validate_range(opts.range, "ScopeNode.new()")

  local self = setmetatable({}, ScopeNode)
  self.name = opts.name
  self.kind = opts.kind
  self.range = opts.range
  self.children = opts.children or {}
  self.parent = opts.parent or nil
  self.is_error = opts.is_error or false
  return self
end

--- Returns true if this node can be drilled into (has children).
--- @return boolean
function ScopeNode:is_scope()
  return #self.children > 0
end

--- Add a child node. Sets the child's parent back-reference.
--- Warns if the child's range is not fully contained within this node's range.
--- @param child ScopeNode
function ScopeNode:add_child(child)
  if self.range and child.range then
    local pr = self.range
    local cr = child.range
    local outside = false
    if cr.start_row < pr.start_row then
      outside = true
    elseif cr.end_row > pr.end_row then
      outside = true
    elseif cr.start_row == pr.start_row and cr.start_col < pr.start_col then
      outside = true
    elseif cr.end_row == pr.end_row and cr.end_col > pr.end_col then
      outside = true
    end
    if outside then
      vim.notify(
        "scopes.nvim: ScopeNode:add_child(): child '"
          .. (child.name or "?")
          .. "' range is outside parent '"
          .. (self.name or "?")
          .. "'",
        vim.log.levels.WARN
      )
    end
  end
  -- TODO: validate that the new child's range does not overlap any existing sibling.
  -- For siblings on different rows: ranges should be mutually exclusive (no row overlap).
  -- For siblings sharing the same start_row and end_row: column ranges should also be
  -- mutually exclusive. Consider emitting at DEBUG level rather than WARN to avoid noise
  -- from Treesitter ERROR nodes and certain LSP servers that return adjacent/touching ranges.
  child.parent = self
  table.insert(self.children, child)
end

--- @class ScopeTree
--- @field root ScopeNode
--- @field source "treesitter"|"lsp"
--- @field bufnr number
--- @field lang string
local ScopeTree = {}
ScopeTree.__index = ScopeTree

--- Create a new ScopeTree.
--- @param opts {root: ScopeNode, source: "treesitter"|"lsp", bufnr: number, lang: string}
--- @return ScopeTree
function ScopeTree.new(opts)
  -- TODO: revisit validation strategy (warn vs return nil vs error)
  if type(opts) ~= "table" then
    vim.notify("scopes.nvim: ScopeTree.new(): opts must be a table", vim.log.levels.WARN)
    opts = {}
  end
  if type(opts.root) ~= "table" then
    vim.notify("scopes.nvim: ScopeTree.new(): root must be a table", vim.log.levels.WARN)
  end
  if opts.source ~= "treesitter" and opts.source ~= "lsp" then
    vim.notify("scopes.nvim: ScopeTree.new(): source must be 'treesitter' or 'lsp'", vim.log.levels.WARN)
  end
  if type(opts.bufnr) ~= "number" then
    vim.notify("scopes.nvim: ScopeTree.new(): bufnr must be a number", vim.log.levels.WARN)
  end
  if type(opts.lang) ~= "string" then
    vim.notify("scopes.nvim: ScopeTree.new(): lang must be a string", vim.log.levels.WARN)
  end

  local self = setmetatable({}, ScopeTree)
  self.root = opts.root
  self.source = opts.source
  self.bufnr = opts.bufnr
  self.lang = opts.lang
  return self
end

local config = require("scopes.config")

-- Per-buffer cache: { [bufnr] = { tree = ScopeTree, timestamp = number } }
local _cache = {}

--- Check if a row falls within a range (inclusive on both ends).
--- @param range {start_row: number, end_row: number}
--- @param row number
--- @return boolean
local function row_in_range(range, row)
  return row >= range.start_row and row <= range.end_row
end

--- Recursively find the deepest scope node containing `row`.
--- Only descends into children that are scopes (is_scope() == true).
--- @param node ScopeNode
--- @param row number
--- @return ScopeNode|nil
local function find_deepest_scope_node(node, row)
  for _, child in ipairs(node.children) do
    if child:is_scope() and row_in_range(child.range, row) then
      local deeper = find_deepest_scope_node(child, row)
      return deeper or child
    end
  end
  return nil
end

--- Find the deepest scope in `scope_tree` that contains `row`.
--- Returns nil when no scope contains the row; callers fall back to root.
--- @param scope_tree ScopeTree
--- @param row number
--- @return ScopeNode|nil
local function find_scope_for_row(scope_tree, row)
  return find_deepest_scope_node(scope_tree.root, row)
end

--- Evict the cached tree for `bufnr`.
--- @param bufnr number
local function invalidate(bufnr)
  _cache[bufnr] = nil
end

--- Build a ScopeTree for `bufnr`, dispatching to the configured backend.
--- Returns a cached tree if one exists and was built within cache.debounce_ms.
--- @param bufnr number
--- @param opts? { backend?: string, lang_config?: table }
--- @return ScopeTree|nil
local function build(bufnr, opts)
  opts = opts or {}
  local cfg = config.get()

  if cfg.cache.enabled then
    local entry = _cache[bufnr]
    if entry and (vim.uv.now() - entry.timestamp) < cfg.cache.debounce_ms then
      return entry.tree
    end
  end

  local backend = opts.backend or cfg.backend
  local result = nil

  if backend == "treesitter" or backend == "auto" then
    local ok, ts = pcall(require, "scopes.backends.treesitter")
    if ok then
      result = ts.build(bufnr, opts.lang_config)
    end
  end

  if backend == "lsp" then
    vim.notify("scopes.nvim: LSP backend not yet implemented", vim.log.levels.WARN)
  end

  if result and cfg.cache.enabled then
    _cache[bufnr] = { tree = result, timestamp = vim.uv.now() }
  end

  return result
end

return {
  ScopeNode = ScopeNode,
  ScopeTree = ScopeTree,
  find_scope_for_row = find_scope_for_row,
  invalidate = invalidate,
  build = build,
}
