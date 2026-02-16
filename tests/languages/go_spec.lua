local go = require("scopes.languages.go")

describe("languages.go", function()
  describe("scope_types", function()
    it("contains function_declaration", function()
      assert.is_true(vim.tbl_contains(go.scope_types, "function_declaration"))
    end)

    it("contains method_declaration", function()
      assert.is_true(vim.tbl_contains(go.scope_types, "method_declaration"))
    end)

    it("contains func_literal", function()
      assert.is_true(vim.tbl_contains(go.scope_types, "func_literal"))
    end)

    it("contains if_statement", function()
      assert.is_true(vim.tbl_contains(go.scope_types, "if_statement"))
    end)

    it("contains for_statement", function()
      assert.is_true(vim.tbl_contains(go.scope_types, "for_statement"))
    end)

    it("contains select_statement", function()
      assert.is_true(vim.tbl_contains(go.scope_types, "select_statement"))
    end)

    it("contains type_declaration", function()
      assert.is_true(vim.tbl_contains(go.scope_types, "type_declaration"))
    end)

    it("contains import_declaration", function()
      assert.is_true(vim.tbl_contains(go.scope_types, "import_declaration"))
    end)
  end)

  describe("symbol_types", function()
    it("contains var_spec", function()
      assert.is_true(vim.tbl_contains(go.symbol_types, "var_spec"))
    end)

    it("contains const_spec", function()
      assert.is_true(vim.tbl_contains(go.symbol_types, "const_spec"))
    end)

    it("contains short_var_declaration", function()
      assert.is_true(vim.tbl_contains(go.symbol_types, "short_var_declaration"))
    end)

    it("contains field_declaration", function()
      assert.is_true(vim.tbl_contains(go.symbol_types, "field_declaration"))
    end)

    it("contains import_spec", function()
      assert.is_true(vim.tbl_contains(go.symbol_types, "import_spec"))
    end)
  end)

  describe("no overlap between scope_types and symbol_types", function()
    it("has no types in both lists", function()
      for _, st in ipairs(go.scope_types) do
        assert.is_false(
          vim.tbl_contains(go.symbol_types, st),
          st .. " is in both scope_types and symbol_types"
        )
      end
    end)
  end)

  describe("structural checks", function()
    it("scope_types is non-empty", function()
      assert.is_true(#go.scope_types > 0)
    end)

    it("symbol_types is non-empty", function()
      assert.is_true(#go.symbol_types > 0)
    end)

    it("get_name is a function", function()
      assert.are.equal("function", type(go.get_name))
    end)

    it("all scope_types entries are strings", function()
      for _, st in ipairs(go.scope_types) do
        assert.are.equal("string", type(st))
      end
    end)

    it("all symbol_types entries are strings", function()
      for _, st in ipairs(go.symbol_types) do
        assert.are.equal("string", type(st))
      end
    end)
  end)

  describe("get_name", function()
    local bufnr

    before_each(function()
      bufnr = vim.api.nvim_create_buf(false, true)
      local lines = vim.fn.readfile("tests/fixtures/sample.go")
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
      vim.api.nvim_set_option_value("filetype", "go", { buf = bufnr })
      vim.treesitter.start(bufnr, "go")
      -- Allow parser to complete
      vim.treesitter.get_parser(bufnr, "go"):parse()
    end)

    after_each(function()
      if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
        vim.api.nvim_buf_delete(bufnr, { force = true })
      end
    end)

    --- Helper: find first TS node of a given type in the tree
    local function find_nodes(root, node_type)
      local found = {}
      local function walk(node)
        if node:type() == node_type then
          table.insert(found, node)
        end
        for child in node:iter_children() do
          walk(child)
        end
      end
      walk(root)
      return found
    end

    local function get_root()
      local parser = vim.treesitter.get_parser(bufnr, "go")
      local tree = parser:parse()[1]
      return tree:root()
    end

    it("extracts function_declaration names", function()
      local root = get_root()
      local nodes = find_nodes(root, "function_declaration")
      local names = {}
      for _, node in ipairs(nodes) do
        table.insert(names, go.get_name(node, bufnr))
      end
      assert.is_true(vim.tbl_contains(names, "NewMyStruct"))
      assert.is_true(vim.tbl_contains(names, "ProcessItems"))
      assert.is_true(vim.tbl_contains(names, "RunWithCallback"))
      assert.is_true(vim.tbl_contains(names, "main"))
    end)

    it("extracts method_declaration names", function()
      local root = get_root()
      local nodes = find_nodes(root, "method_declaration")
      local names = {}
      for _, node in ipairs(nodes) do
        table.insert(names, go.get_name(node, bufnr))
      end
      assert.is_true(vim.tbl_contains(names, "HandleRequest"))
    end)

    it("returns [anonymous] for func_literal", function()
      local root = get_root()
      local nodes = find_nodes(root, "func_literal")
      assert.is_true(#nodes > 0, "expected at least one func_literal")
      assert.are.equal("[anonymous]", go.get_name(nodes[1], bufnr))
    end)

    it("extracts type_declaration names", function()
      local root = get_root()
      local nodes = find_nodes(root, "type_declaration")
      local names = {}
      for _, node in ipairs(nodes) do
        table.insert(names, go.get_name(node, bufnr))
      end
      assert.is_true(vim.tbl_contains(names, "MyStruct"))
    end)

    it("extracts const_spec names", function()
      local root = get_root()
      local nodes = find_nodes(root, "const_spec")
      local names = {}
      for _, node in ipairs(nodes) do
        table.insert(names, go.get_name(node, bufnr))
      end
      assert.is_true(vim.tbl_contains(names, "MaxRetries"))
    end)

    it("extracts var_spec names", function()
      local root = get_root()
      local nodes = find_nodes(root, "var_spec")
      local names = {}
      for _, node in ipairs(nodes) do
        table.insert(names, go.get_name(node, bufnr))
      end
      assert.is_true(vim.tbl_contains(names, "DefaultName"))
    end)

    it("extracts field_declaration names", function()
      local root = get_root()
      local nodes = find_nodes(root, "field_declaration")
      local names = {}
      for _, node in ipairs(nodes) do
        table.insert(names, go.get_name(node, bufnr))
      end
      assert.is_true(vim.tbl_contains(names, "Name"))
      assert.is_true(vim.tbl_contains(names, "Count"))
    end)

    it("returns 'import' for import_declaration", function()
      local root = get_root()
      local nodes = find_nodes(root, "import_declaration")
      assert.is_true(#nodes > 0, "expected at least one import_declaration")
      assert.are.equal("import", go.get_name(nodes[1], bufnr))
    end)

    it("extracts import_spec path names", function()
      local root = get_root()
      local nodes = find_nodes(root, "import_spec")
      local names = {}
      for _, node in ipairs(nodes) do
        table.insert(names, go.get_name(node, bufnr))
      end
      assert.is_true(vim.tbl_contains(names, "fmt"))
      assert.is_true(vim.tbl_contains(names, "strconv"))
    end)

    it("returns 'if' for if_statement", function()
      local root = get_root()
      local nodes = find_nodes(root, "if_statement")
      assert.is_true(#nodes > 0, "expected at least one if_statement")
      assert.are.equal("if", go.get_name(nodes[1], bufnr))
    end)

    it("returns 'for' for for_statement", function()
      local root = get_root()
      local nodes = find_nodes(root, "for_statement")
      assert.is_true(#nodes > 0, "expected at least one for_statement")
      assert.are.equal("for", go.get_name(nodes[1], bufnr))
    end)

    it("extracts short_var_declaration names", function()
      local root = get_root()
      local nodes = find_nodes(root, "short_var_declaration")
      local names = {}
      for _, node in ipairs(nodes) do
        table.insert(names, go.get_name(node, bufnr))
      end
      -- sample.go has several short var declarations (result, callback, s, err, etc.)
      assert.is_true(#names > 0, "expected at least one short_var_declaration")
    end)
  end)

  describe("get_name edge cases", function()
    local bufnr

    after_each(function()
      if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
        vim.api.nvim_buf_delete(bufnr, { force = true })
      end
    end)

    --- Helper: find nodes of a given type
    local function find_nodes(root, node_type)
      local found = {}
      local function walk(node)
        if node:type() == node_type then
          table.insert(found, node)
        end
        for child in node:iter_children() do
          walk(child)
        end
      end
      walk(root)
      return found
    end

    local function parse_go(code)
      bufnr = vim.api.nvim_create_buf(false, true)
      local lines = vim.split(code, "\n")
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
      vim.api.nvim_set_option_value("filetype", "go", { buf = bufnr })
      vim.treesitter.start(bufnr, "go")
      local parser = vim.treesitter.get_parser(bufnr, "go")
      parser:parse()
      local tree = parser:parse()[1]
      return tree:root()
    end

    it("returns node type string for unrecognized node types", function()
      local root = parse_go("package main\n")
      -- source_file is not in scope_types or symbol_types
      assert.are.equal("source_file", go.get_name(root, bufnr))
    end)

    it("returns node type for comment nodes", function()
      local root = parse_go("package main\n// a comment\n")
      local nodes = find_nodes(root, "comment")
      assert.is_true(#nodes > 0, "expected at least one comment")
      assert.are.equal("comment", go.get_name(nodes[1], bufnr))
    end)

    it("does not crash on syntax error nodes", function()
      local root = parse_go("package main\nfunc {\n")
      local nodes = find_nodes(root, "ERROR")
      assert.is_true(#nodes > 0, "expected at least one ERROR node")
      assert.are.equal("ERROR", go.get_name(nodes[1], bufnr))
    end)

    it("returns full variable list from multi-var short_var_declaration", function()
      local root = parse_go("package main\nfunc f() { a, b := 1, 2 }\n")
      local nodes = find_nodes(root, "short_var_declaration")
      assert.is_true(#nodes > 0)
      assert.are.equal("a, b", go.get_name(nodes[1], bufnr))
    end)

    it("extracts individual names from const block", function()
      local root = parse_go("package main\nconst (\n\tA = 1\n\tB = 2\n)\n")
      local nodes = find_nodes(root, "const_spec")
      local names = {}
      for _, node in ipairs(nodes) do
        table.insert(names, go.get_name(node, bufnr))
      end
      assert.is_true(vim.tbl_contains(names, "A"))
      assert.is_true(vim.tbl_contains(names, "B"))
    end)

    it("extracts individual names from var block", function()
      local root = parse_go("package main\nvar (\n\tx = 1\n\ty = 2\n)\n")
      local nodes = find_nodes(root, "var_spec")
      local names = {}
      for _, node in ipairs(nodes) do
        table.insert(names, go.get_name(node, bufnr))
      end
      assert.is_true(vim.tbl_contains(names, "x"))
      assert.is_true(vim.tbl_contains(names, "y"))
    end)

    it("handles empty file with only package clause", function()
      local root = parse_go("package main\n")
      -- Should not crash; root has no scope/symbol children
      assert.are.equal("source_file", go.get_name(root, bufnr))
    end)
  end)
end)
