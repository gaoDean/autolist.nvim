local utils = require("autolist.utils")
local config = require("autolist.config")

local fn = vim.fn
local pat_checkbox = "^%s*%S+%s%[.%]"
local pat_colon = ":%s*$"
local checkbox_filled_pat = config.checkbox.left
	.. config.checkbox.fill
	.. config.checkbox.right
local checkbox_empty_pat = config.checkbox.left .. " " .. config.checkbox.right
-- filter_pat() removes the % signs
local checkbox_filled = utils.get_percent_filtered(checkbox_filled_pat)
local checkbox_empty = utils.get_percent_filtered(checkbox_empty_pat)

local new_before_pressed = false
local next_keypress = ""
local edit_mode = "n"

local M = {}

local function press(key, mode)
	if not key or key == "" then return end
	local parsed_key = vim.api.nvim_replace_termcodes(key, true, true, true)
	if mode == "i" then
		vim.cmd.normal({ "a" .. parsed_key, bang = true })
	else
		vim.cmd.normal({ parsed_key, bang = true })
	end
end

-- returns the correct lists for the current filetype
local function get_lists()
	-- each table in filetype lists has the key of a filetype
	-- each value has the tables (of lists) that it is assigned to
	return config.lists[vim.bo.filetype]
end

local function checkbox_is_filled(line)
	if line:match(checkbox_filled_pat) then
		return true
	elseif line:match(checkbox_empty_pat) then
		return false
	end
	return nil
end

-- recalculates the current list scope
local function recal(override_start_num, reset_list)
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

	while
		line_indent >= list_indent
		and linenum < list_start_num + config.list_cap
	do
		if utils.is_list(line, types) then
			if line_indent == list_indent then
				local val = utils.set_ordered_value(list_start, target)
				utils.set_line_marker(
					linenum,
					utils.get_marker(val, types),
					types,
					line:match(pat_checkbox)
				)
				target = target + 1 -- only increase target if increased list
				prev_indent = -1 -- escaped the child list
			elseif
				line_indent ~= prev_indent -- small difference between var names
				and line_indent == list_indent + config.tabstop
			then
				-- this part recalculates a child list with recursion
				-- the prev_indent prevents it from recalculating multiple times.
				-- the first time this runs, linenum is the first entry in the list
				recal(linenum)
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

local function check_recal(force)
	if config.recal_full then
		recal()
	else
		recal(utils.get_list_start(fn.line("."), get_lists()))
	end
end

local function modify(prev, pattern)
	-- the brackets capture {pattern} and they release on %1
	local matched, nsubs = prev:gsub("^(%s*" .. pattern .. "%s).*$", "%1", 1)
	if nsubs == 0 then
		matched, nsubs = prev:gsub("^(%s*" .. pattern .. ")$", "%1", 1)
	end
	-- trim off spaces
	if
		utils.get_whitespace_trimmed(matched)
		== utils.get_whitespace_trimmed(prev)
	then
		-- if replaced smth
		if nsubs == 1 then
			-- filler return value
			return { replaced = true }
		else
			return { replaced = false }
		end
	end
	return utils.get_ordered_add(matched, 1)
end

function M.new_before(motion, mapping)
	new_before_pressed = true
	return M.new(motion, mapping)
end

function M.new(motion, mapping)
	if motion == nil then
		next_keypress = mapping
		vim.o.operatorfunc = "v:lua.require'autolist'.new"
		edit_mode = vim.api.nvim_get_mode().mode
		return "<esc>g@la"
	end

	press(next_keypress, edit_mode)

	local filetype_lists = get_lists()
	if not filetype_lists then -- this filetype is disabled
		return
	end

	if fn.line(".") <= 0 then return end
	local prev_line = fn.getline(fn.line(".") - 1)
	if
		new_before_pressed
		and fn.line(".") + 1
			== utils.get_list_start(fn.line("."), filetype_lists)
	then
		-- makes it think theres a list entry before current that was 0
		-- if it happens in the middle of the list, recal fixes it
		prev_line = utils.set_ordered_value(fn.getline(fn.line(".") + 1), 0)
	end

	if not utils.is_list(prev_line, filetype_lists) then return end

	local matched = false

	-- ipairs is used to optimise list_types (most used checked first)
	for i, v in ipairs(filetype_lists) do
		local modded = modify(prev_line, v)
		-- if its not true and nil
		if modded.replaced then
			-- it was a list, only it was empty
			matched = true
		elseif modded.replaced ~= false then
			-- sets current line and puts cursor to end
			if prev_line:match(pat_checkbox) then
				modded = modded .. checkbox_empty .. " "
				-- if the prev was checkbox and had no content
				if prev_line:match(pat_checkbox .. "%s?$") then
					matched = true
					break
				end
			elseif
				not new_before_pressed
				and config.colon.indent
				and prev_line:match(pat_colon)
			then
				-- handle colons
				if config.colon.preferred ~= "" then
					modded = modded:gsub("^(%s*).*", "%1", 1)
						.. config.colon.preferred
						.. " "
				end
				modded = config.tab .. modded
				new_before_pressed = true -- just to recal
			end
			local cur_line = fn.getline(".")
			utils.set_current_line(modded .. cur_line:gsub("^%s*", "", 1))
			check_recal(new_before_pressed)
			new_before_pressed = false
			return
		end
	end
	if matched then
		fn.setline(fn.line(".") - 1, "")
		utils.reset_cursor_column()
		new_before_pressed = false
		return
	end
	if config.colon.indent_raw and prev_line:match(pat_colon) then
		utils.set_current_line(
			config.colon.preferred .. " " .. fn.getline("."):gsub("^%s*", "", 1)
		)
	end
	new_before_pressed = false
end

function M.indent(motion, mapping)
	if motion == nil then
		next_keypress = mapping
		if string.lower(mapping) == "<tab>" then
			local cur_line = fn.getline(".")
			if
				utils.is_list(cur_line, get_lists())
				and fn.getpos(".")[3] - 1 == string.len(cur_line) -- cursor on last char of line
			then
				next_keypress = "<c-t>"
			end
		end
		vim.o.operatorfunc = "v:lua.require'autolist'.indent"
		edit_mode = vim.api.nvim_get_mode().mode
		if edit_mode == "i" then return "<esc>g@la" end
		return "g@l"
	end

	press(next_keypress, edit_mode)

	local filetype_lists = get_lists()
	if not filetype_lists then -- this filetype is disabled
		return
	end

	if utils.is_list(fn.getline("."), get_lists()) then recal() end
end

function M.force_recalculate(motion, mapping)
	if motion == nil then
		next_keypress = mapping
		vim.o.operatorfunc = "v:lua.require'autolist'.force_recalculate"
		edit_mode = vim.api.nvim_get_mode().mode
		if edit_mode == "i" then return "<esc>g@la" end
		return "g@l"
	end

	press(next_keypress, edit_mode)

	local filetype_lists = get_lists()
	if not filetype_lists then -- this filetype is disabled
		return
	end

	recal()
end

local function invert()
	local cur_line = fn.getline(".")
	local cur_linenum = fn.line(".")
	local types = get_lists()

	-- if toggle checkbox true and is checkbox, toggle checkbox
	if config.invert.toggles_checkbox then
		-- returns nil if not a checkbox
		local filled = checkbox_is_filled(cur_line)
		if filled == true then
			-- replace current line's empty checkbox with filled checkbox
			fn.setline(
				".",
				(cur_line:gsub(checkbox_filled_pat, checkbox_empty, 1))
			)
			return
		-- it is a checkbox, but not empty
		elseif filled == false then
			-- replace current line's filled checkbox with empty checkbox
			fn.setline(
				".",
				(cur_line:gsub(checkbox_empty_pat, checkbox_filled, 1))
			)
			return
		end
	end

	if utils.is_list(cur_line, types) then
		-- indent the line if current indent is zero
		if
			utils.get_indent_lvl(cur_line) == 0
			and config.invert.indent == true
		then
			fn.setline(".", config.tab .. cur_line)
		end
		-- if ul change to 1.
		if utils.is_ordered(cur_line) then
			-- utils.set_line_marker(cur_linenum, config.invert.ul_marker, types)
			utils.set_line_marker(
				utils.get_list_start(cur_linenum, types),
				config.invert.ul_marker,
				types
			)
		else
			-- if ol change to {config.invert.ol_incrementable}
			local new_marker = config.invert.ol_incrementable
				.. config.invert.ol_delim
			-- utils.set_line_marker(cur_linenum, new_marker, types)
			utils.set_line_marker(
				utils.get_list_start(cur_linenum, types),
				new_marker,
				types
			)
		end
		utils.reset_cursor_column(fn.col("$"))
	end
	check_recal()
end

function M.invert_entry(motion, mapping)
	if motion == nil then
		next_keypress = mapping
		vim.o.operatorfunc = "v:lua.require'autolist'.invert_entry"
		edit_mode = vim.api.nvim_get_mode().mode
		if edit_mode == "i" then return "<esc>g@la" end
		return "g@l"
	end

	press(next_keypress, edit_mode)

	local filetype_lists = get_lists()
	if not filetype_lists then -- this filetype is disabled
		return
	end

	invert()

	-- -- it doubles up, doesn't work just yet
	-- local range = {
	--	 starting = unpack(vim.api.nvim_buf_get_mark(0, "[")),
	--	 ending = unpack(vim.api.nvim_buf_get_mark(0, "]")),
	-- }

	-- if motion == "char" then
	--	 invert()
	--	 return
	-- end

	-- for linenum = range.starting, range.ending, 1 do
	--	 utils.set_line_number(linenum)
	--	 invert()
	-- end
end

return M
