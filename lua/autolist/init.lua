local M = {}

M.default_config = {
	create_cr_mapping = true
}

M.list = function()
	local preceding_line = vim.fn.getline(vim.fn.line(".") - 1)
	if preceding_line:match("^%s*%d+%.%s.") then
		local list_index = preceding_line:match("%d+")
		print(list_index .. "t")
		vim.fn.setline(".", preceding_line:match("^%s*") .. list_index + 1 .. ". ")
		vim.cmd([[execute "normal \<esc>A\<space>"]])
	elseif preceding_line:match("^%s*%d+%.%s$") then
		vim.fn.setline(vim.fn.line(".") - 1, "")
	elseif preceding_line:match("^%s*[-+*]") and #preceding_line:match("[-+*].*") == 1 then
		vim.fn.setline(vim.fn.line(".") - 1, "")
		vim.fn.setline(".", "")
	end
end

M.setup = function(config)
	vim.validate({ config = { config, 'table', true } })
	config = vim.tbl_deep_extend('force', M.default_config, config or {})
	create_cr_mapping = config.create_cr_mapping
	config = setup_config(config)
	apply_config(config)
end

local function setup_config(config)
end

local function apply_config(config)
	if config.create_cr_mapping then
		vim.api.nvim_set_keymap('i', '<cr>', [[<cr><cmd>lua require("autolist").list()<cr>]], { noremap = true, silent = true })
	end
end

return M
