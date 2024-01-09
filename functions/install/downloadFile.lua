require "functions.json"

local tar = require("tar.lib")
local base64 = require("base64.lib")
local get_package_api_url =
"https://api.luam.dev/packages/install"

local tableutils = require(".tableutils.lib")

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

local function concat(t1, i2)
  local t3 = {}
  for _, item in ipairs(t1) do
    table.insert(t3, item)
  end
  table.insert(t3, i2)
  return t3
end

-- Installation

local function combine_to_nested_luam_path(root, options, length)
  for i = 1, math.min(#options, length) do
    root = root .. "/" .. options[i] .. "/luam_modules"
  end

  return root
end

local function perform_relative_to_dir(root, options, func)
  for i = 0, #options do
    if func(combine_to_nested_luam_path(root, options, i)) then
      return true
    end
  end

  return false
end

local function attempt_install(modules_dir, path, options, package_lock, all_package_data, name, version)
  local install_path = fs.combine(path, name)

  if package_lock[install_path] then
    return false
  end
  local package_data = all_package_data[name][version]

  install_into_dir(path, name, package_data.payload)

  package_lock[install_path] = {
    name = name,
    version = version,
    dependencies = package_data.dependencies,
  }

  for dep_name, dep_version in pairs(package_data.providedDependencyVersions) do
    -- If, in the payload, the dependency is included, that means the server identified that a package needed to be served, and so files need to be installed
    if all_package_data[dep_name] and all_package_data[dep_name][dep_version] then
      local next_options = concat(options, name)
      perform_relative_to_dir(modules_dir, next_options, function(next_path)
        return attempt_install(modules_dir, next_path, next_options, package_lock, all_package_data, dep_name,
          dep_version)
      end)
    end

    -- If it wasn't included, that means it exists somewhere else in the module tree already and should only be copied to a place the new module can access it
    local existing_installation_path = ""
    local is_already_accessable = false

    -- Go through the package lock and see if the required version is already accessable from the installation location. Also, cache the file path that the dependency can be copied from if it isn't.
    for path, data in pairs(package_lock) do
      if (data.version == dep_version) then
        existing_installation_path = path
        is_already_accessable = true
      end
    end

    if existing_installation_path ~= "" then

    else
      print(string.format("Warning, %s %s was expected to exist and is required by %s %s, but could not be found.",
        dep_name, dep_version, name, version))
    end
  end

  return true
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
    print(name, version)

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
    error(string.format("%s: %s", error_type, error_handler.readAll()))
  end

  -- This part takes the result and performs the actual installation

  local all_packages_data = decode(result.readAll())
  local served_version = version
  -- Because no version can be specified, we must retrieve the served version so we can access the root package to initialize installation
  for k in pairs(all_packages_data[name]) do
    served_version = k
  end

  local modules_dir = wkdir .. "/luam_modules"

  perform_relative_to_dir(modules_dir, {}, function(path)
    return attempt_install(modules_dir, path, {}, package_lock, all_packages_data, name, served_version)
  end)

  local package_lock_writer = fs.open(package_lock_path, "w");
  package_lock_writer.write(encodePretty(package_lock))
  package_lock_writer.close()

  return served_version
end

return download_file
