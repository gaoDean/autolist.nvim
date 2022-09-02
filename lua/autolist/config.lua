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
	new_entry_on_o = true,

	-- the max list entries it will recalculate
	list_cap = 50,

	invert = {
		-- the mapping to invert the list type e.g ol -> ul, ul -> ol
		-- set this to empty ("") to disable
		mapping = "<c-r>",

		-- invert mapping in normal mode
		normal_mapping = "",

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

	-- filetypes that this plugin is enabled for.
	-- must put file name, not the extension.
	-- if you are not sure, just run :echo &filetype. or :set filetype?
	enabled_filetypes = {
		"markdown",
		"text",
	},

	-- the list entries that will be autocompleted
	lists = {
		generic = {
			"md",
			"digit",
			"ascii",
		},
		-- a table that is used to contain the patterns, as well as any custom
		-- patterns you might want. see preloaded_lists in this file.
		all = { },
	},

	-- a list of functions you run recal() on finish
	-- currently you can do invert() and/or new()
	recal_hooks = {
		"invert",
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
	md = "[-+*]",
	digit = "%d+[.)]",
	ascii = "%a[.)]",
}

local M = vim.deepcopy(default_config)

M.update = function(opts)
	local newconf = vim.tbl_deep_extend("force", default_config, opts or {})

	if newconf.enabled then

		-- append the value of the preloaded generic lists to {all}
		for i, v in ipairs(newconf.lists.generic) do
			-- the first part just appends on to newconf.lists.all
			-- the newconf.lists.generic stores the key for the value in preloaded_lists
			newconf.lists.all[#newconf.lists.all + 1] = preloaded_lists[v]
		end

		-- for each filetype in enabled_filetypes
		for i, ft in ipairs(newconf.enabled_filetypes) do
			if newconf.create_enter_mapping then
				au("Filetype", ft, "inoremap <buffer> <cr> <cr><cmd>lua require('autolist').new()<cr>")
			end
			if newconf.new_entry_on_o then
				au("Filetype", ft, "nnoremap <buffer> o o<cmd>lua require('autolist').new()<cr>")
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
end

return M
