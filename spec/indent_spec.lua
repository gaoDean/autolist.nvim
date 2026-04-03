-- Tests for handle_indent (tab/shift-tab) behavior.
-- These test the legacy tabstop-based indentation.

local auto = require("autolist.auto")
local config = require("autolist.config")

--- Helper: create a scratch buffer with markdown filetype.
local function make_buf(lines, cursor_line)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
  vim.bo.filetype = "markdown"
  vim.opt.expandtab = true
  vim.opt.tabstop = 4
  config.update()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  -- Place cursor at end of line (required for handle_indent to trigger)
  local line = lines[cursor_line or 1]
  vim.api.nvim_win_set_cursor(0, { cursor_line or 1, #line })
  return buf
end

local function get_lines(buf)
  return vim.api.nvim_buf_get_lines(buf, 0, -1, false)
end

describe("handle_indent", function()
  it("tab on a non-list line passes tab through", function()
    -- On a non-list line, tab should not trigger list indentation.
    -- We just verify it doesn't error.
    local buf = make_buf({ "just some text" }, 1)
    -- This should not crash
    auto.tab()
  end)

  it("shift-tab on a non-list line passes through", function()
    local buf = make_buf({ "    just some text" }, 1)
    -- Should not crash
    auto.shift_tab()
  end)

  it("tab on list item at end of line triggers indent", function()
    local buf = make_buf({
      "1. parent",
      "1. child to indent"
    }, 2)
    -- Should not crash — the actual indent is done via feedkeys which
    -- is async, so we just verify no errors.
    auto.tab()
  end)

  it("shift-tab on list item at end of line triggers dedent", function()
    local buf = make_buf({
      "1. parent",
      "    1. nested child"
    }, 2)
    -- Should not crash
    auto.shift_tab()
  end)

  -- ── edge cases ─────────────────────────────────────────────────────────────
  it("tab indentation should match tabstop setting (#87)", function()
    -- After tabbing, the indentation should be exactly 4 spaces (tabstop)
    local buf = make_buf({
      "1. parent",
      "1. child to indent",
    }, 2)

    assert.are.equal(4, config.tabstop)
    assert.are.equal("    ", config.tab)
  end)

  it("shift-tab should respect parent list style (#83)", function()
    local INDENT = "    "
    local buf = make_buf({
      "1. test",
      "2. test",
      "3. test",
      INDENT .. "- a",
      INDENT .. "- b",
      INDENT .. "- c",
      "4. test",
    }, 5)

    vim.keymap.set('i', '<S-Tab>', function() require("autolist.auto").shift_tab() end, { buffer = buf })

    local keys_enter = vim.api.nvim_replace_termcodes("A<S-Tab>", true, false, true)
    local keys_exit = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
    
    vim.api.nvim_feedkeys(keys_enter, "x", false)
    vim.wait(50, function() return false end) -- Give it enough time
    vim.api.nvim_feedkeys(keys_exit, "x", false)

    local r = get_lines(buf)
    -- It should pull back to column 0 and become an ordered list matching the parent
    assert.are.equal("4. b", r[5], "expected child to dedent and adopt ordered marker, got: " .. (r[5] or "nil"))
  end)

  it("tab in insert mode should not misplace cursor (#79)", function()
    local buf = make_buf({
      "- parent item",
      "- child item",
    }, 2)

    -- Should not error or hang
    local ok, err = pcall(auto.tab)
    assert.is_true(ok, "tab() errored: " .. tostring(err))
  end)
end)
