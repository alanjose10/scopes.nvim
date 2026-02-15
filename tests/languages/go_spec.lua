local go_lang = require("scopes.languages.go")

describe("scopes.languages.go", function()
  describe("scope_types", function()
    it("is a non-empty list", function()
      assert.is_true(#go_lang.scope_types > 0)
    end)

    it("contains function_declaration", function()
      assert.is_true(vim.tbl_contains(go_lang.scope_types, "function_declaration"))
    end)

    it("contains method_declaration", function()
      assert.is_true(vim.tbl_contains(go_lang.scope_types, "method_declaration"))
    end)

    it("contains func_literal", function()
      assert.is_true(vim.tbl_contains(go_lang.scope_types, "func_literal"))
    end)

    it("contains if_statement", function()
      assert.is_true(vim.tbl_contains(go_lang.scope_types, "if_statement"))
    end)

    it("contains for_statement", function()
      assert.is_true(vim.tbl_contains(go_lang.scope_types, "for_statement"))
    end)

    it("contains select_statement", function()
      assert.is_true(vim.tbl_contains(go_lang.scope_types, "select_statement"))
    end)

    it("contains only strings", function()
      for _, v in ipairs(go_lang.scope_types) do
        assert.are.equal("string", type(v))
      end
    end)
  end)

  describe("symbol_types", function()
    it("is a non-empty list", function()
      assert.is_true(#go_lang.symbol_types > 0)
    end)

    it("contains var_spec", function()
      assert.is_true(vim.tbl_contains(go_lang.symbol_types, "var_spec"))
    end)

    it("contains const_spec", function()
      assert.is_true(vim.tbl_contains(go_lang.symbol_types, "const_spec"))
    end)

    it("contains short_var_declaration", function()
      assert.is_true(vim.tbl_contains(go_lang.symbol_types, "short_var_declaration"))
    end)

    it("contains type_declaration", function()
      assert.is_true(vim.tbl_contains(go_lang.symbol_types, "type_declaration"))
    end)

    it("contains only strings", function()
      for _, v in ipairs(go_lang.symbol_types) do
        assert.are.equal("string", type(v))
      end
    end)
  end)

  describe("no overlap", function()
    it("scope_types and symbol_types have no common entries", function()
      local scope_set = {}
      for _, v in ipairs(go_lang.scope_types) do
        scope_set[v] = true
      end

      for _, v in ipairs(go_lang.symbol_types) do
        assert.is_falsy(scope_set[v], v .. " should not be in both scope_types and symbol_types")
      end
    end)
  end)

  describe("kind_map", function()
    it("maps all scope types", function()
      for _, st in ipairs(go_lang.scope_types) do
        assert.is_not_nil(go_lang.kind_map[st], "kind_map should have entry for " .. st)
      end
    end)

    it("maps all symbol types", function()
      for _, st in ipairs(go_lang.symbol_types) do
        assert.is_not_nil(go_lang.kind_map[st], "kind_map should have entry for " .. st)
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

    it("extracts function names from Go code", function()
      bufnr = vim.api.nvim_create_buf(false, true)
      local lines = vim.fn.readfile("tests/fixtures/sample.go")
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
      vim.api.nvim_set_option_value("filetype", "go", { buf = bufnr })
      vim.treesitter.start(bufnr, "go")

      local parser = vim.treesitter.get_parser(bufnr, "go")
      local trees = parser:parse()
      local root = trees[1]:root()

      -- Walk top-level children to find function_declaration
      local found_names = {}
      for child in root:iter_children() do
        if child:type() == "function_declaration" then
          local name = go_lang.get_name(child, bufnr)
          table.insert(found_names, name)
        end
      end

      assert.is_true(#found_names > 0)
      assert.is_true(vim.tbl_contains(found_names, "NewMyStruct"))
    end)

    it("extracts const names", function()
      bufnr = vim.api.nvim_create_buf(false, true)
      local lines = vim.fn.readfile("tests/fixtures/sample.go")
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
      vim.api.nvim_set_option_value("filetype", "go", { buf = bufnr })
      vim.treesitter.start(bufnr, "go")

      local parser = vim.treesitter.get_parser(bufnr, "go")
      local trees = parser:parse()
      local root = trees[1]:root()

      local found_const = false
      for child in root:iter_children() do
        if child:type() == "const_declaration" then
          for spec in child:iter_children() do
            if spec:type() == "const_spec" then
              local name = go_lang.get_name(spec, bufnr)
              if name == "MaxRetries" then
                found_const = true
              end
            end
          end
        end
      end

      assert.is_true(found_const)
    end)
  end)
end)
