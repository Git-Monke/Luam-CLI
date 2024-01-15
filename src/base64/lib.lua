local charString = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local charTable = {}
local inverseCharTable = {}

for i = 1, #charString do
    local char = charString:sub(i, i)
    charTable[i] = char
    inverseCharTable[char] = i - 1
end

local blshift, brshift, band = bit.blshift, bit.blogic_rshift, bit.band

local function bytesToChars(a, b, c)
    assert(a, "At least one input byte required")
    local octs = not b and 1 or not c and 2 or 3
    b = b or 0
    c = c or 0
    local sextets = blshift(a, 16) + blshift(b, 8) + c
    local out = ""
    for i = 3, 3 - octs, -1 do
        -- 0x3f = 00111111 (first 6 bits)
        out = out .. charTable[1 + tonumber(band(brshift(sextets, i * 6), 0x3f))]
    end
    out = out .. string.rep("=", 3 - octs)
    return out;
end

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

local function encodeFile(path)
    assert(fs.exists(path), 'File does not exist')
    local reader = fs.open(path, "rb")
    local out = ""
    for _ = 1, fs.getSize(path), 3 do
        local a, b, c = reader.read(), reader.read(), reader.read()
        out = out .. bytesToChars(a, b, c)
    end
    return out
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

local Base64 = {
    encodeFile = encodeFile,
    decodeFile = decodeFile
}

return Base64
