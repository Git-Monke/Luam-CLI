require "functions.json"

local tar = require("tar.lib")
local base64 = require("base64.lib")
local get_package_api_url =
"https://api.luam.dev/packages/install"

-- Utilities

local function install_into_dir(dir, name, encoded_file_data)
  local tar_path = dir .. "/" .. name .. ".tar"

  base64.decodeFile(encoded_file_data, tar_path)
  tar.untar(tar_path, dir)
  fs.delete(tar_path)
end

local function includes(table, item)
  for _, other_item in ipairs(table) do
    if other_item == item then
      return true
    end
  end

  return false
end

local function clone(_table)
  local new_table = {}
  for _, item in ipairs(_table) do
    table.insert(new_table, item)
  end
  return new_table
end

local function combine_luam_path(root, options, i, name)
  for j = 1, i do
    root = root .. "/luam_modules/" .. options[j]
  end

  if name then
    root = root .. "/luam_modules/" .. name
  end

  return root
end

local function get_root(file_path)
  local last_slash_index =
      file_path:match(".*()/")
  return last_slash_index and file_path:sub(1, last_slash_index - 1) or file_path
end

local function find_first_from_path(path, package_name, package_version, package_lock)
  path = path .. "/luam_modules/" .. package_name
  while #path > 0 do
    local data = package_lock[path]

    if data and data.name == package_name and data.version == package_version then
      return path
    end

    for i = 1, 3 do
      local prev_path = path
      path = get_root(path)
      if prev_path == path then
        return false
      end
    end

    path = path .. "/" .. package_name
  end
end

-- package_data should be a table with a "name", "version", and "dependencies"
-- returns the path in the package_lock it copied from
local function install_by_copy(package_data, install_path, package_lock)
  local copy_from_path = ""

  for path, data in pairs(package_lock) do
    if data.name == package_data.name and data.version == package_data.version then
      copy_from_path = path
    end
  end

  fs.copy(copy_from_path, install_path)

  return copy_from_path
end

local function install(root, packages, package_lock, first_package_name, first_package_version)
  local installation_stack = {}

  local first_item = packages[first_package_name][first_package_version]
  first_item.name = first_package_name
  first_item.version = first_package_version
  first_item.options = {}

  table.insert(installation_stack, first_item)

  for _, item in ipairs(installation_stack) do
    local name = item.name
    local version = item.version

    local options = item.options
    local options_clone = clone(options)
    table.insert(options_clone, name)

    for i = 0, #options do
      local install_path = combine_luam_path(root, options, i, name)

      if package_lock[install_path] and package_lock[install_path].version == version then
        break;
      end

      if not package_lock[install_path] then
        if item.payload then
          install_into_dir(get_root(install_path), name, item.payload)

          package_lock[install_path] = {
            name = item.name,
            version = item.version,
            dependencies = item.dependencies
          }

          for dep_name, dep_version in pairs(item.providedDependencyVersions) do
            local new_item = nil

            if packages[dep_name] and packages[dep_name][dep_version] then
              new_item = packages[dep_name][dep_version]
              new_item.name = dep_name
              new_item.version = dep_version
            else
              new_item = {
                name = dep_name,
                version = dep_version
              }
            end
            new_item.options = options_clone
            table.insert(installation_stack, new_item)
          end
        else
          local path_copied_from = ""

          -- In this case, if there is a version then we are copying over a specific dependency that we need
          -- for another package. If there is no version, then we are copying over the dependencies of a dependency
          -- that has been copied over, meaning we first have to find what the original copied dependency was referencing
          -- and then reinstall using that
          if version then
            path_copied_from = install_by_copy(item, install_path, package_lock)
          else
            local item_data = find_first_from_path(item.copied_from_path, name)
            path_copied_from = install_by_copy(item_data, install_path, package_lock)
          end

          local copied_data = package_lock[path_copied_from]
          package_lock[install_path] = copied_data

          for dep_name, _ in pairs(copied_data.dependencies) do
            table.insert(installation_stack,
              { options = options_clone, name = dep_name, copied_from_path = path_copied_from })
          end
        end
        break
      end
    end
  end
end

-- Main

local function download_file(name, version)
  local wkdir = shell.dir()

  local package_lock_path = fs.combine(wkdir, "package-lock.json")
  local package_lock = {}

  if fs.exists(package_lock_path) then
    package_lock = decodeFromFile(package_lock_path) or {}
  end
  local processed_package_lock = {}

  -- This part generates the body of the request
  for _, package in pairs(package_lock) do
    local name = package.name
    local version = package.version

    if not processed_package_lock[name] then
      processed_package_lock[name] = {}
    end

    if not includes(processed_package_lock[name], version) then
      table.insert(processed_package_lock[name], version)
    end
  end

  local encoded_package_lock = encode(processed_package_lock)

  if (encoded_package_lock == "[]") then encoded_package_lock = "{}" end

  local headers = {
    ["X-PackageName"] = name,
    ["X-PackageVersion"] = version,
    ["Content-Type"] = "application/json"
  }

  local result, error_type, error_handler = http.post(get_package_api_url, encoded_package_lock, headers)

  if not result then
    error(string.format("%s: %s", error_type, error_handler and error_handler.readAll()))
  end

  -- This part takes the result and performs the actual installation

  local all_packages_data = decode(result.readAll())
  local served_version = version
  -- Because no version can be specified, we must retrieve the served version so we can access the root package to initialize installation
  for k in pairs(all_packages_data[name]) do
    served_version = k
  end

  install(wkdir, all_packages_data, package_lock, name, served_version)

  local package_lock_writer = fs.open(package_lock_path, "w");
  package_lock_writer.write(encodePretty(package_lock))
  package_lock_writer.close()

  local packages_installed = 0

  for version, _ in pairs(all_packages_data) do
    for package, _ in pairs(all_packages_data[version]) do
      packages_installed = packages_installed + 1
    end
  end

  print(string.format("%s package%s installed", packages_installed, packages_installed > 1 and "s" or ""))
  return served_version
end

return download_file
