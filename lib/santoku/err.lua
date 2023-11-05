local tup = require("santoku.tuple")
local co = require("santoku.co")




























































local M = {}

M.MT = {
  __call = function (wrapper, ...)
    return wrapper.ok(...)
  end
}

M.unimplemented = function (msg)
  M.error("Unimplemented", msg)
end


M.error = function (...)
  error(table.concat({ ... }, ": "), 2)
end

M.pwrapper = function (co, ...)
  local errs = tup(...)
  local wrapper = {
    err = function (...)
      return M.pwrapper(co, ...)
    end,
    exists = function (val, ...)
      if val ~= nil then
        return val, ...
      else
        return co.yield(errs(...))
      end
    end,






    okexists = function (ok, val, ...)
      if ok and val ~= nil then
        return val, ...
      else
        return co.yield(errs(...))
      end
    end,
    noerr = function (ok, ...)
      if ok == false then
        return co.yield(errs(...))
      else
        return ...
      end
    end,
    any = function (...)
      local ok, t
      for i = 1, select("#", ...) do
        t = select(i, ...)
        ok = t()
        if ok then
          return select(2, t())
        end
      end
      return co.yield(errs(select(2, t())))
    end,
    ok = function (ok, ...)
      if ok then
        return ...
      else
        return co.yield(errs(...))
      end
    end
  }
  return setmetatable(wrapper, M.MT)
end









M.pwrap = function (run, onErr)
  onErr = onErr or function (...)
    return false, ...
  end
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
      nxt = tup(onErr(select(2, ret())))
      if not nxt() then
        ret = nxt
        break
      end
    end
  end
  return ret()
end

M.check = function (ok, a, ...)
  if not ok then
    error(a)
  else
    return a, ...
  end
end

return M
