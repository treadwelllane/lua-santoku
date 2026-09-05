local test = require("santoku.test")
local op = require("santoku.op")
local num = require("santoku.num")

test("call", function ()
  assert(5, op.add(3, 2))
  assert(5, op.call(num.min, 5, 10))
end)
