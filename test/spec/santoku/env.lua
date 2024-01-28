local test = require("santoku.test")
local env = require("santoku.env")

test("interpreter", function ()

























end)

test("env", function ()

  local ok, _ = pcall(env.var, "ASDF123")
  assert(false == ok)

  local ok, val = pcall(env.var, "ASDF123", "hello")
  assert(true == ok)
  assert("hello" == val)

  local ok, val = pcall(env.var, "ASDF123", nil)
  assert(true == ok)
  assert(nil == val)

end)
