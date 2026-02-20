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
- [x] Create `lua/scopes/languages/lua.lua` — scope node types (`function_declaration`, `function_definition`, `if_statement`, `for_statement`, `while_statement`) and symbol node types (`assignment_statement`, `local_declaration`)

### 1.2 Treesitter Backend

- [x] Create `lua/scopes/backends/treesitter.lua` — accept `bufnr`, get Treesitter parse tree, walk nodes, and return a `ScopeTree`
- [x] Implement `ScopeNode` class: `name`, `kind`, `range` (`{start_row, start_col, end_row, end_col}`), `children`, `parent`
- [x] Implement `ScopeTree` class: `root` (virtual file-level node), `source` (`"treesitter"`), `bufnr`
- [x] Add validation to `ScopeNode.new()`, `ScopeNode:add_child()`, and `ScopeTree.new()` — warn-and-continue on invalid inputs
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
- [x] Implement `Navigator:breadcrumb_string()` — return formatted breadcrumb string (e.g., `file.go > MyStruct > HandleRequest`)
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

- [x] Wire `lua/scopes/init.lua` `setup()` to register keymaps (`<leader>so` open at cursor, `<leader>sO` open at root)
- [x] Implement `:ScopeOpen` command — open picker at cursor scope
- [x] Implement `:ScopeBrowse` command — open picker at file root
- [x] Add autocommand to invalidate cached tree on `TextChanged` / `BufWritePost`

### 1.7 MVP Smoke Testing

- [ ] Manual testing: open a Go file, invoke `:ScopeOpen`, drill into a function, go back up, jump to a symbol
- [ ] Manual testing: open a Lua file, repeat the above
- [ ] Verify breadcrumb updates correctly during navigation
- [ ] Verify fuzzy filtering works within a scope
- [ ] Verify graceful behavior on files with syntax errors
- [ ] Revisit validation error handling strategy for ScopeNode/ScopeTree constructors (warn-and-continue vs return nil vs error)
- [ ] Add sibling-overlap validation to `ScopeNode:add_child()`: warn when the new child's range overlaps an existing sibling's range; for siblings on the same row, also check column ranges are non-overlapping. Decide on log level (WARN vs DEBUG) given that ERROR nodes and some LSP servers can produce touching/overlapping ranges legitimately.

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

## Tech Debt

Refactoring tasks identified during code review. None are blocking for functionality, but each improves clarity or correctness.

### TD1: Test Infrastructure

- [ ] **TD1.1** Create `tests/helpers.lua` — extract duplicated test utilities: `find_nodes(root, node_type)` (4× in go_spec/lua_spec), `make_buf(fixture, lang)` buffer setup+teardown (7× across treesitter_spec/go_spec/lua_spec/tree_spec), `find_by_name`, `check_parents`, `check_ranges`, `child_names` (currently only in treesitter_spec), `capture_notify()` (the `vim.notify` stub pattern used 4× in tree_spec with inconsistent global names), `valid_kinds` table (identical in go_spec and lua_spec), `assert_valid_lang_config(cfg)` structural checks (identical block in go_spec and lua_spec)
- [ ] **TD1.2** Delete or restore the commented-out test at `tests/backends/treesitter_spec.lua:132-138` (`func_literal inside RunWithCallback`) — it has no explanation for why it was disabled

### TD2: Naming & Conceptual Clarity

- [ ] **TD2.1** Rename `ScopeNode:is_scope()` method to `has_children()` — `is_scope` already means something else in language configs (the `is_scope` boolean field indicating whether a node type creates a drill-able scope). Two concepts sharing the same name is confusing. Update all call sites and tests, and fix the stale `@field is_scope boolean` annotation in the CLAUDE.md data model doc.
- [ ] **TD2.2** Rename `cache.debounce_ms` → `cache.ttl_ms` in `config.lua` and `tree.lua` — the value is used as a max-age TTL check (`now - timestamp < debounce_ms`), not a debounce. Update the config default key and the comparison in `tree.lua:205`.
- [ ] **TD2.3** Rename the ambiguous `backend` config key at one of its two levels — `cfg.backend` (treesitter vs lsp) and `cfg.picker.backend` (snacks vs telescope) share the same key name. Rename `cfg.picker.backend` to `cfg.picker.engine` or rename the top-level one to `cfg.source_backend`.
- [ ] **TD2.4** Standardise the `_mod` import-suffix convention — `lang_config_mod` (`backends/treesitter.lua:8`) and `tree_mod` (`navigator.lua:1`) use a `_mod` suffix that no other import uses. Either apply it consistently everywhere or drop it from these two.

### TD3: Convention Violations

- [ ] **TD3.1** Fix `vim.bo` and `vim.fn.line` usage in `init.lua` — `init.lua:31` uses `vim.bo[ev.buf].buftype` (should be `vim.api.nvim_get_option_value("buftype", {buf=ev.buf})`); `init.lua:56` uses `vim.fn.line(".")` (should be `vim.api.nvim_win_get_cursor(0)[1]`). Both violate the project convention of `vim.api.*` over shorthands.

### TD4: Config Gaps

- [ ] **TD4.1** Wire picker keybindings from config — `picker.lua:139-142` hardcodes `<Tab>` and `<S-Tab>` as string literals and ignores `cfg.picker.drill_down`, `cfg.picker.go_up`, `cfg.picker.enter`, and `cfg.picker.close` entirely. These four config keys exist but are never read.

### TD5: Architecture

- [ ] **TD5.1** Centralize valid kind strings — the set `{function, method, variable, type, const, block, class}` is defined implicitly in `picker.lua` (icons table), `go_spec.lua`, and `lua_spec.lua`. Export it as a single constant (e.g., in `config.lua` or a new `lua/scopes/kinds.lua`), and validate against it in `lang_config.build()` so a typo like `kind = "Function"` produces a warning at load time rather than a silent icon fallback.
- [ ] **TD5.2** Make `find_scope_for_row` a method on `ScopeTree` — it is currently a free function exported from `tree.lua` (`tree_mod.find_scope_for_row(tree, row)`) that exists solely to serve the navigator. A `scope_tree:find_scope_for_row(row)` method would be more discoverable and avoid exporting an internal concern.
- [ ] **TD5.3** Propagate a fallback name when `name_getter` returns nil — several `name_getter` functions in `go.lua` and `lua.lua` return nil when the expected child node is absent. This nil flows through `lang_config.get_name()` → `treesitter.lua:59` → `ScopeNode.new()`, where a generic "name must be a string" warning fires with no indication of which language/node type caused it. The treesitter backend should fall back to the node type string (same as `lang_config.get_name` already does for unrecognized types) and optionally log the node type for debugging.

### TD6: New Language Ergonomics

- [ ] **TD6.1** Create `lua/scopes/languages/_template.lua` — a documented skeleton for new language contributors. Should explain: the `name_getter` signature and what nil vs string return means, valid `kind` values, what `is_scope` means, how to test against the fixture pattern. Relates to TD5.1 (kind validation) and Phase 3.5 contributing guide.

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
