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

return {
  ScopeNode = ScopeNode,
  ScopeTree = ScopeTree,
}
