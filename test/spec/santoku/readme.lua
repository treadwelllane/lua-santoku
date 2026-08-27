local test = require("santoku.test")

local anchor = "test/spec/santoku/readme_anchor.lua"

local function readfile (fp)
  local fh = io.open(fp, "r")
  if not fh then
    return nil
  end
  local data = fh:read("*a")
  fh:close()
  return data
end

test("README reproduces the anchor spec verbatim", function ()
  local readme = readfile("README.md")
  assert(readme,
    "README.md not found beside the test tree: " ..
    "santoku-make copies it in from 3.7.0 onward, check the installed version")
  local spec = readfile(anchor)
  assert(spec, "anchor spec not found: " .. anchor)
  assert(string.find(readme, "```lua\n" .. spec .. "```", 1, true) ~= nil,
    "README.md drifted from " .. anchor ..
    ": the README must contain the anchor spec verbatim inside a ```lua fence, " ..
    "update one or the other so they match, then rerun toku test")
end)
