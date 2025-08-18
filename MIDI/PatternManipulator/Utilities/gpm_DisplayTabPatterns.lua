--@noindex
--@description Pattern manipulator utility Display tab patterns
--@author gaspard
--@about Pattern manipulator utility

local tab_patterns = {}

local payload_drop = nil
local payload_text = 'Moving...'
local above_track = false

function tab_patterns.Show()
    -- PATTERN LIST
    if reaper.ImGui_BeginListBox(ctx, '##listbox_patterns', 215, -1) then
        local track = nil
        if payload_drop then
            local x, y = reaper.GetMousePosition()
            track = reaper.GetTrackFromPoint(x, y)
            if track then
                payload_text = 'Release mouse to drop here. '
                above_track = true
            else
                payload_text = 'No track under mouse cursor.'
                above_track = false
            end
        end

        if reaper.ImGui_IsMouseReleased(ctx, reaper.ImGui_MouseButton_Left()) then
            if payload_drop and track then
                reaper.PreventUIRefresh(1)
                reaper.Undo_BeginBlock()

                local sel_tracks = {}
                local sel_track_count = reaper.CountSelectedTracks(0)
                for i = 0, sel_track_count - 1 do
                    table.insert(sel_tracks, reaper.GetSelectedTrack(0, i))
                end
                local edit_cur_pos = reaper.GetCursorPosition()

                _, _, _ = reaper.BR_GetMouseCursorContext()
                local time_pos = reaper.SnapToGrid(0, reaper.BR_GetMouseCursorContext_Position())

                reaper.SetEditCurPos(time_pos, false, false)
                reaper.SetOnlyTrackSelected(track)
                reaper.InsertMedia(payload_drop, 0)
                reaper.SetTrackSelected(track, false)

                for _, sel_track in ipairs(sel_tracks) do
                    reaper.SetTrackSelected(sel_track, true)
                end
                reaper.SetEditCurPos(edit_cur_pos, false, false)

                reaper.Undo_EndBlock('Insert pattern on track.', -1)
                reaper.PreventUIRefresh(-1)
                reaper.UpdateArrange()
            end
        end

        if payload_drop then payload_drop = nil end

        for i, pattern in ipairs(gpmsys_patterns.file_list) do
            changed, pattern.selected = reaper.ImGui_Selectable(ctx, pattern.name..'##sel_pattern'..tostring(i), pattern.selected)
            if reaper.ImGui_IsItemHovered(ctx, reaper.ImGui_HoveredFlags_Stationary()) then
                reaper.ImGui_SetItemTooltip(ctx, pattern.name)
            end
            if changed then
                if gpmsys_patterns.is_playing then gpmsys_patterns.stop_play = true end
                -- Unselect other patterns
                for j, other_pattern in ipairs(gpmsys_patterns.file_list) do
                    if j ~= i and other_pattern.selected then
                        other_pattern.selected = false
                    end
                end
                if pattern.selected then
                    if not gpmsys_patterns.GetMidiInfoFromFile(pattern.path) then
                        reaper.MB('Selected file has invalid path.\nScanning patterns.', 'ERROR', 0)
                        gpmsys_patterns.ScanPatternFiles()
                    end
                else
                    gpmsys_patterns.pianoroll.notes = {}
                    gpmsys_patterns.pianoroll.range = {min = nil, max = nil}
                    gpmsys_patterns.pianoroll.params = {ppq = nil, bpm = nil, bpi = nil, bpl = nil, end_pos = nil}
                end
            end
            if reaper.ImGui_BeginDragDropSource(ctx) then
                payload_drop = pattern.path
                if not above_track then reaper.ImGui_BeginDisabled(ctx) end
                reaper.ImGui_Text(ctx, pattern.name)
                if not above_track then reaper.ImGui_EndDisabled(ctx) end
                if not above_track then reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), 0xAA2222FF) end
                reaper.ImGui_Text(ctx, payload_text)
                if not above_track then reaper.ImGui_PopStyleColor(ctx) end
                reaper.ImGui_EndDragDropSource(ctx)
            end
        end
        reaper.ImGui_EndListBox(ctx)
    end

    -- PIANOROLL
    reaper.ImGui_SameLine(ctx)
    local button_x = reaper.ImGui_GetCursorPosX(ctx)
    local button_y = reaper.ImGui_GetCursorPosY(ctx)
    reaper.ImGui_SetCursorPosY(ctx, reaper.ImGui_GetCursorPosY(ctx) + 27)
    if reaper.ImGui_BeginChild(ctx, 'child_piano_roll', -1, -1, reaper.ImGui_ChildFlags_Borders()) then
        local draw_list = reaper.ImGui_GetWindowDrawList(ctx)

        local flags = reaper.ImGui_WindowFlags_HorizontalScrollbar()
        reaper.ImGui_WindowFlags_AlwaysHorizontalScrollbar()
        if reaper.ImGui_BeginChild(ctx, 'child_piano_roll_display', -1, -1, reaper.ImGui_ChildFlags_Borders(), flags) then
            local start_x, start_y = reaper.ImGui_GetCursorScreenPos(ctx)
            local pianoroll_length, grid_line_height = reaper.ImGui_GetContentRegionAvail(ctx)

            local grid_length = pianoroll_length / 4
            local bar_num = 4
            local end_pos = pianoroll_length
            local PPQ_one_mesure = 0
            if gpmsys_patterns.pianoroll.params.end_pos then
                PPQ_one_mesure = gpmsys_patterns.pianoroll.params.ppq * 4
                end_pos = (gpmsys_patterns.pianoroll.params.end_pos / PPQ_one_mesure) * pianoroll_length
                bar_num = gpmsys_patterns.pianoroll.params.end_pos / pianoroll_length
                bar_num = math.floor(bar_num) * 4
            end
            for i = 0, bar_num do
                local pos_x = start_x + (grid_length * i)
                local grid_size = gpmsys_patterns.pianoroll.params.bpi and gpmsys_patterns.pianoroll.params.bpi or 4
                local color = i % grid_size == 0 and 0x6B60B5FF or 0x6B60B555
                reaper.ImGui_DrawList_AddLine(draw_list, pos_x, start_y, pos_x, start_y + grid_line_height, color, 1) -- Grid line
            end

            if gpmsys_patterns.pianoroll.notes and gpmsys_patterns.pianoroll.range.min then
                for _, note in ipairs(gpmsys_patterns.pianoroll.notes) do
                    local note_start = (note.start / PPQ_one_mesure) * pianoroll_length
                    local note_length = (note.length / PPQ_one_mesure) * pianoroll_length
                    local note_start_x = start_x + note_start
                    local note_start_y = start_y + ((gpmsys_patterns.pianoroll.range.max - note.pitch) * 10)
                    local note_end_x = note_start_x + note_length
                    local note_end_y = note_start_y + 10
                    local note_color = 0x6B60B5FF
                    local border_color = 0xFFFFFFAA
                    reaper.ImGui_DrawList_AddRectFilled(draw_list, note_start_x, note_start_y, note_end_x, note_end_y, note_color) -- Rect fill
                    reaper.ImGui_DrawList_AddRect(draw_list, note_start_x, note_start_y, note_end_x, note_end_y, border_color) -- Rect borders
                end

                reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + end_pos)
                reaper.ImGui_Text(ctx, '')
            end

            -- Timeline bar
            local timeline = gpmsys_patterns.timeline and gpmsys_patterns.timeline or 0
            local pos_x = start_x + ((timeline / PPQ_one_mesure) * pianoroll_length)
            local timeline_color = gpmsys_patterns.is_playing and 0xFF0000FF or 0xFF0000AA
            reaper.ImGui_DrawList_AddLine(draw_list, pos_x, start_y, pos_x, start_y + grid_line_height, timeline_color, 1)

            reaper.ImGui_EndChild(ctx)
        end

        reaper.ImGui_EndChild(ctx)
    end

    -- Transport buttons (play/pause, stop/return start)
    reaper.ImGui_SetCursorPos(ctx, button_x, button_y)
    local button_width = 80

    local disabled = true
    if gpmsys_patterns.pianoroll.params.end_pos and gpmsys_patterns.pianoroll.notes and gpmsys_patterns.pianoroll.range.min then
        disabled = false
    end
    if disabled then reaper.ImGui_BeginDisabled(ctx) end
    local play_x, play_y = reaper.ImGui_GetCursorScreenPos(ctx)

    -- PLAY
    if reaper.ImGui_Button(ctx, "##play_pause_button", button_width) then
        if gpmsys_patterns.is_playing then
            if gpmsys_patterns.paused == 1 then
                gpmsys_patterns.paused = 0
            else
                gpmsys_patterns.paused = 1
            end
        else
            gpmsys_patterns.stop_play = false
            gpmsys_patterns.is_playing = true
            gpmsys_patterns.timeline = 0
            gpmsys_patterns.PlayMidiPattern()
        end
    end

    reaper.ImGui_SameLine(ctx)
    local stop_x, stop_y = reaper.ImGui_GetCursorScreenPos(ctx)

    -- STOP
    if reaper.ImGui_Button(ctx, "##stop_button", button_width) then
        gpmsys_patterns.stop_play = true
    end
    local _, button_height = reaper.ImGui_GetItemRectSize(ctx)

    reaper.ImGui_SameLine(ctx)

    changed, Settings.pattern_looping.value = reaper.ImGui_Checkbox(ctx, "Looping", Settings.pattern_looping.value)
    if changed then gson.SaveJSON(settings_path, Settings) end

    if disabled then reaper.ImGui_EndDisabled(ctx) end

    -- PLAY
    local draw_list = reaper.ImGui_GetForegroundDrawList(ctx)
    play_x = play_x + button_width / 3
    play_y = play_y + 6
    local a = 10
    local b = a * math.sqrt(3) / 2
    local s1 = {x = play_x, y = play_y}
    local s2 = {x = play_x + b, y = play_y + a / 2}
    local s3 = {x = play_x, y = play_y + a}
    local color = disabled and 0xFFFFFFA1 or 0xFFFFFFFF
    reaper.ImGui_DrawList_AddTriangleFilled(draw_list, s1.x, s1.y, s2.x, s2.y, s3.x, s3.y, color)

    -- PAUSE
    local pause_x = play_x + 13
    local pause_y = play_y
    local rounding = 3
    local width = 5
    local height = 10
    reaper.ImGui_DrawList_AddRectFilled(draw_list, pause_x, pause_y, pause_x + width, pause_y + height, color, rounding)
    pause_x = pause_x + 6
    reaper.ImGui_DrawList_AddRectFilled(draw_list, pause_x, pause_y, pause_x + width, pause_y + height, color, rounding)

    -- STOP
    local stop_side = 10
    stop_x = stop_x + button_width / 2 - stop_side / 2
    stop_y = stop_y + button_height / 2 - stop_side / 2
    reaper.ImGui_DrawList_AddRectFilled(draw_list, stop_x, stop_y, stop_x + stop_side, stop_y + stop_side, color, 1)

end

return tab_patterns
