require "functions.json"

local function init(args)
    local wkdir = shell.dir()

    if args[2] then
        wkdir = wkdir .. "/" .. args[2]
    end

    local package_json_path = fs.combine(wkdir, "package.json")
    local package_json = {}

    if fs.exists(package_json_path) then
        package_json = decodeFromFile(package_json_path)
    end

    if package_json["name"] then
        print("Package has already been initialized")
    end

    local name = args[2] or wkdir:match("([^/]+)$")
    local writer = fs.open(package_json_path, "w")

    package_json["name"] = name
    package_json["version"] = "0.1.0"
    package_json["dependencies"] = package_json["dependencies"] or {}

    writer.write(encodePretty(package_json))

    local ignore_writer = fs.open(fs.combine(wkdir, ".luamignore"), "w")
    ignore_writer.write("luam_modules\n")
    ignore_writer.write("package-lock.json")

    return string.format("Package %s has been initialized", name)
end

return init
