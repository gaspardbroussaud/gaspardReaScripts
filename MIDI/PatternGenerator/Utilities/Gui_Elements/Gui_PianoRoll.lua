--@noindex
--@description Pattern generator user interface gui piano roll
--@author gaspard
--@about User interface piano roll used in gaspard_Pattern generator.lua script

local piano_roll = {}

-- Variables
local notes = {}
local once = false

-- Functions
function piano_roll.Show()
    local draw_list = reaper.ImGui_GetWindowDrawList(ctx)

    if not once then
        notes = System.GetMidiInfoFromFile(patterns_path..'/default_pattern.mid')
        once = true
    end

    local start_x, start_y = reaper.ImGui_GetCursorScreenPos(ctx)

    reaper.ClearConsole()
    for i, note in ipairs(notes) do
        reaper.ShowConsoleMsg(note.start)
        reaper.ShowConsoleMsg('\n')
        reaper.ImGui_DrawList_AddRectFilled(draw_list, start_x, start_y, start_x + 25, start_y + 25, 0xFF0000FF)
    end
end

return piano_roll
