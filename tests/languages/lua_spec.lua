local lua_lang = require("scopes.languages.lua")

describe("languages.lua", function()
  describe("scope_types", function()
    it("contains function_declaration", function()
      assert.is_true(vim.tbl_contains(lua_lang.scope_types, "function_declaration"))
    end)

    it("contains function_definition", function()
      assert.is_true(vim.tbl_contains(lua_lang.scope_types, "function_definition"))
    end)

    it("contains if_statement", function()
      assert.is_true(vim.tbl_contains(lua_lang.scope_types, "if_statement"))
    end)

    it("contains for_statement", function()
      assert.is_true(vim.tbl_contains(lua_lang.scope_types, "for_statement"))
    end)

    it("contains while_statement", function()
      assert.is_true(vim.tbl_contains(lua_lang.scope_types, "while_statement"))
    end)

    it("contains do_statement", function()
      assert.is_true(vim.tbl_contains(lua_lang.scope_types, "do_statement"))
    end)
  end)

  describe("symbol_types", function()
    it("contains assignment_statement", function()
      assert.is_true(vim.tbl_contains(lua_lang.symbol_types, "assignment_statement"))
    end)

    it("contains variable_declaration", function()
      assert.is_true(vim.tbl_contains(lua_lang.symbol_types, "variable_declaration"))
    end)
  end)

  describe("no overlap between scope_types and symbol_types", function()
    it("has no types in both lists", function()
      for _, st in ipairs(lua_lang.scope_types) do
        assert.is_false(
          vim.tbl_contains(lua_lang.symbol_types, st),
          st .. " is in both scope_types and symbol_types"
        )
      end
    end)
  end)

  describe("structural checks", function()
    it("scope_types is non-empty", function()
      assert.is_true(#lua_lang.scope_types > 0)
    end)

    it("symbol_types is non-empty", function()
      assert.is_true(#lua_lang.symbol_types > 0)
    end)

    it("get_name is a function", function()
      assert.are.equal("function", type(lua_lang.get_name))
    end)

    it("all scope_types entries are strings", function()
      for _, st in ipairs(lua_lang.scope_types) do
        assert.are.equal("string", type(st))
      end
    end)

    it("all symbol_types entries are strings", function()
      for _, st in ipairs(lua_lang.symbol_types) do
        assert.are.equal("string", type(st))
      end
    end)
  end)

  describe("get_name", function()
    local bufnr

    before_each(function()
      bufnr = vim.api.nvim_create_buf(false, true)
      local lines = vim.fn.readfile("tests/fixtures/sample.lua")
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
      vim.api.nvim_set_option_value("filetype", "lua", { buf = bufnr })
      vim.treesitter.start(bufnr, "lua")
      vim.treesitter.get_parser(bufnr, "lua"):parse()
    end)

    after_each(function()
      if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
        vim.api.nvim_buf_delete(bufnr, { force = true })
      end
    end)

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
      local parser = vim.treesitter.get_parser(bufnr, "lua")
      local tree = parser:parse()[1]
      return tree:root()
    end

    it("extracts function_declaration names", function()
      local root = get_root()
      local nodes = find_nodes(root, "function_declaration")
      local names = {}
      for _, node in ipairs(nodes) do
        table.insert(names, lua_lang.get_name(node, bufnr))
      end
      -- sample.lua has: M.new, M.process, M._transform, M.each, M.map, setup_defaults, M.init
      assert.is_true(vim.tbl_contains(names, "M.new"))
      assert.is_true(vim.tbl_contains(names, "M.process"))
      assert.is_true(vim.tbl_contains(names, "M._transform"))
      assert.is_true(vim.tbl_contains(names, "M.each"))
      assert.is_true(vim.tbl_contains(names, "M.map"))
      assert.is_true(vim.tbl_contains(names, "setup_defaults"))
      assert.is_true(vim.tbl_contains(names, "M.init"))
    end)

    it("returns [anonymous] for function_definition", function()
      local root = get_root()
      local nodes = find_nodes(root, "function_definition")
      assert.is_true(#nodes > 0, "expected at least one function_definition")
      assert.are.equal("[anonymous]", lua_lang.get_name(nodes[1], bufnr))
    end)

    it("extracts assignment_statement names", function()
      local root = get_root()
      local nodes = find_nodes(root, "assignment_statement")
      local names = {}
      for _, node in ipairs(nodes) do
        table.insert(names, lua_lang.get_name(node, bufnr))
      end
      -- sample.lua has: M.VERSION = "1.0.0" as an assignment_statement
      assert.is_true(vim.tbl_contains(names, "M.VERSION"))
    end)

    it("extracts variable_declaration names", function()
      local root = get_root()
      local nodes = find_nodes(root, "variable_declaration")
      local names = {}
      for _, node in ipairs(nodes) do
        table.insert(names, lua_lang.get_name(node, bufnr))
      end
      -- sample.lua has: local default_opts, local M = {} etc.
      assert.is_true(#names > 0, "expected at least one variable_declaration")
    end)

    it("returns 'if' for if_statement", function()
      local root = get_root()
      local nodes = find_nodes(root, "if_statement")
      assert.is_true(#nodes > 0, "expected at least one if_statement")
      assert.are.equal("if", lua_lang.get_name(nodes[1], bufnr))
    end)

    it("returns 'for' for for_statement", function()
      local root = get_root()
      local nodes = find_nodes(root, "for_statement")
      assert.is_true(#nodes > 0, "expected at least one for_statement")
      assert.are.equal("for", lua_lang.get_name(nodes[1], bufnr))
    end)
  end)

  describe("get_name edge cases", function()
    local bufnr

    after_each(function()
      if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
        vim.api.nvim_buf_delete(bufnr, { force = true })
      end
    end)

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

    local function parse_lua(code)
      bufnr = vim.api.nvim_create_buf(false, true)
      local lines = vim.split(code, "\n")
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
      vim.api.nvim_set_option_value("filetype", "lua", { buf = bufnr })
      vim.treesitter.start(bufnr, "lua")
      local parser = vim.treesitter.get_parser(bufnr, "lua")
      parser:parse()
      local tree = parser:parse()[1]
      return tree:root()
    end

    it("returns node type string for unrecognized node types", function()
      local root = parse_lua("return {}\n")
      -- chunk is not in scope_types or symbol_types
      assert.are.equal("chunk", root:type())
      assert.are.equal("chunk", lua_lang.get_name(root, bufnr))
    end)

    it("returns node type for comment nodes", function()
      local root = parse_lua("-- a comment\nreturn {}\n")
      local nodes = find_nodes(root, "comment")
      assert.is_true(#nodes > 0, "expected at least one comment")
      assert.are.equal("comment", lua_lang.get_name(nodes[1], bufnr))
    end)

    it("does not crash on syntax error nodes", function()
      local root = parse_lua("function (\n")
      local nodes = find_nodes(root, "ERROR")
      assert.is_true(#nodes > 0, "expected at least one ERROR node")
      assert.are.equal("ERROR", lua_lang.get_name(nodes[1], bufnr))
    end)

    it("extracts method-style function declaration name", function()
      local root = parse_lua("local M = {}\nfunction M:method() end\n")
      local nodes = find_nodes(root, "function_declaration")
      local names = {}
      for _, node in ipairs(nodes) do
        table.insert(names, lua_lang.get_name(node, bufnr))
      end
      assert.is_true(vim.tbl_contains(names, "M:method"))
    end)

    it("returns full variable list from multi-assignment", function()
      local root = parse_lua("a, b = 1, 2\n")
      local nodes = find_nodes(root, "assignment_statement")
      assert.is_true(#nodes > 0)
      assert.are.equal("a, b", lua_lang.get_name(nodes[1], bufnr))
    end)

    it("extracts name from local variable declaration", function()
      local root = parse_lua("local x = 42\n")
      local nodes = find_nodes(root, "variable_declaration")
      assert.is_true(#nodes > 0)
      assert.are.equal("x", lua_lang.get_name(nodes[1], bufnr))
    end)

    it("handles empty file", function()
      local root = parse_lua("\n")
      assert.are.equal("chunk", lua_lang.get_name(root, bufnr))
    end)
  end)
end)
