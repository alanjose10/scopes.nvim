local icons = require("scopes.icons")
local config = require("scopes.config")

describe("icons", function()
  before_each(function()
    config.merge({ display = { icons = true } })
  end)

  describe("get_icon (built-in fallback)", function()
    it("returns a non-empty string for all known kinds", function()
      local kinds = { "function", "method", "class", "struct", "variable", "const", "type", "block", "module" }
      for _, kind in ipairs(kinds) do
        local icon = icons.get_icon(kind)
        assert.is_string(icon)
        assert.is_true(#icon > 0, "expected non-empty icon for kind: " .. kind)
      end
    end)

    it("returns the generic fallback icon for an unknown kind", function()
      local icon = icons.get_icon("totally_unknown_kind")
      assert.is_string(icon)
      assert.is_true(#icon > 0)
    end)

    it("returns empty string when display.icons is false", function()
      config.merge({ display = { icons = false } })
      local icon = icons.get_icon("function")
      assert.are.equal("", icon)
    end)
  end)

  describe("get_icon with mini.icons stub", function()
    local original_require

    before_each(function()
      original_require = _G.require
    end)

    after_each(function()
      _G.require = original_require
      -- Clear the cached require result so subsequent tests get a fresh load
      package.loaded["mini.icons"] = nil
    end)

    it("calls mini.icons with the lsp category and mapped kind name", function()
      local called_with = {}
      package.loaded["mini.icons"] = {
        get = function(category, name)
          called_with = { category = category, name = name }
          return "M", "MiniIconsFunction", false
        end,
      }

      local icon = icons.get_icon("function")
      assert.are.equal("lsp", called_with.category)
      assert.are.equal("Function", called_with.name)
      assert.are.equal("M", icon)
    end)

    it("falls back to built-in table when mini.icons returns nil icon", function()
      package.loaded["mini.icons"] = {
        get = function()
          return nil, nil, false
        end,
      }

      local icon = icons.get_icon("function")
      assert.is_string(icon)
      assert.is_true(#icon > 0)
    end)

    it("falls back to built-in table when mini.icons.get errors", function()
      package.loaded["mini.icons"] = {
        get = function()
          error("boom")
        end,
      }

      local icon = icons.get_icon("function")
      assert.is_string(icon)
      assert.is_true(#icon > 0)
    end)
  end)
end)
