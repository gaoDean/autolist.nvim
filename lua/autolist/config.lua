local default_config = {
	enabled = true,
	list_cap = 50,
	colon = {
		indent_raw = true,
		indent = true,
		preferred = "-",
	},
	invert = {
		indent = false,
		toggles_checkbox = true,
		ul_marker = "-",
		ol_incrementable = "1",
		ol_delim = ".",
	},
	lists = {
		markdown = {
			"unordered",
			"digit",
			"ascii",
		},
		text = {
			"unordered",
			"digit",
			"ascii",
		},
		tex = { "latex_item" },
		plaintex = { "latex_item" },
	},
	list_patterns = {
		unordered = "[-+*]", -- - + *
		digit = "%d+[.)]", -- 1. 2. 3.
		ascii = "%a[.)]", -- a) b) c)
		latex_item = "\\item",
	},
	checkbox = {
		left = "%[",
		right = "%]",
		fill = "x",
	},
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
