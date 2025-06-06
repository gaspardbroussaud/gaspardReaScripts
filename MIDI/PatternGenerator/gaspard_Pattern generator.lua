--@noindex
--@description Pattern generator
--@author gaspard
--@version 0.0.7b
--@provides
--    [nomain] Utilities/*.lua
--    [nomain] Utilities/Gui_Elements/*.lua
--@changelog
--  - Remove from ReaPack
--@about
--  ### Pattern generator
--  - A MIDI pattern generator.

-- Toggle button state in Reaper
function SetButtonState(set)
    local _, name, sec, cmd, _, _, _ = reaper.get_action_context()
    if set == 1 then
      action_name = string.match(name, 'gaspard_(.-)%.lua')
      -- Get version from ReaPack
      local pkg = reaper.ReaPack_GetOwner(name)
      version = tostring(select(7, reaper.ReaPack_GetEntryInfo(pkg)))
      reaper.ReaPack_FreeEntry(pkg)
    else
      System.ClearOnExitIfEmpty()
    end
    reaper.SetToggleCommandState(sec, cmd, set or 0)
    reaper.RefreshToolbar2(sec, cmd)
end
SetButtonState(1)

-- Load Utilities
dofile(reaper.GetResourcePath() ..
       '/Scripts/ReaTeam Extensions/API/imgui.lua')
  ('0.9.3.2') -- current version at the time of writing the script

package.path = package.path..';'..debug.getinfo(1, 'S').source:match [[^@?(.*[\/])[^\/]-$]] .. '?.lua' -- GET DIRECTORY FOR REQUIRE
System = require('Utilities/System')
local Gui = require('Utilities/UserInterface')

local json_file_path = reaper.GetResourcePath()..'/Scripts/Gaspard ReaScripts/JSON'
package.path = package.path .. ';' .. json_file_path .. '/?.lua'
gson = require('json_utilities_lib')

settings_path = debug.getinfo(1, 'S').source:match [[^@?(.*[\/])[^\/]-$]]..'Utilities/gaspard_'..action_name..'_settings.json'
presets_path = debug.getinfo(1, 'S').source:match [[^@?(.*[\/])[^\/]-$]]..'Presets'
patterns_path = debug.getinfo(1, 'S').source:match [[^@?(.*[\/])[^\/]-$]]..'Patterns'

--test_sample_filepath = 'C:/Users/Gaspard/Documents/000-Temp/_Tests/Kick 808.wav'
--'/Users/gaspardbroussaud/Documents/Travail/Code/kick-gritty.wav'

System.Init()
Gui.Init()

reaper.defer(Gui.Loop)
reaper.atexit(SetButtonState)
