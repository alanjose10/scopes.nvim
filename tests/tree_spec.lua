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

  describe("validation", function()
    local warnings

    before_each(function()
      warnings = {}
      -- Stub vim.notify to capture warnings
      _G._original_notify = vim.notify
      vim.notify = function(msg, level)
        if level == vim.log.levels.WARN then
          table.insert(warnings, msg)
        end
      end
    end)

    after_each(function()
      vim.notify = _G._original_notify
      _G._original_notify = nil
    end)

    it("warns when name is missing", function()
      ScopeNode.new({
        kind = "variable",
        range = { start_row = 0, start_col = 0, end_row = 0, end_col = 1 },
      })
      assert.is_true(#warnings > 0)
      assert.is_truthy(warnings[1]:find("name"))
    end)

    it("warns when kind is missing", function()
      ScopeNode.new({
        name = "x",
        range = { start_row = 0, start_col = 0, end_row = 0, end_col = 1 },
      })
      assert.is_true(#warnings > 0)
      assert.is_truthy(warnings[1]:find("kind"))
    end)

    it("warns when range is missing", function()
      ScopeNode.new({
        name = "x",
        kind = "variable",
      })
      assert.is_true(#warnings > 0)
      assert.is_truthy(warnings[1]:find("range"))
    end)

    it("warns when start_row > end_row", function()
      ScopeNode.new({
        name = "x",
        kind = "variable",
        range = { start_row = 5, start_col = 0, end_row = 3, end_col = 0 },
      })
      assert.is_true(#warnings > 0)
      assert.is_truthy(warnings[1]:find("start_row"))
    end)

    it("warns when same row but start_col > end_col", function()
      ScopeNode.new({
        name = "x",
        kind = "variable",
        range = { start_row = 5, start_col = 10, end_row = 5, end_col = 3 },
      })
      assert.is_true(#warnings > 0)
      assert.is_truthy(warnings[1]:find("start_col"))
    end)

    it("does not warn for valid single-line range", function()
      ScopeNode.new({
        name = "x",
        kind = "variable",
        range = { start_row = 5, start_col = 0, end_row = 5, end_col = 10 },
      })
      assert.are.equal(0, #warnings)
    end)

    it("still returns a ScopeNode when validation fails", function()
      local node = ScopeNode.new({
        kind = "variable",
        range = { start_row = 5, start_col = 0, end_row = 3, end_col = 0 },
      })
      assert.is_true(#warnings > 0)
      assert.is_not_nil(node)
      assert.are.equal("variable", node.kind)
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

    describe("validation", function()
      local warnings

      before_each(function()
        warnings = {}
        _G._original_notify_ac = vim.notify
        vim.notify = function(msg, level)
          if level == vim.log.levels.WARN then
            table.insert(warnings, msg)
          end
        end
      end)

      after_each(function()
        vim.notify = _G._original_notify_ac
        _G._original_notify_ac = nil
      end)

      it("does not warn when child is fully inside parent", function()
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
        -- Clear any warnings from construction
        warnings = {}
        parent:add_child(child)
        assert.are.equal(0, #warnings)
      end)

      it("warns when child start_row is before parent start_row", function()
        local parent = ScopeNode.new({
          name = "root",
          kind = "function",
          range = { start_row = 5, start_col = 0, end_row = 10, end_col = 0 },
        })
        local child = ScopeNode.new({
          name = "x",
          kind = "variable",
          range = { start_row = 3, start_col = 0, end_row = 7, end_col = 0 },
        })
        warnings = {}
        parent:add_child(child)
        assert.is_true(#warnings > 0)
        assert.is_truthy(warnings[1]:find("outside"))
      end)

      it("warns when child end_row is after parent end_row", function()
        local parent = ScopeNode.new({
          name = "root",
          kind = "function",
          range = { start_row = 0, start_col = 0, end_row = 10, end_col = 0 },
        })
        local child = ScopeNode.new({
          name = "x",
          kind = "variable",
          range = { start_row = 5, start_col = 0, end_row = 15, end_col = 0 },
        })
        warnings = {}
        parent:add_child(child)
        assert.is_true(#warnings > 0)
        assert.is_truthy(warnings[1]:find("outside"))
      end)

      it("warns when child on same start row has start_col before parent", function()
        local parent = ScopeNode.new({
          name = "root",
          kind = "function",
          range = { start_row = 5, start_col = 10, end_row = 10, end_col = 0 },
        })
        local child = ScopeNode.new({
          name = "x",
          kind = "variable",
          range = { start_row = 5, start_col = 5, end_row = 7, end_col = 0 },
        })
        warnings = {}
        parent:add_child(child)
        assert.is_true(#warnings > 0)
        assert.is_truthy(warnings[1]:find("outside"))
      end)

      it("warns when child on same end row has end_col after parent", function()
        local parent = ScopeNode.new({
          name = "root",
          kind = "function",
          range = { start_row = 0, start_col = 0, end_row = 10, end_col = 5 },
        })
        local child = ScopeNode.new({
          name = "x",
          kind = "variable",
          range = { start_row = 5, start_col = 0, end_row = 10, end_col = 10 },
        })
        warnings = {}
        parent:add_child(child)
        assert.is_true(#warnings > 0)
        assert.is_truthy(warnings[1]:find("outside"))
      end)

      it("only checks start_col when on same start row with different end row", function()
        local parent = ScopeNode.new({
          name = "root",
          kind = "function",
          range = { start_row = 5, start_col = 3, end_row = 10, end_col = 5 },
        })
        local child = ScopeNode.new({
          name = "x",
          kind = "variable",
          range = { start_row = 5, start_col = 5, end_row = 8, end_col = 20 },
        })
        warnings = {}
        parent:add_child(child)
        -- start_col 5 >= 3, end_row 8 <= 10, no same-end-row check needed
        assert.are.equal(0, #warnings)
      end)

      it("still adds the child even when validation fails", function()
        local parent = ScopeNode.new({
          name = "root",
          kind = "function",
          range = { start_row = 5, start_col = 0, end_row = 10, end_col = 0 },
        })
        local child = ScopeNode.new({
          name = "x",
          kind = "variable",
          range = { start_row = 1, start_col = 0, end_row = 1, end_col = 5 },
        })
        warnings = {}
        parent:add_child(child)
        assert.is_true(#warnings > 0)
        assert.are.equal(1, #parent.children)
        assert.are.equal(child, parent.children[1])
      end)
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

    describe("validation", function()
      local warnings

      before_each(function()
        warnings = {}
        _G._original_notify_st = vim.notify
        vim.notify = function(msg, level)
          if level == vim.log.levels.WARN then
            table.insert(warnings, msg)
          end
        end
      end)

      after_each(function()
        vim.notify = _G._original_notify_st
        _G._original_notify_st = nil
      end)

      it("warns when root is missing", function()
        ScopeTree.new({ source = "treesitter", bufnr = 1, lang = "go" })
        assert.is_true(#warnings > 0)
        assert.is_truthy(warnings[1]:find("root"))
      end)

      it("warns when source is invalid", function()
        local root = ScopeNode.new({
          name = "file",
          kind = "module",
          range = { start_row = 0, start_col = 0, end_row = 10, end_col = 0 },
        })
        warnings = {}
        ScopeTree.new({ root = root, source = "magic", bufnr = 1, lang = "go" })
        assert.is_true(#warnings > 0)
        assert.is_truthy(warnings[1]:find("source"))
      end)

      it("warns when bufnr is missing", function()
        local root = ScopeNode.new({
          name = "file",
          kind = "module",
          range = { start_row = 0, start_col = 0, end_row = 10, end_col = 0 },
        })
        warnings = {}
        ScopeTree.new({ root = root, source = "treesitter", lang = "go" })
        assert.is_true(#warnings > 0)
        assert.is_truthy(warnings[1]:find("bufnr"))
      end)

      it("still returns a ScopeTree when validation fails", function()
        local st = ScopeTree.new({ source = "invalid" })
        assert.is_true(#warnings > 0)
        assert.is_not_nil(st)
        assert.are.equal("invalid", st.source)
      end)
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
