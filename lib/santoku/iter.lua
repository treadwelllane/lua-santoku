local compat = require("santoku.compat")
local cnoop = compat.noop
local hascall = compat.hasmeta.call

local varg = require("santoku.varg")
local vtup = varg.tup
local vsel = varg.sel

local function _reduce (acc, v, it, a, i, ...)
  if i == nil then
    return v
  elseif not v then
    return _reduce(acc, ..., it, a, it(a, i))
  else
    return _reduce(acc, acc(v, ...), it, a, it(a, i))
  end
end

local function reduce (acc, v, it, a, i)
  assert(hascall(acc))
  assert(hascall(it))
  return vtup(_reduce, acc, v, it, a, it(a, i))
end

local function _collect (a, n)
  a[#a + 1] = n
  return a
end

local function collect (it, a, i)
  assert(hascall(it))
  return reduce(_collect, {}, it, a, i)
end

local function head (it, a, i)
  assert(hascall(it))
  return vsel(2, it(a, i))
end

local function _each (a, ...)
  a(...)
  return a
end

local function each (fn, it, a, i)
  assert(hascall(it))
  return reduce(_each, fn, it, a, i)
end

local function _map (fn, i, ...)
  if i ~= nil then
    return i, fn(...)
  end
end


local function map (fn, it, a, i)
  return function (a, i)
    return vtup(_map, fn, it(a, i))
  end, a, i
end

local function _filter (fn, it, a, i, ...)
  if i ~= nil then
    if fn(...) then
      return i, ...
    else
      return _filter(fn, it, a, it(a, i))
    end
  end
end


local function filter (fn, it, a, i)
  assert(hascall(fn))
  assert(hascall(it))
  return function (a, i)
    return vtup(_filter, fn, it, a, it(a, i))
  end, a, i
end

local function _key (k)
  return k
end

local function _val (_, v)
  return v
end

local function _anext (a, i)
  i = i + 1
  if a[i] ~= nil then
    return i, i, a[i]
  end
end

local function _tnext (a, k)
  k = next(a, k)
  if k ~= nil then
    return k, k, a[k]
  end
end

local function apairs (t)
  return _anext, t, 0
end

local function tpairs (t)
  return _tnext, t, nil
end

local function akeys (t)
  return map(_key, apairs(t))
end

local function avals (t)
  return map(_val, apairs(t))
end

local function tkeys (t)
  return map(_key, tpairs(t))
end

local function tvals (t)
  return map(_val, tpairs(t))
end

local function _async (each, final, it, a, i, ...)
  if i == nil then
    return final(true, i, ...)
  else
    return each(function (ok, ...)
      if ok then
        return _async(each, final, it, a, it(a, i))
      else
        return final(ok, ...)
      end
    end, i, ...)
  end
end

local function async (it, a, i)
  return function (each, final)
    assert(hascall(each))
    final = final or cnoop
    assert(hascall(final))
    return _async(each, final, it, a, it(a, i))
  end
end

local function wrap (it, a, i)
  return function ()
    return vtup(function (i0, ...)
      i = i0
      if i ~= nil then
        return ...
      end
    end, it(a, i))
  end
end

return {

  apairs = apairs,
  akeys = akeys,
  avals = avals,

  tpairs = tpairs,
  tkeys = tkeys,
  tvals = tvals,

  map = map,
  filter = filter,

  async = async,
  wrap = wrap,

  each = each,
  reduce = reduce,
  collect = collect,

  head = head

}














































































































































































































































































































































































































































































































































































































































