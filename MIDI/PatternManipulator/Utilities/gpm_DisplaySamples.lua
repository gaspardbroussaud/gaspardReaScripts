--@noindex
--@description Pattern manipulator utility isplay samples
--@author gaspard
--@about Pattern manipulator utility

local window_samples = {}

local play_selected = -1

local function TextButton(text, i)
    x, y = reaper.ImGui_GetCursorPos(ctx)
    local center = text == "M" and 3 or 3.5
    reaper.ImGui_SetCursorPosX(ctx, x + center)
    reaper.ImGui_Text(ctx, text)
    reaper.ImGui_SetNextItemAllowOverlap(ctx)
    reaper.ImGui_SetCursorPos(ctx, x, y)
    av_x, _ = reaper.ImGui_GetContentRegionAvail(ctx)
    reaper.ImGui_InvisibleButton(ctx, "##"..text..i, av_x, font_size)
    if reaper.ImGui_IsItemActivated(ctx) then return true end
    return false
end

function window_samples.Show()

    local draw_list = reaper.ImGui_GetWindowDrawList(ctx)

    local child_width = (og_window_width - 20) / 4.15 -- = a default width of 200 with og_window_width at 850
    local child_height = (window_height - topbar_height - small_font_size - 30)

    local drop_x, drop_y = reaper.ImGui_GetCursorScreenPos(ctx)

    if reaper.ImGui_BeginChild(ctx, "child_samples", child_width, child_height, reaper.ImGui_ChildFlags_None(), no_scrollbar_flags) then
        local parent_name = ""
        if gpmsys.parent_track then _, parent_name = reaper.GetTrackName(gpmsys.parent_track) end
        local name_is_too_long = reaper.ImGui_CalcTextSize(ctx, parent_name) > reaper.ImGui_GetContentRegionAvail(ctx)
        local parent_name_display = name_is_too_long and string.sub(parent_name, 1, 29).."..." or parent_name
        reaper.ImGui_Text(ctx, parent_name_display) -- Rack name display
        if name_is_too_long then reaper.ImGui_SetItemTooltip(ctx, parent_name) end
        reaper.ImGui_Separator(ctx)

        local forground_draw_list = reaper.ImGui_GetForegroundDrawList(ctx)
        local pos = {x1 = drop_x - 5, y1 = drop_y - 5, x2 = drop_x + child_width + 5, y2 = drop_y + child_height + 5}
        reaper.ImGui_DrawList_AddRect(forground_draw_list, pos.x1, pos.y1, pos.x2, pos.y2, 0xFFFFFF55, 2, reaper.ImGui_DrawFlags_None(), 2)
        if not gpmsys.sample_list then
            local text_insert = "Drop sample file here."
            local selected_tracks = reaper.CountSelectedTracks(0) > 0
            if not selected_tracks then text_insert = "Please select one track." end
            reaper.ImGui_PushFont(ctx, italic_font, small_font_size)
            reaper.ImGui_TextWrapped(ctx, text_insert)
            reaper.ImGui_PopFont(ctx)
            if not selected_tracks then
                reaper.ImGui_EndChild(ctx)
                goto no_selected_track
            end
            goto drop_zone
        end

        if reaper.ImGui_BeginTable(ctx, "table_samples", 4, reaper.ImGui_TableFlags_Borders() | reaper.ImGui_TableFlags_SizingStretchProp()) then
            local name_len, play_len, mute_len, solo_len = child_width / 3, 8, 10, 8
            reaper.ImGui_TableSetupColumn(ctx, "Name", 0, name_len)
            reaper.ImGui_TableSetupColumn(ctx, "Play", 0, play_len)
            reaper.ImGui_TableSetupColumn(ctx, "Mute", 0, mute_len)
            reaper.ImGui_TableSetupColumn(ctx, "Solo", 0, solo_len)

            for i, track in ipairs(gpmsys.sample_list) do
                local retval, name = reaper.GetTrackName(track)
                if not retval then goto continue end

                local mute = reaper.GetMediaTrackInfo_Value(track, "B_MUTE")
                local solo = reaper.GetMediaTrackInfo_Value(track, "I_SOLO")
                local selected = gpmsys.selected_sample_index == i

                reaper.ImGui_TableNextRow(ctx)
                reaper.ImGui_TableNextColumn(ctx)
                local left_x, upper_y = reaper.ImGui_GetCursorScreenPos(ctx)
                local changed, _ = reaper.ImGui_Selectable(ctx, name, selected)
                local hovered = reaper.ImGui_IsItemHovered(ctx)
                if changed then
                    reaper.SetOnlyTrackSelected(track)
                    gpmsys.selected_sample_index = i
                    reaper.GetSetMediaTrackInfo_String(gpmsys.parent_track, "P_EXT:"..extname_track_selected_index, i, true)
                end
                if reaper.ImGui_BeginDragDropSource(ctx) then
                    reaper.ImGui_SetDragDropPayload(ctx, 'SAMPLE_INDEX', tostring(i))
                    reaper.ImGui_Text(ctx, "Dragging...")
                    reaper.ImGui_EndDragDropSource(ctx)
                end
                if reaper.ImGui_BeginDragDropTarget(ctx) then
                    local payload, dragged_index = reaper.ImGui_AcceptDragDropPayload(ctx, 'SAMPLE_INDEX')
                    if payload then
                        local sel_tracks = {}
                        if Settings.selection_link.value then
                            local count_sel_tracks = reaper.CountSelectedTracks(0)
                            if count_sel_tracks > 0 then
                                for j = 0, count_sel_tracks - 1 do
                                    sel_tracks[j] = reaper.GetSelectedTrack(0, j)
                                end
                            end
                        end

                        reaper.PreventUIRefresh(1)
                        reaper.Undo_BeginBlock()

                        dragged_index = tonumber(dragged_index)
                        local track_moved = gpmsys.sample_list[dragged_index]

                        reaper.SetOnlyTrackSelected(track)
                        reaper.ReorderSelectedTracks(dragged_index, 0)

                        reaper.SetOnlyTrackSelected(track_moved)
                        reaper.ReorderSelectedTracks(i, 0)

                        gpmsys.selected_sample_index = i

                        --gpmsys.sample_list = gpmsys_samples.CheckForSampleTracks()
                        --gpmsys_samples.SetNotesInMidiTrackPianoRoll()

                        if Settings.selection_link.value and count_sel_tracks > 0 then
                            for j = 0, count_sel_tracks - 1 do
                                reaper.SetTrackSelected(sel_tracks[j], true)
                            end
                        end

                        reaper.Undo_EndBlock('gaspard_Pattern manipulator_Change sample tracks order', -1)
                        reaper.PreventUIRefresh(-1)
                        reaper.UpdateArrange()
                    end
                    reaper.ImGui_EndDragDropTarget(ctx)
                end

                reaper.ImGui_TableNextColumn(ctx)
                local x, y = reaper.ImGui_GetCursorPos(ctx)
                local play_x, play_y = reaper.ImGui_GetCursorScreenPos(ctx)
                play_x = play_x + play_len / 3
                play_y = play_y + 3
                local a = 10
                local b = a * math.sqrt(3) / 2
                local s1 = {x = play_x, y = play_y}
                local s2 = {x = play_x + b, y = play_y + a / 2}
                local s3 = {x = play_x, y = play_y + a}
                local play_color = play_selected == i and 0xFFFFFFAA or 0xFFFFFFFF
                reaper.ImGui_Text(ctx, "")
                reaper.ImGui_SetNextItemAllowOverlap(ctx)
                reaper.ImGui_SetCursorPos(ctx, x, y)
                local av_x, _ = reaper.ImGui_GetContentRegionAvail(ctx)
                reaper.ImGui_InvisibleButton(ctx, "##play"..i, av_x, font_size)
                if reaper.ImGui_IsItemActivated(ctx) then
                    local retnote, note = reaper.GetSetMediaTrackInfo_String(track, "P_EXT:"..extname_sample_note, "", false)
                    if retnote then
                        note = math.floor(note)
                        play_selected = i
                        note = tonumber(note)
                        reaper.StuffMIDIMessage(0, 0x90, note, 100) -- Note On (MIDI note, Vel 100)
                    end
                end
                if reaper.ImGui_IsItemDeactivated(ctx) then
                    --local index = reaper.GetMediaTrackInfo_Value(gpmsys.parent_track, "IP_TRACKNUMBER") - 1
                    local retnote, note = reaper.GetSetMediaTrackInfo_String(track, "P_EXT:"..extname_sample_note, "", false)
                    if retnote then
                        note = math.floor(note)
                        play_selected = -1
                        note = tonumber(note)
                        reaper.StuffMIDIMessage(0, 0x80, note, 0) -- Note Off (MIDI note, Vel 0)
                    end
                end
                reaper.ImGui_DrawList_AddTriangleFilled(draw_list, s1.x, s1.y, s2.x, s2.y, s3.x, s3.y, play_color)

                if mute > 0 then reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), 0xFF0000FF) end
                reaper.ImGui_TableNextColumn(ctx)
                if TextButton("M", i) then
                    reaper.SetMediaTrackInfo_Value(track, "B_MUTE", math.abs(mute - 1))
                end
                if mute > 0 then reaper.ImGui_PopStyleColor(ctx, 1) end

                reaper.ImGui_TableNextColumn(ctx)
                x, y = reaper.ImGui_GetCursorPos(ctx)
                if solo > 0 then reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), 0x00FF00FF) end
                if TextButton("S", i) then
                    if solo > 0 then solo = 1 end
                    reaper.SetMediaTrackInfo_Value(track, "I_SOLO", math.abs(solo - 1))
                end
                if solo > 0 then reaper.ImGui_PopStyleColor(ctx, 1) end

                local _, lower_y = reaper.ImGui_GetCursorScreenPos(ctx)
                if selected or hovered then
                    local right_x = left_x + child_width
                    local thickness = 1
                    local col_line = 0x7C71C2FF
                    if hovered and not selected then col_line = 0xFFFFFF55 end
                    reaper.ImGui_DrawList_AddRect(draw_list, left_x - 5, upper_y - 2, right_x - 5, lower_y - 2, col_line, thickness)
                end

                ::continue::
            end

            reaper.ImGui_EndTable(ctx)
        end

        ::drop_zone::
        reaper.ImGui_EndChild(ctx)
    end

    if reaper.ImGui_BeginDragDropTarget(ctx) then
        local retval, data_count = reaper.ImGui_AcceptDragDropPayloadFiles(ctx)
        if retval then
            local max_data = data_count - 1
            for i = 0, max_data do
                local _, filepath = reaper.ImGui_GetDragDropPayloadFile(ctx, max_data - i)
                local filename = filepath:match('([^\\/]+)$')
                local name_without_extension = filename:match("(.+)%..+") or filename
                if reaper.file_exists(filepath) then
                    gpmsys_samples.InsertSampleTrack(name_without_extension, filepath)
                end
            end
        end
        reaper.ImGui_EndDragDropTarget(ctx)
    end

    ::no_selected_track::
end

return window_samples
