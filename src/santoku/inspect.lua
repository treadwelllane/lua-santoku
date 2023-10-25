local inspect = require("inspect")
local tbl = require("santoku.table")

local M = {}

M.MT = {
	__call = function (_, ...)
		return M.inspect(...)
	end
}

M.inspect = function (obj, opts)
	opts = opts or {}
	return inspect(obj, tbl({
		process = function (i, p)
			if p[#p] ~= inspect.METATABLE then
				return i
			end
		end
	}):merge(opts))
end

return setmetatable(M, M.MT)
