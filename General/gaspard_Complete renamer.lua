--@description Complete renamer
--@author gaspard
--@version 0.0.3b
--@changelog
--  - Add only show replaced
--  - !!! ATTENTION !!! -> Please delete the .json file at script path before launching for the first time the 0.0.3b
--@about
--  ### Complete renamer
--  - A simple and quick renamer for tracks, regions, markers, items (may add others later).

-- Toggle button state in Reaper
function SetButtonState(set)
    local _, name, sec, cmd, _, _, _ = reaper.get_action_context()
    action_name = string.match(name, "gaspard_(.-)%.lua")
    reaper.SetToggleCommandState(sec, cmd, set or 0)
    reaper.RefreshToolbar2(sec, cmd)
end

-- Get GUI style from file
function GetGuiStylesFromFile()
    local gui_style_settings_path = reaper.GetResourcePath().."/Scripts/Gaspard ReaScripts/GUI/GUI_Style_Settings.lua"
    local style = dofile(gui_style_settings_path)
    style_vars = style.vars
    style_colors = style.colors
end

-- Init system variables
function InitSystemVariables()
    local json_file_path = reaper.GetResourcePath().."/Scripts/Gaspard ReaScripts/JSON"
    package.path = package.path .. ";" .. json_file_path .. "/?.lua"
    gson = require("json_utilities_lib")

    settings_path = debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]]..'/gaspard_'..action_name..'_settings.json'
    Settings = {
        order = {"replace_items", "replace_tracks", "replace_markers", "replace_regions"},
        replace_items = {
            value = false,
            name = "Replace items",
            description = "Find and replace in item names."
        },
        replace_tracks = {
            value = false,
            name = "Replace tracks",
            description = "Find and replace in track names."
        },
        replace_markers = {
            value = false,
            name = "Replace markers",
            description = "Find and replace in marker names."
        },
        replace_regions = {
            value = false,
            name = "Replace regions",
            description = "Find and replace in region names."
        },
        selection_based = {
            value = false,
            name = "Selection based",
            description = "Apply name replacement to selected userdata only."
        },
        tree_start_open = {
            value = false,
            name = "Trees start open",
            description = "Trees for userdata types start opened on script launch."
        },
        only_show_replace = {
            value = false,
            name = "Show only matches",
            description = "Only show matches in userdata names of text input."
        }
    }
    Settings = gson.LoadJSON(settings_path, Settings)
end

-- All initial variable for script and GUI
function InitialVariables()
    InitSystemVariables()
    GetGuiStylesFromFile()
    version = "0.0.1"
    og_window_width = 600
    og_window_height = 500
    window_width = og_window_width
    window_height = og_window_height
    topbar_height = 30
    font_size = 16
    small_font_size = font_size * 0.75
    window_name = "COMPLETE RENAMER"
    project_name = reaper.GetProjectName(0)
    project_path = reaper.GetProjectPath()
    project_id, _ = reaper.EnumProjects(-1)
    no_scrollbar_flags = reaper.ImGui_WindowFlags_NoScrollWithMouse() | reaper.ImGui_WindowFlags_NoScrollbar()
    global_datas = {}
    if Settings.replace_items.value or Settings.replace_tracks.value or Settings.replace_markers.value or Settings.replace_regions.value then
        one_changed = true
    else
        one_changed = false
    end
    settings_one_changed = false
end

-- GUI Initialize function
function Gui_Init()
    InitialVariables()
    ctx = reaper.ImGui_CreateContext('random_play_context')
    font = reaper.ImGui_CreateFont('sans-serif', 16)
    small_font = reaper.ImGui_CreateFont('sans-serif', 16 * 0.75, reaper.ImGui_FontFlags_Italic())
    reaper.ImGui_Attach(ctx, font)
    reaper.ImGui_Attach(ctx, small_font)
end

-- GUI Top Bar
function Gui_TopBar()
    -- GUI Menu Bar
    if reaper.ImGui_BeginChild(ctx, "child_top_bar", window_width, 30, reaper.ImGui_ChildFlags_None(), no_scrollbar_flags) then
        reaper.ImGui_Text(ctx, window_name)

        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(), 5, 0)

        reaper.ImGui_SameLine(ctx)

        local w, _ = reaper.ImGui_CalcTextSize(ctx, "Settings X")
        reaper.ImGui_SetCursorPos(ctx, reaper.ImGui_GetWindowWidth(ctx) - w - 40, 0)

        if reaper.ImGui_BeginChild(ctx, "child_top_bar_buttons", w + 40, 22, reaper.ImGui_ChildFlags_None(), no_scrollbar_flags) then
            reaper.ImGui_Dummy(ctx, 3, 1)
            reaper.ImGui_SameLine(ctx)
            if reaper.ImGui_Button(ctx, 'Settings##settings_button') then
                show_settings = not show_settings
                if settings_one_changed then
                    gson.SaveJSON(settings_path, Settings)
                    settings_one_changed = false
                end
            end
            reaper.ImGui_SameLine(ctx)
            if reaper.ImGui_Button(ctx, 'X##quit_button') then
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
    -- Set child section size (can use PushItemWidth for items without this setting) and center in window_width
    local child_width = window_width - 20
    local child_height = window_height - topbar_height - small_font_size - 30
    reaper.ImGui_SetCursorPosX(ctx, 10)
    if reaper.ImGui_BeginChild(ctx, "child_all_elements", child_width, child_height, reaper.ImGui_ChildFlags_Border(), no_scrollbar_flags) then
        local inner_child_width = child_width - 15
        if reaper.ImGui_BeginChild(ctx, "child_target_settings", inner_child_width, 24, reaper.ImGui_ChildFlags_None(), no_scrollbar_flags) then
            reaper.ImGui_SetCursorPosX(ctx, -30)
            reaper.ImGui_Checkbox(ctx, "##checkbox_empty_dummy", true)
            reaper.ImGui_SameLine(ctx)

            reaper.ImGui_Text(ctx, "Items:")
            reaper.ImGui_SameLine(ctx)
            changed, Settings.replace_items.value = reaper.ImGui_Checkbox(ctx, "##checkbox_replace_items", Settings.replace_items.value)
            if changed then one_changed = true end

            reaper.ImGui_SameLine(ctx)
            reaper.ImGui_Dummy(ctx, 1, 1)
            reaper.ImGui_SameLine(ctx)

            reaper.ImGui_Text(ctx, "Tracks:")
            reaper.ImGui_SameLine(ctx)
            changed, Settings.replace_tracks.value = reaper.ImGui_Checkbox(ctx, "##checkbox_replace_tracks", Settings.replace_tracks.value)
            if changed then one_changed = true end

            reaper.ImGui_SameLine(ctx)
            reaper.ImGui_Dummy(ctx, 1, 1)
            reaper.ImGui_SameLine(ctx)

            reaper.ImGui_Text(ctx, "Markers:")
            reaper.ImGui_SameLine(ctx)
            changed, Settings.replace_markers.value = reaper.ImGui_Checkbox(ctx, "##checkbox_replace_markers", Settings.replace_markers.value)
            if changed then one_changed = true end

            reaper.ImGui_SameLine(ctx)
            reaper.ImGui_Dummy(ctx, 1, 1)
            reaper.ImGui_SameLine(ctx)

            reaper.ImGui_Text(ctx, "Regions:")
            reaper.ImGui_SameLine(ctx)
            changed, Settings.replace_regions.value = reaper.ImGui_Checkbox(ctx, "##checkbox_replace_regions", Settings.replace_regions.value)
            if changed then one_changed = true end

            reaper.ImGui_SameLine(ctx)
            reaper.ImGui_Dummy(ctx, 1, 1)
            reaper.ImGui_SameLine(ctx)

            reaper.ImGui_SetCursorPosX(ctx, window_width - 110)
            if reaper.ImGui_Button(ctx, "Refresh", 70) then
                one_changed = true
            end

            if one_changed then
                GetUserdatas()
                gson.SaveJSON(settings_path, Settings)
                one_changed = false
            end

            reaper.ImGui_EndChild(ctx)
        end

        if reaper.ImGui_BeginChild(ctx, "child_replace_texts", inner_child_width, 50, reaper.ImGui_ChildFlags_None(), no_scrollbar_flags) then
            reaper.ImGui_Text(ctx, "Search:")
            reaper.ImGui_SameLine(ctx)
            reaper.ImGui_PushItemWidth(ctx, -1)
            changed, input_find = reaper.ImGui_InputText(ctx, "##inputtext_find", input_find)
            reaper.ImGui_PopItemWidth(ctx)

            reaper.ImGui_Text(ctx, "Replace:")
            reaper.ImGui_SameLine(ctx)
            reaper.ImGui_PushItemWidth(ctx, -1)
            changed, input_replace = reaper.ImGui_InputText(ctx, "##inputtext_replace", input_replace)
            reaper.ImGui_PopItemWidth(ctx)

            reaper.ImGui_EndChild(ctx)
        end

        reaper.ImGui_Dummy(ctx, 1, 1)
        reaper.ImGui_Separator(ctx)
        reaper.ImGui_Dummy(ctx, 1, 1)

        if reaper.ImGui_BeginChild(ctx, "child_preview_replace", inner_child_width, child_height - 24 - 50 - 50 - 15) then
            DisplayUserdata()

            reaper.ImGui_EndChild(ctx)
        end

        local x, _ = reaper.ImGui_GetContentRegionAvail(ctx)
        local button_x = 100
        if not one_changed then disable = true
        else disable = false end
        if disable then reaper.ImGui_BeginDisabled(ctx) end
        reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + x - button_x)
        if reaper.ImGui_Button(ctx, "APPLY##apply_button", button_x) then
            ApplyReplacedNames()
        end
        if disable then reaper.ImGui_EndDisabled(ctx) end

        reaper.ImGui_EndChild(ctx)
    end
end

function Gui_Settings()
    -- Set Settings Window visibility and settings
    local settings_flags = reaper.ImGui_WindowFlags_NoCollapse() | reaper.ImGui_WindowFlags_NoScrollbar()
    local settings_width = og_window_width - 350
    local settings_height = og_window_height * 0.35
    reaper.ImGui_SetNextWindowSize(ctx, settings_width, settings_height, reaper.ImGui_Cond_Once())
    reaper.ImGui_SetNextWindowPos(ctx, window_x + (window_width - settings_width) * 0.5, window_y + 10, reaper.ImGui_Cond_Appearing())

    local settings_visible, settings_open  = reaper.ImGui_Begin(ctx, 'SETTINGS', true, settings_flags)
    if settings_visible then
        if reaper.ImGui_BeginChild(ctx, "child_settings_window", settings_width - 16, settings_height - 74, reaper.ImGui_ChildFlags_Border()) then
            reaper.ImGui_Text(ctx, Settings.selection_based.name..":")
            reaper.ImGui_SameLine(ctx)
            changed, Settings.selection_based.value = reaper.ImGui_Checkbox(ctx, "##checkbox_selection_based", Settings.selection_based.value)
            if changed then settings_one_changed = true end

            reaper.ImGui_Text(ctx, Settings.tree_start_open.name..":")
            reaper.ImGui_SameLine(ctx)
            changed, Settings.tree_start_open.value = reaper.ImGui_Checkbox(ctx, "##checkbox_tree_start_open", Settings.tree_start_open.value)
            if changed then settings_one_changed = true end

            reaper.ImGui_Text(ctx, Settings.only_show_replace.name..":")
            reaper.ImGui_SameLine(ctx)
            changed, Settings.only_show_replace.value = reaper.ImGui_Checkbox(ctx, "##checkbox_only_show_replace", Settings.only_show_replace.value)
            if changed then settings_one_changed = true end

            reaper.ImGui_EndChild(ctx)
        end

        reaper.ImGui_SetCursorPosX(ctx, settings_width - 80)
        reaper.ImGui_SetCursorPosY(ctx, settings_height - 35)
        if not settings_one_changed then disable = true
        else disable = false end
        if disable then reaper.ImGui_BeginDisabled(ctx) end
        if reaper.ImGui_Button(ctx, "Apply##settings_apply", 70) then
            gson.SaveJSON(settings_path, Settings)
            settings_one_changed = false
        end
        if disable then reaper.ImGui_EndDisabled(ctx) end

        reaper.ImGui_End(ctx)
    else
        show_settings = false
    end

    if not settings_open then
        if settings_one_changed then
            gson.SaveJSON(settings_path, Settings)
            settings_one_changed = false
        end
        show_settings = false
    end
end

-- Gui Version on bottom right
function Gui_Version()
    reaper.ImGui_PushFont(ctx, small_font)
    local w, h = reaper.ImGui_CalcTextSize(ctx, "v"..version)
    reaper.ImGui_SetCursorPosX(ctx, window_width - w - 10)
    reaper.ImGui_SetCursorPosY(ctx, window_height - h - 10)
    reaper.ImGui_Text(ctx, "v"..version)
    reaper.ImGui_PopFont(ctx)
end

-- GUI function for all elements
function Gui_Loop()
    Gui_PushTheme()
    -- Window Settings
    local window_flags = reaper.ImGui_WindowFlags_NoCollapse() | reaper.ImGui_WindowFlags_NoTitleBar() | reaper.ImGui_WindowFlags_NoScrollWithMouse() | reaper.ImGui_WindowFlags_NoScrollbar()
    reaper.ImGui_SetNextWindowSize(ctx, window_width, window_height, reaper.ImGui_Cond_Once())
    -- Font
    reaper.ImGui_PushFont(ctx, font)
    -- Begin
    visible, open = reaper.ImGui_Begin(ctx, window_name, true, window_flags)
    window_x, window_y = reaper.ImGui_GetWindowPos(ctx)
    window_width, window_height = reaper.ImGui_GetWindowSize(ctx)

    current_time = reaper.ImGui_GetTime(ctx)

    if visible then
        -- Top bar elements
        Gui_TopBar()

        -- Settings window
        if show_settings then Gui_Settings() end

        -- All Gui Elements
        Gui_Elements()

        -- Show script version on  bottom right
        Gui_Version()

        reaper.ImGui_End(ctx)
    end

    Gui_PopTheme()
    reaper.ImGui_PopFont(ctx)
    if open then
      reaper.defer(Gui_Loop)
    end
end

-- Push all GUI style settings
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

-- Pop all GUI style settings
function Gui_PopTheme()
    reaper.ImGui_PopStyleVar(ctx, #style_vars)
    reaper.ImGui_PopStyleColor(ctx, #style_colors)
end

---------------------------------------------------

-- Get all items from project in table
function GetItemsFromProject()
    local items = {}
    if Settings.replace_items.value then
        local item_count = reaper.CountMediaItems(0)
        for i = 0, item_count - 1 do
            local item_id = reaper.GetMediaItem(0, i)
            local _, item_name = reaper.GetSetMediaItemTakeInfo_String(reaper.GetTake(item_id, 0), "P_NAME", "", false)
            local selected = reaper.IsMediaItemSelected(item_id)
            table.insert(items, { id = item_id, name = item_name, selected = selected })
        end
    else
        return nil
    end
    return items
end

-- Get all tracks from project in table
function GetTracksFromProject()
    local tracks = {}
    if Settings.replace_tracks.value then
        local track_count = reaper.CountTracks(0)
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
    return tracks
end

-- Get all markers from project in table
function GetMarkersRegionsFromProject()
    local markers = {}
    local regions = {}
    if Settings.replace_markers.value or Settings.replace_regions.value then
        local _, marker_count, region_count = reaper.CountProjectMarkers(0)
        for i = 0, marker_count + region_count - 1 do
            local _, isrgn, pos, rgnend, name, idx = reaper.EnumProjectMarkers2(0, i)
            if isrgn then
                if Settings.replace_regions.value then table.insert(regions, { pos = pos, rgnend = rgnend, id = idx, name = name, selected = false }) end
            else
                if Settings.replace_markers.value then table.insert(markers, {  pos = pos, rgnend = rgnend, id = idx, name = name, selected = false }) end
            end
        end
    end
    if #markers <= 0 then markers = nil end
    if #regions <= 0 then regions = nil end
    return markers, regions
end

function GetUserdatas()
    local items = {display = "Items", show = Settings.replace_items.value, data = GetItemsFromProject()}
    local tracks = {display = "Tracks", show = Settings.replace_tracks.value, data = GetTracksFromProject()}
    local table_markers, table_regions = GetMarkersRegionsFromProject()
    local markers = {display = "Markers", show = Settings.replace_markers.value, data = table_markers}
    local regions = {display = "Regions", show = Settings.replace_regions.value, data = table_regions}
    local order = {"items", "tracks", "markers", "regions"}
    global_datas = {order = order, items = items, tracks = tracks, markers = markers, regions = regions}
end

-- Check data to find input
function IsInputFindInName(name, search)
    search = search:gsub("([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1")
    if name:match(search, 1, true) and search ~= "" then
        return true
    end
    return false
end

function GetReplacedName(name, pattern, replacement)
    pattern = pattern:gsub("([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1")
    name = name:gsub(pattern, replacement)
    return name
end

function ApplyReplacedNames()
    reaper.PreventUIRefresh(-1)
    reaper.Undo_BeginBlock()

    if global_datas.order then
        for _, key in ipairs(global_datas.order) do
            if global_datas[key]["data"] then
                for _, userdata in pairs(global_datas[key]["data"]) do
                    local can_apply = true
                    if Settings.selection_based.value and not userdata.selected then can_apply = false end
                    if IsInputFindInName(userdata.name, input_find) and can_apply then
                        userdata.name = GetReplacedName(userdata.name, input_find, input_replace)
                        if key == "items" then
                            reaper.GetSetMediaItemTakeInfo_String(reaper.GetTake(userdata.id, 0), "P_NAME", userdata.name, true)
                        elseif key == "tracks" then
                            reaper.GetSetMediaTrackInfo_String(userdata.id, "P_NAME", userdata.name, true)
                        elseif key == "markers" then
                            reaper.SetProjectMarker(userdata.id, false, userdata.pos, userdata.rgnend, userdata.name)
                        elseif key == "regions" then
                            reaper.SetProjectMarker(userdata.id, true, userdata.pos, userdata.rgnend, userdata.name)
                        end
                    end
                end
            end
        end
    end

    reaper.Undo_EndBlock("Complete renamer: name replaced.", -1)
    reaper.PreventUIRefresh(1)
    reaper.UpdateArrange()
end

-- Display found and renamed Reaper userdata
function DisplayUserdata()
    if global_datas.order then
        local tree_flags = reaper.ImGui_TreeNodeFlags_SpanAllColumns() | reaper.ImGui_TreeNodeFlags_Framed()
        if Settings.tree_start_open.value then tree_flags = tree_flags | reaper.ImGui_TreeNodeFlags_DefaultOpen() end
        for index, key in ipairs(global_datas.order) do
            if global_datas[key]["data"] then
                if reaper.ImGui_TreeNode(ctx, global_datas[key]["display"].."##index"..tostring(index), tree_flags) then
                    if reaper.ImGui_BeginTable(ctx, "table_"..key, 2, reaper.ImGui_TableFlags_BordersInnerV()) then
                        for _, userdata in pairs(global_datas[key]["data"]) do
                            local input_found = IsInputFindInName(userdata.name, input_find)
                            local show_userdata = true
                            if Settings.only_show_replace.value and not input_found and input_find ~= "" then show_userdata = false end
                            if show_userdata then
                                reaper.ImGui_TableNextRow(ctx)
                                reaper.ImGui_TableNextColumn(ctx)
                                local label = "##selectable"..key..tostring(userdata.id)..userdata.name
                                changed, userdata.selected = reaper.ImGui_Selectable(ctx, userdata.name..label, userdata.selected, reaper.ImGui_SelectableFlags_SpanAllColumns())
                                if changed then
                                    if key == "items" then reaper.SetMediaItemSelected(userdata.id, userdata.selected)
                                    elseif key == "tracks" then reaper.SetTrackSelected(userdata.id, userdata.selected) end
                                    reaper.UpdateArrange()
                                end

                                reaper.ImGui_TableNextColumn(ctx)
                                local can_apply = true
                                if Settings.selection_based.value and not userdata.selected then can_apply = false end
                                if input_found and can_apply then
                                    local replaced_text = GetReplacedName(userdata.name, input_find, input_replace)
                                    reaper.ImGui_Text(ctx, replaced_text)
                                end
                            end
                        end

                        reaper.ImGui_EndTable(ctx)
                    end
                    reaper.ImGui_TreePop(ctx)
                end
            end
        end
    end
end

-- Main script execution
SetButtonState(1)
Gui_Init()
Gui_Loop()
reaper.atexit(SetButtonState)
