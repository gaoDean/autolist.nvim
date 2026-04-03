-- Tests for autolist.config

local config = require("autolist.config")

describe("config", function()

  -- ── defaults ────────────────────────────────────────────────────────
  describe("defaults", function()
    before_each(function()
      config.update()
    end)

    it("is enabled by default", function()
      assert.is_true(config.enabled)
    end)

    it("has colon settings", function()
      assert.is_true(config.colon.indent)
      assert.is_true(config.colon.indent_raw)
      assert.are.equal("-", config.colon.preferred)
    end)

    it("has cycle list with 6 entries starting with '-'", function()
      assert.are.equal(6, #config.cycle)
      assert.are.equal("-", config.cycle[1])
      assert.are.equal("*", config.cycle[2])
      assert.are.equal("1.", config.cycle[3])
      assert.are.equal("1)", config.cycle[4])
      assert.are.equal("a)", config.cycle[5])
      assert.are.equal("I.", config.cycle[6])
    end)

    it("has markdown file type lists", function()
      assert.is_table(config.lists.markdown)
      assert.is_true(#config.lists.markdown > 0)
    end)

    it("has text file type lists", function()
      assert.is_table(config.lists.text)
      assert.is_true(#config.lists.text > 0)
    end)

    it("has norg file type lists (reversed neorg patterns)", function()
      assert.is_table(config.lists.norg)
      assert.is_true(#config.lists.norg > 0)
    end)

    it("has tex and plaintex file type lists", function()
      assert.is_table(config.lists.tex)
      assert.is_table(config.lists.plaintex)
    end)

    it("has checkbox config", function()
      assert.are.equal("%[", config.checkbox.left)
      assert.are.equal("%]", config.checkbox.right)
      assert.are.equal("x", config.checkbox.fill)
    end)

    it("sets list_cap to 50", function()
      assert.are.equal(50, config.list_cap)
    end)

    it("sets tab and tabstop based on expandtab", function()
      assert.is_not_nil(config.tab)
      assert.is_not_nil(config.tabstop)
    end)
  end)

  -- ── update / merge ──────────────────────────────────────────────────
  describe("update", function()
    it("merges user options without clobbering sibling keys", function()
      config.update({ colon = { preferred = "*" } })
      assert.are.equal("*", config.colon.preferred)
      -- other colon defaults preserved
      assert.is_true(config.colon.indent)
      assert.is_true(config.colon.indent_raw)
    end)

    it("does nothing when enabled is false", function()
      local old_cycle = config.cycle
      config.update({ enabled = false })
      -- cycle should not have been updated (early return)
      assert.are.equal(old_cycle, config.cycle)
    end)

    it("adds custom filetypes to lists", function()
      config.update({
        lists = {
          org = { "[-+*]" },
        },
      })
      assert.is_table(config.lists.org)
      assert.are.equal("[-+*]", config.lists.org[1])
    end)

    it("can override checkbox fill character", function()
      config.update({ checkbox = { left = "%(", right = "%)", fill = "X" } })
      assert.are.equal("%(", config.checkbox.left)
      assert.are.equal("%)", config.checkbox.right)
      assert.are.equal("X", config.checkbox.fill)
    end)

    it("recalculates tab string when expandtab changes", function()
      vim.opt.expandtab = true
      vim.opt.tabstop = 2
      config.update()
      assert.are.equal("  ", config.tab)
      assert.are.equal(2, config.tabstop)

      vim.opt.expandtab = false
      config.update()
      assert.are.equal("\t", config.tab)
      assert.are.equal(1, config.tabstop)
    end)
  end)
end)
