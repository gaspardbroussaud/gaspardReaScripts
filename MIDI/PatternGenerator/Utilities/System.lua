--@noindex
--@description Pattern generator functions
--@author gaspard
--@about All functions used in gaspard_Pattern generator.lua script

local System = {}

local path_to_file = "C:/Users/Gaspard/Documents/Local_ReaScripts/test_patterns/Media/RS5K samples/Kick.wav"

-- Global variables
local project_name = reaper.GetProjectName(0)
local project_id, project_path = reaper.EnumProjects(-1)
System.focus_main_window = false

-- Object track variables
System.parent_obj_track = nil
System.objects = {{name = "Kick", path = path_to_file}}

-- Presets variables
System.presets = {}

-- Global funcitons ------
-- Check current focused project
local function ProjectChange()
    local temp_project_id, temp_project_path = reaper.EnumProjects(-1)
    if project_path ~= temp_project_path or project_id ~= temp_project_id or project_name ~= reaper.GetProjectName(0) then
        return true
    else
        return false
    end
end

-- Update userdatas when changing Reaper project
function System.ProjectUpdates()
    if ProjectChange() then
        project_name = reaper.GetProjectName(0)
        project_id, project_path = reaper.EnumProjects(-1)
    end
end

-- Init Settings from file
function System.InitSettings()
    local settings_version = "0.0.1b"
    default_settings = {
        version = settings_version,
        order = {""}
    }
    Settings = gson.LoadJSON(settings_path, default_settings)
    if settings_version ~= Settings.version then
        reaper.MB("Settings are erased due to update in file.\nPlease excuse this behaviour.\nThis won't happen once released.", "WARNING", 0)
        Settings = gson.SaveJSON(settings_path, default_settings)
        Settings = gson.LoadJSON(settings_path, Settings)
    end
end

-- Reposition an item to another index in a given table
function System.RepositionInTable(table_update, from_index, to_index)
    if from_index == to_index then return table_update end

    local item = table_update[from_index]
    table.remove(table_update, from_index)
    table.insert(table_update, to_index, item)

    return table_update
end

-- Object track creation ------
-- Add parent track if not exist
local function CreateParentObjectsTrack()
    local add_parent = true
    local track_count = reaper.CountTracks(0)
    for i = 0, track_count - 1 do
        local track = reaper.GetTrack(0, i)
        if track == System.parent_obj_track then
            add_parent = false
            break
        end
    end
    if add_parent then
        reaper.InsertTrackInProject(0, track_count, 0)
        local parent_track = reaper.GetTrack(0, track_count)
        reaper.GetSetMediaTrackInfo_String(parent_track, "P_NAME", "DRUMS", true)
        reaper.SetMediaTrackInfo_Value(parent_track, "I_FOLDERDEPTH", 1)
        System.parent_obj_track = parent_track
    end
end

-- Add object tracks
local function CreateIndividualObjectTrack()
    for i, object in ipairs(System.objects) do
        local depth = 0
        if i == #object then depth = -1 end
        track_count = reaper.CountTracks(0)

        reaper.InsertTrackInProject(0, track_count, 0)
        local track = reaper.GetTrack(0, track_count)
        reaper.GetSetMediaTrackInfo_String(track, "P_NAME", object.name, true)
        reaper.SetMediaTrackInfo_Value(track, "I_FOLDERDEPTH", depth)
        local fx_index = reaper.TrackFX_AddByName(track, "VSTi: ReaSamplOmatic5000 (Cockos)", false, -1000)
        reaper.TrackFX_SetNamedConfigParm(track, fx_index, "+FILE0", object.path)
        reaper.TrackFX_SetNamedConfigParm(track, fx_index, "DONE", "")
    end
end

-- Overall add parent and objects with undo block
function System.CreateObjectTracks()
    if #System.objects > 0 then
        reaper.PreventUIRefresh(1)
        reaper.Undo_BeginBlock()

        CreateParentObjectsTrack()

        CreateIndividualObjectTrack()

        reaper.Undo_EndBlock("gaspard_Pattern generator_Add drums tracks", -1)
        reaper.PreventUIRefresh(-1)
        reaper.UpdateArrange()
    end
end

-- Preset systems ------
-- Create presets directory if not exist
local function CreateDirectoryIfNotExists(path)
    local attr = reaper.EnumerateFiles(path, 0)
    if not attr then
        reaper.RecursiveCreateDirectory(path, 0)
    end
end

-- Set filename string to os compatible name
local function SanitizeFileName(filename)
    local forbidden_chars = '[<>:"/\\|?*]'
    local sanitized = string.gsub(filename, forbidden_chars, "")
    return sanitized
end

-- Save preset file
function System.SavePreset(name, preset)
    name = SanitizeFileName(name)
    local path = presets_path.."/"..name:gsub("%.json$", "")..".json"
    CreateDirectoryIfNotExists(presets_path)
    gson.SaveJSON(path, preset)
end

-- Get all preset files from folder
function System.ScanPresetFiles()
    local files = {}
    local index = 0
    local file = reaper.EnumerateFiles(presets_path, index)

    while file do
        if file:match("%.json$") then
            table.insert(files, {path = presets_path.."/"..file, name = file:gsub("%.json$", ""), selected = false})
        end
        index = index + 1
        file = reaper.EnumerateFiles(presets_path, index)
    end

    System.presets = files
end

return System
