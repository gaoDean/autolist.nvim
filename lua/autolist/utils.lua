local pat_num = "%d+"
local pat_char = "%a"
local prefix = "^%s*("
local suffix = ").*$"
local fn = vim.fn

local M = {}

function M.str_add_digit(str, digit)
	-- if not a str (a string)
	if str then
		return tostring(tonumber(str) + digit)
	end
	return nil
end


-- increment if its an ordered list
-- the caller must make sure that {entry} is a list
function M.increment(entry, amount)
	if not amount then
		amount = 1
	end
	local digit = entry:gsub(prefix .. "%d+)%..*$", "%1", 1)
	local char = entry:gsub(prefix .. "%a)[.)].*$", "%1", 1)
	-- if its an ordered list
	if digit and digit ~= entry then
		return entry:gsub(digit, M.str_add_digit(digit, amount), 1)
	-- if it's an ascii list
	elseif char and char ~= entry then
		local byteform = char:byte() + amount
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
function M.decrement(entry, amount)
	if not amount then amount = 1 end
	local digit = entry:gsub(prefix .. "%d+)%..*$", "%1", 1)
	local char = entry:gsub(prefix .. "%a)[.)].*$", "%1", 1)
	-- if its an ordered list
	if digit then
		return entry:gsub(digit, M.str_add_digit(digit, amount), 1)
	-- if it's an ascii list
	elseif char then
		local byteform = char:byte() - amount
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

function M.reset_cursor_column()
	local pos = fn.getpos(".")
	pos[3] = 1
	fn.setpos(".", pos)
end

--is ordered list
function M.is_ordered(entry, rise)
	-- increment only acts on incrementable (ordered) lists
	local newval
	if rise and rise > 0 then
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

-- returns the tabs/spaces before a character
function M.get_indent(entry)
	return entry:match("^%s*")
end

-- returns a lua pattern with the current vim tab value
function M.tab_value()
	if vim.opt.expandtab:get() then
		local pattern = ""
		-- get tabstop in spaces
		for i = 1, vim.opt.tabstop:get(), 1 do
			pattern = pattern .. " "
		end
		return pattern
	else
		return "\t"
	end
end

function M.get_value_ordered(entry)
	local digit = entry:gsub(prefix .. "%d+)%..*$", "%1", 1)
	local char = entry:gsub(prefix .. "%a)[.)].*$", "%1", 1)
	if digit then
		return digit
	elseif char then
		local byteform = char:byte()
		if byteform > 96 then
			-- lowercase a is 1
			byteform = byteform - 96
		elseif byteform > 64 then
			-- (-64) + 26
			-- capital A comes after lowercase z
			byteform = byteform - 38
		end
		return byteform
	end
	return nil
end

-- returns successful
function M.set_value_ordered(linenum, line, val)
	local digit = line:gsub(prefix .. "%d+)%..*$", "%1", 1)
	local char = line:gsub(prefix .. "%a)[.)].*$", "%1", 1)
	if digit then
		fn.setline(linenum, (line:gsub("%d+", val, 1)))
		return true
	elseif char then
		if val <= 26 then
			-- 1 equates to byteform of lowercase a
			val = val + 96
		else
			-- 27 equates to byteform of uppercase A
			val = val + 38
		end
		fn.setline(linenum, line:gsub("%a", val, 1))
		return true
	else
		return false
	end
end

function M.get_list_start(cur_linenum)
	local linenum = cur_linenum
	local line = fn.getline(linenum)
	local cur_indent = get_indent_lvl(line)
	while is_ordered(line) or get_indent_lvl(line) > cur_indent do
		linenum = linenum - 1
		line = fn.getline(linenum)
	end
	local line = fn.getline(linenum + 1)
	if is_ordered(line) then
		return linenum + 1
	end
	return nil
end

function M.trim_end(str)
	return str:gsub("%s*$", "")
end

return M
