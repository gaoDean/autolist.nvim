local default_config = {
  enabled = true,
  colon = { -- if a line ends in a colon
    indent = true, -- if in list and line ends in `:` then create list
    indent_raw = true, -- above, but doesn't need to be in a list to work
    preferred = "-", -- what the new list starts with (can be `1.` etc)
  },
  invert = { -- Inverts the list type (ol -> ul, ul -> ol, [ ] -> [x])
    indent = false, -- when on top level list, pressing invert inverts the list and indents it
    toggles_checkbox = true, -- if pressing invert toggles checkbox
    ul_marker = "-", -- when from ordered list to unordered, set marker to whatever this is
    ol_incrementable = "1", -- same thing above but for ordered
  },
  lists = { -- configures list behavio
    -- Each key in lists represents a filetype.
    -- The value is a table of all the list patterns that the filetype implements.
    -- See how to define your custom list below
    -- You can see a few preloaded options in the default configuration such as "unordered" and "digit"
    -- of which the full set you can find in the config.list_patterns
    -- You must put the file name for the filetype, not the file extension
    -- To get the "file name", it is just =:set filetype?= or =:se ft?=.
    markdown = {
      "unordered",
      "digit",
      "ascii", -- specifies activate the ascii list type for markdown files
      "roman", -- see below on the list types
    },
    text = {
      "unordered",
      "digit",
      "ascii",
      "roman",
    },
    tex = { "latex_item" },
    plaintex = { "latex_item" },
  },
  list_patterns = { -- custom list types: see README -> Configuration -> defining custom lists
    unordered = "[-+*]", -- - + *
    digit = "%d+[.)]", -- 1. 2. 3.
    ascii = "%a[.)]", -- a) b) c)
    roman = "%u*[.)]", -- I. II. III.
    latex_item = "\\item",
  },
  checkbox = {
    left = "%[", -- the left checkbox delimiter (you could change to "%(" for brackets)
    right = "%]", -- the right checkbox delim (same customisation as above)
    fill = "x", -- if you do the above two customisations, your checkbox could be (x) instead of [x]
  },

  -- this is all based on lua patterns, see "Defining custom lists" for a nice article to learn them
}

local function get_preloaded_pattern(config, pre)
	local val = config.list_patterns[pre]
	-- if the option is not in preloaded_lists return the pattern
	if not val then return pre end
	return val
end

local M = vim.deepcopy(default_config)

M.update = function(opts)
	local newconf = vim.tbl_deep_extend("force", default_config, opts or {})

	if not newconf.enabled then return end

	for filetype, patterns in pairs(newconf.lists) do
		for i, pattern in pairs(patterns) do
			patterns[i] = get_preloaded_pattern(newconf, pattern)
		end
	end

	for k, v in pairs(newconf) do
		M[k] = v
	end

	-- options that are hidden from config options but accessible by the scripts
	M.list_cap = 50
	M.tabstop = vim.opt.tabstop:get()
	if vim.opt.expandtab:get() then
		local pattern = ""
		-- pattern is tabstop in the form of spaces
		for i = 1, M.tabstop, 1 do
			pattern = pattern .. " "
		end
		M.tab = pattern
	else
		M.tab = "\t"
		-- just for logistics
		M.tabstop = 1 -- honestly i bet tmr i will not know why i did this
	end
	M.recal_full = false
end

return M
