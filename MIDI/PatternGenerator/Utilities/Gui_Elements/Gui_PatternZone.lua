--@noindex
--@description Pattern generator user interface gui drop zone
--@author gaspard
--@about User interface drop zone used in gaspard_Pattern generator.lua script

local pattern_window = {}

local item_path = "C:/Users/Gaspard/Documents/Local_ReaScripts/test_patterns/Media/RS5K Patterns/test_midi.MID"
local payload_on = false
local payload_drop = nil

function pattern_window.Show()
    reaper.ImGui_Text(ctx, "PATTERNS")
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

                --[[retval, measures, cml, fullbeats, cdenom = reaper.TimeMap2_timeToBeats(0, time_pos)
                reaper.ShowConsoleMsg(tostring(measures)..":"..tostring(cml)..":"..tostring(fullbeats)..":"..tostring(cdenom).."\n")]]

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
                --reaper.ImGui_SetDragDropPayload(ctx, "DND_MEDIA_ITEM", pattern.path)
                reaper.ImGui_Text(ctx, "Moving...")
                reaper.ImGui_EndDragDropSource(ctx)
            end
        end

        --[[reaper.ImGui_Text(ctx, "Destination")
        if reaper.ImGui_BeginDragDropTarget(ctx) then
            local retval, payload = reaper.ImGui_AcceptDragDropPayload(ctx, "DND_MEDIA_ITEM")
            if retval then
                local path = payload
                reaper.ShowConsoleMsg(path.."\n")
                reaper.InsertMedia(path, 0)
                reaper.UpdateArrange()
            end
            reaper.ImGui_EndDragDropTarget(ctx)
        end]]

        reaper.ImGui_EndListBox(ctx)
    end
end

return pattern_window
