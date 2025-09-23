--@noindex
--@description Layer manipulator
--@author gaspard
--@version 0.0.1b
--@provides
--    [nomain] Utilities/*.lua
--@changelog Init
--@about Manipulate layers and make variations.

-- Toggle button state in Reaper
function SetButtonState(set)
    local _, name, sec, cmd = reaper.get_action_context()
    if set == 1 then
      action_name = string.match(name, 'gaspard_(.-)%.lua')
      -- Get version from ReaPack
      local pkg = reaper.ReaPack_GetOwner(name)
      version = tostring(select(7, reaper.ReaPack_GetEntryInfo(pkg)))
      version = version == '' and '0.wip' or version
      reaper.ReaPack_FreeEntry(pkg)
      shortcut_activated = true
    end
    reaper.SetToggleCommandState(sec, cmd, set or 0)
    reaper.RefreshToolbar2(sec, cmd)
end
SetButtonState(1)

-- Load Utilities
dofile(reaper.GetResourcePath()..'/Scripts/ReaTeam Extensions/API/imgui.lua') ('0.10.0.1') -- current version at the time of writing the script

script_path = debug.getinfo(1, 'S').source:match [[^@?(.*[\/])[^\/]-$]]
package.path = package.path..';'..script_path .. '?.lua' -- GET DIRECTORY FOR REQUIRE
SYS = require("Utilities/SYSTEM")
GUI = require("Utilities/GUI")

local json_file_path = reaper.GetResourcePath()..'/Scripts/Gaspard ReaScripts/JSON'
package.path = package.path .. ';' .. json_file_path .. '/?.lua'
gson = require('json_utilities_lib')

settings_path = script_path..'Utilities/gaspard_'..action_name..'_settings.json'

SYS.Init()

reaper.defer(GUI.Loop)
reaper.atexit(SetButtonState)
