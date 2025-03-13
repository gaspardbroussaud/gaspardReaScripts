--@description Pattern Manipulator
--@author gaspard
--@version 0.0.1b
--@provides
--    [nomain] Utilities/*.lua
--@changelog
--  - Add script
--@about
--  # Pattern manipulator
--  Set racks of samples to manipulate using midi patterns.
--  ### Sampler
--  * The sampler stores and displays sample files dragged and dropped from explorer/finder.
--  * Available: name, color, waveform display, midi note, ADSR, play, mute, solo (and more to come).
--  * You can drop multiple files at once to import.
--  * To replace a sample file in an existing slot: select slot and drop new file on waveform.
--  * You can reorder the list using both tracks in Reaper TCP and in GUI.
--  ### Patterns
--  * The patterns is a visual display of midi files gathered from a folder path (in settings).
--  * You can drag and drop from the list into a Reaper track to insert the pattern at mouse cursor position.
--  * Pattern paths can be added or removed from the settings tab (and force rescanned).

-- Toggle button state in Reaper
function SetButtonState(set)
    local _, name, sec, cmd, _, _, _ = reaper.get_action_context()
    if set == 1 then
      action_name = string.match(name, 'gaspard_(.-)%.lua')
      -- Get version from ReaPack
      local pkg = reaper.ReaPack_GetOwner(name)
      version = tostring(select(7, reaper.ReaPack_GetEntryInfo(pkg)))
      reaper.ReaPack_FreeEntry(pkg)
    end
    reaper.SetToggleCommandState(sec, cmd, set or 0)
    reaper.RefreshToolbar2(sec, cmd)
end
SetButtonState(1)

-- Load Utilities
dofile(reaper.GetResourcePath() ..
       '/Scripts/ReaTeam Extensions/API/imgui.lua')
  ('0.9.3.2') -- current version at the time of writing the script

script_path = debug.getinfo(1, 'S').source:match [[^@?(.*[\/])[^\/]-$]]
package.path = package.path..';'..script_path .. '?.lua' -- GET DIRECTORY FOR REQUIRE
gpmsys = require('Utilities/gpm_System')
gpmgui = require('Utilities/gpm_DisplayWindow')

local json_file_path = reaper.GetResourcePath()..'/Scripts/Gaspard ReaScripts/JSON'
package.path = package.path .. ';' .. json_file_path .. '/?.lua'
gson = require('json_utilities_lib')

settings_path = script_path..'Utilities/gaspard_'..action_name..'_settings.json'

gpmsys.Init()

reaper.defer(gpmgui.Loop)
reaper.atexit(SetButtonState)
