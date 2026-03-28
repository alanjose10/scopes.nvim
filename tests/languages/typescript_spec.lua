local lang_config = require("scopes.lang_config")
local typescript = lang_config.build(require("scopes.languages.typescript"))
local helpers = require("tests.helpers")

describe("languages.typescript", function()
  describe("scope_types", function()
    it("contains function_declaration", function()
      assert.is_true(vim.tbl_contains(typescript.scope_types, "function_declaration"))
    end)

    it("contains arrow_function", function()
      assert.is_true(vim.tbl_contains(typescript.scope_types, "arrow_function"))
    end)

    it("contains class_declaration", function()
      assert.is_true(vim.tbl_contains(typescript.scope_types, "class_declaration"))
    end)

    it("contains method_definition", function()
      assert.is_true(vim.tbl_contains(typescript.scope_types, "method_definition"))
    end)

    it("contains interface_declaration", function()
      assert.is_true(vim.tbl_contains(typescript.scope_types, "interface_declaration"))
    end)

    it("contains if_statement", function()
      assert.is_true(vim.tbl_contains(typescript.scope_types, "if_statement"))
    end)

    it("contains for_statement", function()
      assert.is_true(vim.tbl_contains(typescript.scope_types, "for_statement"))
    end)
  end)

  describe("symbol_types", function()
    it("contains variable_declarator", function()
      assert.is_true(vim.tbl_contains(typescript.symbol_types, "variable_declarator"))
    end)

    it("contains property_signature", function()
      assert.is_true(vim.tbl_contains(typescript.symbol_types, "property_signature"))
    end)

    it("contains type_alias_declaration", function()
      assert.is_true(vim.tbl_contains(typescript.symbol_types, "type_alias_declaration"))
    end)
  end)

  describe("no overlap between scope_types and symbol_types", function()
    it("has no types in both lists", function()
      for _, st in ipairs(typescript.scope_types) do
        assert.is_false(
          vim.tbl_contains(typescript.symbol_types, st),
          st .. " is in both scope_types and symbol_types"
        )
      end
    end)
  end)

  describe("kind_map", function()
    it("is a table", function()
      assert.are.equal("table", type(typescript.kind_map))
    end)

    it("has an entry for every scope_type", function()
      for _, st in ipairs(typescript.scope_types) do
        assert.is_truthy(typescript.kind_map[st], "missing kind_map entry for scope_type: " .. st)
      end
    end)

    it("has an entry for every symbol_type", function()
      for _, st in ipairs(typescript.symbol_types) do
        assert.is_truthy(typescript.kind_map[st], "missing kind_map entry for symbol_type: " .. st)
      end
    end)

    it("all values are valid kind strings", function()
      for node_type, kind in pairs(typescript.kind_map) do
        assert.is_true(
          helpers.valid_kinds[kind],
          "invalid kind '" .. kind .. "' for node type '" .. node_type .. "'"
        )
      end
    end)
  end)

  describe("node_types", function()
    it("is a non-empty table", function()
      assert.are.equal("table", type(typescript.node_types))
      local count = 0
      for _ in pairs(typescript.node_types) do
        count = count + 1
      end
      assert.is_true(count > 0)
    end)

    it("every entry has kind (string) and is_scope (boolean)", function()
      for node_type, info in pairs(typescript.node_types) do
        assert.are.equal("string", type(info.kind), "kind missing or not string for " .. node_type)
        assert.are.equal("boolean", type(info.is_scope), "is_scope missing or not boolean for " .. node_type)
      end
    end)

    it("derived scope_types matches entries where is_scope == true", function()
      for node_type, info in pairs(typescript.node_types) do
        if info.is_scope then
          assert.is_true(
            vim.tbl_contains(typescript.scope_types, node_type),
            node_type .. " should be in scope_types"
          )
        else
          assert.is_false(
            vim.tbl_contains(typescript.scope_types, node_type),
            node_type .. " should not be in scope_types"
          )
        end
      end
    end)
  end)

  describe("structural checks", function()
    it("passes all structural invariants", function()
      helpers.assert_valid_lang_config(typescript)
    end)
  end)

  describe("get_name", function()
    local bufnr
    local parser_ok = pcall(vim.treesitter.language.inspect, "typescript")

    before_each(function()
      if not parser_ok then
        return
      end
      bufnr = helpers.make_buf("tests/fixtures/sample.ts", "typescript")
    end)

    after_each(function()
      helpers.delete_buf(bufnr)
    end)

    local function get_root()
      local parser = vim.treesitter.get_parser(bufnr, "typescript")
      local tree = parser:parse()[1]
      return tree:root()
    end

    it("extracts function_declaration names", function()
      if not parser_ok then
        pending("typescript treesitter parser not installed")
        return
      end
      local root = get_root()
      local nodes = helpers.find_ts_nodes(root, "function_declaration")
      local names = {}
      for _, node in ipairs(nodes) do
        table.insert(names, typescript.get_name(node, bufnr))
      end
      assert.is_true(vim.tbl_contains(names, "greet"), "expected 'greet' in function_declaration names")
      assert.is_true(vim.tbl_contains(names, "check"), "expected 'check' in function_declaration names")
    end)

    it("returns '[anonymous]' for arrow_function", function()
      if not parser_ok then
        pending("typescript treesitter parser not installed")
        return
      end
      local root = get_root()
      local nodes = helpers.find_ts_nodes(root, "arrow_function")
      assert.is_true(#nodes > 0, "expected at least one arrow_function")
      assert.are.equal("[anonymous]", typescript.get_name(nodes[1], bufnr))
    end)

    it("extracts class_declaration names", function()
      if not parser_ok then
        pending("typescript treesitter parser not installed")
        return
      end
      local root = get_root()
      local nodes = helpers.find_ts_nodes(root, "class_declaration")
      local names = {}
      for _, node in ipairs(nodes) do
        table.insert(names, typescript.get_name(node, bufnr))
      end
      assert.is_true(vim.tbl_contains(names, "Animal"), "expected 'Animal' in class_declaration names")
    end)

    it("extracts method_definition names", function()
      if not parser_ok then
        pending("typescript treesitter parser not installed")
        return
      end
      local root = get_root()
      local nodes = helpers.find_ts_nodes(root, "method_definition")
      local names = {}
      for _, node in ipairs(nodes) do
        table.insert(names, typescript.get_name(node, bufnr))
      end
      assert.is_true(vim.tbl_contains(names, "speak"), "expected 'speak' in method_definition names")
    end)

    it("extracts interface_declaration names", function()
      if not parser_ok then
        pending("typescript treesitter parser not installed")
        return
      end
      local root = get_root()
      local nodes = helpers.find_ts_nodes(root, "interface_declaration")
      local names = {}
      for _, node in ipairs(nodes) do
        table.insert(names, typescript.get_name(node, bufnr))
      end
      assert.is_true(vim.tbl_contains(names, "Shape"), "expected 'Shape' in interface_declaration names")
    end)

    it("returns 'if' for if_statement", function()
      if not parser_ok then
        pending("typescript treesitter parser not installed")
        return
      end
      local root = get_root()
      local nodes = helpers.find_ts_nodes(root, "if_statement")
      assert.is_true(#nodes > 0, "expected at least one if_statement")
      assert.are.equal("if", typescript.get_name(nodes[1], bufnr))
    end)

    it("returns 'for' for for_statement", function()
      if not parser_ok then
        pending("typescript treesitter parser not installed")
        return
      end
      local root = get_root()
      local nodes = helpers.find_ts_nodes(root, "for_statement")
      assert.is_true(#nodes > 0, "expected at least one for_statement")
      assert.are.equal("for", typescript.get_name(nodes[1], bufnr))
    end)

    it("extracts variable_declarator names", function()
      if not parser_ok then
        pending("typescript treesitter parser not installed")
        return
      end
      local root = get_root()
      local nodes = helpers.find_ts_nodes(root, "variable_declarator")
      local names = {}
      for _, node in ipairs(nodes) do
        table.insert(names, typescript.get_name(node, bufnr))
      end
      assert.is_true(vim.tbl_contains(names, "MAX_SIZE"), "expected 'MAX_SIZE' in variable_declarator names")
      assert.is_true(vim.tbl_contains(names, "defaultName"), "expected 'defaultName' in variable_declarator names")
      assert.is_true(vim.tbl_contains(names, "add"), "expected 'add' in variable_declarator names")
    end)

    it("extracts property_signature names", function()
      if not parser_ok then
        pending("typescript treesitter parser not installed")
        return
      end
      local root = get_root()
      local nodes = helpers.find_ts_nodes(root, "property_signature")
      local names = {}
      for _, node in ipairs(nodes) do
        table.insert(names, typescript.get_name(node, bufnr))
      end
      assert.is_true(vim.tbl_contains(names, "color"), "expected 'color' in property_signature names")
    end)

    it("extracts type_alias_declaration names", function()
      if not parser_ok then
        pending("typescript treesitter parser not installed")
        return
      end
      local root = get_root()
      local nodes = helpers.find_ts_nodes(root, "type_alias_declaration")
      local names = {}
      for _, node in ipairs(nodes) do
        table.insert(names, typescript.get_name(node, bufnr))
      end
      assert.is_true(vim.tbl_contains(names, "Point"), "expected 'Point' in type_alias_declaration names")
    end)
  end)

  describe("get_name edge cases", function()
    local bufnr
    local parser_ok = pcall(vim.treesitter.language.inspect, "typescript")

    after_each(function()
      helpers.delete_buf(bufnr)
    end)

    local function parse_ts(code)
      local root
      root, bufnr = helpers.parse_code(code, "typescript")
      return root
    end

    it("returns node type string for unrecognized node types", function()
      if not parser_ok then
        pending("typescript treesitter parser not installed")
        return
      end
      local root = parse_ts("const x = 1;\n")
      -- root is the "program" node, which is not in the typescript node_types table
      assert.are.equal("program", typescript.get_name(root, bufnr))
    end)

    it("does not crash on syntax error nodes", function()
      if not parser_ok then
        pending("typescript treesitter parser not installed")
        return
      end
      local root = parse_ts("function (\n")
      local nodes = helpers.find_ts_nodes(root, "ERROR")
      assert.is_true(#nodes > 0, "expected at least one ERROR node")
      assert.are.equal("ERROR", typescript.get_name(nodes[1], bufnr))
    end)

    it("returns '[anonymous]' for an arrow function parsed inline", function()
      if not parser_ok then
        pending("typescript treesitter parser not installed")
        return
      end
      local root = parse_ts("const fn = () => { return 1; };\n")
      local nodes = helpers.find_ts_nodes(root, "arrow_function")
      assert.is_true(#nodes > 0, "expected at least one arrow_function")
      assert.are.equal("[anonymous]", typescript.get_name(nodes[1], bufnr))
    end)
  end)
end)
