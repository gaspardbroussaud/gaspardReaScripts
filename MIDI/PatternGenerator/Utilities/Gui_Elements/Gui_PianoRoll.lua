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
    if reaper.ImGui_BeginChild(ctx, 'child_piano_roll_display', child_width, child_height, reaper.ImGui_ChildFlags_Border()) then
        local start_x, start_y = reaper.ImGui_GetCursorScreenPos(ctx)
        local bpm, bpi = reaper.GetProjectTimeSignature()
        local _, grid_line_height = reaper.ImGui_GetContentRegionAvail(ctx)
        reaper.ImGui_DrawList_AddLine(draw_list, start_x, start_y - 20, start_x, 600, 0xFF0000DD, 1) -- Grid line

        if System.pianoroll_notes and System.pianoroll_range then
            for _, note in ipairs(System.pianoroll_notes) do
                local note_start = note.start / 15
                local note_length = note.length / 15
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
        end
        reaper.ImGui_EndChild(ctx)
    end
end

return piano_roll
