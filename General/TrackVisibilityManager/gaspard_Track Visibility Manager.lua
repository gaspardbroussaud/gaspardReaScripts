-- @description Track Visibility Manager
-- @author gaspard
-- @version 1.3.11
-- @provides
--    [nomain] Utilities/*.lua
-- @changelog
--  - Update ReaImGui version
-- @about
--  - GUI to hide and show tracks in TCP and mixer with mute and locking.
--  - You can change settings for links between manager and TCP to control selection, mute, solo, and hide/show tracks.
--  - Set an action ID in settings to use with F key while in manager window's focus.

-- Global Variables
version = "1.3.11"
window_name = 'TRACK VISIBILITY MANAGER'

------
-- Load Utilities
dofile(reaper.GetResourcePath() ..
       '/Scripts/ReaTeam Extensions/API/imgui.lua')
  ('0.10.0.1') -- current version at the time of writing the script

package.path = package.path..';'..debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]] .. "?.lua" -- GET DIRECTORY FOR REQUIRE
require('Utilities/UserInterface')
require('Utilities/System')

local json_file_path = reaper.GetResourcePath().."/Scripts/Gaspard ReaScripts/JSON"
package.path = package.path .. ";" .. json_file_path .. "/?.lua"
gson = require("json_utilities_lib")

System_SetButtonState(1)
settings_path = debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]]..'/Utilities/gaspard_'..action_name..'_settings.json'

System_InitSystemVariables()
System_GetGuiStylesFromFile()
System_ResetVariables()
System_GetSelectedTracksTable()
reaper.defer(Gui_Loop)
reaper.atexit(System_SetButtonState)
