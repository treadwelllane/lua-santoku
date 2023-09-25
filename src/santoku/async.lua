local gen = require("santoku.gen")
local compat = require("santoku.compat")
local tup = require("santoku.tuple")

local M = {}

local function pipe (final, ok, args, fns)
  local fn = fns()
  if not ok or not fn then
    return final(ok, args())
  else
    return fn(function (ok, ...)
      return pipe(final, ok, tup(...), tup(select(2, fns())))
    end, args())
  end
end

-- TODO: This should be generalizable. Some kind
-- of tup.reducek or tup.cont that reduces over
-- a list of arguments and allows for early
-- exit. tup.reduce_until? Something in gen?
M.pipe = function (...)
  local n = tup.len(...)
  local final = tup.sel(n, ...)
  local fns = tup(tup.take(n - 1, ...))
  return function (...)
    return pipe(final, true, tup(...), fns)
  end
end

local function each (g, it, done)
  if g:done() or not g:step() then
    return done(true)
  else
    return it(function (ok, ...)
      if not ok then
        return done(ok, ...)
      else
        return each(g, it, done)
      end
    end, g.val())
  end
end

M.each = function (g, it, done)
  assert(gen.iscogen(g))
  assert(compat.iscallable(it))
  return each(g, it, done)
end

return M
