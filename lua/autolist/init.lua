local config = require("autolist.config")

local M = {}

M.setup = function(opts)
	config.update(opts)

	-- i dunno how to do this better
	-- if someone knows, pls tell me
	local generic = require("autolist.generic")
	M.invert = generic.invert
	M.list = generic.list
	M.relist = generic.relist
	M.reset = generic.reset
	M.unlist = generic.unlist
end

return M
