--@description Random play point and time selection size
--@author gaspard
--@version 0.0.7
--@changelog
--  - Update gui style fetch
--  - Minor gui updates
--  - Bug fix
--@about
--  ### How to:
--  - Set a time selection in your project, start and end position will be used.
--  - Start script, it will play project and:
--      - Set a random playhead position between start and end position selected by user.
--      - Set a random time selection of length selected by user.
--      - Repeat process as long as in play mode.

-- TOGGLE BUTTON STATE IN REAPER
function SetButtonState(set)
    local _, _, sec, cmd, _, _, _ = reaper.get_action_context()
    reaper.SetToggleCommandState(sec, cmd, set or 0)
    reaper.RefreshToolbar2(sec, cmd)
end

-- GET GUI STYLES
function GetGuiStylesFromFile()
    gui_style_settings_path = reaper.GetResourcePath().."/Scripts/Gaspard ReaScripts/GUI/GUI_Style_Settings.lua"
    local style = dofile(gui_style_settings_path)
    style_vars = style.vars
    style_colors = style.colors
end

-- All initial variable for script and GUI
function InitialVariables()
    GetGuiStylesFromFile()
    version = "0.0.7"
    window_width = 250
    window_height = 235
    playing = false
    timer = 1
    temp_length = 0
    min_rnd = 0
    max_rnd = 1
    frequency = 4
    frequency_rnd = 0
    project_name = reaper.GetProjectName(0)
    project_path = reaper.GetProjectPath()
    project_id, _ = reaper.EnumProjects(-1)
end

-- GUI Initialize function
function Gui_Init()
    ctx = reaper.ImGui_CreateContext('random_play_context')
    font = reaper.ImGui_CreateFont('sans-serif', 16)
    reaper.ImGui_Attach(ctx, font)
    window_name = "Time Selection Randomizer"
end

-- GUI Top Bar
function Gui_TopBar()
    -- GUI Menu Bar
    if reaper.ImGui_BeginChild(ctx, "child_top_bar", window_width, 30) then
        reaper.ImGui_Text(ctx, window_name)

        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(), 5, 0)

        reaper.ImGui_SameLine(ctx)

        local w, _ = reaper.ImGui_CalcTextSize(ctx, "X")
        reaper.ImGui_SetCursorPos(ctx, reaper.ImGui_GetWindowWidth(ctx) - w - 30, 0)

        if reaper.ImGui_BeginChild(ctx, "child_top_bar_buttons", w + 30, 22) then
            reaper.ImGui_Dummy(ctx, 3, 1)
            reaper.ImGui_SameLine(ctx)
            if reaper.ImGui_Button(ctx, 'X##quit_button') then
                if playing then StartStopLoop() end
                open = false
            end
            reaper.ImGui_EndChild(ctx)
        end

        reaper.ImGui_PopStyleVar(ctx, 1)
        reaper.ImGui_EndChild(ctx)
    end
end

-- Gui Elements
function Gui_Elements()
    item_size = 165
    reaper.ImGui_SetCursorPosX(ctx, (window_width - item_size) * 0.5)
    if reaper.ImGui_BeginChild(ctx, "child_length_elements", item_size, reaper.ImGui_GetFontSize(ctx)) then
        reaper.ImGui_Text(ctx, "Set length in seconds")
        reaper.ImGui_SameLine(ctx)
        reaper.ImGui_TextDisabled(ctx, "(?)")
        if reaper.ImGui_IsItemHovered(ctx, reaper.ImGui_HoveredFlags_Stationary()) then
            reaper.ImGui_SetTooltip(ctx, "Drag with mouse left click.\nHold Left Shift to slow down.\nHold Left Ctrl or double mouse left click to input value.")
        end
        reaper.ImGui_EndChild(ctx)
    end

    if length_pos == nil or length_pos <= 0 then
        reaper.ImGui_BeginDisabled(ctx)
    end

    shift_key = false
    if reaper.ImGui_IsKeyDown(ctx, reaper.ImGui_Key_LeftShift()) then shift_key = true end
    SetSliderSpeed(0.1)

    reaper.ImGui_Dummy(ctx, 1, 1)

    item_size = 120
    reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + (window_width - item_size - 13) * 0.5)
    reaper.ImGui_PushItemWidth(ctx, item_size)
    _, min_rnd, max_rnd = reaper.ImGui_DragFloatRange2(ctx, "##range_length", min_rnd, max_rnd, speed, 0, length_pos)
    if length_pos == nil or length_pos <= 0 then
        reaper.ImGui_EndDisabled(ctx)
    end
    if min_rnd < 0 then min_rnd = 0 end
    if max_rnd < 0 then max_rnd = 0 end
    if min_rnd > max_rnd then min_rnd = max_rnd end

    reaper.ImGui_Dummy(ctx, 10, 10)

    item_size = 175
    reaper.ImGui_SetCursorPosX(ctx, (window_width - item_size) * 0.5)
    if reaper.ImGui_BeginChild(ctx, "child_frequency_elements", item_size, reaper.ImGui_GetFontSize(ctx)) then
        reaper.ImGui_Text(ctx, "Frequency per seconds")
        reaper.ImGui_SameLine(ctx)
        reaper.ImGui_TextDisabled(ctx, "(?)")
        if reaper.ImGui_IsItemHovered(ctx, reaper.ImGui_HoveredFlags_Stationary()) then
            local part_1 = "Frequency is expressed in beats per seconds.\n"
            local part_2 = "Below is the randomness around the frequency's value.\n"
            local part_3 = "For example:\n - Randomness = 5 and Frequency = 10.\n - Frequency random range is 5 to 15.\n   (Plus and minus randomness)"
            reaper.ImGui_SetTooltip(ctx, part_1..part_2..part_3)
        end
        reaper.ImGui_EndChild(ctx)
    end

    reaper.ImGui_Dummy(ctx, 1, 1)

    reaper.ImGui_SetNextItemAllowOverlap(ctx)

    item_size = frequency_rnd * 2 + 60
    if item_size < 60 then item_size = 60 end
    if item_size > window_width - 40 then item_size = window_width - 40 end
    x, y = reaper.ImGui_GetCursorPos(ctx)
    reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + (window_width - item_size - 13) * 0.5)
    reaper.ImGui_PushItemWidth(ctx, item_size)
    reaper.ImGui_BeginDisabled(ctx, optional_disabledIn)
    _, _ = reaper.ImGui_DragDouble(ctx, "##drag_frequency_rnd_visual", frequency_rnd, speed, 0, 10000, "")
    reaper.ImGui_EndDisabled(ctx)

    SetSliderSpeed(0.05)
    max_frequency = 10000
    item_size = 60
    reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + (window_width - item_size - 13) * 0.5)
    reaper.ImGui_SetCursorPosY(ctx, y+1)
    reaper.ImGui_PushItemWidth(ctx, item_size)
    changed, frequency = reaper.ImGui_DragDouble(ctx, "##drag_frequency", frequency, speed, 0, max_frequency, "%.2f")
    if frequency > max_frequency then frequency = max_frequency end
    if changed then timer = current_time end

    reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + (window_width - item_size - 13) * 0.5)
    reaper.ImGui_PushItemWidth(ctx, item_size)
    changed, frequency_rnd = reaper.ImGui_DragDouble(ctx, "##drag_frequency_rnd", frequency_rnd, speed, 0, 10000, "%.2f")
    if changed then timer = current_time end

    reaper.ImGui_Dummy(ctx, 10, 10)

    if start_button_disable then reaper.ImGui_BeginDisabled(ctx) end
    if playing then start_button_text = "Stop"
    else start_button_text = "Start" end
    item_size = 70
    reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + (window_width - item_size - 13) * 0.5)
    if reaper.ImGui_Button(ctx, start_button_text, item_size) then
        StartStopLoop()
    end
    if start_button_disable then reaper.ImGui_EndDisabled(ctx) end
end

-- GUI function for all elements
function Gui_Loop()
    Gui_PushTheme()
    -- Window Settings
    local window_flags = reaper.ImGui_WindowFlags_NoCollapse() | reaper.ImGui_WindowFlags_NoTitleBar() | reaper.ImGui_WindowFlags_NoScrollWithMouse()
    reaper.ImGui_SetNextWindowSize(ctx, window_width, window_height, reaper.ImGui_Cond_Once())
    -- Font
    reaper.ImGui_PushFont(ctx, font)
    -- Begin
    visible, open = reaper.ImGui_Begin(ctx, window_name, true, window_flags)
    window_x, window_y = reaper.ImGui_GetWindowPos(ctx)
    window_width, window_height = reaper.ImGui_GetWindowSize(ctx)

    current_time = reaper.ImGui_GetTime(ctx)
    show_elements = true
    start_button_disable = true

    if CheckProjectChanged() then
        if playing then
            new_project_id, _ = reaper.EnumProjects(-1)
            reaper.SelectProjectInstance(project_id)
            StartStopLoop()
            reaper.SelectProjectInstance(new_project_id)
            project_id = new_project_id
            start_pos = 0
            end_pos = 0
        else
            project_id, _ = reaper.EnumProjects(-1)
        end
    end

    -- Script Execution
    if playing then
        TimeLoopRandom()
        start_button_disable = false
    else
        GetTimeSelection()
        if temp_length ~= length_pos then
            min_rnd = 0
            max_rnd = length_pos
        end
        temp_length = length_pos
        if length_pos > 0 then start_button_disable = false end
    end

    if current_time < 0.1 then
        show_elements = false
        max_rnd = length_pos
    end

    -- Play/Stop transport on Space key pressed while in script window focus
    if reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_Space()) then reaper.Main_OnCommand(40044, 0) end

    if visible then
        -- Top bar elements
        Gui_TopBar()

        -- All Gui Elements
        if show_elements then
            if reaper.ImGui_BeginChild(ctx, "child_gui_elements") then
                Gui_Elements()
                reaper.ImGui_EndChild(ctx)
            end
        end

        w, h = reaper.ImGui_CalcTextSize(ctx, "v"..version)
        reaper.ImGui_SetCursorPosX(ctx, window_width - w - 10)
        reaper.ImGui_SetCursorPosY(ctx, window_height - h - 10)
        reaper.ImGui_Text(ctx, "v"..version)

        reaper.ImGui_End(ctx)
    end

    Gui_PopTheme()
    reaper.ImGui_PopFont(ctx)
    if open then
      reaper.defer(Gui_Loop)
    end
end

-- PUSH ALL GUI STYLE SETTINGS
function Gui_PushTheme()
    -- Style Vars
    for i = 1, #style_vars do
        reaper.ImGui_PushStyleVar(ctx, style_vars[i].var, style_vars[i].value)
    end

    -- Style Colors
    for i = 1, #style_colors do
        reaper.ImGui_PushStyleColor(ctx, style_colors[i].col, style_colors[i].value)
    end
end

-- POP ALL GUI STYLE SETTINGS
function Gui_PopTheme()
    reaper.ImGui_PopStyleVar(ctx, #style_vars)
    reaper.ImGui_PopStyleColor(ctx, #style_colors)
end

-- GET TIME SELECTION POSITIONS AND LENGTH
function GetTimeSelection()
    -- Get time selection start and end positions
    start_pos, end_pos = reaper.GetSet_LoopTimeRange(false, false, 0, 1, false)
    length_pos = end_pos - start_pos
end

-- BUTTON PLAY FUNCTION
function StartStopLoop()
    if not playing then GetTimeSelection() end
    if length_pos > 0 then
        playing = not playing
        if playing then
            -- Toggle repeat state
            reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SAVEREPEAT"), 0) -- Save repeat state to restore on stop
            reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SETREPEAT"), 0) -- Toggle repeat state to ON

            -- Get time selection start and end positions
            GetTimeSelection()

            -- Randomize once to prepare play
            RandomizeTimeSelection()

            timer = current_time + 1 / frequency

            region_index = reaper.AddProjectMarker2(0, true, start_pos, end_pos, "Random_Time_Selection_Script", 0, 0xffffffff)

            reaper.UpdateArrange()

            reaper.Main_OnCommand(1007, 0) -- Play transport
        else
            reaper.Main_OnCommand(1016, 0) -- Stop transport

            -- Restore repeat state
            reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_RESTREPEAT"), 0)

            reaper.DeleteProjectMarker(0, region_index, true)

            -- Set time selection start and end positions to first selected ones
            reaper.GetSet_LoopTimeRange(true, true, start_pos, end_pos, true)

            reaper.UpdateArrange()
        end
    end
end

-- LOOP SET RANDOM VALUES
function TimeLoopRandom()
    if timer <= current_time then
        RandomizeTimeSelection()
        temp_frequency = IntervalSwap(math.random(), frequency - frequency_rnd, frequency + frequency_rnd)
        timer = current_time + 1 / temp_frequency
    end
end

function RandomizeTimeSelection()
    length_rnd = IntervalSwap(math.random(), min_rnd, max_rnd)
    start_rnd = IntervalSwap(math.random(), start_pos, end_pos - length_rnd)
    end_rnd = start_rnd + length_rnd

    -- Set time selection start and end positions
    reaper.GetSet_LoopTimeRange(true, true, start_rnd, end_rnd, true)

    -- Set playhead/edit cursor to time selection start
    reaper.SetEditCurPos(start_rnd, true, true)
end

-- CHECK CURRENT PROJECT CHANGE
function CheckProjectChanged()
    if project_name ~= reaper.GetProjectName(0) or project_path ~= reaper.GetProjectPath() then
        project_name = reaper.GetProjectName(0)
        project_path = reaper.GetProjectPath()
        return true
    else
        return false
    end
end

-- CONVERTS A VALUE TO ANOTHER IN NEW RANGE
function IntervalSwap(value, min, max)
    return min + ((max - min) * value)
end

-- SET SPEED FOR SLIDERS IN GUI
function SetSliderSpeed(prefered_speed)
    speed = prefered_speed
    if shift_key then speed = 0.0001 end
end

-- MAIN SCRIPT EXECUTION
SetButtonState(1)
InitialVariables()
Gui_Init()
Gui_Loop()
reaper.atexit(SetButtonState)
