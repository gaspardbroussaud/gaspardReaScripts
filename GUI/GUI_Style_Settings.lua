--@noindex
--@description Gui Settings for all gaspard's scripts
--@author gaspard
--@version 1.0.0
--@provides [nomain] .
--@about Gui Settings for all gaspard's scripts, called at frame 1 on each GUI script.

local style_vars = {
    {var = reaper.ImGui_StyleVar_WindowRounding(), value = 6},
    {var = reaper.ImGui_StyleVar_ChildRounding(), value = 6},
    {var = reaper.ImGui_StyleVar_PopupRounding(), value = 6},
    {var = reaper.ImGui_StyleVar_FrameRounding(), value = 6}
}

local style_colors = {
    -- Backgrounds
    {col = reaper.ImGui_Col_WindowBg(), value = 0x14141BFF},
    {col = reaper.ImGui_Col_ChildBg(), value = 0x14141BFF},
    {col = reaper.ImGui_Col_MenuBarBg(), value = 0x1F1F28FF},

    -- Borders
    {col = reaper.ImGui_Col_Border(), value = 0x594A8C4A},
    {col = reaper.ImGui_Col_BorderShadow(), value = 0x0000003D},

    -- Text
    {col = reaper.ImGui_Col_Text(), value = 0xFFFFFFFF},
    {col = reaper.ImGui_Col_TextDisabled(), value = 0x808080FF},

    -- Headers
    {col = reaper.ImGui_Col_Header(), value = 0x574F8E55},
    {col = reaper.ImGui_Col_HeaderHovered(), value = 0x7C71C255},
    {col = reaper.ImGui_Col_HeaderActive(), value = 0x6B60B555},

    -- Buttons
    {col = reaper.ImGui_Col_Button(), value = 0x574F8EFF},
    {col = reaper.ImGui_Col_ButtonHovered(), value = 0x7C71C2FF},
    {col = reaper.ImGui_Col_ButtonActive(), value = 0x6B60B5FF},
    {col = reaper.ImGui_Col_CheckMark(), value = 0xFFFFFFFF},

    -- Popups
    {col = reaper.ImGui_Col_PopupBg(), value = 0x14141B99},

    -- Sliders
    {col = reaper.ImGui_Col_SliderGrab(), value = 0x796BB6FF},
    {col = reaper.ImGui_Col_SliderGrabActive(), value = 0x9A8BE1FF},

    -- Frame Background
    {col = reaper.ImGui_Col_FrameBg(), value = 0x574F8EAA},
    {col = reaper.ImGui_Col_FrameBgHovered(), value = 0x7C71C2AA},
    {col = reaper.ImGui_Col_FrameBgActive(), value = 0x6B60B5AA},

    -- Tabs
    {col = reaper.ImGui_Col_Tab(), value = 0x23232BFF},
    {col = reaper.ImGui_Col_TabHovered(), value = 0x3B2F66FF},
    {col = reaper.ImGui_Col_TabSelected(), value = 0x312652FF},
    {col = reaper.ImGui_Col_TabDimmed(), value = 0x23232BFF},
    {col = reaper.ImGui_Col_TabDimmedSelected(), value = 0x23232BFF},

    -- Title
    {col = reaper.ImGui_Col_TitleBg(), value = 0x23232BFF},
    {col = reaper.ImGui_Col_TitleBgActive(), value = 0x23232BFF},
    {col = reaper.ImGui_Col_TitleBgCollapsed(), value = 0x23232BFF},

    -- Scrollbar
    {col = reaper.ImGui_Col_ScrollbarBg(), value = 0x14141BFF},
    {col = reaper.ImGui_Col_ScrollbarGrab(), value = 0x574F8EFF},
    {col = reaper.ImGui_Col_ScrollbarGrabHovered(), value = 0x7C71C2FF},
    {col = reaper.ImGui_Col_ScrollbarGrabActive(), value = 0x6B60B5FF},

    -- Separators
    {col = reaper.ImGui_Col_Separator(), value = 0x594A8CFF},
    {col = reaper.ImGui_Col_SeparatorHovered(), value = 0x796BB6FF},
    {col = reaper.ImGui_Col_SeparatorActive(), value = 0x9A8BE1FF},

    -- Resize Grip
    {col = reaper.ImGui_Col_ResizeGrip(), value = 0x594A8C4A},
    {col = reaper.ImGui_Col_ResizeGripHovered(), value = 0x796BB64A},
    {col = reaper.ImGui_Col_ResizeGripActive(), value = 0x9A8BE14A},

    -- Docking
    {col = reaper.ImGui_Col_DockingPreview(), value = 0x796BB6FF}
}

return { vars = style_vars, colors = style_colors }
