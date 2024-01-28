local iter = require("santoku.iter")
local imap = iter.map
local icollect = iter.collect
local ihead = iter.head

local arr = require("santoku.array")
local acat = arr.concat
local apush = arr.push

local base = require("santoku.string.base")
local snumber = base.number

local find = string.find
local sub = string.sub
local format = string.format



local function _match (pat, delim, invert)
  local ds, de
  return function (str, pos)
    if str and pos <= #str then
      local s, e
      if ds and invert then
        s, e = ds, de
        ds, de = nil, nil
        return pos, str, s, e
      elseif ds then
        s, e = ds, de
        ds, de = nil, nil
        return pos, str, pos, e + 1
      end
      s, e = find(str, pat, pos)
      if delim == true and not ds then
        ds, de = s, e
      end
      if s ~= nil then
        if invert then
          return e + 1, str, pos, s - 1
        else
          return e + 1, str, s, e
        end
      else
        if invert then
          return #str + 1, str, pos, #str
        end
      end
    elseif invert and delim == true and ds then
      s, e = ds, de
      ds, de = nil, nil
      return #str + 1, str, s, e
    end
  end
end

local function split (str, pat, delim)
  return _match(pat, delim, true), str, 1
end

local function match (str, pat, delim)
  return _match(pat, delim, false), str, 1
end










local function interp (s, t)

  local fmtpat = "%%[%w.]+"
  local keypat = "^#%b()"

  local segments = icollect(imap(sub, split(s, fmtpat, true)))
  local out = {}

  for i = 1, #segments do

    local s = segments[i]

    if not ihead(match(s, fmtpat)) then

      apush(out, s)

    else

      local fmt = s
      local key = i <= #segments and ihead(match(segments[i + 1], keypat))

      if key then
        segments[i + 1] = sub(segments[i + 1], #key + 1)
        key = sub(key, 3, #key - 1)
      else
        key = sub(fmt, 2)
        fmt = nil
      end

      local nkey = tonumber(key)
      local result

      if nkey and not t[key] then
        result = t[nkey] or ""
      else
        result = t[key] or ""
      end

      apush(out, fmt and format(fmt, result) or result)

    end

  end

  return acat(out)

end

return {
  split = split,
  match = match,
  sub = sub,
  find = find,
  format = format,
  number = snumber,
  interp = interp,
}

































































































































































