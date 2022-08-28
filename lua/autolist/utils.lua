local config = require("autolist.config")

local pat_num = "%d+"
local pat_char = "%a"

local fn = vim.fn

local M = {}

-- increment if its an ordered list
function M.increment(entry)
	local digit = entry:match(pat_num)
	local char = entry:match(pat_char)
	-- if its an ordered list
	if digit then
		return entry:gsub(digit, digit + 1, 1)
	-- if it's an ascii list
	elseif char then
		local byteform = char:byte() + 1
		-- if bigger than lowercase z wrap to upper A and vice versa
		if byteform > 122 then
			byteform = 65
		elseif byteform > 90 and byteform < 97
			then byteform = 97
		end
		return entry:gsub(char, string.char(byteform), 1)
	end
	-- return original if anything else
	return entry
end

-- set current line to {new_line} and set cursor to end of line
function M.set_current_line(new_line)
	fn.setline(".", new_line)
	local pos = fn.getpos(".")
	-- the third value is the columns
	pos[3] = fn.col("$")
	fn.setpos(".", pos)
end

--is ordered list
local function is_ordered(entry)
	-- increment only acts on incrementable (ordered) lists
	if M.increment(entry) == entry then
		return false
	end
	-- if increment changed {entry} (incrementable)
	return true
end

-- is a list
local function is_list(entry)
	for _, pat in ipairs(config.list_types) do
		local _, nsubs = entry:gsub("^%s*(" .. pat .. "%s?).*$", "%1", 1)
		-- if replaced something
		if nsubs > 0 then
			return true
		end
	end
	return false
end

local function get_indent_lvl(entry)
	-- returns the number of tabs/spaces before a character
	return #(entry:match("^%s*"))
end

-- called it waterfall because the ordered list entries after {ptrline}
-- that belongs to the same list has {rise} added to it.
local function waterfall(ptrline, rise, override_line)
	local cur_indent_lvl
	if override_line then
		cur_indent_lvl = get_indent_lvl(override_line)
	else
		cur_indent_lvl = get_indent_lvl(fn.getline(ptrline))
	end
	-- waterfall only needs to affect after current line
	ptrline = ptrline + 1
	local eval_ptrline = fn.getline(ptrline)
	-- waterfall only acts on ordered lists
	-- if its smaller than current indent, the list is "out of scope"
	-- it can be bigger because it could be unordered but parent list ordered
	while is_ordered(eval_ptrline)
		or get_indent_lvl(eval_ptrline) > cur_indent_lvl
	do
		if indent_level(eval_ptrline) == cur_indent_lvl
			and is_ordered(eval_ptrline)
		then
			-- increment it
			fn.setline(ptrline, M.increment(eval_ptrline))
		end
		ptrline = ptrline + 1
		if ptrline > fn.line('$') then
			return
		end
		eval_ptrline = fn.getline(ptrline)
	end
end


return M
