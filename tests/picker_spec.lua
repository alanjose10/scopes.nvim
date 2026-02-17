--- Tests for lua/scopes/picker.lua
--- Only tests pure functions (make_item, format). open() is not tested here
--- because it depends on snacks.nvim which is not available in the test env.

local tree_mod = require("scopes.tree")
local ScopeNode = tree_mod.ScopeNode
local picker = require("scopes.picker")

--- Build a scope node (with children → is_scope() == true).
local function make_scope_node(opts)
  local node = ScopeNode.new(opts)
  local child = ScopeNode.new({
    name = "inner",
    kind = "variable",
    range = { start_row = opts.range.start_row + 1, start_col = 0, end_row = opts.range.start_row + 1, end_col = 5 },
  })
  node:add_child(child)
  return node
end

--- Build a leaf node (no children → is_scope() == false).
local function make_leaf_node(opts)
  return ScopeNode.new(opts)
end

describe("picker", function()
  describe("make_item", function()
    local node, item

    before_each(function()
      node = make_leaf_node({
        name = "HandleRequest",
        kind = "function",
        range = { start_row = 4, start_col = 0, end_row = 20, end_col = 1 },
      })
      item = picker.make_item(node, 7, "path/to/file.go")
    end)

    it("text equals node.name", function()
      assert.are.equal("HandleRequest", item.text)
    end)

    it("pos is 1-indexed {start_row+1, start_col}", function()
      assert.are.same({ 5, 0 }, item.pos)
    end)

    it("end_pos is 1-indexed {end_row+1, end_col}", function()
      assert.are.same({ 21, 1 }, item.end_pos)
    end)

    it("node field is the original ScopeNode reference", function()
      assert.are.equal(node, item.node)
    end)

    it("kind equals node.kind", function()
      assert.are.equal("function", item.kind)
    end)

    it("buf equals the passed bufnr", function()
      assert.are.equal(7, item.buf)
    end)

    it("file equals the passed buf_name", function()
      assert.are.equal("path/to/file.go", item.file)
    end)
  end)

  describe("format", function()
    local function collect_texts(highlights)
      local texts = {}
      for _, h in ipairs(highlights) do
        texts[#texts + 1] = h[1]
      end
      return texts
    end

    local function find_by_text(highlights, text)
      for _, h in ipairs(highlights) do
        if h[1] == text then
          return h
        end
      end
    end

    local function find_by_hl(highlights, hl)
      for _, h in ipairs(highlights) do
        if h[2] == hl then
          return h
        end
      end
    end

    it("contains the node name", function()
      local node = make_leaf_node({
        name = "MyFunc",
        kind = "function",
        range = { start_row = 9, start_col = 0, end_row = 15, end_col = 1 },
      })
      local item = picker.make_item(node, 1, "f.go")
      local result = picker.format(item, nil)
      local texts = collect_texts(result)
      assert.truthy(vim.tbl_contains(texts, "MyFunc"))
    end)

    it("contains the kind label in [brackets]", function()
      local node = make_leaf_node({
        name = "MyFunc",
        kind = "function",
        range = { start_row = 9, start_col = 0, end_row = 15, end_col = 1 },
      })
      local item = picker.make_item(node, 1, "f.go")
      local result = picker.format(item, nil)
      local texts = collect_texts(result)
      assert.truthy(vim.tbl_contains(texts, "[function]"))
    end)

    it("contains the 1-indexed line number", function()
      local node = make_leaf_node({
        name = "MyFunc",
        kind = "function",
        range = { start_row = 9, start_col = 0, end_row = 15, end_col = 1 },
      })
      local item = picker.make_item(node, 1, "f.go")
      local result = picker.format(item, nil)
      local texts = collect_texts(result)
      -- start_row 9 → line 10
      local found = false
      for _, t in ipairs(texts) do
        if t:find("10") then
          found = true
          break
        end
      end
      assert.is_true(found, "expected line number 10 in format output")
    end)

    it("scope nodes include a drill indicator at the end", function()
      local node = make_scope_node({
        name = "MyFunc",
        kind = "function",
        range = { start_row = 5, start_col = 0, end_row = 20, end_col = 1 },
      })
      local item = picker.make_item(node, 1, "f.go")
      local result = picker.format(item, nil)
      -- Last non-empty highlight should contain the drill indicator
      local last = result[#result]
      assert.truthy(last[1] and last[1] ~= "", "expected drill indicator as last highlight")
      assert.are.equal("  ", last[1])
    end)

    it("leaf nodes do not include a drill indicator", function()
      local node = make_leaf_node({
        name = "myVar",
        kind = "variable",
        range = { start_row = 3, start_col = 0, end_row = 3, end_col = 5 },
      })
      local item = picker.make_item(node, 1, "f.go")
      local result = picker.format(item, nil)
      local texts = collect_texts(result)
      assert.is_false(vim.tbl_contains(texts, "  "), "leaf nodes must not have drill indicator")
    end)

    it("error nodes use DiagnosticError highlight on the name", function()
      local node = ScopeNode.new({
        name = "broken",
        kind = "block",
        range = { start_row = 0, start_col = 0, end_row = 2, end_col = 0 },
        is_error = true,
      })
      local item = picker.make_item(node, 1, "f.go")
      local result = picker.format(item, nil)
      local name_entry = find_by_text(result, "broken")
      assert.truthy(name_entry, "expected to find 'broken' in highlights")
      assert.are.equal("DiagnosticError", name_entry[2])
    end)

    it("normal nodes do not use DiagnosticError highlight on the name", function()
      local node = make_leaf_node({
        name = "goodVar",
        kind = "variable",
        range = { start_row = 0, start_col = 0, end_row = 0, end_col = 5 },
      })
      local item = picker.make_item(node, 1, "f.go")
      local result = picker.format(item, nil)
      local name_entry = find_by_text(result, "goodVar")
      assert.truthy(name_entry, "expected to find 'goodVar' in highlights")
      assert.are_not.equal("DiagnosticError", name_entry[2])
    end)

    it("contains an icon element", function()
      local node = make_leaf_node({
        name = "MyClass",
        kind = "class",
        range = { start_row = 0, start_col = 0, end_row = 10, end_col = 0 },
      })
      local item = picker.make_item(node, 1, "f.go")
      local result = picker.format(item, nil)
      -- Icon element is the first and contains a non-space character
      local first = result[1]
      assert.truthy(first, "expected first highlight to be icon")
      assert.truthy(first[1] and #first[1] > 0, "icon should be non-empty")
    end)
  end)
end)
