--@noindex

local tab_sampler = {}

local function GetMIDINoteName(note_number)
    note_number = math.floor(note_number)
    local note_names = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}
    if note_number >= 0 and note_number <= 127 then
        local note_index = (note_number % 12) + 1
        local octave = math.floor(note_number / 12) - 1
        return note_names[note_index] .. octave
    else
        return "Invalid MIDI note"
    end
end

local function GetMIDINoteNumber(note_name)
    local note_names = {["C"] = 0, ["C#"] = 1, ["D"] = 2, ["D#"] = 3, ["E"] = 4, ["F"] = 5, ["F#"] = 6, ["G"] = 7, ["G#"] = 8, ["A"] = 9, ["A#"] = 10, ["B"] = 11}
    local note, octave = note_name:match("([A-G]#?)(%-?%d+)")
    if note and octave then
        return (note_names[note] or 0) + (tonumber(octave) + 1) * 12
    else
        return nil  -- Invalid note name
    end
end

function tab_sampler.Show()
    if not gpmsys.sample_list or gpmsys.selected_sample_index == 0 then
        reaper.ImGui_Text(ctx, "Please select a sampler track or parent track to display sampler parameters.")
        reaper.ImGui_Text(ctx, "To create a new sampler parent track, simply select a track and insert a sample.")
        return
    end
    local track = gpmsys.sample_list[gpmsys.selected_sample_index]

    local _, name = reaper.GetTrackName(track)
    changed, name = reaper.ImGui_InputText(ctx, "##input_name", name, reaper.ImGui_InputTextFlags_EnterReturnsTrue())
    if changed then
        reaper.GetSetMediaTrackInfo_String(track, "P_NAME", name, true)
    end

    reaper.ImGui_SameLine(ctx)

    changed, track_color = reaper.ImGui_ColorEdit3(ctx, "##color_picker", reaper.ImGui_ColorConvertNative(reaper.GetTrackColor(track)), reaper.ImGui_ColorEditFlags_NoInputs())
    if changed then
        reaper.SetMediaTrackInfo_Value(track, "I_CUSTOMCOLOR", reaper.ImGui_ColorConvertNative(track_color))
    end

    reaper.ImGui_PushItemWidth(ctx, 80)
    local _, note = reaper.GetSetMediaTrackInfo_String(track, "P_EXT:"..extname_sample_track_note, "", false)
    note = tonumber(note)
    --changed, note = reaper.ImGui_InputText(ctx, "MIDI note", tostring(note), reaper.ImGui_InputTextFlags_EnterReturnsTrue())
    changed, note = reaper.ImGui_DragDouble(ctx, "MIDI note##drag_note", note, 0.2, 0, 127, tostring(GetMIDINoteName(tonumber(note))))
    note = math.floor(note)
    if changed then
        local _, fx_name = reaper.GetTrackName(track)
        local fx_index = reaper.TrackFX_GetByName(track, fx_name.." (RS5K)", false)
        reaper.TrackFX_SetParam(track, fx_index, 3, note / 127) -- Parameter index for "Note start" is 3
        reaper.TrackFX_SetParam(track, fx_index, 4, note / 127) -- Parameter index for "Note end" is 4
        reaper.GetSetMediaTrackInfo_String(track, "P_EXT:"..extname_sample_track_note, note, true)
    end
end

return tab_sampler
