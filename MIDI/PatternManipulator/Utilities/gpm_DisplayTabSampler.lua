--@noindex
--@description Pattern manipulator utility Display tab sampler
--@author gaspard
--@about Pattern manipulator utility

local tab_sampler = {}

local item_width = 80
local popup_note = "C4"
local popup_width, popup_height = 300, 88

local function GetMIDINoteName(note_number)
    note_number = math.floor(note_number)
    local note_names = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}
    if Settings.note_nomenclature.selected_index == 2 then
        note_names = {"Do", "Do#", "Re", "Re#", "Mi", "Fa", "Fa#", "Sol", "Sol#", "La", "La#", "Si"}
    else
        note_names = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}
    end
    if note_number >= 0 and note_number <= 127 then
        local note_index = (note_number % 12) + 1
        local octave = math.floor(note_number / 12) - 1
        return note_names[note_index] .. octave
    else
        return "Invalid MIDI note"
    end
end

local function GetMIDINoteNumber(note_name)
    -- Define mappings for both C and Do notations (all in lower-case)
    local note_names = {
        ["c"] = 0, ["c#"] = 1, ["d"] = 2, ["d#"] = 3, ["e"] = 4, ["f"] = 5,
        ["f#"] = 6, ["g"] = 7, ["g#"] = 8, ["a"] = 9, ["a#"] = 10, ["b"] = 11,
        ["do"] = 0, ["do#"] = 1, ["re"] = 2, ["re#"] = 3, ["mi"] = 4, ["fa"] = 5,
        ["fa#"] = 6, ["sol"] = 7, ["sol#"] = 8, ["la"] = 9, ["la#"] = 10, ["si"] = 11
    }

    -- If the input is purely numeric, return it as a number
    if note_name:match("^%-?%d+$") then
        return tonumber(note_name)
    end

    -- Match the note and octave from the string (letters possibly with a '#' and an octave number)
    local note, octave = note_name:match("([A-Za-z]+#?)(%-?%d+)")
    if note and octave then
        note = note:lower()  -- Normalize the note to lower-case for lookup
        return (note_names[note] or 0) + (tonumber(octave) + 1) * 12
    else
        return nil  -- Invalid note name
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
    reaper.ImGui_SetCursorPosX(ctx, pos_x_start + (item_width * 2 + global_spacing * 2))

    -- Note pitch (name)
    local _, note_number = reaper.GetSetMediaTrackInfo_String(track, "P_EXT:"..extname_sample_note, "", false)
    note_number = tonumber(note_number)
    if not note_number then note_number = 60 end
    local note = math.floor(note_number)

    reaper.ImGui_PushItemWidth(ctx, item_width)
    local note_display = tostring(GetMIDINoteName(tonumber(note)))
    changed, note_number = reaper.ImGui_DragDouble(ctx, "MIDI note##drag_note", note_number, 0.1, 0, 127, note_display, reaper.ImGui_SliderFlags_NoInput())
    if reaper.ImGui_IsItemHovered(ctx) and reaper.ImGui_IsMouseDoubleClicked(ctx, reaper.ImGui_MouseButton_Left()) then
        reaper.ImGui_OpenPopup(ctx, 'popup_note_name')
        popup_note = note_display
        popup_width = 0
    end

    -- POPUP note
    reaper.ImGui_SetNextWindowPos(ctx, window_x + (window_width - popup_width) * 0.5, window_y + 68)
    reaper.ImGui_SetNextWindowSize(ctx, popup_width, popup_height)
    if popup_width < 300 then popup_width = popup_width + 100 end
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(), 0xFFFFFFAA)
    if reaper.ImGui_BeginPopup(ctx, 'popup_note_name') then
        reaper.ImGui_Text(ctx, 'NOTE (C or Do notation or midi number):')
        _, popup_note = reaper.ImGui_InputText(ctx, '##popup_inputtext', popup_note)
        flags = reaper.ImGui_TableColumnFlags_WidthStretch() | reaper.ImGui_TableFlags_SizingStretchSame()
        if reaper.ImGui_BeginTable(ctx, 'table_popup', 3, flags) then
            reaper.ImGui_TableNextRow(ctx)
            reaper.ImGui_TableNextColumn(ctx)
            reaper.ImGui_TableNextColumn(ctx)
            if reaper.ImGui_Button(ctx, 'CANCEL', -1) then
                reaper.ImGui_CloseCurrentPopup(ctx)
            end
            reaper.ImGui_TableNextColumn(ctx)
            if reaper.ImGui_Button(ctx, 'APPLY', -1) or reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_Enter()) then
                note_number = GetMIDINoteNumber(popup_note)
                changed = true
                reaper.ImGui_CloseCurrentPopup(ctx)
            end
            reaper.ImGui_EndTable(ctx)
        end
        reaper.ImGui_EndPopup(ctx)
    end
    reaper.ImGui_PopStyleColor(ctx)

    if not note_number then note_number = 60 end
    note_number = math.max(0, math.min(note_number, 127))
    if changed then
        note = math.floor(note_number)
        reaper.TrackFX_SetParam(track, fx_index, 3, note / 127) -- Parameter index for "Note start" is 3
        reaper.TrackFX_SetParam(track, fx_index, 4, note / 127) -- Parameter index for "Note end" is 4
        reaper.GetSetMediaTrackInfo_String(track, "P_EXT:"..extname_sample_note, note_number, true)
    end

    -- ADSR
    local _, sample_len = reaper.GetSetMediaTrackInfo_String(track, "P_EXT:"..extname_sample_length, "", false)
    if not sample_len then sample_len = 2000 end

    -- Get ADSR values
    -- Attack
    local attack = reaper.TrackFX_GetParam(track, fx_index, 9)
    attack = attack * 2000

    -- Decay
    local decay = reaper.TrackFX_GetParam(track, fx_index, 24)
    decay = 14990 * decay + 10

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
    changed, attack = reaper.ImGui_DragDouble(ctx, "##drag_attack", attack, 1, 0, attack_len, "%.2f ms")
    if changed then
        retval = reaper.TrackFX_SetParam(track, fx_index, 9, attack / 2000) -- Parameter index for "Attack" is 9
    end

    reaper.ImGui_SameLine(ctx)
    local aDsr_x = reaper.ImGui_GetCursorPosX(ctx)
    reaper.ImGui_PushItemWidth(ctx, item_width)
    changed, decay = reaper.ImGui_DragDouble(ctx, "##drag_decay", decay, 1, 10, 15000, "%.0f ms")
    if changed then
        reaper.TrackFX_SetParam(track, fx_index, 24, (decay - 10) / 14990) -- Parameter index for "Decay" is 24
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
        local sustain_norm = (10^(sustain / 20) - 10^(-120 / 20)) / (10^(6 / 20) - 10^(-120 / 20))
        reaper.TrackFX_SetParamNormalized(track, fx_index, 25, sustain_norm) -- Parameter index for "Sustain" is 25
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



    -- WAVEFORM DISPLAY -----------------------------------------------------------------
    win_x = win_x + item_w + global_spacing
    local wf_width, wf_height = avail_x - item_w - global_spacing, 50
    reaper.ImGui_SetCursorScreenPos(ctx, win_x, win_y)
    if reaper.ImGui_BeginChild(ctx, "child_waveform", wf_width, wf_height) then
        reaper.ImGui_SetCursorScreenPos(ctx, win_x, win_y)
        reaper.ImGui_SetNextItemAllowOverlap(ctx)
        reaper.ImGui_InvisibleButton(ctx, "##button_replace_sample", wf_width, wf_height)
        reaper.ImGui_SetItemTooltip(ctx, "Drop file on top of waveform to change sample.")
        if reaper.ImGui_IsItemHovered(ctx) then
            reaper.ImGui_DrawList_AddRect(reaper.ImGui_GetForegroundDrawList(ctx), win_x - 2, win_y - 2, win_x + wf_width + 2, win_y + wf_height + 2, 0xFFFFFFA1, 2, 0, 1)
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
                local x1 = win_x + (i / num_samples) * wf_width
                local x2 = win_x + ((i + 1) / num_samples) * wf_width

                -- Normalize values
                local norm_y1 = (waveform[i] - min_val) / amplitude_range
                local norm_y2 = (waveform[i + 1] - min_val) / amplitude_range

                local y1 = win_y + wf_height - (norm_y1 * wf_height)
                local y2 = win_y + wf_height - (norm_y2 * wf_height)

                reaper.ImGui_DrawList_AddLine(draw_list, x1, y1, x2, y2, 0xFFFFFFAA)
            end
        end

        -- Draw ADSR on Waveform
        local ADSR_color = 0xFFAAAAFF
        local a_x1, a_y1 = win_x, win_y + wf_height
        local a_x2, a_y2 = win_x + attack / 2000 * wf_width, win_y + 10
        reaper.ImGui_DrawList_AddLine(draw_list, a_x1, a_y1, a_x2, a_y2, ADSR_color, 3) -- Attack

        local r_x1 = win_x + wf_width - release / 2000 * wf_width
        local r_y1 = a_y2 - ((10^(sustain / 20) - 10^(-120 / 20)) / (10^(6 / 20) - 10^(-120 / 20)) - 0.5) * wf_height
        local r_x2, r_y2 = win_x + wf_width, a_y1
        reaper.ImGui_DrawList_AddLine(draw_list, r_x1, r_y1, r_x2, r_y2, ADSR_color, 3) -- Release

        --wf_width = wf_width - (a_x2 - win_x) - (r_x1 - win_x)
        local d_x = a_x2 + ((decay - 10) / 14990 * wf_width) * 10
        local d_y = a_y2 - ((10^(sustain / 20) - 10^(-120 / 20)) / (10^(6 / 20) - 10^(-120 / 20)) - 0.5) * wf_height
        if d_x > r_x1 then d_x = r_x1 end
        reaper.ImGui_DrawList_AddBezierQuadratic(draw_list, a_x2 - 1, a_y2, d_x, d_y, r_x1 + 1, r_y1, ADSR_color, 3)

        --[[local num_points = 100  -- Number of points in the curve
        local base = 10  -- Logarithm base (adjust for different curves)
        local log_max = math.log(num_points) / math.log(base)  -- Normalize log scaling

        win_x, win_y = a_x2, a_y2
        wf_width, wf_height = wf_width - (a_x2 - win_x) - (r_x1 - win_x), wf_height - 10 - (a_y1 - r_y1)

        for i = 1, num_points - 1 do
            -- X moves linearly
            local x1 = win_x + (i / num_points) * wf_width
            local x2 = win_x + ((i + 1) / num_points) * wf_width

            -- Logarithmic decay for Y
            local norm_y1 = (math.log(i) / math.log(base)) / log_max  -- Log-scaled Y
            local norm_y2 = (math.log(i + 1) / math.log(base)) / log_max

            -- Scale Y values to fit within wf_height (flipped for top-left start)
            local y1 = win_y + norm_y1 * wf_height
            local y2 = win_y + norm_y2 * wf_height

            -- Draw the line
            reaper.ImGui_DrawList_AddLine(draw_list, x1, y1, x2, y2, 0xFFFFFFFF)
        end]]

        reaper.ImGui_EndChild(ctx)
    end
end

return tab_sampler
