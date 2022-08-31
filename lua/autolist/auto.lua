local utils = require("autolist.utils")
local config = require("autolist.config")

local fn = vim.fn
local pat_checkbox = "^%s*%S+%s%[.%]"

local M = {}

local function modify(prev, pattern)
	-- the brackets capture {pattern} and they release on %1
	local matched, nsubs = prev:gsub("^%s*(" .. pattern .. "%s?).*$", "%1", 1)
	if matched == prev or not matched then
		-- if replaced smth
		if nsubs == 1 then
			return "$"
		else
			return ""
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
	for i, v in ipairs(config.list_types) do
		local modded = modify(prev_line, v)
		-- if its not true and nil
		if modded == "$" then
			-- it was a list, only it was empty
			matched = true
		elseif modded ~= "" then
			-- sets current line and puts cursor to end
			if prev_line:match(pat_checkbox) then
				modded = modded .. "[ ] "
				-- if the prev was checkbox and had no content
				if prev_line:match(pat_checkbox .. "%s?$") then
					matched = true
					break
				end
			end
			utils.set_current_line(modded .. fn.getline("."))
			return
		end
	end
	if matched then
		fn.setline(fn.line(".") - 1, "")
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
	local list_start_num = fn.line(".")
	local list_start = fn.getline(list_start_num)
	local list_indent = utils.get_indent_lvl(list_start)

	-- set first entry to one, returns false if fails (not ordered)
	if not utils.set_value_ordered(list_start_num, list_start, 1) then return end

	local target = 2 -- start plus one
	local linenum = list_start_num + 1
	local line = fn.getline(linenum)
	local lineval = utils.get_value_ordered(line)
	local line_indent = utils.get_indent_lvl(line)
	while is_ordered(line)
		and line_indent >= list_indent
	do
		if line_indent == list_indent then
			-- you set like 50 every time you press j, a few more cant hurt, right?
			if not utils.set_value_ordered(linenum, line, target) then return end
			-- only increase target if increased list
			target = target + 1
		end
		-- do these at the end so it can check it at the start of the loop
		linenum = linenum + 1
		line = fn.getline(linenum)
		lineval = utils.get_value_ordered(line)
		line_indent = utils.get_indent_lvl(line)
	end
end

return M
