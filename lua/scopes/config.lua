--- @class scopes.Config
--- @field backend "treesitter"|"lsp"|"auto"
--- @field debug boolean
--- @field keymaps scopes.KeymapConfig
--- @field picker scopes.PickerConfig
--- @field display scopes.DisplayConfig
--- @field treesitter scopes.TreesitterConfig
--- @field cache scopes.CacheConfig
--- @field filename_parsers table<string, string|{parser: string, config: string}>  Maps buffer basename to a treesitter parser override. Value is either a parser language string, or a table with `parser` (treesitter lang) and `config` (lang config name) to decouple them. Does not change the buffer filetype — no LSP or diagnostics side effects.

--- @class scopes.KeymapConfig
--- @field open string
--- @field open_root string

--- @class scopes.PickerConfig
--- @field enter string
--- @field drill_down string
--- @field go_up string
--- @field close string[]
--- @field split_vertical string
--- @field split_horizontal string
--- @field backend "snacks"|"telescope"
--- @field preview boolean
--- @field width? number
--- @field height? number
--- @field border? string

--- @class scopes.DisplayConfig
--- @field icons boolean
--- @field line_numbers boolean
--- @field breadcrumb boolean

--- @class scopes.TreesitterConfig
--- @field scope_types table<string, string[]>

--- @class scopes.CacheConfig
--- @field enabled boolean
--- @field debounce_ms number

local M = {}

--- @type scopes.Config
M.defaults = {
  backend = "auto",
  debug = false,
  keymaps = {
    open = "<leader>so",
    open_root = "<leader>sO",
  },
  picker = {
    enter = "<CR>",
    drill_down = "<Tab>",
    go_up = "<S-Tab>",
    close = { "<Esc>", "q" },
    split_vertical = "<C-v>",
    split_horizontal = "<C-s>",
    backend = "snacks",
    preview = true,
    width = nil,
    height = nil,
    border = nil,
  },
  display = {
    icons = true,
    line_numbers = true, -- TODO: Not yet used
    breadcrumb = true, -- TODO: Not yet used
  },
  -- TODO: Not yet used
  treesitter = {
    scope_types = {},
  },
  cache = {
    enabled = true,
    debounce_ms = 300,
  },
  -- Maps buffer basename to parser/config overrides for files Neovim doesn't assign a
  -- filetype to. Scopes uses the specified parser and lang config internally without
  -- touching the buffer's filetype — no LSP, diagnostics, or highlighting side effects.
  --
  -- Each value is either:
  --   a string  → used as both the treesitter parser language and the lang config name
  --   a table   → { parser = "...", config = "..." } to decouple them
  --
  -- BUILD files use the Python parser (Starlark is a Python subset) but the bzl
  -- lang config so that build rules (go_binary, go_library, etc.) appear as scopes.
  filename_parsers = {
    BUILD = { parser = "python", config = "bzl" },
    ["BUILD.bazel"] = { parser = "python", config = "bzl" },
    ["BUILD.plz"] = { parser = "python", config = "bzl" },
    WORKSPACE = { parser = "python", config = "bzl" },
    ["WORKSPACE.bazel"] = { parser = "python", config = "bzl" },
  },
}

--- Deep merge two tables. Values from `override` take precedence.
--- @param base table
--- @param override table
--- @return table
local function deep_merge(base, override)
  local result = {}
  for k, v in pairs(base) do
    if type(v) == "table" and type(override[k]) == "table" then
      result[k] = deep_merge(v, override[k])
    elseif override[k] ~= nil then
      result[k] = override[k]
    else
      result[k] = v
    end
  end
  -- Include keys from override that are not in base
  for k, v in pairs(override) do
    if result[k] == nil then
      result[k] = v
    end
  end
  return result
end

--- @type scopes.Config
M.current = nil

--- Merge user options with defaults and store as current config.
--- @param opts? table
--- @return scopes.Config
function M.merge(opts)
  M.current = deep_merge(M.defaults, opts or {})
  return M.current
end

--- Get the current config, or defaults if setup hasn't been called.
--- @return scopes.Config
function M.get()
  return M.current or M.defaults
end

return M
