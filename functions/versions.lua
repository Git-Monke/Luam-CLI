require "functions.json"

local function increment_semver(version, incType)
    local major, minor, patch = version:match("(%d+)%.(%d+)%.(%d+)")
    major, minor, patch = tonumber(major), tonumber(minor), tonumber(patch)

    if incType == "major" then
        return string.format("%d.0.0", major + 1)
    elseif incType == "minor" then
        return string.format("%d.%d.0", major, minor + 1)
    elseif incType == "patch" then
        return string.format("%d.%d.%d", major, minor, patch + 1)
    else
        error("Invalid increment type: " .. incType)
    end
end

local function increase_version(incType)
    local wkdir = shell.dir()
    local package_json_path = fs.combine(wkdir, "package.json")

    if not fs.exists(package_json_path) then
        return "No package.json found!"
    end

    local package_json = decodeFromFile(package_json_path)

    if not package_json["version"] then
        return "Must initialize package before incrementing version. Run luam init"
    end

    local new_version = increment_semver(package_json["version"], incType or "patch")
    print(string.format("Updated to %s", new_version))
    package_json["version"] = new_version

    local json_writer =
        fs.open(package_json_path, "w")
    json_writer.write(encodePretty(package_json))
    json_writer.close()

    return new_version
end

return increase_version
