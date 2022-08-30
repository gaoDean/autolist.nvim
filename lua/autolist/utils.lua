local pat_num = "%d+"
local pat_char = "%a"
local prefix = "^%s*("
local suffix = ").*$"
local fn = vim.fn

local M = {}

-- increment if its an ordered list
-- the caller must make sure that {entry} is a list
function M.increment(entry)
	local digit = entry:gsub(prefix .. "%d+)%..*$", "%1", 1)
	local char = entry:match(prefix .. "%a)..*$", "%1", 1)
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

-- the caller must make sure that {entry} is a list
function M.decrement(entry)
	local digit = entry:gsub(prefix .. "%d+)%..*$", "%1", 1)
	local char = entry:match(prefix .. "%a)..*$", "%1", 1)
	-- if its an ordered list
	if digit then
		return entry:gsub(digit, digit - 1, 1)
	-- if it's an ascii list
	elseif char then
		local byteform = char:byte() - 1
		-- if bigger than lowercase z wrap to upper A and vice versa
		if byteform < 65 then
			byteform = 122
		elseif byteform > 90 and byteform < 97
			then byteform = 90
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
function M.is_ordered(entry, rise, list_types)
	-- increment only acts on incrementable (ordered) lists
	local newval
	if rise > 0 then
		newval = M.increment(entry)
	else
		newval = M.decrement(entry)
	end
	-- if increment changed {entry} it is changable thus ordered
	if newval ~= entry then
		return newval
	end
	return nil
end

-- is a list, returns true, the pattern and the result of the pattern
function M.is_list(entry, list_types, more)
	if more then
		more = "%s"
	end
	for _, pat in ipairs(list_types) do
		local sub, nsubs = entry:gsub("^%s*(" .. pat .. more .. ").*$", "%1", 1)
		-- if replaced something
		if nsubs > 0 then
			return true, pat, sub
		end
	end
	return false
end

function M.not_list(entry, list_types, more)
	if more then
		more = "%s"
	end
	for _, pat in ipairs(list_types) do
		local _, nsubs = entry:gsub(prefix .. pat .. more .. suffix, "%1", 1)
		-- if replaced something
		if nsubs > 0 then
			return false
		end
	end
	return true
end

-- returns the number of tabs/spaces before a character
function M.get_indent_lvl(entry)
	return #(entry:match("^%s*"))
end

-- returns a lua pattern with the current vim tab value
function M.tab_value()
	if vim.bo.expandtab then
		local pattern = ""
		-- get tabstop in spaces
		for i = 1, vim.bo.tabstop, 1 do
			pattern = pattern .. " "
		end
		return ret
	else
		return "\t"
	end
end

function M.get_value_ordered(entry)
	local digit = entry:gsub(prefix .. "%d+)%..*$", "%1", 1)
	local char = entry:match(prefix .. "%a)..*$", "%1", 1)
	if digit then
		return digit
	elseif char then
		local byteform = char:byte()
		-- lower a is 1
		if byteform > 96 then
			byteform = byteform - 96
		elseif byteform > 64 then
			byteform = byteform - 64
		end
		return byteform
	end
	return nil
end

return M
