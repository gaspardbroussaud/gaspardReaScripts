-- @description Track Visibility Tool
-- @author gaspard
-- @version 0.0.7
-- @provides
--    [nomain] Utilities/*.lua
-- @changelog WIP: Ready for QA.
-- @about GUI to hide and show tracks in TCP and mixer with mute and locking.

-- Global Variables
ScriptVersion = "v0.0.7"
ScriptName = 'TRACK VISIBILITY TOOL'
Settings = {
    link_select = false,
    link_collapse = false,
    tracks = {}
}

settings_path = debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]]..'/Data/settings_file.dat'
------
-- Load Utilities
dofile(reaper.GetResourcePath() ..
       '/Scripts/ReaTeam Extensions/API/imgui.lua')
  ('0.9.0.2') -- current version at the time of writing the script
package.path = package.path..';'..debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]] .. "?.lua;" -- GET DIRECTORY FOR REQUIRE
require('Utilities/UserInterface')
require('Utilities/System')

local proj = 0
System_SetButtonState(1)
System_SetVariables()
System_GetSelectedTracksTable()
System_ReadSettingsFile()
reaper.defer(Gui_Loop)
reaper.atexit(System_SetButtonState)
