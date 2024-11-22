--@noindex
--@description Random play point and time selection size
--@author gaspard
--@version 0.0.1
--@changelog Initial release
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
    window_width = 300
    window_height = 200
    pos_rnd = 0
    min_rnd = 0
    max_rnd = 10
    playing = false
    timer = 0
end

-- GUI Initialize function
function Gui_Init()
    ctx = reaper.ImGui_CreateContext('random_play_context')
    font = reaper.ImGui_CreateFont('sans-serif', 15)
    reaper.ImGui_Attach(ctx, font)
    window_name = "RANDOM TIME SELECTION"
end

-- GUI Elements
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
                SetButtonState()
                open = false
            end
            reaper.ImGui_EndChild(ctx)
        end

        reaper.ImGui_PopStyleVar(ctx, 1)
        reaper.ImGui_EndChild(ctx)
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

    current_time = math.floor(reaper.ImGui_GetTime(ctx))

    -- Script Execution
    if playing then
        Randomize()
    end

    if visible then
        -- Top bar elements
        Gui_TopBar()

        reaper.ImGui_Text(ctx, "Time elapsed: "..tostring(current_time))

        reaper.ImGui_Text(ctx, "Random position: "..tostring(pos_rnd))

        reaper.ImGui_Text(ctx, "Set random interval (%):")

        reaper.ImGui_SameLine(ctx)

        if reaper.ImGui_BeginTable(ctx, "table_input_lengths", 2, reaper.ImGui_TableFlags_SizingFixedFit(), 70) then
            reaper.ImGui_TableNextRow(ctx)
            reaper.ImGui_TableNextColumn(ctx)
            reaper.ImGui_PushItemWidth(ctx, 30)
            _, min_rnd = reaper.ImGui_InputText(ctx, "##input_text_min_rnd", tostring(min_rnd))
            min_rnd = tonumber(min_rnd)

            reaper.ImGui_TableNextColumn(ctx)
            reaper.ImGui_PushItemWidth(ctx, 30)
            _, max_rnd = reaper.ImGui_InputText(ctx, "##input_text_max_rnd", tostring(max_rnd))
            max_rnd = tonumber(max_rnd)

            reaper.ImGui_EndTable(ctx)
        end

        reaper.ImGui_Dummy(ctx, 10, 10)

        if playing then start_button_text = "Stop"
        else start_button_text = "Start" end
        x, _ = reaper.ImGui_GetContentRegionAvail(ctx)
        reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + (x - 50) * 0.5)
        if reaper.ImGui_Button(ctx, start_button_text, 50) then
            playing = not playing
            GetTimeSelection()
        end

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

-- GET TIME SELECTION START AND END POSITIONS
function GetTimeSelection()
    start_pos, end_pos = reaper.GetSet_LoopTimeRange(false, false, 0, 1, false)
end

function Randomize()
    if timer ~= current_time then
        pos_rnd = math.random(min_rnd, max_rnd)
        timer = current_time
    end
end

-- MAIN SCRIPT EXECUTION
SetButtonState(1)
InitialVariables()
Gui_Init()
Gui_Loop()
reaper.atexit(SetButtonState)
