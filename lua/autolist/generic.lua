local config = require("autolist.config").generic

local M = {}

-- if you don't know regex, you should really learn it.
-- its actually more useful than you might think.

local fn = vim.fn
local pat_digit = "%d+"
local pat_md = "[-+*]"
local pat_check = "%[.%]"
local pat_ol = "^%s*%d+%.%s." -- ordered list
local pat_ul = "^%s*[-+*]%s." -- unordered list
local pat_checkbox = "^%s*%d*[-+*.]%s%[.%]%s."
local pat_ol_less = "^%s*%d+%.%s" -- ordered list
local pat_ul_less = "^%s*[-+*]%s" -- unordered list
local pat_checkbox_less = "^%s*%d*[-+*.]%s%[.%]%s"
local pat_checkbox_empty = "^%s*%d*[-+*.]%s%[%s%]%s" -- checkbox with nothing inside
local pat_indent = "^%s*"

-- an ordered list looks like:
-- 	1. content
-- 	2. content

-- an unordered list looks like:
-- 	- content
-- 	- content

-- a checkbox list looks like:
-- 	- [ ] content
-- 	- [x] content


-- gets the marker of {line} and if its a digit it adds {add}
local function get_marker(line)
	if line:match(pat_ol) then
		line = line:match(pat_digit) + 1 .. ". "
	elseif line:match(pat_ul) then
		-- the set of checkbox lists is a subset of the set of unordered lists
		line = line:match(pat_md) .. " "
	end
	return line
end

-- gets the pattern for the first argument to gsub
-- less is used because some markers are empty
local function get_marker_pat(line)
	if line:match(pat_ol_less) then
		line = "%d+%.%s"
	elseif line:match(pat_ul_less) then
		line = "[-+*]%s"
	end
	return line
end

-- returns true if {line} is not a markdown list
local function neither_list(line)
	if (not line:match(pat_ol_less)) and (not line:match(pat_ul_less)) then
		return true
	end
	return false
end

local function either_list(line)
	if line:match(pat_ol_less) or line:match(pat_ul_less) then
		return true
	end
	return false
end

local function set_cursor_col(relative_move)
	local pos = fn.getpos(".")
	-- pos[3] is the column pos
	pos[3] = pos[3] + relative_move
	fn.setpos(".", pos)
end

-- set current line to {str} and add a space at the end
local function set_cur(str)
	fn.setline(".", str)
	local pos = fn.getpos(".")
	pos[3] = fn.col("$")
	fn.setpos(".", pos)
end


-- increment ordered lists on enter
function M.list()
	local prev_line = fn.getline(fn.line(".") - 1)
	local newline
	if prev_line:match(pat_ul) then
		newline = prev_line:match(pat_ul_less)
	elseif prev_line:match(pat_ol) then
		local list_index = prev_line:match(pat_digit)
		newline = prev_line:match(pat_indent) .. list_index + 1 .. ". "
		waterfall(fn.line("."), 1)
	-- checks if list entry content is all spaces
	-- the ? acts on the %s in the pats, checking for one space then newline
	elseif prev_line:match(pat_ul_less .. "?$")
		or prev_line:match(pat_ol_less .. "?$")
		or prev_line:match(pat_checkbox_less .. "?$")
	then
		fn.setline(fn.line(".") - 1, "")
		fn.setline(".", "")
		return
	end
	if prev_line:match(pat_checkbox) then
		newline = newline .. "[ ] "
	end
	if newline then
		set_cur(newline)
	end
end

function M.reset()
	local prev_line = fn.getline(fn.line(".") - 1)
	if neither_list(prev_line) then return end
	-- reduce the number of the indent that the current line was on
	waterfall(fn.line("."), -1, fn.getline("."):gsub("%s", "", 1))
	-- if prev line is numbered, set current line number to 1
	waterfall(fn.line("."), 1)
	if prev_line:match(pat_ol) then
		fn.setline(".", (fn.getline("."):gsub(pat_digit, "1", 1)))
	end
	M.relist()
end

-- context aware renumbering/remarking
-- Important: if your markdown ordered lists are badly formatted e.g a one
-- followed by a three, the relist cant find the right list. most of the time
-- you'll have the correct formatting, and its not a big deal if you dont, the
-- program wont throw an error, you just wont get a relist.
function M.relist()
	local cur_line = fn.getline(".")
	if fn.line(".") <= 1 or neither_list(cur_line) then
		return
	end
	-- reduce the number of the indent that the current line was on
	waterfall(fn.line("."), -1, "\t" .. fn.getline("."))

	-- no line before current line so nothing to be context-aware of
	local ptrline = fn.line(".") - 1
	local cur_indent = cur_line:match(pat_indent)
	local cur_marker_pat = get_marker_pat(cur_line)
	local eval_ptrline = fn.getline(ptrline)
	local ptrline_indent = eval_ptrline:match(pat_indent)

	-- if indent less than current indent, thats out of scope
	while either_list(eval_ptrline)
		and #ptrline_indent >= #cur_indent
	do
		if #ptrline_indent == #cur_indent then
			cur_line = cur_line:gsub(cur_marker_pat, get_marker(eval_ptrline))
			print(cur_line)
			fn.setline(".", cur_line)

			-- random edge case in setlines
			-- ul -> ol results in cursor being one unit too far left
			-- ol -> ul results in cursor being one unit too far right
			if cur_marker_pat ~= get_marker_pat(eval_ptrline) then
				-- if before dedent marker is ul
				if cur_marker_pat:sub(1, 1) == "[" then
					set_cursor_col(1)
				-- in this case the marker is ol
				else
					set_cursor_col(-1)
				end
			end
			waterfall(fn.line("."), 1)
			return
		-- context optimisation is such a cool name for an option
		elseif eval_ptrline:match(pat_ol)
			and config.context_optim
		then
			-- this is when ptrline_indent > cur_indent
			ptrline = ptrline - eval_ptrline:match(pat_digit)
		else
			ptrline = ptrline - 1
		end
		-- do these at the end so it can check it at the start of the loop
		if ptrline <= 0 then
			return
		end
		eval_ptrline = fn.getline(ptrline)
		ptrline_indent = eval_ptrline:match(pat_indent)
	end
end

-- invert the list type: ol -> ul, ul -> ol
function M.invert()
	local cur_line = fn.getline(".")
	local cur_marker = get_marker_pat(cur_line)
	local new_marker

	-- if toggle checkbox true and is checkbox, toggle checkbox
	if config.invert_toggles_checkbox then
		if cur_line:match(pat_checkbox_empty) then
			new_marker = "[x]"
		-- it is a checkbox, but not empty
		elseif cur_line:match(pat_checkbox_less) then
			new_marker = "[ ]"
		end
		if new_marker:match(pat_check) then
			fn.setline(".", (cur_line:gsub(pat_check, new_marker)))
			return
		end
	end
	-- if ul change to 1.
	if cur_line:match(pat_ul_less) then
		new_marker = "1. "
		set_cursor_col(1)
	-- if ol change to {config.invert_ul_marker}
	elseif cur_line:match(pat_ol_less) then
		new_marker = config.invert_ul_marker .. " "
	end
	fn.setline(".", (cur_line:gsub(cur_marker, new_marker, 1)))
end

function M.unlist()
	if fn.line(".") == fn.line("$") then
		M.relist()
		return
	end
	-- the last deleted line gets stored in register 1
	-- https://www.brianstorti.com/vim-registers/
	-- we need this line to get the indent
	local prev_deleted = fn.getreg("1")
	if prev_deleted:match(pat_ol) then
		waterfall(fn.line(".") - 1, -1, prev_deleted)
	end
end

return M

-- just some random things that are used:
-- comments are put either inline or above the code
-- string:gsub(pat, repl, n) where:
-- 		pat is a lua pattern
-- 		repl is a string, except %x where x is a digit means special thing
--		n is an int that means how many occurences of pat is replaced
