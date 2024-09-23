-- @description Track Visibility Tool
-- @author gaspard
-- @version 0.0.1
-- @provides
--    [nomain] Utilities/*.lua
-- @changelog WIP: Multiple files structure.
-- @about GUI to hide and show tracks in TCP and mixer with mute and locking.

-- SHOW IMGUI DEMO --
--reaper.Main_OnCommand(reaper.NamedCommandLookup("_RS6b4644d86854e10895485f184942fb69ecc26177"), 0)

-- Global Variables
ScriptVersion = "v0.0.1"
ScriptName = 'Track Visibility Tool'
Settings = {
    link_select = false,
    link_collapse = false,
    tracks = {}
}

settings_path = debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]]..'/Data/settings_file'
------
-- Load Utilities
dofile(reaper.GetResourcePath() ..
       '/Scripts/ReaTeam Extensions/API/imgui.lua')
  ('0.9.0.2') -- current version at the time of writing the script
package.path = package.path..';'..debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]] .. "?.lua;" -- GET DIRECTORY FOR REQUIRE
require('Utilities/UserInterface')
require('Utilities/System')
--[[json = require('Utilities/json')
require('Data')]]

local proj = 0
System_SetButtonState(1)
System_SetVariables()
System_GetSelectedTracksTable()
System_GetTracksTable()
System_UpdateTrackCollapse()
reaper.defer(Gui_Loop)
reaper.atexit(System_SetButtonState)
