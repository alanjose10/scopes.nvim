local tree = require("scopes.tree")
local helpers = require("helpers")

describe("scopes.tree", function()
  describe("build", function()
    local bufnr

    after_each(function()
      if bufnr then
        vim.api.nvim_buf_delete(bufnr, { force = true })
        tree.invalidate(bufnr)
        bufnr = nil
      end
    end)

    it("builds a tree from a Go fixture", function()
      bufnr = helpers.load_fixture("tests/fixtures/sample.go")
      vim.api.nvim_set_option_value("filetype", "go", { buf = bufnr })

      -- Give treesitter a moment to parse
      vim.treesitter.start(bufnr, "go")

      local scope_tree, err = tree.build(bufnr, { force = true })
      assert.is_nil(err)
      assert.is_not_nil(scope_tree)
      assert.are.equal("treesitter", scope_tree.source)
      assert.are.equal(bufnr, scope_tree.bufnr)
    end)

    it("root has children for Go file", function()
      bufnr = helpers.load_fixture("tests/fixtures/sample.go")
      vim.api.nvim_set_option_value("filetype", "go", { buf = bufnr })
      vim.treesitter.start(bufnr, "go")

      local scope_tree = tree.build(bufnr, { force = true })
      assert.is_not_nil(scope_tree)
      assert.is_true(#scope_tree.root.children > 0)
    end)

    it("sets parent back-references on all children", function()
      bufnr = helpers.load_fixture("tests/fixtures/sample.go")
      vim.api.nvim_set_option_value("filetype", "go", { buf = bufnr })
      vim.treesitter.start(bufnr, "go")

      local scope_tree = tree.build(bufnr, { force = true })
      assert.is_not_nil(scope_tree)

      for _, child in ipairs(scope_tree.root.children) do
        assert.are.equal(scope_tree.root, child.parent)
      end
    end)

    it("extracts correct names for Go symbols", function()
      bufnr = helpers.load_fixture("tests/fixtures/sample.go")
      vim.api.nvim_set_option_value("filetype", "go", { buf = bufnr })
      vim.treesitter.start(bufnr, "go")

      local scope_tree = tree.build(bufnr, { force = true })
      assert.is_not_nil(scope_tree)

      -- Collect top-level names
      local names = {}
      for _, child in ipairs(scope_tree.root.children) do
        table.insert(names, child.name)
      end

      -- Should find key declarations
      assert.is_true(vim.tbl_contains(names, "MaxRetries"))
      assert.is_true(vim.tbl_contains(names, "DefaultName"))
      assert.is_true(vim.tbl_contains(names, "MyStruct"))
      assert.is_true(vim.tbl_contains(names, "NewMyStruct"))
    end)

    it("maps correct kinds for Go nodes", function()
      bufnr = helpers.load_fixture("tests/fixtures/sample.go")
      vim.api.nvim_set_option_value("filetype", "go", { buf = bufnr })
      vim.treesitter.start(bufnr, "go")

      local scope_tree = tree.build(bufnr, { force = true })
      assert.is_not_nil(scope_tree)

      -- Find the NewMyStruct node
      local func_node
      for _, child in ipairs(scope_tree.root.children) do
        if child.name == "NewMyStruct" then
          func_node = child
          break
        end
      end

      assert.is_not_nil(func_node)
      assert.are.equal("function", func_node.kind)
      assert.is_true(func_node.is_scope)
    end)

    it("builds nested scopes correctly", function()
      bufnr = helpers.load_fixture("tests/fixtures/sample.go")
      vim.api.nvim_set_option_value("filetype", "go", { buf = bufnr })
      vim.treesitter.start(bufnr, "go")

      local scope_tree = tree.build(bufnr, { force = true })
      assert.is_not_nil(scope_tree)

      -- Find HandleRequest method — should have nested if/for blocks
      local method_node
      for _, child in ipairs(scope_tree.root.children) do
        if child.name and child.name:match("HandleRequest") then
          method_node = child
          break
        end
      end

      assert.is_not_nil(method_node)
      assert.is_true(#method_node.children > 0)

      -- Check parent back-references for nested children
      for _, child in ipairs(method_node.children) do
        assert.are.equal(method_node, child.parent)
      end
    end)

    it("builds a tree from a Lua fixture", function()
      bufnr = helpers.load_fixture("tests/fixtures/sample.lua")
      vim.api.nvim_set_option_value("filetype", "lua", { buf = bufnr })
      vim.treesitter.start(bufnr, "lua")

      local scope_tree, err = tree.build(bufnr, { force = true })
      assert.is_nil(err)
      assert.is_not_nil(scope_tree)
      assert.are.equal("treesitter", scope_tree.source)
      assert.is_true(#scope_tree.root.children > 0)
    end)

    it("handles empty buffer gracefully", function()
      bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_set_option_value("filetype", "go", { buf = bufnr })
      vim.treesitter.start(bufnr, "go")

      local scope_tree, err = tree.build(bufnr, { force = true })
      -- Should succeed but root has no children
      if scope_tree then
        assert.are.equal(0, #scope_tree.root.children)
      end
    end)

    it("handles broken Go file without crashing", function()
      bufnr = helpers.load_fixture("tests/fixtures/sample_broken.go")
      vim.api.nvim_set_option_value("filetype", "go", { buf = bufnr })
      vim.treesitter.start(bufnr, "go")

      local scope_tree, err = tree.build(bufnr, { force = true })
      -- Should not crash — returns a partial tree or nil with error
      if scope_tree then
        assert.is_not_nil(scope_tree.root)
      end
    end)

    it("returns error for unsupported filetype without config", function()
      bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "some text" })
      vim.api.nvim_set_option_value("filetype", "unknown_language_xyz", { buf = bufnr })

      local scope_tree, err = tree.build(bufnr, { force = true })
      assert.is_nil(scope_tree)
      assert.is_not_nil(err)
    end)
  end)

  describe("find_scope_at_cursor", function()
    it("finds the deepest scope containing a row", function()
      local test_tree = helpers.make_test_tree()

      -- Row 11 is inside NewMyStruct
      local scope = tree.find_scope_at_cursor(test_tree, 11)
      assert.are.equal("NewMyStruct", scope.name)
    end)

    it("returns root for rows outside all scopes", function()
      local test_tree = helpers.make_test_tree()

      -- Row 3 is between declarations
      local scope = tree.find_scope_at_cursor(test_tree, 3)
      assert.are.equal("<root>", scope.name)
    end)

    it("finds nested scopes", function()
      local test_tree = helpers.make_test_tree()

      -- Row 24 is in HandleRequest > for > if
      local scope = tree.find_scope_at_cursor(test_tree, 24)
      assert.are.equal("if", scope.name)
    end)
  end)

  describe("cache", function()
    local bufnr

    after_each(function()
      if bufnr then
        vim.api.nvim_buf_delete(bufnr, { force = true })
        tree.invalidate(bufnr)
        bufnr = nil
      end
    end)

    it("returns cached tree on second call", function()
      bufnr = helpers.load_fixture("tests/fixtures/sample.go")
      vim.api.nvim_set_option_value("filetype", "go", { buf = bufnr })
      vim.treesitter.start(bufnr, "go")

      local tree1 = tree.build(bufnr, { force = true })
      local tree2 = tree.build(bufnr)

      -- Same reference means cache hit
      assert.are.equal(tree1, tree2)
    end)

    it("invalidate clears cache for buffer", function()
      bufnr = helpers.load_fixture("tests/fixtures/sample.go")
      vim.api.nvim_set_option_value("filetype", "go", { buf = bufnr })
      vim.treesitter.start(bufnr, "go")

      local tree1 = tree.build(bufnr, { force = true })
      tree.invalidate(bufnr)
      local tree2 = tree.build(bufnr)

      -- After invalidation, should get a new tree
      assert.are_not.equal(tree1, tree2)
    end)
  end)
end)
