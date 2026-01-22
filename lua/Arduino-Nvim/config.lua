---@alias Arduino-Nvim.Picker "telescope" | "snacks"

---@class Arduino-Nvim.opts
---@field picker Arduino-Nvim.Picker

local M = {
	---@type Arduino-Nvim.opts
	opts = { picker = "telescope" },
}


---@param opts Arduino-Nvim.opts
function M.setup(opts)
	M.opts = vim.tbl_deep_extend("force", M.opts, opts or {})
end

return M
