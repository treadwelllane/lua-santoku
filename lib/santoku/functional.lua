local op = require("santoku.op")
local varg = require("santoku.varg")
local vsel = varg.sel
local vlen = varg.len
local vtake = varg.take

local function bind (fn, ...)
  if vlen(...) == 0 then
    return fn
  else
    local v = ...
    return function (...)
      return fn(v, ...)
    end
  end
end

local function maybe (fn)
  return function (ok, ...)
    if ok then
      return true, fn(...)
    else
      return false, ...
    end
  end
end

local function compose (a, b)
  return function (...)
    return a(b(...))
  end
end

local function sel (fn, n)
  return function (...)
    return fn(vsel(n, ...))
  end
end

local function take (fn, n)
  return function (...)
    return fn(vtake(n, ...))
  end
end

local function choose (a, b, c, ...)
  if a then
    return b, ...
  else
    return c, ...
  end
end

local function id (...)
  return ...
end

local function noop () end

local function const (x)
  return function ()
    return x
  end
end

local M = {
  id = id,
  bind = bind,
  maybe = maybe,
  compose = compose,
  noop = noop,
  sel = sel,
  take = take,
  choose = choose,
  const = const,
}

M.get = function (p)
  return function (t)
    return t[p]
  end
end

M.tget = function (t)
  return function (p)
    return t[p]
  end
end

M.set = function (p, v)
  return function (t)
    t[p] = v
  end
end

M.tset = function (t, v)
  return function (p)
    t[p] = v
  end
end

for k, v in pairs(op) do
  if not M[k] then
    M[k] = function (...)
      return M.bind(v, ...)
    end
  end
end

return M
