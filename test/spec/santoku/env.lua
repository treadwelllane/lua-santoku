local test = require("santoku.test")
local assert = require("luassert")
local env = require("santoku.env")

test("utils", function ()

  test("interpreter", function ()

























  end)

  test("env", function ()

    local ok, _ = pcall(env.var, "ASDF123")
    assert.equals(false, ok)

    local ok, val = pcall(env.var, "ASDF123", "hello")
    assert.equals(true, ok)
    assert.equals("hello", val)

  end)

end)
