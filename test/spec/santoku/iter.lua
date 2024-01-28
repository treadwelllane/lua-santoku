local test = require("santoku.test")

local fun = require("santoku.functional")
local fbindr = fun.bindr

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
local ifilter = iter.filter
local ieach = iter.each
local ireduce = iter.reduce
local imap = iter.map
local iasync = iter.async
local iwrap = iter.wrap

local tbl = require("santoku.table")
local teq = tbl.equals

test("akeys", function ()
  assert(teq({ 1, 2, 3, 4 }, icollect(akeys({ "a", "b", "c", "d", a = 1, b = 2 }))))
end)

test("avals", function ()
  assert(teq({ "a", "b", "c", "d" }, icollect(avals({ "a", "b", "c", "d", a = 1, b = 2 }))))
end)

test("tkeys", function ()
  assert(teq({ "2", "a", "b" }, asort(icollect(imap(tostring, tkeys({ a = 2, [2] = 4, b = 6 }))))))
end)

test("tvals", function ()
  assert(teq({ 2, 4, 6 }, asort(icollect(tvals({ a = 2, [2] = 4, b = 6 })))))
end)

test("map", function ()
  assert(teq({ 2, 3, 4, 5 }, icollect(imap(fbindr(oadd, 1), avals({ 1, 2, 3, 4 })))))
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






























































































































































































































































































































































































































































































