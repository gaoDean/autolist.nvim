local config = require("autolist.config")

local M = {}

M.setup = function(opts)
	config.update(opts)

	-- i dunno how to do this better
	-- if someone knows, pls tell me
	-- local generic = require("autolist.lists.generic")
	local auto = require("autolist.auto")
	-- M.invert = generic.invert
	M.new = auto.new
	-- M.relist = generic.relist
	M.tab = auto.tab
	-- M.unlist = generic.unlist
end

return M
