local test = require("santoku.test")

local err = require("santoku.error")
local assert = err.assert
local error = err.error
local pcall = err.pcall

local validate = require("santoku.validate")
local eq = validate.isequal

local tbl = require("santoku.table")
local teq = tbl.equals

local arr = require("santoku.array")
local str = require("santoku.string")

test("errors carry as many values as you threw", function ()
  assert(teq({ false, "not found", 404 }, {
    pcall(function ()
      error("not found", 404)
    end)
  }))
  assert(teq({ true, "ok" }, {
    pcall(function ()
      return "ok"
    end)
  }))
end)

test("arrays are mutated in place, and returned", function ()
  local a = { 1 }
  assert(teq({ 1, 2, 3 }, arr.push(a, 2, 3)))
  assert(teq({ 1, 2, 3 }, a))
  assert(teq({ 2, 4, 6 }, arr.filter({ 1, 2, 3, 4, 5, 6 }, function (n)
    return (n % 2) == 0
  end)))
  assert(teq({ 1, 4, 10, 38 }, arr.sort({ 10, 38, 10, 10, 38, 1, 4 }, { unique = true })))
end)

test("reach into nested tables without guarding every step", function ()
  local obj = { a = { b = { 1, 2, { 3, 4 } } } }
  assert(teq({ 4 }, { tbl.get(obj, { "a", "b", 3, 2 }) }))
  assert(teq({}, { tbl.get(obj, { "a", "x", 3, 2 }) }))
end)

test("split and interpolate strings by name", function ()
  assert(teq({ "this", "is", "a", "test" }, str.splits("this is a test", "%s+")))
  assert(eq("Hello World, nice to meet you!",
    str.interp("Hello %who, %adj to meet you!", { who = "World", adj = "nice" })))
  assert(eq("1234.123", str.interp("%4.3f#(score)", { score = 1234.1234 })))
end)
