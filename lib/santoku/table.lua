-- Functions that operate on pure lua tables

-- TODO: Add the pre-curried functions

-- TODO: merge, deep merge, etc, walk a
-- table
--
-- TODO: Clarify where n should be added or
-- omitted: If the library input omits it, omit
-- it except in the case of wrapn, setn, pack,
-- etc.
--
-- Don't use oop style in here, leave that for
-- the API user

local compat = require("santoku.compat")
local tup = require("santoku.tuple")

local M = {}

M.MT = {
  __call = function (M, t)
    return M.wrap(t)
  end
}

M.MT_TABLE = {
  __name = "santoku_table",
  __index = M
}

-- TODO use inherit
M.wrap = function (t)
  t = t or {}
  return setmetatable(t, M.MT_TABLE)
end

M.unwrap = function (t)
  setmetatable(t, nil)
  return t
end

M.unwrapped = function (t)
  return M.assign({}, t)
end

M.get = function (t, ...)
  assert(compat.hasmeta.index(t))
  local m = tup.len(...)
  if m == 0 then
    return t
  else
    for i = 1, m do
      t = t[tup.get(i, ...)]
      if t == nil then
        break
      end
    end
    return t
  end
end

M.update = function (t, ...)
  local m = tup.len(...)
  assert(m > 1, "one or more keys must be provided")
  local ks = tup(tup.take(m - 1, ...))
  local fn = tup.get(m, ...)
  assert(compat.hasmeta.call(fn))
  local v = M.get(t, ks())
  M.set(t, ks(fn(v)))
  return t
end

M.set = function (t, ...)
  local m = tup.len(...)
  assert(m > 1, "one or more keys must be provided")
  local v = tup.get(m, ...)
  m = m - 1
  local t0 = t
  for i = 1, m - 1 do
    assert(compat.hasmeta.index(t0))
    assert(compat.hasmeta.newindex(t0))
    local k = tup.get(i, ...)
    if t0 == nil then
      return
    end
    local nxt = t0[k]
    if nxt == nil then
      nxt = {}
      t0[k] = nxt
    end
    t0 = t0[k]
  end
  t0[tup.get(m, ...)] = v
  return t
end

M.assign = function (t, ...)
  assert(compat.hasmeta.index(t))
  assert(compat.hasmeta.newindex(t))
  local m = tup.len(...)
  for i = 1, m do
    local t0 = tup.get(i, ...)
    assert(compat.hasmeta.pairs(t0))
    for k, v in pairs(t0) do
      t[k] = v
    end
  end
  return t
end

M.each = function (t, fn, ...)
  assert(compat.hasmeta.call(fn))
  assert(compat.hasmeta.index(t))
  for k, v in pairs(t) do
    fn(k, v, ...)
  end
end

M.map = function (t, fn, ...)
  assert(compat.hasmeta.pairs(t))
  assert(compat.hasmeta.call(fn))
  assert(compat.hasmeta.index(t))
  assert(compat.hasmeta.newindex(t))
  for k, v in pairs(t) do
    t[k] = fn(v, ...)
  end
  return t
end

-- TODO: This doesn't check keys that are
-- present in a but not in ts
M.equals = function (a, ...)
  assert(compat.hasmeta.index(a))
  local m = tup.len(...)
  for i = 1, m do
    local t0 = tup.get(i, ...)
    assert(compat.hasmeta.pairs(t0))
    for k, v in pairs(t0) do
      if a[k] ~= v then
        return false
      end
    end
  end
  return true
end

M.merge = function (t, ...)
  assert(compat.hasmeta.index(t))
  assert(compat.hasmeta.newindex(t))
  for i = 1, tup.len(...) do
    local t0 = tup.get(i, ...)
    for k, v in pairs(t0) do
      if not compat.hasmeta.index(v) or not compat.hasmeta.index(t[k]) then
        t[k] = v
      else
        M.merge(t[k], v)
      end
    end
  end
  return t
end

-- TODO: Reduce all of these pack/unpacks
local paths
paths = function (t, fn, stop, ...)
  assert(compat.hasmeta.call(fn))
  assert(compat.hasmeta.call(stop))
  assert(compat.hasmeta.pairs(t))
  for k, v in pairs(t) do
    if stop(v) then
      fn(compat.unpackr(compat.pack(k, ...)))
    else
      paths(v, fn, stop, k, ...)
    end
  end
end

M.paths = function (t, fn, stop)
  stop = stop or function (v)
    return not compat.hasmeta.index(v)
  end
  assert(compat.hasmeta.call(stop))
  assert(compat.hasmeta.call(fn))
  return paths(t, fn, stop)
end

-- TODO: Can we do this without creating a
-- vector of path vectors?
-- TODO: This might be better off called reduce
M.mergeWith = function (t, spec, ...)
  for i = 1, tup.len(...) do
    local t0 = tup.get(i, ...)
    M.paths(spec, function (...)
      M.set(t, tup(...)(
        M.get(spec, ...)(
          M.get(t, ...),
          M.get(t0, ...))))
    end)
  end
  return t
end

M.len = function (t)
  return compat.hasmeta.index(t) and t.n or
         compat.hasmeta.len(t) and #t or nil
end

return setmetatable(M, M.MT)
