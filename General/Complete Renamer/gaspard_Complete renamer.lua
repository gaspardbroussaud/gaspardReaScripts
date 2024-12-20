--@noindex
--@description Complete renamer
--@author gaspard
--@version 0.0.1b
-- @provides
--    [nomain] Utilities/*.lua
--@changelog
--  - Adding script
--@about
--  ### Complete renamer
--  - A complete renamer with selectable and editable rule blocks for tracks, regions, markers, items (may add others later).

-- Toggle button state in Reaper
function SetButtonState(set)
    local _, name, sec, cmd, _, _, _ = reaper.get_action_context()
    action_name = string.match(name, "gaspard_(.-)%.lua")
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
presets_path = debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]]..'/Presets'

System.InitSettings()
Gui.Init()

reaper.defer(Gui.Loop)
reaper.atexit(SetButtonState)