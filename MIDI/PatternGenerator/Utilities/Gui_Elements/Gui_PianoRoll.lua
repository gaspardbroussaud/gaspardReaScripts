--@noindex
--@description Pattern generator user interface gui piano roll
--@author gaspard
--@about User interface piano roll used in gaspard_Pattern generator.lua script

local piano_roll = {}

-- Functions
-- Piano roll display
function piano_roll.Show()
    local draw_list = reaper.ImGui_GetWindowDrawList(ctx)

    reaper.ImGui_Text(ctx, 'PIANO ROLL')
    local child_width, child_height = reaper.ImGui_GetContentRegionAvail(ctx)

    local flags = reaper.ImGui_WindowFlags_HorizontalScrollbar()
    reaper.ImGui_WindowFlags_AlwaysHorizontalScrollbar()
    if reaper.ImGui_BeginChild(ctx, 'child_piano_roll_display', child_width, child_height, reaper.ImGui_ChildFlags_Borders(), flags) then
        local start_x, start_y = reaper.ImGui_GetCursorScreenPos(ctx)
        local pianoroll_length, grid_line_height = reaper.ImGui_GetContentRegionAvail(ctx)

        local grid_length = pianoroll_length / 4
        local bar_num = 4
        local end_pos = pianoroll_length
        local PPQ_one_mesure = 0
        if System.pianoroll_param.end_pos then
            PPQ_one_mesure = System.pianoroll_param.ppq * 4
            end_pos = (System.pianoroll_param.end_pos / PPQ_one_mesure) * pianoroll_length
            bar_num = System.pianoroll_param.end_pos / pianoroll_length
            bar_num = math.floor(bar_num) * 4
        end
        for i = 0, bar_num do
            local pos_x = start_x + (grid_length * i)
            reaper.ImGui_DrawList_AddLine(draw_list, pos_x, start_y, pos_x, start_y + grid_line_height, 0x6B60B555, 1) -- Grid line
        end

        if System.pianoroll_notes and System.pianoroll_range.min then
            for _, note in ipairs(System.pianoroll_notes) do
                local note_start = (note.start / PPQ_one_mesure) * pianoroll_length
                local note_length = (note.length / PPQ_one_mesure) * pianoroll_length
                local note_start_x = start_x + note_start
                local note_start_y = start_y + ((System.pianoroll_range.max - note.pitch) * 10)
                local note_end_x = note_start_x + note_length
                local note_end_y = note_start_y + 10
                local note_color = 0x6B60B5FF
                local border_color = 0xFFFFFFAA
                reaper.ImGui_DrawList_AddRectFilled(draw_list, note_start_x, note_start_y, note_end_x, note_end_y, note_color) -- Rect fill
                reaper.ImGui_DrawList_AddLine(draw_list, note_start_x, note_start_y, note_end_x, note_start_y, border_color, 1) -- Top line
                reaper.ImGui_DrawList_AddLine(draw_list, note_start_x, note_end_y, note_end_x + 1, note_end_y, border_color, 1) -- Bottom line
                reaper.ImGui_DrawList_AddLine(draw_list, note_start_x, note_start_y, note_start_x, note_end_y, border_color, 1) -- Left line
                reaper.ImGui_DrawList_AddLine(draw_list, note_end_x, note_start_y, note_end_x, note_end_y, border_color, 1) -- Right line
            end

            reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + end_pos)
            reaper.ImGui_Text(ctx, '')
        end

        reaper.ImGui_EndChild(ctx)
    end
end

return piano_roll
