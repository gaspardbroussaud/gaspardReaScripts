--@noindex
--@description Pattern generator user interface gui drop zone
--@author gaspard
--@about User interface drop zone used in gaspard_Pattern generator.lua script

local pattern_window = {}

local payload_drop = nil

function pattern_window.Show()
    reaper.ImGui_Text(ctx, "PATTERNS")
    if reaper.ImGui_Button(ctx, "SAVE##pattern_save", 100) then
        local retval, pattern_name = reaper.GetUserInputs("SAVE PATTERN", 1, "Pattern name:", "")
        if retval then
            reaper.CF_SetClipboard(patterns_path..System.separator..pattern_name..".mid")
            local text_part_1 = "The midi patterns path has been set to clipboard. Paste pattern in next window to save.\nPattern name: "
            local text_part_2 = "\nSettings to select are displayed in main Pattern Generator window."
            retval = reaper.MB(text_part_1..pattern_name..text_part_2, "WARNING", 1)
            if retval == 1 then
                reaper.Main_OnCommand(40849, 0) -- Export MIDI
                System.ScanPatternFiles()
            end
        end
    end

    if reaper.ImGui_BeginListBox(ctx, "##listbox_patterns", -1, -1) then
        if reaper.ImGui_IsMouseReleased(ctx, reaper.ImGui_MouseButton_Left()) then
            if payload_drop then
                reaper.PreventUIRefresh(1)
                reaper.Undo_BeginBlock()
                local sel_tracks = {}
                local sel_track_count = reaper.CountSelectedTracks(0)
                for i = 0, sel_track_count - 1 do
                    table.insert(sel_tracks, reaper.GetSelectedTrack(0, i))
                end
                local edit_cur_pos = reaper.GetCursorPosition()

                local x, y = reaper.GetMousePosition()
                _, _, _ = reaper.BR_GetMouseCursorContext()
                local time_pos = reaper.SnapToGrid(0, reaper.BR_GetMouseCursorContext_Position())

                reaper.SetEditCurPos(time_pos, false, false)
                local track = reaper.GetTrackFromPoint(x, y)
                reaper.SetOnlyTrackSelected(track)
                reaper.InsertMedia(payload_drop, 0)
                reaper.SetTrackSelected(track, false)

                for _, sel_track in ipairs(sel_tracks) do
                    reaper.SetTrackSelected(sel_track, true)
                end
                reaper.SetEditCurPos(edit_cur_pos, false, false)

                reaper.Undo_EndBlock("Insert pattern on track.", -1)
                reaper.PreventUIRefresh(-1)
                reaper.UpdateArrange()
            end
        end

        if payload_drop then payload_drop = nil end

        for i, pattern in ipairs(System.patterns) do
            reaper.ImGui_Selectable(ctx, pattern.name.."##sel_pattern"..tostring(i), false)
            if reaper.ImGui_BeginDragDropSource(ctx) then
                payload_drop = pattern.path
                reaper.ImGui_Text(ctx, "Moving...")
                reaper.ImGui_EndDragDropSource(ctx)
            end
        end
        reaper.ImGui_EndListBox(ctx)
    end
end

return pattern_window
