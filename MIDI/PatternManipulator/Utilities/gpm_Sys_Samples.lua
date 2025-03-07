--@noindex

local gpmsys_samples = {}

local extname_parent_track_GUID = extname_global.."PARENT_TRACK_GUID"
local extname_midi_track_GUID = extname_global.."MIDI_INPUTS_GUID"
local extname_is_midi_track = extname_global.."IS_MIDI_TRACK"
extname_track_selected_index = extname_global.."TRACK_SELECTED_INDEX"
extname_sample_track_note = extname_global.."SAMPLE_NOTE"

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
            local is_midi_inputs, _ = reaper.GetSetMediaTrackInfo_String(track, "P_EXT:"..extname_is_midi_track, "", false)
            if is_midi_inputs then
                gpmsys.midi_track = track
                break
            end
            if reaper.BR_GetMediaTrackByGUID(0, parent_GUID) == parent_track then
                table.insert(list, track)
            end
        end
    end
    return #list > 0 and list or nil
end

function gpmsys_samples.CheckForSampleTracks()
    gpmsys.parent_track = GetParentTrack()
    if gpmsys.parent_track then
        local retval, midi_track_GUID = reaper.GetSetMediaTrackInfo_String(gpmsys.parent_track, "P_EXT:"..extname_midi_track_GUID, "", false)
        if retval then gpmsys.midi_track = reaper.BR_GetMediaTrackByGUID(0, midi_track_GUID)
        else gpmsys.midi_track = nil end
        if gpmsys.midi_track then
            local _, parent_name = reaper.GetTrackName(gpmsys.parent_track)
            reaper.GetSetMediaTrackInfo_String(gpmsys.midi_track, 'P_NAME', 'pgm_MIDI_Inputs_'..parent_name, true)
        end

        local _, index = reaper.GetSetMediaTrackInfo_String(gpmsys.parent_track, "P_EXT:"..extname_track_selected_index, "", false)
        gpmsys.selected_sample_index = tonumber(index)
    end
    return GetSampleTracks(gpmsys.parent_track)
end

--------------

local function SetParentTrack()
    local track = nil
    if reaper.CountSelectedTracks(0) > 0 then
        track = reaper.GetSelectedTrack(0, 0)
        local parent_GUID = reaper.GetTrackGUID(track)
        if Settings.project_based_parent.value then
            reaper.SetProjExtState(0, extname_global, extkey_parent_track, parent_GUID)
        end
        reaper.SetMediaTrackInfo_Value(track, "I_FOLDERDEPTH", 1)
        reaper.GetSetMediaTrackInfo_String(track, "P_EXT:"..extname_parent_track_GUID, parent_GUID, true)
        reaper.GetSetMediaTrackInfo_String(track, "P_EXT:"..extname_track_selected_index, 1, true)
    end
    return track
end

local function InsertMIDITrack(parent_index)
    local retval, _ = reaper.GetSetMediaTrackInfo_String(gpmsys.parent_track, "P_EXT:"..extname_midi_track_GUID, "", false)
    if not retval then
        reaper.InsertTrackInProject(0, parent_index, 0)
        local midi_track = reaper.GetTrack(0, parent_index)
        local _, parent_name = reaper.GetTrackName(gpmsys.parent_track)
        reaper.GetSetMediaTrackInfo_String(midi_track, 'P_NAME', 'pgm_MIDI_Inputs_'..parent_name, true)
        reaper.SetMediaTrackInfo_Value(midi_track, 'I_RECARM', 1)
        reaper.SetMediaTrackInfo_Value(midi_track, 'I_RECMON', 1)
        reaper.SetMediaTrackInfo_Value(midi_track, 'I_RECMODE', 0)
        reaper.SetMediaTrackInfo_Value(midi_track, 'I_FOLDERDEPTH', -1)
        reaper.GetSetMediaTrackInfo_String(midi_track, "P_EXT:"..extname_is_midi_track, "true", true)
        reaper.GetSetMediaTrackInfo_String(midi_track, "P_EXT:"..extname_parent_track_GUID, reaper.GetTrackGUID(gpmsys.parent_track), true)
        reaper.GetSetMediaTrackInfo_String(gpmsys.parent_track, "P_EXT:"..extname_midi_track_GUID, reaper.GetTrackGUID(midi_track), true)
        gpmsys.midi_track = midi_track
    end
end

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

    reaper.TrackFX_SetParam(track, fx_index, 3, 60/127) -- Parameter index for "Note start" is 3 (value note (default = C4 = 60 == 0.47))
    reaper.TrackFX_SetParam(track, fx_index, 4, 60/127) -- Parameter index for "Note end" is 4 (value note (default = C4))
    reaper.GetSetMediaTrackInfo_String(track, "P_EXT:"..extname_sample_track_note, 60, true)

    reaper.TrackFX_SetParam(track, fx_index, 5, 0) -- Parameter index for "Pitch@start" is 5 (value 0 == pitch at note (default = C4))

    -- Send midi inputs from midi track to track
    reaper.CreateTrackSend(gpmsys.midi_track, track)
    reaper.SetTrackSendInfo_Value(track, -1, 0, 'I_SRCCHAN', -1)
    reaper.SetTrackSendInfo_Value(track, -1, 0, 'I_MIDIFLAGS', 0)
end

function gpmsys_samples.InsertSampleTrack(name, filepath)
    if not gpmsys.parent_track then
        gpmsys.parent_track = SetParentTrack()
        if not gpmsys.parent_track then return end
    end

    local parent_index = reaper.GetMediaTrackInfo_Value(gpmsys.parent_track, "IP_TRACKNUMBER")
    local last_sample_index = gpmsys.sample_list and #gpmsys.sample_list or 0
    local insert_index = parent_index + last_sample_index

    reaper.PreventUIRefresh(1)
    reaper.Undo_BeginBlock()

    if last_sample_index == 0 then InsertMIDITrack(parent_index) end

    -- Insert track
    reaper.InsertTrackInProject(0, insert_index, 0)
    local inserted_track = reaper.GetTrack(0, insert_index)

    SetSampleTrackParams(name, filepath, inserted_track)

    reaper.SetOnlyTrackSelected(inserted_track)

    reaper.GetSetMediaTrackInfo_String(gpmsys.parent_track, "P_EXT:"..extname_track_selected_index, last_sample_index + 1, true)

    GetSampleTracks(gpmsys.parent_track)

    reaper.Undo_EndBlock('gaspard_Pattern manipulator_Add track', -1)
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
end

return gpmsys_samples
