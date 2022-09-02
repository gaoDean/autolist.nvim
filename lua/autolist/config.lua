-- credit to https://github.com/stevearc/dressing.nvim
-- because i couldn't figure out how to do the config override
-- my excuse is this is my first plugin so ykyk

local default_config = {
	enabled = true,

	-- for if you have something else that you want to map when press return
	-- with the create enter being false, you must create your own mapping
	create_enter_mapping = true,

	-- the mapping to invert the list type e.g ol -> ul, ul -> ol
	-- set this to empty ("") to disable
	invert_mapping = "<c-r>",

	-- invert mapping in normal mode
	invert_normal_mapping = "",

	-- when there is a list like - [x] content, when invert mapping is
	-- pressed and below option is true the list will turn into
	-- - [ ] content, instead of 1. [x] content
	invert_toggles_checkbox = true,

	-- when pressing the relist mapping and current marker is ordered list,
	-- change to invert_ul_marker.
	invert_ul_marker = "-",

	-- the following two settings configure changing from ul to ol
	-- if you put ")", ul -> "1) " (or "2) ")
	invert_ol_delim = ".",

	-- the incrementable part of the ordered list
	-- this can be a number or a char (depending on what you want)
	-- so if the following was "a" (or "b" or "c" etc), ul -> "a. " (or "b. ")
	invert_ol_incrementable = "1",

	-- when key o pressed, new list entry. Enables fo_o. see :h fo-recalle
	new_entry_on_o = true,

	-- filetypes that this plugin is enabled for.
	-- must put file name, not the extension.
	-- if you are not sure, just run :echo &filetype. or :set filetype?
	enabled_filetypes = {
		"markdown",
		"text",
	},

	-- the list entries that will be autocompleted
	list_types = {
		"[-+*]",
		"%d+%.",
		"%a[.)]",
	},

	recal_hooks = {
		"invert",
	},

	-- used to configure what is matched as a checkbox
	checkbox_left = "%[",
	checkbox_right = "%]",
	checkbox_fill = "x",
}

local function au(evt, pat, cmd) -- (string|recalle), (string|table), (string)
	vim.api.nvim_create_autocmd(evt, { pattern = pat, command = cmd, })
end

local M = vim.deepcopy(default_config)

M.update = function(opts)
	local newconf = vim.tbl_deep_extend("force", default_config, opts or {})

	if newconf.enabled then

		-- for each filetype in enabled_filetypes
		for i, ft in ipairs(newconf.enabled_filetypes) do
			if newconf.create_enter_mapping then
				au("Filetype", ft, "inoremap <buffer> <cr> <cr><cmd>lua require('autolist').new()<cr>")
			end
			if newconf.new_entry_on_o then
				au("Filetype", ft, "nnoremap <buffer> o o<cmd>lua require('autolist').new()<cr>")
			end
			if newconf.invert_normal_mapping ~= "" then
				au("Filetype", ft, "nnoremap <buffer> " .. newconf.invert_normal_mapping .. " <cmd>lua require('autolist').invert()<cr>")
			end
			if newconf.invert_mapping ~= "" then
				au("Filetype", ft, "inoremap <buffer> " .. newconf.invert_mapping .. " <cmd>lua require('autolist').invert()<cr>")
			end

			-- to change mapping, just do a imap (not inoremap) to <c-t> to recursively remap
			au("Filetype", ft, "inoremap <buffer> <c-d> <c-d><cmd>lua require('autolist').recal()<cr>")
			au("Filetype", ft, "inoremap <buffer> <c-t> <c-t><cmd>lua require('autolist').recal()<cr>")
			au("Filetype", ft, "nnoremap <buffer> << <<<cmd>lua require('autolist').recal()<cr>")
			au("Filetype", ft, "nnoremap <buffer> >> >><cmd>lua require('autolist').recal()<cr>")
			-- au("Filetype", ft, "nnoremap <buffer> dd dd<cmd>lua require('autolist').unlist()<cr>")
		end
	end

	for k, v in pairs(newconf) do
		M[k] = v
	end
end

return M
