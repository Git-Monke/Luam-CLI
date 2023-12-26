local Tar = require("tar.lib")
local Base64 = require("base64.lib")

local function encodeFile(path)
    assert(fs.exists(path), "File does not exist!")
    local outputPath = "temp-" .. math.floor(1000 * math.random()) .. ".tar"
    Tar.tar(path, outputPath)
    local code = Base64.encodeFile(outputPath)
    fs.delete(outputPath)
    return code
end

return encodeFile
