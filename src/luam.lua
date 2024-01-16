local args = { ... }

if args[1] ~= ".luam" then
    local init = require "functions.init"
    local post = require "functions.post"

    local install = require "functions.install"
    local login = require "functions.login"

    local delete = require "functions.delete"
    local version_tools = require "functions.versions"
    local increment_version = version_tools.increment_version
    local list_version = version_tools.list_version

    local help = require "functions.help"
    local list = require "functions.list"

    local functions = {
        init    = init,
        post    = post,
        install = install,
        i       = install,
        remove  = delete,
        rm      = delete,
        login   = login,
        help    = help,
        list    = list,
        ls      = list,
        version = list_version,
        v       = list_version,
        patch   = function()
            increment_version("patch")
        end,
        minor   = function()
            increment_version("minor")
        end,
        major   = function()
            increment_version("major")
        end
    }

    local start = os.clock()

    local ranSuccessfully, result = pcall(function()
        if not args[1] then
            error("At least one argument expected.")
        end

        if not functions[args[1]] then
            error(string.format("%s is not a valid command", args[1]))
        end

        local result = functions[args[1]](args)
        return result
    end)

    if not ranSuccessfully then
        print("Error!")
    end

    if result then print(result) end
    print(string.format("Finished in %0.3f seconds", os.clock() - start))
else
    local function split(str, delim)
        local result = {}
        for match in (str .. delim):gmatch("(.-)" .. delim) do
            table.insert(result, match)
        end
        return result
    end

    local default_require = require

    local function searchModule(pathParts, moduleName)
        while #pathParts > 0 do
            local path = table.concat(pathParts, "/") .. "/luam_modules/" .. moduleName
            local status, module = pcall(default_require, path:gsub("/", "."))
            if status then
                return module
            end
            table.remove(pathParts)
            table.remove(pathParts)
        end
    end

    function require(moduleName)
        local info = debug.getinfo(2, "S")
        local path = info.source:sub(2)
        path = path:match("(.*/)") or ""
        path = path:sub(1, #path - 1)

        local pathParts = split(path, "/")

        local module = searchModule(pathParts, moduleName)

        if module then
            return module
        end

        return default_require(moduleName)
    end
end
