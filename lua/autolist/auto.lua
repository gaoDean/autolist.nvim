local utils = require("autolist.utils")
local config = require("autolist.config")

local fn = vim.fn
local pat_checkbox = "^%s*%S+%s%[.%]"
local pat_colon = ":%s*$"
local checkbox_filled_pat = config.checkbox.left .. config.checkbox.fill .. config.checkbox.right
local checkbox_empty_pat = config.checkbox.left .. " " .. config.checkbox.right
-- filter_pat() removes the % signs
local checkbox_filled = utils.get_percent_filtered(checkbox_filled_pat)
local checkbox_empty = utils.get_percent_filtered(checkbox_empty_pat)

local M = {}

-- returns the correct lists for the current filetype
local function get_lists()
	-- each table in filetype lists has the key of a filetype
	-- each value has the tables (of lists) that it is assigned to
	return config.ft_lists[vim.bo.filetype]
end

local function checkbox_is_filled(line)
	if line:match(checkbox_filled_pat) then
		return true
	elseif line:match(checkbox_empty_pat) then
		return false
	end
	return nil
end

local function check_recal(func_name, extra)
	if extra == true or utils.does_table_contain(config.recal_hooks, func_name) then
		if config.recal_full then
			M.recal()
		else
			M.recal(utils.get_list_start(fn.line("."), get_lists()))
		end
	end
end

local function modify(prev, pattern)
	-- the brackets capture {pattern} and they release on %1
	local matched, nsubs = prev:gsub("^(%s*" .. pattern .. "%s?).*$", "%1", 1)
	-- trim off spaces
	if utils.get_whitespace_trimmed(matched) == utils.get_whitespace_trimmed(prev) then
		-- if replaced smth
		if nsubs == 1 then
			-- filler return value
			return "$"
		else
			return ""
		end
	end
	return utils.get_ordered_add(matched, 1)
end

function M.new(O_pressed)
	if fn.line(".") <= 0 then return end
	local prev_line = fn.getline(fn.line(".") - 1)
	local filetype_lists = get_lists()
	if O_pressed and fn.line(".") + 1 == utils.get_list_start(fn.line("."), filetype_lists) then
		prev_line = fn.getline(fn.line(".") + 1)
	end

	local matched = false

	-- ipairs is used to optimise list_types (most used checked first)
	for i, v in ipairs(filetype_lists) do
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
			elseif not O_pressed
				and config.colon.indent
				and prev_line:match(pat_colon)
			then
				if config.colon.preferred ~= "" then
					modded = modded:gsub("^(%s*).*", "%1", 1) .. config.colon.preferred .. " "
				end
				modded = config.tab .. modded
				O_pressed = true -- just to recal
			end
			local cur_line = fn.getline(".")
			utils.set_current_line(modded .. cur_line:gsub("^%s*", "", 1))
			check_recal("new", O_pressed)
			return
		end
	end
	if matched then
		fn.setline(fn.line(".") - 1, "")
		utils.reset_cursor_column()
		return
	end
	if not before
		and config.colon.indent_raw
		and prev_line:match(pat_colon)
	then
		utils.set_current_line(config.colon.preferred .. " " .. fn.getline("."):gsub("^%s*", "", 1))
	end
end

function M.tab()
	-- recalculate part of the parent list
	if utils.is_list(fn.getline("."), get_lists()) then
		-- recalculate starting from the parent list
		M.recal(utils.get_list_start(fn.line("."), get_lists()) - 1, 1)
	end
end

function M.detab()
	if utils.is_list(fn.getline("."), get_lists()) then
		M.recal()
	end
end

-- recalculates the current list scope
function M.recal(override_start_num, reset_list)
	-- the var base names: list and line
	-- x is the actual line (fn.getline)
	-- x_num is the line number (fn.line)
	-- x_indent is the indent of the line (utils.get_indent_lvl)

	local types = get_lists()
	local list_start_num
	if override_start_num then
		list_start_num = override_start_num
	else
		list_start_num = utils.get_list_start(fn.line("."), get_lists())
		reset_list = 0
	end
	if reset_list then
		local nxt = list_start_num + reset_list
		fn.setline(nxt, utils.set_ordered_value(fn.getline(nxt), 1))
	end
	if not list_start_num then return end -- returns nil if not ordered list
	local list_start = fn.getline(list_start_num)
	local list_indent = utils.get_indent_lvl(list_start)

	local target = utils.get_value_ordered(list_start) + 1 -- start plus one
				print(target)
	local linenum = list_start_num + 1
	local line = fn.getline(linenum)
	local line_indent = utils.get_indent_lvl(line)
	local last_indent = -1

	while line_indent >= list_indent
		and linenum < list_start_num + config.list_cap
	do
		if utils.is_list(line, get_lists()) then
			if line_indent == list_indent then
				local val = utils.set_ordered_value(list_start, target)
				if marker then
					utils.set_line_marker(linenum, utils.get_marker(val, get_lists()), get_lists())
					-- only increase target if increased list
					target = target + 1
					-- escaped the child list
					last_indent = -1
				end
			elseif line_indent == list_indent + select(2, utils.get_tab_value()) then
				-- this part recalculates a child list with recursion
				-- get_tab_value() returns the amount as the second value
				-- the last_indent prevents it from recalculating multiple times.
				-- the first time this runs, linenum is the first entry in the list
				M.recal(linenum)
				-- so you don't repeat recalculate()
				last_indent = line_indent
				print(last_indent)
			end
		else
			return
		end
		-- do these at the end so it can check it at the start of the loop
		linenum = linenum + 1
		line = fn.getline(linenum)
		line_indent = utils.get_indent_lvl(line)
	end
end

function M.invert()
	local cur_line = fn.getline(".")

	-- if toggle checkbox true and is checkbox, toggle checkbox
	if config.invert.toggles_checkbox then
		-- returns nil if not a checkbox
		local filled = checkbox_is_filled(cur_line)
		if filled == true then
			-- replace current line's empty checkbox with filled checkbox
			fn.setline(".", (cur_line:gsub(checkbox_filled_pat, checkbox_empty, 1)))
			check_recal("invert")
			return
		-- it is a checkbox, but not empty
		elseif filled == false then
			-- replace current line's filled checkbox with empty checkbox
			fn.setline(".", (cur_line:gsub(checkbox_empty_pat, checkbox_filled, 1)))
			check_recal("invert")
			return
		end
	end

	local list, cur_marker_pat = utils.is_list(cur_line, get_lists())
	if list then
		-- if ul change to 1.
		if utils.is_ordered(cur_line) then
			utils.set_current_line(cur_line:gsub(cur_marker_pat, config.invert.ul_marker, 1))
		else
			-- if ol change to {config.invert.ul_marker}
			local new_marker = config.invert.ol_incrementable .. config.invert.ol_delim
			utils.set_current_line(cur_line:gsub(cur_marker_pat, new_marker, 1))
		end
	end
	check_recal("invert")
end


-- TODO
-- replace utils.get_tab_value with a config option

return M
