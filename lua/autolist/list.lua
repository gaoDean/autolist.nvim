-- just some random things that are used:
-- string:gsub(pat, repl, n) where:
-- 		pat is a lua pattern
-- 		repl is a string, except %x where x is a digit means special thing
--		n is an int that means how many occurences of pat is replaced

local config = require("autolist.config")

local M = {}

local fn = vim.fn
local marker_digit = "%d+"
local marker_md = "[-+*]"
local marker_ol = "^%s*%d+%.%s." -- ordered list
local marker_ul = "^%s*[-+*]%s." -- unordered list

-- gets the marker of {line} and if its a digit it adds {add}
local function get_marker(line, add)
	if line:match(marker_ol) then
		line = line:match(marker_digit) + add .. ". "
	elseif line:match(marker_ul) then
		line = line:match(marker_md) .. " "
	end
	return line
end

local function get_marker_pat(line, add)
	if line:match(marker_ol) then
		line = line:match(marker_digit) + add .. "%.%s"
	elseif line:match(marker_ul) then
		line = "%" .. line:match(marker_md) .. "%s"
	end
	return line
end

local function neither_list(line)
	if (not line:match(marker_ol)) and (not line:match(marker_ul)) then
		return true
	end
	return false
end

local function set_cur(str)
	fn.setline(".", str)
	vim.cmd([[execute "normal! \<esc>A\<space>"]])
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
		set_cur(prev_line:match("^%s*") .. list_index + 1 .. ". ")
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
		fn.setline(".", (fn.getline("."):gsub("%d+", "1", 1)))
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

	-- no lists before so no need to renum
	if fn.line(".") == 1 then
		continue = false
	end

	if not continue then
		return
	end

	-- pattern matches
	local spc = "^%s*"

	local prev_line_ptr = fn.line(".") - 1
	local prev_line = fn.getline(prev_line_ptr)

	-- if prev line is a list entry
	if not neither_list(prev_line) then

		-- just a number
		local ptrline = prev_line_ptr

		local cur_line = fn.getline(".")
		local cur_indent = cur_line:match(spc)
		local cur_marker = get_marker_pat(cur_line, 0)

		local optimised = true
		if cur_marker:match(marker_md .. "%s") then
			optimised = false
		end
		-- optimised only works on ordered lists
		-- the list goes {1. x}\n{2. x}\n{3. x} so logically the last indent is
		-- before {1. x}, so searches for 3. and goes 3 lines before that.
		-- optimised doesn't work if bad md formatting as explained above
		if optimised then
			-- eval ptrline just gets the line that ptrline stores
			local eval_ptrline = fn.getline(ptrline)

			-- while the indents don't match
			while eval_ptrline:match(spc) ~= cur_indent do

				if not eval_ptrline:match(marker_ol) then
					-- can't use optimised cus either ul or not a list
					-- could be because of bad list formatting idk
					optimised = false
					break
				end

				ptrline = ptrline - eval_ptrline:match(marker_digit)
				-- explained above at the start of the if

				-- if ptrline out of bounds or eval_ptrline not a list entry
				if ptrline <= 0 then
					-- try using unoptimised search, skips setline function
					optimised = false
					break
				end
				eval_ptrline = fn.getline(ptrline)
				if neither_list(eval_ptrline) then
					optimised = false
					break
				end
			end

			-- found viable line
			if optimised then
				local new_marker = get_marker(fn.getline(ptrline), 1)

				-- some edge case where dedenting a numbered list
				-- adds a space behind it for some reason.
				-- cur marker is a pattern, and if it is an ordered list
				-- it would be the length of five. The new marker
				-- is a string, and would be length 2.
				if #cur_marker == 5 and #new_marker == 2 then
					cur_line = cur_line:sub(1, -2)
				end

				-- use current line and substitue the marker for indent marker
				fn.setline(".", (cur_line:gsub(cur_marker, new_marker, 1)))
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
			if #cur_marker == 5 and #new_marker == 2 then
				cur_line = cur_line:sub(1, -2)
			end
			set_cur(cur_line:gsub(cur_marker, new_marker, 1))
		end
	end
end


return M
