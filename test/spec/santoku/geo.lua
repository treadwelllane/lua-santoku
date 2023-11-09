local assert = require("luassert")
local test = require("santoku.test")

local geo = require("santoku.geo")
local num = require("santoku.num")

test("geo", function ()

  test("distance", function ()
    assert.equals(2, geo.distance({ x = 0, y = 0 }, { x = 0, y = 2 }))
    assert.equals(2, geo.distance({ x = 0, y = 0 }, { x = 2, y = 0 }))
    assert.equals(2 * math.sqrt(2), geo.distance({ x = 0, y = 0 }, { x = 2, y = 2 }))
  end)








  test("angle", function ()
    assert.equals(45, geo.angle({ x = 0, y = 0 }, { x = 2, y = 2 }))
    assert.equals(315, geo.angle({ x = 0, y = 0 }, { x = -2, y = 2 }))
    assert.equals(0, geo.angle({ x = 0, y = 0 }, { x = 0, y = 2 }))
    assert.equals(180, geo.angle({ x = 0, y = 0 }, { x = 0, y = -2 }))
    assert.equals(90, geo.angle({ x = -2, y = 4 }, { x = 0, y = 4 }))
  end)

  test("bearing", function ()
    assert.equals(90, geo.bearing({ lat = 0, lon = 0 }, { lat = 0, lon = -90 }))
  end)




  test("rotate", function ()
    local p
    p = geo.rotate({ x = 0, y = 2 }, { x = 0, y = 0 }, 90)
    p.x = num.trunc(p.x, 8)
    p.y = num.trunc(p.y, 8)
    assert.same({ x = 2, y = 0 }, p)
    p = geo.rotate({ x = 0, y = 2 }, { x = 0, y = 4 }, 90)
    p.x = num.trunc(p.x, 8)
    p.y = num.trunc(p.y, 8)
    assert.same({ x = -2, y = 4 }, p)
  end)

end)
