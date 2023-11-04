local test = require("santoku.test")
local assert = require("luassert")
local env = require("santoku.env")

test("utils", function ()

  test("interpreter", function ()

    -- TODO: This is test is basically just
    -- reimplementing the function. We should
    -- use os.execute or something to actually
    -- invoke a program that calls this and
    -- check the return value
    -- it("should return the interpreter", function ()
    --   local min = 0
    --   local i = 0
    --   while true do
    --     i = i - 1
    --     if arg[i] ~= nil then
    --       min = i
    --     else
    --       break
    --     end
    --   end
    --   local vals = env.interpreter(true)
    --   local j = 1
    --   for i = min, #vals do
    --     assert.equals(vals[j], arg[i])
    --     j = j + 1
    --   end
    -- end)

  end)

  test("env", function ()

    local ok, _ = pcall(env.var, "ASDF123")
    assert.equals(false, ok)

    local ok, val = pcall(env.var, "ASDF123", "hello")
    assert.equals(true, ok)
    assert.equals("hello", val)

  end)

end)
