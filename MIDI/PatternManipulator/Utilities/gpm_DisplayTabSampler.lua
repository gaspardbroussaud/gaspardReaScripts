--@noindex
--@description Pattern manipulator utility Display tab sampler
--@author gaspard
--@about Pattern manipulator utility

-- 9 attack 10 release 24 decay 25 sustain 13 sample start offset 14 sample end offset

local tab_sampler = {}

local item_width = 80
local table_width = (item_width + 8) * 4

local function GetMIDINoteName(note_number)
    note_number = math.floor(note_number)
    local note_names = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}
    --[[if Settings.note_nomenclature.value then
        note_names = {"Do", "Do#", "Re", "Re#", "Mi", "Fa", "Fa#", "Sol", "Sol#", "La", "La#", "Si"}
    else
        note_names = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}
    end]]
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

local function ConvertVstValueToDb(x)
    local k = 0.1
    if x < 1 then
        -- Inverse sigmoid transformation for values in the [0, 1] range (maps to [-inf, 0])
        return 0 + (math.log(x / (1 - x)) / k)  -- x0 = 0 for this range
    elseif x <= 4 then
        -- Reverse linear transformation for values in the [1, 4] range (maps to [0, 12])
        return 12 * (x - 1) / (4 - 1)
    else
        -- Return 12 for values beyond 4
        return 12
    end
end

local function ConvertDbToVstValue(x)
    local k = 0.1
    if x < 0 then
        -- Sigmoid transformation for values in the [-inf, 0] range (maps to [0, 1])
        return 1 / (1 + math.exp(-k * (x - 0)))  -- x0 = 0 for this range
    elseif x <= 12 then
        -- Linear transformation for values in the [0, 12] range (maps to [1, 4])
        return 1 + (x / 12) * (4 - 1)
    else
        -- Return 4 for values beyond 12
        return 4
    end
end

function tab_sampler.Show()
    if not gpmsys.sample_list or gpmsys.selected_sample_index == 0 then
        reaper.ImGui_TextWrapped(ctx, "Please select a sampler track or parent track to display sampler parameters.")
        reaper.ImGui_TextWrapped(ctx, "To create a new sampler parent track, simply select a track and insert a sample.")
        return
    end

    local draw_list = reaper.ImGui_GetWindowDrawList(ctx)

    local track = gpmsys.sample_list[gpmsys.selected_sample_index]
    if not track then
        if gpmsys.sample_list == {} then
            gpmsys.selected_sample_index = 0
            return
        end
        table.remove(gpmsys.sample_list, gpmsys.selected_sample_index)
        gpmsys.selected_sample_index = 1
        return
    end

    local _, fx_name = reaper.GetSetMediaTrackInfo_String(track, "P_EXT:"..extname_sample_name, "", false)
    local fx_index = reaper.TrackFX_GetByName(track, fx_name.." (RS5K)", false)

    local _, name = reaper.GetTrackName(track)
    changed, name = reaper.ImGui_InputText(ctx, "##input_name", name, reaper.ImGui_InputTextFlags_EnterReturnsTrue())
    if changed then
        reaper.GetSetMediaTrackInfo_String(track, "P_NAME", name, true)
    end

    local note_pos_y = reaper.ImGui_GetCursorPosY(ctx) + 2

    reaper.ImGui_SameLine(ctx)
    local win_x, win_y = reaper.ImGui_GetCursorScreenPos(ctx)
    local avail_x = reaper.ImGui_GetContentRegionAvail(ctx)

    changed, track_color = reaper.ImGui_ColorEdit3(ctx, "##color_picker", reaper.ImGui_ColorConvertNative(reaper.GetTrackColor(track)), reaper.ImGui_ColorEditFlags_NoInputs())
    if changed then
        reaper.SetMediaTrackInfo_Value(track, "I_CUSTOMCOLOR", reaper.ImGui_ColorConvertNative(track_color))
    end
    local item_w = reaper.ImGui_GetItemRectSize(ctx)

    -- WAVEFORM DISPLAY -----------------------------------------------------------------
    win_x = win_x + item_w + global_spacing
    local width, height = avail_x - item_w - global_spacing, 50

    reaper.ImGui_SetCursorScreenPos(ctx, win_x, win_y)
    reaper.ImGui_SetNextItemAllowOverlap(ctx)
    reaper.ImGui_InvisibleButton(ctx, "##button_replace_sample", width, height)
    reaper.ImGui_SetItemTooltip(ctx, "Drop file on top of waveform to change sample.")
    if reaper.ImGui_IsItemHovered(ctx) then
        reaper.ImGui_DrawList_AddRect(reaper.ImGui_GetForegroundDrawList(ctx), win_x - 2, win_y - 2, win_x + width + 2, win_y + height + 2, 0xFFFFFFA1, 2, 0, 1)
    end
    if reaper.ImGui_BeginDragDropTarget(ctx) then
        local retval, count = reaper.ImGui_AcceptDragDropPayloadFiles(ctx)
        if retval and count > 0 then
            local _, filepath = reaper.ImGui_GetDragDropPayloadFile(ctx, 0)
            local filename = filepath:match('([^\\/]+)$')
            local name_without_extension = filename:match("(.+)%..+") or filename
            if reaper.file_exists(filepath) then
                gpmsys_samples.ReplaceSampleOnTrack(track, name_without_extension, filepath)
            end
        end
    end

    if window_width >= 0 then
        local _, encoded = reaper.GetSetMediaTrackInfo_String(track, "P_EXT:"..extname_sample_peaks, "", false)
        local waveform = gpmsys.DecodeFromBase64(encoded)

        local min_val, max_val = math.huge, -math.huge
        local num_samples = #waveform
        for i = 1, num_samples do
            if waveform[i] < min_val then min_val = waveform[i] end
            if waveform[i] > max_val then max_val = waveform[i] end
        end

        local amplitude_range = max_val - min_val
        if amplitude_range == 0 then amplitude_range = 1 end

        for i = 1, num_samples - 1 do
            local x1 = win_x + (i / num_samples) * width
            local x2 = win_x + ((i + 1) / num_samples) * width

            -- Normalize values
            local norm_y1 = (waveform[i] - min_val) / amplitude_range
            local norm_y2 = (waveform[i + 1] - min_val) / amplitude_range

            local y1 = win_y + height - (norm_y1 * height)
            local y2 = win_y + height - (norm_y2 * height)

            reaper.ImGui_DrawList_AddLine(draw_list, x1, y1, x2, y2, 0xFFFFFFFF)
        end
    end
    -------------------------------------------------------------------------------------

    reaper.ImGui_SetCursorPosY(ctx, note_pos_y)
    local pos_x_start = reaper.ImGui_GetCursorPosX(ctx)

    -- Vst gain
    local _, gain = reaper.TrackFX_GetFormattedParamValue(track, fx_index, 0)
    gain = tonumber(gain)
    if not gain then gain = -120 end

    reaper.ImGui_PushItemWidth(ctx, item_width)
    local display_gain = gain <= -119.99 and "-inf dB" or "%.1f dB"
    if gain >= 0 then display_gain = "+"..display_gain end

    local gain_speed = gain > -25 and 0.1 or 0.25
    if gain < -115 then gain_speed = 1
    elseif gain < -65 then gain_speed = 0.5 end

    changed, gain = reaper.ImGui_DragDouble(ctx, "Gain##drag_gain", gain, gain_speed, -120, 12, display_gain)
    if changed then
        gain = (10^(gain / 20) - 10^(-120 / 20)) / (10^(6 / 20) - 10^(-120 / 20))
        reaper.TrackFX_SetParamNormalized(track, fx_index, 0, gain)
    end

    reaper.ImGui_SameLine(ctx)
    --reaper.ShowConsoleMsg(tostring(reaper.ImGui_GetItemRectSize(ctx)).."\n")
    --reaper.ImGui_Dummy(ctx, item_width - reaper.ImGui_CalcTextSize(ctx, "Gain"), 1)
    --reaper.ImGui_SameLine(ctx)
    reaper.ImGui_SetCursorPosX(ctx, pos_x_start + (item_width * 2 + global_spacing * 2))--reaper.ImGui_GetItemRectSize(ctx))

    -- Note pitch (name)
    local _, note_number = reaper.GetSetMediaTrackInfo_String(track, "P_EXT:"..extname_sample_note, "", false)
    note_number = tonumber(note_number)
    if not note_number then note_number = 60 end
    local note = math.floor(note_number)

    reaper.ImGui_PushItemWidth(ctx, 80)
    changed, note_number = reaper.ImGui_DragDouble(ctx, "MIDI note##drag_note", note_number, 0.1, 0, 127, tostring(GetMIDINoteName(tonumber(note))))
    note_number = math.max(0, math.min(note_number, 127))

    if changed then
        note = math.floor(note_number)
        reaper.TrackFX_SetParam(track, fx_index, 3, note / 127) -- Parameter index for "Note start" is 3
        reaper.TrackFX_SetParam(track, fx_index, 4, note / 127) -- Parameter index for "Note end" is 4
        reaper.GetSetMediaTrackInfo_String(track, "P_EXT:"..extname_sample_note, note_number, true)
    end

    -- TEST -------------------------------------
    local _, sample_len = reaper.GetSetMediaTrackInfo_String(track, "P_EXT:"..extname_sample_length, "", false)
    if not sample_len then sample_len = 2000 end

    -- Get ADSR values
    -- Attack
    local attack = reaper.TrackFX_GetParam(track, fx_index, 9)
    attack = attack * 2000

    -- Decay
    local decay = reaper.TrackFX_GetParam(track, fx_index, 24)
    decay = decay * 15000

    -- Sustain
    local _, sustain = reaper.TrackFX_GetFormattedParamValue(track, fx_index, 25)
    sustain = tonumber(sustain)
    if not sustain then sustain = -119.99 end

    -- Release
    local release = reaper.TrackFX_GetParam(track, fx_index, 10)
    release = release * 2000

    local attack_len = sample_len - release
    local release_len = sample_len - attack

    -- Draw table
    local Adsr_x = reaper.ImGui_GetCursorPosX(ctx)
    reaper.ImGui_SetCursorPosY(ctx, reaper.ImGui_GetCursorPosY(ctx) + 2)
    reaper.ImGui_PushItemWidth(ctx, item_width)
    changed, attack = reaper.ImGui_DragDouble(ctx, "##drag_attack", attack, 1, 0, attack_len, "%.0f ms")
    if changed then
        retval = reaper.TrackFX_SetParam(track, fx_index, 9, attack / 2000) -- Parameter index for "Attack" is 9
    end

    reaper.ImGui_SameLine(ctx)
    local aDsr_x = reaper.ImGui_GetCursorPosX(ctx)
    reaper.ImGui_PushItemWidth(ctx, item_width)
    changed, decay = reaper.ImGui_DragDouble(ctx, "##drag_decay", decay, 1, 10, 15000, "%.0f ms")
    if changed then
        reaper.TrackFX_SetParam(track, fx_index, 24, decay / 15000) -- Parameter index for "Decay" is 24
    end

    reaper.ImGui_SameLine(ctx)
    local adSr_x = reaper.ImGui_GetCursorPosX(ctx)
    reaper.ImGui_PushItemWidth(ctx, item_width)
    local display_sustain = sustain <= -119.99 and "-inf dB" or "%.1f dB"
    if sustain >= 0 then display_sustain = "+"..display_sustain end
    local sustain_speed = sustain > -25 and 0.1 or 0.25
    if sustain < -115 then sustain_speed = 1
    elseif sustain < -65 then sustain_speed = 0.5 end
    changed, sustain = reaper.ImGui_DragDouble(ctx, "##drag_sustain", sustain, sustain_speed, -119.99, 12, display_sustain)
    if changed then
        sustain = (10^(sustain / 20) - 10^(-120 / 20)) / (10^(6 / 20) - 10^(-120 / 20))
        reaper.TrackFX_SetParamNormalized(track, fx_index, 25, sustain) --ConvertDbToVstValue(sustain)) -- Parameter index for "Sustain" is 25
    end

    reaper.ImGui_SameLine(ctx)
    local adsR_x = reaper.ImGui_GetCursorPosX(ctx)
    reaper.ImGui_PushItemWidth(ctx, item_width)
    changed, release = reaper.ImGui_DragDouble(ctx, "##drag_release", release, -1, 0, release_len, "%.0f ms")
    if changed then
        reaper.TrackFX_SetParam(track, fx_index, 10, release / 2000) -- Parameter index for "Release" is 10
    end

    reaper.ImGui_SetCursorPosX(ctx, Adsr_x)
    local text_w = reaper.ImGui_CalcTextSize(ctx, "A")
    reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + (item_width - text_w) * 0.5)
    reaper.ImGui_Text(ctx, "A")

    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_SetCursorPosX(ctx, aDsr_x)
    text_w = reaper.ImGui_CalcTextSize(ctx, "D")
    reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + (item_width - text_w) * 0.5)
    reaper.ImGui_Text(ctx, "D")

    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_SetCursorPosX(ctx, adSr_x)
    text_w = reaper.ImGui_CalcTextSize(ctx, "S")
    reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + (item_width - text_w) * 0.5)
    reaper.ImGui_Text(ctx, "S")

    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_SetCursorPosX(ctx, adsR_x)
    text_w = reaper.ImGui_CalcTextSize(ctx, "R")
    reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + (item_width - text_w) * 0.5)
    reaper.ImGui_Text(ctx, "R")
    -- TEST -------------------------------------

    --[[ ADSR
    if reaper.ImGui_BeginTable(ctx, "table_adsr", 4, reaper.ImGui_TableFlags_None(), table_width) then
        local _, sample_len = reaper.GetSetMediaTrackInfo_String(track, "P_EXT:"..extname_sample_length, "", false)
        if not sample_len then sample_len = 2000 end

        -- Get ADSR values
        -- Attack
        local attack = reaper.TrackFX_GetParam(track, fx_index, 9)
        attack = attack * 2000

        -- Decay
        local decay = reaper.TrackFX_GetParam(track, fx_index, 24)
        decay = decay * 15000

        -- Sustain
        local _, sustain = reaper.TrackFX_GetFormattedParamValue(track, fx_index, 25)
        sustain = tonumber(sustain)
        if not sustain then sustain = -119.99 end

        -- Release
        local release = reaper.TrackFX_GetParam(track, fx_index, 10)
        release = release * 2000

        local attack_len = sample_len - release
        local release_len = sample_len - attack

        -- Draw table
        reaper.ImGui_TableNextRow(ctx)
        reaper.ImGui_TableNextColumn(ctx)
        reaper.ImGui_PushItemWidth(ctx, item_width)
        changed, attack = reaper.ImGui_DragDouble(ctx, "##drag_attack", attack, 1, 0, attack_len, "%.0f ms")
        if changed then
            retval = reaper.TrackFX_SetParam(track, fx_index, 9, attack / 2000) -- Parameter index for "Attack" is 9
        end

        reaper.ImGui_TableNextColumn(ctx)
        reaper.ImGui_PushItemWidth(ctx, item_width)
        changed, decay = reaper.ImGui_DragDouble(ctx, "##drag_decay", decay, 1, 10, 15000, "%.0f ms")
        if changed then
            reaper.TrackFX_SetParam(track, fx_index, 24, decay / 15000) -- Parameter index for "Decay" is 24
        end

        reaper.ImGui_TableNextColumn(ctx)
        reaper.ImGui_PushItemWidth(ctx, item_width)
        local display_sustain = sustain <= -119.99 and "-inf dB" or "%.1f dB"
        if sustain >= 0 then display_sustain = "+"..display_sustain end
        local sustain_speed = sustain > -25 and 0.1 or 0.25
        if sustain < -115 then sustain_speed = 1
        elseif sustain < -65 then sustain_speed = 0.5 end
        changed, sustain = reaper.ImGui_DragDouble(ctx, "##drag_sustain", sustain, sustain_speed, -119.99, 12, display_sustain)
        if changed then
            sustain = (10^(sustain / 20) - 10^(-120 / 20)) / (10^(6 / 20) - 10^(-120 / 20))
            reaper.TrackFX_SetParamNormalized(track, fx_index, 25, sustain) --ConvertDbToVstValue(sustain)) -- Parameter index for "Sustain" is 25
        end

        reaper.ImGui_TableNextColumn(ctx)
        reaper.ImGui_PushItemWidth(ctx, item_width)
        changed, release = reaper.ImGui_DragDouble(ctx, "##drag_release", release, -1, 0, release_len, "%.0f ms")
        if changed then
            reaper.TrackFX_SetParam(track, fx_index, 10, release / 2000) -- Parameter index for "Release" is 10
        end

        reaper.ImGui_TableNextRow(ctx)
        reaper.ImGui_TableNextColumn(ctx)
        local text_w = reaper.ImGui_CalcTextSize(ctx, "A")
        reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + (item_width - text_w) * 0.5)
        reaper.ImGui_Text(ctx, "A")

        reaper.ImGui_TableNextColumn(ctx)
        text_w = reaper.ImGui_CalcTextSize(ctx, "D")
        reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + (item_width - text_w) * 0.5)
        reaper.ImGui_Text(ctx, "D")

        reaper.ImGui_TableNextColumn(ctx)
        text_w = reaper.ImGui_CalcTextSize(ctx, "S")
        reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + (item_width - text_w) * 0.5)
        reaper.ImGui_Text(ctx, "S")

        reaper.ImGui_TableNextColumn(ctx)
        text_w = reaper.ImGui_CalcTextSize(ctx, "R")
        reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + (item_width - text_w) * 0.5)
        reaper.ImGui_Text(ctx, "R")

        reaper.ImGui_EndTable(ctx)
    end]]

end

return tab_sampler
