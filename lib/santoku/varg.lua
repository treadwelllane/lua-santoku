local sel = select

local function len (...)
  return sel("#", ...)
end

local function take (i, ...)
  if i == 0 then
    return
  else
    return (...), take(i - 1, sel(2, ...))
  end
end

local function get (i, ...)
  return (sel(i, ...))
end

local function set (i, v, n, ...)
  if i == 1 then
    return v, ...
  else
    return n, set(i - 1, v, ...)
  end
end

local function append (a, ...)
  return set(len(...) + 1, a, ...)
end

local function tup (fn, ...)
  return fn(...)
end

local function _interleave (x, n, ...)
  if n < 2 then
    return ...
  else
    return ..., x, _interleave(x, n - 1, sel(2, ...))
  end
end

local function interleave (x, ...)
  return _interleave(x, len(...), ...)
end

local function _reduce (fn, n, a, ...)
  if n == 0 then
    return
  elseif n == 1 then
    return a
  else
    return _reduce(fn, n - 1, fn(a, (...)), sel(2, ...))
  end
end

local function reduce (fn, ...)
  return _reduce(fn, len(...), ...)
end

local function tabulate (...)
  local k = nil
  return reduce(function (a, n)
    if k == nil then
      k = n
      return a
    else
      a[k] = n
      k = nil
      return a
    end
  end, {}, ...)
end

local function filter (fn, ...)
  local n = len(...)
  if n == 0 then
    return
  elseif fn((...)) then
    return ..., filter(fn, sel(2, ...))
  else
    return filter(fn, sel(2, ...))
  end
end

local function each (fn, ...)
  if len(...) > 0 then
    fn((...))
    each(fn, sel(2, ...))
  end
end

local function map (fn, ...)
  if len(...) == 0 then
    return
  else
    return fn((sel(1, ...))), map(fn, sel(2, ...))
  end
end

local function _extend (fn, n, a, ...)
  if n == 0 then
    return fn()
  else
    return a, _extend(fn, n - 1, ...)
  end
end

local function extend (fn, ...)
  return _extend(fn, len(...), ...)
end

local function _reverse (n, a, ...)
  if n > 0 then
    return append(a, _reverse(n - 1, ...))
  end
end

local function reverse (...)
  return _reverse(len(...), ...)
end

local function call (...)
  return map(function (f)
    return f()
  end, ...)
end

local function includes (v, ...)
  for i = 1, len(...) do
    if v == sel(i, ...) then
      return true
    end
  end
  return false
end

return setmetatable({
  tup = tup,
  len = len,
  sel = sel,
  take = take,
  get = get,
  set = set,
  includes = includes,
  append = append,
  extend = extend,
  interleave = interleave,
  reduce = reduce,
  tabulate = tabulate,
  filter = filter,
  reverse = reverse,
  each = each,
  map = map,
  call = call,
}, {
  __call = function (_, ...)
    return tup(...)
  end
})
