local function login(args)
    local key_writer = fs.open("luam.key", "w")
    key_writer.write(args[2])
    key_writer.close()

    return "API token now in use"
end

return login
