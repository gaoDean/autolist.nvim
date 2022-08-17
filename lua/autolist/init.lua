local config = {
	create_enter_mapping = true,
	-- for if you have something else that you want to map when press return
	-- with the create enter being false, you must create your own mapping

	new_entry_on_o = true,
	-- when key o pressed, new list entry. Enables fo_o.

	override_fo_o = true,
	-- if you don't use formatoptions o, set this to true
	-- it will disable fo_o for all filetypes except for enabled types.

	-- if you use any of the override options, you must remove any
	-- definitions of the overrided formatoptions.

	override_fo_r = true,
	-- if you don't use formatoptions r, set this to true
	-- it will disable fo_r for all filetypes except for enabled types.

	enabled_filetypes = { "markdown", "text" },
	-- filetypes that this plugin is enabled for
	-- must put file name, not the extension
	-- if you are not sure of the name, just run :echo &filetype
}

local M = {}

function M.list()
	local continue = false
	for i, ft in ipairs(config.enabled_filetypes) do
		if ft == vim.bo.filetype then
			continue = true
		end
	end
	if not continue then
		return
	end

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
