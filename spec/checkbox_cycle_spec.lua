-- Tests for toggle_checkbox() and cycle_next()/cycle_prev().

local auto = require("autolist.auto")
local config = require("autolist.config")
local utils = require("autolist.utils")

--- Helper: create a scratch buffer with markdown filetype and given lines.
local function make_buf(lines, cursor_line)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
  vim.bo.filetype = "markdown"
  vim.opt.expandtab = true
  vim.opt.tabstop = 4
  config.update()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(0, { cursor_line or 1, 0 })
  return buf
end

local function get_lines(buf)
  return vim.api.nvim_buf_get_lines(buf, 0, -1, false)
end

-- ══════════════════════════════════════════════════════════════════════════
describe("toggle_checkbox", function()
  it("toggles filled [x] to empty [ ]", function()
    local buf = make_buf({ "- [x] completed task" }, 1)

    auto.toggle_checkbox()
    local r = get_lines(buf)
    assert.are.equal("- [ ] completed task", r[1])
  end)

  it("toggles empty [ ] to filled [x]", function()
    local buf = make_buf({ "- [ ] pending task" }, 1)

    auto.toggle_checkbox()
    local r = get_lines(buf)
    assert.are.equal("- [x] pending task", r[1])
  end)

  pending("adds a checkbox to bare bullet (#67)", function()
    local buf = make_buf({ "- regular item" }, 1)

    auto.toggle_checkbox()
    local r = get_lines(buf)
    assert.is_truthy(r[1]:match("%[.%]"),
      "expected checkbox to be added, got: '" .. r[1] .. "'")
  end)

  it("is a no-op on non-list lines", function()
    local buf = make_buf({ "just some text" }, 1)

    auto.toggle_checkbox()
    local r = get_lines(buf)
    assert.are.equal("just some text", r[1])
  end)

  it("preserves bullet marker and content when toggling", function()
    local buf = make_buf({ "* [x] my task with content" }, 1)

    auto.toggle_checkbox()
    local r = get_lines(buf)
    assert.are.equal("* [ ] my task with content", r[1])

    -- toggle back
    auto.toggle_checkbox()
    r = get_lines(buf)
    assert.are.equal("* [x] my task with content", r[1])
  end)

  it("works with ordered list checkboxes", function()
    local buf = make_buf({ "1. [x] ordered task" }, 1)

    auto.toggle_checkbox()
    local r = get_lines(buf)
    assert.are.equal("1. [ ] ordered task", r[1])
  end)

  it("preserves indentation", function()
    local buf = make_buf({ "    - [x] indented task" }, 1)

    auto.toggle_checkbox()
    local r = get_lines(buf)
    assert.are.equal("    - [ ] indented task", r[1])
  end)
end)

-- ══════════════════════════════════════════════════════════════════════════
describe("cycle_next", function()
  it("cycles from - to *", function()
    local buf = make_buf({
      "- first",
      "- second",
    }, 1)

    auto.cycle_next()
    local r = get_lines(buf)
    -- After cycling, the first marker should change to *
    assert.is_truthy(r[1]:match("^%*"), "expected * marker, got: " .. r[1])
  end)

  it("cycles from * to 1.", function()
    local buf = make_buf({
      "* first",
      "* second",
    }, 1)

    auto.cycle_next()
    local r = get_lines(buf)
    assert.is_truthy(r[1]:match("^1%."), "expected 1. marker, got: " .. r[1])
  end)

  it("wraps around from I. back to -", function()
    local buf = make_buf({
      "I. first",
    }, 1)

    auto.cycle_next()
    local r = get_lines(buf)
    assert.is_truthy(r[1]:match("^%-"), "expected - marker, got: " .. r[1])
  end)

  it("returns nil when marker is not in cycle list", function()
    local buf = make_buf({
      "+ first",  -- + is not in the default cycle list
    }, 1)

    -- This should return nil / no-op
    auto.cycle_next()
    local r = get_lines(buf)
    assert.are.equal("+ first", r[1])
  end)
end)

-- ══════════════════════════════════════════════════════════════════════════
describe("cycle_prev", function()
  it("cycles backward from * to -", function()
    local buf = make_buf({
      "* first",
    }, 1)

    auto.cycle_prev()
    local r = get_lines(buf)
    assert.is_truthy(r[1]:match("^%-"), "expected - marker, got: " .. r[1])
  end)

  it("wraps backward from - to I.", function()
    local buf = make_buf({
      "- first",
    }, 1)

    auto.cycle_prev()
    local r = get_lines(buf)
    assert.is_truthy(r[1]:match("^I%."), "expected I. marker, got: " .. r[1])
  end)
end)
