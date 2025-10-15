--@noindex
--@description Layer manipulator SYSTEM
--@author gaspard

local SYS = {}

SYS.is_macOS = not reaper.GetOS():match('Win')
SYS.separator = SYS.is_macOS and '/' or '\\'
SYS.shortcut = nil

SYS.extname = "g_LM_"
SYS.extkey_parent_track = "PARENT_TRACK_GUID"
SYS.parent_track = nil

SYS.TRACKS = require("Utilities/SYSTEM_TRACKS")
SYS.MARKERS = require("Utilities/SYSTEM_MARKERS")

local function SetupSettings()
    local settings_version = "0.0.0"
    local default_settings = {
        version = settings_version,
        order = {}
    }
    Settings = gson.LoadJSON(settings_path, default_settings)
    if not Settings.version or settings_version ~= Settings.version then
        local keys = {}
        Settings = gson.CompleteUpdate(settings_path, Settings, default_settings, keys)
    end
end

SYS.Init = function()
    SetupSettings()
end

SYS.GetTrackFromExtState = function(extname, extkey)
    local retval, GUID = reaper.GetProjExtState(0, extname, extkey)
    return retval and reaper.BR_GetMediaTrackByGUID(0, GUID) or nil
end

SYS.SetTrackToExtState = function(track, extname, extkey)
    reaper.SetProjExtState(0, extname, extkey, reaper.GetTrackGUID(track))
end

SYS.EncodeToBase64 = function(waveform)
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

SYS.DecodeFromBase64 = function(encoded)
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

return SYS
