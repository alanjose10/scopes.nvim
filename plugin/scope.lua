if vim.g.loaded_scope then
  return
end
vim.g.loaded_scope = true

vim.api.nvim_create_user_command("ScopeOpen", function()
  require("scope").open()
end, { desc = "Open scope picker at cursor position" })

vim.api.nvim_create_user_command("ScopeBrowse", function()
  require("scope").open({ root = true })
end, { desc = "Open scope picker at file root" })
