local utils = require("autolist.utils")
local config = require("autolist.config")

local fn = vim.fn
local pat_checkbox = "^%s*%S+%s%[.%]"

local M = {}

local function modify(prev, pattern)
	-- the brackets capture {pattern} and they release on %1
	local matched, nsubs = prev:gsub("^%s*(" .. pattern .. "%s?).*$", "%1", 1)
	if matched == prev or not matched then
		if nsubs > 0 then
			return 1
		else
			return nil
		end
	end
	return utils.increment(matched)
end

function M.new()
	if fn.line(".") <= 0 then return end
	local prev_line = fn.getline(fn.line(".") - 1)

	-- no lists have two letters at the start, at least for now
	if prev_line:sub(1, 2):match("%a%a") then return end

	local matched = false

	-- ipairs is used to optimise list_types (most used checked first)
	for _, pat in ipairs(config.list_types) do
		local modded = modify(prev_line, pat)
		-- if its not true and nil
		if modded == 1 then
			-- it was a list, only it was empty
			matched = true
		elseif modded then
			-- sets current line and puts cursor to end
			if prev_line:match(pat_checkbox) then
				modded = modded .. "[ ] "
				-- if the prev was checkbox and had no content
				if prev_line:match(pat_checkbox .. "%s?$") then
					matched = true
					break
				end
			end
			utils.set_current_line(modded)
			return
		end
	end
	if matched then
		fn.setline(fn.line(".") - 1, "")
	end
end

-- called it waterfall because the ordered list entries after {ptrline}
-- that belongs to the same list has {rise} added to it.
function M.waterfall(ptrline, rise, override_indent)
	local cur_indent_lvl
	if override_indent then
		cur_indent_lvl = override_indent
	else
		cur_indent_lvl = utils.get_indent_lvl(fn.getline(ptrline))
	end
	-- waterfall only needs to affect after current line
	ptrline = ptrline + 1
	local eval_ptrline = fn.getline(ptrline)
	local val = utils.is_ordered(eval_ptrline, rise, config.list_types)
	local ptr_indent_lvl = utils.get_indent_lvl(eval_ptrline)

	-- waterfall only acts on ordered lists
	-- if its smaller than current indent, the list is "out of scope"
	-- it can be bigger because it could be unordered but parent list ordered

	-- loop through lines in current list and incement/decrement ordered lists
	while ptr_indent_lvl > cur_indent_lvl
		or val ~= nil
	do
		-- a stricter check
		if ptr_indent_lvl == cur_indent_lvl
			and val ~= nil
		then
			-- if val isn't nil, it has a value that was increment/decrement
			fn.setline(ptrline, val)
		end
		ptrline = ptrline + 1
		if ptrline > fn.line('$') then
			return
		end
		eval_ptrline = fn.getline(ptrline)
		val = utils.is_ordered(eval_ptrline, config.list_types)
		ptr_indent_lvl = utils.get_indent_lvl(eval_ptrline)
	end
end

function M.relist(prev_indent)
	local cur_line = fn.getline(".")
	local cur_linenum = fn.line(".")
	if cur_linenum <= 1
		or utils.not_list(cur_line, config.list_types)
	then
		return
	end
	-- reduce the number of the indent that the current line was on
	waterfall(cur_linenum, -1, prev_indent)

	-- is_list returns the pattern as the second value
	local _, cur_marker_pat = utils.is_list(cur_line, config.list_types)
	local cur_indent = utils.get_indent_lvl(cur_line)

	local linenum = cur_linenum - 1
	local line = fn.getline(linenum)
	local line_indent = utils.get_indent_lvl(line)
	-- returns the marker as the third value
	local _, _, line_marker = utils.is_list(line, config.list_types)

	-- if indent less than current indent, thats out of scope
	while line_marker
		and line_indent >= cur_indent
	do
		if line_indent == cur_indent then
			cur_line = cur_line:gsub(cur_marker_pat, line_marker, 1)
			fn.setline(".", cur_line)
			-- edge case
			-- if cur_marker_pat ~= line_marker then
			-- 	-- if before dedent marker is ul
			-- 	if cur_marker_pat:sub(1, 1) == "[" then
			-- 		set_cursor_col(1)
			-- 	-- in this case the marker is ol
			-- 	else
			-- 		set_cursor_col(-1)
			-- 	end
			-- end
			waterfall(fn.line("."), 1)
			return
		-- context optimisation is such a cool name for an option
		elseif utils.is_ordered(line)
			and config.context_optim
		then
			-- this is when ptrline_indent > cur_indent
			linenum = linenum - utils.get_value_ordered(line)
		else
			linenum = linenum - 1
		end
		-- do these at the end so it can check it at the start of the loop
		if linenum <= 0 then
			return
		end
		line = fn.getline(linenum)
		line_indent = utils.get_indent_lvl(line)
		_, _, line_marker = utils.is_list(line, config.list_types)
	end
end

function M.recalculate()

end


return M
