local tree = require("scopes.backends.treesitter").build(vim.api.nvim_get_current_buf())
for _, child in ipairs(tree.root.children) do
	print(
		string.format(
			"%s [%s] L%d-%d  scope=%s",
			child.name,
			child.kind,
			child.range.start_row,
			child.range.end_row,
			tostring(child:is_scope())
		)
	)
end
