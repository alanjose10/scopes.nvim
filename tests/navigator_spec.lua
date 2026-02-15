local Navigator = require("scopes.navigator")
local helpers = require("helpers")

describe("scopes.navigator", function()
  local test_tree
  local nav

  before_each(function()
    test_tree = helpers.make_test_tree()
    nav = Navigator:new(test_tree)
  end)

  describe("new", function()
    it("initializes at the root node", function()
      assert.are.equal(test_tree.root, nav.current_node)
    end)

    it("starts with empty breadcrumb", function()
      assert.are.same({}, nav.breadcrumb)
    end)

    it("stores the tree reference", function()
      assert.are.equal(test_tree, nav.tree)
    end)
  end)

  describe("items", function()
    it("returns children of the current node", function()
      local items = nav:items()
      assert.are.equal(#test_tree.root.children, #items)
    end)

    it("returns root children initially", function()
      local items = nav:items()
      assert.are.equal("MaxRetries", items[1].name)
      assert.are.equal("MyStruct", items[2].name)
      assert.are.equal("NewMyStruct", items[3].name)
      assert.are.equal("HandleRequest", items[4].name)
    end)
  end)

  describe("drill_down", function()
    it("changes current node to the selected scope", function()
      local my_struct = test_tree.root.children[2] -- MyStruct
      local ok = nav:drill_down(my_struct)
      assert.is_true(ok)
      assert.are.equal(my_struct, nav.current_node)
    end)

    it("updates breadcrumb on drill", function()
      local my_struct = test_tree.root.children[2]
      nav:drill_down(my_struct)
      assert.are.equal(1, #nav.breadcrumb)
      assert.are.equal(test_tree.root, nav.breadcrumb[1])
    end)

    it("shows children of drilled node", function()
      local my_struct = test_tree.root.children[2]
      nav:drill_down(my_struct)
      local items = nav:items()
      assert.are.equal(1, #items) -- Name field
      assert.are.equal("Name", items[1].name)
    end)

    it("returns false for non-scope nodes", function()
      local max_retries = test_tree.root.children[1] -- const, not a scope
      local ok = nav:drill_down(max_retries)
      assert.is_false(ok)
      assert.are.equal(test_tree.root, nav.current_node)
    end)

    it("returns false for nil node", function()
      local ok = nav:drill_down(nil)
      assert.is_false(ok)
    end)

    it("returns false for node not in current children", function()
      -- Create an unrelated node
      local unrelated = helpers.make_node("unrelated", "function", { start_row = 100, start_col = 0, end_row = 110, end_col = 0 }, true)
      local ok = nav:drill_down(unrelated)
      assert.is_false(ok)
    end)

    it("supports nested drill down", function()
      local handle_req = test_tree.root.children[4] -- HandleRequest
      nav:drill_down(handle_req)

      local for_block = handle_req.children[2] -- for loop
      nav:drill_down(for_block)

      assert.are.equal(for_block, nav.current_node)
      assert.are.equal(2, #nav.breadcrumb)
    end)
  end)

  describe("go_up", function()
    it("returns to parent node", function()
      local my_struct = test_tree.root.children[2]
      nav:drill_down(my_struct)
      local ok = nav:go_up()
      assert.is_true(ok)
      assert.are.equal(test_tree.root, nav.current_node)
    end)

    it("is a no-op at root", function()
      local ok = nav:go_up()
      assert.is_false(ok)
      assert.are.equal(test_tree.root, nav.current_node)
    end)

    it("removes last breadcrumb entry", function()
      local handle_req = test_tree.root.children[4]
      nav:drill_down(handle_req)
      assert.are.equal(1, #nav.breadcrumb)

      nav:go_up()
      assert.are.equal(0, #nav.breadcrumb)
    end)

    it("restores parent children after go_up", function()
      local handle_req = test_tree.root.children[4]
      nav:drill_down(handle_req)
      nav:go_up()

      local items = nav:items()
      assert.are.equal(4, #items) -- root has 4 children
    end)
  end)

  describe("enter", function()
    it("returns row and col for a node", function()
      local my_struct = test_tree.root.children[2]
      local pos = nav:enter(my_struct)
      assert.is_not_nil(pos)
      assert.are.equal(5, pos.row)
      assert.are.equal(0, pos.col)
    end)

    it("returns nil for nil node", function()
      local pos = nav:enter(nil)
      assert.is_nil(pos)
    end)

    it("returns correct position after drill down", function()
      local handle_req = test_tree.root.children[4]
      nav:drill_down(handle_req)

      local if_block = handle_req.children[1]
      local pos = nav:enter(if_block)
      assert.are.equal(18, pos.row)
      assert.are.equal(1, pos.col)
    end)
  end)

  describe("breadcrumb_string", function()
    it("returns empty string at root with no filename", function()
      local bc = nav:breadcrumb_string()
      assert.are.equal("", bc)
    end)

    it("returns filename when at root", function()
      local bc = nav:breadcrumb_string("sample.go")
      assert.are.equal("sample.go", bc)
    end)

    it("includes current node after drill", function()
      local my_struct = test_tree.root.children[2]
      nav:drill_down(my_struct)
      local bc = nav:breadcrumb_string("sample.go")
      assert.are.equal("sample.go > MyStruct", bc)
    end)

    it("shows full path with nested drills", function()
      local handle_req = test_tree.root.children[4]
      nav:drill_down(handle_req)
      local for_block = handle_req.children[2]
      nav:drill_down(for_block)

      local bc = nav:breadcrumb_string("sample.go")
      assert.are.equal("sample.go > HandleRequest > for", bc)
    end)

    it("works without filename", function()
      local handle_req = test_tree.root.children[4]
      nav:drill_down(handle_req)
      local bc = nav:breadcrumb_string()
      assert.are.equal("HandleRequest", bc)
    end)

    it("updates correctly after go_up", function()
      local handle_req = test_tree.root.children[4]
      nav:drill_down(handle_req)
      local for_block = handle_req.children[2]
      nav:drill_down(for_block)

      nav:go_up()
      local bc = nav:breadcrumb_string("sample.go")
      assert.are.equal("sample.go > HandleRequest", bc)
    end)
  end)

  describe("open_at_cursor", function()
    it("finds deepest scope at a given row", function()
      -- Row 24 should be inside HandleRequest > for > nested if
      nav:open_at_cursor(24)
      assert.are.equal("if", nav.current_node.name)
      assert.are.equal("block", nav.current_node.kind)
    end)

    it("navigates to function scope at function row", function()
      -- Row 11 should be inside NewMyStruct
      nav:open_at_cursor(11)
      assert.are.equal("NewMyStruct", nav.current_node.name)
    end)

    it("falls back to root for row outside all scopes", function()
      -- Row 3 is between const and MyStruct - only root contains it
      nav:open_at_cursor(3)
      assert.are.equal("<root>", nav.current_node.name)
    end)

    it("sets breadcrumb correctly for nested scope", function()
      -- Row 24 is in HandleRequest > for > if
      nav:open_at_cursor(24)
      -- Breadcrumb should be: root, HandleRequest, for
      assert.are.equal(3, #nav.breadcrumb)
      assert.are.equal("<root>", nav.breadcrumb[1].name)
      assert.are.equal("HandleRequest", nav.breadcrumb[2].name)
      assert.are.equal("for", nav.breadcrumb[3].name)
    end)

    it("works via constructor opts", function()
      local nav2 = Navigator:new(test_tree, { cursor_row = 11 })
      assert.are.equal("NewMyStruct", nav2.current_node.name)
    end)
  end)

  describe("sequence tests", function()
    it("drill → drill → up → up returns to root", function()
      local handle_req = test_tree.root.children[4]
      nav:drill_down(handle_req)
      local for_block = handle_req.children[2]
      nav:drill_down(for_block)

      nav:go_up()
      nav:go_up()

      assert.are.equal(test_tree.root, nav.current_node)
      assert.are.equal(0, #nav.breadcrumb)
    end)

    it("drill → enter returns position within drilled scope", function()
      local handle_req = test_tree.root.children[4]
      nav:drill_down(handle_req)

      local for_block = handle_req.children[2]
      local pos = nav:enter(for_block)
      assert.are.equal(22, pos.row)
      assert.are.equal(1, pos.col)
    end)

    it("open_at_cursor → go_up → go_up navigates correctly", function()
      nav:open_at_cursor(24) -- in HandleRequest > for > if
      assert.are.equal("if", nav.current_node.name)

      nav:go_up() -- now at for
      assert.are.equal("for", nav.current_node.name)

      nav:go_up() -- now at HandleRequest
      assert.are.equal("HandleRequest", nav.current_node.name)

      nav:go_up() -- now at root
      assert.are.equal("<root>", nav.current_node.name)

      -- One more go_up should be no-op
      local ok = nav:go_up()
      assert.is_false(ok)
    end)
  end)
end)
