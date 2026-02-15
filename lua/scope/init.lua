local config = require("scope.config")

local M = {}

--- Setup scope.nvim with user options.
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
  local cfg = config.get()

  if not cfg then
    vim.notify("scope.nvim: call require('scope').setup() first", vim.log.levels.WARN)
    return
  end

  -- TODO: Phase 1 — build tree, create navigator, open picker
  vim.notify("scope.nvim: picker not yet implemented", vim.log.levels.INFO)
end

return M
