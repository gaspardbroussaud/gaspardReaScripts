--@description Complete renamer
--@author gaspard
--@version 1.1.0
--@provides
--    [nomain] Utilities/*.lua
--    [nomain] Utilities/GUI_Elements/*.lua
--@changelog
--  - Migrate to the ReaImGui 0.10 module API (ImGui.*)
--  - Use the new REAPER region/marker API when available (legacy fallback kept)
--  - Fix marker/region renaming targeting the wrong marker (enumeration index vs displayed number)
--  - Fix renaming markers/regions to an empty name and keep their colors
--  - Fix inverted PreventUIRefresh calls
--  - Fix Ctrl+A crash when a data type is empty in the project
--  - Fix "%" in replace text breaking the rename, ignore empty search text
--  - Fix accents/UTF-8 characters in case rules (é -> É, élan -> Élan)
--  - Fix preset list not refreshing after save/remove (EnumerateFiles cache)
--  - Fix crash when the script is not installed through ReaPack or js_ReaScriptAPI is missing
--  - Use active take name for items, real track name (P_NAME) for tracks
--  - Big performance improvement: project is only re-read when it changes, previews are cached, lists are clipped
--  - Project is no longer marked as modified just by opening the script
--  - Link selection now also works for markers and regions (REAPER with region/marker API)
--  - Settings are kept (merged) on update instead of being erased
--  - Delete key removes selected rules, shortcuts only act when the window is focused
--@about
--  ### Complete renamer
--  - A complete renamer with selectable and editable rule blocks for items, tracks, markers and regions (may evolve).

local SCRIPT_VERSION = "1.1.0"
local script_path = debug.getinfo(1, "S").source:match([[^@?(.*[\/])[^\/]-$]])

-- Dependencies check
if not reaper.ImGui_GetBuiltinPath then
    reaper.MB("This script requires ReaImGui (0.10 or newer).\nInstall it with ReaPack: Extensions > ReaPack > Browse packages > ReaImGui.", "Complete renamer", 0)
    return
end

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua;' .. package.path
local imgui_ok, imgui_module = pcall(require, 'imgui')
if not imgui_ok then
    reaper.MB("Could not load ReaImGui Lua module.\nPlease update ReaImGui to 0.10 or newer.", "Complete renamer", 0)
    return
end
ImGui = imgui_module('0.10')

package.path = package.path .. ';' .. script_path .. "?.lua"

local json_file_path = reaper.GetResourcePath() .. "/Scripts/Gaspard ReaScripts/JSON"
package.path = package.path .. ";" .. json_file_path .. "/?.lua"
local json_ok, json_lib = pcall(require, "json_utilities_lib")
if not json_ok then
    reaper.MB("Missing dependency: json_utilities_lib.lua\nExpected in:\n" .. json_file_path .. "\n\nInstall/update it from the Gaspard ReaScripts repository.", "Complete renamer", 0)
    return
end
gson = json_lib

-- Get script name and version
local _, script_file, section_id, command_id = reaper.get_action_context()
action_name = script_file:match("gaspard_(.-)%.lua$") or "Complete renamer"
version = SCRIPT_VERSION
if reaper.ReaPack_GetOwner then
    local pkg = reaper.ReaPack_GetOwner(script_file)
    if pkg then
        local ok, _, _, _, _, _, _, pkg_version = pcall(reaper.ReaPack_GetEntryInfo, pkg)
        if ok and pkg_version and pkg_version ~= "" then version = tostring(pkg_version) end
        reaper.ReaPack_FreeEntry(pkg)
    end
end

settings_path = script_path .. 'Utilities/gaspard_' .. action_name .. '_settings.json'
rule_default_path = script_path .. 'Utilities/rule_default.json'
presets_path = script_path .. 'Presets'

System = require('Utilities/System')
local Gui = require('Utilities/UserInterface')

-- Toggle button state in Reaper
local function SetButtonState(set)
    if section_id and command_id and command_id > 0 then
        reaper.SetToggleCommandState(section_id, command_id, set)
        reaper.RefreshToolbar2(section_id, command_id)
    end
end

local function OnExit()
    if Settings and Settings.clean_rpp.value then System.CleanExtState() end
    SetButtonState(0)
end

SetButtonState(1)
System.InitSettings()
Gui.Init()

reaper.defer(Gui.Loop)
reaper.atexit(OnExit)
