local tbl = require("santoku.table")
local capi = require("santoku.utc.capi")
return tbl.merge({
  stopwatch = function ()
    local start = capi.time(true)
    local last = start
    return function ()
      local now = capi.time(true)
      local total = now - start
      local duration = now - last
      last = now
      return duration, total
    end
  end,





  ticktock = function ()
    local start = capi.time(true)
    local stats = {}
    return function (name)
      if name == nil then
        return stats, capi.time(true) - start
      end
      local t0 = capi.time(true)
      return function ()
        local dur = capi.time(true) - t0
        local e = stats[name]
        if not e then e = { time = 0, count = 0 }; stats[name] = e end
        e.time = e.time + dur
        e.count = e.count + 1
        return dur
      end
    end
  end
}, capi)
