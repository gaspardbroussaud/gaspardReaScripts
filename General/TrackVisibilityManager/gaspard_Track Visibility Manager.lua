-- @description Track Visibility Manager
-- @author gaspard
-- @version 1.4.1
-- @provides
--    [nomain] Utilities/*.lua
-- @changelog
--  - Fix re-shown tracks staying locked and muted (show -> unlock -> restore mute order)
--  - Mute/solo links and buttons enabled by default
--  - New GUI style shared with GaspaReaLauncher (GUI_STYLE / GUI_SYS libraries, icon top bar, floating settings panel)
--  - Migrate to the ReaImGui 0.10 module API (ImGui.*)
--  - Fix hidden tracks displayed as visible (number used as boolean in checkbox)
--  - Fix selection not restored correctly after hide/show (hidden tracks stayed selected)
--  - Fix empty undo points flooding the undo history when "Link TCP collapse" is enabled
--  - Fix solo button setting "solo in place" when clicking an implied solo track
--  - Fix F key, Ctrl+A and Escape triggering while typing in a text field or when window is not focused
--  - Fix Ctrl/Shift detection when several modifiers are held
--  - Fix GUI collapse state lost when the project changes (unlinked mode)
--  - Hide/show folder children without SWS (SWS no longer required)
--  - Mute state before hiding is stored in the project (P_EXT) instead of a track height hack (old hidden tracks still supported)
--  - Command ID setting accepts numeric and named command IDs
--  - Big performance improvement: track data computed in one pass, only visible rows are drawn
--  - Settings are kept (merged) on update and new settings appear automatically
-- @about
--  - GUI to hide and show tracks in TCP and mixer with mute and locking.
--  - You can change settings for links between manager and TCP to control selection, mute, solo, and hide/show tracks.
--  - Set an action ID in settings to use with F key while in manager window's focus.

local SCRIPT_VERSION = "1.4.1"
local script_path = debug.getinfo(1, "S").source:match([[^@?(.*[\/])[^\/]-$]])

-- Dependencies check
if not reaper.ImGui_GetBuiltinPath then
    reaper.MB("This script requires ReaImGui (0.10 or newer).\nInstall it with ReaPack: Extensions > ReaPack > Browse packages > ReaImGui.", "Track Visibility Manager", 0)
    return
end
package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local imgui_ok, imgui_module = pcall(require, 'imgui')
if not imgui_ok then
    reaper.MB("Could not load ReaImGui Lua module.\nPlease update ReaImGui to 0.10 or newer.", "Track Visibility Manager", 0)
    return
end
ImGui = imgui_module('0.10')

package.path = package.path .. ';' .. script_path .. "?.lua"

local json_file_path = reaper.GetResourcePath() .. "/Scripts/Gaspard ReaScripts/JSON"
package.path = package.path .. ";" .. json_file_path .. "/?.lua"
local json_ok, json_lib = pcall(require, "json_utilities_lib")
if not json_ok then
    reaper.MB("Missing dependency: json_utilities_lib.lua\nExpected in:\n" .. json_file_path .. "\n\nInstall/update it from the Gaspard ReaScripts repository.", "Track Visibility Manager", 0)
    return
end
gson = json_lib
local JSON_VERSION = "1.0.6"
if not gson.version or gson.version_less(gson.version, JSON_VERSION) then
    reaper.MB('Please update gaspard "json_utilities_lib" to version ' .. JSON_VERSION .. ' or higher.', "Track Visibility Manager", 0)
    return
end

-- gaspard GUI libraries (style, fonts, icons, icon buttons)
local libraries_path = reaper.GetResourcePath() .. "/Scripts/Gaspard ReaScripts/Libraries/"
local style_ok, style_lib = pcall(dofile, libraries_path .. "GUI_STYLE.lua")
local sys_ok, sys_lib = pcall(dofile, libraries_path .. "GUI_SYS.lua")
if not style_ok or not sys_ok then
    reaper.MB("Missing dependency: GUI_STYLE.lua / GUI_SYS.lua\nExpected in:\n" .. libraries_path .. "\n\nInstall/update them from the Gaspard ReaScripts repository.", "Track Visibility Manager", 0)
    return
end
GUI_STYLE, GUI_SYS = style_lib, sys_lib

-- Global Variables
version = SCRIPT_VERSION
window_name = 'TRACK VISIBILITY MANAGER'

local _, script_file, section_id, command_id = reaper.get_action_context()
action_name = script_file:match("gaspard_(.-)%.lua$") or "Track Visibility Manager"
settings_path = script_path .. 'Utilities/gaspard_' .. action_name .. '_settings.json'

System = require('Utilities/System')
local Gui = require('Utilities/UserInterface')

local function SetButtonState(set)
    if section_id and command_id and command_id > 0 then
        reaper.SetToggleCommandState(section_id, command_id, set)
        reaper.RefreshToolbar2(section_id, command_id)
    end
end

SetButtonState(1)
System.InitSettings()
Gui.Init()

reaper.defer(Gui.Loop)
reaper.atexit(function() SetButtonState(0) end)
