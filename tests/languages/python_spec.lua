local lang_config = require("scopes.lang_config")
local python = lang_config.build(require("scopes.languages.python"))
local helpers = require("tests.helpers")

describe("languages.python", function()
  describe("scope_types", function()
    it("contains function_definition", function()
      assert.is_true(vim.tbl_contains(python.scope_types, "function_definition"))
    end)

    it("contains class_definition", function()
      assert.is_true(vim.tbl_contains(python.scope_types, "class_definition"))
    end)

    it("contains if_statement", function()
      assert.is_true(vim.tbl_contains(python.scope_types, "if_statement"))
    end)

    it("contains for_statement", function()
      assert.is_true(vim.tbl_contains(python.scope_types, "for_statement"))
    end)

    it("contains while_statement", function()
      assert.is_true(vim.tbl_contains(python.scope_types, "while_statement"))
    end)

    it("contains with_statement", function()
      assert.is_true(vim.tbl_contains(python.scope_types, "with_statement"))
    end)
  end)

  describe("symbol_types", function()
    it("contains assignment", function()
      assert.is_true(vim.tbl_contains(python.symbol_types, "assignment"))
    end)

    it("contains import_statement", function()
      assert.is_true(vim.tbl_contains(python.symbol_types, "import_statement"))
    end)

    it("contains import_from_statement", function()
      assert.is_true(vim.tbl_contains(python.symbol_types, "import_from_statement"))
    end)
  end)

  describe("no overlap between scope_types and symbol_types", function()
    it("has no types in both lists", function()
      for _, st in ipairs(python.scope_types) do
        assert.is_false(
          vim.tbl_contains(python.symbol_types, st),
          st .. " is in both scope_types and symbol_types"
        )
      end
    end)
  end)

  describe("kind_map", function()
    it("is a table", function()
      assert.are.equal("table", type(python.kind_map))
    end)

    it("has an entry for every scope_type", function()
      for _, st in ipairs(python.scope_types) do
        assert.is_truthy(python.kind_map[st], "missing kind_map entry for scope_type: " .. st)
      end
    end)

    it("has an entry for every symbol_type", function()
      for _, st in ipairs(python.symbol_types) do
        assert.is_truthy(python.kind_map[st], "missing kind_map entry for symbol_type: " .. st)
      end
    end)

    it("all values are valid kind strings", function()
      for node_type, kind in pairs(python.kind_map) do
        assert.is_true(
          helpers.valid_kinds[kind],
          "invalid kind '" .. kind .. "' for node type '" .. node_type .. "'"
        )
      end
    end)
  end)

  describe("node_types", function()
    it("is a non-empty table", function()
      assert.are.equal("table", type(python.node_types))
      local count = 0
      for _ in pairs(python.node_types) do
        count = count + 1
      end
      assert.is_true(count > 0)
    end)

    it("every entry has kind (string) and is_scope (boolean)", function()
      for node_type, info in pairs(python.node_types) do
        assert.are.equal("string", type(info.kind), "kind missing or not string for " .. node_type)
        assert.are.equal("boolean", type(info.is_scope), "is_scope missing or not boolean for " .. node_type)
      end
    end)

    it("derived scope_types matches entries where is_scope == true", function()
      for node_type, info in pairs(python.node_types) do
        if info.is_scope then
          assert.is_true(
            vim.tbl_contains(python.scope_types, node_type),
            node_type .. " should be in scope_types"
          )
        else
          assert.is_false(
            vim.tbl_contains(python.scope_types, node_type),
            node_type .. " should not be in scope_types"
          )
        end
      end
    end)
  end)

  describe("structural checks", function()
    it("passes all structural invariants", function()
      helpers.assert_valid_lang_config(python)
    end)
  end)

  describe("get_name", function()
    local bufnr

    before_each(function()
      bufnr = helpers.make_buf("tests/fixtures/sample.py", "python")
    end)

    after_each(function()
      helpers.delete_buf(bufnr)
    end)

    local function get_root()
      local parser = vim.treesitter.get_parser(bufnr, "python")
      local tree = parser:parse()[1]
      return tree:root()
    end

    it("extracts function_definition names", function()
      local root = get_root()
      local nodes = helpers.find_ts_nodes(root, "function_definition")
      local names = {}
      for _, node in ipairs(nodes) do
        table.insert(names, python.get_name(node, bufnr))
      end
      assert.is_true(vim.tbl_contains(names, "main"))
      assert.is_true(vim.tbl_contains(names, "process_animals"))
      assert.is_true(vim.tbl_contains(names, "__init__"))
      assert.is_true(vim.tbl_contains(names, "speak"))
      assert.is_true(vim.tbl_contains(names, "fetch"))
    end)

    it("extracts class_definition names", function()
      local root = get_root()
      local nodes = helpers.find_ts_nodes(root, "class_definition")
      local names = {}
      for _, node in ipairs(nodes) do
        table.insert(names, python.get_name(node, bufnr))
      end
      assert.is_true(vim.tbl_contains(names, "Animal"))
      assert.is_true(vim.tbl_contains(names, "Dog"))
    end)

    it("returns 'if' for if_statement", function()
      local root = get_root()
      local nodes = helpers.find_ts_nodes(root, "if_statement")
      assert.is_true(#nodes > 0, "expected at least one if_statement")
      assert.are.equal("if", python.get_name(nodes[1], bufnr))
    end)

    it("returns 'for' for for_statement", function()
      local root = get_root()
      local nodes = helpers.find_ts_nodes(root, "for_statement")
      assert.is_true(#nodes > 0, "expected at least one for_statement")
      assert.are.equal("for", python.get_name(nodes[1], bufnr))
    end)

    it("returns 'with' for with_statement", function()
      local root = get_root()
      local nodes = helpers.find_ts_nodes(root, "with_statement")
      assert.is_true(#nodes > 0, "expected at least one with_statement")
      assert.are.equal("with", python.get_name(nodes[1], bufnr))
    end)

    it("extracts assignment names", function()
      local root = get_root()
      local nodes = helpers.find_ts_nodes(root, "assignment")
      local names = {}
      for _, node in ipairs(nodes) do
        table.insert(names, python.get_name(node, bufnr))
      end
      assert.is_true(vim.tbl_contains(names, "MAX_SIZE"))
      assert.is_true(vim.tbl_contains(names, "DEFAULT_NAME"))
    end)

    it("extracts import_statement module name", function()
      local root = get_root()
      local nodes = helpers.find_ts_nodes(root, "import_statement")
      local names = {}
      for _, node in ipairs(nodes) do
        table.insert(names, python.get_name(node, bufnr))
      end
      assert.is_true(vim.tbl_contains(names, "os"), "expected 'os' from 'import os'")
      assert.is_true(vim.tbl_contains(names, "sys"), "expected 'sys' from 'import sys as system'")
    end)

    it("extracts import_from_statement module name", function()
      local root = get_root()
      local nodes = helpers.find_ts_nodes(root, "import_from_statement")
      local names = {}
      for _, node in ipairs(nodes) do
        table.insert(names, python.get_name(node, bufnr))
      end
      assert.is_true(vim.tbl_contains(names, "pathlib"), "expected 'pathlib' from 'from pathlib import Path'")
    end)
  end)

  describe("get_name edge cases", function()
    local bufnr

    after_each(function()
      helpers.delete_buf(bufnr)
    end)

    local function parse_py(code)
      local root
      root, bufnr = helpers.parse_code(code, "python")
      return root
    end

    it("returns node type string for unrecognized node types", function()
      local root = parse_py("x = 1\n")
      assert.are.equal("module", python.get_name(root, bufnr))
    end)

    it("does not crash on syntax error nodes", function()
      local root = parse_py("def (\n")
      local nodes = helpers.find_ts_nodes(root, "ERROR")
      assert.is_true(#nodes > 0, "expected at least one ERROR node")
      assert.are.equal("ERROR", python.get_name(nodes[1], bufnr))
    end)

    it("returns 'while' for while_statement", function()
      local root = parse_py("while True:\n  pass\n")
      local nodes = helpers.find_ts_nodes(root, "while_statement")
      assert.is_true(#nodes > 0)
      assert.are.equal("while", python.get_name(nodes[1], bufnr))
    end)

    it("returns module name not alias for aliased import", function()
      local root = parse_py("import numpy as np\n")
      local nodes = helpers.find_ts_nodes(root, "import_statement")
      assert.is_true(#nodes > 0, "expected at least one import_statement")
      assert.are.equal("numpy", python.get_name(nodes[1], bufnr))
    end)

    it("returns all module names joined for multi-name import", function()
      local root = parse_py("import os, sys\n")
      local nodes = helpers.find_ts_nodes(root, "import_statement")
      assert.is_true(#nodes > 0, "expected at least one import_statement")
      assert.are.equal("os, sys", python.get_name(nodes[1], bufnr))
    end)

    it("returns dotted module name for from-import", function()
      local root = parse_py("from os.path import join\n")
      local nodes = helpers.find_ts_nodes(root, "import_from_statement")
      assert.is_true(#nodes > 0, "expected at least one import_from_statement")
      assert.are.equal("os.path", python.get_name(nodes[1], bufnr))
    end)

    it("returns '.' for relative import", function()
      local root = parse_py("from . import something\n")
      local nodes = helpers.find_ts_nodes(root, "import_from_statement")
      assert.is_true(#nodes > 0, "expected at least one import_from_statement")
      assert.are.equal(".", python.get_name(nodes[1], bufnr))
    end)
  end)
end)
