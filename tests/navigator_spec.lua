--- Tests for lua/scopes/navigator.lua
--- Navigator tests must NOT depend on Treesitter.
--- All trees are built by hand using ScopeNode/ScopeTree directly.

local tree_mod = require("scopes.tree")
local ScopeNode = tree_mod.ScopeNode
local ScopeTree = tree_mod.ScopeTree
local Navigator = require("scopes.navigator")

--- Build a small deterministic test tree:
---
---   root "sample.go" (rows 0-99)
---   ├── HandleRequest  function (rows 5-30)
---   │   ├── req        variable (rows 6-6)   ← leaf
---   │   └── Validate   function (rows 10-20)  ← scope
---   │       └── err    variable (rows 11-11)  ← leaf
---   └── main           function (rows 40-60)  ← scope
---       └── x          variable (rows 41-41)  ← leaf
---
--- @return ScopeTree, table  tree and named node references
local function make_test_tree()
  local root = ScopeNode.new({
    name = "sample.go",
    kind = "module",
    range = { start_row = 0, start_col = 0, end_row = 99, end_col = 0 },
  })

  local handle = ScopeNode.new({
    name = "HandleRequest",
    kind = "function",
    range = { start_row = 5, start_col = 0, end_row = 30, end_col = 1 },
  })

  local req = ScopeNode.new({
    name = "req",
    kind = "variable",
    range = { start_row = 6, start_col = 2, end_row = 6, end_col = 10 },
  })

  local validate = ScopeNode.new({
    name = "Validate",
    kind = "function",
    range = { start_row = 10, start_col = 2, end_row = 20, end_col = 3 },
  })

  local err = ScopeNode.new({
    name = "err",
    kind = "variable",
    range = { start_row = 11, start_col = 4, end_row = 11, end_col = 7 },
  })

  local main_fn = ScopeNode.new({
    name = "main",
    kind = "function",
    range = { start_row = 40, start_col = 0, end_row = 60, end_col = 1 },
  })

  local x = ScopeNode.new({
    name = "x",
    kind = "variable",
    range = { start_row = 41, start_col = 2, end_row = 41, end_col = 3 },
  })

  root:add_child(handle)
  handle:add_child(req)
  handle:add_child(validate)
  validate:add_child(err)
  root:add_child(main_fn)
  main_fn:add_child(x)

  local scope_tree = ScopeTree.new({
    root = root,
    source = "treesitter",
    bufnr = 1,
    lang = "go",
  })

  return scope_tree, {
    root = root,
    handle = handle,
    req = req,
    validate = validate,
    err = err,
    main_fn = main_fn,
    x = x,
  }
end

describe("Navigator", function()
  describe("new", function()
    it("initializes current node to tree root", function()
      local scope_tree, nodes = make_test_tree()
      local nav = Navigator.new(scope_tree)
      assert.are.equal(nodes.root, nav:current())
    end)

    it("items() returns root's direct children by default", function()
      local scope_tree, nodes = make_test_tree()
      local nav = Navigator.new(scope_tree)
      local items = nav:items()
      assert.are.equal(2, #items)
      assert.are.equal(nodes.handle, items[1])
      assert.are.equal(nodes.main_fn, items[2])
    end)

    it("breadcrumb_string() starts with just the root name", function()
      local scope_tree = make_test_tree()
      local nav = Navigator.new(scope_tree)
      assert.are.equal("sample.go", nav:breadcrumb_string())
    end)

    it("accepts opts.cursor_row and navigates to that scope", function()
      local scope_tree, nodes = make_test_tree()
      -- row 15 is inside Validate (rows 10-20), which is inside HandleRequest
      local nav = Navigator.new(scope_tree, { cursor_row = 15 })
      assert.are.equal(nodes.validate, nav:current())
    end)
  end)

  describe("drill_down", function()
    it("sets current to the given scope node", function()
      local scope_tree, nodes = make_test_tree()
      local nav = Navigator.new(scope_tree)
      nav:drill_down(nodes.handle)
      assert.are.equal(nodes.handle, nav:current())
    end)

    it("items() returns the drilled node's children", function()
      local scope_tree, nodes = make_test_tree()
      local nav = Navigator.new(scope_tree)
      nav:drill_down(nodes.handle)
      local items = nav:items()
      assert.are.equal(2, #items)
      assert.are.equal(nodes.req, items[1])
      assert.are.equal(nodes.validate, items[2])
    end)

    it("returns true when drilling into a scope node", function()
      local scope_tree, nodes = make_test_tree()
      local nav = Navigator.new(scope_tree)
      local result = nav:drill_down(nodes.handle)
      assert.is_true(result)
    end)

    it("is a no-op when node has no children (leaf)", function()
      local scope_tree, nodes = make_test_tree()
      local nav = Navigator.new(scope_tree)
      nav:drill_down(nodes.handle) -- go into HandleRequest
      local before_items = nav:items()
      nav:drill_down(nodes.req) -- req is a leaf
      -- current and items should be unchanged
      assert.are.equal(nodes.handle, nav:current())
      assert.are.same(before_items, nav:items())
    end)

    it("returns false when drilling into a leaf node", function()
      local scope_tree, nodes = make_test_tree()
      local nav = Navigator.new(scope_tree)
      nav:drill_down(nodes.handle)
      local result = nav:drill_down(nodes.req)
      assert.is_false(result)
    end)

    it("updates breadcrumb_string after drill", function()
      local scope_tree, nodes = make_test_tree()
      local nav = Navigator.new(scope_tree)
      nav:drill_down(nodes.handle)
      assert.are.equal("sample.go > HandleRequest", nav:breadcrumb_string())
    end)
  end)

  describe("go_up", function()
    it("moves current back to parent", function()
      local scope_tree, nodes = make_test_tree()
      local nav = Navigator.new(scope_tree)
      nav:drill_down(nodes.handle)
      nav:go_up()
      assert.are.equal(nodes.root, nav:current())
    end)

    it("restores items() to parent's children after go_up", function()
      local scope_tree, nodes = make_test_tree()
      local nav = Navigator.new(scope_tree)
      nav:drill_down(nodes.handle)
      nav:go_up()
      local items = nav:items()
      assert.are.equal(2, #items)
      assert.are.equal(nodes.handle, items[1])
      assert.are.equal(nodes.main_fn, items[2])
    end)

    it("returns true when successfully moved up", function()
      local scope_tree, nodes = make_test_tree()
      local nav = Navigator.new(scope_tree)
      nav:drill_down(nodes.handle)
      local result = nav:go_up()
      assert.is_true(result)
    end)

    it("is a no-op at root", function()
      local scope_tree, nodes = make_test_tree()
      local nav = Navigator.new(scope_tree)
      nav:go_up() -- already at root
      assert.are.equal(nodes.root, nav:current())
    end)

    it("returns false when already at root", function()
      local scope_tree = make_test_tree()
      local nav = Navigator.new(scope_tree)
      local result = nav:go_up()
      assert.is_false(result)
    end)

    it("updates breadcrumb_string after go_up", function()
      local scope_tree, nodes = make_test_tree()
      local nav = Navigator.new(scope_tree)
      nav:drill_down(nodes.handle)
      nav:go_up()
      assert.are.equal("sample.go", nav:breadcrumb_string())
    end)

    it("multiple go_up calls at root remain at root", function()
      local scope_tree, nodes = make_test_tree()
      local nav = Navigator.new(scope_tree)
      nav:go_up()
      nav:go_up()
      nav:go_up()
      assert.are.equal(nodes.root, nav:current())
    end)
  end)

  describe("enter", function()
    it("returns the start position of the given node", function()
      local scope_tree, nodes = make_test_tree()
      local nav = Navigator.new(scope_tree)
      local pos = nav:enter(nodes.handle)
      assert.are.equal(5, pos.row)
      assert.are.equal(0, pos.col)
    end)

    it("returns the start position of a nested node", function()
      local scope_tree, nodes = make_test_tree()
      local nav = Navigator.new(scope_tree)
      nav:drill_down(nodes.handle)
      local pos = nav:enter(nodes.validate)
      assert.are.equal(10, pos.row)
      assert.are.equal(2, pos.col)
    end)

    it("returns start position for a leaf variable node", function()
      local scope_tree, nodes = make_test_tree()
      local nav = Navigator.new(scope_tree)
      local pos = nav:enter(nodes.req)
      assert.are.equal(6, pos.row)
      assert.are.equal(2, pos.col)
    end)
  end)

  describe("breadcrumb_string", function()
    it("reflects drill path correctly", function()
      local scope_tree, nodes = make_test_tree()
      local nav = Navigator.new(scope_tree)
      nav:drill_down(nodes.handle)
      nav:drill_down(nodes.validate)
      assert.are.equal("sample.go > HandleRequest > Validate", nav:breadcrumb_string())
    end)

    it("reflects go_up correctly after deep drill", function()
      local scope_tree, nodes = make_test_tree()
      local nav = Navigator.new(scope_tree)
      nav:drill_down(nodes.handle)
      nav:drill_down(nodes.validate)
      nav:go_up()
      assert.are.equal("sample.go > HandleRequest", nav:breadcrumb_string())
    end)
  end)

  describe("open_at_cursor", function()
    it("navigates to deepest scope containing the row", function()
      local scope_tree, nodes = make_test_tree()
      local nav = Navigator.new(scope_tree)
      -- row 15 is inside Validate (10-20), inside HandleRequest (5-30)
      nav:open_at_cursor(15)
      assert.are.equal(nodes.validate, nav:current())
    end)

    it("finds HandleRequest when cursor is in it but not in nested scope", function()
      local scope_tree, nodes = make_test_tree()
      local nav = Navigator.new(scope_tree)
      -- row 6 is inside req (leaf) inside HandleRequest — nearest scope is HandleRequest
      nav:open_at_cursor(6)
      assert.are.equal(nodes.handle, nav:current())
    end)

    it("falls back to root when row is outside all scopes", function()
      local scope_tree, nodes = make_test_tree()
      local nav = Navigator.new(scope_tree)
      -- row 2 is before HandleRequest (starts at 5)
      nav:open_at_cursor(2)
      assert.are.equal(nodes.root, nav:current())
    end)

    it("falls back to root when row is between top-level scopes", function()
      local scope_tree, nodes = make_test_tree()
      local nav = Navigator.new(scope_tree)
      -- row 35 is between HandleRequest (5-30) and main (40-60)
      nav:open_at_cursor(35)
      assert.are.equal(nodes.root, nav:current())
    end)

    it("sets correct breadcrumb_string after open_at_cursor", function()
      local scope_tree, nodes = make_test_tree()
      local nav = Navigator.new(scope_tree)
      nav:open_at_cursor(15)
      -- Validate is inside HandleRequest is inside root
      assert.are.equal("sample.go > HandleRequest > Validate", nav:breadcrumb_string())
    end)

    it("sets breadcrumb_string to root name when falling back to root", function()
      local scope_tree = make_test_tree()
      local nav = Navigator.new(scope_tree)
      nav:open_at_cursor(2)
      assert.are.equal("sample.go", nav:breadcrumb_string())
    end)

    it("navigates to main when cursor is inside it", function()
      local scope_tree, nodes = make_test_tree()
      local nav = Navigator.new(scope_tree)
      nav:open_at_cursor(50)
      assert.are.equal(nodes.main_fn, nav:current())
    end)
  end)

  describe("sequence tests", function()
    it("drill → drill → up → up returns to original state", function()
      local scope_tree, nodes = make_test_tree()
      local nav = Navigator.new(scope_tree)

      -- Drill twice
      nav:drill_down(nodes.handle)
      nav:drill_down(nodes.validate)
      assert.are.equal(nodes.validate, nav:current())
      assert.are.equal("sample.go > HandleRequest > Validate", nav:breadcrumb_string())

      -- Go up twice
      nav:go_up()
      assert.are.equal(nodes.handle, nav:current())
      nav:go_up()
      assert.are.equal(nodes.root, nav:current())
      assert.are.equal("sample.go", nav:breadcrumb_string())
      -- items should be back to root's children
      assert.are.equal(2, #nav:items())
    end)

    it("drill → enter returns range from within the drilled scope", function()
      local scope_tree, nodes = make_test_tree()
      local nav = Navigator.new(scope_tree)

      nav:drill_down(nodes.handle)
      -- enter on a child of HandleRequest
      local pos = nav:enter(nodes.validate)
      assert.are.equal(10, pos.row)
      assert.are.equal(2, pos.col)
    end)

    it("drill → go_up at root → go_up stays at root", function()
      local scope_tree, nodes = make_test_tree()
      local nav = Navigator.new(scope_tree)

      nav:drill_down(nodes.handle)
      nav:go_up() -- back to root
      nav:go_up() -- already at root, no-op
      assert.are.equal(nodes.root, nav:current())
      assert.are.equal("sample.go", nav:breadcrumb_string())
    end)

    it("open_at_cursor after drilling resets state", function()
      local scope_tree, nodes = make_test_tree()
      local nav = Navigator.new(scope_tree)

      nav:drill_down(nodes.handle)
      nav:drill_down(nodes.validate)
      -- Now navigate via cursor to main
      nav:open_at_cursor(50)
      assert.are.equal(nodes.main_fn, nav:current())
      assert.are.equal("sample.go > main", nav:breadcrumb_string())
    end)
  end)
end)
