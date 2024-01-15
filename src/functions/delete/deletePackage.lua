local function get_root(file_path)
    local last_slash_index =
        file_path:match(".*()/")
    return last_slash_index and file_path:sub(1, last_slash_index - 1) or file_path
end

local function depends_on(dependent_name, dependent_path, dependee_path, package_lock)
    dependee_path = dependee_path .. "/luam_modules/" .. dependent_name
    while dependee_path ~= dependent_path do
        if package_lock[dependee_path] then
            return false
        end

        for _ = 1, 3 do
            dependee_path = get_root(dependee_path)
        end
        dependee_path = dependee_path .. "/" .. dependent_name
    end
    return true
end

local function find_first_from_path(path, package_name, package_lock)
    path = path .. "/luam_modules/" .. package_name
    while #path > 0 do
        local data = package_lock[path]

        if data then
            return path
        end

        for i = 1, 3 do
            local prev_path = path
            path = get_root(path)
            if prev_path == path then
                return
            end
        end

        path = path .. "/" .. package_name
    end
end

local function has_key(_table, key)
    for k, _ in pairs(_table) do
        if k == key then
            return true
        end
    end
    return false
end

local function deletePackage(name, path, package_lock)
    for package_path, package_data in pairs(package_lock) do
        if has_key(package_data.dependencies, name) then
            print(package_data.name)
            if depends_on(name, path, package_path, package_lock) then
                return
            end
        end
    end

    local data = package_lock[path]
    local dependencies = data.dependencies

    fs.delete(path)
    package_lock[path] = nil

    for sub_path in pairs(package_lock) do
        if sub_path:sub(1, #path) == path then
            package_lock[sub_path] = nil
        end
    end


    for dep_name in pairs(dependencies) do
        local dep_path = find_first_from_path(path, dep_name, package_lock)
        if dep_path then
            deletePackage(dep_name, dep_path, package_lock)
        end
    end
end

return deletePackage
