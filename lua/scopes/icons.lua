local M = {}

local config = require("scopes.config")

--- Built-in Nerd Font icon table, keyed by our internal kind strings.
local BUILTIN = {
  ["function"] = "󰊕",
  ["method"] = "󰊕",
  ["class"] = "󰆧",
  ["struct"] = "󰆧",
  ["variable"] = "󰀫",
  ["const"] = "󰏿",
  ["type"] = "󰊱",
  ["block"] = "󰅪",
  ["module"] = "󰇋",
}

local FALLBACK = "󰉻"

--- Maps our lowercase kind strings to the title-case LSP symbol kind names
--- that mini.icons uses in its "lsp" category.
local KIND_TO_LSP = {
  ["function"] = "Function",
  ["method"] = "Method",
  ["class"] = "Class",
  ["struct"] = "Class",
  ["variable"] = "Variable",
  ["const"] = "Constant",
  ["type"] = "TypeParameter",
  ["block"] = "Module",
  ["module"] = "Module",
}

--- Resolve an icon for a symbol kind.
--- Resolution order:
---   1. Return "" if display.icons is disabled.
---   2. Try mini.icons (lsp category).
---   3. Fall back to built-in Nerd Font table.
---   4. Return a generic fallback icon.
--- @param kind string
--- @return string
function M.get_icon(kind)
  local cfg = config.get()
  if not cfg.display.icons then
    return ""
  end

  -- Try mini.icons
  local mini_ok, mini_icons = pcall(require, "mini.icons")
  if mini_ok and mini_icons then
    local lsp_name = KIND_TO_LSP[kind]
    if lsp_name then
      local ok, icon = pcall(mini_icons.get, "lsp", lsp_name)
      if ok and icon and #icon > 0 then
        return icon
      end
    end
  end

  -- Built-in fallback
  return BUILTIN[kind] or FALLBACK
end

return M
