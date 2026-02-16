local config = require("scopes.config")

describe("scopes.config", function()
  -- Reset state before each test
  before_each(function()
    config.current = nil
  end)

  describe("defaults", function()
    it("has auto backend", function()
      assert.are.equal("auto", config.defaults.backend)
    end)

    it("has keymap defaults", function()
      assert.are.equal("<leader>ss", config.defaults.keymaps.open)
      assert.are.equal("<leader>sS", config.defaults.keymaps.open_root)
    end)

    it("has picker defaults", function()
      assert.are.equal("<CR>", config.defaults.picker.enter)
      assert.are.equal("<Tab>", config.defaults.picker.drill_down)
      assert.are.equal("<S-Tab>", config.defaults.picker.go_up)
      assert.are.equal("snacks", config.defaults.picker.backend)
      assert.is_true(config.defaults.picker.preview)
      assert.are.equal(0.5, config.defaults.picker.width)
      assert.are.equal(0.4, config.defaults.picker.height)
      assert.are.equal("rounded", config.defaults.picker.border)
    end)

    it("has display defaults", function()
      assert.is_true(config.defaults.display.icons)
      assert.is_true(config.defaults.display.line_numbers)
      assert.is_true(config.defaults.display.breadcrumb)
    end)

    it("has cache defaults", function()
      assert.is_true(config.defaults.cache.enabled)
      assert.are.equal(300, config.defaults.cache.debounce_ms)
    end)

    it("has empty treesitter scope_types by default", function()
      assert.are.same({}, config.defaults.treesitter.scope_types)
    end)
  end)

  describe("get", function()
    it("returns defaults when merge has not been called", function()
      local cfg = config.get()
      assert.are.equal(config.defaults, cfg)
    end)

    it("returns current config after merge", function()
      config.merge({ backend = "lsp" })
      local cfg = config.get()
      assert.are.equal("lsp", cfg.backend)
    end)
  end)

  describe("merge", function()
    it("returns defaults when called with nil", function()
      local cfg = config.merge()
      assert.are.equal("auto", cfg.backend)
      assert.are.equal("<leader>ss", cfg.keymaps.open)
    end)

    it("returns defaults when called with empty table", function()
      local cfg = config.merge({})
      assert.are.equal("auto", cfg.backend)
      assert.is_true(cfg.display.icons)
    end)

    it("overrides top-level scalar values", function()
      local cfg = config.merge({ backend = "treesitter" })
      assert.are.equal("treesitter", cfg.backend)
    end)

    it("deep merges nested tables", function()
      local cfg = config.merge({ picker = { width = 0.8 } })
      -- overridden value
      assert.are.equal(0.8, cfg.picker.width)
      -- other picker defaults preserved
      assert.are.equal(0.4, cfg.picker.height)
      assert.are.equal("rounded", cfg.picker.border)
      assert.are.equal("snacks", cfg.picker.backend)
    end)

    it("deep merges multiple nested levels", function()
      local cfg = config.merge({
        keymaps = { open = "<leader>o" },
        display = { icons = false },
      })
      assert.are.equal("<leader>o", cfg.keymaps.open)
      assert.are.equal("<leader>sS", cfg.keymaps.open_root)
      assert.is_false(cfg.display.icons)
      assert.is_true(cfg.display.line_numbers)
    end)

    it("merges list values by index", function()
      local cfg = config.merge({ picker = { close = { "<C-c>" } } })
      -- deep_merge merges by key, so index 1 is overridden, index 2 is kept from defaults
      assert.are.same({ "<C-c>", "q" }, cfg.picker.close)
    end)

    it("stores result as current config", function()
      config.merge({ backend = "lsp" })
      assert.are.equal("lsp", config.current.backend)
    end)

    it("allows user-defined keys not in defaults", function()
      local cfg = config.merge({ custom_key = "hello" })
      assert.are.equal("hello", cfg.custom_key)
    end)

    it("merges treesitter scope_types from user", function()
      local cfg = config.merge({
        treesitter = {
          scope_types = {
            go = { "function_declaration", "method_declaration" },
          },
        },
      })
      assert.are.same({ "function_declaration", "method_declaration" }, cfg.treesitter.scope_types.go)
    end)

    it("does not mutate defaults", function()
      config.merge({ backend = "lsp", picker = { width = 0.9 } })
      assert.are.equal("auto", config.defaults.backend)
      assert.are.equal(0.5, config.defaults.picker.width)
    end)

    it("can be called multiple times independently", function()
      config.merge({ backend = "lsp" })
      assert.are.equal("lsp", config.get().backend)

      config.merge({ backend = "treesitter" })
      assert.are.equal("treesitter", config.get().backend)
    end)
  end)
end)
