local charString = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local inverseCharTable = {}

for i = 1, #charString do
    local char = charString:sub(i, i)
    inverseCharTable[char] = i - 1
end

local blshift, brshift, band = bit.blshift, bit.blogic_rshift, bit.band

local function charsToBytes(chars)
    assert(#chars == 4, "Chars must be of length 4")
    local padding = #chars:gsub("[^=]", "")
    local data = chars:gsub("=", "A")
    local bin = 0
    local out = {}
    for i = 1, 4 do
        bin = bin + blshift(inverseCharTable[data:sub(i, i)], 24 - i * 6)
    end
    for i = 1, 3 do
        out[i] = band(brshift(bin, 24 - i * 8), 0xff)
    end
    return out, padding
end

local function decodeFile(codedString, outPath)
    assert(#codedString % 4 == 0, "Coded string should be a multiple of 4")
    local writer = fs.open(outPath, "wb")
    for i = 1, #codedString, 4 do
        local bytes, padding = charsToBytes(codedString:sub(i, i + 3))
        for j = 1, 3 - padding do
            writer.write(bytes[j])
        end
    end
    writer.close()
end

local owner = "Git-Monke"
local repo = "Luam-CLI"
local path = "prod/luam.lua"

local url = string.format("https://api.github.com/repos/%s/%s/contents/%s", owner, repo, path)

local response = http.get(url)
if response then
    local content = response.readAll()
    response.close()

    local decodedContent = textutils.unserializeJSON(content)
    if decodedContent and decodedContent.content then
        local fileContent = decodedContent.content:gsub("%\n", "")
        decodeFile(fileContent, "luam.lua")
    else
        print("Error: Unable to parse GitHub response.")
    end
else
    print("Error: Unable to fetch file from GitHub.")
end
