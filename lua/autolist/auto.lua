local M = {}

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

return M
