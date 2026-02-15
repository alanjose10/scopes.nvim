if vim.g.loaded_scopes then
  return
end
vim.g.loaded_scopes = true

vim.api.nvim_create_user_command("ScopeOpen", function()
  require("scopes").open()
end, { desc = "Open scope picker at cursor position" })

vim.api.nvim_create_user_command("ScopeBrowse", function()
  require("scopes").open({ root = true })
end, { desc = "Open scope picker at file root" })
