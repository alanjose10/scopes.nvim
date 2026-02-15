--- @class scopes.Config
--- @field backend "treesitter"|"lsp"|"auto"
--- @field keymaps scopes.KeymapConfig
--- @field picker scopes.PickerConfig
--- @field display scopes.DisplayConfig
--- @field treesitter scopes.TreesitterConfig
--- @field cache scopes.CacheConfig

--- @class scopes.KeymapConfig
--- @field open string
--- @field open_root string

--- @class scopes.PickerConfig
--- @field enter string
--- @field drill_down string
--- @field go_up string
--- @field close string[]
--- @field backend "snacks"|"telescope"
--- @field preview boolean
--- @field width number
--- @field height number
--- @field border string

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
  keymaps = {
    open = "<leader>ss",
    open_root = "<leader>sS",
  },
  picker = {
    enter = "<CR>",
    drill_down = "<Tab>",
    go_up = "<S-Tab>",
    close = { "<Esc>", "q" },
    backend = "snacks",
    preview = true,
    width = 0.5,
    height = 0.4,
    border = "rounded",
  },
  display = {
    icons = true,
    line_numbers = true,
    breadcrumb = true,
  },
  treesitter = {
    scope_types = {},
  },
  cache = {
    enabled = true,
    debounce_ms = 300,
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
