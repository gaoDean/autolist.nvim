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

function M.decrement(entry)
	local digit = entry:match(pat_num)
	local char = entry:match(pat_char)
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
	if is_list(entry, list_types) then
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
	end
	return nil
end

-- is a list
function M.is_list(entry, list_types)
	for _, pat in ipairs(list_types) do
		local _, nsubs = entry:gsub("^%s*(" .. pat .. "%s?).*$", "%1", 1)
		-- if replaced something
		if nsubs > 0 then
			return true
		end
	end
	return false
end

-- returns the number of tabs/spaces before a character
function M.get_indent_lvl(entry)
	return #(entry:match("^%s*"))
end

return M
