# scopes.nvim

Hierarchical, scope-based symbol navigation for Neovim.

Browse a file's structure like a tree — drill into functions, classes, and blocks to see their contents, then navigate back up to the parent scope. Think of it as a keyboard-driven alternative to sidebar outlines like Aerial, but scoped to where you are in the file.

> **Status:** Early development (Phase 1 MVP in progress)

## Why?

Existing symbol navigation in Neovim is either flat (Telescope/snacks symbol pickers dump everything at once) or spatial (Aerial shows a permanent sidebar). Neither maps well to how you actually think about code — as nested scopes you move in and out of.

scopes.nvim lets you:

- Open a picker showing symbols **in your current scope**
- **Drill into** a function/class/block with `Tab` to see what's inside
- **Go back up** with `Shift-Tab`
- **Jump** to any symbol with `Enter`
- **Filter** with fuzzy search at any level

## Requirements

- Neovim >= 0.10
- [snacks.nvim](https://github.com/folke/snacks.nvim) (picker backend)
- Treesitter grammars for your language

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "alan/scopes.nvim",
  dependencies = { "folke/snacks.nvim" },
  opts = {},
}
```

## Usage

```lua
require("scopes").setup({
  -- All options are optional. These are the defaults:
  backend = "auto",              -- "treesitter" | "lsp" | "auto"
  keymaps = {
    open = "<leader>ss",         -- Open picker at cursor scope
    open_root = "<leader>sS",    -- Open picker at file root
  },
  picker = {
    backend = "snacks",          -- "snacks" | "telescope" (telescope is planned)
    preview = true,
    width = 0.5,
    height = 0.4,
    border = "rounded",
  },
  display = {
    icons = true,
    line_numbers = true,
    breadcrumb = true,
  },
})
```

### Commands

| Command | Description |
|---|---|
| `:ScopeOpen` | Open scope picker at cursor position |
| `:ScopeBrowse` | Open scope picker at file root |

### Picker Keybindings

| Key | Action |
|---|---|
| `Enter` | Jump to symbol |
| `Tab` | Drill into scope |
| `Shift-Tab` | Go to parent scope |
| `Esc` / `q` | Close picker |
| Type in prompt | Fuzzy filter current scope |

A breadcrumb trail in the picker title shows your current position in the scope hierarchy (e.g., `main.go > MyStruct > HandleRequest`).

## Supported Languages

| Language | Status |
|---|---|
| Go | Phase 1 (in progress) |
| Lua | Phase 1 (in progress) |
| TypeScript | Phase 2 (planned) |
| Python | Phase 2 (planned) |

Adding a new language is a single file with Treesitter node type mappings. See `lua/scopes/languages/` for examples.

## How It Works

scopes.nvim builds a tree from your file's Treesitter parse tree (with LSP as a planned fallback), then lets you navigate that tree through a picker. The architecture has four layers:

1. **Language configs** — declarative mappings from Treesitter node types to scope/symbol categories
2. **Tree builder** — converts Treesitter nodes into a unified `ScopeTree`
3. **Navigator** — UI-agnostic state machine for drill-down/go-up/jump
4. **Picker integration** — thin adapter wiring the Navigator to snacks.picker

## License

MIT
