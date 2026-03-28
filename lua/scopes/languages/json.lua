--- JSON language node types for scopes.nvim
--- Uses pair as the primary scope unit: each "key": value entry is both
--- the named display item and the drillable container. Scalar-valued pairs
--- are terminal (they drill into nothing), which is handled gracefully
--- by the navigator.
--- Maps Treesitter node types to scope/symbol categories.

return {
  pair = {
    kind = "block",
    is_scope = true,
    name_getter = function(node, source)
      local key_node = node:field("key")[1]
      if key_node then
        local text = vim.treesitter.get_node_text(key_node, source)
        -- JSON keys are quoted strings; strip the surrounding quotes.
        if #text >= 2 then
          return text:sub(2, -2)
        end
        return text
      end
    end,
  },
}
