local config = require("autolist.config")

local M = {}

local function snake_to_pascal_case(snake_str)
  snake_str = snake_str:gsub("^(%l)", function (l) return l:upper() end, 1)
  return snake_str:gsub("_(%l)", function (l) return l:upper() end)
end

M.setup = function(opts)
	config.update(opts)
	for k, v in pairs(require("autolist.auto")) do
		M[k] = v
        vim.cmd("command! "
                .. "Autolist"
                .. snake_to_pascal_case(k)
                .. " lua require('autolist')."
                .. k
                .. "()")
	end
end

M.create_mapping_hook = function(mode, mapping, func, alias)
	local additional_function = nil
	local maps = vim.api.nvim_get_keymap(mode)
	for _, map in ipairs(maps) do
		if map.lhs == mapping then
			if map.rhs then
				additional_function = map.rhs:gsub("^v:lua%.", "", 1)
			else
				additional_function = map.callback
			end
			pcall(vim.keymap.del, mode, mapping)
		end
	end
	vim.keymap.set(mode, mapping, function(motion)
		local additional_map = nil
		if additional_function then
			if type(additional_function) == "string" then
				local ok, res = pcall(load("return " .. additional_function))
				if ok then additional_map = res or "" end
			else
				additional_map = additional_function() or ""
			end
		end
		return func(motion, additional_map or alias or mapping) or ""
	end, { expr = true })
end

return M
