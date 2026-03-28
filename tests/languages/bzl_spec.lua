local lang_config = require("scopes.lang_config")
local bzl = lang_config.build(require("scopes.languages.bzl"))
local helpers = require("tests.helpers")

describe("languages.bzl", function()
  describe("scope_types", function()
    it("contains function_definition", function()
      assert.is_true(vim.tbl_contains(bzl.scope_types, "function_definition"))
    end)

    it("contains call", function()
      assert.is_true(vim.tbl_contains(bzl.scope_types, "call"))
    end)
  end)

  describe("symbol_types", function()
    it("contains assignment", function()
      assert.is_true(vim.tbl_contains(bzl.symbol_types, "assignment"))
    end)
  end)

  describe("no overlap between scope_types and symbol_types", function()
    it("has no types in both lists", function()
      for _, st in ipairs(bzl.scope_types) do
        assert.is_false(
          vim.tbl_contains(bzl.symbol_types, st),
          st .. " is in both scope_types and symbol_types"
        )
      end
    end)
  end)

  describe("kind_map", function()
    it("is a table", function()
      assert.are.equal("table", type(bzl.kind_map))
    end)

    it("has an entry for every scope_type", function()
      for _, st in ipairs(bzl.scope_types) do
        assert.is_truthy(bzl.kind_map[st], "missing kind_map entry for scope_type: " .. st)
      end
    end)

    it("has an entry for every symbol_type", function()
      for _, st in ipairs(bzl.symbol_types) do
        assert.is_truthy(bzl.kind_map[st], "missing kind_map entry for symbol_type: " .. st)
      end
    end)

    it("all values are valid kind strings", function()
      for node_type, kind in pairs(bzl.kind_map) do
        assert.is_true(
          helpers.valid_kinds[kind],
          "invalid kind '" .. kind .. "' for node type '" .. node_type .. "'"
        )
      end
    end)
  end)

  describe("node_types", function()
    it("is a non-empty table", function()
      assert.are.equal("table", type(bzl.node_types))
      local count = 0
      for _ in pairs(bzl.node_types) do
        count = count + 1
      end
      assert.is_true(count > 0)
    end)

    it("every entry has kind (string) and is_scope (boolean)", function()
      for node_type, info in pairs(bzl.node_types) do
        assert.are.equal("string", type(info.kind), "kind missing or not string for " .. node_type)
        assert.are.equal("boolean", type(info.is_scope), "is_scope missing or not boolean for " .. node_type)
      end
    end)

    it("derived scope_types matches entries where is_scope == true", function()
      for node_type, info in pairs(bzl.node_types) do
        if info.is_scope then
          assert.is_true(
            vim.tbl_contains(bzl.scope_types, node_type),
            node_type .. " should be in scope_types"
          )
        else
          assert.is_false(
            vim.tbl_contains(bzl.scope_types, node_type),
            node_type .. " should not be in scope_types"
          )
        end
      end
    end)
  end)

  describe("structural checks", function()
    it("passes all structural invariants", function()
      helpers.assert_valid_lang_config(bzl)
    end)
  end)

  describe("get_name", function()
    local bufnr
    local parser_ok = pcall(vim.treesitter.language.inspect, "bzl")

    before_each(function()
      if not parser_ok then
        return
      end
      bufnr = helpers.make_buf("tests/fixtures/sample.bzl", "bzl")
    end)

    after_each(function()
      helpers.delete_buf(bufnr)
    end)

    local function get_root()
      local parser = vim.treesitter.get_parser(bufnr, "bzl")
      local tree = parser:parse()[1]
      return tree:root()
    end

    it("extracts function_definition names", function()
      if not parser_ok then
        pending("bzl treesitter parser not installed")
        return
      end
      local root = get_root()
      local nodes = helpers.find_ts_nodes(root, "function_definition")
      local names = {}
      for _, node in ipairs(nodes) do
        table.insert(names, bzl.get_name(node, bufnr))
      end
      assert.is_true(vim.tbl_contains(names, "make_targets"))
    end)

    it("extracts call names from name keyword argument", function()
      if not parser_ok then
        pending("bzl treesitter parser not installed")
        return
      end
      local root = get_root()
      local nodes = helpers.find_ts_nodes(root, "call")
      local names = {}
      for _, node in ipairs(nodes) do
        table.insert(names, bzl.get_name(node, bufnr))
      end
      assert.is_true(vim.tbl_contains(names, "server"))
      assert.is_true(vim.tbl_contains(names, "auth_lib"))
      assert.is_true(vim.tbl_contains(names, "auth_test"))
    end)

    it("extracts assignment names", function()
      if not parser_ok then
        pending("bzl treesitter parser not installed")
        return
      end
      local root = get_root()
      local nodes = helpers.find_ts_nodes(root, "assignment")
      local names = {}
      for _, node in ipairs(nodes) do
        table.insert(names, bzl.get_name(node, bufnr))
      end
      assert.is_true(vim.tbl_contains(names, "SERVICE_NAME"))
      assert.is_true(vim.tbl_contains(names, "VERSION"))
    end)
  end)

  describe("get_name edge cases", function()
    local bufnr
    local parser_ok = pcall(vim.treesitter.language.inspect, "bzl")

    after_each(function()
      helpers.delete_buf(bufnr)
    end)

    local function parse_bzl(code)
      local root
      root, bufnr = helpers.parse_code(code, "bzl")
      return root
    end

    it("returns function name as fallback when call has no name kwarg", function()
      if not parser_ok then
        pending("bzl treesitter parser not installed")
        return
      end
      local root = parse_bzl('glob(["*.go"])\n')
      local nodes = helpers.find_ts_nodes(root, "call")
      assert.is_true(#nodes > 0, "expected at least one call")
      assert.are.equal("glob", bzl.get_name(nodes[1], bufnr))
    end)

    it("returns node type string for unrecognized node types", function()
      if not parser_ok then
        pending("bzl treesitter parser not installed")
        return
      end
      local root = parse_bzl("x = 1\n")
      assert.are.equal("module", bzl.get_name(root, bufnr))
    end)

    it("does not crash on syntax error nodes", function()
      if not parser_ok then
        pending("bzl treesitter parser not installed")
        return
      end
      local root = parse_bzl("def (\n")
      local nodes = helpers.find_ts_nodes(root, "ERROR")
      assert.is_true(#nodes > 0, "expected at least one ERROR node")
      assert.are.equal("ERROR", bzl.get_name(nodes[1], bufnr))
    end)
  end)
end)
