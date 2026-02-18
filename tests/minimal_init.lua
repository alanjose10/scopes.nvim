-- Minimal init for plenary.nvim tests.
-- Finds plugins in /tmp/nvim-plugins/ (CI) or ~/.local/share/nvim/lazy/ (local).

local plugin_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
vim.opt.runtimepath:prepend(plugin_root)

local function find_plugin(name)
  local candidates = {
    "/tmp/nvim-plugins/" .. name,
    vim.fn.expand("~/.local/share/nvim/lazy/" .. name),
  }
  for _, path in ipairs(candidates) do
    if vim.fn.isdirectory(path) == 1 then
      return path
    end
  end
  error("Plugin not found: " .. name .. " (checked: " .. table.concat(candidates, ", ") .. ")")
end

vim.opt.runtimepath:prepend(find_plugin("plenary.nvim"))
vim.opt.runtimepath:prepend(find_plugin("nvim-treesitter"))
vim.opt.runtimepath:prepend(find_plugin("snacks.nvim"))
