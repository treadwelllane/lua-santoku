local assert = require("luassert")
local test = require("santoku.test")
local sys = require("santoku.system")

local bundle = require("santoku.bundle")
local fs = require("santoku.fs")
local err = require("santoku.err")

test("bundle", function ()

  test("bundle", function ()

    test("should produce a standalone executable from a lua file", function ()
      local infile = "test/res/bundle/test.lua"
      local outdir = "test/res/bundle/test"
      assert(err.pwrap(function (check)
        check(fs.mkdirp(outdir))
        fs.files(outdir):map(check):map(os.remove):each(check)
        check(bundle(infile, outdir, {
          cflags = "-I" .. check(sys.sh("luarocks config variables.LUA_INCDIR")):co():head(),
          ldflags = "-L" .. check(sys.sh("luarocks config variables.LUA_LIBDIR")):co():head() .. " -llua -lm",
        }))
        assert(check(fs.exists(fs.join(outdir, "test.lua"))))
        assert(check(fs.exists(fs.join(outdir, "test.luac"))))
        assert(check(fs.exists(fs.join(outdir, "test.h"))))
        assert(check(fs.exists(fs.join(outdir, "test.c"))))
        assert(check(fs.exists(fs.join(outdir, "test"))))
      end))
    end)

  end)

end)
