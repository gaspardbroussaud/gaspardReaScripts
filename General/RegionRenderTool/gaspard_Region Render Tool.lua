-- @noindex
-- @description Region Render Tool
-- @author gaspard
-- @version 0.0.1
-- @provides
--    [nomain] Utilities/*.lua
-- @changelog
--  • Initial commit.
-- @about GUI to create regiosn based on selected clusters of items and assign to RRM.

-- Global Variables
ScriptVersion = "v0.0.1"
ScriptName = 'REGION RENDER TOOL'
Settings = {
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
System_ReadSettingsFile()
reaper.defer(Gui_Loop)
reaper.atexit(System_SetButtonState)
