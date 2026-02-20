local lang_config = require("scopes.lang_config")
local lua_lang = lang_config.build(require("scopes.languages.lua"))
local helpers = require("tests.helpers")

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
        assert.is_false(vim.tbl_contains(lua_lang.symbol_types, st), st .. " is in both scope_types and symbol_types")
      end
    end)
  end)

  describe("kind_map", function()
    it("is a table", function()
      assert.are.equal("table", type(lua_lang.kind_map))
    end)

    it("has an entry for every scope_type", function()
      for _, st in ipairs(lua_lang.scope_types) do
        assert.is_truthy(lua_lang.kind_map[st], "missing kind_map entry for scope_type: " .. st)
      end
    end)

    it("has an entry for every symbol_type", function()
      for _, st in ipairs(lua_lang.symbol_types) do
        assert.is_truthy(lua_lang.kind_map[st], "missing kind_map entry for symbol_type: " .. st)
      end
    end)

    it("all values are valid kind strings", function()
      local valid_kinds = {
        ["function"] = true,
        ["method"] = true,
        ["variable"] = true,
        ["type"] = true,
        ["const"] = true,
        ["block"] = true,
        ["class"] = true,
      }
      for node_type, kind in pairs(lua_lang.kind_map) do
        assert.is_true(valid_kinds[kind], "invalid kind '" .. kind .. "' for node type '" .. node_type .. "'")
      end
    end)
  end)

  describe("node_types", function()
    it("is a non-empty table", function()
      assert.are.equal("table", type(lua_lang.node_types))
      local count = 0
      for _ in pairs(lua_lang.node_types) do
        count = count + 1
      end
      assert.is_true(count > 0)
    end)

    it("every entry has kind (string) and is_scope (boolean)", function()
      for node_type, info in pairs(lua_lang.node_types) do
        assert.are.equal("string", type(info.kind), "kind missing or not string for " .. node_type)
        assert.are.equal("boolean", type(info.is_scope), "is_scope missing or not boolean for " .. node_type)
      end
    end)

    it("all kind values are valid kind strings", function()
      local valid_kinds = {
        ["function"] = true,
        ["method"] = true,
        ["variable"] = true,
        ["type"] = true,
        ["const"] = true,
        ["block"] = true,
        ["class"] = true,
      }
      for node_type, info in pairs(lua_lang.node_types) do
        assert.is_true(valid_kinds[info.kind], "invalid kind '" .. info.kind .. "' for node type '" .. node_type .. "'")
      end
    end)

    it("derived scope_types matches entries where is_scope == true", function()
      for node_type, info in pairs(lua_lang.node_types) do
        if info.is_scope then
          assert.is_true(vim.tbl_contains(lua_lang.scope_types, node_type), node_type .. " should be in scope_types")
        else
          assert.is_false(vim.tbl_contains(lua_lang.scope_types, node_type), node_type .. " should not be in scope_types")
        end
      end
    end)

    it("derived symbol_types matches entries where is_scope == false", function()
      for node_type, info in pairs(lua_lang.node_types) do
        if not info.is_scope then
          assert.is_true(vim.tbl_contains(lua_lang.symbol_types, node_type), node_type .. " should be in symbol_types")
        else
          assert.is_false(vim.tbl_contains(lua_lang.symbol_types, node_type), node_type .. " should not be in symbol_types")
        end
      end
    end)

    it("derived kind_map matches node_types entries", function()
      for node_type, info in pairs(lua_lang.node_types) do
        assert.are.equal(info.kind, lua_lang.kind_map[node_type], "kind_map mismatch for " .. node_type)
      end
    end)
  end)

  describe("structural checks", function()
    it("passes all structural invariants", function()
      helpers.assert_valid_lang_config(lua_lang)
    end)
  end)

  describe("get_name", function()
    local bufnr

    before_each(function()
      bufnr = helpers.make_buf("tests/fixtures/sample.lua", "lua")
    end)

    after_each(function()
      helpers.delete_buf(bufnr)
    end)

    local function get_root()
      local parser = vim.treesitter.get_parser(bufnr, "lua")
      local tree = parser:parse()[1]
      return tree:root()
    end

    it("extracts function_declaration names", function()
      local root = get_root()
      local nodes = helpers.find_ts_nodes(root, "function_declaration")
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
      local nodes = helpers.find_ts_nodes(root, "function_definition")
      assert.is_true(#nodes > 0, "expected at least one function_definition")
      assert.are.equal("[anonymous]", lua_lang.get_name(nodes[1], bufnr))
    end)

    it("extracts assignment_statement names", function()
      local root = get_root()
      local nodes = helpers.find_ts_nodes(root, "assignment_statement")
      local names = {}
      for _, node in ipairs(nodes) do
        table.insert(names, lua_lang.get_name(node, bufnr))
      end
      -- sample.lua has: M.VERSION = "1.0.0" as an assignment_statement
      assert.is_true(vim.tbl_contains(names, "M.VERSION"))
    end)

    it("extracts variable_declaration names", function()
      local root = get_root()
      local nodes = helpers.find_ts_nodes(root, "variable_declaration")
      local names = {}
      for _, node in ipairs(nodes) do
        table.insert(names, lua_lang.get_name(node, bufnr))
      end
      -- sample.lua has: local default_opts, local M = {} etc.
      assert.is_true(#names > 0, "expected at least one variable_declaration")
    end)

    it("returns 'if' for if_statement", function()
      local root = get_root()
      local nodes = helpers.find_ts_nodes(root, "if_statement")
      assert.is_true(#nodes > 0, "expected at least one if_statement")
      assert.are.equal("if", lua_lang.get_name(nodes[1], bufnr))
    end)

    it("returns 'for' for for_statement", function()
      local root = get_root()
      local nodes = helpers.find_ts_nodes(root, "for_statement")
      assert.is_true(#nodes > 0, "expected at least one for_statement")
      assert.are.equal("for", lua_lang.get_name(nodes[1], bufnr))
    end)
  end)

  describe("get_name edge cases", function()
    local bufnr

    after_each(function()
      helpers.delete_buf(bufnr)
    end)

    local function parse_lua(code)
      local root
      root, bufnr = helpers.parse_code(code, "lua")
      return root
    end

    it("returns node type string for unrecognized node types", function()
      local root = parse_lua("return {}\n")
      -- chunk is not in scope_types or symbol_types
      assert.are.equal("chunk", root:type())
      assert.are.equal("chunk", lua_lang.get_name(root, bufnr))
    end)

    it("returns node type for comment nodes", function()
      local root = parse_lua("-- a comment\nreturn {}\n")
      local nodes = helpers.find_ts_nodes(root, "comment")
      assert.is_true(#nodes > 0, "expected at least one comment")
      assert.are.equal("comment", lua_lang.get_name(nodes[1], bufnr))
    end)

    it("does not crash on syntax error nodes", function()
      local root = parse_lua("function (\n")
      local nodes = helpers.find_ts_nodes(root, "ERROR")
      assert.is_true(#nodes > 0, "expected at least one ERROR node")
      assert.are.equal("ERROR", lua_lang.get_name(nodes[1], bufnr))
    end)

    it("extracts method-style function declaration name", function()
      local root = parse_lua("local M = {}\nfunction M:method() end\n")
      local nodes = helpers.find_ts_nodes(root, "function_declaration")
      local names = {}
      for _, node in ipairs(nodes) do
        table.insert(names, lua_lang.get_name(node, bufnr))
      end
      assert.is_true(vim.tbl_contains(names, "M:method"))
    end)

    it("returns full variable list from multi-assignment", function()
      local root = parse_lua("a, b = 1, 2\n")
      local nodes = helpers.find_ts_nodes(root, "assignment_statement")
      assert.is_true(#nodes > 0)
      assert.are.equal("a, b", lua_lang.get_name(nodes[1], bufnr))
    end)

    it("extracts name from local variable declaration", function()
      local root = parse_lua("local x = 42\n")
      local nodes = helpers.find_ts_nodes(root, "variable_declaration")
      assert.is_true(#nodes > 0)
      assert.are.equal("x", lua_lang.get_name(nodes[1], bufnr))
    end)

    it("handles empty file", function()
      local root = parse_lua("\n")
      assert.are.equal("chunk", lua_lang.get_name(root, bufnr))
    end)
  end)
end)
