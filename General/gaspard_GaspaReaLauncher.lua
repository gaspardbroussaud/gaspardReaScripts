--@description GaspaReaLauncher
--@author gaspard
--@version 0.0.5
--@changelog
--  - Added refresh project list
--  - Button size auto adjust
--@about
--  # Gaspard Reaper Launcher
--  Reaper Launcher for projects.

--#region SCRIPT INIT -------------------------------------------------
-----------------------------------------------------------------------
-----------------------------------------------------------------------
-- Toggle button state in Reaper
local action_name = ""
local version = ""
function SetButtonState(set)
    local _, name, sec, cmd, _, _, _ = reaper.get_action_context()
    if set == 1 then
      action_name = string.match(name, 'gaspard_(.-)%.lua')
      -- Get version from ReaPack
      local pkg = reaper.ReaPack_GetOwner(name)
      version = tostring(select(7, reaper.ReaPack_GetEntryInfo(pkg)))
      reaper.ReaPack_FreeEntry(pkg)
    end
    reaper.SetToggleCommandState(sec, cmd, set or 0)
    reaper.RefreshToolbar2(sec, cmd)
end
SetButtonState(1)

-- Load Utilities
dofile(reaper.GetResourcePath() ..
       '/Scripts/ReaTeam Extensions/API/imgui.lua')
  ('0.9.3.2') -- current version at the time of writing the script

local json_file_path = reaper.GetResourcePath()..'/Scripts/Gaspard ReaScripts/JSON'
package.path = package.path .. ';' .. json_file_path .. '/?.lua'
local gson = require('json_utilities_lib')
local script_path = debug.getinfo(1, 'S').source:match [[^@?(.*[\/])[^\/]-$]]
local settings_path = script_path..'/gaspard_'..action_name..'_settings.json'

local settings_version = "0.0.1"
local default_settings = {
    version = settings_version,
    order = {"close_on_open", "default_open_style"},
    close_on_open = {
        value = true,
        name = "Close on project open",
        description = "Close launcher window on project open."
    },
    search_type = {
        value = "Newest",
        list = {"A-Z", "Z-A", "Newest", "Oldest", "Favorites"},
        name = "Search order type",
        description = "Search order alphabetically, by order, by date..."
    },
    default_open_style = {
        value = "new_tab",
        list = {"current_tab", "new_tab"},
        name = "Default project openning style",
        description = "Open project in current tab or in new tab as default behaviour."
    }
}

Settings = gson.LoadJSON(settings_path, default_settings)
if settings_version ~= Settings.version then
    reaper.ShowConsoleMsg("\n!!! WARNING !!! (gaspard_GaspaReaLauncher.lua)\n")
    reaper.ShowConsoleMsg("Settings are erased due to updates in settings file.\nPlease excuse this behaviour.\n")
    reaper.ShowConsoleMsg("Now in version: "..settings_version.."\n")
    Settings = gson.SaveJSON(settings_path, default_settings)
    Settings = gson.LoadJSON(settings_path, Settings)
end

--#endregion

--#region GUI VARIABLES -----------------------------------------------
-----------------------------------------------------------------------
-----------------------------------------------------------------------
-- Window variables
local og_window_width = 1000
local og_window_height = 400
local min_width, min_height = 500, 201
local max_width, max_height = 1920, 1080
local window_width, window_height = og_window_width, og_window_height
local window_x, window_y = 0, 0
local popup_x, popup_y = 0, 0
local mouse_right_clic_popup = false
local no_scrollbar_flags = reaper.ImGui_WindowFlags_NoScrollWithMouse() | reaper.ImGui_WindowFlags_NoScrollbar()
local window_name = "GASPARD REAPER LAUNCHER"

-- Sizing variables
local topbar_height = 30
local font_size = 16
local small_font_size = font_size * 0.75

-- ImGui Init
local ctx = reaper.ImGui_CreateContext('gaspard_rea_launcher_ctx')
local font = reaper.ImGui_CreateFont('sans-serif', font_size)
local italic_font = reaper.ImGui_CreateFont('sans-serif', font_size, reaper.ImGui_FontFlags_Italic())
local small_font = reaper.ImGui_CreateFont('sans-serif', small_font_size, reaper.ImGui_FontFlags_Italic())
reaper.ImGui_Attach(ctx, font)
reaper.ImGui_Attach(ctx, italic_font)
reaper.ImGui_Attach(ctx, small_font)
local global_spacing = reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing())
local show_settings = false

-- Get GUI style from file
local gui_style_settings_path = reaper.GetResourcePath().."/Scripts/Gaspard ReaScripts/GUI/GUI_Style_Settings.lua"
local style = dofile(gui_style_settings_path)
local style_vars = style.vars
local style_colors = style.colors
--#endregion

--region SCRIPT ELEMENTS ----------------------------------------------
-----------------------------------------------------------------------
-----------------------------------------------------------------------

local project_list = {}
local project_search = ""
local current_right_clic_project = nil
local project_already_selected = false
local open_create = "create"

local function SortFavorites()
    local favorites = {}
    local not_favs = {}
    for _, project in ipairs(project_list) do
        if project.stared then
            favorites[#favorites+1] = project
        else
            not_favs[#not_favs+1] = project
        end
    end
    table.sort(favorites, function(a, b)
        return a.name:lower() < b.name:lower()
    end)
    table.sort(not_favs, function(a, b)
        return a.name:lower() < b.name:lower()
    end)
    project_list = {}
    for _, fav in ipairs(favorites) do
        project_list[#project_list+1] = fav
    end
    for _, not_fav in ipairs(not_favs) do
        project_list[#project_list+1] = not_fav
    end
end

local function SetSortingToType(type, tab)
    if type == "A-Z" then
        table.sort(tab, function(a, b)
            return a.name:lower() < b.name:lower()
        end)
    elseif type == "Z-A" then
        table.sort(tab, function(a, b)
            return a.name:lower() > b.name:lower()
        end)
    elseif type == "Newest" then
        table.sort(project_list, function(a, b)
            return a.date > b.date
        end)
    elseif type == "Oldest" then
        table.sort(project_list, function(a, b)
            return a.date < b.date
        end)
    elseif type == "Favorites" then
        SortFavorites()
    end
end

local function GetRecentProjects()
    local i = 1
    local path = ""
    while path ~= "noEntry" do
        _, path = reaper.BR_Win32_GetPrivateProfileString("recent", "recent" .. string.format("%02d", i), "noEntry", reaper.get_ini_file())
        if path == "noEntry" then break end
        local cur_exists = reaper.file_exists(path)
        local cur_name = path:match("([^\\/]+)$"):gsub("%.rpp$", "")
        local retval, _, _, modified_time, _, _, _, _, _, _, _, _ = reaper.JS_File_Stat(path)
        if retval ~= 0 then modified_time = "" end
        project_list[i] = {exists = cur_exists, name = cur_name, selected = false, path = path, date = modified_time, stared = false, ini_line = i}
        i = i + 1
    end
    if #project_list > 0 then
        SetSortingToType(Settings.search_type.value, project_list)
    end
end

local function System_Init()
    GetRecentProjects()
end

-- Split input text in multiple words (space between in orginial text)
local function SplitIntoWords(text)
    local words = {}
    for word in text:gmatch("%S+") do
        table.insert(words, word)
    end
    return words
end

-- Check for word matches in script names with input text
local function MatchesAllWords(words, text)
    for _, word in ipairs(words) do
        if not text:lower():find(word:lower(), 1, true) then
            return false
        end
    end
    return true
end

local function ShiftSelectInTable(i_one, i_two, tab)
    local first = 0
    local last = 0
    if i_one < i_two then first, last = i_one, i_two
    else first, last = i_two, i_one end

    for i = first, #tab do
        tab[i].selected = true
        if i == last then return end
    end
end

local function LoadInCurrentTab(path)
    reaper.Main_openProject(path)
end

local function LoadInNewTab(path)
    reaper.Main_OnCommand(41929, 0) -- New project tab (ignore default template)
    reaper.Main_openProject(path)
end

local function ProjectLoading(search_type)
    local retval, current_project = reaper.GetSetProjectInfo_String(0, "PROJECT_NAME", "", false)
    if not retval then current_project = "" end
    if current_project == "" then search_type = "current_tab" end
    for _, j_project in ipairs(project_list) do
        if j_project.selected then
            if j_project.exists then
                if search_type == "new_tab" then
                    LoadInNewTab(j_project.path)
                elseif search_type == "current_tab" then
                    LoadInCurrentTab(j_project.path)
                    search_type = "new_tab"
                end
            else
                reaper.MB("No file found at path:\n"..j_project.path, "GASPARD REAPER LAUNCHER ERROR", 0)
                j_project.selected = false
            end
        end
    end

    if Settings.close_on_open.value then open = false end
end

local function NewProjectOpen(search_type)
    if search_type == "new_tab" then
        reaper.Main_OnCommand(41929, 0) -- New project tab (ignore default template)
    elseif search_type == "current_tab" then
        reaper.Main_OnCommand(40023, 0) -- New project
    end

    if Settings.close_on_open.value then open = false end
end

local function OpenProjectSelect(search_type)
    local retval, filepath = reaper.JS_Dialog_BrowseForOpenFiles("Select a project to open", "", "*.rpp", "", false)
    if retval and filepath ~= "" then
        if search_type == "new_tab" then
            reaper.Main_OnCommand(41929, 0) -- New project tab (ignore default template)
            reaper.Main_openProject(filepath)
        elseif search_type == "current_tab" then
            reaper.Main_openProject(filepath)
        end

        if Settings.close_on_open.value then open = false end
    end
end

local function System_Loop()
    CTRL = reaper.ImGui_IsKeyDown(ctx, reaper.ImGui_Key_LeftCtrl()) or reaper.ImGui_IsKeyDown(ctx, reaper.ImGui_Key_RightCtrl())
    SHIFT = reaper.ImGui_IsKeyDown(ctx, reaper.ImGui_Key_LeftShift()) or reaper.ImGui_IsKeyDown(ctx, reaper.ImGui_Key_RightShift())
end

local function LoadSettings()
    gson.LoadJSON(settings_path, Settings)
end

local function SaveSettings()
    gson.SaveJSON(settings_path, Settings)
end

--endregion

--region GUI ELEMENTS -------------------------------------------------
-----------------------------------------------------------------------
-----------------------------------------------------------------------

-- GUI Top Bar
local function TopBarDisplay()
    -- GUI Menu Bar
    local child_width = window_width - global_spacing
    if reaper.ImGui_BeginChild(ctx, "child_top_bar", child_width, topbar_height, reaper.ImGui_ChildFlags_None(), no_scrollbar_flags) then
        reaper.ImGui_Text(ctx, window_name)

        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(), 5, 0)

        reaper.ImGui_SameLine(ctx)
        reaper.ImGui_Dummy(ctx, 3, 1)
        reaper.ImGui_SameLine(ctx)

        local spacing_x = reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing())
        local text_new_project = window_width > 650 and "New project" or "New"
        local text_open_project = window_width > 600 and "Open project" or "Open"
        local text_refresh = window_width > 550 and "Refresh" or "R"
        local new_project_w = reaper.ImGui_CalcTextSize(ctx, text_new_project) + 5 + spacing_x * 2
        local open_project_w = reaper.ImGui_CalcTextSize(ctx, text_open_project) + 5 + spacing_x * 2
        local refresh_w = reaper.ImGui_CalcTextSize(ctx, text_refresh) + 5 + spacing_x * 2
        local settings_w = reaper.ImGui_CalcTextSize(ctx, "Settings") + 5 + spacing_x * 2
        local quit_w = 10 + spacing_x * 2
        local x_pos = child_width + 1 - new_project_w - open_project_w - refresh_w - settings_w - quit_w - spacing_x * 6
        local y_pos = 0

        reaper.ImGui_SetCursorPos(ctx, x_pos, y_pos)
        reaper.ImGui_SetCursorPosY(ctx, y_pos)
        if reaper.ImGui_Button(ctx, text_new_project..'##new_project_button', new_project_w) then
            NewProjectOpen(Settings.default_open_style.value)
        end
        if reaper.ImGui_IsItemHovered(ctx) then
            if reaper.ImGui_IsMouseClicked(ctx, reaper.ImGui_MouseButton_Right()) then
                open_create = "create"
                popup_x, popup_y = reaper.ImGui_GetMousePos(ctx)
                mouse_right_clic_popup = true
            end
        end

        reaper.ImGui_SameLine(ctx)

        reaper.ImGui_SetCursorPosY(ctx, y_pos)
        if reaper.ImGui_Button(ctx, text_open_project..'##open_project_button', open_project_w) then
            OpenProjectSelect(Settings.default_open_style.value)
        end
        if reaper.ImGui_IsItemHovered(ctx) then
            if reaper.ImGui_IsMouseClicked(ctx, reaper.ImGui_MouseButton_Right()) then
                open_create = "open"
                popup_x, popup_y = reaper.ImGui_GetMousePos(ctx)
                mouse_right_clic_popup = true
            end
        end

        reaper.ImGui_SameLine(ctx)

        reaper.ImGui_SetCursorPosY(ctx, y_pos)
        if reaper.ImGui_Button(ctx, text_refresh..'##refresh_button', refresh_w) then
            GetRecentProjects()
        end

        reaper.ImGui_SameLine(ctx)

        reaper.ImGui_SetCursorPosY(ctx, y_pos)
        if reaper.ImGui_Button(ctx, 'Settings##settings_button', settings_w) then
            show_settings = not show_settings
            if not show_settings then SaveSettings() end
        end

        reaper.ImGui_SameLine(ctx)

        reaper.ImGui_SetCursorPosY(ctx, y_pos)
        if reaper.ImGui_Button(ctx, 'X##quit_button', quit_w) then
            open = false
        end

        reaper.ImGui_PopStyleVar(ctx, 1)

        if mouse_right_clic_popup then
            reaper.ImGui_OpenPopup(ctx, "popup_mouse_rc_topbar")
            mouse_right_clic_popup = false
        end
        reaper.ImGui_SetNextWindowPos(ctx, popup_x, popup_y)
        if reaper.ImGui_BeginPopup(ctx, "popup_mouse_rc_topbar") then
            reaper.ImGui_SetKeyboardFocusHere(ctx)
            local text = open_create == "create" and "Create" or "Open"

            reaper.ImGui_Selectable(ctx, text.." in current tab", false)
            if reaper.ImGui_IsItemActivated(ctx) then
                if create_open == "open" then
                    NewProjectOpen("current_tab")
                else
                    OpenProjectSelect("current_tab")
                end
            end

            reaper.ImGui_Selectable(ctx, text.." in new tab", false)
            if reaper.ImGui_IsItemActivated(ctx) then
                if create_open == "create" then
                    NewProjectOpen("new_tab")
                else
                    OpenProjectSelect("new_tab")
                end
            end

            reaper.ImGui_EndPopup(ctx)
        end

        reaper.ImGui_EndChild(ctx)
    end
end

-- Push all GUI style settings
local function Gui_PushTheme()
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
local function Gui_PopTheme()
    reaper.ImGui_PopStyleVar(ctx, #style_vars)
    reaper.ImGui_PopStyleColor(ctx, #style_colors)
end

-- All GUI elements
local function ElementsDisplay()
    -- Search bar
    reaper.ImGui_Text(ctx, "Search:")

    reaper.ImGui_SameLine(ctx)

    reaper.ImGui_PushItemWidth(ctx, -1 - 100)
    changed, project_search = reaper.ImGui_InputText(ctx, "##search_bar", project_search)

    reaper.ImGui_SameLine(ctx)

    reaper.ImGui_PushItemWidth(ctx, -1)
    if reaper.ImGui_BeginCombo(ctx, "##sort_search", Settings.search_type.value) then
        for _, type in ipairs(Settings.search_type.list) do
            local is_selected = (type == Settings.search_type.value)
            if reaper.ImGui_Selectable(ctx, type, is_selected) then
                Settings.search_type.value = type
                SetSortingToType(type, project_list)
            end
        end
        reaper.ImGui_EndCombo(ctx)
    end

    -- Listbox of projects
    if reaper.ImGui_BeginListBox(ctx, "##project_listbox", -1, -1) then
        local draw_list = reaper.ImGui_GetWindowDrawList(ctx)

        for i, project in ipairs(project_list) do
            if project_search == "" or MatchesAllWords(SplitIntoWords(project_search), project.name) then
                -- Favorite start
                local cx, cy = reaper.ImGui_GetCursorScreenPos(ctx)
                local button_size = 15
                if reaper.ImGui_InvisibleButton(ctx, "##star_"..tostring(i), button_size, button_size) then
                    project.stared = not project.stared
                    SetSortingToType(Settings.search_type.value, project_list)
                end
                local hovered = reaper.ImGui_IsItemHovered(ctx)

                reaper.ImGui_SameLine(ctx)

                if hovered then
                    local col_header = reaper.ImGui_GetStyleColor(ctx, reaper.ImGui_Col_HeaderHovered())
                    local content_x, _ = reaper.ImGui_GetContentRegionMax(ctx)
                    local padding_x, _ = reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding())
                    reaper.ImGui_DrawList_AddRectFilled(draw_list, cx, cy - 2, cx + content_x - padding_x, cy + 18, col_header)
                end

                -- Selectable line
                local hovered_and_selected = hovered and project.selected
                if hovered_and_selected then reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Header(), 0x00000000) end
                if not project.exists then reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), 0xFF0000A1) end
                local selectable_flags = reaper.ImGui_SelectableFlags_SpanAllColumns() | reaper.ImGui_SelectableFlags_AllowDoubleClick()
                changed, project.selected = reaper.ImGui_Selectable(ctx, project.name, project.selected, selectable_flags)
                if not project.exists then reaper.ImGui_PopStyleColor(ctx, 1) end
                if hovered_and_selected then reaper.ImGui_PopStyleColor(ctx, 1) end

                local selectable_hovered = reaper.ImGui_IsItemHovered(ctx)

                if changed then
                    if SHIFT then
                        if last_project_selected ~= i then
                            ShiftSelectInTable(i, last_project_selected, project_list)
                        end
                    else
                        if not CTRL then
                            if not project.selected then project.selected = true end
                            for j, j_project in ipairs(project_list) do
                                if j ~= i then j_project.selected = false end
                            end
                        end
                    end

                    last_project_selected = i
                end

                -- On Double clic
                if reaper.ImGui_IsItemHovered(ctx) then
                    if reaper.ImGui_IsMouseClicked(ctx, reaper.ImGui_MouseButton_Right()) then
                        if project.selected then
                            project_already_selected = true
                        else
                            project.selected = true
                        end
                        popup_x, popup_y = reaper.ImGui_GetMousePos(ctx)
                        mouse_right_clic_popup = true
                        current_right_clic_project = project
                    end

                    if reaper.ImGui_IsMouseDoubleClicked(ctx, reaper.ImGui_MouseButton_Left()) then
                        --[[for _, j_project in ipairs(project_list) do
                            if j_project.selected then
                                if j_project.exists then
                                    if Settings.default_open_style.value == "new_tab" then
                                        LoadInNewTab(j_project.path)
                                    elseif Settings.default_open_style.value == "current_tab" then
                                        LoadInCurrentTab(j_project.path)
                                    end

                                    if Settings.close_on_open.value then open = false end
                                else
                                    reaper.MB("No file found at path:\n"..j_project.path, "GASPARD REAPER LAUNCHER ERROR", 0)
                                    j_project.selected = false
                                end
                            end
                        end]]
                        ProjectLoading(Settings.default_open_style.value)
                    end
                end

                local outer_r = 6
                local color = project.stared and 0xFFFFFFFF or hovered and 0xCCCCCCFF or selectable_hovered and 0xAAAAAAAA or 0x00000000
                reaper.ImGui_DrawList_AddCircleFilled(draw_list, cx + (button_size / 1.6), cy + (button_size / 2), outer_r, color)
            end
        end

        reaper.ImGui_EndListBox(ctx)
    end

    if mouse_right_clic_popup then
        reaper.ImGui_OpenPopup(ctx, "popup_mouse_right_clic")
        mouse_right_clic_popup = false
    end
    reaper.ImGui_SetNextWindowPos(ctx, popup_x, popup_y)
    if reaper.ImGui_BeginPopup(ctx, "popup_mouse_right_clic") then
        reaper.ImGui_SetKeyboardFocusHere(ctx)
        if not current_right_clic_project then
            reaper.ImGui_CloseCurrentPopup(ctx)
            return
        end

        reaper.ImGui_Selectable(ctx, "Load in current tab", false)
        if reaper.ImGui_IsItemActivated(ctx) then
            --[[for _, j_project in ipairs(project_list) do
                if j_project.selected then
                    if j_project.exists then
                        LoadInCurrentTab(j_project.path)
                    else
                        reaper.MB("No file found at path:\n"..j_project.path.."\nRemove path?", "GASPARD REAPER LAUNCHER ERROR", 0)
                        j_project.selected = false
                    end
                end
            end
            if Settings.close_on_open.value then open = false end]]
            ProjectLoading("current_tab")
        end

        reaper.ImGui_Selectable(ctx, "Load in new tab", false)
        if reaper.ImGui_IsItemActivated(ctx) then
            --[[for _, j_project in ipairs(project_list) do
                if j_project.selected then
                    if j_project.exists then
                        LoadInNewTab(j_project.path)
                    else
                        reaper.MB("No file found at path:\n"..j_project.path, "GASPARD REAPER LAUNCHER ERROR", 0)
                        j_project.selected = false
                    end
                end
            end
            if Settings.close_on_open.value then open = false end]]
            ProjectLoading("new_tab")
        end

        reaper.ImGui_Selectable(ctx, "Remove entry", false)
        if reaper.ImGui_IsItemActivated(ctx) then
            if reaper.ShowMessageBox("The selected entries will be removed.", "REMOVE SELECTED ENTRIES", 1) == 1 then
                for _, j_project in ipairs(project_list) do
                    if j_project.selected then
                        reaper.BR_Win32_WritePrivateProfileString("recent", "recent"..string.format("%02d", j_project.ini_line), "", reaper.get_ini_file())
                    end
                end
                GetRecentProjects()
            end
        end

        reaper.ImGui_EndPopup(ctx)
    else
        if current_right_clic_project then
            if not project_already_selected then
                current_right_clic_project.selected = false
            else
                project_already_selected = false
            end
            current_right_clic_project = nil
        end
    end
end

-- All Settings
local function ElementsSettings()
    local settings_flags = reaper.ImGui_WindowFlags_NoCollapse() | reaper.ImGui_WindowFlags_NoScrollbar() | reaper.ImGui_WindowFlags_NoResize()
    local settings_width = og_window_width - 80
    local settings_height = og_window_height * 0.7
    reaper.ImGui_SetNextWindowSize(ctx, settings_width, settings_height, reaper.ImGui_Cond_Once())
    reaper.ImGui_SetNextWindowPos(ctx, window_x + (window_width - settings_width) * 0.5, window_y + 10, reaper.ImGui_Cond_Appearing())
    local settings_visible, settings_open = reaper.ImGui_Begin(ctx, "SETTINGS", true, settings_flags)
    if settings_visible then
        local one_changed = false

        changed, Settings.close_on_open.value = reaper.ImGui_Checkbox(ctx, Settings.close_on_open.name, Settings.close_on_open.value)
        if changed then one_changed = true end
        reaper.ImGui_SetItemTooltip(ctx, Settings.close_on_open.description)

        local display = (Settings.default_open_style.value:sub(1,1):upper()..Settings.default_open_style.value:sub(2)):gsub("_", " ")
        reaper.ImGui_PushItemWidth(ctx, 110)
        if reaper.ImGui_BeginCombo(ctx, Settings.default_open_style.name, display) then
            for _, type in ipairs(Settings.default_open_style.list) do
                local is_selected = (type == Settings.default_open_style.value)
                local type_display = (type:sub(1,1):upper()..type:sub(2)):gsub("_", " ")
                if reaper.ImGui_Selectable(ctx, type_display, is_selected) then
                    Settings.default_open_style.value = type
                end
            end
            reaper.ImGui_EndCombo(ctx)
        end
        reaper.ImGui_SetItemTooltip(ctx, Settings.default_open_style.description)

        if one_changed then SaveSettings() end

        reaper.ImGui_End(ctx)
    else
        settings_open = false
    end
    if not settings_open then
        show_settings = false
    end
end

-- Main loop
local function Gui_Loop()
    -- On tick
    System_Loop()

    -- GUI --------
    Gui_PushTheme()

    -- Window Settings
    local window_flags = reaper.ImGui_WindowFlags_NoCollapse() | reaper.ImGui_WindowFlags_NoTitleBar() | no_scrollbar_flags
    reaper.ImGui_SetNextWindowSize(ctx, window_width, window_height, reaper.ImGui_Cond_Once())
    reaper.ImGui_SetNextWindowSizeConstraints(ctx, min_width, min_height, max_width, max_height)
    -- Font
    reaper.ImGui_PushFont(ctx, font)
    -- Begin
    visible, open = reaper.ImGui_Begin(ctx, window_name, true, window_flags)
    window_x, window_y = reaper.ImGui_GetWindowPos(ctx)
    window_width, window_height = reaper.ImGui_GetWindowSize(ctx)

    global_spacing = reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing())

    if visible then
        TopBarDisplay()

        ElementsDisplay()

        if show_settings then ElementsSettings() end

        reaper.ImGui_End(ctx)
    end

    Gui_PopTheme()
    reaper.ImGui_PopFont(ctx)
    if open then
      reaper.defer(Gui_Loop)
    end
end

--endregion

System_Init()
Gui_Loop()

reaper.atexit(SetButtonState)
