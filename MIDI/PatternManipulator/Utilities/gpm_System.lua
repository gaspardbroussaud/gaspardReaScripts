--@noindex
--@description Pattern manipulator utility System
--@author gaspard
--@about Pattern manipulator utility

local gpmsys = {}

-- Global variables
gpmsys.separator = reaper.GetOS():match('Win') and '\\' or '/'
extname_global = "g_PGM_"
extkey_parent_track = "PARENT_TRACK_GUID"
gpmsys.parent_track = nil

-- Samples variables
gpmsys_samples = require("Utilities/gpm_SystemSamples")
gpmsys.sample_list = {}
gpmsys.selected_sample_index = 0

-- Patterns variables
gpmsys_patterns = require("Utilities/gpm_SystemPatterns")
local local_pattern_path = debug.getinfo(1, 'S').source:match [[^@?(.*[\/])[^\/]-$]]--..'Patterns'
local_pattern_path = string.gsub(local_pattern_path, '\\', gpmsys.separator)
local_pattern_path = string.gsub(local_pattern_path, '/', gpmsys.separator)
local_pattern_path = string.gsub(local_pattern_path, 'Utilities', 'Patterns')

local function SettingsInit()
    local settings_version = '0.0.1b'
    local default_settings = {
        version = settings_version,
        order = {'project_based_parent'},
        project_based_parent = {
            value = false,
            name = 'Project based parent',
            description = 'Use one track as parent for all sample tracks.'
        },
        obey_note_off = {
            value = true,
            name = 'Obey note off',
            description = 'Obey note off on sample insert.'
        },
        attack_amount = {
            value = 0.96,
            name = 'Attack time',
            description = 'Attack time in milliseconds.'
        },
        decay_amount = {
            value = 248,
            name = 'Decay time',
            description = 'Decay time in milliseconds.'
        },
        sustain_amount = {
            value = 0,
            name = 'Sustain volume',
            description = 'Sustain volume in db.'
        },
        release_amount = {
            value = 40,
            name = 'Release time',
            description = 'Release time in milliseconds.'
        },
        selection_link = {
            value = false,
            name = 'Selection link',
            description = 'Link track and GUI selection on GUI selected (not track selected).'
        },
        pattern_folder_paths = {
            value = {local_pattern_path},
            name = 'Patterns folder',
            description = 'Patterns folders OS location path.'
        }
    }
    Settings = gson.LoadJSON(settings_path, default_settings)
    if settings_version ~= Settings.version then
        reaper.ShowConsoleMsg("\n!!! WARNING !!! (gaspard_Pattern manipulator.lua)\n")
        reaper.ShowConsoleMsg("Settings are erased due to update in settings file.\nPlease excuse this behaviour.\nThis won't happen once released.\n")
        reaper.ShowConsoleMsg("Now in version: "..settings_version.."\n")
        --reaper.MB("Settings are erased due to update in file.\nPlease excuse this behaviour.\nThis won't happen once released.", 'WARNING', 0)
        Settings = gson.SaveJSON(settings_path, default_settings)
        Settings = gson.LoadJSON(settings_path, Settings)
    end
end

function gpmsys.Init()
    SettingsInit()
    gpmsys.sample_list = gpmsys_samples.CheckForSampleTracks()
    gpmsys_patterns.ScanPatternFiles()
end

function gpmsys.GetTrackFromExtState(extname, extkey)
    local retval, GUID = reaper.GetProjExtState(0, extname, extkey)
    if not retval then return nil end
    return reaper.BR_GetMediaTrackByGUID(0, GUID)
end

function gpmsys.SetTrackToExtState(track, extname, extkey)
    reaper.SetProjExtState(0, extname, extkey, reaper.GetTrackGUID(track))
end

function gpmsys.EncodeToBase64(waveform)
    local b64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local function to_binary(num)
        local bin = ""
        for i = 7, 0, -1 do
            bin = bin .. ((num >> i) & 1)
        end
        return bin
    end

    local binary_data = ""
    for _, v in ipairs(waveform) do
        local byte = math.floor((v + 1) * 127.5)  -- Normalize from [-1,1] to [0,255]
        binary_data = binary_data .. to_binary(byte)
    end

    local padding = #binary_data % 6
    if padding > 0 then
        binary_data = binary_data .. string.rep("0", 6 - padding)
    end

    local encoded = ""
    for i = 1, #binary_data, 6 do
        local chunk = tonumber(binary_data:sub(i, i + 5), 2) or 0
        encoded = encoded .. b64:sub(chunk + 1, chunk + 1)
    end

    while (#encoded % 4) ~= 0 do
        encoded = encoded .. "="
    end

    return encoded
end

function gpmsys.DecodeFromBase64(encoded)
    local b64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local binary_data = ""

    -- Remove padding characters
    encoded = encoded:gsub("=", "")

    -- Convert Base64 characters to binary
    for i = 1, #encoded do
        local char = encoded:sub(i, i)
        local index = b64:find(char, 1, true) - 1
        if index then
            -- Convert to a 6-bit binary string
            local bin = ""
            for j = 5, 0, -1 do
                bin = bin .. ((index >> j) & 1)
            end
            binary_data = binary_data .. bin
        end
    end

    local waveform = {}
    for i = 1, #binary_data, 8 do
        local byte_str = binary_data:sub(i, i + 7)
        if #byte_str == 8 then  -- Ensure we have a full byte
            local byte = 0
            for j = 1, 8 do
                byte = byte * 2 + tonumber(byte_str:sub(j, j))
            end
            table.insert(waveform, (byte / 127.5) - 1)  -- Convert back to [-1, 1] range
        end
    end

    return waveform
end

return gpmsys
