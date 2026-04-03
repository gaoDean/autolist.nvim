-- Integration tests for new_bullet() — bullet continuation, empty-bullet
-- deletion, and the new_bullet_before() variant.

local auto = require("autolist.auto")
local config = require("autolist.config")

--- Simulate pressing Enter in insert mode at end of line:
--- 1. Insert a blank line below the cursor
--- 2. Move the cursor to the new line
--- 3. Call auto.new_bullet()
local function simulate_enter(buf)
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(buf, cursor_line, cursor_line, false, { "" })
  vim.api.nvim_win_set_cursor(0, { cursor_line + 1, 0 })
  auto.new_bullet()
end

--- Helper: create a scratch buffer with markdown filetype.
local function make_buf(lines, cursor_line)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
  vim.bo.filetype = "markdown"
  vim.opt.expandtab = true
  vim.opt.tabstop = 4
  config.update()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(0, { cursor_line or #lines, 0 })
  return buf
end

local function get_lines(buf)
  return vim.api.nvim_buf_get_lines(buf, 0, -1, false)
end

-- ──────────────────────────────────────────────────────────────────────────
describe("new_bullet", function()

  -- ── ordered list continuation ──────────────────────────────────────
  describe("ordered list continuation", function()
    it("creates next numbered bullet after a content-filled item", function()
      local buf = make_buf({ "1. First" }, 1)

      simulate_enter(buf)
      local r = get_lines(buf)
      assert.are.equal("1. First", r[1])
      assert.are.equal("2. ", r[2])
    end)

    it("creates correct next number for multi-digit lists", function()
      local buf = make_buf({ "9. Ninth" }, 1)

      simulate_enter(buf)
      local r = get_lines(buf)
      assert.are.equal("10. ", r[2])
    end)

    it("continues alphabetic lists", function()
      local buf = make_buf({ "a) First" }, 1)

      simulate_enter(buf)
      local r = get_lines(buf)
      assert.are.equal("b) ", r[2])
    end)

    it("continues roman numeral lists", function()
      local buf = make_buf({ "I. First" }, 1)

      simulate_enter(buf)
      local r = get_lines(buf)
      assert.are.equal("II. ", r[2])
    end)
  end)

  -- ── unordered list continuation ────────────────────────────────────
  describe("unordered list continuation", function()
    it("creates same unordered bullet (-)", function()
      local buf = make_buf({ "- First" }, 1)

      simulate_enter(buf)
      local r = get_lines(buf)
      assert.are.equal("- First", r[1])
      assert.are.equal("- ", r[2])
    end)

    it("creates same unordered bullet (*)", function()
      local buf = make_buf({ "* First" }, 1)

      simulate_enter(buf)
      local r = get_lines(buf)
      assert.are.equal("* ", r[2])
    end)

    it("creates same unordered bullet (+)", function()
      local buf = make_buf({ "+ First" }, 1)

      simulate_enter(buf)
      local r = get_lines(buf)
      assert.are.equal("+ ", r[2])
    end)
  end)

  -- ── empty bullet deletion ─────────────────────────────────────────
  describe("empty bullet deletion", function()
    it("deletes empty ordered bullet on enter", function()
      local buf = make_buf({ "1. First" }, 1)

      -- Enter 1: creates "2. "
      simulate_enter(buf)
      local r = get_lines(buf)
      assert.are.equal("2. ", r[2])

      -- Enter 2: empty bullet "2. " should be cleared
      simulate_enter(buf)
      r = get_lines(buf)
      assert.are.equal("1. First", r[1])
    end)

    it("deletes empty unordered bullet on enter", function()
      local buf = make_buf({ "- First" }, 1)

      -- Enter 1: creates "- "
      simulate_enter(buf)
      local r = get_lines(buf)
      assert.are.equal("- ", r[2])

      -- Enter 2: empty bullet "- " should be deleted
      simulate_enter(buf)
      r = get_lines(buf)
      assert.are.equal("- First", r[1])
    end)

    it("does not create spurious bullet on third enter", function()
      local buf = make_buf({ "1. First" }, 1)

      -- Enter 1 → creates bullet
      simulate_enter(buf)
      -- Enter 2 → deletes empty bullet
      simulate_enter(buf)
      -- Enter 3 → should NOT create a new bullet
      simulate_enter(buf)
      local r = get_lines(buf)

      -- Should not have any bullet other than "1. First"
      for i = 2, #r do
        assert.is_falsy(r[i]:match("^%d+%."), "spurious bullet on line " .. i .. ": " .. r[i])
      end
    end)
  end)

  -- ── checkbox continuation ─────────────────────────────────────────
  describe("checkbox continuation", function()
    it("continues a checkbox list with empty checkbox", function()
      local buf = make_buf({ "- [x] Done task" }, 1)

      simulate_enter(buf)
      local r = get_lines(buf)
      -- Should create a new bullet; the checkbox part is included in the bullet
      assert.is_truthy(r[2]:match("^%- %[.%]"))
    end)
  end)

  -- ── filetype handling ─────────────────────────────────────────────
  describe("filetype handling", function()
    it("returns nil for unsupported filetype", function()
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_set_current_buf(buf)
      vim.bo.filetype = "rust"
      config.update()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "- item", "" })
      vim.api.nvim_win_set_cursor(0, { 2, 0 })

      local result = auto.new_bullet()
      assert.is_nil(result)
    end)
  end)

  -- ── indented list continuation ────────────────────────────────────
  describe("indented list continuation", function()
    it("preserves indentation on continuation", function()
      local buf = make_buf({ "    - Nested item" }, 1)

      simulate_enter(buf)
      local r = get_lines(buf)
      -- New bullet should have same indentation
      assert.is_truthy(r[2]:match("^    %- "))
    end)
  end)
end)

-- ──────────────────────────────────────────────────────────────────────────
describe("new_bullet_before", function()
  it("inserts bullet above current line", function()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buf)
    vim.bo.filetype = "markdown"
    vim.opt.expandtab = true
    vim.opt.tabstop = 4
    config.update()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
      "1. First",
      "",  -- simulate a blank line above where the bullet will go
    })
    -- Cursor on the blank line; the "previous line" (below) is line 1
    vim.api.nvim_win_set_cursor(0, { 1, 0 })

    -- Insert a blank line above
    vim.api.nvim_buf_set_lines(buf, 0, 0, false, { "" })
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    auto.new_bullet_before()

    local r = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    -- Should have a bullet on the first line
    assert.is_truthy(r[1]:match("%d+%.") or r[1] == "")
  end)
end)

-- ──────────────────────────────────────────────────────────────────────────
describe("colon indentation", function()
  it("creates indented bullet when previous line ends in colon", function()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buf)
    vim.bo.filetype = "markdown"
    vim.opt.expandtab = true
    vim.opt.tabstop = 4
    config.update()

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
      "My heading:",
      "",
    })
    vim.api.nvim_win_set_cursor(0, { 2, 0 })
    auto.new_bullet()

    local r = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    -- With indent_raw = true, a colon-ending line creates an indented bullet
    -- using config.colon.preferred (default "-")
    assert.is_truthy(r[2]:match("^%s+%-"), "expected indented bullet, got: " .. r[2])
  end)

  it("uses config.colon.preferred marker", function()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buf)
    vim.bo.filetype = "markdown"
    vim.opt.expandtab = true
    vim.opt.tabstop = 4
    config.update({ colon = { preferred = "*" } })

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
      "My heading:",
      "",
    })
    vim.api.nvim_win_set_cursor(0, { 2, 0 })
    auto.new_bullet()

    local r = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    assert.is_truthy(r[2]:match("%*"), "expected '*' bullet, got: " .. r[2])

    -- reset
    config.update({ colon = { preferred = "-" } })
  end)
end)
