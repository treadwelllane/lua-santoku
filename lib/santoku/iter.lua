local validate = require("santoku.validate")
local hascall = validate.hascall
local hasindex = validate.hasindex

local fun = require("santoku.functional")
local noop = fun.noop

local arr = require("santoku.array")
local aoverlay = arr.overlay
local aspread = arr.spread

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
  return _reduce(acc, v, it, a, it(a, i))
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
  if i ~= nil then
    return vsel(2, it(a, i))
  end
end

local function _each (a, ...)
  a(...)
  return a
end

local function each (fn, it, a, i)
  assert(hascall(fn))
  assert(hascall(it))
  return reduce(_each, fn, it, a, i)
end

local function _map (fn, i, ...)
  if i ~= nil then
    return i, fn(...)
  end
end


local function map (fn, it, a, i)
  assert(hascall(fn))
  assert(hascall(it))
  return function (a, i)
    return _map(fn, it(a, i))
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
    return _filter(fn, it, a, it(a, i))
  end, a, i
end


local function flatten (parent_it, parent_a, parent_i)
  assert(hascall(parent_it))
  local parent_i0, child_it, child_a, child_i
  local function _flatten (parent_a, parent_i)
    if parent_i == nil then
      return
    end
    if child_it == nil then
      parent_i0, child_it, child_a, child_i = parent_it(parent_a, parent_i)
      if parent_i0 == nil then
        return
      end
      assert(hascall(child_it))
    end
    return vtup(function (child_i0, ...)
      if child_i0 == nil then
        child_it = nil
        return _flatten(parent_a, parent_i0)
      else
        child_i = child_i0
        return parent_i, ...
      end
    end, child_it(child_a, child_i))
  end
  return _flatten, parent_a, parent_i
end




local function _interleave (v, it)
  local t = {}
  local interleaving = false
  return function (a, i)
    while true do
      if #t == 0 then
        aoverlay(t, 1, it(a, i))
        i = t[1]
      elseif t[1] == nil then
        return
      elseif not interleaving then
        interleaving = true
        return aspread(t)
      else
        interleaving = false
        aoverlay(t, 1, it(a, i))
        return t[1], v
      end
    end
  end
end

local function _deinterleave (it)
  local removing = false
  local function helper (a, i)
    if i ~= nil then
      if not removing then
        removing = true
        return it(a, i)
      else
        removing = false
        return helper(a, it(a, i))
      end
    end
  end
  return helper
end

local function interleave (v, it, a, i)
  assert(hascall(it))
  return _interleave(v, it), a, i
end

local function deinterleave (it, a, i)
  assert(hascall(it))
  return _deinterleave(it), a, i
end

local function single (v)
  return function (_, i)
    if i then
      return false, v
    end
  end, nil, true
end

local function once (fn)
  assert(hascall(fn))
  return function (_, i)
    if i then
      return false, fn()
    end
  end, nil, true
end

local function tail (it, a, i)
  assert(hascall(it))
  return it, a, (it(a, i))
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
  assert(hasindex(t))
  return _anext, t, 0
end

local function tpairs (t)
  assert(hasindex(t))
  return _tnext, t, nil
end

local function akeys (t)
  assert(hasindex(t))
  return map(_key, apairs(t))
end

local function avals (t)
  assert(hasindex(t))
  return map(_val, apairs(t))
end

local function tkeys (t)
  assert(hasindex(t))
  return map(_key, tpairs(t))
end

local function tvals (t)
  assert(hasindex(t))
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
  assert(hascall(it))
  return function (each, final)
    assert(hascall(each))
    final = final or noop
    assert(hascall(final))
    return _async(each, final, it, a, it(a, i))
  end
end

local function wrap (it, a, i)
  assert(hascall(it))
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

  once = once,
  single = single,

  apairs = apairs,
  akeys = akeys,
  avals = avals,

  tpairs = tpairs,
  tkeys = tkeys,
  tvals = tvals,

  map = map,
  filter = filter,
  flatten = flatten,

  interleave = interleave,
  deinterleave = deinterleave,

  async = async,
  wrap = wrap,

  each = each,
  reduce = reduce,
  collect = collect,

  head = head,
  tail = tail,

}


















































































































































































































