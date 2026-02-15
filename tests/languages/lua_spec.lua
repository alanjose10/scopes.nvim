local lua_lang = require("scopes.languages.lua")

describe("scopes.languages.lua", function()
  describe("scope_types", function()
    it("is a non-empty list", function()
      assert.is_true(#lua_lang.scope_types > 0)
    end)

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

    it("contains only strings", function()
      for _, v in ipairs(lua_lang.scope_types) do
        assert.are.equal("string", type(v))
      end
    end)
  end)

  describe("symbol_types", function()
    it("is a non-empty list", function()
      assert.is_true(#lua_lang.symbol_types > 0)
    end)

    it("contains assignment_statement", function()
      assert.is_true(vim.tbl_contains(lua_lang.symbol_types, "assignment_statement"))
    end)

    it("contains variable_declaration", function()
      assert.is_true(vim.tbl_contains(lua_lang.symbol_types, "variable_declaration"))
    end)

    it("contains only strings", function()
      for _, v in ipairs(lua_lang.symbol_types) do
        assert.are.equal("string", type(v))
      end
    end)
  end)

  describe("no overlap", function()
    it("scope_types and symbol_types have no common entries", function()
      local scope_set = {}
      for _, v in ipairs(lua_lang.scope_types) do
        scope_set[v] = true
      end

      for _, v in ipairs(lua_lang.symbol_types) do
        assert.is_falsy(scope_set[v], v .. " should not be in both scope_types and symbol_types")
      end
    end)
  end)

  describe("kind_map", function()
    it("maps all scope types", function()
      for _, st in ipairs(lua_lang.scope_types) do
        assert.is_not_nil(lua_lang.kind_map[st], "kind_map should have entry for " .. st)
      end
    end)

    it("maps all symbol types", function()
      for _, st in ipairs(lua_lang.symbol_types) do
        assert.is_not_nil(lua_lang.kind_map[st], "kind_map should have entry for " .. st)
      end
    end)
  end)

  describe("get_name", function()
    local bufnr

    after_each(function()
      if bufnr then
        vim.api.nvim_buf_delete(bufnr, { force = true })
        bufnr = nil
      end
    end)

    it("extracts function names from Lua code", function()
      bufnr = vim.api.nvim_create_buf(false, true)
      local lines = vim.fn.readfile("tests/fixtures/sample.lua")
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
      vim.api.nvim_set_option_value("filetype", "lua", { buf = bufnr })
      vim.treesitter.start(bufnr, "lua")

      local parser = vim.treesitter.get_parser(bufnr, "lua")
      local trees = parser:parse()
      local root = trees[1]:root()

      -- Walk children to find function_declaration nodes
      local found_names = {}
      for child in root:iter_children() do
        if child:type() == "function_declaration" then
          local name = lua_lang.get_name(child, bufnr)
          table.insert(found_names, name)
        end
      end

      assert.is_true(#found_names > 0)
    end)
  end)
end)
