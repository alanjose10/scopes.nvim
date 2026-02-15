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
  local cfg = config.get()

  if not cfg then
    vim.notify("scopes.nvim: call require('scopes').setup() first", vim.log.levels.WARN)
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local tree_mod = require("scopes.tree")

  -- Build the scope tree
  local scope_tree, err = tree_mod.build(bufnr)
  if not scope_tree then
    vim.notify("scopes.nvim: " .. (err or "failed to build scope tree"), vim.log.levels.WARN)
    return
  end

  -- Set up cache invalidation autocommands for this buffer
  tree_mod.setup_autocmds(bufnr)

  -- Create navigator
  local Navigator = require("scopes.navigator")
  local nav_opts = {}

  if not opts.root then
    -- Open at cursor position
    local cursor = vim.api.nvim_win_get_cursor(0)
    nav_opts.cursor_row = cursor[1] - 1 -- Convert to 0-indexed
  end

  local navigator = Navigator:new(scope_tree, nav_opts)

  -- Get filename for breadcrumb display
  local filename = vim.api.nvim_buf_get_name(bufnr)
  if filename ~= "" then
    filename = vim.fn.fnamemodify(filename, ":t")
  else
    filename = "[No Name]"
  end

  -- Open picker
  local picker = require("scopes.picker")
  picker.open(navigator, {
    filename = filename,
    bufnr = bufnr,
  })
end

return M
