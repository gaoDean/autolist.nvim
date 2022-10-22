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

local function check_recal(func_name, force)
	if force == true or vim.tbl_contains(config.recal_function_hooks, func_name) then
		if config.recal_full then
			M.recal()
		else
			M.recal(utils.get_list_start(fn.line("."), get_lists()))
		end
	end
end

local function modify(prev, pattern)
	-- the brackets capture {pattern} and they release on %1
	local matched, nsubs = prev:gsub("^(%s*" .. pattern .. "%s).*$", "%1", 1)
	if nsubs == 0 then
		matched, nsubs = prev:gsub("^(%s*" .. pattern .. ")$", "%1", 1)
	end
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
		-- makes it think theres a list entry before current that was 0
		-- if it happens in the middle of the list, recal fixes it
		prev_line = utils.set_ordered_value(fn.getline(fn.line(".") + 1), 0)
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
				-- handle colons
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

function M.indent(direction)
	if utils.is_list(fn.getline("."), get_lists()) then
		if direction == ">>" then
			local ctrl_t = vim.api.nvim_replace_termcodes("<c-t>", true, true, true)
			vim.api.nvim_feedkeys(ctrl_t, "m", false)
		elseif direction == "<<" then
			local ctrl_d = vim.api.nvim_replace_termcodes("<c-d>", true, true, true)
			vim.api.nvim_feedkeys(ctrl_d, "m", false)
		else
			print("autolist: must provide a direction to indent")
		end
	else
		local tab = vim.api.nvim_replace_termcodes("<Tab>", true, true, true)
		vim.api.nvim_feedkeys(tab, "n", false)
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
		list_start_num = utils.get_list_start(fn.line("."), types)
		reset_list = 0
	end
	if not list_start_num then return end -- returns nil if not ordered list
	if reset_list then
		local next_num = list_start_num + reset_list
		local nxt = fn.getline(next_num)
		if utils.is_ordered(nxt) then
			fn.setline(next_num, utils.set_ordered_value(nxt, 1))
		end
	end
	local list_start = fn.getline(list_start_num)
	local list_indent = utils.get_indent_lvl(list_start)

	local target = utils.get_value_ordered(list_start) + 1 -- start plus one
	local linenum = list_start_num + 1
	local line = fn.getline(linenum)
	local line_indent = utils.get_indent_lvl(line)
	local prev_indent = -1

	while line_indent >= list_indent
		and linenum < list_start_num + config.list_cap
	do
		if utils.is_list(line, types) then
			if line_indent == list_indent then
				local val = utils.set_ordered_value(list_start, target)
				utils.set_line_marker(linenum, utils.get_marker(val, types), types, line:match(pat_checkbox))
				target = target + 1 -- only increase target if increased list
				prev_indent = -1 -- escaped the child list
			elseif line_indent ~= prev_indent -- small difference between var names
				and line_indent == list_indent + config.tabstop then
				-- this part recalculates a child list with recursion
				-- the prev_indent prevents it from recalculating multiple times.
				-- the first time this runs, linenum is the first entry in the list
				M.recal(linenum)
				prev_indent = line_indent -- so you don't repeat recalculate()
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
	local cur_linenum = fn.line(".")
	local types = get_lists()

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

	if utils.is_list(cur_line, types) then
		-- indent the line if current indent is zero
		if utils.get_indent_lvl(cur_line) == 0
			and config.invert.indent == true
		then
			fn.setline(".", config.tab .. cur_line)
		end
		-- if ul change to 1.
		if utils.is_ordered(cur_line) then
			-- utils.set_line_marker(cur_linenum, config.invert.ul_marker, types)
			utils.set_line_marker(utils.get_list_start(cur_linenum, types), config.invert.ul_marker, types)
		else
			-- if ol change to {config.invert.ol_incrementable}
			local new_marker = config.invert.ol_incrementable .. config.invert.ol_delim
			-- utils.set_line_marker(cur_linenum, new_marker, types)
			utils.set_line_marker(utils.get_list_start(cur_linenum, types), new_marker, types)
		end
		utils.reset_cursor_column(fn.col("$"))
	end
	check_recal("invert")
end

return M
