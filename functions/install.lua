local download_file = require "functions.install.downloadFile"

local function install(args)
    print(string.format("Fetching %s %s", args[2], args[3]))
    download_file(args[2], args[3])
end

return install
