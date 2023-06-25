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
    print("autolist.nvim: There has been a major update. Please read README again for guide.")
end

return M
