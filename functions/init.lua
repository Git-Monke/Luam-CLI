require "functions.json"

local function init(args)
    local wkdir = shell.dir()

    if args[2] then
        wkdir = wkdir .. "/" .. args[2]
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
        name = args[2] or "",
        version = "0.1.0",
        dependencies = {}
    }
    writer.write(encodePretty(default_package_structure))

    local ignore_writer = fs.open(fs.combine(wkdir, ".luamignore"), "w")
    ignore_writer.write("luam_modules\n")
    ignore_writer.write("package-lock.json")

    return string.format("Package %s has been initialized", name)
end

return init
