-- @noindex
-- @description Track Visibility Tool
-- @author gaspard
-- @version 0.0.8
-- @provides
--    [nomain] Utilities/*.lua
-- @changelog WIP: Update settings_file.txt location path.
-- @about GUI to hide and show tracks in TCP and mixer with mute and locking.

-- Global Variables
ScriptVersion = "v0.0.8"
ScriptName = 'TRACK VISIBILITY TOOL'
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

-- Get Script Path then GUI Settings folder and Styles script
local gui_script_folder = debug.getinfo(1, "S").source:match([[^@?(.*[\/])[^\/]-$]])
local _, end_path = string.find(gui_script_folder, 'gaspardReaScripts\\')
if end_path ~= nil then
  gui_script_folder = string.sub(gui_script_folder, 1, end_path)..'GUI\\?.lua'
end
package.path = package.path..';'..gui_script_folder
require('GUI_Style_Settings')

gui_style_var = GUI_Style_Var_Global()
gui_style_color = GUI_Style_Color_Global()
reaper.ShowConsoleMsg(tostring(gui_style_color[0].value).."\n")

System_SetButtonState(1)
System_SetVariables()
System_GetSelectedTracksTable()
System_ReadSettingsFile()
reaper.defer(Gui_Loop)
reaper.atexit(System_SetButtonState)
