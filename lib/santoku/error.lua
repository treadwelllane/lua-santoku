local arr = require("santoku.array")
local acat = arr.concat

local varg = require("santoku.varg")
local vinterleave = varg.interleave
local vmap = varg.map

local _error = error

local function error (...)
  _error(acat({ vinterleave(": ", vmap(tostring, ...)) }))
end

local function check (ok, ...)
  if not ok then
    _error({ ... })
  else
    return ...
  end
end

local function exists (...)
  return check(... ~= nil, ...)
end





























































return {
  error = error,
  check = check,
  exists = exists,

}
