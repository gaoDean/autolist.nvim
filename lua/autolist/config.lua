-- credit to https://github.com/stevearc/dressing.nvim
-- because i couldn't figure out how to do the config override
-- my excuse is this is my first plugin so ykyk

local default_config = {
	generic = {

		enabled = true,

		-- for if you have something else that you want to map when press return
		-- with the create enter being false, you must create your own mapping
		create_enter_mapping = true,

		-- the mapping to invert the list type e.g ol -> ul, ul -> ol
		-- set this to empty ("") to disable
		invert_mapping = "<c-r>",

		-- when pressing the relist mapping and current marker is ordered list,
		-- change to invert_ul_marker.
		invert_ul_marker = "-",

		-- This just allows the relisting function to use the current list
		-- formatting to search for the right list type.
		-- Important: if your markdown ordered lists are badly formatted e.g a one
		-- followed by a three, the relist cant find the right list. most of the
		-- time you'll have the correct formatting, and its not a big deal if you
		-- dont, the program wont throw an error, you just wont get a relist.
		context_optim = true,

		-- when key o pressed, new list entry. Enables fo_o. see :h fo-table
		new_entry_on_o = true,

		-- if you use any of the override options, you must remove any definitions
		-- of the overrided formatoptions, or you can define the options before
		-- sourcing the require setup for this plugin, so it can override it.
		-- see README#configuration

		-- if you don't use fo_r (or if you disable it), set this to true.
		-- it will disable fo_r for all filetypes except for enabled types.
		-- perhaps grep for "formatoptions-=r" and "fo-=r"
		override_fo_r = true,

		-- if you don't use fo_o (or if you disable it), set this to true
		-- it will disable fo_o for all filetypes except for enabled types.
		-- perhaps grep for "formatoptions-=o" and "fo-=o"
		override_fo_o = true,

		-- filetypes that this plugin is enabled for.
		-- must put file name, not the extension.
		-- if you are not sure, just run :echo &filetype. or :set filetype?
		enabled_filetypes = { "markdown", "text" },
	},
}

local function au(evt, pat, cmd) -- (string|table), (string|table), (string)
	vim.api.nvim_create_autocmd(evt, { pattern = pat, command = cmd, })
end

local function map(mode, keys, output)
	vim.api.nvim_set_keymap(mode, keys, output, { noremap = false, silent = true})
end

local function nmap(keys, output)
	map("n", keys, output)
end

local function imap(keys, output)
	map("i", keys, output)
end

local M = vim.deepcopy(default_config)

M.update = function(opts)
	local newconf = vim.tbl_deep_extend("force", default_config, opts or {})

	if newconf.generic.enabled then
		if newconf.generic.override_fo_o then
			au("Filetype", "*", "setl formatoptions-=o")
		end

		if newconf.generic.override_fo_r then
			au("Filetype", "*", "setl formatoptions-=r")
		end

		-- for each filetype in enabled_filetypes
		for i, ft in ipairs(newconf.generic.enabled_filetypes) do
			-- there are no comments in markdown so comments should be free for use
			au("Filetype", ft, "setl comments=b:*,b:-,b:+,n:>")
			au("Filetype", ft, "setl formatoptions+=r")
			if newconf.generic.new_entry_on_o then
				au("Filetype", ft, "setl formatoptions+=o")
			end
			if newconf.generic.create_enter_mapping then
				au("Filetype", ft, "inoremap <buffer> <cr> <cr><cmd>lua require('autolist').list()<cr>")
			end
			if newconf.generic.new_entry_on_o then
				au("Filetype", ft, "nnoremap <buffer> o o<cmd>lua require('autolist').list()<cr>")
			end
			if newconf.generic.invert_mapping ~= "" then
				au("Filetype", ft, "inoremap <buffer> " .. newconf.generic.invert_mapping .. " <cmd>lua require('autolist').invert()<cr>")
			end

			-- to change mapping, just do a imap (not inoremap) to <c-t> to recursively remap
			au("Filetype", ft, "inoremap <buffer> <c-d> <c-d><cmd>lua require('autolist').relist()<cr>")
			au("Filetype", ft, "inoremap <buffer> <c-t> <c-t><cmd>lua require('autolist').reset()<cr>")
			au("Filetype", ft, "nnoremap <buffer> << <<<cmd>lua require('autolist').relist()<cr>")
			au("Filetype", ft, "nnoremap <buffer> >> >><cmd>lua require('autolist').reset()<cr>")
			au("Filetype", ft, "nnoremap <buffer> dd dd<cmd>lua require('autolist').unlist()<cr>")
		end
	end

	for k, v in pairs(newconf) do
		M[k] = v
	end
end

return M
