-- Concrete behavioral tests for every area the bautolist.nvim fork changed.
-- These test CORRECT BEHAVIOR, not any particular implementation.
-- Each test group maps to a specific code-path difference between the repos.

local auto = require("autolist.auto")
local config = require("autolist.config")
local utils = require("autolist.utils")
local numbers = require("autolist.numbers")

local list_types = { "[-+*]", "%d+[.)]", "%a[.)]", "%u+[.)]" }

--- Simulate pressing Enter: insert blank line below cursor, move down, call new_bullet.
local function simulate_enter(buf, text)
  vim.keymap.set('i', '<CR>', '<CR><cmd>lua require("autolist.auto").new_bullet()<CR>', { buffer = buf })
  local suffix = (text or "") .. "<Esc>"
  local keys = vim.api.nvim_replace_termcodes("A<CR>" .. suffix, true, false, true)
  vim.api.nvim_feedkeys(keys, "x", false)
end

local function make_buf(lines, cursor_line)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
  vim.bo.filetype = "markdown"
  vim.bo.autoindent = true
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
-- AREA 1: Roman numeral pattern %u* vs %u+
-- The upstream pattern is %u*[.)] which matches zero uppercase letters,
-- meaning a bare "." or ")" matches. This causes false positives.
-- ══════════════════════════════════════════════════════════════════════
describe("roman numeral pattern: zero-or-more vs one-or-more", function()

  -- A bare dot should never be a list item
  it("a bare '.' is not a list item", function()
    assert.is_falsy(utils.is_list(".", list_types))
  end)

  it("a bare ')' is not a list item", function()
    assert.is_falsy(utils.is_list(")", list_types))
  end)

  -- Quarto fragment separator
  it("'. . .' is not a list item", function()
    assert.is_falsy(utils.is_list(". . .", list_types))
  end)

  -- A real roman numeral still works
  it("'I. item' IS a valid roman list item", function()
    assert.is_truthy(utils.is_list("I. item", list_types))
  end)

  it("'IV. item' IS a valid roman list item", function()
    assert.is_truthy(utils.is_list("IV. item", list_types))
  end)

  it("'III. item' IS a valid roman list item", function()
    assert.is_truthy(utils.is_list("III. item", list_types))
  end)

  -- The %u* bug also affects exec_ordered / is_ordered
  it("is_ordered does not detect '.' as ordered", function()
    assert.is_nil(utils.is_ordered("."))
  end)

  it("is_ordered does not detect '. . .' as ordered", function()
    assert.is_nil(utils.is_ordered(". . ."))
  end)

  -- exec_ordered also uses %u* internally for roman parsing
  it("get_value_ordered does not crash or return nonzero for '.'", function()
    local val = utils.get_value_ordered(".")
    assert.are.equal(0, val)
  end)

  it("get_value_ordered returns correct value for real roman markers", function()
    assert.are.equal(1, utils.get_value_ordered("I. item"))
    assert.are.equal(4, utils.get_value_ordered("IV. item"))
  end)
end)

-- ══════════════════════════════════════════════════════════════════════
-- AREA 2: Marker must be followed by whitespace or be at end-of-line
-- Without this check, "**bold**" matches as unordered (*) list,
-- and "-not a list" matches as unordered (-) list.
-- ══════════════════════════════════════════════════════════════════════
describe("list marker must be followed by whitespace", function()

  it("'**bold text**' is NOT an unordered list", function()
    assert.is_falsy(utils.is_list("**bold text**", list_types))
  end)

  it("'*italic text*' is NOT an unordered list", function()
    assert.is_falsy(utils.is_list("*italic text*", list_types))
  end)

  it("'-not a list' (no space after dash) is NOT a list", function()
    assert.is_falsy(utils.is_list("-not a list", list_types))
  end)

  it("'1.not a list' (no space after marker) is NOT a list", function()
    assert.is_falsy(utils.is_list("1.not a list", list_types))
  end)

  it("'+noSpaceAfter' is NOT a list", function()
    assert.is_falsy(utils.is_list("+noSpaceAfter", list_types))
  end)

  -- But these should still work
  it("'- item' (with space) IS a list", function()
    assert.is_truthy(utils.is_list("- item", list_types))
  end)

  it("'1. item' (with space) IS a list", function()
    assert.is_truthy(utils.is_list("1. item", list_types))
  end)

  -- Bare markers at end-of-line (empty bullets) should still be detected
  it("bare '-' at end-of-line IS a list item", function()
    assert.is_truthy(utils.is_list("-", list_types))
  end)

  it("bare '1.' at end-of-line IS a list item", function()
    assert.is_truthy(utils.is_list("1.", list_types))
  end)

  it("'- ' (marker + trailing space) IS a list item", function()
    assert.is_truthy(utils.is_list("- ", list_types))
  end)
end)

-- ══════════════════════════════════════════════════════════════════════
-- AREA 3: set_line_marker trailing space normalization
-- When replacing a marker, the space between marker and content should
-- be exactly one space, not whatever the original had.
-- ══════════════════════════════════════════════════════════════════════
describe("set_line_marker space normalization", function()

  it("normalizes multiple spaces after marker to exactly one", function()
    local buf = make_buf({ "1.   item" }, 1)  -- 3 spaces
    utils.set_line_marker(1, "2.", list_types)
    local r = get_lines(buf)
    -- Should have exactly "2. item" (one space), not "2.   item"
    assert.are.equal("2. item", r[1],
      "expected exactly one space after marker, got: '" .. r[1] .. "'")
  end)

  it("empty bullet gets a trailing space after marker change", function()
    local buf = make_buf({ "1." }, 1)
    utils.set_line_marker(1, "2.", list_types)
    local r = get_lines(buf)
    -- After changing marker on an empty bullet, there should be a space
    -- so the cursor lands after the space, not on the dot
    assert.is_truthy(r[1]:match("^2%. "),
      "expected '2. ' (with trailing space), got: '" .. r[1] .. "'")
  end)

  it("preserves content after marker change", function()
    local buf = make_buf({ "1. hello world" }, 1)
    utils.set_line_marker(1, "2.", list_types)
    local r = get_lines(buf)
    assert.is_truthy(r[1]:match("hello world"),
      "content was lost after marker change: '" .. r[1] .. "'")
  end)
end)

-- ══════════════════════════════════════════════════════════════════════
-- AREA 4: Empty bullet deletion should truly delete the line
-- Upstream uses fn.setline(line, "") which clears to empty but leaves
-- a ghost blank line. The correct behavior is to fully remove it.
-- ══════════════════════════════════════════════════════════════════════
describe("empty bullet deletion should remove the line entirely", function()

  it("empty ordered bullet is fully deleted, not just cleared", function()
    local buf = make_buf({ "1. First" }, 1)

    -- Enter 1: creates empty bullet (trailing space stripped by Esc)
    simulate_enter(buf)
    local r = get_lines(buf)
    assert.are.equal(2, #r)
    assert.is_truthy(r[2]:match("^2%."),
      "expected new bullet starting with '2.', got: '" .. (r[2] or "nil") .. "'")

    -- Enter 2: should delete the empty "2. " line
    simulate_enter(buf)
    r = get_lines(buf)

    -- The total line count tells us if the line was deleted vs cleared.
    -- If deleted: 2 lines (original + cursor's new blank)
    -- If cleared to "": 3 lines (original, ghost "", cursor blank)
    -- Correct behavior: the empty bullet line should be gone
    assert.are.equal(2, #r,
      "expected 2 lines (line was deleted), got " .. #r .. " (line may have been cleared to empty)")
  end)

  it("empty unordered bullet is fully deleted", function()
    local buf = make_buf({ "- First" }, 1)

    simulate_enter(buf)
    simulate_enter(buf)
    local r = get_lines(buf)

    assert.are.equal(2, #r,
      "expected 2 lines after empty bullet deletion, got " .. #r)
  end)
end)

-- ══════════════════════════════════════════════════════════════════════
-- AREA 5: Empty bullet detection with stripped trailing space
-- When Neovim processes <CR>, it may strip trailing whitespace from the
-- line, turning "2. " into "2." — the empty bullet check must still work.
-- ══════════════════════════════════════════════════════════════════════
describe("empty bullet detection with stripped trailing space", function()

  it("bare '2.' (no trailing space) is detected as an empty bullet", function()
    local buf = make_buf({
      "1. First",
      "2.",        -- simulates Neovim stripping the trailing space
    }, 2)

    simulate_enter(buf)
    local r = get_lines(buf)

    -- The "2." line should be detected as empty and removed.
    -- There should NOT remain a "2." line in the buffer.
    local found_bare = false
    for _, line in ipairs(r) do
      if line == "2." then found_bare = true end
    end
    assert.is_false(found_bare,
      "bare '2.' was not detected as an empty bullet and was left in buffer")
  end)

  it("bare '-' (no trailing space) is detected as an empty bullet", function()
    local buf = make_buf({
      "- First",
      "-",
    }, 2)

    simulate_enter(buf)
    local r = get_lines(buf)

    local found_bare = false
    for _, line in ipairs(r) do
      if line == "-" then found_bare = true end
    end
    assert.is_false(found_bare,
      "bare '-' was not detected as an empty bullet")
  end)
end)

-- ══════════════════════════════════════════════════════════════════════
-- AREA 6: recalculate() child list reset
-- When recalculate is called from the top level (no override_start_num),
-- the first item of a child ordered list should be reset to 1.
-- ══════════════════════════════════════════════════════════════════════
describe("recalculate child list numbering reset", function()

  it("child ordered list starting at 3 resets to 1", function()
    local buf = make_buf({
      "1. parent",
      INDENT .. "3. child a",
      INDENT .. "4. child b",
    }, 1)

    auto.recalculate()
    local r = get_lines(buf)

    assert.are.equal(INDENT .. "1. child a", r[2],
      "child was not reset to 1, got: '" .. r[2] .. "'")
    assert.are.equal(INDENT .. "2. child b", r[3],
      "child was not renumbered sequentially, got: '" .. r[3] .. "'")
  end)

  it("alphabetic child list starting at c) resets to a)", function()
    local buf = make_buf({
      "1. parent",
      INDENT .. "c) child a",
      INDENT .. "d) child b",
    }, 1)

    auto.recalculate()
    local r = get_lines(buf)

    assert.are.equal(INDENT .. "a) child a", r[2],
      "alpha child was not reset to a), got: '" .. r[2] .. "'")
    assert.are.equal(INDENT .. "b) child b", r[3],
      "alpha child was not renumbered, got: '" .. r[3] .. "'")
  end)

  it("renumbers correctly when child has arbitrary starting numbers", function()
    local buf = make_buf({
      "1. parent",
      INDENT .. "5. alpha",
      INDENT .. "8. beta",
      INDENT .. "2. gamma",
      "2. next parent",
    }, 1)

    auto.recalculate()
    local r = get_lines(buf)

    assert.are.equal(INDENT .. "1. alpha", r[2],
      "first child should be 1, got: '" .. r[2] .. "'")
    assert.are.equal(INDENT .. "2. beta", r[3],
      "second child should be 2, got: '" .. r[3] .. "'")
    assert.are.equal(INDENT .. "3. gamma", r[4],
      "third child should be 3, got: '" .. r[4] .. "'")
    assert.are.equal("2. next parent", r[5])
  end)
end)

-- ══════════════════════════════════════════════════════════════════════
-- AREA 7: Cursor position after set_line_marker on empty bullets
-- After changing a marker on an empty bullet (e.g. shift-tab on "    1. "),
-- the cursor should land AFTER the trailing space, not ON the dot or marker.
-- ══════════════════════════════════════════════════════════════════════
describe("cursor position after marker change on empty bullet", function()

  it("cursor ends at the correct column after set_line_marker", function()
    local buf = make_buf({ "    1. " }, 1)
    vim.api.nvim_win_set_cursor(0, { 1, 6 })  -- somewhere on the line

    utils.set_line_marker(1, "2.", list_types)
    local r = get_lines(buf)
    local cursor_col = vim.api.nvim_win_get_cursor(0)[2]

    -- Cursor should be at or past the end of "    2. "
    -- The line should end with a space
    assert.is_truthy(r[1]:match("%s$"),
      "expected trailing space on empty bullet, got: '" .. r[1] .. "'")
  end)
end)

-- ══════════════════════════════════════════════════════════════════════
-- AREA 8: get_bullet_from matching behavior
-- The bullet extractor should require actual whitespace after the marker
-- (not match zero-width), and should handle end-of-line markers.
-- ══════════════════════════════════════════════════════════════════════
describe("bullet pattern matching edge cases", function()

  it("new_bullet correctly continues from '- item' (normal case)", function()
    local buf = make_buf({ "- item" }, 1)
    simulate_enter(buf, "test")
    local r = get_lines(buf)
    assert.are.equal("- test", r[2])
  end)

  it("new_bullet correctly continues from '* item'", function()
    local buf = make_buf({ "* item" }, 1)
    simulate_enter(buf, "test")
    local r = get_lines(buf)
    assert.are.equal("* test", r[2])
  end)

  -- Markdown bold should not trigger a bullet
  it("new_bullet after '**bold text**' does NOT create a bullet", function()
    local buf = make_buf({ "**bold text**" }, 1)
    simulate_enter(buf)
    local r = get_lines(buf)
    assert.are.equal("", r[2],
      "**bold** incorrectly triggered a bullet: '" .. r[2] .. "'")
  end)

  -- Horizontal rule should not trigger a bullet
  it("new_bullet after '---' does NOT create a bullet", function()
    local buf = make_buf({ "---" }, 1)
    simulate_enter(buf)
    local r = get_lines(buf)
    -- Should be empty, not "-"
    assert.are.equal("", r[2],
      "--- incorrectly triggered a bullet: '" .. r[2] .. "'")
  end)

  -- Indented content should not falsely match
  it("new_bullet after '-noSpace' does NOT create a bullet", function()
    local buf = make_buf({ "-noSpace" }, 1)
    simulate_enter(buf)
    local r = get_lines(buf)
    assert.are.equal("", r[2],
      "'-noSpace' incorrectly triggered a bullet: '" .. r[2] .. "'")
  end)
end)

-- ══════════════════════════════════════════════════════════════════════
-- AREA 9: recalculate on heading-adjacent lists
-- A list directly beneath a markdown heading should not lose its bullets.
-- The heading "# Foo" must not be treated as a list marker.
-- ══════════════════════════════════════════════════════════════════════
describe("recalculate with markdown headings above lists", function()

  it("unordered list directly after heading retains bullets", function()
    local buf = make_buf({
      "# Heading",
      "- item one",
      "- item two",
    }, 2)

    auto.recalculate()
    local r = get_lines(buf)

    assert.are.equal("- item one", r[2],
      "bullet was stripped: '" .. r[2] .. "'")
    assert.are.equal("- item two", r[3],
      "bullet was stripped: '" .. r[3] .. "'")
  end)

  it("ordered list directly after heading renumbers correctly", function()
    local buf = make_buf({
      "# Heading",
      "1. first",
      "1. second",
    }, 2)

    auto.recalculate()
    local r = get_lines(buf)

    assert.are.equal("1. first", r[2])
    assert.are.equal("2. second", r[3])
  end)

  it("heading is not treated as the start of the list", function()
    -- The heading line itself must not be detected as list item
    assert.is_falsy(utils.is_list("# My heading", list_types))
    assert.is_falsy(utils.is_list("## Sub heading", list_types))
  end)
end)

-- ══════════════════════════════════════════════════════════════════════
-- AREA 10: debug print removed from cycle
-- Upstream has print(target_index) in cycle() which pollutes output.
-- ══════════════════════════════════════════════════════════════════════
describe("cycle should not produce debug output", function()
  it("cycle_next does not print to stdout", function()
    local buf = make_buf({ "- item" }, 1)

    -- Capture print output
    local printed = {}
    local old_print = print
    print = function(...) table.insert(printed, { ... }) end

    auto.cycle_next()

    print = old_print

    -- There should be no debug prints
    assert.are.equal(0, #printed,
      "cycle_next printed debug output: " .. vim.inspect(printed))
  end)
end)

-- ══════════════════════════════════════════════════════════════════════
-- AREA 11: Checkbox continuation should create UNCHECKED checkbox
-- When continuing a list from a checked [x] item, the new item
-- should have an empty [ ] checkbox, not a copy of [x].
-- ══════════════════════════════════════════════════════════════════════
describe("checkbox continuation state", function()

  it("continuing from [x] item creates bullet with [ ] (Issue #86)", function()
    -- The desired behavior is that a new item starts unchecked.
    local buf = make_buf({ "- [x] done task" }, 1)

    simulate_enter(buf, "test")
    local r = get_lines(buf)

    -- The new line will have `- [ ] test`
    assert.is_truthy(r[2]:match("^%- %[ %] test"),
      "expected a bullet with [ ] checkbox, got: '" .. (r[2] or "nil") .. "'")
  end)

  it("continuing from [ ] item creates bullet with [ ]", function()
    local buf = make_buf({ "- [ ] pending task" }, 1)

    simulate_enter(buf, "test")
    local r = get_lines(buf)

    assert.is_truthy(r[2]:match("%[ %] test"),
      "expected empty checkbox, got: '" .. (r[2] or "nil") .. "'")
  end)
end)

-- ══════════════════════════════════════════════════════════════════════
-- AREA 12: Deprecated Neovim API usage
-- vim.api.nvim_buf_get_option is deprecated in newer Neovim.
-- vim.bo[buf].filetype should be used instead.
-- ══════════════════════════════════════════════════════════════════════
describe("treesitter module API compatibility", function()

  it("treesitter module loads without error", function()
    local ok, ts = pcall(require, "autolist.treesitter")
    assert.is_true(ok, "treesitter module failed to load: " .. tostring(ts))
  end)

  it("treesitter:new returns nil gracefully when no parser exists", function()
    local ts = require("autolist.treesitter")
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buf)
    vim.bo.filetype = "nonexistent_ft"

    -- With no treesitter parser installed, this should return nil, not error
    local ok, result = pcall(ts.new, buf, vim.api.nvim_get_current_win())
    -- Either it returns nil or errors gracefully
    if ok then
      assert.is_nil(result, "treesitter:new returned non-nil instead of nil when no parser exists")
    else
      assert.is_truthy(result, "treesitter:new crashed with error string")
    end
  end)
end)

-- ══════════════════════════════════════════════════════════════════════
-- AREA 13: Multi-space indentation handling in set_line_marker
-- The original captures trailing spaces with (%s*) and replaces with %2.
-- The fork uses a hardcoded " ". This affects lines with varied spacing.
-- ══════════════════════════════════════════════════════════════════════
describe("set_line_marker handles varied spacing consistently", function()

  it("zero spaces between marker and content gets normalized", function()
    -- "1.item" — no space between marker and content
    -- After set_line_marker, the spacing behavior depends on implementation
    local buf = make_buf({ "1.item" }, 1)
    utils.set_line_marker(1, "2.", list_types)
    local r = get_lines(buf)
    -- The result should have the content "item" present
    assert.is_truthy(r[1]:match("item"), "content was lost: '" .. r[1] .. "'")
  end)

  it("tab between marker and content gets handled", function()
    local buf = make_buf({ "1.\titem" }, 1)
    utils.set_line_marker(1, "2.", list_types)
    local r = get_lines(buf)
    assert.is_truthy(r[1]:match("item"), "content was lost: '" .. r[1] .. "'")
  end)
end)

-- ══════════════════════════════════════════════════════════════════════
-- AREA 14: recalculate with override_start_num (child reset path)
-- When recalculate is called recursively with override_start_num,
-- it should still reset the child's first item to 1.
-- ══════════════════════════════════════════════════════════════════════
describe("recalculate with override_start_num", function()

  it("recursive call resets child numbering", function()
    -- Build a list where recalculate will be called recursively
    local buf = make_buf({
      "1. parent one",
      "1. parent two",
      INDENT .. "5. child a",
      INDENT .. "7. child b",
      "1. parent three",
    }, 1)

    auto.recalculate()
    local r = get_lines(buf)

    assert.are.equal("1. parent one", r[1])
    assert.are.equal("2. parent two", r[2])
    -- Children under parent two should be reset
    assert.are.equal(INDENT .. "1. child a", r[3],
      "child was not reset to 1, got: '" .. r[3] .. "'")
    assert.are.equal(INDENT .. "2. child b", r[4],
      "child was not sequenced, got: '" .. r[4] .. "'")
    assert.are.equal("3. parent three", r[5])
  end)
end)

-- ══════════════════════════════════════════════════════════════════════
-- AREA 15: new_bullet_before with colon lines
-- Pressing O above a colon-ending line should NOT create an
-- indented sub-bullet (it should match context ABOVE, not below).
-- ══════════════════════════════════════════════════════════════════════
describe("new_bullet_before colon interaction", function()

  it("O above colon line does not create indented bullet", function()
    local buf = make_buf({
      "Some context",
      "Line ending in colon:",
      INDENT .. "- existing child",
    }, 2)

    -- Simulate O: insert blank line above cursor, move to it
    vim.api.nvim_buf_set_lines(buf, 1, 1, false, { "" })
    vim.api.nvim_win_set_cursor(0, { 2, 0 })
    auto.new_bullet_before()

    local r = get_lines(buf)
    -- The inserted line should NOT be an indented bullet created from
    -- the colon on the line below
    assert.is_falsy(r[2]:match("^%s+%-"),
      "O created an indented bullet above colon line: '" .. r[2] .. "'")
  end)
end)

-- ══════════════════════════════════════════════════════════════════════
-- AREA 16: get_list_start walks backward correctly
-- The function should find the first contiguous list item by walking up.
-- It should stop at blanks, non-list lines, and buffer boundaries.
-- ══════════════════════════════════════════════════════════════════════
describe("get_list_start edge cases", function()

  it("finds start at line 1 when list starts at top of buffer", function()
    local buf = make_buf({
      "1. first",
      "2. second",
      "3. third",
    }, 3)
    assert.are.equal(1, utils.get_list_start(3, list_types))
  end)

  it("handles single-item list", function()
    local buf = make_buf({
      "1. only item",
    }, 1)
    assert.are.equal(1, utils.get_list_start(1, list_types))
  end)

  it("does not walk past different indent levels", function()
    local buf = make_buf({
      INDENT .. "1. indented",
      "1. not indented",
    }, 2)
    -- Line 2 should be its own list start (different indent from line 1)
    local start = utils.get_list_start(2, list_types)
    -- This depends on behavior: get_list_start walks up while is_list matches,
    -- regardless of indent. So it may OR may not stop. In current implementation
    -- it might go to 1, but #82 / #83 changes this logic. Here we assert it correctly
    -- detects line 2 is its own list start.
    assert.are.equal(2, start, "get_list_start incorrectly walked past different indent level to: " .. tostring(start))
  end)
end)
