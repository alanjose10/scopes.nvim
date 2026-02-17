local M = {}

local ICONS = {
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

--- Convert a ScopeNode to a snacks picker item.
--- @param node ScopeNode
--- @param bufnr number
--- @param buf_name string
--- @return table
function M.make_item(node, bufnr, buf_name)
  return {
    text = node.name,
    file = buf_name,
    buf = bufnr,
    pos = { node.range.start_row + 1, node.range.start_col },
    end_pos = { node.range.end_row + 1, node.range.end_col },
    node = node,
    kind = node.kind,
  }
end

--- Format a picker item for display (snacks.picker.Highlight[]).
--- @param item table
--- @param _picker any
--- @return table
function M.format(item, _picker)
  local node = item.node
  local icon = ICONS[node.kind] or "󰉻"
  local name_hl = node.is_error and "DiagnosticError" or "SnacksPickerFile"
  local drill = node:is_scope() and "  " or ""
  return {
    { icon .. " ", "SnacksPickerSpecial" },
    { node.name, name_hl },
    { " " },
    { "[" .. node.kind .. "]", "SnacksPickerComment" },
    { "  :" .. (node.range.start_row + 1), "SnacksPickerLineNr" },
    { drill, "SnacksPickerDir" },
  }
end

--- Open the scope picker for the given navigator.
--- @param nav Navigator
--- @param bufnr number
function M.open(nav, bufnr)
  local ok, Snacks = pcall(require, "snacks")
  if not ok then
    vim.notify("scopes.nvim: snacks.nvim is required", vim.log.levels.ERROR)
    return
  end

  local buf_name = vim.api.nvim_buf_get_name(bufnr)
  local main_win = vim.api.nvim_get_current_win()

  Snacks.picker({
    title = nav:breadcrumb_string(),

    finder = function()
      local items = {}
      for _, node in ipairs(nav:items()) do
        items[#items + 1] = M.make_item(node, bufnr, buf_name)
      end
      return items
    end,

    format = M.format,

    confirm = function(picker, item)
      if not item then
        return
      end
      local pos = nav:enter(item.node)
      picker:close()
      if vim.api.nvim_win_is_valid(main_win) then
        vim.api.nvim_win_set_cursor(main_win, { pos.row + 1, pos.col })
      end
    end,

    actions = {
      scope_drill = function(picker)
        local item = picker:current({ resolve = false })
        if item and nav:drill_down(item.node) then
          picker.title = nav:breadcrumb_string()
          picker:refresh()
        end
      end,

      scope_up = function(picker)
        if nav:go_up() then
          picker.title = nav:breadcrumb_string()
          picker:refresh()
        end
      end,
    },

    win = {
      input = {
        keys = {
          ["<Tab>"] = { "scope_drill", mode = { "i", "n" } },
          ["<S-Tab>"] = { "scope_up", mode = { "i", "n" } },
        },
      },
    },
  })
end

return M
