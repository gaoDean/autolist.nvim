local config = require("autolist.config")

local M = {}

local func = require("autolist.list")
M.reset = func.reset
M.relist = func.relist
M.list = func.list
M.invert = func.invert

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
		config = vim.tbl_deep_extend("force", config, set_config)
	end

	if config.create_enter_mapping then
		imap("<cr>", "<cr><cmd>lua require('autolist').list()<cr>")
	end

	if config.new_entry_on_o then
		nmap("o", "o<cmd>lua require('autolist').list()<cr>")
	end

	if config.invert_mapping ~= "" then
		imap(config.invert_mapping, "<cmd>lua require('autolist').invert()<cr>")
	end

	if config.tab_mapping ~= "" then
		imap(config.tab_mapping, "<c-t><cmd>lua require('autolist').reset()<cr>")
	end

	if config.detab_mapping ~= "" then
		imap(config.detab_mapping, "<c-d><cmd>lua require('autolist').relist()<cr>")
	end

	if config.override_fo_o then
		au("Filetype", "*", "setl formatoptions-=o")
	end

	if config.override_fo_r then
		au("Filetype", "*", "setl formatoptions-=r")
	end

	for i, ft in ipairs(config.enabled_filetypes) do
		au("Filetype", ft, "setl comments=b:*,b:-,b:+,n:>")
		au("Filetype", ft, "setl formatoptions+=r")
		if config.new_entry_on_o then
			au("Filetype", ft, "setl formatoptions+=o")
		end
	end

end

return M
