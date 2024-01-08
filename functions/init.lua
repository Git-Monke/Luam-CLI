require "functions.json"

local function init(args)
    local wkdir = shell.dir()

    print("Create new directory or initialize in current directory? (y/n)")
    local create_in_new_dir = io.read() == "y"
    local name = shell.dir():match("([^/]+)$")

    if create_in_new_dir then
        print("Package name: ")
        name = io.read()
        wkdir = fs.combine(wkdir, name)
    end

    local package_json_path = fs.combine(wkdir, "package.json")

    if fs.exists(package_json_path) then
        print("Package has already been initialized. Write over existing information? (y/n)")

        local result = io.read()
        if result ~= "y" then
            return "Project initalization aborted"
        end
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
