local tup = require("santoku.tuple")
local co = require("santoku.co")
local fun = require("santoku.fun")
local compat = require("santoku.compat")





































































local M = {}

local IDX = {}

M.MT = {
  __index = IDX,
  __call = function (wrapper, ...)
    return wrapper.ok(...)
  end
}

IDX.tag = function (o, err_tag)
  return M.pwrapper(o.co, err_tag)
end

IDX.ok = function (o, ok, ...)
  if ok then
    return ...
  else
    return o.co.yield(o.err_tag, ...)
  end
end

IDX.exists = function (o, val, ...)
  if val ~= nil then
    return val, ...
  else
    return o.co.yield(o.err_tag, ...)
  end
end

IDX.okexists = function (o, ok, val, ...)
  if ok and val ~= nil then
    return val, ...
  else
    return o.co.yield(o.err_tag, ...)
  end
end

IDX.noerr = function (o, ok, ...)
  if ok == false then
    return o.co.yield(o.err_tag, ...)
  else
    return ...
  end
end

M.pwrapper = function (co, err_tag)
  return setmetatable({ co = co, err_tag = err_tag }, M.MT)
end

M.pwrap = function (run, on_err)
  on_err = on_err or fun.bindl(compat.id, false)
  local co = co()
  local cor = co.create(function ()
    return run(M.pwrapper(co))
  end)
  local ret
  local nxt = tup()
  while true do
    ret = tup(co.resume(cor, select(2, nxt())))
    local status = co.status(cor)
    if status == "dead" then
      break
    elseif status == "suspended" then
      nxt = tup(on_err(select(2, ret())))
      if not nxt() then
        ret = nxt
        break
      end
    end
  end
  return ret()
end

M.error = function (...)
  error(tup.concat(tup.interleave(": ", tup.map(tostring, ...))), 0)
end

M.check = function (ok, ...)
  if not ok then
    M.error(...)
  else
    return ...
  end
end

return M
