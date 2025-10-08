--@noindex
--@description Layer manipulator GUI
--@author gaspard

local GUI = {}

-- Window variables
local window_name = "LAYER MANIPULATOR"
local window_x, window_y
local window_width, window_height = 600, 350
local min_width, min_height, max_width, max_height = 300, 150, 1200, 600
local popup_x, popup_y = 0, 0
local index_popup = -1
local no_scrollbar_flags = reaper.ImGui_WindowFlags_NoScrollWithMouse() | reaper.ImGui_WindowFlags_NoScrollbar()

-- Get GUI style from file
local GUI_STYLE = dofile(reaper.GetResourcePath() .. "/Scripts/Gaspard ReaScripts/Libraries/GUI_STYLE.lua")
local GUI_SYS = dofile(reaper.GetResourcePath() .. "/Scripts/Gaspard ReaScripts/Libraries/GUI_SYS.lua")

local default_font_size = 16

-- ImGui Init
ctx = reaper.ImGui_CreateContext('layer_manipulator_context')
GUI.fonts = {}
GUI.fonts.arial = {}
GUI.fonts.arial.classic = reaper.ImGui_CreateFontFromFile(GUI_STYLE.FONTS.ARIAL.CLASSIC)
GUI.fonts.arial.vertical = reaper.ImGui_CreateFontFromFile(GUI_STYLE.FONTS.ARIAL.VERTICAL)
GUI.fonts.arial.italic = reaper.ImGui_CreateFontFromFile(GUI_STYLE.FONTS.ARIAL.CLASSIC, 0, reaper.ImGui_FontFlags_Italic())
GUI.fonts.icons = reaper.ImGui_CreateFontFromFile(GUI_STYLE.FONTS.ICONS)
GUI.icon_size = {w = 22, h = 22}
reaper.ImGui_Attach(ctx, GUI.fonts.arial.classic)
reaper.ImGui_Attach(ctx, GUI.fonts.arial.vertical)
reaper.ImGui_Attach(ctx, GUI.fonts.arial.italic)
reaper.ImGui_Attach(ctx, GUI.fonts.icons)

-- Variables
local checked_state = nil

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
    local w, h = reaper.ImGui_CalcTextSize(ctx, "v" .. version)
    reaper.ImGui_SetCursorPosX(ctx, window_width - w - reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding()) * 2)
    reaper.ImGui_SetCursorPosY(ctx, window_height - h - select(2, reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding())) * 2)
    reaper.ImGui_Text(ctx, "v" .. version)
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
    reaper.ImGui_Text(ctx, "v" .. version)
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
    local tabs_y = reaper.ImGui_GetCursorPosY(ctx) + select(2, reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding())) * 4
        + select(2, reaper.ImGui_CalcTextSize(ctx, "A"))
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
    local test = true
    if SYS.TRACKS.GROUPS or test then
        local column_count = tab_displayed == "Matrix" and SYS.MARKERS.COUNT + 1 or 1
        local first_col_width = tabs_offset_width - reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding()) * 2
        local table_width = tab_displayed == "Matrix" and -1 or first_col_width
        pos_y = reaper.ImGui_GetCursorPosY(ctx)
        if tab_displayed == "Files" and SYS.MARKERS.COUNT > 0 then
            local header_height = 0
            local length = 0
            for i, marker in ipairs(SYS.MARKERS.LIST) do
                local text = tostring(math.floor(marker.pos) + (math.floor(100 * (marker.pos - math.floor(marker.pos))) / 100))
                --local text = tostring(position)
                if #text > length then length = #text end
            end
            reaper.ImGui_PushFont(ctx, GUI.fonts.arial.vertical, 12)
            for i = 1, length do
                header_height = select(2, reaper.ImGui_CalcTextSize(ctx, "1")) + header_height - 5
            end
            reaper.ImGui_PopFont(ctx)
            reaper.ImGui_SetCursorPosY(ctx, pos_y + header_height + 5)
            pos_y = reaper.ImGui_GetCursorPosY(ctx)
        end
        if SYS.TRACKS.GROUPS then
            if reaper.ImGui_BeginTable(ctx, "table_matrix", column_count, reaper.ImGui_TableFlags_BordersInner(), table_width) then
                reaper.ImGui_TableSetupColumn(ctx, "", reaper.ImGui_TableColumnFlags_WidthFixed(), first_col_width)
                if tab_displayed == "Matrix" and SYS.MARKERS.COUNT > 0 then
                    for _, marker in ipairs(SYS.MARKERS.LIST) do
                        local position = math.floor(marker.pos) + (math.floor(100 * (marker.pos - math.floor(marker.pos))) / 100)
                        reaper.ImGui_TableSetupColumn(ctx, tostring(position), reaper.ImGui_TableColumnFlags_WidthFixed(), 20)
                    end
                end
                reaper.ImGui_TableNextRow(ctx)
                reaper.ImGui_TableSetColumnIndex(ctx, 0)
                if tab_displayed == "Matrix" and SYS.MARKERS.COUNT > 0 then
                    for i, marker in ipairs(SYS.MARKERS.LIST) do
                        reaper.ImGui_TableSetColumnIndex(ctx, i)
                        reaper.ImGui_PushStyleVarY(ctx, reaper.ImGui_StyleVar_ItemSpacing(), -5)
                        reaper.ImGui_PushFont(ctx, GUI.fonts.arial.vertical, 12)
                        local text = tostring(math.floor(marker.pos) + (math.floor(100 * (marker.pos - math.floor(marker.pos))) / 100)):reverse()
                        --local text = tostring(position)--[[:gsub("_{[%x%-]+}$", "")]]:reverse()
                        for t = 1, #text do
                            local displayed = text:sub(t, t)
                            local cur_x = reaper.ImGui_GetCursorPosX(ctx)
                            reaper.ImGui_PushFont(ctx, GUI.fonts.arial.classic, 12)
                            local default_x = reaper.ImGui_CalcTextSize(ctx, "0")
                            local max_x = reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing()) * 0.5 + default_x - reaper.ImGui_CalcTextSize(ctx, displayed)
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
                    retval, group.selected = reaper.ImGui_Selectable(ctx, group.name .. "##selectable" .. group.guid, group.selected)
                    if retval then
                        if group.selected then
                            for g, sub_group in ipairs(SYS.TRACKS.GROUPS) do
                                if i ~= g then
                                    sub_group.selected = false
                                    reaper.GetSetMediaTrackInfo_String(sub_group.track, "P_EXT:" .. SYS.extname .. "SELECTED", tostring(false), true)
                                end
                            end
                        end

                        reaper.GetSetMediaTrackInfo_String(group.track, "P_EXT:" .. SYS.extname .. "SELECTED", tostring(group.selected), true)
                    end

                    if tab_displayed == "Matrix" then
                        local draw_list = reaper.ImGui_GetForegroundDrawList(ctx)
                        local mouse_left_button = reaper.ImGui_IsMouseDown(ctx, reaper.ImGui_MouseButton_Left())
                        local mouse_left_drag = reaper.ImGui_IsMouseDragging(ctx, reaper.ImGui_MouseButton_Left())
                        if not mouse_left_drag and not mouse_left_button then checked_state = nil end
                        for j, marker in ipairs(SYS.MARKERS.LIST) do
                            reaper.ImGui_TableSetColumnIndex(ctx, j)

                            local x, y = reaper.ImGui_GetWindowPos(ctx)
                            x = x + reaper.ImGui_GetCursorPosX(ctx) - reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding())
                            y = y + reaper.ImGui_GetCursorPosY(ctx) - select(2, reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding()))

                            local prev_checked = reaper.GetSetMediaTrackInfo_String(group.track, "P_EXT:" .. SYS.extname .. "MATRIX_" .. marker.guid, "", false)
                            local retcheck = false
                            local checked = false

                            reaper.ImGui_Selectable(ctx, "##selectable_martrix_" .. marker.guid .. group.guid, prev_checked)

                            if reaper.ImGui_IsItemHovered(ctx, reaper.ImGui_HoveredFlags_AllowWhenBlockedByActiveItem()) then
                                if not mouse_left_drag and reaper.ImGui_IsMouseClicked(ctx, reaper.ImGui_MouseButton_Left()) then
                                    checked = not prev_checked
                                    retcheck = true
                                    checked_state = checked
                                elseif mouse_left_drag then
                                    if checked_state == nil then
                                        checked = checked_state ~= nil and checked_state or not prev_checked
                                        retcheck = true
                                    else
                                        if checked_state ~= nil and checked_state ~= prev_checked then
                                            checked = checked_state
                                            retcheck = true
                                        end
                                    end
                                end
                            end

                            local w, h = reaper.ImGui_GetItemRectSize(ctx)
                            reaper.ImGui_DrawList_AddRectFilled(draw_list, x, y, x + w, y + h, ((reaper.ImGui_GetStyleColor(ctx, reaper.ImGui_Col_Header()) >> 8) << 8)
                                | (0x30 & 0xFF))
                            if retcheck then
                                if checked then
                                    reaper.GetSetMediaTrackInfo_String(group.track, "P_EXT:" .. SYS.extname .. "MATRIX_" .. marker.guid, "true", true)

                                    local random_file = SYS.TRACKS.GetRandomFileFromGroup(group)
                                    if random_file then
                                        reaper.PreventUIRefresh(1)

                                        local edit_cursor_pos = reaper.GetCursorPosition()

                                        local sel_tracks = {}
                                        for t = 1, reaper.CountSelectedTracks(-1) do
                                            table.insert(sel_tracks, reaper.GetSelectedTrack(-1, t - 1))
                                        end
                                        reaper.SetOnlyTrackSelected(group.track)

                                        local sel_items = {}
                                        local item_count = reaper.CountSelectedMediaItems(-1)
                                        if item_count > 0 then
                                            for it = 1, item_count do
                                                table.insert(sel_items, reaper.GetSelectedMediaItem(-1, it - 1))
                                            end
                                            for it, item in ipairs(sel_items) do
                                                reaper.SetMediaItemSelected(item, false)
                                            end
                                        end

                                        reaper.InsertMedia(random_file.path, 0)
                                        local new_item = reaper.GetSelectedMediaItem(-1, 0)

                                        reaper.SetMediaItemPosition(new_item, marker.pos, false)

                                        reaper.SetTrackSelected(group.track, false)
                                        for t, track in ipairs(sel_tracks) do
                                            reaper.SetTrackSelected(track, true)
                                        end

                                        reaper.SetMediaItemSelected(new_item, false)
                                        for it, item in ipairs(sel_items) do
                                            reaper.SetMediaItemSelected(item, true)
                                        end

                                        reaper.SetEditCurPos(edit_cursor_pos, false, false)

                                        reaper.PreventUIRefresh(-1)
                                        reaper.UpdateArrange()
                                    else
                                        reaper.GetSetMediaTrackInfo_String(group.track, "P_EXT:" .. SYS.extname .. "MATRIX_" .. marker.guid, "", true)
                                    end
                                else
                                    reaper.GetSetMediaTrackInfo_String(group.track, "P_EXT:" .. SYS.extname .. "MATRIX_" .. marker.guid, "", true)

                                    local track_item_count = reaper.CountTrackMediaItems(group.track)
                                    if track_item_count > 0 then
                                        reaper.PreventUIRefresh(1)

                                        for it = 1, track_item_count do
                                            local item = reaper.GetTrackMediaItem(group.track, it - 1)
                                            local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
                                            if pos == marker.pos then
                                                reaper.DeleteTrackMediaItem(group.track, item)
                                                break
                                            end
                                        end

                                        reaper.PreventUIRefresh(-1)
                                        reaper.UpdateArrange()
                                    end
                                end
                            end
                        end
                    end
                end

                reaper.ImGui_EndTable(ctx)
            end
        else
            reaper.ImGui_SetCursorPosX(ctx, tabs_x)
            reaper.ImGui_SetCursorPosY(ctx, tabs_y)
            reaper.ImGui_TextWrapped(ctx, "Please select a group folder track or create a group in Files tab.")
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
            reaper.ImGui_SetCursorPosY(ctx, tabs_y)
            if reaper.ImGui_BeginChild(ctx, "child_files") then
                if group then
                    reaper.ImGui_Text(ctx, '"' .. group.name .. '"' .. " is the currently selected track group.")

                    reaper.ImGui_Separator(ctx)

                    if group.files then
                        if reaper.ImGui_BeginListBox(ctx, "##listbox_files") then
                            for i, file in ipairs(group.files) do
                                reaper.ImGui_Selectable(ctx, file.name .. "##" .. file.path, index_popup == i)
                                local hovered = reaper.ImGui_IsItemHovered(ctx)

                                reaper.ImGui_SetItemTooltip(ctx, file.path)

                                if hovered and reaper.ImGui_IsMouseClicked(ctx, reaper.ImGui_MouseButton_Right()) then
                                    index_popup = i
                                    popup_x, popup_y = reaper.ImGui_GetMousePos(ctx)
                                    reaper.ImGui_OpenPopup(ctx, "popup_file_context")
                                end
                            end

                            local popup_w = reaper.ImGui_CalcTextSize(ctx, "Remove file") + reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding()) * 2
                            local popup_h = select(2, reaper.ImGui_CalcTextSize(ctx, "Remove file"))
                                + select(2, reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding())) * 2
                            reaper.ImGui_SetNextWindowSize(ctx, popup_w, popup_h)
                            reaper.ImGui_SetNextWindowPos(ctx, popup_x, popup_y)
                            if reaper.ImGui_BeginPopup(ctx, "popup_file_context") then
                                if reaper.ImGui_Selectable(ctx, "Remove file") then
                                    SYS.TRACKS.RemoveFileFromGroup(group, index_popup)
                                    reaper.ImGui_CloseCurrentPopup(ctx)
                                    index_popup = -1
                                end

                                reaper.ImGui_EndPopup(ctx)
                            end
                            if not reaper.ImGui_IsPopupOpen(ctx, "popup_file_context") then index_popup = -1 end

                            reaper.ImGui_EndListBox(ctx)
                        end
                    end
                else
                    if SYS.TRACKS.GROUPS then
                        reaper.ImGui_TextWrapped(ctx, "No track group selected.")
                        if reaper.ImGui_Button(ctx, "Add new group track") then
                            local insert_index = reaper.GetMediaTrackInfo_Value(SYS.TRACKS.GROUPS[#SYS.TRACKS.GROUPS].track, "IP_TRACKNUMBER") + 1

                            reaper.PreventUIRefresh(1)

                            reaper.InsertTrackAtIndex(insert_index, 0)
                            reaper.SetMediaTrackInfo_Value(SYS.TRACKS.GROUPS[#SYS.TRACKS.GROUPS].track, "I_FOLDERDEPTH", 0)

                            local insert_track = reaper.GetTrack(-1, insert_index - 1)
                            reaper.SetMediaTrackInfo_Value(insert_track, "I_FOLDERDEPTH", reaper.GetTrackDepth(SYS.TRACKS.PARENT) - 1)
                            reaper.GetSetMediaTrackInfo_String(insert_track, "P_EXT:" .. SYS.extname .. "PARENT_GUID", reaper.GetTrackGUID(SYS.TRACKS.PARENT), true)

                            reaper.PreventUIRefresh(-1)
                            reaper.UpdateArrange()
                        end
                    else
                        local sel_track_count = reaper.CountSelectedTracks(-1)
                        local first_selected = sel_track_count > 0 and reaper.GetSelectedTrack(-1, 0) or nil

                        local text = sel_track_count > 0 and string.format("Selected track: %s.", select(2, reaper.GetTrackName(first_selected))) or "No track selected."
                        reaper.ImGui_TextWrapped(ctx, text)

                        if sel_track_count <= 0 then reaper.ImGui_BeginDisabled(ctx) end
                        if reaper.ImGui_Button(ctx, "Make selected track into group parent track") then
                            SYS.TRACKS.MakeGroupParentTrack(first_selected)
                            --[[local parent_GUID = reaper.GetTrackGUID(first_selected)
                            for t = 1, #sel_track_count do
                                reaper.GetSetMediaTrackInfo_String(reaper.GetSelectedTrack(-1, t - 1), "P_EXT:"..SYS.extname.."PARENT_GUID", parent_GUID, true)
                            end]]
                        end
                        if sel_track_count <= 0 then reaper.ImGui_EndDisabled(ctx) end
                    end
                end

                reaper.ImGui_EndChild(ctx)
            end

            if reaper.ImGui_BeginDragDropTarget(ctx) and SYS.TRACKS.GROUPS then
                local retval, data_count = reaper.ImGui_AcceptDragDropPayloadFiles(ctx)
                if retval then
                    local max_data = data_count - 1
                    for i = 0, max_data do
                        local _, filepath = reaper.ImGui_GetDragDropPayloadFile(ctx, max_data - i)
                        if reaper.file_exists(filepath) and group then
                            SYS.TRACKS.InsertFileInGroup(group.track, filepath)
                        end
                    end
                end
                reaper.ImGui_EndDragDropTarget(ctx)
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

        if KEYS.CheckShortcutPressed(shortcut) then open = false end

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
