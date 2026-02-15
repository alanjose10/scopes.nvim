--- Navigator — state machine over a ScopeTree.
--- Tracks current node, breadcrumb path, and provides drill/up/enter operations.
--- UI-agnostic: knows nothing about pickers.

--- @class scopes.Navigator
--- @field tree ScopeTree
--- @field current_node ScopeNode
--- @field breadcrumb ScopeNode[]
--- @field _original_cursor {row: number, col: number}|nil
local Navigator = {}
Navigator.__index = Navigator

--- Create a new Navigator.
--- @param scope_tree ScopeTree
--- @param opts? { cursor_row?: number }
--- @return scopes.Navigator
function Navigator:new(scope_tree, opts)
  opts = opts or {}
  local self = setmetatable({}, Navigator)
  self.tree = scope_tree
  self.current_node = scope_tree.root
  self.breadcrumb = {}
  self._original_cursor = nil

  -- If cursor_row is given, open at the deepest scope containing that row
  if opts.cursor_row then
    self:open_at_cursor(opts.cursor_row)
  end

  return self
end

--- Return the list of children of the current node (items for picker display).
--- @return ScopeNode[]
function Navigator:items()
  return self.current_node.children
end

--- Drill down into a child scope node.
--- Sets current_node to the given child, updates breadcrumb.
--- Returns false if the node is not a scope (can't be drilled into).
--- @param node ScopeNode
--- @return boolean success
function Navigator:drill_down(node)
  if not node or not node.is_scope then
    return false
  end

  -- Verify this node is a child of current_node
  local found = false
  for _, child in ipairs(self.current_node.children) do
    if child == node then
      found = true
      break
    end
  end

  if not found then
    return false
  end

  table.insert(self.breadcrumb, self.current_node)
  self.current_node = node
  return true
end

--- Move current node to parent. No-op at root.
--- @return boolean success true if we moved up, false if already at root
function Navigator:go_up()
  if #self.breadcrumb == 0 then
    return false
  end

  self.current_node = table.remove(self.breadcrumb)
  return true
end

--- Return the target buffer position for jumping to a node.
--- @param node ScopeNode
--- @return {row: number, col: number}|nil
function Navigator:enter(node)
  if not node or not node.range then
    return nil
  end

  return {
    row = node.range.start_row,
    col = node.range.start_col,
  }
end

--- Return a formatted breadcrumb string reflecting the current path.
--- e.g., "file.go > MyStruct > HandleRequest"
--- @param filename? string optional filename to prepend
--- @return string
function Navigator:breadcrumb_string(filename)
  local parts = {}

  if filename then
    table.insert(parts, filename)
  end

  for _, node in ipairs(self.breadcrumb) do
    if node.name ~= "<root>" then
      table.insert(parts, node.name)
    end
  end

  if self.current_node.name ~= "<root>" then
    table.insert(parts, self.current_node.name)
  end

  return table.concat(parts, " > ")
end

--- Find the deepest scope containing the given row and navigate to it.
--- Sets current_node and breadcrumb accordingly.
--- @param row number 0-indexed row number
function Navigator:open_at_cursor(row)
  local path = {}
  self:_find_deepest_scope(self.tree.root, row, path)

  if #path > 0 then
    -- path contains [root, ..., deepest_scope]
    -- breadcrumb is everything except the last entry (current)
    self.breadcrumb = {}
    for i = 1, #path - 1 do
      table.insert(self.breadcrumb, path[i])
    end
    self.current_node = path[#path]
  else
    -- No scope found at cursor, stay at root
    self.current_node = self.tree.root
    self.breadcrumb = {}
  end
end

--- Recursively find the deepest scope containing the given row.
--- @param node ScopeNode
--- @param row number
--- @param path ScopeNode[]
--- @return boolean found
function Navigator:_find_deepest_scope(node, row, path)
  -- Check if this node contains the row
  if node.range then
    if row < node.range.start_row or row > node.range.end_row then
      return false
    end
  end

  table.insert(path, node)

  -- Try to find a deeper scope among children
  for _, child in ipairs(node.children) do
    if child.is_scope and child.range then
      if row >= child.range.start_row and row <= child.range.end_row then
        if self:_find_deepest_scope(child, row, path) then
          return true
        end
      end
    end
  end

  -- This node is the deepest scope containing the row
  -- Only count it if it's a scope node (or root)
  if node.is_scope then
    return true
  end

  -- Not a scope, remove from path
  table.remove(path)
  return false
end

return Navigator
