--@noindex
--@description Pattern generator functions
--@author gaspard
--@about All functions used in gaspard_Pattern generator.lua script

local System = {}

-- Global variables
local project_name = reaper.GetProjectName(0)
local project_id, project_path = reaper.EnumProjects(-1)
System.focus_main_window = false

-- Sample track variables
System.parent_obj_track = nil
System.samples = {}

-- Presets variables
System.presets = {}

-- Patterns variables
System.patterns = {}
System.selected_pattern = {}

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

-- Copy file to new file
local function CopyFile(src, dest)
    local input = io.open(src, "rb")
    if not input then return false, "Source file not found" end

    local output = io.open(dest, "wb")
    if not output then 
        input:close()
        return false, "Failed to create destination file"
    end

    local data = input:read("*a")
    output:write(data)

    input:close()
    output:close()
    return true
end

-- Init Settings from file
local function InitSettings()
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

-- Sample track creation ------
-- Add parent track if not exist with MIDI input track as hidden child
local function CreateParentSamplesTrack()
    local track_count = reaper.CountTracks(0)
    for i = 0, track_count - 1 do
        local track = reaper.GetTrack(0, i)
        local retval, _ = reaper.GetSetMediaTrackInfo_String(track, "P_EXT:PatternGenerator:MasterTrack", "", false)
        if retval then
            return
        end
    end
    reaper.InsertTrackInProject(0, track_count, 0)
    local parent_track = reaper.GetTrack(0, track_count)
    reaper.GetSetMediaTrackInfo_String(parent_track, "P_NAME", "DRUMS", true)
    reaper.SetMediaTrackInfo_Value(parent_track, "I_FOLDERDEPTH", 1)
    reaper.GetSetMediaTrackInfo_String(parent_track, "P_EXT:PatternGenerator:MasterTrack", "true", true)

    reaper.InsertTrackInProject(0, track_count + 1, 0)
    local in_midi_track = reaper.GetTrack(0, track_count + 1)
    reaper.GetSetMediaTrackInfo_String(in_midi_track, "P_NAME", "MIDI_INPUTS", true)
    reaper.SetMediaTrackInfo_Value(in_midi_track, "B_SHOWINMIXER", 0)
    reaper.SetMediaTrackInfo_Value(in_midi_track, "B_SHOWINTCP", 0)
    reaper.SetMediaTrackInfo_Value(in_midi_track, "I_RECARM", 1)
    reaper.SetMediaTrackInfo_Value(in_midi_track, "I_RECMON", 1)
    reaper.SetMediaTrackInfo_Value(in_midi_track, "I_RECMODE", 0)
end

-- Get index in TCP of parent track
local function GetParentTrackIndex()
    local track_count = reaper.CountTracks(0)
    for i = 0, track_count - 1 do
        local track = reaper.GetTrack(0, i)
        local retval, _ = reaper.GetSetMediaTrackInfo_String(track, "P_EXT:PatternGenerator:MasterTrack", "", false)
        if retval then
            return i
        end
    end
    return nil
end

-- Overall add parent and samples with undo block
function System.CreateSampleTrack(name, path, index)
    local track = nil

    reaper.PreventUIRefresh(1)
    reaper.Undo_BeginBlock()

    local parent_index = GetParentTrackIndex()
    if parent_index then
        local track_index = parent_index + index + 1
        reaper.InsertTrackInProject(0, track_index, 0)
        track = reaper.GetTrack(0, track_index)
        reaper.GetSetMediaTrackInfo_String(track, "P_NAME", name, true)
        local fx_index = reaper.TrackFX_AddByName(track, "VSTi: ReaSamplOmatic5000 (Cockos)", false, -1000)
        reaper.TrackFX_SetNamedConfigParm(track, fx_index, "+FILE0", path)
        reaper.TrackFX_SetNamedConfigParm(track, fx_index, "DONE", "")
        local midi_track = reaper.GetTrack(0, GetParentTrackIndex() + 1)
        reaper.CreateTrackSend(midi_track, track)
        reaper.SetTrackSendInfo_Value(track, -1, 0, "I_SRCCHAN", -1)
        reaper.SetTrackSendInfo_Value(track, -1, 0, "I_MIDIFLAGS", 0)
        reaper.SetTrackSendInfo_Value(track, -1, 0, "B_MUTE", 1)
    end

    reaper.Undo_EndBlock("gaspard_Pattern generator_Add drums tracks", -1)
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()

    return name, path, track
end

-- Play MIDI note for sample on track
function System.PreviewReaSamplOmatic(track)
    if not track then return end

    reaper.SetTrackSendInfo_Value(track, -1, 0, "B_MUTE", 0)
    local index = GetParentTrackIndex()

    --Play MIDI note
    reaper.StuffMIDIMessage(index, 0x90, 60, 100) -- Note On (C4, Vel 100)
    reaper.defer(function()
        reaper.StuffMIDIMessage(index, 0x80, 60, 0) -- Note Off
        reaper.SetTrackSendInfo_Value(track, -1, 0, "B_MUTE", 1)
    end)
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

-- Get all preset files from folder
function System.ScanPatternFiles()
    local files = {}
    local index = 0
    local file = reaper.EnumerateFiles(patterns_path, index)

    while file do
        if file:match("%.MID$") or file:match("%.mid$") then
            local name = file:gsub("%.MID$", "")
            name = file:gsub("%.mid$", "")
            table.insert(files, {path = patterns_path.."/"..file, name = name, selected = false})
        end
        index = index + 1
        file = reaper.EnumerateFiles(patterns_path, index)
    end

    System.patterns = files
end

-- Copy imported files in GUI to project directory
function System.CopyFileToProjectDirectory(name, path)
    local dir_path = path:match("(.+)[\\/][^\\/]+$") or path
    if dir_path == path then return path end
    local sample_path = reaper.GetProjectPathEx(0).."/RS5K Samples"
    if dir_path ~= sample_path then
        CreateDirectoryIfNotExists(sample_path)
        CopyFile(path, sample_path.."/"..name)
        return sample_path.."/"..name
    end
end

function System.Init()
    InitSettings()
    CreateParentSamplesTrack()
    System.ScanPatternFiles()
end

-- Get all child tracks from parent
function GetChildTracks(parent)
    local list = {}
    local count = reaper.CountTracks(0)
    for i = 0, count - 1 do
        local track = reaper.GetTrack(0, i)
        if reaper.GetParentTrack(track) == parent then
            table.insert(list, track)
        end
    end
    return list
end

-- Delete all tracks on exit
function System.ClearOnExitIfEmpty()
    local test = true
    if not System.samples or #System.samples < 1 or test then
        local index = GetParentTrackIndex()
        if index then
            local parent_track = reaper.GetTrack(0, index)
            local tracks = GetChildTracks(parent_track)
            for _, track in ipairs(tracks) do
                reaper.DeleteTrack(track)
            end
            reaper.DeleteTrack(parent_track)
        end
    end
end

return System
