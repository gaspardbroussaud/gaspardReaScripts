--@author gaspard
--@version 1.0.1
--@provides
--  [nomain] .
--  Icons_Solid.ttf

-- TEMPLATE IN SCRIPT:
--package.path = package.path .. ';' .. reaper.GetResourcePath()..'/Scripts/Gaspard ReaScripts/Libraries' .. '/?.lua'
--local GUI_STYLE = require('GUI_STYLE')
--
--or
--
--local GUI_STYLE = dofile(reaper.GetResourcePath().."/Scripts/Gaspard ReaScripts/Libraries/GUI_STYLE.lua")

local _STYLE_FONT = {
    ICONS = reaper.GetResourcePath()..'/Scripts/Gaspard ReaScripts/Libraries/Icons_Solid.ttf',
    ARIAL = 'arial'
}

local _ICONS = {
    ['QUIT'] = '9',
    ['GEAR'] = 'A',
    ['NEW_FILE'] = 'P',
    ['IMPORT_FILE'] = 'M',
    ['UPLOAD'] = 'I',
    ['NUM_SORT_UP'] = 'r',
    ['NUM_SORT_DOWN'] = 'q',
    ['ALPHABETICAL_SORT_UP'] = 't',
    ['ALPHABETICAL_SORT_DOWN'] = 's',
    ['FAVORITE_SORT_UP'] = '&',
    ['FAVORITE_SORT_DOWN'] = '%',
    ['FAVORITE'] = 'S',
    ['BOOKMARK'] = 'a',
    ['REFRESH_ARROW'] = 'J'
}

local _STYLE_VAR = {
    {var = reaper.ImGui_StyleVar_WindowRounding(), value = 6},
    {var = reaper.ImGui_StyleVar_ChildRounding(), value = 6},
    {var = reaper.ImGui_StyleVar_PopupRounding(), value = 6},
    {var = reaper.ImGui_StyleVar_FrameRounding(), value = 6}
}

local _COLORS = {
    WHITE = 0xFFFFFFFF,
    GRAY = 0x808080FF,
    BLACK = 0x00000000,
    GRAY_BG = 0x2B2B2BFF,
    BLACK_RAISIN = 0x23232BFF,
    BLACK_BG = 0x14141BFF,
    BLACK_ISH = 0x0000003D,
    EERIE_BLACK = 0x1F1F28FF,
    DARK_PURPLE = 0x594A8C4A,
    PURPLE = 0x574F8EFF,
    PURPLE_TRANSPARANT = 0x574F8EAA,
    PURPLE_MORE_TRANSPARENT = 0x574F8EA1,
    LIGHT_PURPLE = 0x7C71C2FF,
    LIGHT_PURPLE_TRANSPARANT = 0x7C71C2AA,
    LIGHTER_PURPLE = 0x796BB6FF,
    VIOLET_PURPLE = 0x6B60B5FF,
    VIOLET_PURPLE_TRANSPARENT = 0x6B60B5FA,
    VIOLET_PURPLE_MORE_TRANSPARENT = 0x6B60B5AA,
    LAVENDER_PURPLE = 0x9A8BE1FF,
    PURPLE_NAVY = 0x594A8CFF
}

local _STYLE_COL = {
    -- Backgrounds
    {col = reaper.ImGui_Col_WindowBg(), value = _COLORS.BLACK_BG},
    {col = reaper.ImGui_Col_ChildBg(), value = _COLORS.BLACK_BG},
    {col = reaper.ImGui_Col_MenuBarBg(), value = _COLORS.EERIE_BLACK},
    {col = reaper.ImGui_Col_PopupBg(), value = _COLORS.BLACK_BG},

    -- Borders
    {col = reaper.ImGui_Col_Border(), value = _COLORS.DARK_PURPLE},
    {col = reaper.ImGui_Col_BorderShadow(), value = _COLORS.BLACK_ISH},

    -- Text
    {col = reaper.ImGui_Col_Text(), value = _COLORS.WHITE},
    {col = reaper.ImGui_Col_TextDisabled(), value = _COLORS.GRAY},

    -- Headers
    {col = reaper.ImGui_Col_Header(), value = _COLORS.PURPLE},
    {col = reaper.ImGui_Col_HeaderHovered(), value = _COLORS.LIGHT_PURPLE},
    {col = reaper.ImGui_Col_HeaderActive(), value = _COLORS.VIOLET_PURPLE_TRANSPARENT},

    -- Buttons
    {col = reaper.ImGui_Col_Button(), value = _COLORS.PURPLE},
    {col = reaper.ImGui_Col_ButtonHovered(), value = _COLORS.LIGHT_PURPLE},
    {col = reaper.ImGui_Col_ButtonActive(), value = _COLORS.VIOLET_PURPLE},
    {col = reaper.ImGui_Col_CheckMark(), value = _COLORS.WHITE},

    -- Sliders
    {col = reaper.ImGui_Col_SliderGrab(), value = _COLORS.LIGHT_PURPLE},--LIGHTER_PURPLE
    {col = reaper.ImGui_Col_SliderGrabActive(), value = _COLORS.LAVENDER_PURPLE},

    -- Frame Background
    {col = reaper.ImGui_Col_FrameBg(), value = _COLORS.PURPLE_TRANSPARANT},
    {col = reaper.ImGui_Col_FrameBgHovered(), value = _COLORS.LIGHT_PURPLE_TRANSPARANT},
    {col = reaper.ImGui_Col_FrameBgActive(), value = _COLORS.VIOLET_PURPLE_TRANSPARENT},

    -- Tabs
    {col = reaper.ImGui_Col_Tab(), value = _COLORS.PURPLE_MORE_TRANSPARENT},
    {col = reaper.ImGui_Col_TabHovered(), value = _COLORS.LIGHT_PURPLE},
    {col = reaper.ImGui_Col_TabSelected(), value = _COLORS.VIOLET_PURPLE},
    {col = reaper.ImGui_Col_TabDimmed(), value = _COLORS.BLACK_RAISIN},
    {col = reaper.ImGui_Col_TabDimmedSelected(), value = _COLORS.BLACK_RAISIN},

    -- Title
    {col = reaper.ImGui_Col_TitleBg(), value = _COLORS.BLACK_RAISIN},
    {col = reaper.ImGui_Col_TitleBgActive(), value = _COLORS.BLACK_RAISIN},
    {col = reaper.ImGui_Col_TitleBgCollapsed(), value = _COLORS.BLACK_RAISIN},

    -- Scrollbar
    {col = reaper.ImGui_Col_ScrollbarBg(), value = _COLORS.BLACK_BG},
    {col = reaper.ImGui_Col_ScrollbarGrab(), value = _COLORS.PURPLE},
    {col = reaper.ImGui_Col_ScrollbarGrabHovered(), value = _COLORS.LIGHT_PURPLE},
    {col = reaper.ImGui_Col_ScrollbarGrabActive(), value = _COLORS.VIOLET_PURPLE},

    -- Separators
    {col = reaper.ImGui_Col_Separator(), value = _COLORS.PURPLE_NAVY},
    {col = reaper.ImGui_Col_SeparatorHovered(), value = _COLORS.LIGHT_PURPLE},--LIGHTER_PURPLE
    {col = reaper.ImGui_Col_SeparatorActive(), value = _COLORS.LAVENDER_PURPLE},

    -- Resize Grip
    {col = reaper.ImGui_Col_ResizeGrip(), value = _COLORS.BLACK},
    {col = reaper.ImGui_Col_ResizeGripHovered(), value = _COLORS.BLACK},
    {col = reaper.ImGui_Col_ResizeGripActive(), value = _COLORS.BLACK},

    -- Docking
    {col = reaper.ImGui_Col_DockingPreview(), value = _COLORS.LIGHT_PURPLE}--LIGHTER_PURPLE
}

return {FONTS = _STYLE_FONT, ICONS = _ICONS, VARS = _STYLE_VAR, COLORS = _STYLE_COL}
