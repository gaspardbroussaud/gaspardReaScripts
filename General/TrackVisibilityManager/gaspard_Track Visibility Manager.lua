-- @description Track Visibility Manager
-- @author gaspard
-- @version 1.3.3
-- @provides
--    [nomain] Utilities/*.lua
-- @changelog
--  - Updated GUI style fetch (internal)
--  - Increased font size
-- @about
--  - GUI to hide and show tracks in TCP and mixer with mute and locking.
--  - You can change settings for links between manager and TCP to control selection, mute, solo, and hide/show tracks.
--  - Set an action ID in settings to use with F key while in manager window's focus.

-- Global Variables
ScriptVersion = "v1.3.3"
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
System_GetGuiStylesFromFile()
System_SetVariables()
System_GetSelectedTracksTable()
System_ReadSettingsFile()
reaper.defer(Gui_Loop)
reaper.atexit(System_SetButtonState)
