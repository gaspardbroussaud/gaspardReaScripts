--@description Complete selection
--@author gaspard
--@version 0.1.10b
--@changelog
--  - GaspaReaLauncher GUI style (icon top bar, floating settings panel)
--@about
--  ### Complete selection
--  - A simple and quick selction tool for tracks, regions, markers, items (may add others later).

-- gaspard libraries: GUI style and GUI system (icon buttons)
GUI_STYLE = dofile(reaper.GetResourcePath() .. "/Scripts/Gaspard ReaScripts/Libraries/GUI_STYLE.lua")
GUI_SYS = dofile(reaper.GetResourcePath() .. "/Scripts/Gaspard ReaScripts/Libraries/GUI_SYS.lua")

-- Toggle button state in Reaper
function SetButtonState(set)
    local _, name, sec, cmd, _, _, _ = reaper.get_action_context()
    action_name = string.match(name, "gaspard_(.-)%.lua")
    reaper.SetToggleCommandState(sec, cmd, set or 0)
    reaper.RefreshToolbar2(sec, cmd)
end

-- Get script version with ReaPack (fallback: @version of this file)
function GetScriptVersion()
    local script_path = select(2, reaper.get_action_context())
    if reaper.ReaPack_GetOwner then
        local pkg = reaper.ReaPack_GetOwner(script_path)
        if pkg then
            local pkg_version = tostring(select(7, reaper.ReaPack_GetEntryInfo(pkg)))
            reaper.ReaPack_FreeEntry(pkg)
            if pkg_version ~= "" and pkg_version ~= "nil" then return pkg_version end
        end
    end
    local file = io.open(script_path, "r")
    if file then
        local header = file:read(1024) or ""
        file:close()
        local file_version = header:match("@version%s+([%w%.]+)")
        if file_version then return file_version end
    end
    return "1.0.0"
end

-- Init system variables
function InitSystemVariables()
    local json_file_path = reaper.GetResourcePath().."/Scripts/Gaspard ReaScripts/JSON"
    package.path = package.path .. ";" .. json_file_path .. "/?.lua"
    gson = require("json_utilities_lib")

    settings_path = debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]]..'/gaspard_'..action_name..'_settings.json'
    Settings = {
        order = {"show_items", "show_tracks", "show_markers", "show_regions", "tree_start_open"},
        show_items = {
            value = false,
            name = "Show items",
            description = "Toggle show items in GUI."
        },
        show_tracks = {
            value = false,
            name = "Show tracks",
            description = "Toggle show tracks in GUI."
        },
        show_markers = {
            value = false,
            name = "Show markers",
            description = "Toggle show markers in GUI."
        },
        show_regions = {
            value = false,
            name = "Show regions",
            description = "Toggle show regions in GUI."
        },
        tree_start_open = {
            value = false,
            name = "Trees open on start",
            description = "Trees for userdata types start opened on script launch."
        }
    }
    Settings = gson.LoadJSON(settings_path, Settings)
end

-- All initial variable for script and GUI
function InitialVariables()
    InitSystemVariables()
    version = GetScriptVersion()
    og_window_width = 600
    og_window_height = 500
    min_width, min_height = 450, 300
    window_width = og_window_width
    window_height = og_window_height
    window_x, window_y = 0, 0
    topbar_height = 30
    font_size = 16
    icon_size = 22
    small_font_size = font_size * 0.75
    show_settings = false
    window_name = "COMPLETE SELECTION"
    project_name = reaper.GetProjectName(0)
    project_path = reaper.GetProjectPath()
    project_id, _ = reaper.EnumProjects(-1)
    no_scrollbar_flags = reaper.ImGui_WindowFlags_NoScrollWithMouse() | reaper.ImGui_WindowFlags_NoScrollbar()
    global_datas = {}
    show_items = Settings.show_items.value
    show_tracks = Settings.show_tracks.value
    show_markers = Settings.show_markers.value
    show_regions = Settings.show_regions.value
    if show_items or show_tracks or show_markers or show_regions then GetUserdatas() end
    last_changed = nil
end

-- GUI Initialize function
function Gui_Init()
    InitialVariables()
    ctx = reaper.ImGui_CreateContext('random_play_context')
    font = reaper.ImGui_CreateFontFromFile(GUI_STYLE.FONTS.ARIAL.CLASSIC)
    italic_font = reaper.ImGui_CreateFontFromFile(GUI_STYLE.FONTS.ARIAL.CLASSIC, 0, reaper.ImGui_FontFlags_Italic())
    icon_font = reaper.ImGui_CreateFontFromFile(GUI_STYLE.FONTS.ICONS)
    reaper.ImGui_Attach(ctx, font)
    reaper.ImGui_Attach(ctx, italic_font)
    reaper.ImGui_Attach(ctx, icon_font)
end

-- GUI Top Bar (GaspaReaLauncher style)
function Gui_TopBar()
    reaper.ImGui_BeginGroup(ctx)
    -- Name and version
    reaper.ImGui_Text(ctx, window_name)
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_PushFont(ctx, italic_font, font_size * 0.75)
    reaper.ImGui_Text(ctx, "v" .. version)
    reaper.ImGui_PopFont(ctx)

    -- Icon buttons (right to left)
    local menu = {}
    table.insert(menu, {icon = 'QUIT', hint = 'Close', font = icon_font, size = icon_size, right_click = false})
    table.insert(menu, {icon = 'GEAR', hint = 'Settings', font = icon_font, size = icon_size, right_click = false})
    local rv, button = GUI_SYS.IconButtonRight(ctx, menu, window_width)
    if rv then
        if button == 'QUIT' then
            open = false
        elseif button == 'GEAR' then
            show_settings = not show_settings
        end
    end
    reaper.ImGui_EndGroup(ctx)
end

-- Gui Elements
function Gui_Elements()
    -- Set child section size (can use PushItemWidth for items without this setting) and center in window_width
    local child_width = window_width - 20
    local _, avail_y = reaper.ImGui_GetContentRegionAvail(ctx)
    local child_height = avail_y - 10
    reaper.ImGui_Indent(ctx, 2) -- 10px margin without SetCursorPos (needs no trailing item)
    if reaper.ImGui_BeginChild(ctx, "child_all_elements", child_width, child_height, reaper.ImGui_ChildFlags_Borders(), no_scrollbar_flags) then
        local inner_child_width = child_width - 15
        if reaper.ImGui_BeginChild(ctx, "child_target_settings", inner_child_width, 24, reaper.ImGui_ChildFlags_None(), no_scrollbar_flags) then
            reaper.ImGui_SetCursorPosX(ctx, -30)
            reaper.ImGui_Checkbox(ctx, "##checkbox_empty_dummy", true)
            reaper.ImGui_SameLine(ctx)

            reaper.ImGui_Text(ctx, "Items:")
            reaper.ImGui_SameLine(ctx)
            changed, show_items = reaper.ImGui_Checkbox(ctx, "##checkbox_show_items", show_items)
            if changed then one_changed = true end

            reaper.ImGui_SameLine(ctx)
            reaper.ImGui_Dummy(ctx, 1, 1)
            reaper.ImGui_SameLine(ctx)

            reaper.ImGui_Text(ctx, "Tracks:")
            reaper.ImGui_SameLine(ctx)
            changed, show_tracks = reaper.ImGui_Checkbox(ctx, "##checkbox_show_tracks", show_tracks)
            if changed then one_changed = true end

            reaper.ImGui_SameLine(ctx)
            reaper.ImGui_Dummy(ctx, 1, 1)
            reaper.ImGui_SameLine(ctx)

            reaper.ImGui_Text(ctx, "Markers:")
            reaper.ImGui_SameLine(ctx)
            changed, show_markers = reaper.ImGui_Checkbox(ctx, "##checkbox_show_markers", show_markers)
            if changed then one_changed = true end

            reaper.ImGui_SameLine(ctx)
            reaper.ImGui_Dummy(ctx, 1, 1)
            reaper.ImGui_SameLine(ctx)

            reaper.ImGui_Text(ctx, "Regions:")
            reaper.ImGui_SameLine(ctx)
            changed, show_regions = reaper.ImGui_Checkbox(ctx, "##checkbox_show_regions", show_regions)
            if changed then one_changed = true end

            reaper.ImGui_SameLine(ctx)
            reaper.ImGui_Dummy(ctx, 1, 1)
            reaper.ImGui_SameLine(ctx)

            reaper.ImGui_SetCursorPosX(ctx, window_width - 110)
            if reaper.ImGui_Button(ctx, "Refresh", 70) then GetUserdatas() end

            if one_changed then
                GetUserdatas()
                one_changed = false
            end

            reaper.ImGui_EndChild(ctx)
        end

        if reaper.ImGui_BeginChild(ctx, "child_replace_texts", inner_child_width, 100, reaper.ImGui_ChildFlags_None(), no_scrollbar_flags) then
            reaper.ImGui_Text(ctx, "Search:")
            reaper.ImGui_SameLine(ctx)
            reaper.ImGui_PushItemWidth(ctx, -1)
            changed, input_search = reaper.ImGui_InputTextMultiline(ctx, "##inputtext_search", input_search, nil, 100)
            reaper.ImGui_PopItemWidth(ctx)
            if changed then
                GetUserdatas()
                input_one_changed = true
            end

            reaper.ImGui_EndChild(ctx)
        end

        reaper.ImGui_Dummy(ctx, 1, 1)
        reaper.ImGui_Separator(ctx)
        reaper.ImGui_Dummy(ctx, 1, 1)

        if reaper.ImGui_BeginChild(ctx, "child_preview_replace", inner_child_width, child_height - 24 - 124 - 15) then
            DisplayUserdata()

            reaper.ImGui_EndChild(ctx)
        end

        reaper.ImGui_EndChild(ctx)
    end
    reaper.ImGui_Unindent(ctx, 2)
end

-- Settings panel (GaspaReaLauncher style: under top bar, right aligned, changes saved immediately)
function Gui_Settings()
    local settings_flags = reaper.ImGui_WindowFlags_NoCollapse() | reaper.ImGui_WindowFlags_NoScrollbar() | reaper.ImGui_WindowFlags_NoResize()
        | reaper.ImGui_WindowFlags_TopMost() | reaper.ImGui_WindowFlags_NoDecoration() | reaper.ImGui_WindowFlags_AlwaysAutoResize()
    reaper.ImGui_SetNextWindowPos(ctx, window_x + window_width - 8, window_y + topbar_height + 5, reaper.ImGui_Cond_Always(), 1, 0)
    local settings_visible = reaper.ImGui_Begin(ctx, '##settings_window', true, settings_flags)
    if not settings_visible then
        show_settings = false
        return
    end

    reaper.ImGui_Text(ctx, "SETTINGS")
    reaper.ImGui_Separator(ctx)

    local one_changed = false
    for _, key in ipairs(Settings.order) do
        local setting = Settings[key]
        if setting and type(setting.value) == "boolean" then
            local changed
            changed, setting.value = reaper.ImGui_Checkbox(ctx, setting.name .. "##setting_" .. key, setting.value)
            if changed then one_changed = true end
            reaper.ImGui_SetItemTooltip(ctx, setting.description)
        end
    end
    if one_changed then gson.SaveJSON(settings_path, Settings) end

    reaper.ImGui_End(ctx)
end

-- GUI function for all elements
function Gui_Loop()
    Gui_PushTheme()
    -- Window Settings
    local window_flags = reaper.ImGui_WindowFlags_NoCollapse() | reaper.ImGui_WindowFlags_NoTitleBar() | reaper.ImGui_WindowFlags_NoScrollWithMouse() | reaper.ImGui_WindowFlags_NoScrollbar()
    reaper.ImGui_SetNextWindowSize(ctx, window_width, window_height, reaper.ImGui_Cond_Once())
    reaper.ImGui_SetNextWindowSizeConstraints(ctx, min_width, min_height, math.huge, math.huge)
    -- Font
    reaper.ImGui_PushFont(ctx, font, font_size)
    -- Begin
    visible, open = reaper.ImGui_Begin(ctx, window_name, true, window_flags)
    window_x, window_y = reaper.ImGui_GetWindowPos(ctx)
    window_width, window_height = reaper.ImGui_GetWindowSize(ctx)

    current_time = reaper.ImGui_GetTime(ctx)
    if ProjectChange() then GetUserdatas() end
    ctrl_a_key = false
    if reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_Escape()) then
        ClearUserdataSelection()
    elseif reaper.ImGui_IsKeyDown(ctx, reaper.ImGui_Key_LeftCtrl()) and reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_A()) then
        ctrl_a_key = true
    end

    if visible then
        -- Top bar elements
        Gui_TopBar()

        -- Settings window
        if show_settings then Gui_Settings() end

        -- All Gui Elements
        Gui_Elements()

        reaper.ImGui_End(ctx)
    end

    reaper.ImGui_PopFont(ctx)
    Gui_PopTheme()
    if open then
      reaper.defer(Gui_Loop)
    end
end

-- Push all GUI style settings
function Gui_PushTheme()
    for i = 1, #GUI_STYLE.VARS do
        reaper.ImGui_PushStyleVar(ctx, GUI_STYLE.VARS[i].var, GUI_STYLE.VARS[i].value)
    end
    for i = 1, #GUI_STYLE.COLORS do
        reaper.ImGui_PushStyleColor(ctx, GUI_STYLE.COLORS[i].col, GUI_STYLE.COLORS[i].value)
    end
end

-- Pop all GUI style settings
function Gui_PopTheme()
    reaper.ImGui_PopStyleVar(ctx, #GUI_STYLE.VARS)
    reaper.ImGui_PopStyleColor(ctx, #GUI_STYLE.COLORS)
end

---------------------------------------------------

-- Check current focused project
function ProjectChange()
    if project_name ~= reaper.GetProjectName(0) or project_path ~= reaper.GetProjectPath() then
        project_name = reaper.GetProjectName(0)
        project_path = reaper.GetProjectPath()
        return true
    else
        return false
    end
end

-- Get all items from project in table
function GetItemsFromProject()
    local items = {}
    if show_items then
        local item_count = reaper.CountMediaItems(0)
        if item_count > 0 then
            for i = 0, item_count - 1 do
                local item_id = reaper.GetMediaItem(0, i)
                local take = reaper.GetTake(item_id, 0)
                local item_name = ""
                if take then
                    _, item_name = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
                else
                    _, item_name = reaper.GetSetMediaItemInfo_String(item_id, "P_NOTES", "", false)
                end
                local selected = reaper.IsMediaItemSelected(item_id)
                table.insert(items, { id = item_id, name = item_name, selected = selected })
            end
        else
            return nil
        end
    else
        return nil
    end
    return items
end

-- Get all tracks from project in table
function GetTracksFromProject()
    local tracks = {}
    if show_tracks then
        local track_count = reaper.CountTracks(0)
        if track_count > 0 then
            for i = 0, track_count - 1 do
                local track_id = reaper.GetTrack(0, i)
                local _, track_name = reaper.GetTrackName(track_id)
                if tostring(track_name):match("^Track %d+$") then track_name = "" end
                local selected = reaper.IsTrackSelected(track_id)
                table.insert(tracks, { id = track_id, name = track_name, selected = selected })
            end
        else
            return nil
        end
    else
        return nil
    end
    return tracks
end

-- Get all markers from project in table
function GetMarkersRegionsFromProject()
    local markers = {}
    local regions = {}
    if show_markers or show_regions then
        local _, marker_count, region_count = reaper.CountProjectMarkers(0)
        for i = 0, marker_count + region_count - 1 do
            local _, isrgn, pos, rgnend, name, idx = reaper.EnumProjectMarkers2(0, i)
            if isrgn then
                if show_regions then table.insert(regions, { pos = pos, rgnend = rgnend, id = idx, name = name, selected = false }) end
            else
                if show_markers then table.insert(markers, {  pos = pos, rgnend = rgnend, id = idx, name = name, selected = false }) end
            end
        end
    end
    if #markers <= 0 then markers = nil end
    if #regions <= 0 then regions = nil end
    return markers, regions
end

-- Get all userdatas for all types
function GetUserdatas()
    local items = {display = "Items", show = show_items, data = GetItemsFromProject()}
    local tracks = {display = "Tracks", show = show_tracks, data = GetTracksFromProject()}
    local table_markers, table_regions = GetMarkersRegionsFromProject()
    local markers = {display = "Markers", show = show_markers, data = table_markers}
    local regions = {display = "Regions", show = show_regions, data = table_regions}
    local order = {"items", "tracks", "markers", "regions"}
    global_datas = {order = order, items = items, tracks = tracks, markers = markers, regions = regions}
end

-- Check data to find input
function IsInputFindInName(name, search)
    name = name:gsub("([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1")
    for line in search:gmatch("([^\n]+)") do
        line = line:gsub("([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1")
        if name:find(line, 1, true) then
            return true
        end
    end
    return false
end

-- Display found and renamed Reaper userdata
function DisplayUserdata()
    if global_datas.order then
        local tree_flags = reaper.ImGui_TreeNodeFlags_SpanAllColumns() | reaper.ImGui_TreeNodeFlags_Framed()
        if Settings.tree_start_open.value then tree_flags = tree_flags | reaper.ImGui_TreeNodeFlags_DefaultOpen() end
        local selection_index = 0
        for index, key in ipairs(global_datas.order) do
            if global_datas[key]["data"] then
                if reaper.ImGui_TreeNode(ctx, global_datas[key]["display"].."##index"..tostring(index), tree_flags) then
                    for _, userdata in pairs(global_datas[key]["data"]) do
                        local input_found = IsInputFindInName(userdata.name, input_search)
                        local show_userdata = true
                        if not input_found and input_search ~= "" then show_userdata = false end
                        if show_userdata then
                            local label = "##selectable"..key..tostring(userdata.id)..userdata.name
                            if ctrl_a_key then userdata.selected = true end
                            changed, userdata.selected = reaper.ImGui_Selectable(ctx, userdata.name..label, userdata.selected, reaper.ImGui_SelectableFlags_SpanAllColumns())
                            if changed then
                                -- Get key press Shift
                                local shift = reaper.ImGui_IsKeyDown(ctx, reaper.ImGui_Mod_Shift())
                                if shift and last_changed and userdata.selected and last_changed.userdata ~= userdata then
                                    local current_changed = { userdata = userdata, index = selection_index }
                                    SelectFromOneToTheOther(last_changed, current_changed)
                                end

                                if key == "items" then reaper.SetMediaItemSelected(userdata.id, userdata.selected)
                                elseif key == "tracks" then reaper.SetTrackSelected(userdata.id, userdata.selected) end
                                reaper.UpdateArrange()
                                if userdata.selected then
                                    last_changed = { userdata = userdata, index = selection_index }
                                else
                                    last_changed = nil
                                end
                            end
                        end
                        selection_index = selection_index + 1
                    end
                    reaper.ImGui_TreePop(ctx)
                end
            end
        end
    end
end

function SelectFromOneToTheOther(one, other)
    if global_datas.order then
        local first = one
        local last = other
        if one.index > other.index then
            first = other
            last = one
        end
        local can_select = false
        for _, key in ipairs(global_datas.order) do
            if global_datas[key]["data"] then
                for _, userdata in pairs(global_datas[key]["data"]) do
                    local input_found = IsInputFindInName(userdata.name, input_search)
                    local show_userdata = true
                    if not input_found and input_search ~= "" then show_userdata = false end
                    if show_userdata then
                        if userdata == first.userdata then
                            can_select = true
                        end

                        if can_select then
                            userdata.selected = true
                            if key == "items" then reaper.SetMediaItemSelected(userdata.id, userdata.selected)
                            elseif key == "tracks" then reaper.SetTrackSelected(userdata.id, userdata.selected) end
                        end

                        if userdata == last.userdata then
                            can_select = false
                        end
                    end
                end
            end
        end
        reaper.UpdateArrange()
    end
end

-- Clear data selection in GUI and project
function ClearUserdataSelection()
    if global_datas.order then
        for _, key in ipairs(global_datas.order) do
            if global_datas[key]["data"] then
                for _, userdata in pairs(global_datas[key]["data"]) do
                    userdata.selected = false
                    if key == "items" then reaper.SetMediaItemSelected(userdata.id, userdata.selected)
                    elseif key == "tracks" then reaper.SetTrackSelected(userdata.id, userdata.selected) end
                end
            end
        end
        reaper.UpdateArrange()
    end
end

-- Main script execution
SetButtonState(1)
Gui_Init()
Gui_Loop()
reaper.atexit(SetButtonState)
