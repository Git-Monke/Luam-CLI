local args = { ... }

local init = require "functions.init"
local post = require "functions.post"

local install = require "functions.install"
local login = require "functions.login"

local functions = {
    init = init,
    post = post,
    add = "",
    install = install,
    login = login
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
