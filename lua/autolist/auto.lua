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
	return M.new(motion, mapping, true)
end

local function get_bullet_from(line, pattern)
    local matched_bare = line:match("^%s*"
                                    .. pattern
                                    .. "%s*") -- only bullet, no checkbox
    local matched_with_checkbox = line:match("^(%s*"
                                             .. pattern
                                             .. "%s*"
                                             .. "%[.%]"
                                             .. "%s*") -- bullet and checkbox

    return matched_with_checkbox or matched_bare
end

local function is_in_code_fence()
    -- check if Treesitter parser is installed, and if so, check if we're in a markdown code fence
    local parser = require('autolist.treesitter')
        :new(vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win())
    return parser and parser:is_in_markdown_code_fence()
end

local function find_suitable_bullet(line, filetype_lists, del_above)
	-- ipairs is used to optimise list_types (most used checked first)
	for i, filetype_specific_pattern in ipairs(filetype_lists) do
        local bullet = get_bullet_from(line, filetype_specific_pattern)

        if bullet then
            if string.len(line) == string.len(bullet) then
                -- empty bullet, delete it
                fn.setline(fn.line(".") - (del_above and 1 or -1), "")
                utils.reset_cursor_column()
                return
            end
            return utils.get_ordered_add(bullet, 1) -- add 1 to ordered
        end
	end
end


function M.new(motion, mapping, prev_line_override)
	local filetype_lists = get_lists()

    if motion == nil then
        next_keypress = mapping
        vim.o.operatorfunc = "v:lua.require'autolist'.new"
        edit_mode = vim.api.nvim_get_mode().mode
        if utils.is_list(fn.getline("."), filetype_lists) then
            return "<esc>g@la"
        end
        return mapping
    end

    press(next_keypress, edit_mode)

    if not filetype_lists then return nil end
    if is_in_code_fence() then return nil end

    print(prev_line_override)
    -- if new_bullet_before, prev_line should be the line below
    local prev_line = fn.getline(fn.line(".") + (prev_line_override and 1 or -1))

    local cur_line = fn.getline(".")
    local bullet = find_suitable_bullet(prev_line,
                                        filetype_lists,
                                        not prev_line_override)


    if prev_line:match(pat_colon)
        and (config.colon.indent_raw
             or (bullet and config.colon.indent)) then
        bullet = config.tab .. config.colon.preferred .. " "
    end

    if bullet then
        utils.set_current_line(bullet .. cur_line:gsub("^%s*", "", 1))
    end
end

function M.indent(motion, mapping)
	local filetype_lists = get_lists()

	local current_line_is_list = utils.is_list(fn.getline("."), filetype_lists)

	if motion == nil then
		if string.lower(mapping) == "<tab>" then
			local cur_line = fn.getline(".")
			if
				current_line_is_list
				and fn.getpos(".")[3] - 1 == string.len(cur_line) -- cursor on last char of line
			then
				mapping = "<c-t>"
			end
		end
		next_keypress = mapping
		vim.o.operatorfunc = "v:lua.require'autolist'.indent"
		edit_mode = vim.api.nvim_get_mode().mode
		if not current_line_is_list then return mapping end
		if edit_mode == "i" then return "<esc>g@la" end
		return "g@l"
	end

	press(next_keypress, edit_mode)

	if current_line_is_list then recal() end
end

function M.force_recalculate(motion, mapping)
	local filetype_lists = get_lists()
	if motion == nil then
		next_keypress = mapping
		vim.o.operatorfunc = "v:lua.require'autolist'.force_recalculate"
		edit_mode = vim.api.nvim_get_mode().mode
		if edit_mode == "i" then return "<esc>g@la" end
		return "g@l"
	end

	press(next_keypress, edit_mode)

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
