<p align="center">
  <img src="https://santoku.dev/logo-santoku.png" height="64" alt="santoku">
</p>

# santoku

The base library the rest of the santoku ecosystem is built on. Arrays and tables that
mutate in place, errors that carry more than a string, string splitting and named
interpolation, continuation-passing async, validation, serialization, UTC time, random
numbers, benchmarking, tracing, and a tiny test harness.

## Install

```sh
luarocks install santoku
```

## Example

```lua
local err = require("santoku.error")
local arr = require("santoku.array")
local str = require("santoku.string")

local ok, msg, code = err.pcall(function ()
  err.error("not found", 404)
end)

print(ok, msg, code)

print(str.interp("%who has %(count) items", {
  who = "Ada",
  count = #arr.filter({ 1, 2, 3, 4 }, function (n) return n % 2 == 0 end)
}))
```

Array functions mutate and return the same table, so pipelines allocate nothing extra.

## Documentation

Runnable examples and the full API: [santoku.dev](https://santoku.dev/#santoku).

For agents and LLM tooling: [llms.txt](https://santoku.dev/llms.txt) for the index,
[llms-full.txt](https://santoku.dev/llms-full.txt) for every documented example.

## Tests

The tests are the spec, one file per module, under
[`test/spec/santoku`](test/spec/santoku): [`array.lua`](test/spec/santoku/array.lua),
[`table.lua`](test/spec/santoku/table.lua), [`string.lua`](test/spec/santoku/string.lua),
[`error.lua`](test/spec/santoku/error.lua), [`async.lua`](test/spec/santoku/async.lua),
[`validate.lua`](test/spec/santoku/validate.lua),
[`serialize.lua`](test/spec/santoku/serialize.lua), and the rest beside them.

## License

MIT, see [LICENSE](LICENSE).

## More examples

```lua
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
```
