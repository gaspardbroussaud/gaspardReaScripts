--@noindex
--@description Pattern generator user interface gui piano roll
--@author gaspard
--@about User interface piano roll used in gaspard_Pattern generator.lua script

local piano_roll = {}

-- Functions
-- Pitch to 0-100 range
function PitchToRange(pitch)
    local old_range = System.pianoroll_range.max - System.pianoroll_range.min
    if old_range == 0 then
        pitch = 0
    else
        local new_range = 100
        pitch = ((pitch - System.pianoroll_range.min) * new_range) / old_range
    end
    return pitch
end

-- Piano roll display
function piano_roll.Show()
    local draw_list = reaper.ImGui_GetWindowDrawList(ctx)

    reaper.ImGui_Text(ctx, 'PIANO ROLL')
    local child_width, child_height = reaper.ImGui_GetContentRegionAvail(ctx)
    if reaper.ImGui_BeginChild(ctx, 'child_piano_roll_display', child_width + 100, child_height, reaper.ImGui_ChildFlags_Border()) then
        local start_x, start_y = reaper.ImGui_GetCursorScreenPos(ctx)

        if System.pianoroll_notes and System.pianoroll_range then
            for i, note in ipairs(System.pianoroll_notes) do
                local note_start = note.start / 25
                local note_length = note.length / 25
                local note_height = PitchToRange(note.pitch)
                local note_start_x = start_x + note_start
                local note_start_y = start_y + note_height
                local note_end_x = note_start_x + note_length
                local note_end_y = note_start_y + 10
                reaper.ImGui_DrawList_AddRectFilled(draw_list, note_start_x, note_start_y, note_end_x, note_end_y, 0xFF0000FF)
            end
        end
        reaper.ImGui_EndChild(ctx)
    end
end

return piano_roll
