--@noindex
--@description Layer manipulator SYSTEM
--@author gaspard

local _SYSTEM = {}

_SYSTEM.is_macOS = not reaper.GetOS():match('Win')
_SYSTEM.separator = _SYSTEM.is_macOS and '/' or '\\'

_SYSTEM.extname = "g_PGM_"
_SYSTEM.extkey_parent_track = "PARENT_TRACK_GUID"
_SYSTEM.parent_track = nil

_SYSTEM.TRACKS = require("Utilities/SYSTEM_TRACKS")
_SYSTEM.MARKERS = require("Utilities/SYSTEM_MARKERS")

local function SetupSettings()
    local default_settings = {
        version = '0.0.1b',
        order = {}
    }
    Settings = gson.LoadJSON(settings_path, default_settings)
    if default_settings.version ~= Settings.version then
        reaper.ShowConsoleMsg("\n!!! WARNING !!! (gaspard_Pattern manipulator.lua)\n")
        reaper.ShowConsoleMsg("Settings are erased due to update in settings file.\nPlease excuse this behaviour.\nThis won't happen once released.\n")
        reaper.ShowConsoleMsg("Now in version: "..default_settings.version.."\n")
        Settings = gson.SaveJSON(settings_path, default_settings)
        Settings = gson.LoadJSON(settings_path, Settings)
    end
end

_SYSTEM.Init = function()
    SetupSettings()
end

_SYSTEM.GetTrackFromExtState = function(extname, extkey)
    local retval, GUID = reaper.GetProjExtState(0, extname, extkey)
    return retval and reaper.BR_GetMediaTrackByGUID(0, GUID) or nil
end

_SYSTEM.SetTrackToExtState = function(track, extname, extkey)
    reaper.SetProjExtState(0, extname, extkey, reaper.GetTrackGUID(track))
end

_SYSTEM.EncodeToBase64 = function(waveform)
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

_SYSTEM.DecodeFromBase64 = function(encoded)
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

return _SYSTEM
