local config = require("autolist.config")

local M = {}

M.setup = function(opts)
	config.update(opts)
	for k, v in pairs(require("autolist.auto")) do
		M[k] = v
	end
end

return M
