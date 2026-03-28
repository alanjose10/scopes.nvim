local lang_config = require("scopes.lang_config")
local json = lang_config.build(require("scopes.languages.json"))
local helpers = require("tests.helpers")

describe("languages.json", function()
  describe("scope_types", function()
    it("contains pair", function()
      assert.is_true(vim.tbl_contains(json.scope_types, "pair"))
    end)
  end)

  describe("symbol_types", function()
    it("is empty (all JSON nodes are scopes)", function()
      assert.are.equal(0, #json.symbol_types)
    end)
  end)

  describe("no overlap between scope_types and symbol_types", function()
    it("has no types in both lists", function()
      for _, st in ipairs(json.scope_types) do
        assert.is_false(
          vim.tbl_contains(json.symbol_types, st),
          st .. " is in both scope_types and symbol_types"
        )
      end
    end)
  end)

  describe("kind_map", function()
    it("is a table", function()
      assert.are.equal("table", type(json.kind_map))
    end)

    it("has an entry for every scope_type", function()
      for _, st in ipairs(json.scope_types) do
        assert.is_truthy(json.kind_map[st], "missing kind_map entry for scope_type: " .. st)
      end
    end)

    it("all values are valid kind strings", function()
      for node_type, kind in pairs(json.kind_map) do
        assert.is_true(
          helpers.valid_kinds[kind],
          "invalid kind '" .. kind .. "' for node type '" .. node_type .. "'"
        )
      end
    end)
  end)

  describe("node_types", function()
    it("is a non-empty table", function()
      assert.are.equal("table", type(json.node_types))
      local count = 0
      for _ in pairs(json.node_types) do
        count = count + 1
      end
      assert.is_true(count > 0)
    end)

    it("every entry has kind (string) and is_scope (boolean)", function()
      for node_type, info in pairs(json.node_types) do
        assert.are.equal("string", type(info.kind), "kind missing or not string for " .. node_type)
        assert.are.equal("boolean", type(info.is_scope), "is_scope missing or not boolean for " .. node_type)
      end
    end)

    it("derived scope_types matches entries where is_scope == true", function()
      for node_type, info in pairs(json.node_types) do
        if info.is_scope then
          assert.is_true(
            vim.tbl_contains(json.scope_types, node_type),
            node_type .. " should be in scope_types"
          )
        end
      end
    end)
  end)

  describe("structural checks", function()
    it("passes all structural invariants", function()
      helpers.assert_valid_lang_config(json)
    end)
  end)

  describe("get_name", function()
    local bufnr

    before_each(function()
      bufnr = helpers.make_buf("tests/fixtures/sample.json", "json")
    end)

    after_each(function()
      helpers.delete_buf(bufnr)
    end)

    local function get_root()
      local parser = vim.treesitter.get_parser(bufnr, "json")
      local tree = parser:parse()[1]
      return tree:root()
    end

    it("extracts top-level key names from pair nodes", function()
      local root = get_root()
      local nodes = helpers.find_ts_nodes(root, "pair")
      local names = {}
      for _, node in ipairs(nodes) do
        table.insert(names, json.get_name(node, bufnr))
      end
      assert.is_true(vim.tbl_contains(names, "name"))
      assert.is_true(vim.tbl_contains(names, "version"))
      assert.is_true(vim.tbl_contains(names, "scripts"))
      assert.is_true(vim.tbl_contains(names, "dependencies"))
      assert.is_true(vim.tbl_contains(names, "config"))
    end)

    it("extracts nested key names", function()
      local root = get_root()
      local nodes = helpers.find_ts_nodes(root, "pair")
      local names = {}
      for _, node in ipairs(nodes) do
        table.insert(names, json.get_name(node, bufnr))
      end
      assert.is_true(vim.tbl_contains(names, "build"))
      assert.is_true(vim.tbl_contains(names, "test"))
      assert.is_true(vim.tbl_contains(names, "database"))
      assert.is_true(vim.tbl_contains(names, "server"))
      assert.is_true(vim.tbl_contains(names, "host"))
    end)
  end)

  describe("get_name edge cases", function()
    local bufnr

    after_each(function()
      helpers.delete_buf(bufnr)
    end)

    local function parse_json(code)
      local root
      root, bufnr = helpers.parse_code(code, "json")
      return root
    end

    it("returns node type string for unrecognized node types", function()
      local root = parse_json('{"key": "value"}\n')
      -- root is 'document', not in node_types
      assert.are.equal("document", json.get_name(root, bufnr))
    end)

    it("strips quotes from key names", function()
      local root = parse_json('{"my-key": 42}\n')
      local nodes = helpers.find_ts_nodes(root, "pair")
      assert.is_true(#nodes > 0, "expected at least one pair")
      assert.are.equal("my-key", json.get_name(nodes[1], bufnr))
    end)

    it("extracts keys from deeply nested objects", function()
      local root = parse_json('{"a": {"b": {"c": 1}}}\n')
      local nodes = helpers.find_ts_nodes(root, "pair")
      local names = {}
      for _, node in ipairs(nodes) do
        table.insert(names, json.get_name(node, bufnr))
      end
      assert.is_true(vim.tbl_contains(names, "a"))
      assert.is_true(vim.tbl_contains(names, "b"))
      assert.is_true(vim.tbl_contains(names, "c"))
    end)
  end)
end)
