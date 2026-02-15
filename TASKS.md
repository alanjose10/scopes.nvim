# scopes.nvim - Task Breakdown

Derived from the [PRD](scopes-nvim-prd.md). Tasks are ordered by dependency within each phase.

---

## Phase 0: Project Scaffolding

- [x] Create directory structure (`lua/scopes/`, `lua/scopes/backends/`, `lua/scopes/languages/`, `plugin/`, `tests/`, `tests/fixtures/`)
- [x] Create `CLAUDE.md` with project context (structure, conventions, testing)
- [x] Create `lua/scopes/config.lua` — default config table, `merge()` function to deep-merge user config with defaults, validation
- [x] Create `lua/scopes/init.lua` — `setup(opts)` entry point that calls config merge
- [x] Create `plugin/scopes.lua` — `:ScopeOpen` and `:ScopeBrowse` user commands (stubs wired to init)
- [x] Add test fixtures: sample Go file (`tests/fixtures/sample.go`) and Lua file (`tests/fixtures/sample.lua`) with nested scopes

---

## Phase 1: Core (MVP)

### 1.1 Language Definitions

- [x] Create `lua/scopes/languages/go.lua` — scope node types (`function_declaration`, `method_declaration`, `func_literal`, `if_statement`, `for_statement`, `select_statement`) and symbol node types (`var_spec`, `const_spec`, `short_var_declaration`, `type_declaration`)
- [x] Create `lua/scopes/languages/lua.lua` — scope node types (`function_declaration`, `function_definition`, `if_statement`, `for_statement`, `while_statement`) and symbol node types (`assignment_statement`, `variable_declaration`)

### 1.2 Treesitter Backend

- [x] Create `lua/scopes/backends/treesitter.lua` — accept `bufnr`, get Treesitter parse tree, walk nodes, and return a `ScopeTree`
- [x] Implement `ScopeNode` class: `name`, `kind`, `range` (`{start_row, start_col, end_row, end_col}`), `children`, `parent`
- [x] Implement `ScopeTree` class: `root` (virtual file-level node), `source` (`"treesitter"`), `bufnr`
- [x] Resolve node names from Treesitter (extract identifier/name child from scope nodes)
- [x] Load language-specific scope/symbol types from `lua/scopes/languages/`; fall back to generic heuristics for unsupported languages
- [x] Handle Treesitter ERROR nodes — include in tree with a visual indicator flag
- [x] Write `tests/tree_spec.lua` — parse fixture files, assert tree structure (depth, node names, kinds, parent links)

### 1.3 Navigator

- [x] Create `lua/scopes/navigator.lua` — state machine holding `current_node`, `breadcrumb` path, cursor position
- [x] Implement `Navigator:new(scope_tree, opts)` — initialize at file root or at scope containing cursor position
- [x] Implement `Navigator:items()` — return list of children of current node (for picker display)
- [x] Implement `Navigator:drill_down(node)` — set current node to selected child scope, update breadcrumb
- [x] Implement `Navigator:go_up()` — move current node to parent; no-op at root
- [x] Implement `Navigator:enter(node)` — return target buffer position for jumping
- [x] Implement `Navigator:breadcrumb()` — return formatted breadcrumb string (e.g., `file.go > MyStruct > HandleRequest`)
- [x] Write `tests/navigator_spec.lua` — test drill-down, go-up, enter, breadcrumb, root boundary

### 1.4 Tree Builder (facade)

- [x] Create `lua/scopes/tree.lua` — public `build(bufnr, opts)` function that selects backend based on config (`"auto"` / `"treesitter"` / `"lsp"`) and returns a `ScopeTree`
- [x] Implement cursor-to-scope resolution: given a cursor position and a `ScopeTree`, find the deepest scope containing the cursor
- [x] Add debounced caching: store last tree per buffer, re-build on `TextChanged`/`BufEnter` with configurable debounce (`cache.debounce_ms`)

### 1.5 Snacks.picker Integration

- [x] Create `lua/scopes/picker.lua` — snacks.picker custom source
- [x] Format picker items: symbol name, kind label, line number
- [x] Wire `<CR>` (Enter) action — call `Navigator:enter()`, close picker, jump cursor
- [x] Wire `<Tab>` action — call `Navigator:drill_down()` on selected item, refresh picker items
- [x] Wire `<S-Tab>` action — call `Navigator:go_up()`, refresh picker items
- [x] Wire `<Esc>` / `q` — close picker, restore cursor to original position
- [x] Display breadcrumb in picker title/header
- [x] Fuzzy filtering via snacks.picker built-in text input (no custom work needed, just ensure source refreshes correctly)
- [x] Respect picker config: `width`, `height`, `border`

### 1.6 Integration & Commands

- [x] Wire `lua/scopes/init.lua` `setup()` to register keymaps (`<leader>ss` open at cursor, `<leader>sS` open at root)
- [x] Implement `:ScopeOpen` command — open picker at cursor scope
- [x] Implement `:ScopeBrowse` command — open picker at file root
- [x] Add autocommand to invalidate cached tree on `TextChanged` / `BufWritePost`

### 1.7 MVP Smoke Testing

- [ ] Manual testing: open a Go file, invoke `:ScopeOpen`, drill into a function, go back up, jump to a symbol
- [ ] Manual testing: open a Lua file, repeat the above
- [ ] Verify breadcrumb updates correctly during navigation
- [ ] Verify fuzzy filtering works within a scope
- [ ] Verify graceful behavior on files with syntax errors

---

## Phase 2: Polish

### 2.1 LSP Fallback Backend

- [ ] Create `lua/scopes/backends/lsp.lua` — request `textDocument/documentSymbol`, convert `DocumentSymbol[]` response into `ScopeTree`
- [ ] Map LSP `SymbolKind` enum to display kind strings
- [ ] Handle LSP returning flat `SymbolInformation[]` (no hierarchy) — build a flat list under root
- [ ] Handle empty/stale LSP responses — fall back to last known good tree or Treesitter
- [ ] Update `tree.lua` `build()` — in `"auto"` mode, try Treesitter first, then LSP
- [ ] Write `tests/lsp_spec.lua` — test with mock DocumentSymbol responses

### 2.2 Peek Preview

- [ ] Implement preview in `picker.lua` — on item highlight, temporarily move buffer cursor to symbol location
- [ ] On picker dismiss (`<Esc>`/`q`), restore cursor to original position
- [ ] On picker confirm (`<CR>`), keep cursor at symbol
- [ ] Respect `picker.preview` config toggle
- [ ] Leverage snacks.picker / Telescope native preview if available

### 2.3 Telescope Extension

- [ ] Create Telescope extension adapter in `picker.lua` (or separate `lua/scopes/telescope.lua`)
- [ ] Implement Telescope finder that returns Navigator items
- [ ] Wire custom actions for `<Tab>` (drill-down) and `<S-Tab>` (go-up) via Telescope `attach_mappings`
- [ ] Breadcrumb display in Telescope prompt title
- [ ] Respect `picker.backend` config to select snacks vs Telescope

### 2.4 Icon Support

- [ ] Add icon mappings per symbol kind (function, variable, class, method, type, etc.) using Nerd Font codepoints
- [ ] Integrate with `nvim-web-devicons` if available, fall back to built-in icon table
- [ ] Respect `display.icons` config toggle
- [ ] Show icons in picker item formatting (prefix before symbol name)

### 2.5 Additional Language Support

- [ ] Create `lua/scopes/languages/typescript.lua` — scope types (`function_declaration`, `arrow_function`, `class_declaration`, `method_definition`, `if_statement`, `for_statement`) and symbol types (`variable_declarator`, `property_signature`, `type_alias_declaration`)
- [ ] Create `lua/scopes/languages/python.lua` — scope types (`function_definition`, `class_definition`, `if_statement`, `for_statement`, `while_statement`, `with_statement`) and symbol types (`assignment`, `global_statement`)
- [ ] Add test fixtures: `tests/fixtures/sample.ts`, `tests/fixtures/sample.py`
- [ ] Write tree-building tests for TypeScript and Python fixtures
- [ ] Test indentation-based Python scoping thoroughly

### 2.6 Display Options

- [ ] Implement `display.line_numbers` toggle — show/hide line numbers in picker items
- [ ] Implement `display.breadcrumb` toggle — show/hide breadcrumb in picker title

---

## Phase 3: Advanced

### 3.1 Breadcrumb Interactive Navigation

- [ ] Make breadcrumb segments selectable/clickable (if picker framework supports it)
- [ ] Selecting a breadcrumb segment navigates directly to that scope level
- [ ] Fall back to non-interactive breadcrumb if framework doesn't support it

### 3.2 Persistent Sidebar Mode

- [ ] Implement opt-in sidebar view (similar to Aerial) showing full scope tree
- [ ] Sidebar updates on cursor move and buffer changes
- [ ] Support toggle command (`:ScopeToggleSidebar`)
- [ ] Highlight current scope in sidebar based on cursor position

### 3.3 Symbol Bookmarks & Recent Jumps

- [ ] Track recent scope jumps per buffer (ring buffer, configurable size)
- [ ] Provide `:ScopeRecent` command to show recent jump targets
- [ ] Allow bookmarking specific scopes within a file
- [ ] Persist bookmarks across sessions (optional, via shada or JSON file)

### 3.4 Scope Folding Integration

- [ ] Integrate with Neovim's fold system (`foldmethod=expr`)
- [ ] Provide fold expression based on scope tree depth
- [ ] Command to fold/unfold all scopes at a given depth level

### 3.5 Community Language Support

- [ ] Document how to add a new language (contributing guide)
- [ ] Provide a template `lua/scopes/languages/_template.lua`
- [ ] Add generic fallback heuristics for languages without explicit definitions
- [ ] Accept community PRs for Rust, Java, C/C++, Ruby, etc.

---

## Performance Targets (from PRD)

- Picker opens in under 50ms for files up to 2,000 lines
- Treesitter tree build completes in under 20ms for typical source files
- Drill-down/go-up transitions feel instant (no perceptible lag)
- Graceful degradation on syntax errors (no crashes, partial tree shown)
