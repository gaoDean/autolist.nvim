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
local function waterfall(ptrline, rise, override_line)
	local cur_indent_lvl
	if override_line then
		cur_indent_lvl = utils.get_indent_lvl(override_line)
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

return M
