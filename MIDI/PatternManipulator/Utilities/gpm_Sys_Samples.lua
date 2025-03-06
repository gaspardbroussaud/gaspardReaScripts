--@noindex

local gpmsys_samples = {}

local extname_parent_track_GUID = extname_global..":PARENT_TRACK_GUID"

local function GetParentFromSelectedTrack()
    local sel_track_count = reaper.CountSelectedTracks(0)
    if sel_track_count == 0 then return nil end

    local parent_track = nil
    for i = 0, sel_track_count - 1 do
        local track = reaper.GetSelectedTrack(0, i)
        local retval, parent_GUID = reaper.GetSetMediaTrackInfo_String(track, "P_EXT:"..extname_parent_track_GUID, "", false)
        if retval then
            parent_track = reaper.BR_GetMediaTrackByGUID(0, parent_GUID)
            break
        end
    end
    return parent_track
end

local function GetParentTrack()
    local parent_track = nil
    if Settings.project_based_parent.value then parent_track = gpmsys.GetTrackFromExtState(extname_global, extkey_parent_track) end
    if not parent_track then parent_track = GetParentFromSelectedTrack() end
    return parent_track
end

local function GetSampleTracks(parent_track)
    if not parent_track then return nil end
    local parent_index = reaper.GetMediaTrackInfo_Value(parent_track, "IP_TRACKNUMBER")

    local list = {}
    for i = parent_index, reaper.CountTracks(0) - 1 do
        local track = reaper.GetTrack(0, i)
        local retval, parent_GUID = reaper.GetSetMediaTrackInfo_String(track, "P_EXT:"..extname_parent_track_GUID, "", false)
        if retval then
            local is_midi_inputs, _ = reaper.GetSetMediaTrackInfo_String(track, "P_EXT:IS_MIDI_INPUTS", "", false)
            if not is_midi_inputs and reaper.BR_GetMediaTrackByGUID(0, parent_GUID) == parent_track then
                table.insert(list, track)
            end
        else
            break
        end
    end
    return #list > 0 and list or nil
end

function gpmsys_samples.CheckForSampleTracks()
    --gpmsys.parent_track = GetParentTrack()
    return GetSampleTracks(gpmsys.parent_track)
end

--------------

local function SetSampleTrackParams(name, filepath, track)
    -- Set parent GUID as extstate
    local parent_GUID = reaper.GetTrackGUID(gpmsys.parent_track)
    reaper.GetSetMediaTrackInfo_String(track, "P_EXT:"..extname_parent_track_GUID, parent_GUID, true)

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

    local ms = Settings.release_amount.value / 2000
    reaper.TrackFX_SetParam(track, fx_index, 10, ms) -- Parameter index for "Release" is 10 (value 1 == 2s)

    -- Send midi inputs from midi track to track
    local retval, midi_track_GUID = reaper.GetSetMediaTrackInfo_String(gpmsys.parent_track, "P_EXT:"..extname_global.."MIDI_INPUTS_TRACK", "", false)
    local midi_track = nil
    if retval then
        midi_track = reaper.BR_GetMediaTrackByGUID(0, midi_track_GUID)
        reaper.CreateTrackSend(midi_track, track)
        reaper.SetTrackSendInfo_Value(track, -1, 0, 'I_SRCCHAN', -1)
        reaper.SetTrackSendInfo_Value(track, -1, 0, 'I_MIDIFLAGS', 0)
        reaper.SetTrackSendInfo_Value(track, -1, 0, 'B_MUTE', 1)
    end
end

local function SetParentTrack()
    local track = nil
    if reaper.CountSelectedTracks(0) > 0 then
        track = reaper.GetSelectedTrack(0, 0)
        local parent_GUID = reaper.GetTrackGUID(track)
        if Settings.project_based_parent.value then
            reaper.SetProjExtState(0, extname_global, extkey_parent_track, parent_GUID)
        end
    end
    return track
end

function gpmsys_samples.InsertSampleTrack(name, filepath)
    if not gpmsys.parent_track then
        gpmsys.parent_track = SetParentTrack()
    end

    local parent_index = reaper.GetMediaTrackInfo_Value(gpmsys.parent_track, "IP_TRACKNUMBER")
    local last_sample_index = gpmsys.sample_list and #gpmsys.sample_list or 0
    local insert_index = parent_index + last_sample_index

    reaper.PreventUIRefresh(1)
    reaper.Undo_BeginBlock()

    -- Insert track
    reaper.InsertTrackInProject(0, insert_index, 0)
    local inserted_track = reaper.GetTrack(0, insert_index)

    SetSampleTrackParams(name, filepath, inserted_track)

    reaper.Undo_EndBlock('gaspard_Pattern manipulator_Add track', -1)
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
end

return gpmsys_samples
