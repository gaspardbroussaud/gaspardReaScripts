-- @description Track Visibility Tool
-- @author gaspard
-- @version 1.0.6
-- @provides
--    [nomain] Utilities/*.lua
-- @changelog
--  • Bugfix: Removed flicker on collapse track to state 1 (medium) with link tcp collapse enabled
--  • Bugfix: Unlink selection at start if setting disabled
--  • Gui fixes and improvements
--  • Added debug lines in script
-- @about GUI to hide and show tracks in TCP and mixer with mute and locking.

-- Global Variables
ScriptVersion = "v1.0.6"
ScriptName = 'TRACK VISIBILITY MANAGER'
Settings = {
    link_select = false,
    link_collapse = false,
    tracks = {}
}

settings_path = debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]]..'/Utilities/settings_file.txt'
------
-- Load Utilities
dofile(reaper.GetResourcePath() ..
       '/Scripts/ReaTeam Extensions/API/imgui.lua')
  ('0.9.0.2') -- current version at the time of writing the script

package.path = package.path..';'..debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]] .. "?.lua" -- GET DIRECTORY FOR REQUIRE
require('Utilities/UserInterface')
require('Utilities/System')

System_SetButtonState(1)
System_SetVariables()
System_GetSelectedTracksTable()
System_ReadSettingsFile()
reaper.defer(Gui_Loop)
reaper.atexit(System_SetButtonState)
