local download_file = require "functions.install.downloadFile"
local delete = require "functions.delete"
require "functions.json"

local function install(args)
    local name = args[2]
    local version = args[3]

    if not name then
        return "A name must be provided in order to add a package"
    end

    local wkdir = shell.dir()
    local package_path = fs.combine(wkdir, "package.json")

    local package_json = {}

    if fs.exists(package_path) then
        package_json = decodeFromFile(package_path)
    end

    if package_json and package_json.dependencies and package_json.dependencies[name] then
        delete({ 0, name })
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
