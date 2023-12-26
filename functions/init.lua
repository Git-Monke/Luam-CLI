require "functions.json"

local function init(args)
    local wkdir = shell.dir()

    print("Package name: ")
    local name = io.read()

    print("Confirm creation (y/n): ")
    local confirmation = io.read()

    if confirmation ~= "y" then
        return "Package initialization aborted"
    end

    local package_json_path = fs.combine(wkdir, "package.json")

    if fs.exists(package_json_path) then
        return "Package has already been initialized."
    end

    local writer = fs.open(package_json_path, "w")
    local default_package_structure = {
        name = name,
        version = "0.1.0",
        dependencies = {}
    }
    writer.write(encodePretty(default_package_structure))

    return string.format("Package %s has been initialized", name)
end

return init
