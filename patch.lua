local function read_file(src)
    local f = assert(io.open(src, "r"), "No such a file or directory - " .. src)
    local result = f:read("a*")
    f:close()
    return result
 end
 
 local function write_file(dst, content)
    local f = assert(io.open(dst, "w"), "No such a file or directory - " .. dst)
    f:write(content)
    f:close()
 end

-- common.c
_common_c = read_file("common.c")

_s = 1
_matches = {}
_noopId = 0

while true do
    local _first, _last = _common_c:find("fetch_ssl.-%(.-%).-{", _s)
    if _first == nil then
        break
    end

    local _leftBrackets = 1
    local _shift = 1
    while _leftBrackets > 0 do
        local c = _common_c:sub(_last + _shift, _last + _shift)
        if c == "{" then
            _leftBrackets = _leftBrackets + 1
        elseif c == "}" then
            _leftBrackets = _leftBrackets - 1
        end
        _shift = _shift + 1
    end

    _common_c = _common_c:sub(1, _first) .. "_noop" .. _noopId .. "(){}\n" .. _common_c:sub(_last + _shift)
    _s = _first
    _noopId = _noopId + 1
end

write_file("common.c", _common_c)

-- common.h
_common_h = read_file("common.h")
_common_h, matched = _common_h:gsub('#include "openssl%-compat%.h"', '#include "mbedtls-compat.h"')
if matched == 0 and not _common_h:find('#include "mbedtls-compat.h"', 1, true) then 
    error("Unrecoverable libfetch common.h code change!")
end
write_file("common.h", _common_h)

-- http.c
_http_c = read_file("http.c")
if not _http_c:find('#include "mbedtls.h"', 1, true) then 
    _http_c, matched = _http_c:gsub('#include "common%.h"\n', '#include "common.h"\n#include "mbedtls.h"\n')
    if matched == 0 and not _http_c:find('#include "mbedtls.h"', 1, true) then 
        error("Unrecoverable libfetch http.c code change!")
    end
end

_http_c, matched = _http_c:gsub('fetch_ssl%(conn, URL, verbose%)', "fetch_mbedtls(conn, URL, verbose, CHECK_FLAG('p'))")
if matched == 0 and not _http_c:find("fetch_mbedtls(conn, URL, verbose, CHECK_FLAG('p'))", 1, true) then 
    error("Unrecoverable libfetch http.c 2 code change!")
end

while true do 
    _varStart, _varEnd = _http_c:find('%S* = strdupa')
    if _varStart == nil then
        break
    end
    _var = _http_c:match('(%S*) = strdupa%(.*%)', _varStart)
    _http_c = _http_c:sub(1, _varStart - 1) .. _var .. " = strdup" .. _http_c:sub(_varEnd + 1) 



    -- locate end of scope
    local _leftBrackets = 1
    local _shift = 1
    while _leftBrackets > 0 do
        local c = _http_c:sub(_varEnd + _shift, _varEnd + _shift)
        if c == "{" then
            _leftBrackets = _leftBrackets + 1
        elseif c == "}" then
            _leftBrackets = _leftBrackets - 1
        end
        _shift = _shift + 1
    end

    -- locate last call
    _lastEnd = _varEnd
    while true do 
        local _varStart, _varEnd = _http_c:find("%W" .. _var .. "%W", _lastEnd)
        if _varStart == nil or _varStart > _varEnd + _shift - 2 then 
            break
        end
        _lastEnd = _varEnd
    end

    _shift = 1
    while true do
        local c = _http_c:sub(_lastEnd + _shift, _lastEnd + _shift)
        _shift = _shift + 1
        if c == "\n" then
            break
        end
    end

    -- inject free
    _http_c = _http_c:sub(1, _lastEnd + _shift) .. "free(" .. _var .. ");\n" .. _http_c:sub(_lastEnd + _shift + 1) 
end

write_file("http.c", _http_c)

os.execute("rm -f openssl-compat.c")
os.execute("rm -f openssl-compat.h")

ls = io.popen("ls -1 *.errors")
files = ls:read("a*")

for s in files:gmatch("[^\r\n]+") do
    name = s:match("(%S-)%.errors")
    os.execute("sh errlist.sh " .. name .. "_errlist " .. name .. " " .. s .. " > " .. name .. "err.h")
end