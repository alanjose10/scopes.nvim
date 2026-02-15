  
**Product Requirements Document**

*scope.nvim*

Hierarchical Scope Browser for Neovim

| Version | 0.1.0 (Draft) |
| :---- | :---- |
| **Author** | Alan |
| **Date** | February 2026 |
| **Status** | Draft / RFC |

# **1\. Overview**

scope.nvim is a Neovim plugin that enables hierarchical, tree-based navigation of code symbols within a file. Unlike flat symbol pickers (such as Telescope LSP symbols or snacks.picker), scope.nvim treats the code structure as a navigable tree, allowing the user to drill into and out of scopes (functions, classes, blocks) interactively.

The plugin presents a floating picker window showing symbols in the current scope. The user can select a symbol to jump to it, drill into a scope to see its children, or navigate back up to the parent scope. This interaction model maps naturally to how developers mentally model code structure, especially in large files.

# **2\. Problem Statement**

When navigating large files (500+ lines), existing tools have significant limitations:

* Flat symbol lists (Telescope, snacks.picker) dump all symbols at once, making it hard to locate items within deeply nested scopes.

* Aerial/sidebar views show the full tree but require visual scanning and mouse interaction; they occupy permanent screen real estate.

* Built-in search (/ or grep) requires the user to already know the name of what they are looking for.

* Go-to-definition and references work for cross-file navigation but not for browsing within a single file.

scope.nvim fills the gap: a keyboard-driven, scope-aware symbol browser that lets you navigate a file the way you think about it.

# **3\. Target Users**

* Developers working in Neovim who regularly navigate files with 300+ lines.

* Users of Go, TypeScript, Python, Rust, Lua, and other languages with well-supported Treesitter grammars and/or LSP servers.

* Keyboard-centric developers who prefer modal workflows over mouse-driven sidebars.

# **4\. Core Features**

## **4.1 Scope-Aware Picker**

Rather than implementing a standalone floating window, scope.nvim integrates with existing picker ecosystems as a custom source/extension for snacks.picker (primary) and Telescope (secondary). The picker lists symbols within the current scope, determined by cursor position on invocation. The picker includes an always-visible text input box for real-time fuzzy filtering of the current scope’s symbols.

* Shows symbol name, kind (function, variable, type, etc.), and line number.

* Symbols are ordered by their position in the file (top to bottom).

* The picker title/header shows the current scope path as a breadcrumb (e.g., package \> MyStruct \> HandleRequest).

## **4.2 Drill-Down Navigation**

| Key | Action | Behaviour |
| :---- | :---- | :---- |
| Enter / CR | Jump to symbol | Close picker, move cursor to the selected symbol in the buffer. |
| Tab | Drill into scope | If the selected symbol is a scope (function, class, block), replace the picker contents with that scope’s children. Update breadcrumb. |
| Shift-Tab | Go to parent scope | Navigate up one level in the tree. If already at the file root, do nothing (or flash/beep). |
| j / k or ↓ / ↑ | Cycle through items | Standard vertical navigation within the picker list. |
| Esc / q | Close picker | Dismiss the picker without jumping. |
| Text input (prompt) | Fuzzy filter | Always-visible text input box at top of picker. Typing filters current scope’s symbols in real time using fuzzy matching. Handled natively by snacks.picker/Telescope. |

## **4.3 Preview (Optional, Phase 2\)**

While navigating the picker results, the buffer cursor temporarily moves to the highlighted symbol (peek preview). On dismiss, the cursor returns to its original position. On confirm, the cursor stays. This leverages the preview capabilities of snacks.picker/Telescope.

## **4.4 Scope Breadcrumb**

A breadcrumb trail shown in the picker’s title or prompt area, displaying the current navigation path. Example: file.go \> MyStruct \> HandleRequest \> if err \!= nil. Selecting any segment of the breadcrumb (stretch goal) could navigate directly to that level.

# **5\. Technical Design**

## **5.1 Data Source Strategy**

The plugin should support two backends, with Treesitter as the primary and LSP as a fallback. This dual approach handles the trade-offs well:

| Aspect | Treesitter | LSP |
| :---- | :---- | :---- |
| **Speed** | Very fast; local parse tree, no RPC overhead. | Depends on server; can be slow on large repos. |
| **Accuracy** | Syntax-level; does not understand types, imports, or semantic relationships. | Semantically accurate; understands the full project. |
| **Error tolerance** | Good; Treesitter uses error recovery and partial parses. | Varies; some LSP servers struggle with broken syntax. |
| **Scope awareness** | Excellent; direct access to the syntax tree and node hierarchy. | DocumentSymbol provides hierarchy, but not all servers implement it fully. |
| **Setup** | Requires Treesitter grammar installed for the language. | Requires a running LSP server attached to the buffer. |

Recommendation: Use Treesitter as default. Fall back to LSP textDocument/documentSymbol when Treesitter grammar is unavailable. Allow the user to force a specific backend via configuration.

## **5.2 Architecture**

The plugin is structured into four layers:

1. Tree Builder: Consumes Treesitter nodes or LSP DocumentSymbol responses and produces a unified ScopeTree data structure (a tree of ScopeNode objects).

2. Navigator: Maintains state (current node, path/breadcrumb, history). Exposes methods: enter(), drill\_down(), go\_up(), filter().

3. Picker Integration: A custom source/extension for snacks.picker (primary) and Telescope (secondary). Provides the item list, handles drill-down/go-up actions via custom key mappings, and delegates navigation logic to the Navigator. Fuzzy filtering is handled natively by the host picker’s built-in text input.

4. Integration Layer: Exposes user commands (:ScopeOpen, :ScopeBrowse) and configurable keymaps. Handles autocommands for re-parsing on file change. Manages picker backend selection (snacks vs Telescope).

## **5.3 ScopeTree Data Structure**

\--- @class ScopeNode  
\--- @field name string          \-- Display name (e.g., "HandleRequest")  
\--- @field kind string          \-- Symbol kind ("function", "variable", "class", etc.)  
\--- @field range Range          \-- {start\_row, start\_col, end\_row, end\_col}  
\--- @field children ScopeNode\[\] \-- Child nodes in this scope  
\--- @field parent ScopeNode|nil \-- Back-reference to parent (set during build)

\--- @class ScopeTree  
\--- @field root ScopeNode       \-- Virtual root (file-level scope)  
\--- @field source string        \-- "treesitter" | "lsp"  
\--- @field bufnr number         \-- Buffer this tree was built from

## **5.4 Error Handling Strategy**

Code errors in the buffer will affect the quality of the tree. The plugin should handle this gracefully:

* Treesitter: The parser performs error recovery automatically. Nodes marked as ERROR in the syntax tree should be shown in the picker with a visual indicator (e.g., dimmed or marked with a warning icon) but not excluded. This lets the user still navigate partially broken files.

* LSP: If the LSP server returns empty or stale symbols due to errors, the plugin should fall back to the last known good tree or fall back to Treesitter for that buffer.

* If both backends fail, show an informative message rather than an empty picker (e.g., "Unable to parse symbols. Check for syntax errors.").

* Debounce re-parsing on TextChanged to avoid flickering during rapid edits.

# **6\. Configuration**

require("scope").setup({  
  backend \= "auto",           \-- "treesitter" | "lsp" | "auto"  
  keymaps \= {  
    open \= "\<leader\>ss",      \-- Open scope picker at cursor  
    open\_root \= "\<leader\>sS", \-- Open scope picker at file root  
  },  
  picker \= {  
    enter \= "\<CR\>",           \-- Jump to symbol  
    drill\_down \= "\<Tab\>",     \-- Enter child scope  
    go\_up \= "\<S-Tab\>",        \-- Return to parent scope  
    close \= { "\<Esc\>", "q" },  
    backend \= "snacks",      \-- "snacks" | "telescope"  
    preview \= true,           \-- Enable peek preview  
    width \= 0.5,              \-- Picker width (fraction of editor)  
    height \= 0.4,             \-- Picker height (fraction of editor)  
    border \= "rounded",  
  },  
  display \= {  
    icons \= true,             \-- Show Nerd Font icons per symbol kind  
    line\_numbers \= true,      \-- Show line numbers next to symbols  
    breadcrumb \= true,        \-- Show scope path in picker title  
  },  
  treesitter \= {  
    \-- Language-specific node types to treat as scopes  
    scope\_types \= {  
      go \= { "function\_declaration", "method\_declaration",  
             "func\_literal", "if\_statement", "for\_statement" },  
      lua \= { "function\_declaration", "function\_definition",  
             "if\_statement", "for\_statement" },  
    },  
  },  
  cache \= {  
    enabled \= true,  
    debounce\_ms \= 300,        \-- Debounce re-parse on text change  
  },  
})

# **7\. Language Support**

Phase 1 should focus on languages with mature Treesitter grammars and predictable scope structures. The following are the initial target languages:

| Language | Scope Nodes | Symbol Nodes | Notes |
| :---- | :---- | :---- | :---- |
| **Go** | function\_declaration, method\_declaration, func\_literal, if/for/select | var\_spec, const\_spec, short\_var\_declaration, type\_declaration | Primary dev language; first-class support. |
| **Lua** | function\_declaration, function\_definition, if/for/while | assignment\_statement, local\_declaration | Required for dogfooding (Neovim config). |
| **TypeScript** | function\_declaration, arrow\_function, class\_declaration, method\_definition | variable\_declarator, property\_signature, type\_alias\_declaration | High demand; complex scope nesting. |
| **Python** | function\_definition, class\_definition, if/for/while/with | assignment, global\_statement | Indentation-based; test thoroughly. |

Additional languages can be added by contributing scope\_types and symbol\_types mappings. The plugin should degrade gracefully for unsupported languages by using generic Treesitter node heuristics or falling back to LSP.

# **8\. Development Plan**

## **8.1 Phase 1: Core (MVP)**

* Treesitter-based tree builder for Go and Lua.

* snacks.picker source with Enter (jump), Tab (drill-down), Shift-Tab (go up), Esc (close). Built-in text input for fuzzy filtering.

* Breadcrumb display in picker title.

* Setup function with sensible defaults.

## **8.2 Phase 2: Polish**

* LSP fallback backend (textDocument/documentSymbol).

* Peek preview while navigating.

* Telescope extension support (snacks.picker is Phase 1).

* Icon support (Nerd Fonts / nvim-web-devicons).

* TypeScript and Python support.

## **8.3 Phase 3: Advanced**

* Breadcrumb click/select navigation (if feasible within the picker framework).

* Persistent sidebar mode (opt-in, similar to Aerial).

* Symbol bookmarks / recent jumps history.

* Treesitter-based scope folding integration.

* Community language support contributions.

# **9\. Working with Claude Code**

This section provides guidance for developing scope.nvim effectively with Claude Code as a development partner.

## **9.1 Project Setup**

Start by scaffolding the project structure. Create a CLAUDE.md file in the repo root to give Claude Code persistent context about the project:

\# scope.nvim

Neovim plugin for hierarchical scope-based symbol navigation.  
Written in Lua. Uses Treesitter (primary) and LSP (fallback).

\#\# Structure  
lua/scope/init.lua       \-- Setup \+ public API  
lua/scope/tree.lua       \-- ScopeTree builder (TS \+ LSP)  
lua/scope/navigator.lua  \-- State machine for drill/up/jump  
lua/scope/picker.lua     \-- Picker source (snacks \+ telescope)  
lua/scope/config.lua     \-- Default config \+ merge logic  
lua/scope/languages/     \-- Per-language scope\_types

\#\# Testing  
Tests use plenary.nvim: \`nvim \--headless \-c "PlenaryBustedDirectory tests/"\`

\#\# Conventions  
\- Lua style: snake\_case, type annotations via LuaLS/EmmyLua  
\- All Neovim API calls go through vim.api, not vim.fn  
\- Error handling: never crash, always degrade gracefully

## **9.2 Recommended Workflow**

1. Start with the data model: Ask Claude Code to implement the ScopeNode and ScopeTree types in tree.lua, with unit tests that parse a sample Go file using Treesitter and assert the tree structure.

2. Build the navigator: Implement the state machine with tests for drill\_down, go\_up, and enter operations. Keep it decoupled from the UI.

3. Build the picker integration: Implement the snacks.picker source first (it has a simpler API). Wire the Navigator into the picker’s custom action mappings for Tab/Shift-Tab. Telescope support can follow using a similar adapter pattern.

4. Integrate and iterate: Wire up commands, autocommands, and user configuration. Add languages one at a time.

## **9.3 Tips for Effective Claude Code Usage**

* Keep the CLAUDE.md up to date as the project evolves. Claude Code reads it on every session start.

* Use task-oriented prompts: “Implement the Treesitter tree builder for Go in lua/scope/tree.lua. It should accept a bufnr, get the TS tree, and return a ScopeTree.”

* Ask Claude Code to write tests alongside implementation. Neovim plugin testing with plenary.nvim is well-supported.

* For tricky Treesitter queries, ask Claude Code to explore the syntax tree first: “Write a script that prints the Treesitter node types for this Go file so we can identify which nodes to use as scope boundaries.”

* When debugging, share error output and the relevant file. Claude Code can trace through Lua code effectively.

# **10\. Project Structure**

scope.nvim/  
├── lua/  
│   └── scope/  
│       ├── init.lua          \-- setup(), public commands  
│       ├── config.lua        \-- defaults, merge, validation  
│       ├── tree.lua          \-- ScopeTree / ScopeNode builder  
│       ├── navigator.lua     \-- navigation state machine  
│       ├── picker.lua        \-- snacks.picker source \+ telescope extension  
│       ├── backends/  
│       │   ├── treesitter.lua \-- TS-specific tree building  
│       │   └── lsp.lua        \-- LSP DocumentSymbol adapter  
│       └── languages/  
│           ├── go.lua         \-- Go scope/symbol node types  
│           ├── lua.lua        \-- Lua scope/symbol node types  
│           ├── typescript.lua \-- TS scope/symbol node types  
│           └── python.lua     \-- Python scope/symbol node types  
├── plugin/  
│   └── scope.lua             \-- vim.api.nvim\_create\_user\_command  
├── tests/  
│   ├── tree\_spec.lua         \-- ScopeTree unit tests  
│   ├── navigator\_spec.lua    \-- Navigator state tests  
│   └── fixtures/             \-- Sample source files for testing  
├── CLAUDE.md                     \-- Claude Code project context  
├── README.md  
└── LICENSE

# **11\. Success Metrics**

* Picker opens in under 50ms for files up to 2,000 lines.

* Treesitter tree build completes in under 20ms for typical source files.

* Drill-down/go-up transitions feel instant (no perceptible lag).

* Plugin handles syntax errors gracefully: no crashes, partial tree shown.

* Personally useful for daily Go development within 2 weeks of starting.

# **12\. Open Questions**

* Should anonymous scopes (e.g., Go func literals passed as arguments) appear as named items or be grouped under a generic label?

* How deep should the tree go? Should individual if/for blocks be drillable, or should there be a configurable depth limit?

* How should the plugin handle differences between snacks.picker and Telescope APIs for custom actions (drill-down/go-up)? Should there be a shared adapter interface?

* How should multi-cursor / split-window scenarios be handled?

* Should there be a way to bookmark frequently visited scopes within a file?

# **13\. References**

* Aerial.nvim: https://github.com/stevearc/aerial.nvim

* Snacks.nvim picker: https://github.com/folke/snacks.nvim

* Neovim Treesitter API: :help treesitter, :help vim.treesitter

* LSP DocumentSymbol: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/\#textDocument\_documentSymbol

* Plenary.nvim (testing): https://github.com/nvim-lua/plenary.nvim