local pat_num = "%d+"
local pat_char = "%a"
local prefix = "^%s*("
local suffix = ").*$"
local fn = vim.fn

local M = {}

-- search up ascii table
-- value of char (value a)
local function vo(char) return char:byte() end
local va = vo("a")
local vA = vo("A")
local vz = vo("z")
local vZ = vo("Z")
local lenalph = 26 -- length of alphabet
-- the difference between capital A and lenalph minus 1
local diffAalph = 38 -- 27 plus 38 equals capital A in byteform

local function custom_round(a, b, val)
	-- if val bigger than the middle of a and b
	if val > (a + b) / 2 then
		-- return the bigger
		-- a > b ? a : b;
		if a > b then
			return a
		else
			return b
		end
	else
		-- return the smaller
		-- a < b ? a : b;
		if a < b then
			return a
		else
			return b
		end
	end
end

-- wrap the char
-- increment z goes to A
-- increment Z goes to a
-- decrement vice verca
local function charwrap(byte)
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

-- just remember, to use a local function inside a function, you must
-- declare the local function before the current function.

-- ================================ utilities ============================== --

local function char_add(char, amount)
	return string.char(charwrap(char:byte() + amount))
end

-- add a number to a digit (thats a string)
local function str_add(str, amount)
	-- if not a str (a string)
	local num = tonumber(str)
	if num then return tostring(num + amount) end
	return nil
end

-- convert list number to char (1 -> a, 27 -> A)
local function number_to_char(number)
	if number <= lenalph then
		-- 1 equates to byteform of lowercase a
		return string.char(number + va - 1)
	else
		-- 27 equates to byteform of uppercase A
		return string.char(number + diffAalph)
	end
end

-- reduce boilerplate
local function exec_ordered(entry, func_digit, func_char, return_else)
	local digit = entry:gsub("^%s*(%d+)[.)].*$", "%1", 1)
	local char = entry:gsub("^%s*(%a)[.)].*$", "%1", 1)
	if digit and digit ~= entry then
		return func_digit(digit)
	elseif char and char ~= entry then
		return func_char(char)
	else
		return return_else
	end
end

local function char_to_number(char)
	local byteform = char:byte()
	if byteform >= va then
		byteform = byteform - (va - 1) -- lowercase a is 1
	elseif byteform >= vA then
		-- capital A comes after lowercase z in numbered form
		byteform = byteform - diffAalph -- (-64) + 26
	end
	return byteform
end

-- ================================ setters ==( set, reset )================ --

-- change the list marker of the current line
function M.set_line_marker(linenum, marker, list_types, checkbox)
	local line = fn.getline(linenum)
	line = line:gsub("%s*$", "", 1)
	line = line:gsub(
		"^(%s*)" .. M.get_marker_pat(line, list_types) .. "%s*",
		"%1" .. marker .. " ",
		1
	)
	if checkbox then line = line .. " " end
	fn.setline(linenum, line)
	M.reset_cursor_column(fn.col("$"))
end

function M.set_ordered_value(line, val)
	local function digitfunc() return (line:gsub("^(%s*)%d+", "%1" .. val, 1)) end
	local function charfunc()
		return (line:gsub("^(%s*)%a", "%1" .. number_to_char(val), 1))
	end
	return exec_ordered(line, digitfunc, charfunc, line)
end

function M.reset_cursor_column(col)
	if not col then col = 1 end
	local pos = fn.getpos(".")
	pos[3] = col
	fn.setpos(".", pos)
end

-- set current line to {new_line} and set cursor to end of line
function M.set_current_line(new_line)
	fn.setline(".", new_line)
	local pos = fn.getpos(".")
	-- the third value is the columns
	pos[3] = fn.col("$")
	fn.setpos(".", pos)
end

function M.set_line_number(num)
	local pos = fn.getpos(".")
	-- the second value is the row
	pos[2] = num
	fn.setpos(".", pos)
end

-- ================================ getters ==( get )======================= --

-- returns the number of tabs/spaces before a character
function M.get_indent_lvl(entry) return #(entry:match("^%s*")) end

-- get the list marker from the line
function M.get_marker(line, list_types)
	return select(3, M.is_list(line, list_types))
end

function M.get_marker_pat(line, list_types)
	return select(2, M.is_list(line, list_types))
end

-- trim whitespace
function M.get_whitespace_trimmed(str) return str:gsub("%s*$", "", 1) end

-- delete % signs
function M.get_percent_filtered(pat) return pat:gsub("%%", "") end

-- get the value of the ordered list
function M.get_value_ordered(entry)
	return exec_ordered(entry, tonumber, char_to_number, 0)
end

-- return add {amount} to the current ordered list
function M.get_ordered_add(entry, amount)
	if not amount then amount = 1 end -- defaults to increment
	local function digitfunc(digit)
		return entry:gsub(digit, str_add(digit, amount), 1)
	end
	local function charfunc(char)
		return entry:gsub(char, char_add(char, amount), 1)
	end
	return exec_ordered(entry, digitfunc, charfunc, entry)
end

-- get the start of the current list scope (indent)
function M.get_list_start(cur_linenum, list_types)
	if not cur_linenum then cur_linenum = fn.line(".") end
	local linenum = cur_linenum
	local line = fn.getline(linenum)
	local cur_indent = M.get_indent_lvl(line)
	if cur_indent < 0 then cur_indent = 0 end
	if list_types then
		while
			M.is_list(line, list_types)
			and M.get_indent_lvl(line) >= cur_indent
		do
			linenum = linenum - 1
			line = fn.getline(linenum)
		end
	else
		while
			(M.is_ordered(line) and M.get_indent_lvl(line) >= cur_indent)
			or M.get_indent_lvl(line) > cur_indent
		do
			linenum = linenum - 1
			line = fn.getline(linenum)
		end
	end
	line = fn.getline(linenum + 1)
	if M.is_list(line, list_types) then return linenum + 1 end
	return nil
end

-- ================================ checkers ==( does, is )================= --

-- is a list, returns true, the pattern and the result of the pattern
function M.is_list(entry, list_types, more)
	if not list_types then return M.is_ordered(entry) end
	if more then
		more = "%s"
	else
		more = ""
	end
	for _, pat in ipairs(list_types) do
		local sub, nsubs = entry:gsub(prefix .. pat .. more .. suffix, "%1", 1)
		-- if replaced something
		if nsubs > 0 then return true, pat, sub end
	end
	return false
end

--is ordered list
function M.is_ordered(entry, rise)
	-- increment only acts on incrementable (ordered) lists
	local newval
	if rise and rise > 0 then
		newval = M.get_ordered_add(entry, 1)
	else
		newval = M.get_ordered_add(entry, -1)
	end
	-- if increment changed {entry} it is changable thus ordered
	if newval ~= entry then return newval end
	return nil
end

return M
