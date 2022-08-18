local config = require("autolist.config")

local M = {}

local fn = vim.fn
local marker_digit = "%d+"
local marker_md = "[-+*]"
local marker_ol = "^%s*%d+%.%s."
local marker_ul = "^%s*[-+*]%s."

-- gets the marker of {line} and if its a digit it adds {add}
local function get_marker(line, add)
	if line:match(ol_marker) then
		line = line:match(marker_digit) + add .. ". "
	else if marker:match(ul_marker) then
		line = line:match(marker_md) .. " "
	end
	return line
end
end

local function neither_list(line)
	if (not line:match(ol_marker)) and (not line:match(ul_marker)) then
		return true
	end
	return false
end

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

	local prev_line = fn.getline(fn.line(".") - 1)
	if prev_line:match("^%s*%d+%.%s.") then
		local list_index = prev_line:match("%d+")
		fn.setline(".", prev_line:match("^%s*") .. list_index + 1 .. ". ")
		vim.cmd([[execute "normal! \<esc>A\<space>"]])
	elseif prev_line:match("^%s*%d+%.%s$") then
		fn.setline(fn.line(".") - 1, "")
	elseif prev_line:match("^%s*[-+*]") and #prev_line:match("[-+*].*") == 1 then
		fn.setline(fn.line(".") - 1, "")
		fn.setline(".", "")
	end
end

function M.tab()
	-- checks if current filetype is in enabled filetypes
	local continue = false
	for i, ft in ipairs(config.enabled_filetypes) do
		-- the filetype of current buffer
		if ft == vim.bo.filetype then
			continue = true
		end
	end
	if not continue then
		return
	end

	-- if prev line is numbered, set current line number to 1
	local prev_line = fn.getline(fn.line(".") - 1)
	if prev_line:match("^%s*%d+%.%s.") then
		fn.setline(".", fn.getline("."):sub("%d+", "1"))
	end
end

function M.detab()
	-- checks if current filetype is in enabled filetypes
	local continue = false
	for i, ft in ipairs(config.enabled_filetypes) do
		-- the filetype of current buffer
		if ft == vim.bo.filetype then
			continue = true
		end
	end
	if not continue then
		return
	end

	-- pattern matches
	local spc = "^%s*"
	local ol_marker = "^%s*%d+%.%s."
	local ul_marker = "^%s*[-+*]%s."

	local prev_line_ptr = fn.line(".") - 1
	local prev_line = fn.getline(prev_line_ptr)

	-- if prev line is a list entry
	if not neither_list(prev_line) then

		-- just a number
		local ptrline = prev_line_ptr

		local cur_indent = fn.getline("."):match(spc)
		local cur_marker = get_marker(fn.getline("."), 0)

		local optimised = config.optimised_renum
		if optimised then
			-- eval ptrline just gets the line that ptrline stores
			local eval_ptrline = fn.getline(ptrline)

			-- while the indents don't match
			while eval_ptrline:match(spc) ~= cur_indent do
				ptrline = ptrline - eval_ptrline:match(marker_digit)
				-- the list goes 1. 2. 3. so logically the last indent is
				-- before 1., so searches for 3. and goes 3 lines before that

				-- if ptrline out of bounds or eval_ptrline not a list entry
				if ptrline <= 0 or neither_list(eval_ptrline) then
					-- try using unoptimised search, skips setline function
					optimised = false
					break
				end
				eval_ptrline = fn.getline(ptrline)
			end

			-- found viable line
			if optimised then
				local new_marker = get_marker(fn.getline(ptrline), 1)
				-- use current line and substitue the marker for indent marker
				fn.setline(".", fn.getline("."):sub(cur_marker, new_marker))
			end
		end

		if not optimised then
			ptrline = prev_line_ptr
			-- search all lines before current for something of the same indent
			while fn.getline(ptrline):match(spc) ~= cur_indent do
				-- work upwards, checking every line
				ptrline = ptrline - 1
				-- should short curcuit / lazy or, so when getline is
				-- called ptrline should in the bounds of the file
				if ptrline <= 0 or neither_list(fn.getline(ptrline)) then
					-- if out of bounds or not list entry return
					return
				end
			end
			local new_marker = get_marker(fn.getline(ptrline), 1)
			fn.setline(".", fn.getline("."):sub(cur_marker, new_marker))
		end
	end
end


return M
