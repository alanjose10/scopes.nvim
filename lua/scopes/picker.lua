local M = {}

local config = require("scopes.config")
local icons = require("scopes.icons")

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
  local icon = icons.get_icon(node.kind)
  local name_hl = node.is_error and "DiagnosticError" or "SnacksPickerFile"
  local drill = node:is_scope() and "  " or ""
  local cfg = config.get()
  local result = {}
  if cfg.display.icons then
    result[#result + 1] = { icon .. " ", "SnacksPickerSpecial" }
  end
  result[#result + 1] = { node.name, name_hl }
  return vim.list_extend(result, {
    { " " },
    { "[" .. node.kind .. "]", "SnacksPickerComment" },
    { "  :" .. (node.range.start_row + 1), "SnacksPickerLineNr" },
    { drill, "SnacksPickerDir" },
  })
end

--- Jump to a range in the given window, optionally opening a split first.
--- @param range {row: number, col: number}
--- @param split_mode "current"|"vsplit"|"hsplit"
--- @param target_win number
local function open_at(range, split_mode, target_win)
  if not range then
    return
  end
  if not vim.api.nvim_win_is_valid(target_win) then
    return
  end
  -- Ensure focus is on target_win before splitting; no-op for "current" mode.
  vim.api.nvim_set_current_win(target_win)
  local dest_win
  if split_mode == "vsplit" then
    dest_win = vim.api.nvim_open_win(0, true, { split = "right" })
  elseif split_mode == "hsplit" then
    dest_win = vim.api.nvim_open_win(0, true, { split = "below" })
  elseif split_mode == "current" then
    dest_win = target_win
  else
    vim.notify("scopes.nvim: unknown split_mode: " .. tostring(split_mode), vim.log.levels.WARN)
    return
  end
  vim.api.nvim_win_set_cursor(dest_win, { range.row + 1, range.col })
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
  local original_cursor = vim.api.nvim_win_get_cursor(main_win)
  local confirmed = false
  local cfg = config.get()

  Snacks.picker({
    title = nav:breadcrumb_string(),

    layout = {
      layout = {
        width = cfg.picker.width,
        height = cfg.picker.height,
        border = cfg.picker.border,
      },
    },

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
      confirmed = true
      local pos = nav:enter(item.node)
      picker:close()
      open_at(pos, "current", main_win)
    end,

    on_close = function(_picker)
      if not confirmed and vim.api.nvim_win_is_valid(main_win) then
        vim.api.nvim_win_set_cursor(main_win, original_cursor)
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
        -- Focus on the node's parent when going up in scope
        local prev_node = nav:current()
        if nav:go_up() then
          picker.title = nav:breadcrumb_string()
          picker:find({
            refresh = true,
            on_done = function()
              for item, idx in picker:iter() do
                if item.node == prev_node then
                  picker.list:view(idx)
                  return
                end
              end
            end,
          })
        end
      end,

      scope_split_v = function(picker)
        local item = picker:current({ resolve = false })
        if not item then
          return
        end
        confirmed = true
        local pos = nav:enter(item.node)
        picker:close()
        open_at(pos, "vsplit", main_win)
      end,

      scope_split_h = function(picker)
        local item = picker:current({ resolve = false })
        if not item then
          return
        end
        confirmed = true
        local pos = nav:enter(item.node)
        picker:close()
        open_at(pos, "hsplit", main_win)
      end,
    },

    win = {
      input = {
        keys = {
          ["<Tab>"] = { "scope_drill", mode = { "i", "n" } },
          ["<S-Tab>"] = { "scope_up", mode = { "i", "n" } },
          [cfg.picker.split_vertical] = { "scope_split_v", mode = { "i", "n" } },
          [cfg.picker.split_horizontal] = { "scope_split_h", mode = { "i", "n" } },
        },
      },
    },
  })
end

return M
