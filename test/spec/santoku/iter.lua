local test = require("santoku.test")

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
local vtup = varg.tup

local op = require("santoku.op")
local oadd = op.add

local arr = require("santoku.array")
local asort = arr.sort

local iter = require("santoku.iter")
local akeys = iter.akeys
local avals = iter.avals
local tkeys = iter.tkeys
local tvals = iter.tvals
local icollect = iter.collect
local itail = iter.tail
local ifilter = iter.filter
local iflatten = iter.flatten
local ieach = iter.each
local ireduce = iter.reduce
local imap = iter.map
local iasync = iter.async
local iwrap = iter.wrap
local isingle = iter.single
local ionce = iter.once
local ideinterleave = iter.deinterleave
local iinterleave = iter.interleave
local idrop = iter.drop
local ilast = iter.last

local tbl = require("santoku.table")
local teq = tbl.equals

test("akeys", function ()
  assert(teq({ 1, 2, 3, 4 }, icollect(akeys({ "a", "b", "c", "d", a = 1, b = 2 }))))
end)

test("avals", function ()
  assert(teq({ "a", "b", "c", "d" }, icollect(avals({ "a", "b", "c", "d", a = 1, b = 2 }))))
  assert(teq({}, icollect(avals({}))))
end)

test("tkeys", function ()
  assert(teq({ "2", "a", "b" }, asort(icollect(imap(tostring, tkeys({ a = 2, [2] = 4, b = 6 }))))))
end)

test("tvals", function ()
  assert(teq({ 2, 4, 6 }, asort(icollect(tvals({ a = 2, [2] = 4, b = 6 })))))
end)

test("empty", function ()
  assert(teq({}, icollect(noop)))
end)

test("single", function ()
  assert(teq({ "a" }, icollect(isingle("a"))))
end)

test("flatten", function ()
  local input = { { 1, 2 }, { 3, 4 }, { 5, 6 }, { 7, 8 } }
  local expected = { 1, 2, 3, 4, 5, 6, 7, 8 }
  assert(teq(expected, icollect(iflatten(imap(avals, avals(input))))))
  assert(teq({ 1, 2, 3, 4 }, icollect(iflatten(imap(isingle, avals({ 1, 2, 3, 4 }))))))
end)

test("map", function ()
  assert(teq({ 2, 3, 4, 5 }, icollect(imap(bind(oadd, 1), avals({ 1, 2, 3, 4 })))))
end)

test("reduce", function ()
  assert(teq({ 6 }, { ireduce(oadd, 0, avals({ 1, 2, 3 })) }))
end)

test("filter", function ()
  assert(teq({ 2, 4 }, icollect(ifilter(function (a) return a % 2 == 0 end, avals({ 1, 2, 3, 4 })))))
end)

test("each", function ()
  local called = 0
  ieach(function (...)
    called = called + 1
    assert(teq({ ... }, { called }))
  end, avals({ 1, 2, 3, 4 }))
  assert(called == 4)
end)

test("once", function ()
  local it, a, i = ionce(function () return 1 end)
  local i, v = it(a, i)
  assert(notnil(i))
  assert(eq(v, 1))
  i = it(a, i)
  assert(isnil(i))
end)

test("interleave", function ()
  assert(teq({ 1, "x", 2, "x", 3 }, icollect(iinterleave("x", avals({ 1, 2, 3 })))))
  assert(teq({ 1, "x", 3, }, icollect(iinterleave("x", avals({ 1, 3 })))))
  assert(teq({ 1 }, icollect(iinterleave("x", avals({ 1 })))))
end)

test("deinterleave", function ()
  assert(teq({ 1, 2, 3 }, icollect(ideinterleave(avals({ 1, "x", 2, "x", 3 })))))
  assert(teq({ 1, 2 }, icollect(ideinterleave(avals({ 1, "x", 2, "x" })))))
  assert(teq({ 1, 2 }, icollect(ideinterleave(avals({ 1, "x", 2 })))))
  assert(teq({ 1 }, icollect(ideinterleave(avals({ 1, "x" })))))
  assert(teq({ 1 }, icollect(ideinterleave(avals({ 1 })))))
  assert(teq({}, icollect(ideinterleave(avals({})))))
end)

test("tail", function ()
  assert(teq({ 2, 3 }, icollect(itail(avals({ 1, 2, 3 })))))
  assert(teq({}, icollect(itail(avals({ 3 })))))
end)

test("drop", function ()
  assert(teq({ 1, 2, 3, 4 }, icollect(idrop(0, avals({ 1, 2, 3, 4 })))))
  assert(teq({ 3, 4 }, icollect(idrop(2, avals({ 1, 2, 3, 4 })))))
  assert(teq({}, icollect(idrop(4, avals({ 1, 2, 3, 4 })))))
  assert(teq({}, icollect(idrop(5, avals({ 1, 2, 3, 4 })))))
  assert(teq({}, icollect(idrop(1, avals({})))))
  assert(teq({}, icollect(idrop(1, avals({ 3 })))))
end)

test("last", function ()
  assert(teq({ 4 }, { ilast(avals({ 1, 2, 3, 4 })) }))
  assert(teq({ 4 }, { ilast(avals({ 4 })) }))
  assert(teq({}, { ilast(avals({})) }))
end)

test("async", function ()
  local async = iasync(avals({ 1, 2, 3, 4 }))
  local called = 0
  local finished = false
  vtup(function (...)
    assert(teq({ ... }, { "hi" }))
  end, async(function (done, x)
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
  local async = iasync(avals({ 1, 2, 3, 4 }))
  local called = 0
  local finished = false
  vtup(function (...)
    assert(teq({ ... }, { "exit" }))
  end, async(function (done, x)
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

test("wrap", function ()
  local wrap = iwrap(avals({ "a", "b", "c", "d" }))
  assert(teq({ "a", "b", "c", "d" }, { wrap(), wrap(), wrap(), wrap() }))
end)






























































































































































































































































































































































































































































































