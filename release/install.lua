local a = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local b = {}
for c = 1, #a do
    local d = a:sub(c, c)
    b[d] = c - 1
end; local e, f, g = bit.blshift, bit.blogic_rshift, bit.band; local function h(i)
    assert(#i == 4, "Chars must be of length 4")
    local j = #i:gsub("[^=]", "")
    local k = i:gsub("=", "A")
    local l = 0; local m = {}
    for c = 1, 4 do l = l + e(b[k:sub(c, c)], 24 - c * 6) end; for c = 1, 3 do m[c] = g(f(l, 24 - c * 8), 0xff) end; return
        m, j
end; local function n(o, p)
    assert(#o % 4 == 0, "Coded string should be a multiple of 4")
    local q = fs.open(p, "wb")
    for c = 1, #o, 4 do
        local r, j = h(o:sub(c, c + 3))
        for s = 1, 3 - j do q.write(r[s]) end
    end; q.close()
end; local t = "Git-Monke"
local u = "Luam-CLI"
local v = "release/luam.lua"
local w = string.format("https://api.github.com/repos/%s/%s/contents/%s", t, u, v)
local x = http.get(w)
if x then
    local y = x.readAll()
    x.close()
    local z = textutils.unserializeJSON(y)
    if z and z.content then
        local A = z.content:gsub("%\n", "")
        n(A, "luam.lua")
    else
        print("Error: Unable to parse GitHub response.")
    end
else
    print("Error: Unable to fetch file from GitHub.")
end; local B = 'shell.setPath(shell.path() .. ":" .. "/")'
local C = 'shell.setPath%(shell.path%(%) %.. ":" .. "/"%)'
C = C:gsub("([%(%)%.])", "%%%1")
local D = fs.open("startup.lua", "r")
local E = D and D.readAll()
if not E or E and not E:find(C) then
    shell.setPath(shell.path() .. ":" .. "/")
    local q = fs.open("startup.lua", "w")
    q.write("\n" .. B)
    q.close()
    print("Luam has been installed successfully!")
    print("Run luam help for information about usage")
end
