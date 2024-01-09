local encodeFile = require("functions.post.encodeFile")
local json = require("functions.json")

local post_package_api_url =
"https://api.luam.dev/packages"

local function validate_package_json(package_json)
    local required_fields = { "name", "version", "dependencies" }

    for _, required_field in ipairs(required_fields) do
        if not package_json[required_field] then
            error(string.format('Required field "%s" missing from package.json', required_field))
        end
    end
end

local function post()
    local wkdir = shell.dir()
    local package_json_path = fs.combine(wkdir, "package.json")

    if not fs.exists('luam.key') then
        return 'No api token found. Run luam login and provide a valid api token.'
    end

    local api_token = fs.open("luam.key", "r").readAll()

    if not fs.exists(package_json_path) then
        return '"package.json" not found. Run "luam init" to initialize package.'
    end

    local package_json = decodeFromFile(package_json_path)
    validate_package_json(package_json)

    local luam_ignore_path = fs.combine(wkdir, ".luamignore")
    local luam_ignore = {}

    if fs.exists(luam_ignore_path) then
        local luam_ignore_reader = fs.open(luam_ignore_path, "r")
        local line = "temp"

        while line do
            line = luam_ignore_reader.readLine()
            if not line then
                break
            end
            table.insert(luam_ignore, wkdir .. "/" .. line)
        end
    end
    table.print(luam_ignore)
    local encoded_payload = encodeFile(wkdir, luam_ignore)
    local request_body = {
        name = package_json.name,
        version = package_json.version,
        dependencies = package_json.dependencies,
        payload = encoded_payload,
    }

    local result, detail, errorResponse = http.post(post_package_api_url, encode(request_body), {
        Authorization = api_token
    })

    if not result then
        return string.format("%s: %s", detail, decode(errorResponse.readAll()).message or "No message provided")
    end

    return string.format("%s v%s was posted successfully!", package_json.name, package_json.version)
end

return post
