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
    --[[local BPM = System.pianoroll_param.bpm and 'Tempo: '..tostring(System.pianoroll_param.bpm):gsub('%.0$', '') or ''
    local BPL_BPI = ''
    if System.pianoroll_param.bpl and System.pianoroll_param.bpi then
        BPL_BPI = 'Time Sig: '..System.pianoroll_param.bpl..'/'..math.floor(System.pianoroll_param.bpi)
    end
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_Text(ctx, tostring(BPM))
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_Text(ctx, tostring(BPL_BPI))]]
    local child_width, child_height = reaper.ImGui_GetContentRegionAvail(ctx)

    if reaper.ImGui_BeginChild(ctx, 'child_piano_roll_display', child_width, child_height, reaper.ImGui_ChildFlags_Border()) then
        local start_x, start_y = reaper.ImGui_GetCursorScreenPos(ctx)
        local pianoroll_length, grid_line_height = reaper.ImGui_GetContentRegionAvail(ctx)

        local grid_length = pianoroll_length / 4
        for i = 0, 4 do
            local pos_x = start_x + (grid_length * i)
            reaper.ImGui_DrawList_AddLine(draw_list, pos_x, start_y, pos_x, start_y + grid_line_height, 0x6B60B555, 1) -- Grid line
        end

        if System.pianoroll_notes and System.pianoroll_range.min then
            local PPQ_one_mesure = System.pianoroll_param.ppq * 4
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
        end
        reaper.ImGui_EndChild(ctx)
    end
end

return piano_roll
