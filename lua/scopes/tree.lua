--- Tree builder facade.
--- Public API for building ScopeTree from a buffer.
--- Selects backend based on config and provides cursor-to-scope resolution.

local config = require("scopes.config")

local M = {}

--- @type table<number, {tree: ScopeTree, tick: number}>
local cache = {}

--- @type table<number, any>
local debounce_timers = {}

--- Build a ScopeTree from a buffer.
--- Selects backend based on config ("auto", "treesitter", or "lsp").
--- @param bufnr number
--- @param opts? { force?: boolean }
--- @return ScopeTree|nil tree
--- @return string|nil error
function M.build(bufnr, opts)
  opts = opts or {}
  local cfg = config.get()

  -- Check cache first (unless forced rebuild)
  if not opts.force and cfg.cache.enabled then
    local cached = cache[bufnr]
    if cached then
      local current_tick = vim.api.nvim_buf_get_changedtick(bufnr)
      if cached.tick == current_tick then
        return cached.tree, nil
      end
    end
  end

  local tree, err

  local backend = cfg.backend or "auto"

  if backend == "treesitter" or backend == "auto" then
    local ts_backend = require("scopes.backends.treesitter")
    tree, err = ts_backend.build(bufnr)

    if tree then
      -- Cache the result
      if cfg.cache.enabled then
        cache[bufnr] = {
          tree = tree,
          tick = vim.api.nvim_buf_get_changedtick(bufnr),
        }
      end
      return tree, nil
    end

    -- If auto mode and treesitter failed, try LSP
    if backend == "auto" then
      local lsp_ok, lsp_backend = pcall(require, "scopes.backends.lsp")
      if lsp_ok and lsp_backend then
        tree, err = lsp_backend.build(bufnr)
        if tree then
          if cfg.cache.enabled then
            cache[bufnr] = {
              tree = tree,
              tick = vim.api.nvim_buf_get_changedtick(bufnr),
            }
          end
          return tree, nil
        end
      end
    end
  elseif backend == "lsp" then
    local lsp_ok, lsp_backend = pcall(require, "scopes.backends.lsp")
    if lsp_ok and lsp_backend then
      tree, err = lsp_backend.build(bufnr)
      if tree then
        if cfg.cache.enabled then
          cache[bufnr] = {
            tree = tree,
            tick = vim.api.nvim_buf_get_changedtick(bufnr),
          }
        end
        return tree, nil
      end
    else
      err = "LSP backend not available"
    end
  else
    err = "unknown backend: " .. tostring(backend)
  end

  return nil, err
end

--- Find the deepest scope containing the given cursor position.
--- @param scope_tree ScopeTree
--- @param row number 0-indexed row
--- @return ScopeNode
function M.find_scope_at_cursor(scope_tree, row)
  local result = scope_tree.root
  M._find_deepest(scope_tree.root, row, function(node)
    result = node
  end)
  return result
end

--- Internal recursive helper for finding deepest scope.
--- @param node ScopeNode
--- @param row number
--- @param on_found fun(node: ScopeNode)
function M._find_deepest(node, row, on_found)
  if not node.is_scope then
    return
  end

  if node.range then
    if row < node.range.start_row or row > node.range.end_row then
      return
    end
  end

  on_found(node)

  for _, child in ipairs(node.children) do
    if child.is_scope and child.range then
      if row >= child.range.start_row and row <= child.range.end_row then
        M._find_deepest(child, row, on_found)
      end
    end
  end
end

--- Invalidate the cache for a specific buffer.
--- @param bufnr number
function M.invalidate(bufnr)
  cache[bufnr] = nil
end

--- Invalidate all cached trees.
function M.invalidate_all()
  cache = {}
end

--- Set up autocommands for cache invalidation with debouncing.
--- @param bufnr number
function M.setup_autocmds(bufnr)
  local cfg = config.get()
  if not cfg.cache.enabled then
    return
  end

  local group = vim.api.nvim_create_augroup("scopes_cache_" .. bufnr, { clear = true })

  vim.api.nvim_create_autocmd({ "TextChanged", "BufWritePost" }, {
    group = group,
    buffer = bufnr,
    callback = function()
      -- Debounce: cancel any pending invalidation
      if debounce_timers[bufnr] then
        debounce_timers[bufnr]:stop()
      end

      local timer = vim.uv.new_timer()
      debounce_timers[bufnr] = timer
      timer:start(cfg.cache.debounce_ms, 0, vim.schedule_wrap(function()
        M.invalidate(bufnr)
        timer:stop()
        timer:close()
        debounce_timers[bufnr] = nil
      end))
    end,
  })

  -- Clean up on buffer delete
  vim.api.nvim_create_autocmd("BufDelete", {
    group = group,
    buffer = bufnr,
    callback = function()
      M.invalidate(bufnr)
      if debounce_timers[bufnr] then
        debounce_timers[bufnr]:stop()
        debounce_timers[bufnr]:close()
        debounce_timers[bufnr] = nil
      end
    end,
  })
end

return M
