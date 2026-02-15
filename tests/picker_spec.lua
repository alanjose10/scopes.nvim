local Navigator = require("scopes.navigator")
local config = require("scopes.config")
local helpers = require("helpers")

describe("scopes.picker", function()
  local test_tree
  local nav

  before_each(function()
    config.current = nil
    config.merge({})
    test_tree = helpers.make_test_tree()
    nav = Navigator:new(test_tree)
  end)

  describe("item formatting", function()
    it("each item has text and kind fields", function()
      -- We test the formatting logic by verifying navigator items have needed fields
      local items = nav:items()
      for _, item in ipairs(items) do
        assert.is_not_nil(item.name)
        assert.is_not_nil(item.kind)
        assert.is_not_nil(item.range)
      end
    end)

    it("scope items have is_scope true", function()
      local items = nav:items()
      -- MyStruct, NewMyStruct, HandleRequest are scopes
      local scope_count = 0
      for _, item in ipairs(items) do
        if item.is_scope then
          scope_count = scope_count + 1
        end
      end
      assert.is_true(scope_count >= 3)
    end)

    it("items have line number information", function()
      local items = nav:items()
      for _, item in ipairs(items) do
        assert.is_not_nil(item.range)
        assert.is_not_nil(item.range.start_row)
      end
    end)
  end)

  describe("breadcrumb updates", function()
    it("breadcrumb changes after drill_down", function()
      local bc_before = nav:breadcrumb_string("test.go")
      local my_struct = test_tree.root.children[2]
      nav:drill_down(my_struct)
      local bc_after = nav:breadcrumb_string("test.go")

      assert.are_not.equal(bc_before, bc_after)
      assert.is_truthy(bc_after:match("MyStruct"))
    end)

    it("breadcrumb updates after go_up", function()
      local my_struct = test_tree.root.children[2]
      nav:drill_down(my_struct)
      local bc_drilled = nav:breadcrumb_string("test.go")

      nav:go_up()
      local bc_up = nav:breadcrumb_string("test.go")

      assert.are_not.equal(bc_drilled, bc_up)
    end)
  end)

  describe("edge cases", function()
    it("drill on leaf node is a no-op", function()
      local max_retries = test_tree.root.children[1] -- const, not a scope
      local items_before = nav:items()
      nav:drill_down(max_retries)
      local items_after = nav:items()
      assert.are.equal(#items_before, #items_after)
    end)

    it("go_up at root is a no-op", function()
      local items_before = nav:items()
      nav:go_up()
      local items_after = nav:items()
      assert.are.equal(#items_before, #items_after)
    end)

    it("handles empty scope (no children to show)", function()
      -- Drill into an if block that has no children
      local handle_req = test_tree.root.children[4]
      nav:drill_down(handle_req)
      local if_block = handle_req.children[1]
      nav:drill_down(if_block)
      local items = nav:items()
      assert.are.equal(0, #items)
    end)
  end)
end)
