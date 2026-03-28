local lang_config = require("scopes.lang_config")
local yaml = lang_config.build(require("scopes.languages.yaml"))
local helpers = require("tests.helpers")

describe("languages.yaml", function()
  describe("scope_types", function()
    it("contains block_mapping_pair", function()
      assert.is_true(vim.tbl_contains(yaml.scope_types, "block_mapping_pair"))
    end)
  end)

  describe("symbol_types", function()
    it("is empty (all YAML nodes are scopes)", function()
      assert.are.equal(0, #yaml.symbol_types)
    end)
  end)

  describe("no overlap between scope_types and symbol_types", function()
    it("has no types in both lists", function()
      for _, st in ipairs(yaml.scope_types) do
        assert.is_false(
          vim.tbl_contains(yaml.symbol_types, st),
          st .. " is in both scope_types and symbol_types"
        )
      end
    end)
  end)

  describe("kind_map", function()
    it("is a table", function()
      assert.are.equal("table", type(yaml.kind_map))
    end)

    it("has an entry for every scope_type", function()
      for _, st in ipairs(yaml.scope_types) do
        assert.is_truthy(yaml.kind_map[st], "missing kind_map entry for scope_type: " .. st)
      end
    end)

    it("all values are valid kind strings", function()
      for node_type, kind in pairs(yaml.kind_map) do
        assert.is_true(
          helpers.valid_kinds[kind],
          "invalid kind '" .. kind .. "' for node type '" .. node_type .. "'"
        )
      end
    end)
  end)

  describe("node_types", function()
    it("is a non-empty table", function()
      assert.are.equal("table", type(yaml.node_types))
      local count = 0
      for _ in pairs(yaml.node_types) do
        count = count + 1
      end
      assert.is_true(count > 0)
    end)

    it("every entry has kind (string) and is_scope (boolean)", function()
      for node_type, info in pairs(yaml.node_types) do
        assert.are.equal("string", type(info.kind), "kind missing or not string for " .. node_type)
        assert.are.equal("boolean", type(info.is_scope), "is_scope missing or not boolean for " .. node_type)
      end
    end)

    it("derived scope_types matches entries where is_scope == true", function()
      for node_type, info in pairs(yaml.node_types) do
        if info.is_scope then
          assert.is_true(
            vim.tbl_contains(yaml.scope_types, node_type),
            node_type .. " should be in scope_types"
          )
        end
      end
    end)
  end)

  describe("structural checks", function()
    it("passes all structural invariants", function()
      helpers.assert_valid_lang_config(yaml)
    end)
  end)

  describe("get_name", function()
    local bufnr

    before_each(function()
      bufnr = helpers.make_buf("tests/fixtures/sample.yaml", "yaml")
    end)

    after_each(function()
      helpers.delete_buf(bufnr)
    end)

    local function get_root()
      local parser = vim.treesitter.get_parser(bufnr, "yaml")
      local tree = parser:parse()[1]
      return tree:root()
    end

    it("extracts top-level key names from block_mapping_pair", function()
      local root = get_root()
      local nodes = helpers.find_ts_nodes(root, "block_mapping_pair")
      local names = {}
      for _, node in ipairs(nodes) do
        table.insert(names, yaml.get_name(node, bufnr))
      end
      assert.is_true(vim.tbl_contains(names, "version"))
      assert.is_true(vim.tbl_contains(names, "services"))
      assert.is_true(vim.tbl_contains(names, "networks"))
      assert.is_true(vim.tbl_contains(names, "volumes"))
    end)

    it("extracts nested key names", function()
      local root = get_root()
      local nodes = helpers.find_ts_nodes(root, "block_mapping_pair")
      local names = {}
      for _, node in ipairs(nodes) do
        table.insert(names, yaml.get_name(node, bufnr))
      end
      assert.is_true(vim.tbl_contains(names, "web"))
      assert.is_true(vim.tbl_contains(names, "db"))
      assert.is_true(vim.tbl_contains(names, "image"))
    end)
  end)

  describe("get_name edge cases", function()
    local bufnr

    after_each(function()
      helpers.delete_buf(bufnr)
    end)

    local function parse_yaml(code)
      local root
      root, bufnr = helpers.parse_code(code, "yaml")
      return root
    end

    it("returns node type string for unrecognized node types", function()
      local root = parse_yaml("key: value\n")
      -- The root is a 'stream' node, which is not in node_types
      assert.are.equal("stream", yaml.get_name(root, bufnr))
    end)

    it("extracts key from a simple scalar pair", function()
      local root = parse_yaml("host: localhost\n")
      local nodes = helpers.find_ts_nodes(root, "block_mapping_pair")
      assert.is_true(#nodes > 0, "expected at least one block_mapping_pair")
      assert.are.equal("host", yaml.get_name(nodes[1], bufnr))
    end)

    it("extracts key from a nested mapping pair", function()
      local root = parse_yaml("config:\n  host: localhost\n  port: 5432\n")
      local nodes = helpers.find_ts_nodes(root, "block_mapping_pair")
      local names = {}
      for _, node in ipairs(nodes) do
        table.insert(names, yaml.get_name(node, bufnr))
      end
      assert.is_true(vim.tbl_contains(names, "config"))
      assert.is_true(vim.tbl_contains(names, "host"))
      assert.is_true(vim.tbl_contains(names, "port"))
    end)
  end)
end)
