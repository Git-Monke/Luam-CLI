--   Uses POSIX form with no extra length file names

local IGNORE_DOTFILES = true

local DEFAULT_MODE = "000755 \0"

local UNAME = string.rep("\0", 32)
local GNAME = UNAME

local LINKNAME = string.rep("\0", 100)

local DEV_MAJOR = "000000 \0"
local DEV_MINOR = DEV_MAJOR

local UID = DEV_MAJOR
local GID = DEV_MINOR

local FLAG_FILE = "0"
local FLAG_DIR = "5"

local VERSION = "00"
local MAGIC = "ustar\0"
local EMPTY_CHECKSUM = string.rep(" ", 8)
local NULL_BLOCK = string.rep("\0", 512)

local function pad(string, length, char)
    char = char or "0"
    if #string >= length then return string end
    return string.rep(char, length - #string) .. string
end

local function padEnd(string, length, char)
    char = char or "0"
    if #string >= length then return string end
    return string .. string.rep(char, length - #string)
end

local function toOctal(number)
    return string.format("%o", number)
end

-- Returns the header checksum as an octal string
local function calcChecksum(header)
    local checksum = 0
    for char in string.gmatch(header, ".") do
        checksum = checksum + string.byte(char)
    end
    return string.format("%06s", toOctal(checksum)) .. "\0 "
end

local function constructHeader(dir, path)
    local filePath = dir .. "/" .. path
    assert(fs.exists(filePath), "The file path " .. filePath .. " does not exist")

    local flag = fs.isDir(filePath) and FLAG_DIR or FLAG_FILE
    local size = pad(toOctal(fs.getSize(filePath)), 11, 0) .. " "
    local mtime = pad(toOctal(os.date("%s")), 11) .. " "

    local name, prefix

    if #path > 100 then
        prefix = string.sub(path, 1, 155)
        name = padEnd(string.sub(path, 156, 255), 100, "\0")
    else
        name = padEnd(path, 100, "\0")
        prefix = string.rep("\0", 155)
    end

    local preChecksum = name ..
        DEFAULT_MODE ..
        UID ..
        GID ..
        size ..
        mtime

    local postChecksum = flag ..
        LINKNAME ..
        MAGIC ..
        VERSION ..
        UNAME ..
        GNAME ..
        DEV_MAJOR ..
        DEV_MINOR ..
        prefix

    local checksum = calcChecksum(preChecksum .. EMPTY_CHECKSUM .. postChecksum)

    return padEnd(preChecksum .. checksum .. postChecksum, 512, "\0")
end

local function writeHeader(header, tarWriter)
    for i = 1, #header do
        tarWriter.write(string.byte(header, i))
    end
end

local function encodeFile(dir, path, tarWriter)
    local filePath = dir .. "/" .. path
    assert(fs.exists(filePath))

    local header = constructHeader(dir, path)
    writeHeader(header, tarWriter)

    local size = fs.getSize(filePath)
    local padding = 0

    if not fs.isDir(filePath) then
        padding = 512 - (size % 512)
    end

    local reader = fs.open(filePath, "rb")

    for _ = 1, size do
        tarWriter.write(reader.read())
    end

    for _ = 1, padding do
        tarWriter.write(0)
    end
end

local function endArchive(tarWriter)
    for _ = 1, 1024 do
        tarWriter.write(0)
    end
    tarWriter.close()
end

local function includes(tabl, item)
    for _, other_item in ipairs(tabl) do
        if other_item == item then
            return true
        end
    end

    return false
end

local function tarifyRecursive(dir, currentPath, ignore_files, writer, writerPath)
    local absPath = dir .. "/" .. currentPath
    if includes(ignore_files, absPath) then
        return
    end

    if not fs.isDir(absPath) then
        encodeFile(dir, currentPath, writer)
        return
    else
        if #fs.list(absPath) == 0 then
            encodeFile(dir, currentPath, writer)
        end
    end

    for _, subDir in ipairs(fs.list(absPath)) do
        if (IGNORE_DOTFILES and string.sub(subDir, 1, 1) ~= ".") or (not IGNORE_DOTFILES) then
            local subPath = currentPath .. "/" .. subDir
            local subAbsPath = dir .. "/" .. subPath

            if fs.isDir(subAbsPath) then
                tarifyRecursive(dir, subPath, ignore_files, writer, writerPath)
            elseif subAbsPath ~= writerPath then
                if not includes(ignore_files, subAbsPath) then
                    encodeFile(dir, subPath, writer)
                end
            end
        end
    end
end

local function tar(path, out, ignore_files, writer)
    assert(path, "No path was provided")

    if out then
        assert(string.sub(out, -4) == ".tar", "Output file path must end with .tar!")
    end

    local dir, filename = string.match(path, "(.-)/([^/]+)$")

    dir = dir or ""
    filename = filename or path
    out = out or ("/" .. dir .. "/" .. filename .. ".tar")

    writer = writer or fs.open(out, "wb")

    tarifyRecursive(dir, filename, ignore_files, writer, out)
    endArchive(writer)
end

local function extract(header, start, _end)
    local substr = header:sub(start, _end):gsub("\0", "")
    substr = substr:gsub("^%s+", "")
    substr = substr:gsub("%s+$", "")
    return substr
end

local function parseHeader(header)
    local name = extract(header, 1, 100)
    local prefix = extract(header, 345, 500)
    local size = tonumber(extract(header, 124, 136), 8)
    local type = tonumber(extract(header, 156, 157))

    return name, prefix, size, type
end

local function reconstructFile(outPath, size, reader)
    local writer = fs.open(outPath, "wb")
    for _ = 1, size do
        writer.write(reader.read())
    end

    local padding = 512 - (size % 512)

    if padding ~= 512 then
        for _ = 1, padding do
            reader.read()
        end
    end

    writer.close()
end

local function untar(path, outPath)
    outPath = outPath or shell.dir()
    assert(fs.exists(path))
    assert(string.sub(path, -4) == ".tar", "File is not a tar file")
    assert(fs.getSize(path) % 512 == 0, "File size is not a multiple of 512. Invalid tar.")

    local reader = fs.open(path, "rb")

    for _ = 1, (fs.getSize(path) / 512) - 1 do
        local header = reader.read(512)

        if header == nil then
            return;
        end

        if header ~= NULL_BLOCK then
            local name, prefix, size, type = parseHeader(header)
            local newOutPath = outPath .. "/" .. (prefix and (prefix .. name) or name)

            if type == 5 then
                fs.makeDir(newOutPath)
            else
                if not fs.exists(newOutPath) then
                    reconstructFile(newOutPath, size, reader)
                else
                    for i = 1, 512 do
                        reader.read()
                    end
                end
            end
        end
    end
end

local Tar = {
    tar = tar,
    untar = untar
}

return Tar
