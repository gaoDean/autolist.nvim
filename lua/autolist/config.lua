-- credit to https://github.com/stevearc/dressing.nvim
-- because i couldn't figure out how to do the config override
-- my excuse is this is my first plugin so ykyk

local default_config = {
	-- enables/disables the plugin
	enabled = true,

	-- for if you have something else that you want to map when press return
	-- with the create enter being false, you must create your own mapping
	create_enter_mapping = true,

	-- when key o pressed, new list entry, functions like <cr> but normal mode
	-- also enables capital O
	new_entry_on_o = true,

	-- the max list entries it will recalculate
	list_cap = 50,

	-- line ending with a colon
	colon = {
		-- when a line ends with a colon, the list is automatically indented
		indent_raw = true,

		-- when a *list* ends with a colon, the list is automatically indented
		indent = true,

		-- the preferred marker when starting a list from a colon
		-- set to empty to use current
		preferred = "-"
	},

	invert = {
		-- the mapping to invert the list type e.g ol -> ul, ul -> ol
		-- set this to empty ("") to disable
		mapping = "<c-r>",

		-- invert mapping in normal mode
		normal_mapping = "",

		-- when no indent and it wants to change the list marker (not checkbox)
		-- indent the line then change the list marker.
		indent = false,

		-- when there is a list like - [x] content, when invert mapping is
		-- pressed and below option is true the list will turn into
		-- - [ ] content, instead of 1. [x] content
		toggles_checkbox = true,

		-- when pressing the relist mapping and current marker is ordered list,
		-- change to {ul_marker}.
		ul_marker = "-",

		-- the following two settings configure changing from ul to ol
		-- the incrementable part of the ordered list
		-- this can be a number or a char (depending on what you want)
		-- so if the following was "a" (or "b" or "c" etc), ul -> "a. " (or "b. ")
		ol_incrementable = "1",

		-- if you put ")", ul -> "1) " (or "2) ")
		-- basically what goes after {ol_incrementable}
		ol_delim = ".",
	},

	-- the list entries that will be autocompleted
	lists = {
		preloaded = {
			-- these options correspond to the options in the {filetypes} table
			generic = {
				"unordered",
				"digit",
				"ascii",
			},
			latex = {
				"latex_item",
			},
			-- you can set your own list types using lua's patterns, take a
			-- look at the preloaded_lists variable in this file
		},

		-- its hard to wrap your mind around but in preloaded_lists, each table
		-- is a "group" of list types, and in this filetypes table, each
		-- filetype is a filetype that this "group" is applied to.
		filetypes = {
			-- must put file name, not the extension.
			-- if you are not sure, just run :set filetype? or :echo &filetype

			-- this means the generic lists will be applied to markdown and text
			generic = {
				"markdown",
				"text",
			},
			-- this means the latex preloaded group is applied to latex files only
			latex = {
				"tex",
				"plaintex",
			},
		},
	},

	-- a list of functions you run recal() on finish
	-- currently you can do invert() and/or new()
	recal_hooks = {
		"invert",
		"new",
	},

	-- used to configure what is matched as a checkbox
	-- in this case a filled checkbox would be "%[x%]" or "[x]"
	checkbox = {
		left = "%[",
		right = "%]",
		fill = "x",
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
			if newconf.create_enter_mapping then
				au("Filetype", ft, "inoremap <buffer> <cr> <cr><cmd>lua require('autolist').new()<cr>")
			end
			if newconf.new_entry_on_o then
				au("Filetype", ft, "nnoremap <buffer> o o<cmd>lua require('autolist').new()<cr>")
				au("Filetype", ft, "nnoremap <buffer> O O<cmd>lua require('autolist').new(true)<cr>")
			end
			if newconf.invert.normal_mapping ~= "" then
				au("Filetype", ft, "nnoremap <buffer> " .. newconf.invert.normal_mapping .. " <cmd>lua require('autolist').invert()<cr>")
			end
			if newconf.invert.mapping ~= "" then
				au("Filetype", ft, "inoremap <buffer> " .. newconf.invert.mapping .. " <cmd>lua require('autolist').invert()<cr>")
			end

			-- to change mapping, just do a imap (not inoremap) to <c-t> to recursively remap
			au("Filetype", ft, "inoremap <buffer> <c-d> <c-d><cmd>lua require('autolist').detab()<cr>")
			au("Filetype", ft, "inoremap <buffer> <c-t> <c-t><cmd>lua require('autolist').tab()<cr>")
			au("Filetype", ft, "nnoremap <buffer> << <<<cmd>lua require('autolist').detab()<cr>")
			au("Filetype", ft, "nnoremap <buffer> >> >><cmd>lua require('autolist').tab()<cr>")
			-- au("Filetype", ft, "nnoremap <buffer> dd dd<cmd>lua require('autolist').unlist()<cr>")
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
