-- just some random things that are used:
-- comments are put either inline or above the code
-- string:gsub(pat, repl, n) where:
-- 		pat is a lua pattern
-- 		repl is a string, except %x where x is a digit means special thing
--		n is an int that means how many occurences of pat is replaced

local config = require("autolist.config")

local M = {}

local fn = vim.fn
local pat_digit = "%d+"
local pat_md = "[-+*]"
local pat_ol = "^%s*%d+%.%s." -- ordered list
local pat_ul = "^%s*[-+*]%s." -- unordered list
local pat_indent = "^%s*"

-- called it waterfall because the ordered list entries after {ptrline}
-- that belongs to the same list has {rise} added to it.
local function waterfall(ptrline, rise)
	local cur_indent = fn.getline(ptrline - 1):match(pat_indent)
	local eval_ptrline = fn.getline(ptrline)
	-- while the list is ongoing
	while eval_ptrline:match(pat_ol) or eval_ptrline:match(pat_indent) > cur_indent do
		if eval_ptrline:match(pat_indent) == cur_indent and eval_ptrline:match(pat_ol) then
			-- set ptrline's digit to itself, plus rise
			local line_digit = eval_ptrline:match(pat_digit)
			fn.setline(ptrline, (eval_ptrline:gsub(pat_digit, line_digit + rise, 1)))
		end
		ptrline = ptrline + 1
		if ptrline > fn.line('$') then
			return
		end
		eval_ptrline = fn.getline(ptrline)
	end
end

-- gets the marker of {line} and if its a digit it adds {add}
local function get_marker(line, add)
	if line:match(pat_ol) then
		line = line:match(pat_digit) + add .. ". "
	elseif line:match(pat_ul) then
		line = line:match(pat_md) .. " "
	end
	return line
end

-- gets the pattern for the first argument to gsub
local function get_marker_pat(line, add)
	if line:match(pat_ol) then
		line = line:match(pat_digit) + add .. "%.%s"
	elseif line:match(pat_ul) then
		line = "%" .. line:match(pat_md) .. "%s"
	end
	return line
end

-- returns true if {line} is not a markdown list
local function neither_list(line)
	if (not line:match(pat_ol)) and (not line:match(pat_ul)) then
		return true
	end
	return false
end

local function either_list(line)
	if line:match(pat_ol) or line:match(pat_ul) then
		return true
	end
	return false
end

-- set current line to {str} and add a space at the end
local function set_cur(str)
	fn.setline(".", str)
	vim.cmd([[execute "normal! \<esc>A\<space>"]])
end

-- increment ordered lists on enter
function M.list()
	local prev_line = fn.getline(fn.line(".") - 1)
	if prev_line:match("^%s*%d+%.%s.") then
		local list_index = prev_line:match("%d+")
		set_cur(prev_line:match("^%s*") .. list_index + 1 .. ". ")
		waterfall(fn.line(".") + 1)
	-- checks if list entry is empty and clears the line
	elseif prev_line:match("^%s*[-+*]%s?$") or prev_line:match("^%s*%d+%.%s?$") then
		fn.setline(fn.line(".") - 1, "")
		fn.setline(".", "")
	end
end

function M.reset()
	-- if prev line is numbered, set current line number to 1
	local prev_line = fn.getline(fn.line(".") - 1)
	if prev_line:match(pat_ol) then
		fn.setline(".", (fn.getline("."):gsub(pat_digit, "1", 1)))
	end
end

-- context aware renumbering/remarking
function M.relist()
	-- no lists before so no need to renum
	if fn.line(".") == 1 then
		return
	end

	local prev_line_ptr = fn.line(".") - 1
	local prev_line = fn.getline(prev_line_ptr)

	-- if prev line is a list entry
	if either_list(prev_line) then
		local ptrline = prev_line_ptr

		local cur_line = fn.getline(".")
		local cur_indent = cur_line:match(pat_indent)
		local cur_marker = get_marker_pat(cur_line, 0)

		local optimised = true
		if cur_marker:match(pat_md .. "%s") then
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
			while eval_ptrline:match(pat_indent) ~= cur_indent do

				-- can't use optimised because cus either ul or not a list
				if not eval_ptrline:match(pat_ol) then
					optimised = false
					break
				end

				-- explained above at the start of the if
				ptrline = ptrline - eval_ptrline:match(pat_digit)

				-- if ptrline out of bounds or eval_ptrline not a list entry
				-- try using unoptimised search, skips setline function
				if ptrline <= 0 then
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
			while fn.getline(ptrline):match(pat_indent) ~= cur_indent do
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

-- invert the list type: ol -> ul, ul -> ol
function M.invert()
	local cur_line = fn.getline(".")
	local cur_marker = get_marker_pat(cur_line, 0)

	-- if ul change to 1.
	if cur_line:match("^%s*[-+*]%s") then
		local new_marker = "1. "
		set_cur(cur_line:gsub(pat_md .. "%s", new_marker, 1))
	-- if ol change to {config.invert_preferred_ul_marker}
	elseif cur_line:match("^%s*%d+%.%s") then
		local new_marker = config.invert_preferred_ul_marker
		set_cur(cur_line:gsub(cur_marker, new_marker, 1))
	end
end

function M.unlist()
	waterfall(fn.line("."), -1)
end

return M
