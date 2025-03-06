--@noindex

local gpmsys = {}

-- Global variables
extname_global = "g_PGM"
extkey_parent_track = "PARENT_TRACK_GUID"
gpmsys.parent_track = nil

-- Samples variables
gpmsys_samples = require("Utilities/gpm_Sys_Samples")
gpmsys.sample_list = {}

local function SettingsInit()
    local settings_version = '0.0.4b'
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
        release_amount = {
            value = 40,
            name = 'Release time',
            description = 'Release time in milliseconds.'
        }
    }
    Settings = gson.LoadJSON(settings_path, default_settings)
    if settings_version ~= Settings.version then
        reaper.MB("Settings are erased due to update in file.\nPlease excuse this behaviour.\nThis won't happen once released.", 'WARNING', 0)
        Settings = gson.SaveJSON(settings_path, default_settings)
        Settings = gson.LoadJSON(settings_path, Settings)
    end
end

function gpmsys.Init()
    SettingsInit()
    gpmsys.sample_list = gpmsys_samples.CheckForSampleTracks()
end

function gpmsys.GetTrackFromExtState(extname, extkey)
    local retval, GUID = reaper.GetProjExtState(0, extname, extkey)
    if not retval then return nil end
    local track = reaper.BR_GetMediaTrackByGUID(0, GUID)
    return track
end

return gpmsys
