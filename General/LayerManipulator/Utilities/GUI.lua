--@noindex
--@description Layer manipulator GUI
--@author gaspard

local GUI = {}

-- Window variables
local window_name = "LAYER MANIPULATOR"
local window_x, window_y
local window_width, window_height = 600, 350
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
GUI.fonts.arial.classic = reaper.ImGui_CreateFontFromFile(GUI_STYLE.FONTS.ARIAL.CLASSIC)
GUI.fonts.arial.vertical = reaper.ImGui_CreateFontFromFile(GUI_STYLE.FONTS.ARIAL.VERTICAL)
GUI.fonts.arial.italic = reaper.ImGui_CreateFont(GUI_STYLE.FONTS.ARIAL.CLASSIC, reaper.ImGui_FontFlags_Italic())
GUI.fonts.icons = reaper.ImGui_CreateFontFromFile(GUI_STYLE.FONTS.ICONS)
GUI.icon_size = {w = 22, h = 22}
reaper.ImGui_Attach(ctx, GUI.fonts.arial.classic)
reaper.ImGui_Attach(ctx, GUI.fonts.arial.vertical)
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

local function Draw_VerticalText(text)
    reaper.ImGui_PushFont(ctx, GUI.fonts.arial.vertical, default_font_size)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(), reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing()), 0)
    local letter_spacing = select(2, reaper.ImGui_CalcTextSize(ctx, 'A')) - 2
    local pos_x, pos_y = reaper.ImGui_GetCursorPosX(ctx), reaper.ImGui_GetCursorPosY(ctx) - letter_spacing * #text
    text = text:reverse()
    text = text:sub(1, 1)
    for ci = 1, #text do
        reaper.ImGui_SetCursorPos(ctx, pos_x, pos_y + letter_spacing * (ci - 1))
        reaper.ImGui_Text(ctx, text:sub(ci, ci))
    end
    reaper.ImGui_PopStyleVar(ctx)
    reaper.ImGui_PopFont(ctx)
end


local function Display_Elements()
    SYS.TRACKS.GROUPS = reaper.CountSelectedTracks(-1) > 0 and SYS.TRACKS.GetTrackGroups(reaper.GetSelectedTrack(-1, 0)) or nil
    SYS.TRACKS.PARENT = SYS.TRACKS.GROUPS and SYS.TRACKS.PARENT or nil
    SYS.MARKERS.GetGroupMarkers()

    reaper.ImGui_BeginGroup(ctx) -- GLOBAL

    local pos_y = reaper.ImGui_GetCursorPosY(ctx)
    local parent_name = SYS.TRACKS.PARENT and select(2, reaper.GetTrackName(SYS.TRACKS.PARENT)) or ""
    local og_x, og_y = reaper.ImGui_GetCursorPos(ctx)
    reaper.ImGui_Text(ctx, parent_name)

    reaper.ImGui_SetCursorPosY(ctx, pos_y + select(2, reaper.ImGui_CalcTextSize(ctx, "A")))

    local tabs_offset_width = 200
    reaper.ImGui_BeginGroup(ctx) -- TABS
    reaper.ImGui_SetCursorPosX(ctx, og_x + tabs_offset_width)
    local tabs_x = reaper.ImGui_GetCursorPosX(ctx)
    pos_x, pos_y = og_x, og_y
    local tab_displayed = "Matrix"
    if reaper.ImGui_BeginTabBar(ctx, "tab_controls") then
        if reaper.ImGui_BeginTabItem(ctx, "Matrix##tab_matrix") then
            tab_displayed = "Matrix"
            reaper.ImGui_EndTabItem(ctx)
        end

        if reaper.ImGui_BeginTabItem(ctx, "Files##tab_files") then
            tab_displayed = "Files"
            reaper.ImGui_EndTabItem(ctx)
        end
        reaper.ImGui_EndTabBar(ctx)
    end
    reaper.ImGui_EndGroup(ctx) -- TABS

    ------

    reaper.ImGui_BeginGroup(ctx) -- TABLE

    if SYS.TRACKS.GROUPS then
        local column_count = tab_displayed == "Matrix" and SYS.MARKERS.COUNT + 1 or 1
        reaper.ShowConsoleMsg("\n"..tostring(column_count))
        local first_col_width = tabs_offset_width - reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding()) * 2
        local table_width = tab_displayed == "Matrix" and -1 or first_col_width
        pos_y = reaper.ImGui_GetCursorPosY(ctx)
        if tab_displayed == "Files" and SYS.MARKERS.COUNT > 0 then
            local header_height = 0
            local length = 0
            for i, marker in ipairs(SYS.MARKERS.LIST) do
                local text = tostring(marker.pos)
                if #text > length then length = #text end
            end
            reaper.ImGui_PushFont(ctx, GUI.fonts.arial.vertical, 12)
            for i = 1, length do
                header_height = select(2, reaper.ImGui_CalcTextSize(ctx, "1")) + header_height
            end
            reaper.ImGui_PopFont(ctx)
            reaper.ImGui_SetCursorPosY(ctx, pos_y + header_height)
            pos_y = reaper.ImGui_GetCursorPosY(ctx)
        end
        if reaper.ImGui_BeginTable(ctx, "table_matrix", column_count, reaper.ImGui_TableFlags_BordersInner(), table_width) then
            reaper.ImGui_TableSetupColumn(ctx, "", reaper.ImGui_TableColumnFlags_WidthFixed(), first_col_width)
            if tab_displayed == "Matrix" and SYS.MARKERS.COUNT > 0 then
                for _, marker in ipairs(SYS.MARKERS.LIST) do
                    reaper.ImGui_TableSetupColumn(ctx, tostring(marker.pos), reaper.ImGui_TableColumnFlags_WidthFixed(), 20)
                end
            end
            reaper.ImGui_TableNextRow(ctx)
            reaper.ImGui_TableSetColumnIndex(ctx, 0)
            --reaper.ImGui_Text(ctx, "")
            if tab_displayed == "Matrix" and SYS.MARKERS.COUNT > 0 then
                for i, marker in ipairs(SYS.MARKERS.LIST) do
                    reaper.ImGui_TableSetColumnIndex(ctx, i)
                    reaper.ImGui_PushStyleVarY(ctx, reaper.ImGui_StyleVar_ItemSpacing(), -5)
                    reaper.ImGui_PushFont(ctx, GUI.fonts.arial.vertical, 12)
                    local text = tostring(marker.pos)--[[:gsub("_{[%x%-]+}$", "")]]:reverse()
                    for t = 1, #text do
                        local displayed = text:sub(t, t)
                        local cur_x = reaper.ImGui_GetCursorPosX(ctx)
                        reaper.ImGui_PushFont(ctx, GUI.fonts.arial.classic, 12)
                        local default_x = reaper.ImGui_CalcTextSize(ctx, "0")
                        local max_x = default_x - reaper.ImGui_CalcTextSize(ctx, displayed)
                        reaper.ImGui_PopFont(ctx)
                        reaper.ImGui_SetCursorPosX(ctx, cur_x + max_x * 2)
                        reaper.ImGui_Text(ctx, displayed)
                        reaper.ImGui_SetCursorPosX(ctx, cur_x)
                    end
                    reaper.ImGui_PopFont(ctx)
                    reaper.ImGui_PopStyleVar(ctx)
                end
            end

            for i, group in ipairs(SYS.TRACKS.GROUPS) do
                reaper.ImGui_TableNextRow(ctx)
                reaper.ImGui_TableSetColumnIndex(ctx, 0)
                retval, group.selected = reaper.ImGui_Selectable(ctx, group.name.."##selectable"..group.guid, group.selected)

                if tab_displayed == "Matrix" then
                    for j, marker in ipairs(SYS.MARKERS.LIST) do
                        reaper.ImGui_TableSetColumnIndex(ctx, j)
                        local checked = reaper.GetSetMediaTrackInfo_String(group.track, "P_EXT:"..SYS.extname.."MATRIX_"..marker.guid, "", false)
                        local text = checked and " X" or ""
                        retcheck, checked = reaper.ImGui_Selectable(ctx, text.."##selectable_martrix_"..marker.guid..group.guid, checked)
                        if retcheck then
                            if checked then
                                reaper.GetSetMediaTrackInfo_String(group.track, "P_EXT:"..SYS.extname.."MATRIX_"..marker.guid, "true", true)
                            else
                                reaper.GetSetMediaTrackInfo_String(group.track, "P_EXT:"..SYS.extname.."MATRIX_"..marker.guid, "", true)
                            end
                        end
                    end
                end
            end

            reaper.ImGui_EndTable(ctx)
        end

        if tab_displayed == "Files" then
            local group = nil
            if SYS.TRACKS.GROUPS then
                for i, cur_group in ipairs(SYS.TRACKS.GROUPS) do
                    if cur_group.selected then
                        group = cur_group
                        break
                    end
                end
            end
            reaper.ImGui_SetCursorPosX(ctx, tabs_x)
            reaper.ImGui_SetCursorPosY(ctx, pos_y)
            if group then
                reaper.ImGui_Text(ctx, group.name.." is currently selected track group.")
            else
                reaper.ImGui_TextWrapped(ctx, "Files in group, all files can be selected and modified from here.")
            end
        end
    end

    reaper.ImGui_EndGroup(ctx) -- TABLE

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
