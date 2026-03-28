# Python Import Visibility — Design Spec

**Date:** 2026-03-28
**Branch:** fix/python-language-support

## Problem

Python imports (`import os`, `from os import path`, etc.) are invisible in the scopes picker.
The treesitter backend silently passes through any node type not listed in the language config,
so `import_statement` and `import_from_statement` nodes are never surfaced as symbols.

## Fix

Add two new symbol entries to `lua/scopes/languages/python.lua`:

| Node type | kind | is_scope | name shown |
|---|---|---|---|
| `import_statement` | `"const"` | `false` | module name |
| `import_from_statement` | `"const"` | `false` | module name |

Both are non-scoped symbols (leaf nodes in the picker, not drillable).
`kind = "const"` matches the visual treatment Go uses for its `import_spec` entries.

## Name Extraction

**`import_statement`** — reads `node:field("name")[1]`:
- If the child is a plain `dotted_name` → return its text (e.g. `"os"`, `"os.path"`)
- If the child is an `aliased_import` → recurse to its inner `name` field and return the
  module name (e.g. `import numpy as np` → `"numpy"`, not `"np"`)
- Multiple imports on one line (`import a, b`) → show only the first module name

**`import_from_statement`** — reads `node:field("module_name")[1]` directly:
- `from os import path` → `"os"`
- `from os.path import join` → `"os.path"`
- `from . import something` → `"."` (relative import — acceptable fallback)

## Files Changed

| File | Change |
|---|---|
| `lua/scopes/languages/python.lua` | Add `import_statement` and `import_from_statement` entries |
| `tests/fixtures/sample.py` | Add import lines: `import os`, `import numpy as np`, `from os.path import join` |
| `tests/languages/python_spec.lua` | Add `symbol_types` membership tests + `get_name` fixture tests for both new types |

## Test Cases

- `symbol_types` contains `"import_statement"`
- `symbol_types` contains `"import_from_statement"`
- `get_name` on `import_statement` node for `import os` → `"os"`
- `get_name` on `import_statement` node for `import numpy as np` → `"numpy"`
- `get_name` on `import_from_statement` node for `from os.path import join` → `"os.path"`

## Out of Scope

- Multi-name imports (`import a, b`) — only first module shown; acceptable for MVP
- `from __future__ import annotations` — treated identically to any other from-import
- Star imports (`from os import *`) — module name shown (`"os"`), which is correct
