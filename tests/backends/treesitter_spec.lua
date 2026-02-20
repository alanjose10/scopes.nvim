local ts_backend = require("scopes.backends.treesitter")
local helpers = require("tests.helpers")

describe("backends.treesitter", function()
  describe("build() with Go fixture", function()
    local scope_tree
    local bufnr

    before_each(function()
      bufnr = helpers.make_buf("tests/fixtures/sample.go", "go")
      scope_tree = ts_backend.build(bufnr)
    end)

    after_each(function()
      helpers.delete_buf(bufnr)
    end)

    it("returns a ScopeTree with source set to treesitter", function()
      assert.is_truthy(scope_tree)
      assert.are.equal("treesitter", scope_tree.source)
    end)

    it("returns a ScopeTree with correct bufnr", function()
      assert.are.equal(bufnr, scope_tree.bufnr)
    end)

    it("returns a ScopeTree with lang set to go", function()
      assert.are.equal("go", scope_tree.lang)
    end)

    it("root has correct number of top-level children", function()
      -- import(1), const MaxRetries(1), var DefaultName(1), type MyStruct(1),
      -- converStrToInt, NewMyStruct, HandleRequest, ProcessItems, RunWithCallback, main = 6 functions
      -- Total: 1 + 1 + 1 + 1 + 6 = 10
      local root = scope_tree.root
      assert.are.equal(10, #root.children)
    end)

    it("function nodes have correct names", function()
      local names = helpers.child_names(scope_tree.root)
      assert.is_true(vim.tbl_contains(names, "converStrToInt"))
      assert.is_true(vim.tbl_contains(names, "NewMyStruct"))
      assert.is_true(vim.tbl_contains(names, "HandleRequest"))
      assert.is_true(vim.tbl_contains(names, "ProcessItems"))
      assert.is_true(vim.tbl_contains(names, "RunWithCallback"))
      assert.is_true(vim.tbl_contains(names, "main"))
    end)

    it("HandleRequest is a method", function()
      local nodes = helpers.find_by_name(scope_tree.root, "HandleRequest")
      assert.are.equal(1, #nodes)
      assert.are.equal("method", nodes[1].kind)
    end)

    it("HandleRequest has children (if + for blocks)", function()
      local nodes = helpers.find_by_name(scope_tree.root, "HandleRequest")
      assert.is_true(#nodes[1].children > 0)
      local kinds = {}
      for _, child in ipairs(nodes[1].children) do
        kinds[child.kind] = true
      end
      assert.is_truthy(kinds["block"], "expected block children in HandleRequest")
    end)

    it("has nested scopes: if inside for inside HandleRequest", function()
      local handle = helpers.find_by_name(scope_tree.root, "HandleRequest")[1]
      -- Find the for loop inside HandleRequest
      local for_nodes = helpers.find_by_name(handle, "for")
      assert.is_true(#for_nodes > 0, "expected a for loop inside HandleRequest")
      -- Find if statements inside the for loop
      local if_nodes = helpers.find_by_name(for_nodes[1], "if")
      assert.is_true(#if_nodes > 0, "expected if statements inside for loop")
    end)

    it("type_declaration for MyStruct contains field_declaration children", function()
      local my_struct = helpers.find_by_name(scope_tree.root, "MyStruct")[1]
      assert.is_truthy(my_struct, "expected MyStruct node")
      assert.are.equal("type", my_struct.kind)
      local field_names = helpers.child_names(my_struct)
      assert.is_true(vim.tbl_contains(field_names, "Name"))
      assert.is_true(vim.tbl_contains(field_names, "Count"))
    end)

    -- it("func_literal inside RunWithCallback exists with name [anonymous]", function()
    --   local run = helpers.find_by_name(scope_tree.root, "RunWithCallback")[1]
    --   assert.is_truthy(run)
    --   local anon = helpers.find_by_name(run, "[anonymous]")
    --   assert.is_true(#anon > 0, "expected anonymous function inside RunWithCallback")
    --   assert.are.equal("function", anon[1].kind)
    -- end)

    it("parent back-references are correct at every level", function()
      -- Root's parent should be nil
      assert.is_nil(scope_tree.root.parent)
      for _, child in ipairs(scope_tree.root.children) do
        helpers.check_parents(child, scope_tree.root)
      end
    end)

    it("all nodes have valid ranges", function()
      helpers.check_ranges(scope_tree.root)
    end)

    it("kind values match kind_map", function()
      local lang_config = require("scopes.lang_config")
      local go_lang = lang_config.build(require("scopes.languages.go"))
      local valid_kinds = { module = true }
      for _, kind in pairs(go_lang.kind_map) do
        valid_kinds[kind] = true
      end
      -- Also allow "block" for ERROR nodes
      valid_kinds["block"] = true

      local function check_kinds(node)
        assert.is_true(valid_kinds[node.kind], "unexpected kind '" .. node.kind .. "' on node '" .. node.name .. "'")
        for _, child in ipairs(node.children) do
          check_kinds(child)
        end
      end
      check_kinds(scope_tree.root)
    end)

    it("import_declaration contains import_spec children", function()
      local imports = helpers.find_by_name(scope_tree.root, "import")[1]
      assert.is_truthy(imports, "expected import node")
      assert.are.equal("block", imports.kind)
      local import_names = helpers.child_names(imports)
      assert.is_true(vim.tbl_contains(import_names, "fmt"))
      assert.is_true(vim.tbl_contains(import_names, "strconv"))
    end)

    it("const MaxRetries is a const symbol", function()
      local nodes = helpers.find_by_name(scope_tree.root, "MaxRetries")
      assert.are.equal(1, #nodes)
      assert.are.equal("const", nodes[1].kind)
    end)

    it("var DefaultName is a variable symbol", function()
      local nodes = helpers.find_by_name(scope_tree.root, "DefaultName")
      assert.are.equal(1, #nodes)
      assert.are.equal("variable", nodes[1].kind)
    end)
  end)

  describe("build() with Lua fixture", function()
    local scope_tree
    local bufnr

    before_each(function()
      bufnr = helpers.make_buf("tests/fixtures/sample.lua", "lua")
      scope_tree = ts_backend.build(bufnr)
    end)

    after_each(function()
      helpers.delete_buf(bufnr)
    end)

    it("returns a ScopeTree with source set to treesitter", function()
      assert.is_truthy(scope_tree)
      assert.are.equal("treesitter", scope_tree.source)
    end)

    it("returns a ScopeTree with lang set to lua", function()
      assert.are.equal("lua", scope_tree.lang)
    end)

    it("root has top-level children", function()
      assert.is_true(#scope_tree.root.children > 0)
    end)

    it("finds expected function declarations", function()
      local names = helpers.child_names(scope_tree.root)
      assert.is_true(vim.tbl_contains(names, "M.new"))
      assert.is_true(vim.tbl_contains(names, "M.process"))
      assert.is_true(vim.tbl_contains(names, "M._transform"))
      assert.is_true(vim.tbl_contains(names, "M.each"))
      assert.is_true(vim.tbl_contains(names, "M.map"))
      assert.is_true(vim.tbl_contains(names, "setup_defaults"))
      assert.is_true(vim.tbl_contains(names, "M.init"))
    end)

    it("M.process has nested children (if, for)", function()
      local process = helpers.find_by_name(scope_tree.root, "M.process")[1]
      assert.is_truthy(process)
      assert.is_true(#process.children > 0)
      local has_if = #helpers.find_by_name(process, "if") > 0
      local has_for = #helpers.find_by_name(process, "for") > 0
      assert.is_true(has_if, "expected if blocks inside M.process")
      assert.is_true(has_for, "expected for block inside M.process")
    end)

    it("setup_defaults is a function_declaration", function()
      local nodes = helpers.find_by_name(scope_tree.root, "setup_defaults")
      assert.are.equal(1, #nodes)
      assert.are.equal("function", nodes[1].kind)
    end)

    it("anonymous function_definition inside M.init exists", function()
      local init = helpers.find_by_name(scope_tree.root, "M.init")[1]
      assert.is_truthy(init)
      local anon = helpers.find_by_name(init, "[anonymous]")
      assert.is_true(#anon > 0, "expected anonymous function inside M.init")
    end)

    it("parent back-references are correct", function()
      assert.is_nil(scope_tree.root.parent)
      for _, child in ipairs(scope_tree.root.children) do
        helpers.check_parents(child, scope_tree.root)
      end
    end)

    it("all nodes have valid ranges", function()
      helpers.check_ranges(scope_tree.root)
    end)
  end)

  describe("build() error handling", function()
    it("returns nil for buffer with no treesitter parser", function()
      local bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "some text" })
      -- Don't set a filetype that has a parser
      vim.api.nvim_set_option_value("filetype", "unknown_filetype_xyz", { buf = bufnr })

      local result = ts_backend.build(bufnr)
      assert.is_nil(result)

      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it("returns root with no children for empty buffer", function()
      local bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "" })
      vim.api.nvim_set_option_value("filetype", "go", { buf = bufnr })
      vim.treesitter.start(bufnr, "go")
      vim.treesitter.get_parser(bufnr, "go"):parse()

      local result = ts_backend.build(bufnr)
      assert.is_truthy(result)
      assert.are.equal(0, #result.root.children)

      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

  end)
end)
