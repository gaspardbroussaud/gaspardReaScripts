--@noindex
--@description Layer manipulator GUI
--@author gaspard

local GUI = {}

-- Window variables
local window_name = "LAYER MANIPULATOR"
local window_x, window_y
local window_width, window_height = 600, 300
local min_width, min_height, max_width, max_height = 300, 150, 1200, 600
local no_scrollbar_flags = reaper.ImGui_WindowFlags_NoScrollWithMouse() | reaper.ImGui_WindowFlags_NoScrollbar()

-- Get GUI style from file
local GUI_STYLE = dofile(reaper.GetResourcePath().."/Scripts/Gaspard ReaScripts/Libraries/GUI_STYLE.lua")
local GUI_SYS = dofile(reaper.GetResourcePath().."/Scripts/Gaspard ReaScripts/Libraries/GUI_SYS.lua")

local default_font_size = 16

-- ImGui Init
ctx = reaper.ImGui_CreateContext('layer_manipulator_context')
GUI.fonts = {}
GUI.fonts.arial = {}
GUI.fonts.arial.classic = reaper.ImGui_CreateFont(GUI_STYLE.FONTS.ARIAL)
GUI.fonts.arial.italic = reaper.ImGui_CreateFont(GUI_STYLE.FONTS.ARIAL, reaper.ImGui_FontFlags_Italic())
GUI.fonts.icons = reaper.ImGui_CreateFontFromFile(GUI_STYLE.FONTS.ICONS)
GUI.icon_size = {w = 22, h = 22}
reaper.ImGui_Attach(ctx, GUI.fonts.arial.classic)
reaper.ImGui_Attach(ctx, GUI.fonts.arial.italic)
reaper.ImGui_Attach(ctx, GUI.fonts.icons)

-- Push all GUI style settings
local function Gui_PushTheme()
    -- Style Vars
    for i = 1, #GUI_STYLE.VARS do
        reaper.ImGui_PushStyleVar(ctx, GUI_STYLE.VARS[i].var, GUI_STYLE.VARS[i].value)
    end

    -- Style Colors
    for i = 1, #GUI_STYLE.COLORS do
        reaper.ImGui_PushStyleColor(ctx, GUI_STYLE.COLORS[i].col, GUI_STYLE.COLORS[i].value)
    end
end

-- Pop all GUI style settings
local function Gui_PopTheme()
    reaper.ImGui_PopStyleVar(ctx, #GUI_STYLE.VARS)
    reaper.ImGui_PopStyleColor(ctx, #GUI_STYLE.COLORS)
end

local function Draw_ResizeHandle(draw_list)
    local radius = 5

    local win_x, win_y = reaper.ImGui_GetWindowPos(ctx)
    local win_w, win_h = reaper.ImGui_GetWindowSize(ctx)

    local x = win_x + win_w - radius
    local y = win_y + win_h - radius

    local start_angle = math.rad(-45)
    local end_angle = math.rad(135)

    reaper.ImGui_DrawList_PathLineTo(draw_list, x, y)
    reaper.ImGui_DrawList_PathArcTo(draw_list, x, y, radius, start_angle, end_angle, 12)
    reaper.ImGui_DrawList_PathFillConvex(draw_list, 0xFFFFFFAA)
end

-- Gui Version on bottom right
local function Display_Version()
    reaper.ImGui_PushFont(ctx, GUI.fonts.arial.italic, default_font_size * 0.75)
    local w, h = reaper.ImGui_CalcTextSize(ctx, "v"..version)
    reaper.ImGui_SetCursorPosX(ctx, window_width - w - reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding()) * 2)
    reaper.ImGui_SetCursorPosY(ctx, window_height - h - select(2, reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding())) * 2)
    reaper.ImGui_Text(ctx, "v"..version)
    reaper.ImGui_PopFont(ctx)
end

-- GUI Top Bar
local function Display_TopBar()
    -- OTHER GUI TOPBAR
    reaper.ImGui_BeginGroup(ctx)
    -- Name
    reaper.ImGui_Text(ctx, window_name)

    --[[reaper.ImGui_SameLine(ctx)

    reaper.ImGui_PushFont(ctx, GUI.fonts.arial.italic, default_font_size * 0.75)
    reaper.ImGui_Text(ctx, "v"..version)
    reaper.ImGui_PopFont(ctx)]]

    -- Buttons
    local menu = {}
    table.insert(menu, {icon = 'QUIT', hint = 'Close', font = GUI.fonts.icons, size = GUI.icon_size.h, right_click = false})
    table.insert(menu, {icon = 'GEAR', hint = 'Settings', font = GUI.fonts.icons, size = GUI.icon_size.h, right_click = false})
    local rv, button = GUI_SYS.IconButtonRight(ctx, menu, window_width)
    if rv then
        --local right_click = reaper.ImGui_IsMouseClicked(ctx, reaper.ImGui_MouseButton_Right())
        if button == 'QUIT' then
            open = false
        elseif button == 'GEAR' then
            reaper.ImGui_OpenPopup(ctx, "popup_settings")
        end
    end
    reaper.ImGui_EndGroup(ctx)
end

local function Display_Elements()
    SYS.TRACKS.GROUPS = reaper.CountSelectedTracks(-1) > 0 and SYS.TRACKS.GetTrackGroups(reaper.GetSelectedTrack(-1, 0)) or nil
    SYS.TRACKS.PARENT = SYS.TRACKS.GROUPS and SYS.TRACKS.PARENT or nil

    reaper.ImGui_BeginGroup(ctx) -- GLOBAL

    local pos_y = reaper.ImGui_GetCursorPosY(ctx)
    local parent_name = SYS.TRACKS.PARENT and select(2, reaper.GetTrackName(SYS.TRACKS.PARENT)) or ""
    reaper.ImGui_Text(ctx, parent_name)

    reaper.ImGui_SetCursorPosY(ctx, pos_y + select(2, reaper.ImGui_CalcTextSize(ctx, "A")) + select(2, reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding())))
    if reaper.ImGui_BeginChild(ctx, "##child_track_groups", 200, -1) then--, reaper.ImGui_ChildFlags_Borders()) then
        if not SYS.TRACKS.GROUPS then goto skip_groups end
        reaper.ImGui_Dummy(ctx, -1, select(2, reaper.ImGui_CalcTextSize(ctx, "A")) + select(2, reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding())))
        for i, group in ipairs(SYS.TRACKS.GROUPS) do
            if group.name then
                retval, group.selected = reaper.ImGui_Selectable(ctx, group.name.."##"..group.guid, group.selected)
                if retval then
                    reaper.GetSetMediaTrackInfo_String(track, "P_EXT:"..SYS.extname.."SELECTED", tostring(group.selected), true)
                end
            end
        end
        ::skip_groups::
        reaper.ImGui_EndChild(ctx)
    end

    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_SetCursorPosY(ctx, pos_y)

    reaper.ImGui_BeginGroup(ctx) -- TABS
    if reaper.ImGui_BeginTabBar(ctx, "tab_controls") then
        if reaper.ImGui_BeginTabItem(ctx, "Matrix##tab_matrix") then
            if reaper.ImGui_BeginTable(ctx, "##table_matrix_markers", SYS.MARKERS.COUNT) then
                reaper.ImGui_TableNextRow(ctx)
                for i, marker in ipairs(SYS.MARKERS.LIST) do
                    reaper.ImGui_TableNextColumn(ctx)
                    reaper.ImGui_Text(ctx, "Name "..tostring(i))
                end
                for i, group in ipairs(SYS.TRACKS.GROUPS) do
                    reaper.ImGui_TableNextRow(ctx)
                    for j, marker in ipairs(SYS.MARKERS.LIST) do
                        reaper.ImGui_TableNextColumn(ctx)
                        reaper.ImGui_Text(ctx, tostring(i)..", "..tostring(j))
                    end
                end

                reaper.ImGui_EndTable(ctx)
            end
            reaper.ImGui_EndTabItem(ctx)
        end

        if reaper.ImGui_BeginTabItem(ctx, "Files##tab_files") then
            reaper.ImGui_TextWrapped(ctx, "Files in group, all files can be selected and modified from here.")
            reaper.ImGui_EndTabItem(ctx)
        end
        reaper.ImGui_EndTabBar(ctx)
    end
    reaper.ImGui_EndGroup(ctx) -- TABS

    reaper.ImGui_EndGroup(ctx) -- GLOBAL
end

local function Display_Settings()
    local popup_w, popup_h = 200, 150
    reaper.ImGui_SetNextWindowSize(ctx, popup_w, popup_h)
    local pos_x = window_x + window_width - popup_w * 0.5 - reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding())
    local pos_y = window_y + GUI.icon_size.h + select(2, reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding())) * 6
    reaper.ImGui_SetNextWindowPos(ctx, pos_x, pos_y)
    if reaper.ImGui_BeginPopup(ctx, "popup_settings") then
        reaper.ImGui_Text(ctx, "Settings")
        reaper.ImGui_Separator(ctx)
        reaper.ImGui_Checkbox(ctx, "Setting 1")
        reaper.ImGui_EndPopup(ctx)
    end
end

GUI.Loop = function()
    -- GUI --------
    Gui_PushTheme()

    -- Window Settings
    local window_flags = reaper.ImGui_WindowFlags_NoCollapse() | reaper.ImGui_WindowFlags_NoTitleBar() | no_scrollbar_flags
    reaper.ImGui_SetNextWindowSize(ctx, window_width, window_height, reaper.ImGui_Cond_Once())
    reaper.ImGui_SetNextWindowSizeConstraints(ctx, min_width, min_height, max_width, max_height)

    -- Font
    reaper.ImGui_PushFont(ctx, GUI.fonts.arial.classic, default_font_size)

    -- Begin
    visible, open = reaper.ImGui_Begin(ctx, window_name, true, window_flags)
    window_x, window_y = reaper.ImGui_GetWindowPos(ctx)
    window_width, window_height = reaper.ImGui_GetWindowSize(ctx)

    global_spacing = reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing())

    if visible then
        shortcut_activated = true

        Display_TopBar()

        reaper.ImGui_Separator(ctx)

        Display_Elements()

        Display_Settings()

        Display_Version()

        --Draw_ResizeHandle(reaper.ImGui_GetForegroundDrawList(ctx))

        reaper.ImGui_End(ctx)
    end

    Gui_PopTheme()
    reaper.ImGui_PopFont(ctx)

    -- Quit app window on Escape key pressed
    if reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_Escape()) then open = false end

    if open then
        reaper.defer(GUI.Loop)
    end
end

return GUI
