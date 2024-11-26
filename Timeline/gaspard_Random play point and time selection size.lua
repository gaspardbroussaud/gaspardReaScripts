--@description Random play point and time selection size
--@author gaspard
--@version 0.0.3
--@changelog
--  - Update frequency display and randomness
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

-- All initial variable for script and GUI
function InitialVariables()
    version = "0.0.3"
    window_width = 250
    window_height = 235
    playing = false
    timer = 1
    temp_length = 0
    min_rnd = 0
    max_rnd = 1
    frequency = 0.25
    frequency_rnd = 0
end

-- GUI Initialize function
function Gui_Init()
    ctx = reaper.ImGui_CreateContext('random_play_context')
    font = reaper.ImGui_CreateFont('sans-serif', 16)
    reaper.ImGui_Attach(ctx, font)
    window_name = "RANDOM TIME SELECTION"
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

    speed = 0.1
    if reaper.ImGui_IsKeyDown(ctx, reaper.ImGui_Key_LeftShift()) then speed = 0.0001 end

    reaper.ImGui_Dummy(ctx, 1, 1)

    item_size = 120
    reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + (window_width - item_size - 13) * 0.5)
    reaper.ImGui_PushItemWidth(ctx, item_size)
    _, min_rnd, max_rnd = reaper.ImGui_DragFloatRange2(ctx, "##range_length", min_rnd, max_rnd, speed, 0, length_pos)
    if length_pos == nil or length_pos <= 0 then
        reaper.ImGui_EndDisabled(ctx)
    end

    reaper.ImGui_Dummy(ctx, 10, 10)

    item_size = 165
    reaper.ImGui_SetCursorPosX(ctx, (window_width - item_size) * 0.5)
    if reaper.ImGui_BeginChild(ctx, "child_frequency_elements", item_size, reaper.ImGui_GetFontSize(ctx)) then
        reaper.ImGui_Text(ctx, "Frequency in seconds")
        reaper.ImGui_SameLine(ctx)
        reaper.ImGui_TextDisabled(ctx, "(?)")
        if reaper.ImGui_IsItemHovered(ctx, reaper.ImGui_HoveredFlags_Stationary()) then
            reaper.ImGui_SetTooltip(ctx, "Frequency is expressed in seconds.\nBelow is the randomness around the frequency's value.\nFor example:\n - Randomness = 5 and Frequency = 10.\n - Frequency random range is 5 to 15.\n   (Plus and minus randomness)")
        end
        reaper.ImGui_EndChild(ctx)
    end

    reaper.ImGui_Dummy(ctx, 1, 1)

    item_size = 60
    reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + (window_width - item_size - 13) * 0.5)
    reaper.ImGui_PushItemWidth(ctx, item_size)
    _, frequency = reaper.ImGui_DragDouble(ctx, "##drag_frequency", frequency, speed, 0, 9999.99, "%.2f")
    if frequency > 9999.99 then frequency = 9999.99 end

    item_size = (frequency_rnd + 6) * 10
    if item_size < 25 then item_size = 25 end
    if item_size > window_width - 40 then item_size = window_width - 40 end
    reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + (window_width - item_size - 13) * 0.5)
    reaper.ImGui_PushItemWidth(ctx, item_size)
    _, frequency_rnd = reaper.ImGui_DragDouble(ctx, "##drag_frequency_rnd", frequency_rnd, speed, 0, 100, "%.2f")

    reaper.ImGui_Dummy(ctx, 10, 10)

    if playing then start_button_text = "Stop"
    else start_button_text = "Start" end
    item_size = 70
    reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + (window_width - item_size - 13) * 0.5)
    if reaper.ImGui_Button(ctx, start_button_text, item_size) then
        StartStopLoop()
    end
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

    -- Script Execution
    if playing then
        TimeLoopRandom()
    else
        GetTimeSelection()
        --if max_rnd > length_pos then max_rnd = length_pos end
        if temp_length ~= length_pos then
            min_rnd = 0
            max_rnd = length_pos
        end
        temp_length = length_pos
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
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowRounding(), 6)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ChildRounding(), 6)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_PopupRounding(), 6)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameRounding(), 6)

    -- Style Colors
    -- Backgrounds
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_WindowBg(), 0x14141BFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ChildBg(), 0x14141BFF) --Added
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_MenuBarBg(), 0x1F1F28FF)

    -- Bordures
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(), 0x594A8C4A)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_BorderShadow(), 0x0000003D)

    -- Texte
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), 0xFFFFFFFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TextDisabled(), 0x808080FF)

    -- En-têtes (Headers)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Header(), 0x574F8E55)--0x23232BAF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderHovered(), 0x7C71C255)--0x2C2D39AF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderActive(), 0x6B60B555)--0x272734AF)

    -- Boutons
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x574F8EFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0x7C71C2FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), 0x6B60B5FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_CheckMark(), 0xFFFFFFFF)

    -- Popups
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_PopupBg(), 0x14141B99)

    -- Curseur (Slider)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_SliderGrab(), 0x796BB6FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_SliderGrabActive(), 0x9A8BE1FF)

    -- Fond de cadre (Frame BG)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(), 0x574F8EAA)--0x23232BFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgHovered(), 0x7C71C2AA)--0x2C2D39FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgActive(), 0x6B60B5AA)--0x272734FF)

    -- Onglets (Tabs)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Tab(), 0x23232BFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabHovered(), 0x3B2F66FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabSelected(), 0x312652FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabDimmed(), 0x23232BFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabDimmedSelected(), 0x23232BFF)

    -- Titre
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBg(), 0x23232BFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBgActive(), 0x23232BFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBgCollapsed(), 0x23232BFF)

    -- Scrollbar
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarBg(), 0x14141BFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrab(), 0x574F8EFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrabHovered(), 0x7C71C2FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrabActive(), 0x6B60B5FF)

    -- Séparateurs
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Separator(), 0x594A8CFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_SeparatorHovered(), 0x796BB6FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_SeparatorActive(), 0x9A8BE1FF)

    -- Redimensionnement (Resize Grip)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGrip(), 0x594A8C4A)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGripHovered(), 0x796BB64A)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGripActive(), 0x9A8BE14A)

    -- Docking
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_DockingPreview(), 0x796BB6FF)
end

-- POP ALL GUI STYLE SETTINGS
function Gui_PopTheme()
    reaper.ImGui_PopStyleVar(ctx, 4)
    reaper.ImGui_PopStyleColor(ctx, 39)
end

-- GET TIME SELECTION POSITIONS AND LENGTH
function GetTimeSelection()
    -- Get time selection start and end positions
    start_pos, end_pos = reaper.GetSet_LoopTimeRange(false, false, 0, 1, false)
    length_pos = end_pos - start_pos
end

-- BUTTON PLAY FUNCTION
function StartStopLoop()
    playing = not playing
    if playing then
        -- Toggle repeat state
        reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SAVEREPEAT"), 0) -- Save repeat state to restore on stop
        reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SETREPEAT"), 0) -- Toggle repeat state to ON

        -- Get time selection start and end positions
        GetTimeSelection()

        -- Randomize once to prepare play
        RandomizeTimeSelection()

        -- Set playhead/edit cursor to time selection start
        reaper.SetEditCurPos(start_pos, true, true)

        timer = current_time + frequency

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

-- LOOP SET RANDOM VALUES
function TimeLoopRandom()
    if timer <= current_time then
        RandomizeTimeSelection()
        temp_frequency = IntervalSwap(math.random(), frequency - frequency_rnd, frequency + frequency_rnd)
        timer = current_time + temp_frequency
    end
end

function RandomizeTimeSelection()
    length_rnd = IntervalSwap(math.random(), min_rnd, max_rnd)--0, length_pos)
    start_rnd = IntervalSwap(math.random(), start_pos, end_pos - length_rnd)
    end_rnd = start_rnd + length_rnd

    -- Set time selection start and end positions
    reaper.GetSet_LoopTimeRange(true, true, start_rnd, end_rnd, true)
end

function IntervalSwap(value, min, max)
    return min + ((max - min) * value)
end

-- MAIN SCRIPT EXECUTION
SetButtonState(1)
InitialVariables()
Gui_Init()
Gui_Loop()
reaper.atexit(SetButtonState)
