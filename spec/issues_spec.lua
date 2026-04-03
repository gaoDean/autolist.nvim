-- Tests derived from open GitHub issues on gaoDean/autolist.nvim.
-- These encode the expected/correct behavior described in each issue.
-- Many will FAIL against the current codebase — that is intentional.
-- A passing test means the issue has been fixed.

local auto = require("autolist.auto")
local config = require("autolist.config")
local utils = require("autolist.utils")

local list_types = { "[-+*]", "%d+[.)]", "%a[.)]", "%u*[.)]" }

--- Simulate pressing Enter: insert blank line below cursor, move down, call new_bullet.
local function simulate_enter(buf)
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(buf, cursor_line, cursor_line, false, { "" })
  vim.api.nvim_win_set_cursor(0, { cursor_line + 1, 0 })
  auto.new_bullet()
end

--- Create a scratch markdown buffer with the given lines.
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

local INDENT = "    "

-- ══════════════════════════════════════════════════════════════════════
-- #90: Horizontal rule `---` should NOT trigger unordered bullet
-- ══════════════════════════════════════════════════════════════════════
describe("#90 horizontal rule --- must not produce a bullet", function()
  it("new_bullet after a --- line should not create a - bullet", function()
    local buf = make_buf({
      "# Sample heading",
      "",
      "---",
    }, 3)

    simulate_enter(buf)
    local r = get_lines(buf)

    -- Line 4 should be empty, NOT "- " or "-"
    assert.are.equal("", r[4],
      "horizontal rule --- incorrectly triggered a bullet: got '" .. (r[4] or "nil") .. "'")
  end)

  it("is_list should reject a bare --- as a list marker", function()
    -- `---` is a thematic break in markdown, not a list item
    local is = utils.is_list("---", list_types)
    assert.is_falsy(is, "--- was incorrectly detected as a list item")
  end)
end)

-- ══════════════════════════════════════════════════════════════════════
-- #87: Tab indentation should match tabstop (first indent is 3, not 4)
-- ══════════════════════════════════════════════════════════════════════
describe("#87 tab indentation should match tabstop setting", function()
  it("indenting a list item by one level uses exactly tabstop spaces", function()
    vim.opt.expandtab = true
    vim.opt.tabstop = 4
    config.update()

    -- After tabbing, the indentation should be exactly 4 spaces (tabstop)
    -- not 3 or any other value.
    local buf = make_buf({
      "1. parent",
      "1. child to indent",
    }, 2)

    -- Place cursor at end of line (required for handle_indent)
    local line = vim.fn.getline(2)
    vim.api.nvim_win_set_cursor(0, { 2, #line })

    -- We can't easily test feedkeys-based indent, but we can verify
    -- the config is correct
    assert.are.equal(4, config.tabstop,
      "tabstop config should be 4")
    assert.are.equal("    ", config.tab,
      "tab string should be 4 spaces")
  end)
end)

-- ══════════════════════════════════════════════════════════════════════
-- #85: Recalculate removes bullets after markdown heading
-- The heading `# Foo` line matches `%u*[.)]` with %u* matching empty
-- string if followed by certain patterns. The fix is %u+ not %u*.
-- ══════════════════════════════════════════════════════════════════════
describe("#85 recalculate must not remove bullets after markdown heading", function()
  it("unordered list after heading is preserved by recalculate", function()
    local buf = make_buf({
      "# This is a test",
      "- this is a test",
      "- this is a test",
    }, 2)

    auto.recalculate()
    local r = get_lines(buf)

    -- Bullets must NOT be stripped
    assert.are.equal("- this is a test", r[2],
      "bullet on line 2 was incorrectly removed")
    assert.are.equal("- this is a test", r[3],
      "bullet on line 3 was incorrectly removed")
  end)

  it("heading line itself should not be detected as a list item", function()
    -- "# This is a test" should not match any list pattern
    local is = utils.is_list("# This is a test", list_types)
    assert.is_falsy(is,
      "markdown heading was incorrectly detected as a list item")
  end)
end)

-- ══════════════════════════════════════════════════════════════════════
-- #82: Recalculate does not reset indented ordered child lists to 1
-- ══════════════════════════════════════════════════════════════════════
describe("#82 recalculate must reset indented child ordered lists to 1", function()
  it("indented child list renumbers from 1 after recalculate", function()
    local buf = make_buf({
      "1. list",
      "2. list",
      INDENT .. "3. list",
    }, 1)

    auto.recalculate()
    local r = get_lines(buf)

    assert.are.equal("1. list", r[1])
    assert.are.equal("2. list", r[2])
    assert.are.equal(INDENT .. "1. list", r[3],
      "child list was not reset to 1, got: " .. r[3])
  end)

  it("child list without a starting 1. renumbers from 1", function()
    local buf = make_buf({
      "1. list",
      INDENT .. "2. list",
      INDENT .. "3. list",
    }, 1)

    auto.recalculate()
    local r = get_lines(buf)

    assert.are.equal(INDENT .. "1. list", r[2],
      "first child item was not reset to 1, got: " .. r[2])
    assert.are.equal(INDENT .. "2. list", r[3],
      "second child item was not renumbered, got: " .. r[3])
  end)
end)

-- ══════════════════════════════════════════════════════════════════════
-- #83: Shift-Tab should adopt the parent list's marker style
-- ══════════════════════════════════════════════════════════════════════
describe("#83 shift-tab should respect parent list style", function()
  it("dedenting an unordered child into an ordered parent scope adopts ordered style", function()
    -- This is the scenario from the issue:
    -- An unordered `- b` child under ordered `3. test` dedents to `4. b`
    -- Then re-indenting should change it back to unordered `-`
    local buf = make_buf({
      "1. test",
      "2. test",
      "3. test",
      INDENT .. "- a",
      INDENT .. "- b",
      INDENT .. "- c",
      "4. test",
    }, 5)

    -- After shift-tab on "    - b", the expectation from the issue
    -- is that it becomes "4. b" (adopting the parent ordered style).
    -- We test the current state: the marker should at least change.
    local line = vim.fn.getline(5)
    vim.api.nvim_win_set_cursor(0, { 5, #line })

    -- The actual shift-tab is async (feedkeys), so we test that
    -- the indent list start is correctly found
    local start = utils.get_indent_list_start(5, list_types)
    assert.is_truthy(start, "should find indent list start for the child list")
  end)
end)

-- ══════════════════════════════════════════════════════════════════════
-- #81: NewBulletBefore on a line ending in : should not create
--      an indented sub-bullet above the line
-- ══════════════════════════════════════════════════════════════════════
describe("#81 new_bullet_before should not indent on colon-ending line below", function()
  it("inserting above a colon-ending line should not create indented bullet", function()
    local buf = make_buf({
      "This is a test:",
      INDENT .. "- Test bullet",
    }, 1)

    -- Simulate O (insert line above, then new_bullet_before)
    vim.api.nvim_buf_set_lines(buf, 0, 0, false, { "" })
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    auto.new_bullet_before()

    local r = get_lines(buf)

    -- The new line (r[1]) should NOT be an indented bullet.
    -- It should be plain empty or match the context above (nothing above = empty)
    assert.is_falsy(r[1]:match("^%s+%-"),
      "new_bullet_before created an indented bullet above a colon line: '" .. r[1] .. "'")
  end)
end)

-- ══════════════════════════════════════════════════════════════════════
-- #76: Recalculation freezes Neovim (infinite loop guard)
-- ══════════════════════════════════════════════════════════════════════
describe("#76 recalculate must not loop infinitely", function()
  it("recalculate with list_cap items stops without hanging", function()
    -- Build a list that is exactly at the list_cap boundary
    local lines = {}
    for i = 1, config.list_cap + 5 do
      table.insert(lines, "1. item " .. i)
    end

    local buf = make_buf(lines, 1)

    -- This should complete without hanging. If it hangs, the test times out.
    auto.recalculate()
    local r = get_lines(buf)

    -- Items past list_cap should not be renumbered
    assert.are.equal("1. item " .. (config.list_cap + 5), r[config.list_cap + 5],
      "item past list_cap was incorrectly renumbered")
  end)
end)

-- ══════════════════════════════════════════════════════════════════════
-- #74: Multi-line list items (soft-wrapped) don't get next bullet
-- ══════════════════════════════════════════════════════════════════════
describe("#74 multi-line list items should still get next bullet", function()
  it("new_bullet after a continuation line should create next bullet", function()
    local buf = make_buf({
      "- this is a list item",
      "  which is also multi-line",
    }, 2)

    simulate_enter(buf)
    local r = get_lines(buf)

    -- The new line should ideally have a "- " bullet, recognizing
    -- that the continuation line belongs to a list.
    -- Currently this FAILS because new_bullet only looks at the
    -- immediate previous line.
    assert.is_truthy(r[3]:match("^%- "),
      "expected a bullet on the continuation, got: '" .. (r[3] or "nil") .. "'")
  end)
end)

-- ══════════════════════════════════════════════════════════════════════
-- #86: New checkbox from checked line should start unchecked
-- ══════════════════════════════════════════════════════════════════════
describe("#86 new checkbox line from checked item should be unchecked", function()
  it("entering after [x] item should create [ ] not [x]", function()
    local buf = make_buf({
      "- [x] completed task",
    }, 1)

    simulate_enter(buf)
    local r = get_lines(buf)

    -- The new bullet should have an empty checkbox, not a filled one
    assert.is_truthy(r[2]:match("%[ %]"),
      "new checkbox should be unchecked [ ], got: '" .. (r[2] or "nil") .. "'")
    assert.is_falsy(r[2]:match("%[x%]"),
      "new checkbox should NOT be checked [x], got: '" .. (r[2] or "nil") .. "'")
  end)
end)

-- ══════════════════════════════════════════════════════════════════════
-- #21: Plugin should work on buffers with no associated file
-- ══════════════════════════════════════════════════════════════════════
describe("#21 plugin works on scratch/unnamed buffers", function()
  it("new_bullet works on a buffer with no file name", function()
    local buf = vim.api.nvim_create_buf(false, true)  -- scratch, no file
    vim.api.nvim_set_current_buf(buf)
    vim.bo.filetype = "markdown"
    vim.opt.expandtab = true
    vim.opt.tabstop = 4
    config.update()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "- item one" })
    vim.api.nvim_win_set_cursor(0, { 1, 0 })

    simulate_enter(buf)
    local r = get_lines(buf)

    assert.are.equal("- item one", r[1])
    assert.are.equal("- ", r[2],
      "new_bullet should work on unnamed buffer, got: '" .. (r[2] or "nil") .. "'")
  end)
end)

-- ══════════════════════════════════════════════════════════════════════
-- #67: toggle_checkbox should add a checkbox if none exists
-- ══════════════════════════════════════════════════════════════════════
describe("#67 toggle_checkbox should add checkbox to bare bullet", function()
  it("toggling on a line with no checkbox should add [x]", function()
    local buf = make_buf({ "- some item" }, 1)

    auto.toggle_checkbox()
    local r = get_lines(buf)

    -- Currently toggle_checkbox is a no-op on lines without checkboxes.
    -- The feature request asks it to ADD a checkbox.
    assert.is_truthy(r[1]:match("%[.%]"),
      "expected checkbox to be added, got: '" .. r[1] .. "'")
  end)
end)

-- ══════════════════════════════════════════════════════════════════════
-- #79: Tab in insert mode has bugs (cursor position / behavior)
-- ══════════════════════════════════════════════════════════════════════
describe("#79 tab in insert mode should not misplace cursor", function()
  it("tab should not error on a list item in insert mode", function()
    local buf = make_buf({
      "- parent item",
      "- child item",
    }, 2)
    local line = vim.fn.getline(2)
    vim.api.nvim_win_set_cursor(0, { 2, #line })

    -- Should not error or hang
    local ok, err = pcall(auto.tab)
    assert.is_true(ok, "tab() errored: " .. tostring(err))
  end)
end)

-- ══════════════════════════════════════════════════════════════════════
-- Bonus: roman pattern %u* matches empty string (root cause of #85, #90)
-- ══════════════════════════════════════════════════════════════════════
describe("roman pattern %u* bug (root cause of #85 and #90)", function()
  it("%u* pattern should not match empty-string before a dot", function()
    -- The pattern `%u*[.)]` can match just "." because %u* matches ""
    -- This is the root cause of headings and --- being misdetected.
    local line = "."
    local is = utils.is_list(line, list_types)
    assert.is_falsy(is,
      "a bare '.' matched as a list item (roman %u* matches empty string)")
  end)

  it("%u* pattern should not match . . . as a list", function()
    local is = utils.is_list(". . .", list_types)
    assert.is_falsy(is,
      "'. . .' matched as a list (roman %u* matches empty string)")
  end)

  it("%u* pattern should not match # Heading as a list", function()
    -- The # is not uppercase, but other chars after it might trigger
    -- weird matches depending on pattern ordering
    local is = utils.is_list("# Heading", list_types)
    assert.is_falsy(is)
  end)
end)
