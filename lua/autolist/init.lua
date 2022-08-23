local config = require("autolist.config")

local M = {}

local func = require("autolist.list")
M.invert = func.invert
M.list = func.list
M.relist = func.relist
M.reset = func.reset
M.unlist = func.unlist

-- helper

local function au(evt, pat, cmd) -- (string|table), (string|table), (string)
	vim.api.nvim_create_autocmd(evt, { pattern = pat, command = cmd, })
end

local function map(mode, keys, output)
	vim.api.nvim_set_keymap(mode, keys, output, { noremap = true, silent = true})
end

local function nmap(keys, output)
	map("n", keys, output)
end

local function imap(keys, output)
	map("i", keys, output)
end

-- helper

function M.setup(set_config)
	if set_config then
		-- force uses 3rd arg's value if 2nd and 3rd have conflicting key-values
		config = vim.tbl_deep_extend("force", config, set_config)
	end

	if config.override_fo_o then
		au("Filetype", "*", "setl formatoptions-=o")
	end

	if config.override_fo_r then
		au("Filetype", "*", "setl formatoptions-=r")
	end

	-- for each filetype in enabled_filetypes
	for i, ft in ipairs(config.enabled_filetypes) do
		-- there are no comments in markdown so comments should be free for use
		au("Filetype", ft, "setl comments=b:*,b:-,b:+,n:>")
		au("Filetype", ft, "setl formatoptions+=r")
		if config.new_entry_on_o then
			au("Filetype", ft, "setl formatoptions+=o")
		end
		if config.create_enter_mapping then
			au("Filetype", ft, "inoremap <buffer> <cr> <cr><cmd>lua require('autolist').list()<cr>")
		end
		if config.new_entry_on_o then
			au("Filetype", ft, "nnoremap <buffer> o o<cmd>lua require('autolist').list()<cr>")
		end
		if config.invert_mapping ~= "" then
			au("Filetype", ft, "inoremap <buffer> " .. config.invert_mapping .. " <cmd>lua require('autolist').invert()<cr>")
		end

		-- to change mapping, just do a imap (not inoremap) to <c-t> to recursively remap
		au("Filetype", ft, "inoremap <buffer> <c-d> <c-d><cmd>lua require('autolist').relist()<cr>")
		au("Filetype", ft, "inoremap <buffer> <c-t> <c-t><cmd>lua require('autolist').reset()<cr>")
		au("Filetype", ft, "nnoremap <buffer> << <<<cmd>lua require('autolist').relist()<cr>")
		au("Filetype", ft, "nnoremap <buffer> >> >><cmd>lua require('autolist').reset()<cr>")
		au("Filetype", ft, "nnoremap <buffer> dd <cmd>lua require('autolist').unlist()<cr>dd")
	end

end

return M
