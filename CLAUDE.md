# scopes.nvim
Neovim plugin for hierarchical, scope-based symbol navigation. Browse a file's structure like a tree — drill into functions, classes, and blocks to see their contents, navigate back up to the parent scope.
Integrates with snacks.picker (primary) and Telescope (planned) rather than implementing a standalone UI.
Written in Lua. Uses Treesitter (primary) and LSP (fallback).

## Current Status
See TASKS.md for progress. Pick up from the first unchecked task in the current phase.

## Structure
```
lua/scopes/init.lua          -- setup() + public API
lua/scopes/config.lua        -- defaults, merge, validation
lua/scopes/tree.lua          -- ScopeTree / ScopeNode builder (facade)
lua/scopes/navigator.lua     -- navigation state machine
lua/scopes/picker.lua        -- snacks.picker source + telescope extension
lua/scopse/backends/
  treesitter.lua             -- TS-specific tree building
  lsp.lua                   -- LSP DocumentSymbol adapter
lua/scopes/languages/
  go.lua                    -- Go scope/symbol node types
  lua.lua                   -- Lua scope/symbol node types
  typescript.lua            -- TS scope/symbol node types
  python.lua                -- Python scope/symbol node types
plugin/scospe.lua            -- :ScopeOpen, :ScopeBrowse user commands
tests/                      -- plenary.nvim tests
tests/fixtures/             -- sample source files for testing
```

## Data Model

```lua
--- @class ScopeNode
--- @field name string            -- Display name ("HandleRequest", "err", etc.)
--- @field kind string            -- Symbol kind: "function", "method", "variable", "type", "const", "block", "class"
--- @field range {start_row: number, start_col: number, end_row: number, end_col: number}
--- @field children ScopeNode[]   -- Child nodes within this scope
--- @field parent ScopeNode|nil   -- Back-reference (set during build, not in language configs)
--- @field is_scope boolean       -- true if this node can be drilled into (has meaningful children)
--- @field is_error boolean       -- true if this came from a Treesitter ERROR node

--- @class ScopeTree
--- @field root ScopeNode         -- Virtual root representing file-level scope
--- @field source "treesitter"|"lsp"
--- @field bufnr number
--- @field lang string            -- Language identifier

--- @class LangConfig
--- @field scope_types string[]   -- Treesitter node types that create scopes (can be drilled into)
--- @field symbol_types string[]  -- Treesitter node types that appear as items in a scope
--- @field get_name fun(node: TSNode, source: number): string  -- Extract display name from a TS node
```

## Architecture

Four layers, each independently testable:

1. **Language configs** (`languages/*.lua`) — declarative mappings from Treesitter node types to scope/symbol categories. Pure data, no logic.
2. **Tree builder** (`tree.lua` + `backends/`) — consumes TS nodes or LSP DocumentSymbols, produces a `ScopeTree`. Stateless.
3. **Navigator** (`navigator.lua`) — state machine over a `ScopeTree`. Tracks current node, breadcrumb path, cursor index. Exposes `drill_down()`, `go_up()`, `enter()`, `children()`, `open_at_cursor()`. No UI dependency.
4. **Picker integration** (`picker.lua`) — thin adapter between Navigator and snacks.picker. Provides items, maps keybindings to Navigator methods, handles refresh on drill/up.

## Testing

Tests use plenary.nvim:

```bash
# Run all tests
nvim --headless -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"

# Run a single test file
nvim --headless -c "PlenaryBustedFile tests/tree_spec.lua {minimal_init = 'tests/minimal_init.lua'}"
```

## Conventions
- **Language**: Lua, targeting Neovim >= 0.10
- **Style**: snake_case everywhere. Use `stylua` for formatting.
- **Type annotations**: EmmyLua / LuaLS style (`--- @class`, `--- @field`, `--- @param`, `--- @return`)
- **Neovim API**: always `vim.api.*`, never `vim.fn.*` unless there's no API equivalent
- **Error handling**: never crash. Degrade gracefully. Show `vim.notify(..., vim.log.levels.WARN)` for user-facing issues.
- **No globals**: everything is `local` and returned from modules
- Module naming: `require("scope.config")`, `require("scope.backends.treesitter")`, etc.
- **Tests**: plenary.nvim busted-style. One `_spec.lua` per module.

## Key Data Types
- `ScopeNode`: name, kind, range, children[], parent
- `ScopeTree`: root (ScopeNode), source ("treesitter"|"lsp"), bufnr
- `Navigator`: current_node, breadcrumb path, history

## User Commands
- `:ScopeOpen` — open picker at cursor scope
- `:ScopeBrowse` — open picker at file root


## Key Design Decisions

- **Treesitter first, LSP fallback.** Treesitter is fast, works offline, and gives direct access to the syntax tree. LSP is Phase 2.
- **snacks.picker, not a custom UI.** We get fuzzy filtering, the text input prompt, preview, and window management for free. Our code only provides items and custom actions.
- **Navigator is UI-agnostic.** The Navigator knows nothing about pickers. This means Telescope support (Phase 2) is just a new adapter, not a rewrite.
- **Language configs are declarative.** Adding a new language should be a single file with two lists of node types and a name extractor function.

## Critical Assumption

The snacks.picker API must support refreshing items in-place when the user hits Tab/Shift-Tab (drill down / go up). If it doesn't, fallback plan is close-and-reopen the picker. Spike this early (Phase 1D, first task).

## Dependencies

- **Required**: Neovim >= 0.10, snacks.nvim
- **Required for testing**: plenary.nvim, Treesitter grammars (Go, Lua)
- **Optional**: nvim-web-devicons or mini.icons (for symbol kind icons)
- **Phase 2**: telescope.nvim
