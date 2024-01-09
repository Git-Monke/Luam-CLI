local download_file = require "functions.install.downloadFile"
require "functions.json"
local function install(args)
    local name = args[2]
    local version = args[3]

    local wkdir = shell.dir()
    local package_path = fs.combine(wkdir, "package.json")

    local package_json = {}

    if fs.exists(package_path) then
        package_json = decodeFromFile(package_path)
    end

    local served_version = download_file(name, version)

    if not package_json.dependencies then
        package_json.dependencies = {}
    end

    package_json.dependencies[args[2]] = "^" .. served_version
    local package_json_writer = fs.open(package_path, "w")
    package_json_writer.write(encodePretty(package_json))
end

return install
