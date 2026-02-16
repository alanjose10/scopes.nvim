--- @class ScopeNode
--- @field name string
--- @field kind string
--- @field range {start_row: number, start_col: number, end_row: number, end_col: number}
--- @field children ScopeNode[]
--- @field parent ScopeNode|nil
--- @field is_error boolean
local ScopeNode = {}
ScopeNode.__index = ScopeNode

--- Create a new ScopeNode.
--- @param opts {name: string, kind: string, range: table, children?: ScopeNode[], parent?: ScopeNode, is_error?: boolean}
--- @return ScopeNode
function ScopeNode.new(opts)
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
--- @param child ScopeNode
function ScopeNode:add_child(child)
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
