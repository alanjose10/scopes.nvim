local tree_mod = require("scopes.tree")

--- @class Navigator
--- @field _tree       ScopeTree
--- @field _current    ScopeNode
--- @field _breadcrumb ScopeNode[]
local Navigator = {}
Navigator.__index = Navigator

--- Create a new Navigator initialised at the tree root.
--- @param scope_tree ScopeTree
--- @param opts? {cursor_row?: number}
--- @return Navigator
function Navigator.new(scope_tree, opts)
  local self = setmetatable({}, Navigator)
  self._tree = scope_tree
  self._current = scope_tree.root
  self._breadcrumb = { scope_tree.root }
  if opts and opts.cursor_row then
    self:open_at_cursor(opts.cursor_row)
  end
  return self
end

--- Return the current node (the node whose children are currently shown).
--- @return ScopeNode
function Navigator:current()
  return self._current
end

--- Return the children of the current node.
--- @return ScopeNode[]
function Navigator:items()
  return self._current.children
end

--- Drill down into a scope node. No-op if the node is a leaf.
--- @param node ScopeNode
--- @return boolean  true if drilled, false if node is a leaf
function Navigator:drill_down(node)
  if not node:is_scope() then
    return false
  end
  table.insert(self._breadcrumb, node)
  self._current = node
  return true
end

--- Move up to the parent scope. No-op if already at root.
--- @return boolean  true if moved up, false if already at root
function Navigator:go_up()
  if self._current == self._tree.root then
    return false
  end
  table.remove(self._breadcrumb)
  self._current = self._breadcrumb[#self._breadcrumb]
  return true
end

--- Return the start position of a node (for cursor jumping).
--- @param node ScopeNode
--- @return {row: number, col: number}
function Navigator:enter(node)
  return { row = node.range.start_row, col = node.range.start_col }
end

--- Return the breadcrumb path as a " > " separated string.
--- @return string
function Navigator:breadcrumb_string()
  local parts = {}
  for _, node in ipairs(self._breadcrumb) do
    table.insert(parts, node.name)
  end
  return table.concat(parts, " > ")
end

--- Navigate to the deepest scope containing `row`.
--- Rebuilds _current and _breadcrumb via parent pointers.
--- Falls back to root when no scope contains the row.
--- @param row number
function Navigator:open_at_cursor(row)
  local target = tree_mod.find_scope_for_row(self._tree, row)
  if not target then
    self._current = self._tree.root
    self._breadcrumb = { self._tree.root }
    return
  end
  -- Walk parent chain to reconstruct the full path from root to target.
  local path = {}
  local node = target
  while node do
    table.insert(path, 1, node)
    node = node.parent
  end
  self._breadcrumb = path
  self._current = target
end

return Navigator
