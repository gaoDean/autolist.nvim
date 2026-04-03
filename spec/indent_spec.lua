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
end)
