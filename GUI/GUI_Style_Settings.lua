-- @noindex

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
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabActive(), 0x312652FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabUnfocused(), 0x23232BFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabUnfocusedActive(), 0x23232BFF)

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

-----------------------------------------------------------------------------------------

-- DARK GUI VERSION
function Gui_PushTheme()
    -- Style Vars
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowRounding(), 6)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ChildRounding(), 6)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_PopupRounding(), 6)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameRounding(), 6)

    -- Style Colors
    -- Backgrounds
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_WindowBg(), 0x1A1A21FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_MenuBarBg(), 0x292935FF)

    -- Border
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(), 0x71609A4A)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_BorderShadow(), 0x0000003D)

    -- Text
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), 0xFFFFFFFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TextDisabled(), 0x808080FF)

    -- Headers
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Header(), 0x21212BFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderHovered(), 0x30323FFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderActive(), 0x292935FF)

    -- Buttons
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x21212BFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0x30323FFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), 0x292935FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_CheckMark(), 0xBD94FBFF)

    -- Popups
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_PopupBg(), 0x1A1A2199)

    -- Slider
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_SliderGrab(), 0x71609A8A)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_SliderGrabActive(), 0xBD94FB8A)

    -- Frame BG
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(), 0x21212BFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgHovered(), 0x30323FFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgActive(), 0x292935FF)

    -- Tabs
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Tab(), 0x292935FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabHovered(), 0x3D3D52FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabActive(), 0x343647FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabUnfocused(), 0x292935FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabUnfocusedActive(), 0x292935FF)

    -- Title
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBg(), 0x292935FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBgActive(), 0x292935FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBgCollapsed(), 0x292935FF)

    -- Scrollbar
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarBg(), 0x1A1A21FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrab(), 0x292935FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrabHovered(), 0x30323FFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ScrollbarGrabActive(), 0x3D3D52FF)

    -- Separator
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Separator(), 0x71609AFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_SeparatorHovered(), 0xBD94FBFF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_SeparatorActive(), 0xD69AFFFF)

    -- Resize Grip
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGrip(), 0x71609A4A)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGripHovered(), 0xBD94FB4A)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ResizeGripActive(), 0xD69AFF4A)

    -- Docking
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_DockingPreview(), 0x71609AFF)
end
