--@description Json functions for gaspard's scripts
--@author gaspard
--@version 1.0.3
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
  local settings = var or {}
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

--[[ TEMPLATE EXEMPLE (copy from line 44 to 57 and remove the REMOVE_THIS text at line 50)
-- Init system variables
function InitSystemVariables()
  local json_file_path = reaper.GetResourcePath().."/Scripts/Gaspard ReaScripts/JSON"
  package.path = package.path .. ";" .. json_file_path .. "/?.lua"
  gson = require("json_utilities_lib")

  settings_path = debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]REMOVE_THIS]..'/gaspard_'..action_name..'_settings.json'
  Settings = {
    order = { "test1", "test2", "test3" },
    test1 = {
      value = false,
      name = "Region name from folder cascade",
      description = "Use cascading track folders to name regions."
    },
    test2 = {
      value = 4,
      min = 0,
      max = 1000,
      name = "Displayed name",
      description = "Tooltip description."
    },
    test3 = {
      value = "",
      char_type = nil,
      name = "Text pattern",
      description = "Pattern to look for in region names. Can be regex."
    }
  }
  Settings = gson.LoadJSON(settings_path, Settings)
end

-- EXEMPLE VARIABLE TYPES
-- BOOLEAN:
key_name = {
  value = true,
  name = "Name to display",
  description = "Tooltip text for element."
}

-- STRING:
key_name = {
  value = "Text",
  char_type = nil --or flags list => reaper.ImGui_InputTextFlags_AllowTabInput() | reaper.ImGui_InputTextFlags_AutoSelectAll(),
  name = "Name",
  description = "Tooltip description."
}

-- NUMBER:
key_name = {
  value = 0 --(int or float)
  min = 0, --(-math.huge if none)
  max = 100, --(math.huge if none) If both nil then inputText with reaper.ImGui_InputTextFlags_CharsDecimal() | reaper.ImGui_InputTextFlags_CharsNoBlank()
  format = "%.2f",
  name = "Name",
  description = "Tooltip description."
}
]]
