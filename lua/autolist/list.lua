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
local pat_ol_less = "^%s*%d+%.%s" -- ordered list
local pat_ul_less = "^%s*[-+*]%s" -- unordered list
local pat_indent = "^%s*"

-- called it waterfall because the ordered list entries after {ptrline}
-- that belongs to the same list has {rise} added to it.
local function waterfall(ptrline, rise)
	if ptrline >= fn.line('$') then
		return
	end
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
local function get_marker(line)
	if line:match(pat_ol) then
		line = line:match(pat_digit) + 1 .. ". "
	elseif line:match(pat_ul) then
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
	if fn.line(".") <= 1 then
		return
	end

	local ptrline = fn.line(".") - 1
	local cur_line = fn.getline(".")
	local cur_indent = cur_line:match(pat_indent)
	local cur_marker_pat = get_marker_pat(cur_line)

	local eval_ptrline = fn.getline(ptrline)
	local ptrline_indent = eval_ptrline:match(pat_indent)

	while either_list(eval_ptrline) and ptrline_indent >= cur_indent do
		if ptrline_indent == cur_indent then
			cur_line = cur_line:gsub(cur_marker_pat, get_marker(eval_ptrline))
			fn.setline(".", cur_line)
			return
		-- this is when ptrline_indent > cur_indent
		-- elseif eval_ptrline:match(pat_ol) then
		-- 	ptrline = ptrline - eval_ptrline:match(pat_digit)
		else
			ptrline = ptrline - 1
		end
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
