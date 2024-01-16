local function has_keys(table)
    for _, _ in pairs(table) do
        return true
    end
    return false
end

local function dict_length(table)
    local result = 0
    for _, _ in pairs(table) do
        result = result + 1
    end
    return result
end

local function list()
    local wkdir = shell.dir()
    local package_json_path = fs.combine(wkdir, "package.json")
    local package_lock_path = fs.combine(wkdir, "package-lock.json")

    if not fs.exists(package_json_path) then
        return "No package.json found!"
    end

    if not fs.exists(package_lock_path) then
        return "No packages installed"
    end

    local package_json = decodeFromFile(package_json_path)
    local package_lock = decodeFromFile(package_lock_path)

    if not package_lock then
        return "Must have package lock to run list command"
    end

    if not has_keys(package_lock) then
        return "No packages installed"
    end

    local dependency_count = dict_length(package_json.dependencies)

    print()
    print(string.format("%s dependenc%s", dependency_count, dependency_count > 1 and "ies" or "y"))
    print()

    for dependency, version in pairs(package_json.dependencies) do
        print(dependency .. " " .. version)
    end

    print()
    print(string.format("%s packages installed", dict_length(package_lock)))
    print("")
    for path, data in pairs(package_lock) do
        path = path:gsub(wkdir, ""):gsub("/luam_modules/", "")
        path = path:gsub("/", " > ")
        print(string.format("%s %s", path, data.version))
    end

    print()
end

return list
