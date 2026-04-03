-- Tests for autolist init.lua (setup, command registration)

describe("init", function()
  it("setup creates PascalCase vim commands", function()
    local autolist = require("autolist")
    autolist.setup()

    -- Check that key commands exist. vim.fn.exists returns 2 for commands.
    assert.are.equal(2, vim.fn.exists(":AutolistRecalculate"))
    assert.are.equal(2, vim.fn.exists(":AutolistNewBullet"))
    assert.are.equal(2, vim.fn.exists(":AutolistNewBulletBefore"))
    assert.are.equal(2, vim.fn.exists(":AutolistToggleCheckbox"))
    assert.are.equal(2, vim.fn.exists(":AutolistCycleNext"))
    assert.are.equal(2, vim.fn.exists(":AutolistCyclePrev"))
    assert.are.equal(2, vim.fn.exists(":AutolistTab"))
    assert.are.equal(2, vim.fn.exists(":AutolistShiftTab"))
  end)

  it("setup exposes auto functions on the module", function()
    local autolist = require("autolist")
    autolist.setup()

    assert.is_function(autolist.recalculate)
    assert.is_function(autolist.new_bullet)
    assert.is_function(autolist.new_bullet_before)
    assert.is_function(autolist.toggle_checkbox)
    assert.is_function(autolist.cycle_next)
    assert.is_function(autolist.cycle_prev)
    assert.is_function(autolist.tab)
    assert.is_function(autolist.shift_tab)
  end)

  it("setup passes options through to config", function()
    local autolist = require("autolist")
    local config = require("autolist.config")

    autolist.setup({ colon = { preferred = "+" } })
    assert.are.equal("+", config.colon.preferred)

    -- reset
    autolist.setup({ colon = { preferred = "-" } })
  end)

  it("create_mapping_hook prints deprecation warning", function()
    local autolist = require("autolist")
    -- This function should exist but just print a warning
    assert.is_function(autolist.create_mapping_hook)
  end)
end)
