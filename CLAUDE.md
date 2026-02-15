# scope.nvim

Neovim plugin for hierarchical scope-based symbol navigation.
Written in Lua. Uses Treesitter (primary) and LSP (fallback).

## Structure
```
lua/scope/init.lua          -- setup() + public API
lua/scope/config.lua        -- defaults, merge, validation
lua/scope/tree.lua          -- ScopeTree / ScopeNode builder (facade)
lua/scope/navigator.lua     -- navigation state machine
lua/scope/picker.lua        -- snacks.picker source + telescope extension
lua/scope/backends/
  treesitter.lua             -- TS-specific tree building
  lsp.lua                   -- LSP DocumentSymbol adapter
lua/scope/languages/
  go.lua                    -- Go scope/symbol node types
  lua.lua                   -- Lua scope/symbol node types
  typescript.lua            -- TS scope/symbol node types
  python.lua                -- Python scope/symbol node types
plugin/scope.lua            -- :ScopeOpen, :ScopeBrowse user commands
tests/                      -- plenary.nvim tests
tests/fixtures/             -- sample source files for testing
```

## Testing
Tests use plenary.nvim:
```
nvim --headless -c "PlenaryBustedDirectory tests/"
```

## Conventions
- Lua style: snake_case, type annotations via LuaLS/EmmyLua
- All Neovim API calls go through vim.api, not vim.fn
- Error handling: never crash, always degrade gracefully
- Module naming: `require("scope.config")`, `require("scope.backends.treesitter")`, etc.

## Key Data Types
- `ScopeNode`: name, kind, range, children[], parent
- `ScopeTree`: root (ScopeNode), source ("treesitter"|"lsp"), bufnr
- `Navigator`: current_node, breadcrumb path, history

## User Commands
- `:ScopeOpen` — open picker at cursor scope
- `:ScopeBrowse` — open picker at file root
