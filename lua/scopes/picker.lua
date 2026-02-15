--- Snacks.picker integration for scopes.nvim.
--- Thin adapter between Navigator and snacks.picker.
--- Provides items, maps keybindings to Navigator methods, handles refresh on drill/up.

local config = require("scopes.config")

local M = {}

--- Icon mappings per symbol kind (Nerd Font).
--- @type table<string, string>
local kind_icons = {
  ["function"] = "󰊕",
  method = "󰊕",
  variable = "󰀫",
  const = "󰏿",
  type = "",
  class = "",
  block = "󰅩",
  file = "󰈔",
  error = "",
}

--- Format a ScopeNode into a picker item.
--- @param node ScopeNode
--- @param cfg scopes.Config
--- @return table item
local function format_item(node, cfg)
  local item = {
    text = node.name,
    node = node,
  }

  -- Add icon prefix
  if cfg.display.icons then
    local icon = kind_icons[node.kind] or "󰅩"
    item.icon = icon
  end

  -- Add line number
  if cfg.display.line_numbers and node.range then
    item.lnum = node.range.start_row + 1 -- 1-indexed for display
  end

  -- Add kind label
  item.kind = node.kind

  return item
end

--- Build the list of picker items from the navigator's current children.
--- @param navigator scopes.Navigator
--- @param cfg scopes.Config
--- @return table[] items
local function build_items(navigator, cfg)
  local items = {}
  for _, child in ipairs(navigator:items()) do
    table.insert(items, format_item(child, cfg))
  end
  return items
end

--- Open the scope picker with snacks.picker.
--- @param navigator scopes.Navigator
--- @param opts? { filename?: string, bufnr?: number }
function M.open(navigator, opts)
  opts = opts or {}
  local cfg = config.get()

  local snacks_ok, Snacks = pcall(require, "snacks")
  if not snacks_ok or not Snacks.picker then
    vim.notify("scopes.nvim: snacks.nvim with picker support is required", vim.log.levels.WARN)
    return
  end

  local filename = opts.filename
  local target_bufnr = opts.bufnr or navigator.tree.bufnr
  local original_cursor = vim.api.nvim_win_get_cursor(0)

  local function get_title()
    if cfg.display.breadcrumb then
      local bc = navigator:breadcrumb_string(filename)
      if bc ~= "" then
        return "Scopes: " .. bc
      end
    end
    return "Scopes"
  end

  local function get_items()
    return build_items(navigator, cfg)
  end

  -- Build the picker source
  local picker_opts = {
    title = get_title(),
    items = get_items(),
    format = function(item)
      local parts = {}

      if item.icon then
        table.insert(parts, { item.icon .. " ", "Special" })
      end

      table.insert(parts, { item.text, item.node and item.node.is_scope and "Function" or "Normal" })

      if item.kind then
        table.insert(parts, { " [" .. item.kind .. "]", "Comment" })
      end

      if item.lnum then
        table.insert(parts, { " :" .. item.lnum, "LineNr" })
      end

      return parts
    end,
    confirm = function(picker, item)
      if not item or not item.node then
        return
      end

      local pos = navigator:enter(item.node)
      if pos then
        picker:close()
        vim.api.nvim_win_set_cursor(0, { pos.row + 1, pos.col })
      end
    end,
    actions = {
      scope_drill_down = function(picker, item)
        if not item or not item.node then
          return
        end

        if navigator:drill_down(item.node) then
          -- Refresh the picker with new items
          M._refresh_picker(picker, navigator, cfg, filename)
        end
      end,
      scope_go_up = function(picker)
        if navigator:go_up() then
          M._refresh_picker(picker, navigator, cfg, filename)
        end
      end,
    },
    win = {
      input = {
        keys = {
          [cfg.picker.drill_down] = { "scope_drill_down", mode = { "i", "n" } },
          [cfg.picker.go_up] = { "scope_go_up", mode = { "i", "n" } },
        },
      },
    },
  }

  -- Set picker dimensions
  if cfg.picker.width then
    picker_opts.layout = picker_opts.layout or {}
    picker_opts.layout.width = cfg.picker.width
  end
  if cfg.picker.height then
    picker_opts.layout = picker_opts.layout or {}
    picker_opts.layout.height = cfg.picker.height
  end

  Snacks.picker.pick(picker_opts)
end

--- Refresh the picker in-place with updated items and title.
--- @param picker any snacks.picker instance
--- @param navigator scopes.Navigator
--- @param cfg scopes.Config
--- @param filename? string
function M._refresh_picker(picker, navigator, cfg, filename)
  local items = build_items(navigator, cfg)

  -- Update title
  if cfg.display.breadcrumb then
    local bc = navigator:breadcrumb_string(filename)
    if bc ~= "" then
      picker.title = "Scopes: " .. bc
    else
      picker.title = "Scopes"
    end
  end

  -- Update items — use the picker's API to refresh
  if picker.items then
    picker:clear()
    for _, item in ipairs(items) do
      picker:add(item)
    end
  end

  -- Fallback: close and reopen if refresh doesn't work
  -- (This handles the case where snacks.picker doesn't support in-place refresh)
end

return M
