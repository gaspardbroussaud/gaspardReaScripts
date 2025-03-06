--@noindex

local window_samples = {}

-- DEBUG TEST --------------------------------
local track_list = {}
for i = 0, reaper.CountTracks(0) - 1 do
    local track = reaper.GetTrack(0, i)
    table.insert(track_list, track)
end
-- DEBUG TEST --------------------------------

local function TextButton(text, i)
    x, y = reaper.ImGui_GetCursorPos(ctx)
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
    local child_height = (window_height - topbar_height - small_font_size - 30) - font_size - 8
    if reaper.ImGui_BeginChild(ctx, "child_samples", child_width, child_height, reaper.ImGui_ChildFlags_Border(), no_scrollbar_flags) then
        if reaper.ImGui_BeginTable(ctx, "table_samples", 4, reaper.ImGui_TableFlags_Borders() | reaper.ImGui_TableFlags_SizingStretchProp()) then
            local name_len, play_len, mute_len, solo_len = child_width / 3, 8, 10, 8
            reaper.ImGui_TableSetupColumn(ctx, "Name", 0, name_len)
            reaper.ImGui_TableSetupColumn(ctx, "Play", 0, play_len)
            reaper.ImGui_TableSetupColumn(ctx, "Mute", 0, mute_len)
            reaper.ImGui_TableSetupColumn(ctx, "Solo", 0, solo_len)

            for i, track in ipairs(track_list) do
                local retval, name = reaper.GetTrackName(track)
                if not retval then goto continue end

                local mute = reaper.GetMediaTrackInfo_Value(track, "B_MUTE")
                local solo = reaper.GetMediaTrackInfo_Value(track, "I_SOLO")
                local selected = reaper.IsTrackSelected(track)

                reaper.ImGui_TableNextRow(ctx)
                reaper.ImGui_TableNextColumn(ctx)
                local left_x, upper_y = reaper.ImGui_GetCursorScreenPos(ctx)
                changed, selected = reaper.ImGui_Selectable(ctx, name, selected)
                local hovered = reaper.ImGui_IsItemHovered(ctx)
                if changed then
                    if selected then
                        reaper.SetOnlyTrackSelected(track)
                    else
                        reaper.SetTrackSelected(track, false)
                    end
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
                reaper.ImGui_Text(ctx, "")
                reaper.ImGui_DrawList_AddTriangleFilled(draw_list, s1.x, s1.y, s2.x, s2.y, s3.x, s3.y, 0xFFFFFFFF)
                reaper.ImGui_SetNextItemAllowOverlap(ctx)
                reaper.ImGui_SetCursorPos(ctx, x, y)
                local av_x, _ = reaper.ImGui_GetContentRegionAvail(ctx)
                reaper.ImGui_InvisibleButton(ctx, "##play"..i, av_x, font_size)
                if reaper.ImGui_IsItemActivated(ctx) then
                end

                if mute > 0 then reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), 0xFFAAAAFF) end
                reaper.ImGui_TableNextColumn(ctx)
                if TextButton("M", i) then
                    reaper.SetMediaTrackInfo_Value(track, "B_MUTE", math.abs(mute - 1))
                end
                if mute > 0 then reaper.ImGui_PopStyleColor(ctx, 1) end

                reaper.ImGui_TableNextColumn(ctx)
                x, y = reaper.ImGui_GetCursorPos(ctx)
                if solo > 0 then reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), 0xF0E115FF) end
                if TextButton("S", i) then
                    if solo > 0 then solo = 1 end
                    reaper.SetMediaTrackInfo_Value(track, "I_SOLO", math.abs(solo - 1))
                end
                if solo > 0 then reaper.ImGui_PopStyleColor(ctx, 1) end

                local _, lower_y = reaper.ImGui_GetCursorScreenPos(ctx)
                if selected or hovered then
                    local right_x = left_x + child_width - 17
                    local thickness = 1
                    local col_line = 0xFF000055
                    if hovered and not selected then col_line = 0xFFFFFF55 end
                    reaper.ImGui_DrawList_AddRect(draw_list, left_x - 5, upper_y - 2, right_x - 5, lower_y - 2, col_line, thickness)
                end

                ::continue::
            end

            reaper.ImGui_EndTable(ctx)
        end

        reaper.ImGui_EndChild(ctx)
    end
end

return window_samples
