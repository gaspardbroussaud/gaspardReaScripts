--@noindex
--@description Pattern generator functions
--@author gaspard
--@about All functions used in gaspard_Pattern generator.lua script

local System = {}

-- Global variables
local project_name = reaper.GetProjectName(0)
local project_id, project_path = reaper.EnumProjects(-1)
System.focus_main_window = false
System.Shift = false
System.Ctrl = false
System.separator = reaper.GetOS():match('Win') and '\\' or '/'
System.show_pattern_export = false

-- Sample track variables
System.parent_obj_track = nil
System.samples = {}
System.max_samples = 9
local ext_PatternGenerator = 'gaspard_PatternGenerator'
local key_parent_track = 'ParentTrack_GUID'
local key_in_midi_track = 'InMidiTrack_GUID'

-- Presets variables
System.presets = {}

-- Patterns variables
System.patterns = {}

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

    System.Shift = reaper.ImGui_IsKeyDown(ctx, reaper.ImGui_Key_LeftShift())
    System.Ctrl = reaper.ImGui_IsKeyDown(ctx, reaper.ImGui_Key_LeftCtrl())
end

-- Copy file to new file
local function CopyFile(src, dest)
    local input = io.open(src, 'rb')
    if not input then return false, 'Source file not found' end

    local output = io.open(dest, 'wb')
    if not output then
        input:close()
        return false, 'Failed to create destination file'
    end

    local data = input:read('*a')
    output:write(data)

    input:close()
    output:close()
    return true, 'Success'
end

-- Init Settings from file
local function InitSettings()
    local settings_version = '0.0.2b'
    default_settings = {
        version = settings_version,
        order = {'obey_note_off', 'release', 'release_amount'},
        obey_note_off = {
            value = true,
            name = 'Obey note off',
            description = 'Obey not off activated on track insert.'
        },
        release = {
            value = true,
            name = 'Release',
            description = 'Release is applied on track insert.'
        },
        release_amount = {
            value = 40,
            name = 'Release amount',
            description = 'Release amount in milliseconds.'
        }
    }
    Settings = gson.LoadJSON(settings_path, default_settings)
    if settings_version ~= Settings.version then
        reaper.MB("Settings are erased due to update in file.\nPlease excuse this behaviour.\nThis won't happen once released.", 'WARNING', 0)
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

-- Get parent track from GUID
local function GetTrackFromExtState(extname, key)
    local retval, GUID = reaper.GetProjExtState(0, extname, key)
    if not retval then return nil end
    local track = reaper.BR_GetMediaTrackByGUID(0, GUID)
    return track
end

-- Get all child tracks from parent
local function GetChildTracks(parent)
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

-- Sample track creation ------
-- Declare samples list if parent exists on script launch
local function DeclareSamplesList(parent)
    local child_tracks = GetChildTracks(parent)
    for i = 1, System.max_samples do
        System.samples[i] = {}
    end
    for _, track in ipairs(child_tracks) do
        local _, index = reaper.GetSetMediaTrackInfo_String(track, 'P_EXT:gaspard_PatternGenerator:SampleIndex', '', false)
        if index then
            local _, name = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', '', false)
            local _, path = reaper.GetSetMediaTrackInfo_String(track, 'P_EXT:gaspard_PatternGenerator:SamplePath', '', false)
            System.samples[index] = {name = name, path = path, track = track}
        end
    end
end

function System.SamplesListUpdate()
    local parent_track = GetTrackFromExtState(ext_PatternGenerator, key_parent_track)
    local child_tracks = GetChildTracks(parent_track)
    for _, track in ipairs(child_tracks) do
        local _, index = reaper.GetSetMediaTrackInfo_String(track, 'P_EXT:gaspard_PatternGenerator:SampleIndex', '', false)
        index = tonumber(index)
        if index and index ~= '' then
            local _, name = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', '', false)
            local _, path = reaper.GetSetMediaTrackInfo_String(track, 'P_EXT:gaspard_PatternGenerator:SamplePath', '', false)
            System.samples[index] = {name = name, path = path, track = track}
        end
    end
end

-- Add parent track if not exist with MIDI input track as hidden child
local function CreateParentSamplesTrack()
    local parent_track = GetTrackFromExtState(ext_PatternGenerator, key_parent_track)
    if parent_track then
        DeclareSamplesList(parent_track)
        return
    end

    reaper.PreventUIRefresh(1)
    reaper.Undo_BeginBlock()

    --local track_count = reaper.CountTracks(0)

    -- Parent track ------
    reaper.InsertTrackInProject(0, 0, 0)
    parent_track = reaper.GetTrack(0, 0)
    reaper.GetSetMediaTrackInfo_String(parent_track, 'P_NAME', 'DRUMS', true)
    reaper.SetMediaTrackInfo_Value(parent_track, 'I_FOLDERDEPTH', 1)
    reaper.SetMediaTrackInfo_Value(parent_track, 'I_FOLDERCOMPACT', 1)
    reaper.GetSetMediaTrackInfo_String(parent_track, 'P_EXT:gaspard_PatternGenerator:MasterTrack', 'true', true)
    local GUID = reaper.GetTrackGUID(parent_track)
    reaper.SetProjExtState(0, ext_PatternGenerator, key_parent_track, GUID)

    DeclareSamplesList(parent_track)

    -- MIDI inputs track ------
    reaper.InsertTrackInProject(0, 1, 0)
    local in_midi_track = reaper.GetTrack(0, 1)
    reaper.GetSetMediaTrackInfo_String(in_midi_track, 'P_NAME', 'PATTERN_GENERATOR_MIDI_INPUTS', true)
    reaper.SetMediaTrackInfo_Value(in_midi_track, 'I_RECARM', 1)
    reaper.SetMediaTrackInfo_Value(in_midi_track, 'I_RECMON', 1)
    reaper.SetMediaTrackInfo_Value(in_midi_track, 'I_RECMODE', 0)
    reaper.SetMediaTrackInfo_Value(in_midi_track, 'I_FOLDERDEPTH', -1)
    local midi_GUID = reaper.GetTrackGUID(in_midi_track)
    reaper.SetProjExtState(0, ext_PatternGenerator, key_in_midi_track, midi_GUID)

    reaper.Undo_EndBlock('gaspard_Pattern generator_Add parent and midi inputs tracks', -1)
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
end

-- Get index in TCP of parent track
function System.GetParentTrackIndex()
    local parent_track = GetTrackFromExtState(ext_PatternGenerator, key_parent_track)
    if not parent_track then return nil, nil end
    local index = reaper.GetMediaTrackInfo_Value(parent_track, 'IP_TRACKNUMBER') - 1
    return parent_track, index
end

function System.GetMidiTrackIndex()
    local midi_track = GetTrackFromExtState(ext_PatternGenerator, key_in_midi_track)
    if not midi_track then return nil, nil end
    local index = reaper.GetMediaTrackInfo_Value(midi_track, 'IP_TRACKNUMBER') - 1
    return midi_track, index
end

function System.GetSamplesTracks()
    local parent_track, parent_index = System.GetParentTrackIndex()
    if parent_track and parent_index then
        local sample_tracks = GetChildTracks(parent_track)
        table.remove(sample_tracks)

        if #sample_tracks > 0 then
            return true, sample_tracks, parent_track, parent_index
        end
    end

    return false, nil, nil, nil
end

local function SetSampleTrackParams(name, filepath, index, track)
    reaper.GetSetMediaTrackInfo_String(track, 'P_EXT:gaspard_PatternGenerator:SamplePath', tostring(filepath), true)
    reaper.GetSetMediaTrackInfo_String(track, 'P_EXT:gaspard_PatternGenerator:SampleIndex', tostring(index), true)

    -- Set track name
    reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', name, true)

    -- Insert fx with sample
    local fx_index = reaper.TrackFX_AddByName(track, 'VSTi: ReaSamplOmatic5000 (Cockos)', false, -1000)
    reaper.TrackFX_SetNamedConfigParm(track, fx_index, '+FILE0', filepath)
    reaper.TrackFX_SetNamedConfigParm(track, fx_index, 'DONE', '')
    reaper.TrackFX_SetParam(track, fx_index, 2, 0) -- Parameter index for "Min vol" is 2 (value 0 == -inf)
    if Settings.obey_note_off.value then
        reaper.TrackFX_SetParam(track, fx_index, 11, 1) -- Parameter index for "Obey Note Off" is 11 (value 1 == true)
    end
    if Settings.release.value then
        local ms = Settings.release_amount.value / 2000
        reaper.TrackFX_SetParam(track, fx_index, 10, ms) -- Parameter index for "Release" is 10 (value 1 == 2s)
    end

    -- Send midi inputs from midi track to track
    local midi_track = GetTrackFromExtState(ext_PatternGenerator, key_in_midi_track)
    reaper.CreateTrackSend(midi_track, track)
    reaper.SetTrackSendInfo_Value(track, -1, 0, 'I_SRCCHAN', -1)
    reaper.SetTrackSendInfo_Value(track, -1, 0, 'I_MIDIFLAGS', 0)
    reaper.SetTrackSendInfo_Value(track, -1, 0, 'B_MUTE', 1)
end

-- Overall add parent and samples with undo block
function System.InsertSampleTrack(name, filepath, sample_index)
    local parent_track, parent_index = System.GetParentTrackIndex()
    if parent_track and parent_index then
        -- Get insert index track position
        local insert_index = 1
        local child_tracks = GetChildTracks(parent_track)
        table.remove(child_tracks)
        if #child_tracks > 0 then
            local count = 0
            for i, sample in ipairs(System.samples) do
                if sample and sample.name then
                    count = count + 1
                    if i == sample_index then
                        insert_index = count
                        break
                    end
                end
            end
        end

        reaper.PreventUIRefresh(1)
        reaper.Undo_BeginBlock()

        -- Insert track
        local track_index = parent_index + insert_index
        reaper.InsertTrackInProject(0, track_index, 0)
        local inserted_track = reaper.GetTrack(0, track_index)

        SetSampleTrackParams(name, filepath, sample_index, inserted_track)

        reaper.Undo_EndBlock('gaspard_Pattern generator_Add drums tracks', -1)
        reaper.PreventUIRefresh(-1)
        reaper.UpdateArrange()

        return inserted_track
    else
        return nil
    end
end

function System.ReplaceSample(index)
    local track = System.samples[index].track
    reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', System.samples[index].name, true)
    local fx_index = reaper.TrackFX_GetByName(track, 'VSTi: ReaSamplOmatic5000 (Cockos)', false)
    reaper.TrackFX_SetNamedConfigParm(track, fx_index, '+FILE0', System.samples[index].path)
    reaper.TrackFX_SetNamedConfigParm(track, fx_index, 'DONE', '')
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
    local sanitized = string.gsub(filename, forbidden_chars, '')
    return sanitized
end

-- Save preset file
function System.SavePreset(name, preset)
    name = SanitizeFileName(name)
    local path = presets_path..'/'..name:gsub('%.json$', '')..'.json'
    CreateDirectoryIfNotExists(presets_path)
    gson.SaveJSON(path, preset)
end

-- Get all preset files from folder
function System.ScanPresetFiles()
    local files = {}
    local index = 0
    local file = reaper.EnumerateFiles(presets_path, index)

    while file do
        if file:match('%.json$') then
            table.insert(files, {path = presets_path..'/'..file, name = file:gsub('%.json$', ''), selected = false})
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
        if file:match('%.MID$') or file:match('%.mid$') then
            local name = file:gsub('%.MID$', '')
            name = file:gsub('%.mid$', '')
            table.insert(files, {path = patterns_path..'/'..file, name = name, selected = false})
        end
        index = index + 1
        file = reaper.EnumerateFiles(patterns_path, index)
    end

    System.patterns = files
end

-- Get Samples directory for current project
local function GetSamplesDirectory()
    return reaper.GetProjectPathEx(0)..System.separator..'RS5K Samples'
end

-- Copy imported files in GUI to project directory
function System.CopyFileToProjectDirectory(name, path)
    local dir_path = path:match('(.+)[\\/][^\\/]+$') or path
    if dir_path == path then return false, path end
    local sample_path = GetSamplesDirectory()
    if dir_path ~= sample_path then
        CreateDirectoryIfNotExists(sample_path)
        CopyFile(path, sample_path..System.separator..name)
        return true, sample_path..System.separator..name
    end
    return false, path
end

function System.CheckFileInDirectory(file_path, file_name, dir_path)
    dir_path = dir_path or GetSamplesDirectory()
    local dir_file = io.open(dir_path..System.separator..file_name, 'rb')
    if not dir_file then return false, file_path end

    local file = io.open(file_path, 'rb')
    if not file then
        io.close(dir_file)
        return false, nil
    end

    local dir_data = dir_file:read('*a')
    local file_data = file:read('*a')
    if dir_data == file_data then
        io.close(dir_file)
        io.close(file)
        return true, dir_path..System.separator..file_name
    end

    if dir_file then io.close(dir_file) end
    if file then io.close(file) end
    return false, nil
end

function System.Init()
    InitSettings()
    CreateParentSamplesTrack()
    System.ScanPatternFiles()
end

-- Delete all tracks on exit
function System.ClearOnExitIfEmpty()
    local parent_track = GetTrackFromExtState(ext_PatternGenerator, key_parent_track)
    if not parent_track then return end

    reaper.PreventUIRefresh(1)
    reaper.Undo_BeginBlock()

    local tracks = GetChildTracks(parent_track)
    for _, track in ipairs(tracks) do
        reaper.DeleteTrack(track)
    end

    reaper.SetProjExtState(0, ext_PatternGenerator, key_parent_track, '')
    reaper.DeleteTrack(parent_track)

    reaper.Undo_EndBlock('gaspard_Pattern generator_Clear elements', -1)
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
end

return System
