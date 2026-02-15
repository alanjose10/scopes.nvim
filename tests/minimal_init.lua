-- Minimal init for plenary.nvim tests.
-- Adds the plugin and plenary to the runtime path.

local plugin_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
vim.opt.runtimepath:prepend(plugin_root)

-- Add plenary.nvim (lazy.nvim default location)
local plenary_path = vim.fn.expand("~/.local/share/nvim/lazy/plenary.nvim")
vim.opt.runtimepath:prepend(plenary_path)

-- Add tests/ to package.path so test helpers can be required
package.path = plugin_root .. "/tests/?.lua;" .. package.path
