-- Install treesitter parsers synchronously using nvim-treesitter's async Task API.
-- Usage: nvim --headless -u scripts/install_parsers.lua
-- Expects nvim-treesitter to already be in the runtimepath.

local parsers = { "go", "lua", "python", "yaml", "json", "typescript" }

local ok, install = pcall(require, "nvim-treesitter.install")
if not ok then
  io.stderr:write("nvim-treesitter not found in runtimepath\n")
  vim.cmd("cquit 1")
  return
end

local task = install.install(parsers)
local success, err = task:pwait(300000) -- 5 minute timeout

if not success then
  io.stderr:write("Parser installation failed: " .. tostring(err) .. "\n")
  vim.cmd("cquit 1")
  return
end

vim.cmd("quit")
