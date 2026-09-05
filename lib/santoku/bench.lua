local collectgarbage = collectgarbage
local print = print
local time = require("santoku.utc.capi").time
local function clock ()
  return time(true)
end

return function (tag, fn, ...)
  collectgarbage()
  collectgarbage()
  local t0 = clock()
  local x = fn(...)
  local t1 = clock()
  print(tag, t1 - t0, x)
end
