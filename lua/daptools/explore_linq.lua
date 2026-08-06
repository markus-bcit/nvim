-- Lightweight "Explore LINQ" helper for nvim-dap + netcoredbg.
--
-- Rider's Explore LINQ is a debugger visualizer that shows, per LINQ operator,
-- the intermediate sequence and (for EF Core) the translated SQL. netcoredbg/DAP
-- doesn't expose per-operator intermediate sequences, so we can't replicate the
-- chain view. This helper covers the practical day-to-day need:
--   - For an IEnumerable<T> variable/expression: materialize it (.ToList()) and
--     render the first N items as a table by fetching each item's properties.
--   - For an IQueryable<T>: also evaluate .ToQueryString() (EF Core 5+) and
--     show the translated SQL above the table.
--
-- Usage:
--   - Normal mode <leader>dL: explore the word under the cursor (a variable).
--   - Visual mode <leader>dL: explore the selected expression.
--   Requires an active debug session stopped at a breakpoint (so the current
--   frame can evaluate expressions against the live debuggee).

local M = {}

local MAX_ITEMS = 50
local MAX_VALUE_LEN = 120

---Get the expression to explore: visual selection text if in visual mode, else
---the word under the cursor.
local function get_expression()
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    local ok, region = pcall(vim.fn.getregion, vim.fn.getpos("v"), vim.fn.getpos("."), { type = mode })
    if ok and region and #region > 0 then
      return table.concat(region, " ")
    end
    return nil
  end
  local w = vim.fn.expand("<cword>")
  if w and w ~= "" then return w end
  return nil
end

---Normalize a selection that is a statement into an expression:
---  - strip a leading `var <ident> = ` / `using var <ident> = ` / `<type> <ident> = `
---  - strip a trailing `;`
---  - collapse newlines to spaces, trim
--- Returns (expr, had_statement_prefix) so the caller can message accordingly.
local function normalize_expression(text)
  if not text then return nil, false end
  local had_prefix = false
  local s = text:gsub("\n", " "):gsub("\r", " ")
  -- strip leading `var X = ` / `using var X = ` (statement declaration)
  local new = s:gsub("^%s*using%s+var%s+([%w_]+)%s*=%s*", "")
  if new ~= s then s = new; had_prefix = true else
    new = s:gsub("^%s*var%s+([%w_]+)%s*=%s*", "")
    if new ~= s then s = new; had_prefix = true end
  end
  -- strip trailing `;`
  new = s:gsub("%s*;%s*$", "")
  if new ~= s then s = new; had_prefix = true end
  s = s:gsub("^%s+", ""):gsub("%s+$", "")
  return s, had_prefix
end

---Fetch child variables of a variablesReference (one DAP `variables` request).
local function fetch_children(session, ref, cb)
  if not ref or ref == 0 then cb({}) return end
  session:request("variables", { variablesReference = ref }, function(err, resp)
    if err or not resp or not resp.variables then cb({}) return end
    cb(resp.variables)
  end)
end

---Evaluate an expression in the current frame and return {result, type, variablesReference}.
local function evaluate(session, expr, cb)
  local frame = session.current_frame
  if not frame then cb(nil, "no current stack frame (not paused at a breakpoint?)") return end
  session:request("evaluate", {
    expression = expr,
    frameId = frame.id,
    context = "repl",
  }, function(err, resp)
    if err or not resp then cb(nil, err and err.message or "evaluate failed") return end
    cb({
      result = resp.result,
      type = resp.type,
      variablesReference = resp.variablesReference,
    })
  end)
end

---Is this child name an indexed list element like `[0]`, `[1]`, ...?
local function is_indexed_item(name)
  return name ~= nil and name:match("^%[(%d+)%]$") ~= nil
end

---Skip noisy inherited/interface members when listing an item's fields.
---Catches `System.Collections.IList.Item` (indexer that throws TargetParameterCountException),
---`System.Collections.ICollection.SyncRoot`, `Static members`, etc.
local function is_noisy_prop(name)
  if not name or name == "" then return true end
  if name == "Static members" then return true end
  if name:match("^System%.") then return true end
  return false
end

---Build a list of items from a materialized list's children.
---Only indexed children (`[0]`, `[1]`, ...) are treated as items; the list's own
---members (Capacity, Count, SyncRoot, Item, Static members, ...) are skipped.
---Each item's fields are fetched (one `variables` request per item, up to MAX_ITEMS).
---Returns (rows, truncated_count). Each row = { index, type, fields = {{name,value},...} }.
local function build_item_table(session, list_ref, cb)
  fetch_children(session, list_ref, function(children)
    if not children or #children == 0 then cb({}, 0, nil) return end
    local items = {}
    for _, c in ipairs(children) do
      if is_indexed_item(c.name) then table.insert(items, c) end
    end
    if #items == 0 then
      local dump = {}
      for _, c in ipairs(children) do
        table.insert(dump, string.format("  name=%q value=%q type=%q ref=%d",
          c.name or "", c.value or "", c.type or "", c.variablesReference or 0))
      end
      cb({}, 0, dump)
      return
    end
    local truncated = 0
    local limited = items
    if #limited > MAX_ITEMS then
      truncated = #limited - MAX_ITEMS
      limited = { unpack(items, 1, MAX_ITEMS) }
    end
    local rows = {}
    local pending = #limited
    if pending == 0 then cb({}, truncated, nil) return end
    for i, item in ipairs(limited) do
      local idx = item.name:match("^%[(%d+)%]$") or tostring(i - 1)
      fetch_children(session, item.variablesReference, function(props)
        local fields = {}
        if props then
          for _, p in ipairs(props) do
            if not is_noisy_prop(p.name) then
              table.insert(fields, { name = p.name, value = p.value })
            end
          end
        end
        table.insert(rows, { index = idx, type = item.value, fields = fields })
        pending = pending - 1
        if pending == 0 then cb(rows, truncated, nil) end
      end)
    end
  end)
end

local function truncate(s, n)
  s = tostring(s or "")
  if #s <= n then return s end
  return s:sub(1, n - 1) .. "…"
end

---Debug renderer: dump the raw children of the materialized list so we can see
---how netcoredbg names collection elements (e.g. `[0]`, `0`, `[0] :`, etc.).
local function render_debug(expr, sql, dump)
  local lines = {}
  table.insert(lines, "# Explore LINQ (debug): " .. expr)
  table.insert(lines, "")
  table.insert(lines, "No indexed children (`[0]`, `[1]`, ...) were found in the")
  table.insert(lines, "materialized list's variables. Raw children reported by netcoredbg:")
  table.insert(lines, "")
  for _, d in ipairs(dump) do table.insert(lines, d) end
  table.insert(lines, "")
  table.insert(lines, "Paste this output so the filter can be adjusted.")
  table.insert(lines, "# :bd to close")
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].filetype = "markdown"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.cmd("sbuffer " .. buf)
  vim.api.nvim_set_current_buf(buf)
end

---Render the result in a scratch buffer as markdown.
---Layout: SQL block (if any), then one section per item with fields listed as `name = value`.
local function render(expr, sql, rows, truncated)
  local lines = {}
  table.insert(lines, "# Explore LINQ: " .. expr)
  table.insert(lines, "")
  if sql and sql ~= "" then
    table.insert(lines, "## SQL (EF Core ToQueryString)")
    for _, line in ipairs(vim.split(sql, "\n")) do
      table.insert(lines, "  " .. line)
    end
    table.insert(lines, "")
  end
  if #rows == 0 then
    table.insert(lines, "(no items / unable to enumerate)")
  else
    table.insert(lines, string.format("%d item(s):", #rows))
    table.insert(lines, "")
    -- field-name column width for alignment within each item
    local maxname = 0
    for _, r in ipairs(rows) do
      for _, f in ipairs(r.fields) do
        if #f.name > maxname then maxname = #f.name end
      end
    end
    maxname = math.min(maxname, 30)
    for _, r in ipairs(rows) do
      table.insert(lines, string.format("## [%s]  %s", r.index, truncate(r.type, 80)))
      if #r.fields == 0 then
        table.insert(lines, "  (no public fields/properties, or a scalar)")
      else
        for _, f in ipairs(r.fields) do
          local pad = string.rep(" ", maxname - #f.name)
          table.insert(lines, string.format("  %s%s = %s", f.name, pad, truncate(f.value, MAX_VALUE_LEN)))
        end
      end
      table.insert(lines, "")
    end
    if truncated and truncated > 0 then
      table.insert(lines, string.format("... (%d more item(s) truncated; raise MAX_ITEMS to see more)", truncated))
      table.insert(lines, "")
    end
  end
  table.insert(lines, "# :bd to close")

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].filetype = "markdown"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.cmd("sbuffer " .. buf)
  vim.api.nvim_set_current_buf(buf)
end

---Public entry point. `expr` is the LINQ expression/variable to explore.
function M.explore(expr)
  expr = expr or get_expression()
  if not expr or expr == "" then
    vim.notify("explore_linq: nothing to explore (no selection/word under cursor)", vim.log.levels.WARN)
    return
  end
  local normalized, was_statement = normalize_expression(expr)
  if not normalized or normalized == "" then
    vim.notify("explore_linq: could not parse expression: " .. expr, vim.log.levels.WARN)
    return
  end
  -- C# 12 collection expressions (`[]`) are not supported by netcoredbg's
  -- Roslyn evaluator (it pins an older C# language version) — error CS1525.
  -- Also flag block-lambda statements that are awkward to evaluate as an expression.
  if normalized:find("%[%]") or normalized:find("[]", 1, true) then
    vim.notify(
      "explore_linq: selection contains a C# 12 `[]` collection expression, which netcoredbg's evaluator can't compile (CS1525). "
      .. "Set a breakpoint AFTER the statement, put the cursor on the result variable (e.g. `exercisesLinq`) and press <leader>dL to explore it instead.",
      vim.log.levels.ERROR)
    return
  end
  expr = normalized
  local dap = require("dap")
  local session = dap.session()
  if not session then
    vim.notify("explore_linq: no active debug session", vim.log.levels.WARN)
    return
  end
  if not session.current_frame then
    vim.notify("explore_linq: not paused at a breakpoint (no current frame to evaluate against)", vim.log.levels.WARN)
    return
  end
  vim.notify("explore_linq: evaluating " .. expr .. (was_statement and " (stripped statement prefix)" or "") .. " ...", vim.log.levels.INFO)

  -- 1. Evaluate the expression to get its value/type (for display + fallback).
  evaluate(session, expr, function(val, err)
    if err or not val then
      vim.notify("explore_linq: evaluate failed: " .. tostring(err), vim.log.levels.ERROR)
      return
    end
    -- Best-effort SQL (EF Core 5+ ToQueryString). Fails silently for non-IQueryable;
    -- we don't sniff the type name because lazy iterators report concrete types like
    -- IteratorSelectIterator, not the IEnumerable/IQueryable interface.
    local function fetch_sql(cb)
      evaluate(session, "(" .. expr .. ").ToQueryString()", function(sql_val, sql_err)
        if sql_err or not sql_val or not sql_val.result then cb(nil) return end
        cb(sql_val.result)
      end)
    end

    -- 2. Materialize via .ToArray(). Arrays are exposed by netcoredbg as indexed
    -- children [0]..[N-1] directly; a List<T> is instead exposed as its internal
    -- fields (_items, _size, ...), which would force us to drill into _items.
    -- .ToArray() works on any IEnumerable<T> (lazy iterators, lists, arrays).
    -- If it errors, the expression isn't enumerable -> show the raw value.
    evaluate(session, "(" .. expr .. ").ToArray()", function(list_val, list_err)
      if list_err or not list_val then
        -- Not enumerable (compile/runtime error): show the raw value, best-effort SQL.
        fetch_sql(function(sql)
          render(expr, sql, { { index = "0", type = val.result or "", fields = {} } }, 0)
        end)
        return
      end
      local ref = list_val.variablesReference or 0
      if ref == 0 then
        -- Materialized but no children (e.g. empty list, or a scalar that happened
        -- to have a .ToList()). Render as empty items.
        fetch_sql(function(sql) render(expr, sql, {}, 0) end)
        return
      end
      build_item_table(session, ref, function(rows, truncated, debug_dump)
        fetch_sql(function(sql)
          if debug_dump and #debug_dump > 0 then
            render_debug(expr, sql, debug_dump)
          else
            render(expr, sql, rows, truncated)
          end
        end)
      end)
    end)
  end)
end

return M
