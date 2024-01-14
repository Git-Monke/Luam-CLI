require "functions.json"
require "functions.delete.deletePackage"

local deletePackage = require "functions.delete.deletePackage"

local function delete(args)
    local wkdir = shell.dir()
    local package_to_delete = args[2]
    -- If they didn't include a package, no need to delete
    if not package_to_delete then
        return
    end

    local package_json_path = fs.combine(wkdir, "package.json")

    -- If there is not package json, they've never installed anything. No need to delete
    if not package_json_path then
        return "No package.json found."
    end

    local package_json = decodeFromFile(package_json_path)

    -- If no dependencies, of course, no reason to delete
    if not package_json.dependencies then
        return "No dependencies to delete"
    end

    -- If the dependency doesn't exist, no need to delete!
    if not package_json.dependencies[package_to_delete] then
        return string.format("%s not found. Perhaps you made a typo?", package_to_delete)
    end

    package_json.dependencies[package_to_delete] = nil

    local package_lock_path = fs.combine(wkdir, "package-lock.json")
    local package_lock = {}

    if fs.exists(package_json_path) then
        package_lock = decodeFromFile(package_lock_path)
    end

    local package_to_delete_path = wkdir .. "/luam_modules/" .. package_to_delete

    -- If the file we need to delete can't be found, handle it
    if not fs.exists(package_to_delete_path) then
        return string.format("%s not found", package_to_delete_path)
    end

    deletePackage(package_to_delete, package_to_delete_path, package_lock)

    local package_json_writer = fs.open(package_json_path, "w")
    package_json_writer.write(encodePretty(package_json))
    package_json_writer.close()

    local package_lock_writer = fs.open(package_lock_path, "w")
    package_lock_writer.write(encodePretty(package_lock))
    package_lock_writer.close()
end

return delete
