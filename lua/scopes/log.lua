local config = require("scopes.config")

local M = {}

--- Emit a debug message when config.debug is true.
--- Shown via vim.notify at INFO level so it appears in :messages.
--- @param msg string
function M.debug(msg)
  if config.get().debug then
    vim.notify("[scopes] " .. msg, vim.log.levels.INFO)
  end
end

return M
