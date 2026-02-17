local config = require("scopes.config")

local M = {}

--- Setup scopes.nvim with user options.
--- @param opts? table
function M.setup(opts)
  config.merge(opts)

  local cfg = config.get()

  -- Register keymaps
  if cfg.keymaps.open then
    vim.keymap.set("n", cfg.keymaps.open, function()
      M.open()
    end, { desc = "Scope: open at cursor" })
  end

  if cfg.keymaps.open_root then
    vim.keymap.set("n", cfg.keymaps.open_root, function()
      M.open({ root = true })
    end, { desc = "Scope: open at file root" })
  end
end

--- Open the scope picker.
--- @param opts? { root?: boolean }
function M.open(opts)
  opts = opts or {}
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor_row = vim.fn.line(".") - 1 -- 0-indexed

  local scope_tree = require("scopes.tree").build(bufnr)
  if not scope_tree then
    vim.notify("scopes.nvim: could not build scope tree for this buffer", vim.log.levels.WARN)
    return
  end

  local nav_opts = opts.root and {} or { cursor_row = cursor_row }
  local nav = require("scopes.navigator").new(scope_tree, nav_opts)

  require("scopes.picker").open(nav, bufnr)
end

return M
