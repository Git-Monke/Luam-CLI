local function login(args)
    print("API Token: ")
    local token = io.read()

    local key_writer = fs.open("luam.key", "w")
    key_writer.write(token)
    key_writer.close()

    return "API token now in use"
end

return login
