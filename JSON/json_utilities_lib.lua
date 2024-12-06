--@description Json functions for gaspard's scripts
--@author gaspard
--@version 1.0
--@provides [nomain] .
--@about Json functions for gaspard's scripts

local gson = {}

-- Get JSON utilities from file
package.path = package.path..';'..debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]] .. "?.lua" -- GET DIRECTORY FOR REQUIRE
json = require("json")

-- Save json to file
function gson.SaveJSON(path, var)
  local filepath = path
  local file = assert(io.open(filepath, "w+"))

  local serialized = json.encode(var)
  assert(file:write(serialized))

  file:close()
  return true
end

-- Load json from file
function gson.LoadJSON(path, var)
  local filepath = path
  local settings = var
  local file = io.open(filepath, "rb")
  if not file then
    gson.SaveJSON(filepath, settings)
    return settings
  end

  local raw_text = file:read("*all")
  file:close()

  return json.decode(raw_text)
end

return gson

-- TEMPLATE (remove the REMOVE_THIS text at line 50)
--[[ Init system variables
function InitSystemVariables()
  local json_file_path = reaper.GetResourcePath().."/Scripts/Gaspard ReaScripts/JSON"
  package.path = package.path .. ";" .. json_file_path .. "/?.lua"
  gson = require("json_utilities_lib")

  --settings_path = debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]REMOVE_THIS]..'/gaspard_Set region render martrix to same named track_settings.json'
  Settings = {
      region_naming_parent_casacde = false,
      look_for_patterns = false,
      region_naming_pattern = ""
  }
  Settings = gson.LoadJSON(settings_path, Settings)
end
]]