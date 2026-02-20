local lang_config = require("scopes.lang_config")

--- Minimal mock node_types for testing build() in isolation.
local mock_node_types = {
  my_scope = {
    kind = "function",
    is_scope = true,
    name_getter = function(_node, _source)
      return "scope-name"
    end,
  },
  my_symbol = {
    kind = "variable",
    is_scope = false,
    name_getter = function(_node, _source)
      return "symbol-name"
    end,
  },
  no_getter = {
    kind = "block",
    is_scope = true,
    -- deliberately no name_getter
  },
}

--- Minimal fake TSNode for testing get_name without a real parser.
local function make_fake_node(node_type)
  return {
    type = function()
      return node_type
    end,
  }
end

describe("lang_config", function()
  describe("build()", function()
    local cfg

    before_each(function()
      cfg = lang_config.build(mock_node_types)
    end)

    it("returns a table", function()
      assert.are.equal("table", type(cfg))
    end)

    it("exposes the original node_types table", function()
      assert.are.equal(mock_node_types, cfg.node_types)
    end)

    it("scope_types contains only entries with is_scope == true", function()
      assert.is_true(vim.tbl_contains(cfg.scope_types, "my_scope"))
      assert.is_true(vim.tbl_contains(cfg.scope_types, "no_getter"))
      assert.is_false(vim.tbl_contains(cfg.scope_types, "my_symbol"))
    end)

    it("symbol_types contains only entries with is_scope == false", function()
      assert.is_true(vim.tbl_contains(cfg.symbol_types, "my_symbol"))
      assert.is_false(vim.tbl_contains(cfg.symbol_types, "my_scope"))
      assert.is_false(vim.tbl_contains(cfg.symbol_types, "no_getter"))
    end)

    it("kind_map maps every node type to its kind", function()
      assert.are.equal("function", cfg.kind_map["my_scope"])
      assert.are.equal("variable", cfg.kind_map["my_symbol"])
      assert.are.equal("block", cfg.kind_map["no_getter"])
    end)

    it("get_name is a function", function()
      assert.are.equal("function", type(cfg.get_name))
    end)

    it("get_name calls the matching name_getter", function()
      local node = make_fake_node("my_scope")
      assert.are.equal("scope-name", cfg.get_name(node, 0))
    end)

    it("get_name calls name_getter for symbol nodes", function()
      local node = make_fake_node("my_symbol")
      assert.are.equal("symbol-name", cfg.get_name(node, 0))
    end)

    it("get_name falls back to node type string when no name_getter", function()
      local node = make_fake_node("no_getter")
      assert.are.equal("no_getter", cfg.get_name(node, 0))
    end)

    it("get_name falls back to node type string for unknown node types", function()
      local node = make_fake_node("completely_unknown")
      assert.are.equal("completely_unknown", cfg.get_name(node, 0))
    end)
  end)

  describe("build() with empty node_types", function()
    it("returns valid empty config", function()
      local cfg = lang_config.build({})
      assert.are.equal("table", type(cfg))
      assert.are.equal(0, #cfg.scope_types)
      assert.are.equal(0, #cfg.symbol_types)
      assert.are.equal("table", type(cfg.kind_map))
      assert.are.equal("function", type(cfg.get_name))
    end)

    it("get_name on empty config falls back to node type", function()
      local cfg = lang_config.build({})
      local node = make_fake_node("some_node")
      assert.are.equal("some_node", cfg.get_name(node, 0))
    end)
  end)

  describe("load()", function()
    it("returns a LangConfig for a known language (go)", function()
      local cfg = lang_config.load("go")
      assert.is_truthy(cfg)
      assert.is_true(#cfg.scope_types > 0)
      assert.is_true(#cfg.symbol_types > 0)
      assert.are.equal("function", type(cfg.get_name))
    end)

    it("returns a LangConfig for a known language (lua)", function()
      local cfg = lang_config.load("lua")
      assert.is_truthy(cfg)
      assert.is_true(#cfg.scope_types > 0)
    end)

    it("returns nil for an unknown language", function()
      local cfg = lang_config.load("no_such_language_xyz")
      assert.is_nil(cfg)
    end)
  end)
end)
