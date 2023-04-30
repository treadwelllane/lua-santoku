local template = require("santoku.template")
local vec = require("santoku.vector")
local fs = require("santoku.fs")

describe("template", function ()

  it("should compile a template string", function ()
    local ok, tpl = template("<title><%render% return title %></title>")
    assert(ok, tpl)
    local ok, str = tpl:render({ title = "Hello, World!" })
    assert(ok, str)
    assert.same(str, "<title>Hello, World!</title>")
  end)

  it("should allow custom delimiters", function ()
    local ok, tpl = template("<title>{{ return title }}</title>", { open = "{{", close = "}}" })
    assert(ok, tpl)
    local ok, str = tpl:render({ title = "Hello, World!" })
    assert(ok, str)
    assert.same(str, "<title>Hello, World!</title>")
  end)

  it("should handle multiple replacements", function ()
    local ok, tpl = template("<title><% return title %> <% return title %></title>")
    assert(ok, tpl)
    local ok, str = tpl:render({ title = "Hello, World!" })
    assert(ok, str)
    assert.same(str, "<title>Hello, World! Hello, World!</title>")
  end)

  it("should handle multiple replacements", function ()
    local ok, tpl = template("<%compile% a = check(template:compilefile('test/spec/santoku/template/title.html')) %><title><% return check(a:render()) %></title>")
    assert(ok, tpl)
    assert.same(tpl.deps, vec("test/spec/santoku/template/title.html"))
    local ok, str = tpl:render({ title = "Hello, World!" })
    assert(ok, str)
    assert.same(str, "<title>Hello, World!</title>")
  end)

  it("should support sharing fenv to child templates", function ()
    local ok, tpl = template("<% title = 'Hello, World!' %><title><% return check(check(template:compilefile('test/spec/santoku/template/title.html')):render()) %></title>")
    assert(ok, tpl)
    local ok, str = tpl:render({ title = "Hello, World!" })
    assert(ok, str)
    assert.same(str, "<title>Hello, World!</title>")
  end)

  it("should handle whitespace between blocks", function ()
    local ok, tpl = template("<title><% return check(check(template:compilefile('test/spec/santoku/template/title.html')):render()) %> <% return check(check(template:compilefile('test/spec/santoku/template/name.html')):render()) %></title>")
    assert(ok, tpl)
    local ok, str = tpl:render({
      title = "Hello, World!",
      name = "123"
    })
    assert(ok, str)
    assert.same(str, "<title>Hello, World! 123</title>")
  end)

  it("should support multiple nesting levels ", function ()
    local ok, tpl = template("<title><% return check(check(template:compilefile('test/spec/santoku/template/titles.html')):render()) %></title>")
    assert(ok, tpl)
    local ok, str = tpl:render({
      title = "Hello, World!",
      name = "123"
    })
    assert(ok, str)
    assert.same(str, "<title>Hello, World! 123</title>")
  end)

  it("should support multiple templates", function ()
    local ok, tpl = template("<%compile% a, b = check(template:compilefile('test/spec/santoku/template/title.html')), check(template:compilefile('test/spec/santoku/template/titles.html')) %><title><% return check(a:render()) %> <% return check(b:render()) %></title>")
    assert(ok, tpl)
    assert.same(tpl.deps, vec("test/spec/santoku/template/title.html", "test/spec/santoku/template/titles.html"))
    local ok, str = tpl:render({
      title = "Hello, World!",
      name = "123"
    })
    assert(ok, str)
    assert.same(str, "<title>Hello, World! Hello, World! 123</title>")
  end)

  it("should support multiple templates (again)", function ()
    local ok, getconfig = fs.loadfile("test/spec/santoku/template/config.lua")
    assert(ok, getconfig)
    local config = getconfig()
    local ok, data = fs.readfile("test/spec/santoku/template/index.html")
    assert(ok, data)
    local ok, tpl = template(data, config)
    assert(ok, tpl)
    local ok, str = tpl()
    assert(ok, str)
  end)

  -- TODO: Handle indentation
  it("should handle trailing characters", function ()
    local ok, tpl = template([[
      <template
        data-api="/api/ping"
        data-method="get"
        <% return "\n", gen.pairs(redirects)
            :map(function (status, redirect)
              return string.format("data-handler-%d=\"redirect:%s\"", status, redirect)
            end)
            :concat("\n") %>>
      </template>
    ]])
    assert(ok, tpl)
    local ok, str = tpl:render({
      gen = require("santoku.gen"),
      string = string,
      redirects = { [403] = "/login" }
    })
    assert(ok, str)
    assert.same([[
      <template
        data-api="/api/ping"
        data-method="get"
data-handler-403="redirect:/login">
      </template>
    ]], str) -- TODO: Should this ']]' be hanging?
  end)

  -- TODO: Handle indentation
  it("should allow multiple compile-time functions", function ()
    local ok, tpl = template([[
      <%compile% return title %>
      <%compile% return name %>
      <% return "!" %>
    ]], {
      env = {
        title = "Hello",
        name = "World"
      }
    })
    assert(ok, tpl)
    local ok, str = tpl:render()
    assert(ok, str)
    assert.same([[
      HelloWorld!
    ]], str)
  end)

end)
