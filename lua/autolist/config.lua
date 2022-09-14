local default_config = {
	enabled = true,
	list_cap = 50,
	colon = {
		indent_raw = true,
		indent = true,
		preferred = "-"
	},
	invert = {
		indent = false,
		toggles_checkbox = true,
		ul_marker = "-",
		ol_incrementable = "1",
		ol_delim = ".",
	},
	lists = {
		preloaded = {
			generic = {
				"unordered",
				"digit",
				"ascii",
			},
			latex = {
				"latex_item",
			},
		},
		filetypes = {
			generic = {
				"markdown",
				"text",
			},
			latex = {
				"tex",
				"plaintex",
			},
		},
	},
	recal_function_hooks = {
		"invert",
		"new",
	},
	checkbox = {
		left = "%[",
		right = "%]",
		fill = "x",
	},
	insert_mappings = {
		invert = { "<c-r>+[catch]" },
		new = { "<CR>" },
		tab = { "<c-t>" },
		detab = { "<c-d>" },
		recal = { "<c-z>" },
		indent = {
			"<tab>+('>>')",
			"<s-tab>+('<<')",
		},
	},
	normal_mappings = {
		new = {
			"o",
			"O+(true)",
		},
		tab = { ">>" },
		detab = { "<<" },
		recal = { "dd" },
	},
}

local function au(evt, pat, cmd) -- (string|recalle), (string|table), (string)
	vim.api.nvim_create_autocmd(evt, { pattern = pat, command = cmd, })
end

local preloaded_lists = {
	unordered = "[-+*]",
	digit = "%d+[.)]",
	ascii = "%a[.)]",
	latex_item = "\\item"
}

local function get_preloaded_pattern(pre)
	local val = preloaded_lists[pre]
	-- if the option is not in preloaded_lists return the pattern
	if not val then
		return pre
	end
	return val
end

local function setmap(func, mappings, ft, mode)
	for _, map in pairs(mappings) do
		local args = (map:match("%+%(.*%)") or ""):sub(3, -2)
		local catch = (map:match("%+%[.*%]") or ""):sub(3, -2)
		map = map:gsub("%+.*", "")
		if catch == "catch" then
			map = map .. " " -- catch the mapping, dont execute
		else
			map = map .. " " .. map -- execute the mapping
		end
		au("Filetype", ft, mode .. " <buffer> " .. map .. "<cmd>lua require('autolist')." .. func .. "(" .. args .. ")<cr>")
	end
end

local M = vim.deepcopy(default_config)

M.update = function(opts)
	local newconf = vim.tbl_deep_extend("force", default_config, opts or {})

	local filetype_lists = {}
	for list, filetypes in pairs(newconf.lists.filetypes) do
		for _, filetype in pairs(filetypes) do
			if not filetype_lists[filetype] then
				filetype_lists[filetype] = {}
			end
			for _, list_type in pairs(newconf.lists.preloaded[list]) do
				table.insert(filetype_lists[filetype], get_preloaded_pattern(list_type))
			end
		end
	end

	-- DEBUG: this lists the patterns for each filetype
	-- for filetype, table in pairs(filetype_lists) do
	-- 	for _, pattern in pairs(table) do
	-- 		print(filetype, pattern)
	-- 	end
	-- end

	if newconf.enabled then

		-- for each filetype in th enabled filetypes
		for ft, _ in pairs(filetype_lists) do
			for func, mappings in pairs(newconf.normal_mappings) do setmap(func, mappings, ft, "nnoremap") end
			for func, mappings in pairs(newconf.insert_mappings) do setmap(func, mappings, ft, "inoremap") end
		end
	end

	for k, v in pairs(newconf) do
		M[k] = v
	end

	-- options that are hidden from config options but accessible by the scripts
	M.ft_lists = filetype_lists
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
	M.recal_full = false -- I don't think this should be a config option
end

return M
