--@noindex
--@description Pattern generator user interface gui piano roll
--@author gaspard
--@about User interface piano roll used in gaspard_Pattern generator.lua script

local piano_roll = {}

-- Variables
local notes = {}
local range = {}
local once = false

-- Functions
-- Pitch to 0-100 range
function PitchToRange(pitch)
    --range.min
    --range.max
    return pitch
end

-- Piano roll display
function piano_roll.Show()
    local draw_list = reaper.ImGui_GetWindowDrawList(ctx)

    if not once then
        notes, range = System.GetMidiInfoFromFile(patterns_path..'/default_pattern.mid')
        once = true
    end

    reaper.ImGui_Text(ctx, 'PIANO ROLL')
    local start_x, start_y = reaper.ImGui_GetCursorScreenPos(ctx)

    if notes and range then
        for i, note in ipairs(notes) do
            local note_start = note.start / 15
            local note_length = note.length / 15
            local note_height = PitchToRange(note.pitch)
            reaper.ImGui_DrawList_AddRectFilled(draw_list, start_x + note_start, start_y, start_x + note_start + note_length, start_y + 10, 0xFF0000FF)
        end
    end
end

return piano_roll
