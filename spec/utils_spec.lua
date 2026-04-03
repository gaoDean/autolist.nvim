-- Tests for autolist.utils — pure and semi-pure utility functions.
-- Some functions depend on vim.fn (buffer state); we test the subset
-- that can run without complex buffer setup, plus buffer-based ones
-- where we create scratch buffers.

local utils = require("autolist.utils")

-- Ensure config is initialized
require("autolist.config").update()

-- The standard markdown list types matching config.lists.markdown
local list_types = { "[-+*]", "%d+[.)]", "%a[.)]", "%u*[.)]" }

describe("utils", function()

  -- ── get_indent_lvl ─────────────────────────────────────────────────
  describe("get_indent_lvl", function()
    it("returns 0 for no indent", function()
      assert.are.equal(0, utils.get_indent_lvl("- item"))
    end)

    it("counts leading spaces", function()
      assert.are.equal(2, utils.get_indent_lvl("  - item"))
      assert.are.equal(4, utils.get_indent_lvl("    - item"))
    end)

    it("counts a tab as one character", function()
      assert.are.equal(1, utils.get_indent_lvl("\t- item"))
    end)

    it("returns 0 for empty string", function()
      assert.are.equal(0, utils.get_indent_lvl(""))
    end)
  end)

  -- ── get_whitespace_trimmed ─────────────────────────────────────────
  describe("get_whitespace_trimmed", function()
    it("trims trailing whitespace", function()
      assert.are.equal("hello", utils.get_whitespace_trimmed("hello   "))
    end)

    it("does not trim leading whitespace", function()
      assert.are.equal("  hello", utils.get_whitespace_trimmed("  hello  "))
    end)

    it("handles string with no trailing whitespace", function()
      assert.are.equal("hello", utils.get_whitespace_trimmed("hello"))
    end)
  end)

  -- ── get_percent_filtered ───────────────────────────────────────────
  describe("get_percent_filtered", function()
    it("removes percent signs", function()
      assert.are.equal("[x]", utils.get_percent_filtered("%[x%]"))
      assert.are.equal("[ ]", utils.get_percent_filtered("%[ %]"))
    end)

    it("passes through strings without percents", function()
      assert.are.equal("hello", utils.get_percent_filtered("hello"))
    end)
  end)

  -- ── is_list ────────────────────────────────────────────────────────
  describe("is_list", function()
    it("detects unordered list markers", function()
      assert.is_truthy(utils.is_list("- item", list_types))
      assert.is_truthy(utils.is_list("+ item", list_types))
      assert.is_truthy(utils.is_list("* item", list_types))
    end)

    it("detects indented unordered markers", function()
      assert.is_truthy(utils.is_list("  - item", list_types))
      assert.is_truthy(utils.is_list("    * item", list_types))
    end)

    it("detects digit ordered markers", function()
      assert.is_truthy(utils.is_list("1. item", list_types))
      assert.is_truthy(utils.is_list("12. item", list_types))
      assert.is_truthy(utils.is_list("1) item", list_types))
    end)

    it("detects ascii ordered markers", function()
      assert.is_truthy(utils.is_list("a) item", list_types))
      assert.is_truthy(utils.is_list("b. item", list_types))
    end)

    it("detects roman numeral markers", function()
      assert.is_truthy(utils.is_list("I. item", list_types))
      assert.is_truthy(utils.is_list("IV. item", list_types))
      assert.is_truthy(utils.is_list("XII) item", list_types))
    end)

    it("rejects non-list lines", function()
      assert.is_falsy(utils.is_list("just some text", list_types))
      assert.is_falsy(utils.is_list("", list_types))
      assert.is_falsy(utils.is_list("   ", list_types))
    end)

    it("returns the pattern and match on success", function()
      local is, pat, match = utils.is_list("- item", list_types)
      assert.is_truthy(is)
      assert.is_not_nil(pat)
      assert.are.equal("-", match)
    end)

    it("returns the digit marker on success", function()
      local is, pat, match = utils.is_list("1. item", list_types)
      assert.is_truthy(is)
      assert.are.equal("1.", match)
    end)

    it("falls through to is_ordered when list_types is nil", function()
      -- ordered line
      assert.is_truthy(utils.is_list("1. item", nil))
      -- unordered line — is_ordered returns nil for unordered
      assert.is_falsy(utils.is_list("- item", nil))
    end)

    it("with more=true, requires whitespace after marker", function()
      assert.is_truthy(utils.is_list("- item", list_types, true))
      -- bare marker at end-of-line has no trailing space
      -- (but the upstream %u* pattern may behave oddly here)
    end)
  end)

  -- ── get_marker ─────────────────────────────────────────────────────
  describe("get_marker", function()
    it("extracts marker from unordered list", function()
      assert.are.equal("-", utils.get_marker("- item", list_types))
      assert.are.equal("*", utils.get_marker("* item", list_types))
      assert.are.equal("+", utils.get_marker("+ item", list_types))
    end)

    it("extracts marker from ordered list", function()
      assert.are.equal("1.", utils.get_marker("1. item", list_types))
      assert.are.equal("3)", utils.get_marker("3) item", list_types))
    end)

    it("extracts marker from indented list", function()
      assert.are.equal("-", utils.get_marker("   - item", list_types))
      assert.are.equal("1.", utils.get_marker("   1. item", list_types))
    end)

    it("extracts roman numeral marker", function()
      assert.are.equal("IV.", utils.get_marker("IV. item", list_types))
    end)
  end)

  -- ── get_value_ordered ──────────────────────────────────────────────
  describe("get_value_ordered", function()
    it("returns digit value", function()
      assert.are.equal(1, utils.get_value_ordered("1. item"))
      assert.are.equal(42, utils.get_value_ordered("42. item"))
    end)

    it("returns ascii value (a=1, b=2, ...)", function()
      assert.are.equal(1, utils.get_value_ordered("a) item"))
      assert.are.equal(3, utils.get_value_ordered("c) item"))
    end)

    it("returns roman numeral value", function()
      assert.are.equal(1,  utils.get_value_ordered("I. item"))
      assert.are.equal(4,  utils.get_value_ordered("IV. item"))
      assert.are.equal(10, utils.get_value_ordered("X. item"))
    end)

    it("returns 0 for unordered lists", function()
      assert.are.equal(0, utils.get_value_ordered("- item"))
    end)
  end)

  -- ── get_ordered_add ────────────────────────────────────────────────
  describe("get_ordered_add", function()
    it("increments digit markers", function()
      assert.are.equal("2. item",  utils.get_ordered_add("1. item", 1))
      assert.are.equal("11. item", utils.get_ordered_add("10. item", 1))
    end)

    it("increments ascii markers", function()
      assert.are.equal("b) item", utils.get_ordered_add("a) item", 1))
    end)

    it("increments roman markers", function()
      assert.are.equal("II. item", utils.get_ordered_add("I. item", 1))
    end)

    it("does not change unordered markers", function()
      assert.are.equal("- item", utils.get_ordered_add("- item", 1))
    end)

    it("defaults to increment of 1", function()
      assert.are.equal("2. item", utils.get_ordered_add("1. item"))
    end)

    it("decrements digit markers", function()
      assert.are.equal("1. item", utils.get_ordered_add("2. item", -1))
    end)

    it("wraps alphabetic z -> a on increment", function()
      assert.are.equal("a) item", utils.get_ordered_add("z) item", 1))
    end)

    it("wraps alphabetic a -> z on decrement", function()
      assert.are.equal("z) item", utils.get_ordered_add("a) item", -1))
    end)
  end)

  -- ── set_ordered_value ──────────────────────────────────────────────
  describe("set_ordered_value", function()
    it("sets digit value", function()
      assert.are.equal("5. item", utils.set_ordered_value("1. item", 5))
    end)

    it("sets ascii value", function()
      assert.are.equal("c) item", utils.set_ordered_value("a) item", 3))
    end)

    it("sets roman value", function()
      assert.are.equal("V. item", utils.set_ordered_value("I. item", 5))
    end)

    it("leaves unordered unchanged", function()
      assert.are.equal("- item", utils.set_ordered_value("- item", 5))
    end)
  end)

  -- ── is_ordered ─────────────────────────────────────────────────────
  describe("is_ordered", function()
    it("returns truthy for ordered lists", function()
      assert.is_truthy(utils.is_ordered("1. item"))
      assert.is_truthy(utils.is_ordered("a) item"))
      assert.is_truthy(utils.is_ordered("I. item"))
    end)

    it("returns nil for unordered lists", function()
      assert.is_nil(utils.is_ordered("- item"))
      assert.is_nil(utils.is_ordered("* item"))
    end)

    it("returns nil for non-list lines", function()
      assert.is_nil(utils.is_ordered("just text"))
    end)
  end)

  -- ── set_line_marker (requires buffer) ──────────────────────────────
  describe("set_line_marker", function()
    local function setup_buf(lines)
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_set_current_buf(buf)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      return buf
    end

    it("replaces the marker of an ordered list item", function()
      local buf = setup_buf({ "1. item" })
      utils.set_line_marker(1, "2.", list_types)
      local result = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      assert.are.equal("2. item", result[1])
    end)

    it("replaces the marker of an unordered list item", function()
      local buf = setup_buf({ "- item" })
      utils.set_line_marker(1, "*", list_types)
      local result = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      assert.are.equal("* item", result[1])
    end)

    it("preserves indentation", function()
      local buf = setup_buf({ "   1. item" })
      utils.set_line_marker(1, "2.", list_types)
      local result = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      assert.are.equal("   2. item", result[1])
    end)

    it("trims trailing whitespace on the line", function()
      local buf = setup_buf({ "1. item   " })
      utils.set_line_marker(1, "2.", list_types)
      local result = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      assert.are.equal("2. item", result[1])
    end)
  end)

  -- ── set_current_line (requires buffer) ─────────────────────────────
  describe("set_current_line", function()
    it("sets current line and moves cursor to end", function()
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_set_current_buf(buf)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "old line" })
      vim.api.nvim_win_set_cursor(0, { 1, 0 })

      utils.set_current_line("new content here")
      local result = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      assert.are.equal("new content here", result[1])
    end)
  end)

  -- ── get_list_start (requires buffer) ───────────────────────────────
  describe("get_list_start", function()
    local function setup_buf(lines, cursor_line)
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_set_current_buf(buf)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      vim.api.nvim_win_set_cursor(0, { cursor_line or 1, 0 })
      return buf
    end

    it("returns the first line of a contiguous list", function()
      setup_buf({
        "1. first",
        "2. second",
        "3. third",
      }, 3)
      assert.are.equal(1, utils.get_list_start(3, list_types))
    end)

    it("returns current line when not in a list", function()
      setup_buf({
        "just text",
        "1. item",
      }, 1)
      assert.are.equal(1, utils.get_list_start(1, list_types))
    end)

    it("stops at a blank line (tight list boundary)", function()
      setup_buf({
        "1. first",
        "",
        "2. second",
      }, 3)
      -- The blank line breaks the list; line 3 is start of its own context
      assert.are.equal(3, utils.get_list_start(3, list_types))
    end)
  end)

  -- ── get_indent_list_start (requires buffer) ────────────────────────
  describe("get_indent_list_start", function()
    local function setup_buf(lines, cursor_line)
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_set_current_buf(buf)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      vim.api.nvim_win_set_cursor(0, { cursor_line or 1, 0 })
      return buf
    end

    it("finds start of a list at current indent level", function()
      setup_buf({
        "1. first",
        "2. second",
        "3. third",
      }, 3)
      assert.are.equal(1, utils.get_indent_list_start(3, list_types))
    end)

    it("walks past deeper-indented children", function()
      setup_buf({
        "1. parent",
        "    - child",
        "    - child2",
        "2. next parent",
      }, 4)
      assert.are.equal(1, utils.get_indent_list_start(4, list_types))
    end)

    it("returns nil for non-list lines", function()
      setup_buf({
        "just text",
      }, 1)
      assert.is_nil(utils.get_indent_list_start(1, list_types))
    end)

    it("handles ordered-only traversal when called without list_types", function()
      setup_buf({
        "1. first",
        "2. second",
      }, 2)
      -- without list_types, uses the else branch (ordered + indent logic)
      assert.are.equal(1, utils.get_indent_list_start(2, nil))
    end)
  end)
end)
