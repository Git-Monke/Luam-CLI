
---------------------------------------------------------
----------------Auto generated code block----------------
---------------------------------------------------------

do
    local searchers = package.searchers or package.loaders
    local origin_seacher = searchers[2]
    searchers[2] = function(path)
        local files =
        {
------------------------
-- Modules part begin --
------------------------

["functions.post.encodeFile"] = function()
--------------------
-- Module: 'functions.post.encodeFile'
--------------------
local Tar = require("tar.lib")
local Base64 = require("base64.lib")

local function encodeFile(path, ignore)
    assert(fs.exists(path), "File does not exist!")
    local outputPath = "temp-" .. math.floor(1000 * math.random()) .. ".tar"
    Tar.tar(path, outputPath, ignore)
    local code = Base64.encodeFile(outputPath)
    fs.delete(outputPath)
    return code
end

return encodeFile

end,

["functions.post"] = function()
--------------------
-- Module: 'functions.post'
--------------------
local encodeFile = require("functions.post.encodeFile")
local increment_version = require("functions.versions")
require("functions.json")

local post_package_api_url =
"https://api.luam.dev/packages"

local function validate_package_json(package_json)
    local required_fields = { "name", "version", "dependencies" }

    for _, required_field in ipairs(required_fields) do
        if not package_json[required_field] then
            error(string.format('Required field "%s" missing from package.json', required_field))
        end
    end

    local vcw = fs.open(string.format(".luamversioncache/%s", package_json.name), "r")

    if vcw then
        local version = vcw.readAll()
        if version == package_json["version"] then
            local new_version = increment_version("patch")
            package_json["version"] = new_version
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

    local encoded_payload = encodeFile(wkdir, luam_ignore)
    local request_body = {
        name = package_json.name,
        version = package_json.version,
        dependencies = package_json.dependencies,
        payload = encoded_payload,
    }

    local vcw = fs.open(".luamversioncache" .. "/" .. package_json.name, "w")
    vcw.write(package_json.version)
    vcw.close()

    local result, detail, errorResponse = http.post(post_package_api_url, encode(request_body), {
        Authorization = api_token
    })

    if not result then
        if not errorResponse then
            return "The request timed out. Either luam is down or it is blocked on your network"
        end

        return string.format("%s: %s", detail, decode(errorResponse.readAll()).message or "No message provided")
    end

    return string.format("%s v%s was posted successfully!", package_json.name, package_json.version)
end

return post

end,

["functions.install.downloadFile"] = function()
--------------------
-- Module: 'functions.install.downloadFile'
--------------------
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

end,

["functions.json"] = function()
--------------------
-- Module: 'functions.json'
--------------------
------------------------------------------------------------------ utils
local controls = {
	["\n"] = "\\n",
	["\r"] = "\\r",
	["\t"] = "\\t",
	["\b"] = "\\b",
	["\f"] = "\\f",
	["\""] = "\\\"",
	["\\"] = "\\\\"
}

local function isArray(t)
	local max = 0
	for k, v in pairs(t) do
		if type(k) ~= "number" then
			return false
		elseif k > max then
			max = k
		end
	end
	return max == #t
end

local whites = { ['\n'] = true, ['\r'] = true, ['\t'] = true, [' '] = true, [','] = true, [':'] = true }
function removeWhite(str)
	while whites[str:sub(1, 1)] do
		str = str:sub(2)
	end
	return str
end

------------------------------------------------------------------ encoding

local function encodeCommon(val, pretty, tabLevel, tTracking)
	local str = ""

	-- Tabbing util
	local function tab(s)
		str = str .. ("\t"):rep(tabLevel) .. s
	end

	local function arrEncoding(val, bracket, closeBracket, iterator, loopFunc)
		str = str .. bracket
		if pretty then
			str = str .. "\n"
			tabLevel = tabLevel + 1
		end
		for k, v in iterator(val) do
			tab("")
			loopFunc(k, v)
			str = str .. ","
			if pretty then str = str .. "\n" end
		end
		if pretty then
			tabLevel = tabLevel - 1
		end
		if str:sub(-2) == ",\n" then
			str = str:sub(1, -3) .. "\n"
		elseif str:sub(-1) == "," then
			str = str:sub(1, -2)
		end
		tab(closeBracket)
	end

	-- Table encoding
	if type(val) == "table" then
		tTracking[val] = true
		if isArray(val) then
			arrEncoding(val, "[", "]", ipairs, function(k, v)
				str = str .. encodeCommon(v, pretty, tabLevel, tTracking)
			end)
		else
			arrEncoding(val, "{", "}", pairs, function(k, v)
				assert(type(k) == "string", "JSON object keys must be strings", 2)
				str = str .. encodeCommon(k, pretty, tabLevel, tTracking)
				str = str .. (pretty and ": " or ":") .. encodeCommon(v, pretty, tabLevel, tTracking)
			end)
		end
		-- String encoding
	elseif type(val) == "string" then
		str = '"' .. val:gsub("[%c\"\\]", controls) .. '"'
		-- Number encoding
	elseif type(val) == "number" or type(val) == "boolean" then
		str = tostring(val)
	else
		error("JSON only supports arrays, objects, numbers, booleans, and strings", 2)
	end
	return str
end

function encode(val)
	return encodeCommon(val, false, 0, {})
end

function encodePretty(val)
	return encodeCommon(val, true, 0, {})
end

------------------------------------------------------------------ decoding

local decodeControls = {}
for k, v in pairs(controls) do
	decodeControls[v] = k
end

function parseBoolean(str)
	if str:sub(1, 4) == "true" then
		return true, removeWhite(str:sub(5))
	else
		return false, removeWhite(str:sub(6))
	end
end

function parseNull(str)
	return nil, removeWhite(str:sub(5))
end

local numChars = { ['e'] = true, ['E'] = true, ['+'] = true, ['-'] = true, ['.'] = true }
function parseNumber(str)
	local i = 1
	while numChars[str:sub(i, i)] or tonumber(str:sub(i, i)) do
		i = i + 1
	end
	local val = tonumber(str:sub(1, i - 1))
	str = removeWhite(str:sub(i))
	return val, str
end

function parseString(str)
	str = str:sub(2)
	local s = ""
	while str:sub(1, 1) ~= "\"" do
		local next = str:sub(1, 1)
		str = str:sub(2)
		assert(next ~= "\n", "Unclosed string")

		if next == "\\" then
			local escape = str:sub(1, 1)
			str = str:sub(2)

			next = assert(decodeControls[next .. escape], "Invalid escape character")
		end

		s = s .. next
	end
	return s, removeWhite(str:sub(2))
end

function parseArray(str)
	str = removeWhite(str:sub(2))

	local val = {}
	local i = 1
	while str:sub(1, 1) ~= "]" do
		local v = nil
		v, str = parseValue(str)
		val[i] = v
		i = i + 1
		str = removeWhite(str)
	end
	str = removeWhite(str:sub(2))
	return val, str
end

function parseObject(str)
	str = removeWhite(str:sub(2))

	local val = {}
	while str:sub(1, 1) ~= "}" do
		local k, v = nil, nil
		k, v, str = parseMember(str)
		val[k] = v
		str = removeWhite(str)
	end
	str = removeWhite(str:sub(2))
	return val, str
end

function parseMember(str)
	local k = nil
	k, str = parseValue(str)
	local val = nil
	val, str = parseValue(str)
	return k, val, str
end

function parseValue(str)
	local fchar = str:sub(1, 1)
	if fchar == "{" then
		return parseObject(str)
	elseif fchar == "[" then
		return parseArray(str)
	elseif tonumber(fchar) ~= nil or numChars[fchar] then
		return parseNumber(str)
	elseif str:sub(1, 4) == "true" or str:sub(1, 5) == "false" then
		return parseBoolean(str)
	elseif fchar == "\"" then
		return parseString(str)
	elseif str:sub(1, 4) == "null" then
		return parseNull(str)
	end
	return nil
end

function decode(str)
	str = removeWhite(str)
	t = parseValue(str)
	return t
end

function decodeFromFile(path)
	local file = assert(fs.open(path, "r"))
	local decoded = decode(file.readAll())
	file.close()
	return decoded
end

end,

["functions.init"] = function()
--------------------
-- Module: 'functions.init'
--------------------
require "functions.json"

local function init(args)
    local wkdir = shell.dir()

    if args[2] then
        wkdir = wkdir .. "/" .. args[2]
    end

    local package_json_path = fs.combine(wkdir, "package.json")
    local package_json = {}

    if fs.exists(package_json_path) then
        package_json = decodeFromFile(package_json_path)
    end

    if package_json["name"] then
        print("Package has already been initialized")
    end

    local name = args[2] or wkdir:match("([^/]+)$")
    local writer = fs.open(package_json_path, "w")

    package_json["name"] = name
    package_json["version"] = "0.1.0"
    package_json["dependencies"] = package_json["dependencies"] or {}

    writer.write(encodePretty(package_json))

    local ignore_writer = fs.open(fs.combine(wkdir, ".luamignore"), "w")
    ignore_writer.write("luam_modules\n")
    ignore_writer.write("package-lock.json")

    return string.format("Package %s has been initialized", name)
end

return init

end,

["functions.delete.deletePackage"] = function()
--------------------
-- Module: 'functions.delete.deletePackage'
--------------------
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

end,

["functions.versions"] = function()
--------------------
-- Module: 'functions.versions'
--------------------
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

end,

["functions.delete"] = function()
--------------------
-- Module: 'functions.delete'
--------------------
require "functions.json"
require "functions.delete.deletePackage"

local deletePackage = require "functions.delete.deletePackage"

local function delete(args)
    local wkdir = shell.dir()
    local package_to_delete = args[2]
    -- If they didn't include a package, no need to delete
    if not package_to_delete then
        return
    end

    local package_json_path = fs.combine(wkdir, "package.json")

    -- If there is not package json, they've never installed anything. No need to delete
    if not package_json_path then
        return "No package.json found."
    end

    local package_json = decodeFromFile(package_json_path)

    -- If no dependencies, of course, no reason to delete
    if not package_json.dependencies then
        return "No dependencies to delete"
    end

    -- If the dependency doesn't exist, no need to delete!
    if not package_json.dependencies[package_to_delete] then
        return string.format("%s not found. Perhaps you made a typo?", package_to_delete)
    end

    package_json.dependencies[package_to_delete] = nil

    local package_lock_path = fs.combine(wkdir, "package-lock.json")
    local package_lock = {}

    if fs.exists(package_json_path) then
        package_lock = decodeFromFile(package_lock_path)
    end

    local package_to_delete_path = wkdir .. "/luam_modules/" .. package_to_delete

    -- If the file we need to delete can't be found, handle it
    if not fs.exists(package_to_delete_path) then
        return string.format("%s not found", package_to_delete_path)
    end

    deletePackage(package_to_delete, package_to_delete_path, package_lock)

    local package_json_writer = fs.open(package_json_path, "w")
    package_json_writer.write(encodePretty(package_json))
    package_json_writer.close()

    local package_lock_writer = fs.open(package_lock_path, "w")
    package_lock_writer.write(encodePretty(package_lock))
    package_lock_writer.close()
end

return delete

end,

["functions.add"] = function()
--------------------
-- Module: 'functions.add'
--------------------
local download_file = require "functions.install.downloadFile"
local delete = require "functions.delete"
require "functions.json"

local function install(args)
    local name = args[2]
    local version = args[3]

    if not name then
        return "A name must be provided in order to add a package"
    end

    local wkdir = shell.dir()
    local package_path = fs.combine(wkdir, "package.json")

    local package_json = {}

    if fs.exists(package_path) then
        package_json = decodeFromFile(package_path)
    end

    if package_json and package_json.dependencies and package_json.dependencies[name] then
        delete({ 0, name })
    end

    local served_version = download_file(name, version)

    if not package_json.dependencies then
        package_json.dependencies = {}
    end

    package_json.dependencies[args[2]] = "^" .. served_version
    local package_json_writer = fs.open(package_path, "w")
    package_json_writer.write(encodePretty(package_json))
end

return install

end,

["functions.login"] = function()
--------------------
-- Module: 'functions.login'
--------------------
local function login(args)
    print("API Token: ")
    local token = io.read()

    local key_writer = fs.open("luam.key", "w")
    key_writer.write(token)
    key_writer.close()

    return "API token now in use"
end

return login

end,

["base64.lib"] = function()
--------------------
-- Module: 'base64.lib'
--------------------
local charString = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local charTable = {}
local inverseCharTable = {}

for i = 1, #charString do
    local char = charString:sub(i, i)
    charTable[i] = char
    inverseCharTable[char] = i - 1
end

local blshift, brshift, band = bit.blshift, bit.blogic_rshift, bit.band

local function bytesToChars(a, b, c)
    assert(a, "At least one input byte required")
    local octs = not b and 1 or not c and 2 or 3
    b = b or 0
    c = c or 0
    local sextets = blshift(a, 16) + blshift(b, 8) + c
    local out = ""
    for i = 3, 3 - octs, -1 do
        -- 0x3f = 00111111 (first 6 bits)
        out = out .. charTable[1 + tonumber(band(brshift(sextets, i * 6), 0x3f))]
    end
    out = out .. string.rep("=", 3 - octs)
    return out;
end

local function charsToBytes(chars)
    assert(#chars == 4, "Chars must be of length 4")
    local padding = #chars:gsub("[^=]", "")
    local data = chars:gsub("=", "A")
    local bin = 0
    local out = {}
    for i = 1, 4 do
        bin = bin + blshift(inverseCharTable[data:sub(i, i)], 24 - i * 6)
    end
    for i = 1, 3 do
        out[i] = band(brshift(bin, 24 - i * 8), 0xff)
    end
    return out, padding
end

local function encodeFile(path)
    assert(fs.exists(path), 'File does not exist')
    local reader = fs.open(path, "rb")
    local out = ""
    for _ = 1, fs.getSize(path), 3 do
        local a, b, c = reader.read(), reader.read(), reader.read()
        out = out .. bytesToChars(a, b, c)
    end
    return out
end

local function decodeFile(codedString, outPath)
    assert(#codedString % 4 == 0, "Coded string should be a multiple of 4")
    local writer = fs.open(outPath, "wb")
    for i = 1, #codedString, 4 do
        local bytes, padding = charsToBytes(codedString:sub(i, i + 3))
        for j = 1, 3 - padding do
            writer.write(bytes[j])
        end
    end
    writer.close()
end

local Base64 = {
    encodeFile = encodeFile,
    decodeFile = decodeFile
}

return Base64

end,

["tar.lib"] = function()
--------------------
-- Module: 'tar.lib'
--------------------
--   Uses POSIX form with no extra length file names

local IGNORE_DOTFILES = true

local DEFAULT_MODE = "000755 \0"

local UNAME = string.rep("\0", 32)
local GNAME = UNAME

local LINKNAME = string.rep("\0", 100)

local DEV_MAJOR = "000000 \0"
local DEV_MINOR = DEV_MAJOR

local UID = DEV_MAJOR
local GID = DEV_MINOR

local FLAG_FILE = "0"
local FLAG_DIR = "5"

local VERSION = "00"
local MAGIC = "ustar\0"
local EMPTY_CHECKSUM = string.rep(" ", 8)
local NULL_BLOCK = string.rep("\0", 512)

local function pad(string, length, char)
    char = char or "0"
    if #string >= length then return string end
    return string.rep(char, length - #string) .. string
end

local function padEnd(string, length, char)
    char = char or "0"
    if #string >= length then return string end
    return string .. string.rep(char, length - #string)
end

local function toOctal(number)
    return string.format("%o", number)
end

-- Returns the header checksum as an octal string
local function calcChecksum(header)
    local checksum = 0
    for char in string.gmatch(header, ".") do
        checksum = checksum + string.byte(char)
    end
    return string.format("%06s", toOctal(checksum)) .. "\0 "
end

local function constructHeader(dir, path)
    local filePath = dir .. "/" .. path
    assert(fs.exists(filePath), "The file path " .. filePath .. " does not exist")

    local flag = fs.isDir(filePath) and FLAG_DIR or FLAG_FILE
    local size = pad(toOctal(fs.getSize(filePath)), 11, 0) .. " "
    local mtime = pad(toOctal(os.date("%s")), 11) .. " "

    local name, prefix

    if #path > 100 then
        prefix = string.sub(path, 1, 155)
        name = padEnd(string.sub(path, 156, 255), 100, "\0")
    else
        name = padEnd(path, 100, "\0")
        prefix = string.rep("\0", 155)
    end

    local preChecksum = name ..
        DEFAULT_MODE ..
        UID ..
        GID ..
        size ..
        mtime

    local postChecksum = flag ..
        LINKNAME ..
        MAGIC ..
        VERSION ..
        UNAME ..
        GNAME ..
        DEV_MAJOR ..
        DEV_MINOR ..
        prefix

    local checksum = calcChecksum(preChecksum .. EMPTY_CHECKSUM .. postChecksum)

    return padEnd(preChecksum .. checksum .. postChecksum, 512, "\0")
end

local function writeHeader(header, tarWriter)
    for i = 1, #header do
        tarWriter.write(string.byte(header, i))
    end
end

local function encodeFile(dir, path, tarWriter)
    local filePath = dir .. "/" .. path
    assert(fs.exists(filePath))

    local header = constructHeader(dir, path)
    writeHeader(header, tarWriter)

    local size = fs.getSize(filePath)
    local padding = 0

    if not fs.isDir(filePath) then
        padding = 512 - (size % 512)
    end

    local reader = fs.open(filePath, "rb")

    for _ = 1, size do
        tarWriter.write(reader.read())
    end

    for _ = 1, padding do
        tarWriter.write(0)
    end
end

local function endArchive(tarWriter)
    for _ = 1, 1024 do
        tarWriter.write(0)
    end
    tarWriter.close()
end

local function includes(tabl, item)
    for _, other_item in ipairs(tabl) do
        if other_item == item then
            return true
        end
    end

    return false
end

local function tarifyRecursive(dir, currentPath, ignore_files, writer, writerPath)
    local absPath = dir .. "/" .. currentPath
    if includes(ignore_files, absPath) then
        return
    end

    if not fs.isDir(absPath) then
        encodeFile(dir, currentPath, writer)
        return
    else
        if #fs.list(absPath) == 0 then
            encodeFile(dir, currentPath, writer)
        end
    end

    for _, subDir in ipairs(fs.list(absPath)) do
        if (IGNORE_DOTFILES and string.sub(subDir, 1, 1) ~= ".") or (not IGNORE_DOTFILES) then
            local subPath = currentPath .. "/" .. subDir
            local subAbsPath = dir .. "/" .. subPath

            if fs.isDir(subAbsPath) then
                tarifyRecursive(dir, subPath, ignore_files, writer, writerPath)
            elseif subAbsPath ~= writerPath then
                if not includes(ignore_files, subAbsPath) then
                    encodeFile(dir, subPath, writer)
                end
            end
        end
    end
end

local function tar(path, out, ignore_files, writer)
    assert(path, "No path was provided")

    if out then
        assert(string.sub(out, -4) == ".tar", "Output file path must end with .tar!")
    end

    local dir, filename = string.match(path, "(.-)/([^/]+)$")

    dir = dir or ""
    filename = filename or path
    out = out or ("/" .. dir .. "/" .. filename .. ".tar")

    writer = writer or fs.open(out, "wb")

    tarifyRecursive(dir, filename, ignore_files, writer, out)
    endArchive(writer)
end

local function extract(header, start, _end)
    local substr = header:sub(start, _end):gsub("\0", "")
    substr = substr:gsub("^%s+", "")
    substr = substr:gsub("%s+$", "")
    return substr
end

local function parseHeader(header)
    local name = extract(header, 1, 100)
    local prefix = extract(header, 345, 500)
    local size = tonumber(extract(header, 124, 136), 8)
    local type = tonumber(extract(header, 156, 157))

    return name, prefix, size, type
end

local function reconstructFile(outPath, size, reader)
    local writer = fs.open(outPath, "wb")
    for _ = 1, size do
        writer.write(reader.read())
    end

    local padding = 512 - (size % 512)

    if padding ~= 512 then
        for _ = 1, padding do
            reader.read()
        end
    end

    writer.close()
end

local function untar(path, outPath)
    outPath = outPath or shell.dir()
    assert(fs.exists(path))
    assert(string.sub(path, -4) == ".tar", "File is not a tar file")
    assert(fs.getSize(path) % 512 == 0, "File size is not a multiple of 512. Invalid tar.")

    local reader = fs.open(path, "rb")

    for _ = 1, (fs.getSize(path) / 512) - 1 do
        local header = reader.read(512)

        if header == nil then
            return;
        end

        if header ~= NULL_BLOCK then
            local name, prefix, size, type = parseHeader(header)
            local newOutPath = outPath .. "/" .. (prefix and (prefix .. name) or name)

            if type == 5 then
                fs.makeDir(newOutPath)
            else
                if not fs.exists(newOutPath) then
                    reconstructFile(newOutPath, size, reader)
                else
                    for i = 1, 512 do
                        reader.read()
                    end
                end
            end
        end
    end
end

local Tar = {
    tar = tar,
    untar = untar
}

return Tar

end,

----------------------
-- Modules part end --
----------------------
        }
        if files[path] then
            return files[path]
        else
            return origin_seacher(path)
        end
    end
end
---------------------------------------------------------
----------------Auto generated code block----------------
---------------------------------------------------------
local args = { ... }

if args[1] ~= ".luam" then
    local init = require "functions.init"
    local post = require "functions.post"

    local add = require "functions.add"
    local login = require "functions.login"

    local delete = require "functions.delete"
    local increment_version = require "functions.versions"

    local functions = {
        init   = init,
        post   = post,
        add    = add,
        a      = add,
        delete = delete,
        d      = delete,
        login  = login,
        patch  = function()
            increment_version("patch")
        end,
        minor  = function()
            increment_version("minor")
        end,
        major  = function()
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