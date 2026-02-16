local tree = require("scopes.tree")
local ScopeNode = tree.ScopeNode
local ScopeTree = tree.ScopeTree

describe("ScopeNode", function()
  describe("new", function()
    it("sets all fields from opts", function()
      local node = ScopeNode.new({
        name = "HandleRequest",
        kind = "function",
        range = { start_row = 10, start_col = 0, end_row = 20, end_col = 1 },
        is_error = true,
      })
      assert.are.equal("HandleRequest", node.name)
      assert.are.equal("function", node.kind)
      assert.are.same({ start_row = 10, start_col = 0, end_row = 20, end_col = 1 }, node.range)
      assert.is_true(node.is_error)
    end)

    it("defaults children to empty table", function()
      local node = ScopeNode.new({
        name = "x",
        kind = "variable",
        range = { start_row = 0, start_col = 0, end_row = 0, end_col = 1 },
      })
      assert.are.same({}, node.children)
    end)

    it("defaults parent to nil", function()
      local node = ScopeNode.new({
        name = "x",
        kind = "variable",
        range = { start_row = 0, start_col = 0, end_row = 0, end_col = 1 },
      })
      assert.is_nil(node.parent)
    end)

    it("defaults is_error to false", function()
      local node = ScopeNode.new({
        name = "x",
        kind = "variable",
        range = { start_row = 0, start_col = 0, end_row = 0, end_col = 1 },
      })
      assert.is_false(node.is_error)
    end)
  end)

  describe("is_scope", function()
    it("returns false when node has no children", function()
      local node = ScopeNode.new({
        name = "x",
        kind = "variable",
        range = { start_row = 0, start_col = 0, end_row = 0, end_col = 1 },
      })
      assert.is_false(node:is_scope())
    end)

    it("returns true when node has children", function()
      local parent = ScopeNode.new({
        name = "root",
        kind = "function",
        range = { start_row = 0, start_col = 0, end_row = 10, end_col = 0 },
      })
      local child = ScopeNode.new({
        name = "x",
        kind = "variable",
        range = { start_row = 1, start_col = 0, end_row = 1, end_col = 5 },
      })
      parent:add_child(child)
      assert.is_true(parent:is_scope())
    end)
  end)

  describe("add_child", function()
    it("appends child to children list", function()
      local parent = ScopeNode.new({
        name = "root",
        kind = "function",
        range = { start_row = 0, start_col = 0, end_row = 10, end_col = 0 },
      })
      local child = ScopeNode.new({
        name = "x",
        kind = "variable",
        range = { start_row = 1, start_col = 0, end_row = 1, end_col = 5 },
      })
      parent:add_child(child)
      assert.are.equal(1, #parent.children)
      assert.are.equal(child, parent.children[1])
    end)

    it("sets parent back-reference on child", function()
      local parent = ScopeNode.new({
        name = "root",
        kind = "function",
        range = { start_row = 0, start_col = 0, end_row = 10, end_col = 0 },
      })
      local child = ScopeNode.new({
        name = "x",
        kind = "variable",
        range = { start_row = 1, start_col = 0, end_row = 1, end_col = 5 },
      })
      parent:add_child(child)
      assert.are.equal(parent, child.parent)
    end)

    it("maintains order with multiple children", function()
      local parent = ScopeNode.new({
        name = "root",
        kind = "function",
        range = { start_row = 0, start_col = 0, end_row = 10, end_col = 0 },
      })
      local a = ScopeNode.new({
        name = "a",
        kind = "variable",
        range = { start_row = 1, start_col = 0, end_row = 1, end_col = 1 },
      })
      local b = ScopeNode.new({
        name = "b",
        kind = "variable",
        range = { start_row = 2, start_col = 0, end_row = 2, end_col = 1 },
      })
      local c = ScopeNode.new({
        name = "c",
        kind = "variable",
        range = { start_row = 3, start_col = 0, end_row = 3, end_col = 1 },
      })
      parent:add_child(a)
      parent:add_child(b)
      parent:add_child(c)
      assert.are.equal(3, #parent.children)
      assert.are.equal("a", parent.children[1].name)
      assert.are.equal("b", parent.children[2].name)
      assert.are.equal("c", parent.children[3].name)
    end)

    it("sets grandchild parent to child, not root", function()
      local root = ScopeNode.new({
        name = "root",
        kind = "function",
        range = { start_row = 0, start_col = 0, end_row = 20, end_col = 0 },
      })
      local child = ScopeNode.new({
        name = "child",
        kind = "function",
        range = { start_row = 1, start_col = 0, end_row = 10, end_col = 0 },
      })
      local grandchild = ScopeNode.new({
        name = "grandchild",
        kind = "variable",
        range = { start_row = 2, start_col = 0, end_row = 2, end_col = 5 },
      })
      root:add_child(child)
      child:add_child(grandchild)
      assert.are.equal(child, grandchild.parent)
      assert.are_not.equal(root, grandchild.parent)
    end)
  end)
end)

describe("ScopeTree", function()
  describe("new", function()
    it("sets all fields from opts", function()
      local root = ScopeNode.new({
        name = "file",
        kind = "module",
        range = { start_row = 0, start_col = 0, end_row = 100, end_col = 0 },
      })
      local st = ScopeTree.new({ root = root, source = "treesitter", bufnr = 1, lang = "go" })
      assert.are.equal(root, st.root)
      assert.are.equal("treesitter", st.source)
      assert.are.equal(1, st.bufnr)
      assert.are.equal("go", st.lang)
    end)

    it("root is accessible as a ScopeNode", function()
      local root = ScopeNode.new({
        name = "file",
        kind = "module",
        range = { start_row = 0, start_col = 0, end_row = 50, end_col = 0 },
      })
      local st = ScopeTree.new({ root = root, source = "lsp", bufnr = 2, lang = "lua" })
      assert.are.equal("file", st.root.name)
      assert.are.equal("module", st.root.kind)
      assert.are.same({}, st.root.children)
    end)
  end)
end)
