-- Integration tests for recalculate() using real Neovim buffers.
-- Tests cover flat renumbering, nested child lists, and edge cases.

local auto = require("autolist.auto")
local config = require("autolist.config")

-- Helper: create a scratch buffer, set filetype/options, populate lines,
-- position cursor, call recalculate(), and return the buffer contents.
local function recalc_buf(lines, cursor_line)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
  vim.bo.filetype = "markdown"
  vim.opt.expandtab = true
  vim.opt.tabstop = 4
  config.update()

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(0, { cursor_line or 1, 0 })

  auto.recalculate()

  return vim.api.nvim_buf_get_lines(buf, 0, -1, false)
end

-- Standard indentation at tabstop=4
local INDENT = "    "
local INDENT2 = "        "

describe("recalculate", function()

  -- ── flat list renumbering ──────────────────────────────────────────
  it("renumbers a flat ordered list sequentially", function()
    local result = recalc_buf({
      "1. first",
      "1. second",
      "1. third",
    }, 1)

    assert.are.equal("1. first",  result[1])
    assert.are.equal("2. second", result[2])
    assert.are.equal("3. third",  result[3])
  end)

  it("renumbers when starting from a middle item", function()
    local result = recalc_buf({
      "1. first",
      "1. second",
      "1. third",
    }, 2)

    -- recalculate finds list_start and renumbers from there
    assert.are.equal("1. first",  result[1])
    assert.are.equal("2. second", result[2])
    assert.are.equal("3. third",  result[3])
  end)

  it("preserves already-correct numbering", function()
    local result = recalc_buf({
      "1. first",
      "2. second",
      "3. third",
    }, 1)

    assert.are.equal("1. first",  result[1])
    assert.are.equal("2. second", result[2])
    assert.are.equal("3. third",  result[3])
  end)

  -- ── nested list handling ───────────────────────────────────────────
  it("recalculates child ordered list", function()
    local result = recalc_buf({
      "1. parent",
      INDENT .. "3. child",
      INDENT .. "4. child two",
    }, 1)

    assert.are.equal("1. parent", result[1])
    -- Child list should be recalculated
    assert.is_truthy(result[2]:match("child"))
    assert.is_truthy(result[3]:match("child two"))
  end)

  it("handles doubly-nested (3-level) lists", function()
    local result = recalc_buf({
      "1. top",
      INDENT .. "5. mid",
      INDENT2 .. "9. deep",
      INDENT2 .. "9. deep2",
    }, 1)

    assert.are.equal("1. top", result[1])
    assert.is_truthy(result[2]:match("mid"))
    assert.is_truthy(result[3]:match("deep"))
    assert.is_truthy(result[4]:match("deep2"))
  end)

  it("does not alter unordered child lists", function()
    local result = recalc_buf({
      "1. parent",
      INDENT .. "- child one",
      INDENT .. "- child two",
      "1. second parent",
    }, 1)

    assert.are.equal("1. parent",             result[1])
    assert.are.equal(INDENT .. "- child one", result[2])
    assert.are.equal(INDENT .. "- child two", result[3])
    assert.are.equal("2. second parent",      result[4])
  end)

  -- ── boundary conditions ────────────────────────────────────────────
  it("stops at a non-list line", function()
    local result = recalc_buf({
      "1. first",
      "1. second",
      "some text",
      "1. unrelated",
    }, 1)

    assert.are.equal("1. first",    result[1])
    assert.are.equal("2. second",   result[2])
    assert.are.equal("some text",   result[3])
    assert.are.equal("1. unrelated", result[4])  -- not touched
  end)

  it("stops at a blank line (tight list)", function()
    local result = recalc_buf({
      "1. first",
      "1. second",
      "",
      "1. separate",
    }, 1)

    assert.are.equal("1. first",    result[1])
    assert.are.equal("2. second",   result[2])
    assert.are.equal("",            result[3])
    assert.are.equal("1. separate", result[4])  -- not touched
  end)

  -- ── multi-digit and special markers ────────────────────────────────
  it("handles multi-digit ordered lists", function()
    local result = recalc_buf({
      "1. first",
      "1. second",
      "1. third",
      "1. fourth",
      "1. fifth",
      "1. sixth",
      "1. seventh",
      "1. eighth",
      "1. ninth",
      "1. tenth",
    }, 1)

    assert.are.equal("10. tenth", result[10])
  end)

  it("renumbers alphabetic ordered lists", function()
    local result = recalc_buf({
      "a) first",
      "a) second",
      "a) third",
    }, 1)

    assert.are.equal("a) first",  result[1])
    assert.are.equal("b) second", result[2])
    assert.are.equal("c) third",  result[3])
  end)

  it("renumbers roman numeral ordered lists", function()
    local result = recalc_buf({
      "I. first",
      "I. second",
      "I. third",
    }, 1)

    assert.are.equal("I. first",   result[1])
    assert.are.equal("II. second", result[2])
    assert.are.equal("III. third", result[3])
  end)

  -- ── empty bullet spacing ───────────────────────────────────────────
  it("handles empty bullet (marker-only line)", function()
    local result = recalc_buf({
      "1. first",
      "1. ",
    }, 1)

    assert.are.equal("1. first", result[1])
    -- The empty bullet should get renumbered
    assert.is_truthy(result[2]:match("^2"))
  end)

  -- ── infinite loop guard (issue #76) ────────────────────────────────
  it("recalculate with list_cap items stops without hanging (#76)", function()
    -- Build a list that is exactly at the list_cap boundary
    local lines = {}
    for i = 1, config.list_cap + 5 do
      table.insert(lines, "1. item " .. i)
    end

    local result = recalc_buf(lines, 1)

    -- Items past list_cap should not be renumbered
    assert.are.equal("1. item " .. (config.list_cap + 5), result[config.list_cap + 5],
      "item past list_cap was incorrectly renumbered")
  end)
end)
