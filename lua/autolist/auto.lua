local utils = require("autolist.utils")
local config = require("autolist.config")

local fn = vim.fn
local pat_checkbox = "^%s*%S+%s%[.%]"
local checkbox_filled_pat = config.checkbox_left .. config.checkbox_fill .. config.checkbox_right
local checkbox_empty_pat = config.checkbox_left .. " " .. config.checkbox_right
-- filter_pat() removes the % signs
local checkbox_filled = utils.filter_pat(checkbox_filled_pat)
local checkbox_empty = utils.filter_pat(checkbox_empty_pat)

local M = {}

local function checkbox_is_filled(line)
	if line:match(checkbox_filled_pat) then
		return true
	elseif line:match(checkbox_empty_pat) then
		return false
	end
	return nil
end

local function check_recal(func_name)
	if utils.table_contains(config.recal_hooks, func_name) then
		M.recal()
	end
end

local function modify(prev, pattern)
	-- the brackets capture {pattern} and they release on %1
	local matched, nsubs = prev:gsub("^(%s*" .. pattern .. "%s?).*$", "%1", 1)
	-- trim off spaces
	if utils.trim_end(matched) == utils.trim_end(prev) then
		-- if replaced smth
		if nsubs == 1 then
			-- filler return value
			return "$"
		else
			return ""
		end
	end
	return utils.ordered_add(matched, 1)
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
				modded = modded .. checkbox_empty .. " "
				-- if the prev was checkbox and had no content
				if prev_line:match(pat_checkbox .. "%s?$") then
					matched = true
					break
				end
			end
			local cur_line = fn.getline(".")
			utils.set_current_line(modded .. cur_line:gsub("^%s*", "", 1))
			check_recal("new")
			return
		end
	end
	if matched then
		fn.setline(fn.line(".") - 1, "")
		utils.reset_cursor_column()
	end
end

-- recalculates the current list scope
function M.recal(override_start_num)
	local list_start_num
	if override_start_num then
		list_start_num = utils.get_list_start(override_start_num)
	else
		list_start_num = utils.get_list_start(fn.line("."))
	end
	if not list_start_num then return end -- returns nil if not ordered list
	local list_start = fn.getline(list_start_num)
	local list_indent = utils.get_indent_lvl(list_start)

	-- set first entry to one, returns false if fails (not ordered)
	if not utils.set_value_ordered(list_start_num, list_start, 1) then
		return
	end

	local target = 2 -- start plus one
	local linenum = list_start_num + 1
	local line = fn.getline(linenum)
	local lineval = utils.get_value_ordered(line)
	local line_indent = utils.get_indent_lvl(line)
	local nextline = fn.getline(linenum + 1)
	local done = -1
	while line_indent >= list_indent
		and linenum < list_start_num + 100
	do
		if line_indent == list_indent then
			if utils.is_ordered(line) then
				-- you set like 50 every time you press j, a few more cant hurt, right?
				-- btw this calls set_value_ordered
				if not utils.set_value_ordered(linenum, line, target) then
					return
				end
				-- only increase target if increased list
				target = target + 1
			else
				-- same indent and isnt ordered
				return
			end
		elseif utils.is_ordered(nextline)
			and line_indent ~= done
			and utils.get_indent_lvl(nextline) == line_indent
		then
			local new_indent = utils.get_indent_lvl(line)
			-- the first time this runs, linenum is the first entry in the list
			M.recal(linenum)
			done = new_indent -- so you don't repeat recalculate()
		end
		-- do these at the end so it can check it at the start of the loop
		linenum = linenum + 1
		line = fn.getline(linenum)
		lineval = utils.get_value_ordered(line)
		line_indent = utils.get_indent_lvl(line)
		nextline = fn.getline(linenum + 1)
	end
end

function M.invert()
	local cur_line = fn.getline(".")

	-- if toggle checkbox true and is checkbox, toggle checkbox
	if config.invert_toggles_checkbox then
		-- returns nil if not a checkbox
		local filled = checkbox_is_filled(cur_line)
		if filled == true then
			-- replace current line's empty checkbox with filled checkbox
			fn.setline(".", (cur_line:gsub(checkbox_filled_pat, checkbox_empty)))
			check_recal("invert")
			return
		-- it is a checkbox, but not empty
		elseif filled == false then
			-- replace current line's filled checkbox with empty checkbox
			fn.setline(".", (cur_line:gsub(checkbox_empty_pat, checkbox_filled)))
			check_recal("invert")
			return
		end
	end

	local list, cur_marker_pat = utils.is_list(cur_line, config.list_types)
	if list then
		-- if ul change to 1.
		if utils.is_ordered(cur_line) then
			utils.set_current_line(cur_line:gsub(cur_marker_pat, config.invert_ul_marker, 1))
		else
			-- if ol change to {config.invert_ul_marker}
			local new_marker = config.invert_ol_incrementable .. config.invert_ol_delim
			utils.set_current_line(cur_line:gsub(cur_marker_pat, new_marker, 1))
		end
	end
	check_recal("invert")
end

return M
