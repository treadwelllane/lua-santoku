







local err = require("santoku.err")
local vec = require("santoku.vector")
local gen = require("santoku.gen")





local M = {}














M.match = function (str, pat, n)
  assert(type(pat) == "string")
  assert(type(str) == "string")
  local t = vec()
  for tok in str:gmatch(pat) do
    t:append(tok)
		if n and t.n == n then
			break
		end
  end
  return t
end




















M.split = function (str, pat, opts)
  opts = opts or {}
  pat = pat or "%s+"
  local delim = opts.delim or false
  local n = 1
  local ls = 1
  local stop = false
  local ret = vec()
  while not stop do
    local s, e = str:find(pat, n)
    stop = s == nil
    if stop then
      s = #str + 1
    end
    if delim == true then
      ret:append(str:sub(n, s - 1))
      if not stop then
        ret:append(str:sub(s, e))
      end
    elseif delim == "left" then
      ret:append(str:sub(n, e))
    elseif delim == "right" then
      ret:append(str:sub(ls, s - 1))
    else
      ret:append(str:sub(n, s - 1))
    end
    if stop then
      break
    else
      ls = s
      n = e + 1
    end
  end
  return ret
end

M.quote = function (s, q, e)
  q = q or "\""
  e = e or "\\"
  assert(type(s) == "string")
  assert(type(q) == "string")
  assert(type(e) == "string")
  return table.concat({ q, (s:gsub(q, e .. q)), q })
end

M.unquote = function (s, q, e)
  q = q or "\""
  e = e or "\\"
  assert(type(s) == "string")
  assert(type(q) == "string")
  assert(type(e) == "string")
  if M.startswith(s, q) and M.endswith(s, q) then
    local slen = s:len()
    local qlen = q:len()
    return (s:sub(1 + qlen, slen - qlen):gsub(e .. q, q))
  else
    return s
  end
end


M.escape = function (s)
  return (s:gsub("[%(%)%.%%+%-%*%?%[%]%^%$]", "%%%1"))
end


M.unescape = function (s)
  return (s:gsub("%%([%(%)%.%%+%-%*%?%[%]%^%$])", "%1"))
end

M.printf = function (s, ...)
  return io.write(s:format(...))
end

M.printi = function (s, t)
  return print(M.interp(s, t))
end







M.interp = function (s, t)

  local fmtpat = "%%[%w.]+"
  local keypat = "^#%b()"

  local segments = M.split(s, fmtpat, { delim = true })

  return gen.ipairs(segments):map(function (i, s)

    if not s:match(fmtpat) then
      return s
    end

    local format = s
    local key = i <= segments.n and segments[i + 1]:match(keypat)

    if key then
      segments[i + 1] = segments[i + 1]:sub(#key + 1)
      key = key:sub(3, #key - 1)
    else
      key = format:sub(2)
      format = nil
    end

    local nkey = tonumber(key)
    local result

    if nkey and not t[key] then
      result = t[nkey] or ""
    else
      result = t[key] or ""
    end

    return format and string.format(format, result) or result

  end):concat()

end

M.parse = function (s, pat)
  local keys = vec()
  pat = pat:gsub("%b()#%b()", function (k)
    local fmt = k:match("%b()")
    local key = k:sub(#fmt + 2)
    key = key:sub(2, #key - 1)
    keys:append(key)
    return fmt
  end)
  local vals = vec.pack(string.match(s, pat))
  return gen.ivals(keys):co():zip(gen.ivals(vals):co()):tabulate()
end






M.indent = function (s, opts) -- luacheck: ignore
  err.unimplemented("indent")
end






M.trim = function (s, opts)
  local left = "%s*"
  local right = "%s*"
  if opts == nil then -- luacheck: ignore

  elseif type(opts) == "string" then
    left = opts
    right = opts
  elseif type(opts) == "table" then
    left = opts.left or left
    right = opts.right or right
  else
    error("unexpected options argument: " .. type(opts))
  end
  if left ~= false then
    s = s:gsub("^" .. left, "")
  end
  if right ~= false then
    s = s:gsub(right  .. "$", "")
  end
  return s
end

M.isempty = function (s)
  if s == nil or s:match("^%s*$") then
    return true
  else
    return false
  end
end

M.endswith = function (str, pat)
  if str ~= nil and str:match(pat .. "$") then
    return true
  else
    return false
  end
end

M.startswith = function (str, pat)
  if str ~= nil and str:match("^" .. pat) then
    return true
  else
    return false
  end
end

M.stripprefix = function (str, pfx)
  if not M.startswith(str, M.escape(pfx)) then
    return str
  end
  local pfxlen = pfx:len()
  local strlen = str:len()
  return str:sub(pfxlen + 1, strlen)
end



M.commonprefix = function (...)
  local strList = { ... }
  local shortest, prefix, first = math.huge, ""
  for _, str in pairs(strList) do
    if str:len() < shortest then shortest = str:len() end
  end
  for strPos = 1, shortest do
    if strList[1] then
      first = strList[1]:sub(strPos, strPos)
    else
      return prefix
    end
    for listPos = 2, #strList do
      if strList[listPos]:sub(strPos, strPos) ~= first then
        return prefix
      end
    end
    prefix = prefix .. first
  end
  return prefix
end

return M










