local config = {
	create_enter_mapping = true,
	new_entry_on_o = true,
	enabled_filetypes = { "markdown", "txt" },
}

local M = {}

function M.list()
	local preceding_line = vim.fn.getline(vim.fn.line(".") - 1)
	if preceding_line:match("^%s*%d+%.%s.") then
		local list_index = preceding_line:match("%d+")
		vim.fn.setline(".", preceding_line:match("^%s*") .. list_index + 1 .. ". ")
		vim.cmd([[execute "normal! \<esc>A\<space>"]])
	elseif preceding_line:match("^%s*%d+%.%s$") then
		vim.fn.setline(vim.fn.line(".") - 1, "")
	elseif preceding_line:match("^%s*[-+*]") and #preceding_line:match("[-+*].*") == 1 then
		vim.fn.setline(vim.fn.line(".") - 1, "")
		vim.fn.setline(".", "")
	end
end

function M.setup(set_config)
	if set_config then
		config = vim.tbl_deep_extend("force", config, set_config)
	end

	if config.create_enter_mapping then
		imap("<cr>", "<cr><cmd>lua require('autolist').list()<cr>")
		print("map")
	end

	for i, ft in ipairs(config.enabled_filetypes) do
		au("Filetype", ft, "setl comments=b:*,b:-,b:+,n:>")
		au("Filetype", ft, "setl formatoptions+=r")
		if config.new_entry_on_o then
			au("Filetype", ft, "setl formatoptions+=o")
		end
	end
end

-- helper

function au(evt, pat, cmd) -- (string|table), (string|table), (string)
	vim.api.nvim_create_autocmd(evt, { pattern = pat, command = cmd, })
end

function map(mode, keys, output)
	vim.api.nvim_set_keymap(mode, keys, output, { noremap = true, silent = true})
end

function imap(keys, output)
	map("i", keys, output)
end

return M
