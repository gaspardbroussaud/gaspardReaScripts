--@noindex

-- 9 attack 10 release 24 decay 25 sustain 13 sample start offset 14 sample end offset

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
    local _, fx_name = reaper.GetTrackName(track)
    local fx_index = reaper.TrackFX_GetByName(track, fx_name.." (RS5K)", false)

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
    changed, note = reaper.ImGui_DragDouble(ctx, "MIDI note##drag_note", note, 0.2, 0, 127, tostring(GetMIDINoteName(tonumber(note))))
    note = math.floor(note)
    if changed then
        reaper.TrackFX_SetParam(track, fx_index, 3, note / 127) -- Parameter index for "Note start" is 3
        reaper.TrackFX_SetParam(track, fx_index, 4, note / 127) -- Parameter index for "Note end" is 4
        reaper.GetSetMediaTrackInfo_String(track, "P_EXT:"..extname_sample_track_note, note, true)
    end

    if reaper.ImGui_BeginTable(ctx, "table_adsr", 4) then
        local _, sample_len = reaper.GetSetMediaTrackInfo_String(track, "P_EXT:"..extname_sample_track_length, "", false)
        if not sample_len then sample_len = 2000 end

        -- Get ADSR values
        -- Attack
        local _, attack_min, attack_max, attack = reaper.TrackFX_GetParamEx(track, fx_index, 9)
        attack = attack * 2000

        -- Decay
        local _, decay_min, decay_max, decay = reaper.TrackFX_GetParamEx(track, fx_index, 24)
        decay = decay * 15000

        -- Sustain
        local _, sustain_min, sustain_max, sustain = reaper.TrackFX_GetParamEx(track, fx_index, 25)
        --sustain = sustain

        -- Release
        local _, release_min, release_max, release = reaper.TrackFX_GetParamEx(track, fx_index, 10)
        release = release * 2000

        local attack_len = sample_len - release
        local release_len = sample_len - attack

        -- Draw table
        reaper.ImGui_TableNextRow(ctx)
        reaper.ImGui_TableNextColumn(ctx)
        reaper.ImGui_Text(ctx, "A")
        reaper.ImGui_TableNextColumn(ctx)
        reaper.ImGui_Text(ctx, "D")
        reaper.ImGui_TableNextColumn(ctx)
        reaper.ImGui_Text(ctx, "S")
        reaper.ImGui_TableNextColumn(ctx)
        reaper.ImGui_Text(ctx, "R")

        reaper.ImGui_TableNextRow(ctx)
        reaper.ImGui_TableNextColumn(ctx)
        changed, attack = reaper.ImGui_DragDouble(ctx, "##drag_attack", attack, 1, 0, attack_len, "%.1f")
        if changed then
            reaper.TrackFX_SetParam(track, fx_index, 9, attack / 2000) -- Parameter index for "Attack" is 9
        end

        reaper.ImGui_TableNextColumn(ctx)
        changed, decay = reaper.ImGui_DragDouble(ctx, "##drag_decay", decay, 1, 10, 15000, "%.1f")
        if changed then
            reaper.TrackFX_SetParam(track, fx_index, 24, decay / 15000) -- Parameter index for "Decay" is 24
        end

        reaper.ImGui_TableNextColumn(ctx)
        changed, sustain = reaper.ImGui_DragDouble(ctx, "##drag_sustain", sustain, 1, -120, 12, "%.1f")
        if changed then
            reaper.TrackFX_SetParam(track, fx_index, 25, sustain / 132) -- Parameter index for "Sustain" is 25
        end

        reaper.ImGui_TableNextColumn(ctx)
        changed, release = reaper.ImGui_DragDouble(ctx, "##drag_release", release, 1, 0, release_len, "%.1f")
        if changed then
            reaper.TrackFX_SetParam(track, fx_index, 10, release / 2000) -- Parameter index for "Release" is 10
        end

        reaper.ImGui_EndTable(ctx)
    end

    local win_x, win_y = reaper.ImGui_GetCursorScreenPos(ctx)
    local width, height = 300, 100  -- Waveform area size
    local mid_y = win_y + height / 2

    -- Loop through the waveform data and draw lines to represent it
    for i = 1, #gpmsys.sample_waveform - 1 do
        local x1 = win_x + (i / #gpmsys.sample_waveform) * width
        local x2 = win_x + ((i + 1) / #gpmsys.sample_waveform) * width
        local y1 = mid_y - (gpmsys.sample_waveform[i] * height / 2)
        local y2 = mid_y - (gpmsys.sample_waveform[i + 1] * height / 2)

        reaper.ImGui_DrawList_AddLine(draw_list, x1, y1, x2, y2, 0xFFFFFFFF)
    end
end

return tab_sampler
