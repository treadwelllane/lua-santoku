local tup = require("santoku.tuple")

describe("tuple", function ()

  it("stores varargs", function ()

    local tup, m = tup(1, 2, 3)
    assert(m == 3)

    local a, b, c = tup()
    assert.equals(1, a)
    assert.equals(2, b)
    assert.equals(3, c)

  end)

  it("allows append", function ()

    local tup, m = tup(1)
    assert(m == 1)

    local a, b, c = tup(2, 3)
    assert.equals(1, a)
    assert.equals(2, b)
    assert.equals(3, c)

  end)

end)
