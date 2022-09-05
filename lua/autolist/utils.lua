local pat_num = "%d+"
local pat_char = "%a"
local prefix = "^%s*("
local suffix = ").*$"
local fn = vim.fn

local M = {}

-- search up ascii table
-- value of char (value a)
local function vo(char) return char:byte() end
local va = vo('a')
local vA = vo('A')
local vz = vo('z')
local vZ = vo('Z')
local lenalph = 26 -- length of alphabet
-- the difference between capital A and lenalph minus 1
local diffAalph = 38 -- 27 plus 38 equals capital A in byteform

-- ================================ utilities ============================== --

local function char_add(char, amount)
	return string.char(charwrap(char:byte() + amount))
end

local function str_add(str, amount)
	-- if not a str (a string)
	if tonumber(str) then
		return tostring(tonumber(str) + amount)
	end
	return nil
end

local function number_to_char(number)
	if number <= lenalph then
		-- 1 equates to byteform of lowercase a
		return number + va - 1
	else
		-- 27 equates to byteform of uppercase A
		return number + diffAalph
	end
end

-- reduce boilerplate
local function exec_ordered(entry, func_digit, func_char, return_else, return_last)
	local digit = entry:gsub("^%s*(%d+)%..*$", "%1", 1)
	local char = entry:gsub("^%s*(%a)[.)].*$", "%1", 1)
	if digit and digit ~= entry then
		return func_digit(digit)
	elseif char and char ~= entry then
		return func_char(char)
	else
		return return_else
	end
	return return_last -- nil if not defined
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

-- ================================ setters ==( set, reset )================ --

function M.set_list_line(linenum, marker, list_types)
	local line = fn.getline(linenum)
	local line = line:gsub(select(2, M.is_list(line, list_types)), marker)
	fn.setline(linenum, line)
end

function M.set_value(line, linenum, val)
	local function digitfunc() fn.setline(linenum, (line:gsub("%d+", val, 1))) end
	local function charfunc() fn.setline(linenum, (line:gsub("%a", number_to_char(val), 1))) end
	return exec_ordered(line, digitfunc, charfunc)
end

function M.reset_cursor_column()
	local pos = fn.getpos(".")
	pos[3] = 1
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

-- ================================ getters ==( get )======================= --

-- returns the number of tabs/spaces before a character
function M.get_indent_lvl(entry) return #(entry:match("^%s*")) end

-- returns the tabs/spaces before a character
function M.get_indent(entry) return entry:match("^%s*") end

-- get the place where the indented list began
function M.get_parent_list(line) return M.get_list_start(line) - 1 end

-- get the list marker from the line
function M.get_marker(line, list_types) return select(3, M.is_list(line, list_types)) end

-- trim whitespace
function M.get_whitespace_trimmed(str) return str:gsub("%s*$", "") end

-- delete % signs
function M.get_percent_filtered(pat) return pat:gsub("%%", "") end

-- get the value of the ordered list
function M.get_value_ordered(entry)
	local function digitfunc(input) return tonumber(input) end
	return exec_ordered(entry, digitfunc, char_to_number, 0)
end

-- return add {amount} to the current ordered list
function M.get_ordered_add(entry, amount)
	if not amount then amount = 1 end -- defaults to increment
	local function digitfunc(digit) return entry:gsub(digit, str_add(digit, amount), 1) end
	local function charfunc(char) return entry:gsub(char, char_add(char, amount), 1) end
	return exec_ordered(entry, digitfunc, charfunc, entry)
end

-- returns a lua pattern with the current vim tab value
function M.get_tab_value()
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

-- get the start of the current list scope (indent)
function M.get_list_start(cur_linenum, list_types)
	if not cur_linenum then
		cur_linenum = fn.line(".")
	end
	local linenum = cur_linenum
	local line = fn.getline(linenum)
	local cur_indent = M.get_indent_lvl(line)
	if cur_indent < 0 then cur_indent = 0 end
	if list_types then
		while (M.is_list(line, list_types)
			and M.get_indent_lvl(line) >= cur_indent)
			or M.get_indent_lvl(line) > cur_indent
		do
			linenum = linenum - 1
			line = fn.getline(linenum)
		end
	else
		while (M.is_ordered(line)
			and M.get_indent_lvl(line) >= cur_indent)
			or M.get_indent_lvl(line) > cur_indent
		do
			linenum = linenum - 1
			line = fn.getline(linenum)
		end
	end
	line = fn.getline(linenum + 1)
	if M.is_list(line, list_types) then
		return linenum + 1
	end
	return nil
end

-- ================================ checkers ==( does, is )================= --

function M.does_table_contain(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end

function M.is_same_list_type(la, lb, list_types)
	for _, pat in ipairs(list_types) do
		local _, asub = la:gsub(prefix .. pat .. suffix, "%1", 1)
		local _, bsub = lb:gsub(prefix .. pat .. suffix, "%1", 1)
		-- if they sub something, asub should be 1 cus this ---^ (and bsub)
		if asub > 0 and bsub > 0 then
			return true
		end
	end
	return false
end

-- is a list, returns true, the pattern and the result of the pattern
function M.is_list(entry, list_types, more)
	if not list_types then
		return M.is_ordered(entry)
	end
	if more then
		more = "%s"
	else
		more = ""
	end
	for i, pat in ipairs(list_types) do
		local sub, nsubs = entry:gsub(prefix .. pat .. more .. suffix, "%1", 1)
		-- if replaced something
		if nsubs > 0 then
			return true, pat, sub, i
		end
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
	if newval ~= entry then
		return newval
	end
	return nil
end

return M
