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
        --table.remove(gpmsys.sample_list, gpmsys.selected_sample_index)
        gpmsys.selected_sample_index = 1
        return
    end

    local _, fx_name = reaper.GetSetMediaTrackInfo_String(track, "P_EXT:"..extname_sample_name, "", false)
    local fx_index = reaper.TrackFX_GetByName(track, fx_name.." (RS5K)", false)

    -- Track name
    local _, name = reaper.GetTrackName(track)
    changed, name = reaper.ImGui_InputText(ctx, "##input_name", name, reaper.ImGui_InputTextFlags_EnterReturnsTrue())
    if reaper.ImGui_IsItemActive(ctx) then shortcut_activated = false end
    if changed then
        reaper.GetSetMediaTrackInfo_String(track, "P_NAME", name, true)
    end

    local note_pos_y = reaper.ImGui_GetCursorPosY(ctx) + 2

    reaper.ImGui_SameLine(ctx)
    local win_x, win_y = reaper.ImGui_GetCursorScreenPos(ctx)
    local avail_x = reaper.ImGui_GetContentRegionAvail(ctx)

    -- Track color
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
    if reaper.ImGui_IsItemActive(ctx) then shortcut_activated = false end
    if changed then
        gain = (10^(gain / 20) - 10^(-120 / 20)) / (10^(6 / 20) - 10^(-120 / 20))
        reaper.TrackFX_SetParamNormalized(track, fx_index, 0, gain)
    end

    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_SetCursorPosX(ctx, pos_x_start + (item_width * 2 + global_spacing * 2))

    -- Midi note pitch (name display)
    local _, note_number = reaper.GetSetMediaTrackInfo_String(track, "P_EXT:"..extname_sample_note, "", false)
    note_number = tonumber(note_number)
    if not note_number then note_number = 60 end
    local note = math.floor(note_number)

    reaper.ImGui_PushItemWidth(ctx, item_width)
    local note_display = tostring(GetMIDINoteName(tonumber(note)))
    changed, note_number = reaper.ImGui_DragDouble(ctx, "MIDI note##drag_note", note_number, 0.1, 0, 127, note_display, reaper.ImGui_SliderFlags_NoInput())
    if reaper.ImGui_IsItemActive(ctx) then shortcut_activated = false end

    if reaper.ImGui_IsItemActivated(ctx) then previous_note = note end
    local is_note_edited = reaper.ImGui_IsItemDeactivatedAfterEdit(ctx)

    if reaper.ImGui_IsItemHovered(ctx) and reaper.ImGui_IsMouseDoubleClicked(ctx, reaper.ImGui_MouseButton_Left()) then
        reaper.ImGui_OpenPopup(ctx, 'popup_note_name')
        popup_note = note_display
        popup_width = 0
        previous_note = note
    end

    -- POPUP note
    reaper.ImGui_SetNextWindowPos(ctx, window_x + (window_width - popup_width) * 0.5, window_y + 68)
    reaper.ImGui_SetNextWindowSize(ctx, popup_width, popup_height)
    if popup_width < 300 then popup_width = popup_width + 100 end
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(), 0xFFFFFFAA)
    if reaper.ImGui_BeginPopup(ctx, 'popup_note_name') then
        reaper.ImGui_Text(ctx, 'NOTE (C or Do notation or midi number):')
        _, popup_note = reaper.ImGui_InputText(ctx, '##popup_inputtext', popup_note)
        if reaper.ImGui_IsItemActive(ctx) then shortcut_activated = false end
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
                is_note_edited = true
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

    if is_note_edited then gpmsys_samples.SetNotesInMidiTrackPianoRoll() end

    -- ADSR
    local _, sample_len = reaper.GetSetMediaTrackInfo_String(track, "P_EXT:"..extname_sample_length, "", false)
    if not sample_len then sample_len = 2000 end
    local _, display_sample_len = reaper.GetSetMediaTrackInfo_String(track, "P_EXT:"..extname_display_sample_length, "", false)
    if not display_sample_len then display_sample_len = 2000 end

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
    changed, attack = reaper.ImGui_DragDouble(ctx, "##drag_attack", attack, 1, 0, attack_len, "%.2fms")
    if reaper.ImGui_IsItemActive(ctx) then shortcut_activated = false end
    if changed then
        retval = reaper.TrackFX_SetParam(track, fx_index, 9, attack / 2000) -- Parameter index for "Attack" is 9
    end

    reaper.ImGui_SameLine(ctx)
    local aDsr_x = reaper.ImGui_GetCursorPosX(ctx)
    reaper.ImGui_PushItemWidth(ctx, item_width)
    changed, decay = reaper.ImGui_DragDouble(ctx, "##drag_decay", decay, 1, 10, 15000, "%.0fms")
    if reaper.ImGui_IsItemActive(ctx) then shortcut_activated = false end
    if changed then
        reaper.TrackFX_SetParam(track, fx_index, 24, (decay - 10) / 14990) -- Parameter index for "Decay" is 24
    end

    reaper.ImGui_SameLine(ctx)
    local adSr_x = reaper.ImGui_GetCursorPosX(ctx)
    reaper.ImGui_PushItemWidth(ctx, item_width)
    local display_sustain = sustain <= -119.99 and "-infdB" or "%.1fdB"
    if sustain >= 0 then display_sustain = "+"..display_sustain end
    local sustain_speed = sustain > -25 and 0.1 or 0.25
    if sustain < -115 then sustain_speed = 1
    elseif sustain < -65 then sustain_speed = 0.5 end
    changed, sustain = reaper.ImGui_DragDouble(ctx, "##drag_sustain", sustain, sustain_speed, -119.99, 12, display_sustain)
    if reaper.ImGui_IsItemActive(ctx) then shortcut_activated = false end
    if changed then
        local sustain_norm = (10^(sustain / 20) - 10^(-120 / 20)) / (10^(6 / 20) - 10^(-120 / 20))
        reaper.TrackFX_SetParamNormalized(track, fx_index, 25, sustain_norm) -- Parameter index for "Sustain" is 25
    end

    reaper.ImGui_SameLine(ctx)
    local adsR_x = reaper.ImGui_GetCursorPosX(ctx)
    reaper.ImGui_PushItemWidth(ctx, item_width)
    changed, release = reaper.ImGui_DragDouble(ctx, "##drag_release", release, -1, 0, release_len, "%.0fms")
    if reaper.ImGui_IsItemActive(ctx) then shortcut_activated = false end
    if changed then
        reaper.TrackFX_SetParam(track, fx_index, 10, release / 2000) -- Parameter index for "Release" is 10
    end

    reaper.ImGui_SameLine(ctx)
    _, Settings.show_adsr.value = reaper.ImGui_Checkbox(ctx, "Show##checkbox_adsr", Settings.show_adsr.value)

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

    -- Offset values

    --[[Start and end offsets
    local start_offset = reaper.TrackFX_GetParam(track, fx_index, 13) -- Parameter index for "Start offset" is 13
    local end_offset = reaper.TrackFX_GetParam(track, fx_index, 14) -- Parameter index for "End offset" is 14
    -- In milliseconds
    local ms_start_offset = start_offset * sample_len
    local ms_end_offset = end_offset * sample_len
    -- In seconds
    local s_start_offset = ms_start_offset / 1000
    local s_end_offset = ms_end_offset / 1000
    -- Minimum or maximum values
    local max_start_offset = (sample_len - attack - release - ms_start_offset) / 1000
    local min_end_offset = (ms_start_offset + attack + release) / 1000
    reaper.ClearConsole()
    reaper.ShowConsoleMsg(ms_start_offset.." / "..attack.." = "..min_end_offset)

    -- Start offset dragdouble
    local display_start_offset = string.format("%.2f", s_start_offset)
    changed, s_start_offset = reaper.ImGui_DragDouble(ctx, "Start offset", s_start_offset, 0.001, 0, max_start_offset, display_start_offset.."s")
    if changed then
        start_offset = s_start_offset * 1000 / sample_len
        reaper.TrackFX_SetParam(track, fx_index, 13, start_offset) -- Parameter index for "Start offset" is 13
    end

    -- End offset dragdouble
    local display_end_offset = string.format("%.2f", s_end_offset)
    changed, s_end_offset = reaper.ImGui_DragDouble(ctx, "End offset", s_end_offset, 0.001, min_end_offset, sample_len / 1000, display_end_offset.."s")
    if changed then
        end_offset = s_end_offset * 1000 / sample_len
        reaper.TrackFX_SetParam(track, fx_index, 14, end_offset) -- Parameter index for "End offset" is 14
    end]]


    local start_offset = reaper.TrackFX_GetParam(track, fx_index, 13)
    start_offset = start_offset * sample_len / 1000
    local display_start_offset = string.format("%.2f", start_offset)
    changed, start_offset = reaper.ImGui_DragDouble(ctx, "Start offset##drag_start_offset", start_offset, 0.001, 0, sample_len / 1000, display_start_offset.."s")
    if reaper.ImGui_IsItemActive(ctx) then shortcut_activated = false end

    --reaper.ClearConsole()
    --reaper.ShowConsoleMsg(attack.." / "..tostring(start_offset * 1000).."\n")

    start_offset = start_offset * 1000 / sample_len
    if changed then
        reaper.TrackFX_SetParam(track, fx_index, 13, start_offset) -- Parameter index for "Start offset" is 13
    end

    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_SetCursorPosX(ctx, pos_x_start + (item_width * 2 + global_spacing * 2))

    -- End offset
    local end_offset = reaper.TrackFX_GetParam(track, fx_index, 14)
    end_offset = end_offset * sample_len / 1000
    local display_end_offset = string.format("%.2f", tostring(end_offset * 1000 - start_offset * sample_len) / 1000)
    local min_end_offset = 0
    changed, end_offset = reaper.ImGui_DragDouble(ctx, "Length##drag_end_offset", end_offset, 0.001, min_end_offset, sample_len / 1000, display_end_offset.."s")
    if reaper.ImGui_IsItemActive(ctx) then shortcut_activated = false end
    end_offset = end_offset * 1000 / sample_len
    if changed then
        reaper.TrackFX_SetParam(track, fx_index, 14, end_offset) -- Parameter index for "End offset" is 14
    end

    --display_sample_len = sample_len - end_offset * 1000 - start_offset * sample_len
    display_sample_len = sample_len - start_offset * 1000 + (end_offset - 1) * 1000
    reaper.GetSetMediaTrackInfo_String(track, "P_EXT:"..extname_display_sample_length, display_sample_len, true)
    --reaper.ImGui_Text(ctx, display_sample_len)


    -- WAVEFORM DISPLAY -----------------------------------------------------------------
    win_x = win_x + item_w + global_spacing
    local wf_width, wf_height = avail_x - item_w - global_spacing, 50
    reaper.ImGui_SetCursorScreenPos(ctx, win_x, win_y)
    local test = true
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
                    gpmsys.app_init = true
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

        local offset_hide_color = (reaper.ImGui_GetColor(ctx, reaper.ImGui_Col_ChildBg()) & 0xFFFFFF00) | 0xDF
        local offset_line_color = 0xFFFFFFAA

        -- Draw start offset on waveform
        if test and start_offset > 0 then
            reaper.ImGui_DrawList_AddRectFilled(draw_list, win_x, win_y, win_x + start_offset * wf_width, win_y + wf_height, offset_hide_color, 0)

            win_x = win_x + start_offset * wf_width
            reaper.ImGui_DrawList_AddLine(draw_list, win_x, win_y, win_x, win_y + wf_height, offset_line_color, 2)
        end

        local ADSR_start_offset = start_offset * wf_width
        local ADSR_end_offset = math.abs(end_offset - start_offset - 1) * wf_width
        local ADSR_width = wf_width - ADSR_start_offset - ADSR_end_offset
        local ADSR_color = 0x7C71C2FF
        local ADSR_color_bg = 0x14141BFF
        local ADSR_thick = 3
        local ADSR_thick_bg = 5

        -- Draw Adsr on waveform
        local a_x1 = win_x
        local a_y1 = win_y + wf_height
        local a_x2 = a_x1 + (attack / sample_len * wf_width)
        local a_y2 = win_y + 10

        -- Draw adsR on waveform
        local r_x2 = win_x + wf_width - ADSR_end_offset
        local r_y2 = win_y + wf_height
        local r_x1 = r_x2 - (release / sample_len * wf_width)
        local r_y1 = math.min(a_y2 + (sustain * -1.1), win_y + wf_height - 5)

        -- Draw aDSr on waveform
        local ADSR_decay = ((decay - 10) / 14990 * ADSR_width)
        local d_x2 = a_x2 + ADSR_decay * 5
        local d_y2 = r_y1 - 5
        local d_x3 = a_x2 + ADSR_decay * 10
        if d_x3 > r_x1 then d_x3 = r_x1 end
        local d_y3 = r_y1 - ADSR_decay / 10

        if test and Settings.show_adsr.value then
            reaper.ImGui_DrawList_AddLine(draw_list, a_x1, a_y1, a_x2, a_y2, ADSR_color_bg, ADSR_thick_bg) -- Attack bg
            reaper.ImGui_DrawList_AddLine(draw_list, r_x1, r_y1, r_x2, r_y2, ADSR_color_bg, ADSR_thick_bg) -- Release bg
            reaper.ImGui_DrawList_AddBezierCubic(draw_list, a_x2, a_y2, d_x2, d_y2, d_x3, d_y3, r_x1 + 1, r_y1, ADSR_color_bg, ADSR_thick_bg) -- Decay/Sustain bg

            reaper.ImGui_DrawList_AddLine(draw_list, a_x1, a_y1, a_x2, a_y2, ADSR_color, ADSR_thick) -- Attack
            reaper.ImGui_DrawList_AddLine(draw_list, r_x1, r_y1, r_x2, r_y2, ADSR_color, ADSR_thick) -- Release
            reaper.ImGui_DrawList_AddBezierCubic(draw_list, a_x2, a_y2, d_x2, d_y2, d_x3, d_y3, r_x1 + 1, r_y1, ADSR_color, ADSR_thick) -- Decay/Sustain
        end

        -- Draw end offset on waveform
        if test and end_offset < 0.999 then
            reaper.ImGui_DrawList_AddRectFilled(draw_list, r_x2, win_y, win_x + wf_width, r_y2, offset_hide_color, 0)
            reaper.ImGui_DrawList_AddLine(draw_list, r_x2, win_y, r_x2, r_y2, offset_line_color, 2)
        end

        reaper.ImGui_EndChild(ctx)
    end
end

return tab_sampler
