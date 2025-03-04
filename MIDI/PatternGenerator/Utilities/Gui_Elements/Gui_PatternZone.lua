--@noindex
--@description Pattern generator user interface gui pattern zone
--@author gaspard
--@about User interface pattern zone used in gaspard_Pattern generator.lua script

local pattern_window = {}

local payload_drop = nil
local payload_text = 'Moving...'
local above_track = false

function pattern_window.Show()
    reaper.ImGui_Text(ctx, 'PATTERNS')
    if reaper.ImGui_Button(ctx, 'SAVE##pattern_save', 100) then
        System.show_midi_export_settings = true
    end

    if reaper.ImGui_BeginListBox(ctx, '##listbox_patterns', -1, -1) then
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

        for i, pattern in ipairs(System.patterns) do
            changed, pattern.selected = reaper.ImGui_Selectable(ctx, pattern.name..'##sel_pattern'..tostring(i), pattern.selected)
            if reaper.ImGui_IsItemHovered(ctx, reaper.ImGui_HoveredFlags_Stationary()) then
                reaper.ImGui_SetItemTooltip(ctx, pattern.name)
            end
            if changed then
                -- Unselect other patterns
                for j, other_pattern in ipairs(System.patterns) do
                    if j ~= i and other_pattern.selected then
                        other_pattern.selected = false
                    end
                end
                if pattern.selected then
                    System.GetMidiInfoFromFile(pattern.path)
                else
                    System.pianoroll_notes = {}
                    System.pianoroll_range = {min = nil, max = nil}
                    System.pianoroll_param = {ppq = nil, bpm = nil, bpi = nil, bpl = nil, end_pos = nil}
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
end

return pattern_window
