-- Minimal test runner for Neovim headless mode.
-- Emulates busted's describe/it/assert API so the spec files can run
-- unchanged inside `nvim --headless`.
--
-- Usage:
--   nvim --headless -u NONE +"set rtp+=." +"luafile spec/run_tests.lua" +qa

local pass_count = 0
local fail_count = 0
local error_count = 0
local current_describe = {}
local before_each_fns = {}
local after_each_fns = {}

-- ── assert shim ──────────────────────────────────────────────────────

local _assert = {}

_assert.are = {}
_assert.are.equal = function(expected, actual, msg)
  if expected ~= actual then
    error(string.format(
      "%sexpected %s, got %s",
      msg and (msg .. ": ") or "",
      vim.inspect(expected),
      vim.inspect(actual)
    ), 2)
  end
end

_assert.is_true = function(val, msg)
  if val ~= true then
    error(string.format(
      "%sexpected true, got %s",
      msg and (msg .. ": ") or "",
      vim.inspect(val)
    ), 2)
  end
end

_assert.is_false = function(val, msg)
  if val ~= false then
    error(string.format(
      "%sexpected false, got %s",
      msg and (msg .. ": ") or "",
      vim.inspect(val)
    ), 2)
  end
end

_assert.is_truthy = function(val, msg)
  if not val then
    error(string.format(
      "%sexpected truthy, got %s",
      msg and (msg .. ": ") or "",
      vim.inspect(val)
    ), 2)
  end
end

_assert.is_falsy = function(val, msg)
  if val then
    error(string.format(
      "%sexpected falsy, got %s",
      msg and (msg .. ": ") or "",
      vim.inspect(val)
    ), 2)
  end
end

_assert.is_nil = function(val, msg)
  if val ~= nil then
    error(string.format(
      "%sexpected nil, got %s",
      msg and (msg .. ": ") or "",
      vim.inspect(val)
    ), 2)
  end
end

_assert.is_not_nil = function(val, msg)
  if val == nil then
    error(string.format(
      "%sexpected non-nil",
      msg and (msg .. ": ") or ""
    ), 2)
  end
end

_assert.is_table = function(val, msg)
  if type(val) ~= "table" then
    error(string.format(
      "%sexpected table, got %s",
      msg and (msg .. ": ") or "",
      type(val)
    ), 2)
  end
end

_assert.is_function = function(val, msg)
  if type(val) ~= "function" then
    error(string.format(
      "%sexpected function, got %s",
      msg and (msg .. ": ") or "",
      type(val)
    ), 2)
  end
end

_assert.fail = function(msg)
  error(msg or "assertion failed", 2)
end

-- allow assert.is_truthy(...) style calls
setmetatable(_assert, {
  __index = function(_, k)
    return rawget(_assert, k)
  end,
})

-- ── describe/it/before_each/after_each ───────────────────────────────

local function get_context_name()
  return table.concat(current_describe, " > ")
end

function describe(name, fn)
  table.insert(current_describe, name)
  local saved_before = vim.deepcopy(before_each_fns)
  local saved_after = vim.deepcopy(after_each_fns)
  fn()
  before_each_fns = saved_before
  after_each_fns = saved_after
  table.remove(current_describe)
end

function it(name, fn)
  local context = get_context_name()
  local full_name = context .. " > " .. name

  -- run before_each hooks
  for _, hook in ipairs(before_each_fns) do
    hook()
  end

  local ok, err = pcall(fn)
  if ok then
    pass_count = pass_count + 1
    io.write(string.format("  ✓ %s\n", full_name))
  else
    fail_count = fail_count + 1
    io.write(string.format("  ✗ %s\n    %s\n", full_name, err))
  end

  -- run after_each hooks
  for _, hook in ipairs(after_each_fns) do
    local hook_ok, hook_err = pcall(hook)
    if not hook_ok then
      io.write(string.format("    [after_each error] %s\n", hook_err))
    end
  end
end

function before_each(fn)
  table.insert(before_each_fns, fn)
end

function after_each(fn)
  table.insert(after_each_fns, fn)
end

-- pending/skip placeholders
function pending(name)
  io.write(string.format("  ○ PENDING: %s\n", name))
end

-- ── globals ──────────────────────────────────────────────────────────

-- Expose assert globally
assert = setmetatable(_assert, {
  __call = function(_, val, msg)
    if not val then
      error(msg or "assertion failed", 2)
    end
  end,
})

-- ── run spec files ───────────────────────────────────────────────────────

local spec_dir = "spec"
local spec_files = {
  "numbers_spec.lua",
  "config_spec.lua",
  "utils_spec.lua",
  "recalculate_spec.lua",
  "new_bullet_spec.lua",
  "checkbox_cycle_spec.lua",
  "init_spec.lua",
  "indent_spec.lua",
  "issues_spec.lua",
  "fork_behaviors_spec.lua",
}

io.write("\n══════════════════════════════════════════════════\n")
io.write("  autolist.nvim test suite\n")
io.write("══════════════════════════════════════════════════\n\n")

for _, file in ipairs(spec_files) do
  local path = spec_dir .. "/" .. file
  io.write(string.format("── %s ──\n", file))
  local chunk, load_err = loadfile(path)
  if chunk then
    local ok, run_err = pcall(chunk)
    if not ok then
      error_count = error_count + 1
      io.write(string.format("  ✗ ERROR loading %s: %s\n", file, run_err))
    end
  else
    error_count = error_count + 1
    io.write(string.format("  ✗ LOAD ERROR %s: %s\n", file, load_err))
  end
  io.write("\n")
end

-- ── summary ──────────────────────────────────────────────────────────

io.write("══════════════════════════════════════════════════\n")
io.write(string.format(
  "  Results: %d passed, %d failed, %d errors\n",
  pass_count, fail_count, error_count
))
io.write("══════════════════════════════════════════════════\n")

if fail_count > 0 or error_count > 0 then
  vim.cmd("cquit 1")
end
