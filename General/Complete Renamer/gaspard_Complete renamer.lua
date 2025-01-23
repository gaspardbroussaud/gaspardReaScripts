--@description Complete renamer
--@author gaspard
--@version 1.0
--@provides
--    [nomain] Utilities/*.lua
--    [nomain] Utilities/GUI_Elements/*.lua
--@changelog
--  - Script release
--  - Resizable userdata table
--  - Added rules preset system
--@about
--  ### Complete renamer
--  - A complete renamer with selectable and editable rule blocks for items, tracks, markers and regions (may evolve).

-- Toggle button state in Reaper
function SetButtonState(set)
    local _, name, sec, cmd, _, _, _ = reaper.get_action_context()
    if set == 1 then
      action_name = string.match(name, "gaspard_(.-)%.lua")
      -- Get version from ReaPack
      local pkg = reaper.ReaPack_GetOwner(name)
      version = tostring(select(7, reaper.ReaPack_GetEntryInfo(pkg)))
      reaper.ReaPack_FreeEntry(pkg)
    else
      if Settings.clean_rpp.value then System.CleanExtState() end
    end
    reaper.SetToggleCommandState(sec, cmd, set or 0)
    reaper.RefreshToolbar2(sec, cmd)
end
SetButtonState(1)

-- Load Utilities
dofile(reaper.GetResourcePath() ..
       '/Scripts/ReaTeam Extensions/API/imgui.lua')
  ('0.9.0.2') -- current version at the time of writing the script

package.path = package.path..';'..debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]] .. "?.lua" -- GET DIRECTORY FOR REQUIRE
System = require('Utilities/System')
local Gui = require('Utilities/UserInterface')

local json_file_path = reaper.GetResourcePath().."/Scripts/Gaspard ReaScripts/JSON"
package.path = package.path .. ";" .. json_file_path .. "/?.lua"
gson = require("json_utilities_lib")

settings_path = debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]]..'/Utilities/gaspard_'..action_name..'_settings.json'
rule_default_path = debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]]..'/Utilities/rule_default.json'
presets_path = debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]]..'/Presets'

System.InitSettings()
Gui.Init()

reaper.defer(Gui.Loop)
reaper.atexit(SetButtonState)
