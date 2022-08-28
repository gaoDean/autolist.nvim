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

return M
