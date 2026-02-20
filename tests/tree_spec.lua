local tree = require("scopes.tree")
local ScopeNode = tree.ScopeNode
local ScopeTree = tree.ScopeTree
local helpers = require("tests.helpers")

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
    local warnings, restore_notify

    before_each(function()
      warnings, restore_notify = helpers.capture_notify()
    end)

    after_each(function()
      restore_notify()
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
      local warnings, restore_notify, clear_warnings

      before_each(function()
        warnings, restore_notify, clear_warnings = helpers.capture_notify()
      end)

      after_each(function()
        restore_notify()
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
        clear_warnings()
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
        clear_warnings()
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
        clear_warnings()
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
        clear_warnings()
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
        clear_warnings()
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
        clear_warnings()
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
        clear_warnings()
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

describe("find_scope_for_row", function()
  local tree_mod = require("scopes.tree")
  local ScopeNode = tree_mod.ScopeNode
  local ScopeTree = tree_mod.ScopeTree

  --- Build a small test tree for row-lookup tests.
  ---   root (rows 0–99)
  ---   ├── funcA  function (rows 5–20)
  ---   │   └── nested  function (rows 10–15)
  ---   │       └── x  variable (rows 11–11)  ← leaf
  ---   └── funcB  function (rows 30–50)
  local function make_row_tree()
    local root = ScopeNode.new({
      name = "root",
      kind = "module",
      range = { start_row = 0, start_col = 0, end_row = 99, end_col = 0 },
    })
    local func_a = ScopeNode.new({
      name = "funcA",
      kind = "function",
      range = { start_row = 5, start_col = 0, end_row = 20, end_col = 1 },
    })
    local nested = ScopeNode.new({
      name = "nested",
      kind = "function",
      range = { start_row = 10, start_col = 2, end_row = 15, end_col = 3 },
    })
    local x = ScopeNode.new({
      name = "x",
      kind = "variable",
      range = { start_row = 11, start_col = 4, end_row = 11, end_col = 10 },
    })
    local func_b = ScopeNode.new({
      name = "funcB",
      kind = "function",
      range = { start_row = 30, start_col = 0, end_row = 50, end_col = 1 },
    })
    local y = ScopeNode.new({
      name = "y",
      kind = "variable",
      range = { start_row = 31, start_col = 2, end_row = 31, end_col = 5 },
    })

    root:add_child(func_a)
    func_a:add_child(nested)
    nested:add_child(x) -- x has no children → leaf, not a scope
    root:add_child(func_b)
    func_b:add_child(y) -- give funcB a child so is_scope() == true

    local scope_tree = ScopeTree.new({
      root = root,
      source = "treesitter",
      bufnr = 1,
      lang = "go",
    })
    return scope_tree, { root = root, func_a = func_a, nested = nested, x = x, func_b = func_b, y = y }
  end

  it("returns the deepest scope containing the row", function()
    local st = make_row_tree()
    -- row 12 is inside nested (10–15) which is inside funcA (5–20)
    local result = tree_mod.find_scope_for_row(st, 12)
    assert.are.equal("nested", result.name)
  end)

  it("returns outer scope when row is in a non-scope (leaf) child", function()
    local st = make_row_tree()
    -- row 11 has x (leaf) inside nested → nearest scope is nested
    local result = tree_mod.find_scope_for_row(st, 11)
    assert.are.equal("nested", result.name)
  end)

  it("returns nil when row is outside all scopes", function()
    local st = make_row_tree()
    -- row 2 is before funcA (starts at row 5)
    local result = tree_mod.find_scope_for_row(st, 2)
    assert.is_nil(result)
  end)

  it("returns nil when row is between two top-level scopes", function()
    local st = make_row_tree()
    -- row 25 is between funcA (5–20) and funcB (30–50)
    local result = tree_mod.find_scope_for_row(st, 25)
    assert.is_nil(result)
  end)

  it("returns funcB when row is inside it", function()
    local st = make_row_tree()
    local result = tree_mod.find_scope_for_row(st, 40)
    assert.are.equal("funcB", result.name)
  end)
end)

describe("build", function()
  local tree_mod = require("scopes.tree")
  local config = require("scopes.config")
  local bufnr

  before_each(function()
    config.merge({})
    bufnr = helpers.make_buf("tests/fixtures/sample.go", "go")
    tree_mod.invalidate(bufnr)
  end)

  after_each(function()
    helpers.delete_buf(bufnr)
  end)

  it("returns a ScopeTree with source = treesitter for a parseable buffer", function()
    local result = tree_mod.build(bufnr)
    assert.is_not_nil(result)
    assert.are.equal("treesitter", result.source)
  end)

  it("returns nil for a buffer with no parser", function()
    local warnings, restore = helpers.capture_notify()
    local empty_bufnr = vim.api.nvim_create_buf(false, true)
    local result = tree_mod.build(empty_bufnr)
    restore()
    assert.is_nil(result)
    vim.api.nvim_buf_delete(empty_bufnr, { force = true })
  end)

  it("returns nil and emits a WARN for backend = lsp", function()
    local warnings, restore = helpers.capture_notify()
    local result = tree_mod.build(bufnr, { backend = "lsp" })
    restore()
    assert.is_nil(result)
    assert.is_true(#warnings > 0)
    assert.is_truthy(warnings[1]:find("LSP"))
  end)

  it("uses treesitter when opts.backend = treesitter", function()
    local result = tree_mod.build(bufnr, { backend = "treesitter" })
    assert.is_not_nil(result)
    assert.are.equal("treesitter", result.source)
  end)
end)

describe("cache", function()
  local tree_mod = require("scopes.tree")
  local config = require("scopes.config")
  local bufnr

  before_each(function()
    config.merge({ cache = { enabled = true, debounce_ms = 300 } })
    bufnr = helpers.make_buf("tests/fixtures/sample.go", "go")
    tree_mod.invalidate(bufnr)
  end)

  after_each(function()
    helpers.delete_buf(bufnr)
  end)

  it("two consecutive build() calls return the same object (cache hit)", function()
    local t1 = tree_mod.build(bufnr)
    local t2 = tree_mod.build(bufnr)
    assert.are.equal(t1, t2)
  end)

  it("returns a new object after invalidate() (cache miss)", function()
    local t1 = tree_mod.build(bufnr)
    tree_mod.invalidate(bufnr)
    local t2 = tree_mod.build(bufnr)
    assert.are_not.equal(t1, t2)
  end)

  it("always builds fresh when cache.enabled = false", function()
    config.merge({ cache = { enabled = false, debounce_ms = 300 } })
    local t1 = tree_mod.build(bufnr)
    local t2 = tree_mod.build(bufnr)
    assert.are_not.equal(t1, t2)
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
      local warnings, restore_notify, clear_warnings

      before_each(function()
        warnings, restore_notify, clear_warnings = helpers.capture_notify()
      end)

      after_each(function()
        restore_notify()
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
        clear_warnings()
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
        clear_warnings()
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
