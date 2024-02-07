local test = require("santoku.test")
local serialize = require("santoku.serialize") -- luacheck: ignore

local err = require("santoku.error")
local assert = err.assert

local validate = require("santoku.validate")
local notnil = validate.isnotnil
local isnil = validate.isnil
local eq = validate.isequal

local fun = require("santoku.functional")
local bind = fun.bind
local noop = fun.noop

local varg = require("santoku.varg")
local tup = varg.tup

local op = require("santoku.op")
local add = op.add

local arr = require("santoku.array")
local sort = arr.sort
local spread = arr.spread
local pack = arr.pack

local iter = require("santoku.iter")
local pairs = iter.pairs
local paste = iter.paste
local ikeys = iter.ikeys
local ivals = iter.ivals
local keys = iter.keys
local vals = iter.vals
local map = iter.map
local collect = iter.collect
local singleton = iter.singleton
local once = iter.once
local flatten = iter.flatten
local reduce = iter.reduce
local filter = iter.filter
local each = iter.each
local interleave = iter.interleave
local deinterleave = iter.deinterleave
local tail = iter.tail
local drop = iter.drop
local take = iter.take
local last = iter.last
local async = iter.async
local first = iter.first
local chain = iter.chain
local tabulate = iter.tabulate

local tbl = require("santoku.table")
local teq = tbl.equals

test("ikeys", function ()
  assert(teq({ 1, 2, 3, 4 }, collect(ikeys({ "a", "b", "c", "d", a = 1, b = 2 }))))
end)

test("ivals", function ()
  assert(teq({ "a", "b", "c", "d" }, collect(ivals({ "a", "b", "c", "d", a = 1, b = 2 }))))
  assert(teq({}, collect(ivals({}))))
end)

test("keys", function ()
  assert(teq({ "2", "a", "b" }, sort(collect(map(tostring, keys({ a = 2, [2] = 4, b = 6 }))))))
end)

test("vals", function ()
  assert(teq({ 2, 4, 6 }, sort(collect(vals({ a = 2, [2] = 4, b = 6 })))))
end)

test("empty", function ()
  assert(teq({}, collect(noop)))
end)

test("single", function ()
  assert(teq({ "a" }, collect(singleton("a"))))
end)

test("flatten", function ()
  local input = { { 1, 2 }, { 3, 4 }, { 5, 6 }, { 7, 8 } }
  local expected = { 1, 2, 3, 4, 5, 6, 7, 8 }
  assert(teq(expected, collect(flatten(map(ivals, ivals(input))))))
  assert(teq({ 1, 2, 3, 4 }, collect(flatten(map(singleton, ivals({ 1, 2, 3, 4 }))))))
end)

test("flatten", function ()
  local input = { { a = 1 }, { b = 2 }, { c = 3 }, { d = 4 } }
  local expected = { { "a", 1 }, { "b", 2 }, { "c", 3 }, { "d", 4 } }
  assert(teq(expected, collect(map(pack, flatten(map(pairs, vals(input)))))))
  assert(teq({ "a", "b", "c", "d" }, collect(flatten(map(pairs, vals(input))))))
end)

test("map", function ()
  assert(teq({ 2, 3, 4, 5 }, collect(map(bind(add, 1), ivals({ 1, 2, 3, 4 })))))
end)

test("reduce", function ()
  assert(teq({ 6 }, { reduce(add, 0, ivals({ 1, 2, 3 })) }))
end)

test("filter", function ()
  assert(teq({ 2, 4 }, collect(filter(function (a) return a % 2 == 0 end, ivals({ 1, 2, 3, 4 })))))
end)

test("each", function ()
  local called = 0
  each(function (...)
    called = called + 1
    assert(teq({ ... }, { called }))
  end, ivals({ 1, 2, 3, 4 }))
  assert(called == 4)
end)

test("once", function ()
  local it = once(function () return 1 end)
  local i = it()
  assert(notnil(i))
  assert(eq(i, 1))
  i = it()
  assert(isnil(i))
end)

test("interleave", function ()
  assert(teq({ 1, "x", 2, "x", 3 }, collect(interleave("x", ivals({ 1, 2, 3 })))))
  assert(teq({ 1, "x", 3, }, collect(interleave("x", ivals({ 1, 3 })))))
  assert(teq({ 1 }, collect(interleave("x", ivals({ 1 })))))
end)

test("deinterleave", function ()
  assert(teq({ 1, 2, 3 }, collect(deinterleave(ivals({ 1, "x", 2, "x", 3 })))))
  assert(teq({ 1, 2 }, collect(deinterleave(ivals({ 1, "x", 2, "x" })))))
  assert(teq({ 1, 2 }, collect(deinterleave(ivals({ 1, "x", 2 })))))
  assert(teq({ 1 }, collect(deinterleave(ivals({ 1, "x" })))))
  assert(teq({ 1 }, collect(deinterleave(ivals({ 1 })))))
  assert(teq({}, collect(deinterleave(ivals({})))))
end)

test("tail", function ()
  assert(teq({ 2, 3 }, collect(tail(ivals({ 1, 2, 3 })))))
  assert(teq({}, collect(tail(ivals({ 3 })))))
end)

test("drop", function ()
  assert(teq({ 1, 2, 3, 4 }, collect(drop(0, ivals({ 1, 2, 3, 4 })))))
  assert(teq({ 3, 4 }, collect(drop(2, ivals({ 1, 2, 3, 4 })))))
  assert(teq({}, collect(drop(4, ivals({ 1, 2, 3, 4 })))))
  assert(teq({}, collect(drop(5, ivals({ 1, 2, 3, 4 })))))
  assert(teq({}, collect(drop(1, ivals({})))))
  assert(teq({}, collect(drop(1, ivals({ 3 })))))
end)

test("last", function ()
  assert(teq({ 4 }, { last(vals({ 1, 2, 3, 4 })) }))
  assert(teq({ 4 }, { last(vals({ 4 })) }))
  assert(teq({}, { last(vals({})) }))
end)

test("async", function ()
  local asy = async(ivals({ 1, 2, 3, 4 }))
  local called = 0
  local finished = false
  tup(function (...)
    assert(teq({ ... }, { "hi" }))
  end, asy(function (done, x)
    called = called + 1
    assert(teq({ called }, { x }))
    return done(true)
  end, function (ok)
    finished = true
    assert(teq({ 4 }, { called }))
    assert(ok == true)
    return "hi"
  end))
  assert(finished)
end)

test("async abort", function ()
  local asy = async(ivals({ 1, 2, 3, 4 }))
  local called = 0
  local finished = false
  tup(function (...)
    assert(teq({ ... }, { "exit" }))
  end, asy(function (done, x)
    called = called + 1
    assert(teq({ called }, { x }))
    if x > 2 then
      return done(false, "exit")
    else
      return done(true)
    end
  end, function (ok, x)
    finished = true
    assert(teq({ 3 }, { called }))
    assert(ok == false)
    return x
  end))
  assert(finished)
end)

test("first", function ()
  assert(teq({ "a", "a" }, { first(pairs({ a = "a" })) }))
end)

test("chain", function ()
  assert(teq({ "a", "a" }, collect(chain(singleton("a"), keys({ a = 1 })))))
end)

test("paste", function ()
  assert(teq({ { "a", 1 }, { "a", 2 } }, collect(map(pack, paste("a", ivals({ 1, 2 }))))))
end)

test("take", function ()
  assert(teq({ 1, 2, 3 }, collect(take(3, ivals({ 1, 2, 3, 4, 5 })))))
end)

test("tabulate", function ()
  assert(teq({ a = 1, b = 2 }, tabulate(map(spread, ivals({ { "a", 1 }, { "b", 2 } })))))
end)















































































































































































































































































































































