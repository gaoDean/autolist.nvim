local config = require("autolist.config")

local M = {}

M.setup = function(opts)
	config.update(opts)

	-- i dunno how to do this better
	-- if someone knows, pls tell me
	local auto = require("autolist.auto")
	M.new = auto.new
	M.detab = auto.detab
	M.tab = auto.tab
	M.invert = auto.invert
	M.recal = auto.recal
	M.indent = auto.indent
end

return M
