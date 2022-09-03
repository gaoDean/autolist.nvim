local pat_num = "%d+"
local pat_char = "%a"
local prefix = "^%s*("
local suffix = ").*$"
local fn = vim.fn

local M = {}

local function vo(char)
	return char:byte()
end

local function custom_round(a, b, val)
	-- if val bigger than the middle of a and b
	if val > (a + b) / 2 then
		-- return the bigger
		-- a > b ? a : b;
		if a > b then return a else return b end
	else
		-- return the smaller
		-- a < b ? a : b;
		if a < b then return a else return b end
	end
end

-- wrap the char
-- increment z goes to A
-- increment Z goes to a
-- decrement vice verca
function M.charwrap(byte)
	-- search up ascii table
	-- value of char (value a)
	local va = vo('a')
	local vA = vo('A')
	local vz = vo('z')
	local vZ = vo('Z')
	if byte > vz then
		return vA
	-- smaller than 'z'
	elseif byte < vA then
		return vz
	elseif byte > vZ and byte < va then
		-- return the further value
		-- round == 'a' ? 'Z' : 'a'
		return custom_round(vZ, va, byte) == va and vZ or vA
	end
	return byte
end

function M.str_add_digit(str, digit)
	-- if not a str (a string)
	if tonumber(str) then
		return tostring(tonumber(str) + digit)
	end
	return nil
end

function M.ordered_add(entry, amount)
	-- defaults to increment
	if not amount then amount = 1 end
	local digit = entry:gsub(prefix .. "%d+)%..*$", "%1", 1)
	local char = entry:gsub(prefix .. "%a)[.)].*$", "%1", 1)
	-- if its an ordered list
	if digit and digit ~= entry then
		return entry:gsub(digit, M.str_add_digit(digit, amount), 1)
	-- if it's an ascii list
	elseif char and char ~= entry then
		local byteform = charwrap(char:byte() + amount)
		-- if bigger than lowercase z wrap to upper A and vice versa
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
		newval = M.ordered_add(entry, 1)
	else
		newval = M.ordered_add(entry, -1)
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
	else
		more = ""
	end
	for _, pat in ipairs(list_types) do
		local sub, nsubs = entry:gsub(prefix .. pat .. more .. suffix, "%1", 1)
		-- if replaced something
		if nsubs > 0 then
			return true, pat, sub
		end
	end
	return false
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
		local tabstop = vim.opt.tabstop:get()
		-- get tabstop in spaces
		for i = 1, tabstop, 1 do
			pattern = pattern .. " "
		end
		return pattern, tabstop
	else
		return "\t", 1
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
	if not cur_linenum then
		cur_linenum = fn.line(".")
	end
	local linenum = cur_linenum
	local line = fn.getline(linenum)
	local cur_indent = M.get_indent_lvl(line)
	if cur_indent < 0 then cur_indent = 0 end
	while (M.is_ordered(line) and M.get_indent_lvl(line) >= cur_indent) or M.get_indent_lvl(line) > cur_indent do
		linenum = linenum - 1
		line = fn.getline(linenum)
	end
	line = fn.getline(linenum + 1)
	if M.is_ordered(line) then
		return linenum + 1
	end
	return nil
end

function M.get_parent_list(line)
	return M.get_list_start(line) - 1
end

function M.trim_end(str)
	return str:gsub("%s*$", "")
end

function M.filter_pat(pat)
	return pat:gsub("%%", "")
end

function M.table_contains(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end

-- returns the correct lists for the current filetype
function M.get_lists(filetype_lists)
	-- each table in filetype lists has the key of a filetype
	-- each value has the tables (of lists) that it is assigned to
	return filetype_lists[vim.bo.filetype]
end


return M
