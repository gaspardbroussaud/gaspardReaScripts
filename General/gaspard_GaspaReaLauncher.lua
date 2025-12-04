--@description GaspaReaLauncher
--@author gaspard
--@version 1.1.1
--@changelog
--  - Added relink option for invalid file paths
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
        version = version ~= "" and version or "1.0.0"
        reaper.ReaPack_FreeEntry(pkg)
    end
    reaper.SetToggleCommandState(sec, cmd, set or 0)
    reaper.RefreshToolbar2(sec, cmd)
end
SetButtonState(1)

-- Load Utilities
dofile(reaper.GetResourcePath() ..
       '/Scripts/ReaTeam Extensions/API/imgui.lua')
  ('0.10.0.1') -- current version at the time of writing the script

local json_file_path = reaper.GetResourcePath()..'/Scripts/Gaspard ReaScripts/JSON'
package.path = package.path .. ';' .. json_file_path .. '/?.lua'
local gson = require('json_utilities_lib')
local json_version = "1.0.6"
if not gson.version or gson.version_less(gson.version, json_version) then
    reaper.MB('Please update gaspard "json_utilities_lib" to version ' .. json_version .. ' or higher.', "ERROR", 0)
    return
end

local settings_path = debug.getinfo(1, 'S').source:match [[^@?(.*[\/])[^\/]-$]] .. '/gaspard_'..action_name..'_settings.json'
local settings_version = "0.0.6"
local default_settings = {
    version = settings_version,
    order = {"close_on_open", "search_type", "default_open_style", "display_full_path", "close_on_escape", "show_path_hovered"},
    close_on_open = {
        value = true,
        name = "Close on project open",
        description = "Close launcher window on project open."
    },
    search_type = {
        value = "Newest",
        list = {"A-Z", "Z-A", "Newest", "Oldest", "Favorites_Down", "Favorites_Up"},
        name = "Search order type",
        description = "Search order alphabetically, by order, by date..."
    },
    default_open_style = {
        value = "new_tab",
        list = {"current_tab", "new_tab"},
        name = "Default project openning style",
        description = "Open project in current tab or in new tab as default behaviour."
    },
    display_full_path = {
        value = false,
        name = "Display full path",
        description = "Display full path in list view."
    },
    close_on_escape = {
        value = false,
        name = "Close on escape",
        description = "Close launcher on Escape key pressed."
    },
    show_path_hovered = {
        value = false,
        name = "Show path on hover",
        description = "Show full project path on hovered in list."
    }
}

Settings = gson.LoadJSON(settings_path, default_settings)
if not Settings.version or settings_version ~= Settings.version then
    local keys = {}
    Settings = gson.CompleteUpdate(settings_path, Settings, default_settings, keys)
    --local updated_settings = gson.UpdateSettings(Settings, default_settings, keys)
    --Settings = gson.SaveJSON(settings_path, updated_settings)
    --Settings = gson.LoadJSON(settings_path, Settings)
end

local KEYS = dofile(reaper.GetResourcePath().."/Scripts/Gaspard ReaScripts/Libraries/KEYBOARD.lua")
local shortcut = KEYS.GetTableOfPressedKeys()

--#endregion

--#region GUI VARIABLES -----------------------------------------------
-----------------------------------------------------------------------
-----------------------------------------------------------------------
-- Get GUI style from file
local GUI_STYLE = dofile(reaper.GetResourcePath().."/Scripts/Gaspard ReaScripts/Libraries/GUI_STYLE.lua")
local GUI_SYS = dofile(reaper.GetResourcePath().."/Scripts/Gaspard ReaScripts/Libraries/GUI_SYS.lua")

-- Window variables
local og_window_width = 1000
local og_window_height = 500
local min_width, min_height = 510, 201
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

-- ImGui Init
local ctx = reaper.ImGui_CreateContext('gaspard_rea_launcher_ctx')
local arial_font = reaper.ImGui_CreateFontFromFile(GUI_STYLE.FONTS.ARIAL.CLASSIC)
local italic_arial_font = reaper.ImGui_CreateFontFromFile(GUI_STYLE.FONTS.ARIAL.CLASSIC, 0, reaper.ImGui_FontFlags_Italic())
local icon_font = reaper.ImGui_CreateFontFromFile(GUI_STYLE.FONTS.ICONS)
reaper.ImGui_Attach(ctx, arial_font)
reaper.ImGui_Attach(ctx, italic_arial_font)
reaper.ImGui_Attach(ctx, icon_font)
local show_settings = false
--#endregion

--region SCRIPT ELEMENTS ----------------------------------------------
-----------------------------------------------------------------------
-----------------------------------------------------------------------

local os_is_windows = reaper.GetOS():find("Win")

local project_list = {}
local project_search = ""
local curr_right_clc_proj = nil
local project_already_selected = false
local proj_sel_num = 0
local open_create = "create"
local ini_file = reaper.get_ini_file()

local function SortFavorites(order)
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
    local list1, list2 = {}, {}
    if order == 'DOWN' then
        list1, list2 = favorites, not_favs
    elseif order == 'UP' then
        list1, list2 = not_favs, favorites
    end
    for _, proj in ipairs(list1) do
        project_list[#project_list+1] = proj
    end
    for _, proj in ipairs(list2) do
        project_list[#project_list+1] = proj
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
            return a.ini_line > b.ini_line --Formerly by .date
        end)
    elseif type == "Oldest" then
        table.sort(project_list, function(a, b)
            return a.ini_line < b.ini_line --Formerly by .date
        end)
    elseif type == "Favorites_Down" then
        SortFavorites('DOWN')
    elseif type == "Favorites_Up" then
        SortFavorites('UP')
    end
end

local function CleanRecentProjects()
    local retval, max_recent = reaper.BR_Win32_GetPrivateProfileString("Reaper", "maxrecent", "", ini_file)
    if retval ~= 0 then max_recent = tonumber(max_recent) else max_recent = 50 end

    -- Check if there is a missmatch
    local found = false
    local _, prev = reaper.BR_Win32_GetPrivateProfileString("Recent", string.format("recent%02d", 1), "noEntry", ini_file)
    for i = 2, max_recent do
        local _, current = reaper.BR_Win32_GetPrivateProfileString("Recent", string.format("recent%02d", i), "noEntry", ini_file)
        if prev == "noEntry" and current ~= "noEntry" then
            found = true
            break
        end
        prev = current
    end
    if not found then return end

    local project_paths = {}
    for i = 1, max_recent do
        local _, path = reaper.BR_Win32_GetPrivateProfileString("Recent", string.format("recent%02d", i), "noEntry", ini_file)
        if path ~= "noEntry" then
            project_paths[#project_paths+1] = path
            reaper.BR_Win32_WritePrivateProfileString("Recent", string.format("recent%02d", i), "", ini_file)
        end
    end

    for i, path in ipairs(project_paths) do
        reaper.BR_Win32_WritePrivateProfileString("Recent", string.format("recent%02d", i), path, ini_file)
    end
end

local function GetRecentProjects()
    CleanRecentProjects()
    local i = 1
    local path = ""
    project_list = {}
    while path ~= "noEntry" do
        _, path = reaper.BR_Win32_GetPrivateProfileString("Recent", string.format("recent%02d", i), "noEntry", ini_file)
        if path == "noEntry" or path == "" then break end

        for _, proj in ipairs(project_list) do if proj.path == path then goto skip_entry end end

        local cur_exists = reaper.file_exists(path)
        local cur_name = path:match("([^\\/]+)$"):gsub("%.rpp$", "")
        local retval, _, _, modified_time, _, _, _, _, _, _, _, _ = reaper.JS_File_Stat(path)
        if retval ~= 0 or not cur_exists then modified_time = "00"..tostring(i) end
        project_list[i] = {exists = cur_exists, name = cur_name, selected = false, path = path, date = modified_time, stared = false, ini_line = i}

        i = i + 1
        ::skip_entry::
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
    if not i_one or not i_two then return nil end
    if i_one < i_two then first, last = i_one, i_two
    else first, last = i_two, i_one end

    for i = first, #tab do
        tab[i].selected = true
        if i == last then return last - first end
    end
end

local function SelectAllCtrlA(tab)
    proj_sel_num = 0
    for _, element in ipairs(tab) do
        element.selected = true
        proj_sel_num = proj_sel_num + 1
    end
end

local function LoadInCurrentTab(path)
    reaper.Main_openProject(path)
end

local function LoadInNewTab(path)
    reaper.Main_OnCommand(41929, 0) -- New project tab (ignore default template)
    reaper.Main_openProject(path)
end

local function ProjectLoading(search_type, already_selected, current_project_selected)
    local shoud_close = false
    local retval, current_project = reaper.GetSetProjectInfo_String(0, "PROJECT_NAME", "", false)
    if not retval then current_project = "" end
    if current_project == "" then search_type = "current_tab" end
    if not already_selected then
        if current_project_selected.exists then
            if search_type == "new_tab" then
                LoadInNewTab(current_project_selected.path)
            elseif search_type == "current_tab" then
                LoadInCurrentTab(current_project_selected.path)
                search_type = "new_tab"
            end
            shoud_close = Settings.close_on_open.value
        else
            reaper.MB("No file found at path:\n"..current_project_selected.path, "GASPARD REAPER LAUNCHER ERROR", 0)
            current_project_selected.selected = false
        end
    else
        for _, j_project in ipairs(project_list) do
            if j_project.selected then
                if j_project.exists then
                    if search_type == "new_tab" then
                        LoadInNewTab(j_project.path)
                    elseif search_type == "current_tab" then
                        LoadInCurrentTab(j_project.path)
                        search_type = "new_tab"
                    end
                    shoud_close = Settings.close_on_open.value
                else
                    reaper.MB("No file found at path:\n"..j_project.path, "GASPARD REAPER LAUNCHER ERROR", 0)
                    j_project.selected = false
                end
            end
        end
    end

    if shoud_close then open = false end
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
    Settings = gson.LoadJSON(settings_path, Settings)
end

--endregion

--region GUI ELEMENTS -------------------------------------------------
-----------------------------------------------------------------------
-----------------------------------------------------------------------

-- GUI Top Bar
local function TopBarDisplay()
    -- OTHER GUI TOPBAR
    reaper.ImGui_BeginGroup(ctx)
    -- Name
    reaper.ImGui_Text(ctx, window_name)
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_PushFont(ctx, italic_arial_font, font_size * 0.75)
    reaper.ImGui_Text(ctx, "v"..version)
    reaper.ImGui_PopFont(ctx)

    -- Buttons
    local menu = {}
    table.insert(menu, {icon = 'QUIT', hint = 'Close', font = icon_font, size = 22, right_click = false})
    table.insert(menu, {icon = 'GEAR', hint = 'Settings', font = icon_font, size = 22, right_click = false})
    table.insert(menu, {icon = 'REFRESH_ARROW', hint = 'Refresh', font = icon_font, size = 22, right_click = false})
    table.insert(menu, {icon = 'IMPORT_FILE', hint = 'Open project', font = icon_font, size = 22, right_click = true})
    table.insert(menu, {icon = 'NEW_FILE', hint = 'New project', font = icon_font, size = 22, right_click = true})
    local rv, button = GUI_SYS.IconButtonRight(ctx, menu, window_width)
    if rv then
        local right_click = reaper.ImGui_IsMouseClicked(ctx, reaper.ImGui_MouseButton_Right())
        if button == 'QUIT' then
            open = false
        elseif button == 'GEAR' then
            show_settings = not show_settings
            if not show_settings then SaveSettings() end
        elseif button == 'REFRESH_ARROW' then
            GetRecentProjects()
        elseif button == 'IMPORT_FILE' then
            if right_click then
                open_create = "open"
                popup_x, popup_y = reaper.ImGui_GetMousePos(ctx)
                mouse_right_clic_popup = true
            else
                OpenProjectSelect(Settings.default_open_style.value)
            end
        elseif button == 'NEW_FILE' then
            if right_click then
                open_create = "create"
                popup_x, popup_y = reaper.ImGui_GetMousePos(ctx)
                mouse_right_clic_popup = true
            else
                NewProjectOpen(Settings.default_open_style.value)
            end
        end
    end
    reaper.ImGui_EndGroup(ctx)

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
            if open_create == "create" then
                NewProjectOpen("current_tab")
            else
                OpenProjectSelect("current_tab")
            end
        end

        reaper.ImGui_Selectable(ctx, text.." in new tab", false)
        if reaper.ImGui_IsItemActivated(ctx) then
            if open_create == "create" then
                NewProjectOpen("new_tab")
            else
                OpenProjectSelect("new_tab")
            end
        end

        reaper.ImGui_EndPopup(ctx)
    end
end

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

-- All GUI elements
local function ElementsDisplay()
    -- Search bar
    reaper.ImGui_Text(ctx, "Search:")

    reaper.ImGui_SameLine(ctx)

    reaper.ImGui_PushItemWidth(ctx, -1 - 65)
    changed, project_search = reaper.ImGui_InputText(ctx, "##search_bar", project_search)

    reaper.ImGui_SameLine(ctx)

    reaper.ImGui_PushItemWidth(ctx, -1)
    local icons = {
        ["A-Z"] = "ALPHABETICAL_SORT_DOWN",
        ["Z-A"] = "ALPHABETICAL_SORT_UP",
        ["Newest"] = "NUM_SORT_DOWN",
        ["Oldest"] = "NUM_SORT_UP",
        ["Favorites_Up"] = "FAVORITE_SORT_UP",
        ["Favorites_Down"] = "FAVORITE_SORT_DOWN"
    }
    local display = GUI_STYLE.ICONS[icons[Settings.search_type.value]]
    reaper.ImGui_PushFont(ctx, icon_font, 20)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), 0xFFFFFFDF)
    if reaper.ImGui_BeginCombo(ctx, "##sort_search", display) then
        for _, type in ipairs(Settings.search_type.list) do
            local is_selected = (type == Settings.search_type.value)
            local display_type = GUI_STYLE.ICONS[icons[type]]
            if reaper.ImGui_Selectable(ctx, display_type, is_selected) then
                Settings.search_type.value = type
                SaveSettings()
                SetSortingToType(type, project_list)
            end
        end
        reaper.ImGui_EndCombo(ctx)
    end
    reaper.ImGui_PopStyleColor(ctx)
    reaper.ImGui_PopFont(ctx)

    -- Listbox of projects
    if reaper.ImGui_BeginListBox(ctx, "##project_listbox", -1, -1) then
        local draw_list = reaper.ImGui_GetWindowDrawList(ctx)

        if CTRL and reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_A()) then SelectAllCtrlA(project_list) end

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
                if hovered then
                    local col_header = reaper.ImGui_GetStyleColor(ctx, reaper.ImGui_Col_HeaderHovered())
                    local content_x, _ = reaper.ImGui_GetContentRegionAvail(ctx)
                    reaper.ImGui_DrawList_AddRectFilled(draw_list, cx, cy - 2, cx + content_x, cy + 21, col_header)
                end

                reaper.ImGui_SameLine(ctx)

                -- Selectable line
                local hovered_and_selected = hovered and project.selected
                if hovered_and_selected then reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Header(), 0x00000000) end
                if not project.exists then reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), 0xFF0000A1) end
                local selectable_flags = reaper.ImGui_SelectableFlags_SpanAllColumns() | reaper.ImGui_SelectableFlags_AllowDoubleClick()
                local display_name = Settings.display_full_path.value and project.path or project.name
                local display_id = display_name..tostring(i)
                changed, project.selected = reaper.ImGui_Selectable(ctx, display_name.."##"..display_id, project.selected, selectable_flags)
                if not project.exists then reaper.ImGui_PopStyleColor(ctx, 1) end
                if hovered_and_selected then reaper.ImGui_PopStyleColor(ctx, 1) end

                local selectable_hovered = reaper.ImGui_IsItemHovered(ctx)
                if Settings.show_path_hovered.value and reaper.ImGui_IsItemHovered(ctx, reaper.ImGui_HoveredFlags_Stationary()) then
                    if not project.exists then reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), 0xFF0000FA) end
                    reaper.ImGui_SetItemTooltip(ctx, project.path)
                    if not project.exists then reaper.ImGui_PopStyleColor(ctx, 1) end
                end

                if changed then
                    if SHIFT then
                        if last_project_selected ~= i then
                            local shift_count = ShiftSelectInTable(i, last_project_selected, project_list)
                            if shift_count then proj_sel_num = proj_sel_num + shift_count end
                        end
                    else
                        if CTRL then
                            if project.selected then
                                proj_sel_num = proj_sel_num + 1
                            else
                                proj_sel_num = proj_sel_num - 1
                            end
                        else
                            if not project.selected then project.selected = true end
                            for j, j_project in ipairs(project_list) do
                                if j ~= i then j_project.selected = false end
                            end
                            proj_sel_num = 1
                        end
                    end

                    last_project_selected = i
                end

                -- On Double clic and right clic
                if selectable_hovered then
                    -- Right clic
                    if reaper.ImGui_IsMouseClicked(ctx, reaper.ImGui_MouseButton_Right()) then
                        if project.selected then
                            project_already_selected = true
                        else
                            project.selected = true
                        end
                        popup_x, popup_y = reaper.ImGui_GetMousePos(ctx)
                        mouse_right_clic_popup = true
                        curr_right_clc_proj = project
                    end

                    -- Double clic
                    if reaper.ImGui_IsMouseDoubleClicked(ctx, reaper.ImGui_MouseButton_Left()) then
                        ProjectLoading(Settings.default_open_style.value, false, project)
                    end
                end

                --local outer_r = 6
                local color = project.stared and 0xFFFFFFFF or hovered and 0xCCCCCCFF or selectable_hovered and 0xAAAAAAAA or 0x00000000
                reaper.ImGui_PushFont(ctx, icon_font, 16)
                reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), color)
                reaper.ImGui_SetCursorScreenPos(ctx, cx + 2, cy + 2)
                reaper.ImGui_Text(ctx, GUI_STYLE.ICONS["FAVORITE"])
                reaper.ImGui_PopStyleColor(ctx)
                reaper.ImGui_PopFont(ctx)
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
        if not curr_right_clc_proj then
            reaper.ImGui_CloseCurrentPopup(ctx)
            return
        end

        if not curr_right_clc_proj.exists then reaper.ImGui_BeginDisabled(ctx) end
        reaper.ImGui_Selectable(ctx, "Open in current tab", false)
        if reaper.ImGui_IsItemActivated(ctx) then
            ProjectLoading("current_tab", project_already_selected, curr_right_clc_proj)
        end

        reaper.ImGui_Selectable(ctx, "Open in new tab", false)
        if reaper.ImGui_IsItemActivated(ctx) then
            ProjectLoading("new_tab", project_already_selected, curr_right_clc_proj)
        end
        if not curr_right_clc_proj.exists then reaper.ImGui_EndDisabled(ctx) end

        if curr_right_clc_proj.exists then
            local text_explorer = os_is_windows and "explorer" or "finder"
            reaper.ImGui_Selectable(ctx, "Show in "..text_explorer, false)
            if reaper.ImGui_IsItemActive(ctx) then
                if not project_already_selected then
                    local folder = curr_right_clc_proj.path:match("^(.*)[/\\]")
                    reaper.CF_ShellExecute(folder)
                else
                    for _, j_project in ipairs(project_list) do
                        if j_project.selected and j_project.exists then
                            local folder = j_project.path:match("^(.*)[/\\]")
                            reaper.CF_ShellExecute(folder)
                        end
                    end
                end
            end
        else
            reaper.ImGui_Selectable(ctx, "Relink project path", false)
            if reaper.ImGui_IsItemActive(ctx) then
                local retval, selected_path = reaper.GetUserFileNameForRead("", "Select a REAPER project file", ".rpp")
                if retval and selected_path ~= "" then
                    reaper.BR_Win32_WritePrivateProfileString("Recent", string.format("recent%02d", curr_right_clc_proj.ini_line), selected_path, ini_file)
                    GetRecentProjects()
                end
            end
        end

        local msg_text = not project_already_selected and "y" or proj_sel_num > 1 and "ies" or "y"
        reaper.ImGui_Selectable(ctx, "Remove entr"..msg_text, false)
        if reaper.ImGui_IsItemActivated(ctx) then
            if reaper.ShowMessageBox("The selected entr"..msg_text.." will be removed.", "REMOVE SELECTED ENTR"..string.upper(msg_text), 1) == 1 then
                if not project_already_selected then
                    if curr_right_clc_proj.exists then
                        reaper.BR_Win32_WritePrivateProfileString("Recent", string.format("recent%02d", curr_right_clc_proj.ini_line), "", ini_file)
                    end
                else
                    for _, j_project in ipairs(project_list) do
                        if j_project.selected then
                            reaper.BR_Win32_WritePrivateProfileString("Recent", string.format("recent%02d", j_project.ini_line), "", ini_file)
                        end
                    end
                end
                GetRecentProjects()
            end
        end

        reaper.ImGui_EndPopup(ctx)
    else
        if curr_right_clc_proj then
            if not project_already_selected then
                curr_right_clc_proj.selected = false
            else
                project_already_selected = false
            end
            curr_right_clc_proj = nil
        end
    end
end

-- All Settings
local function ElementsSettings()
    local settings_flags = reaper.ImGui_WindowFlags_NoCollapse() | reaper.ImGui_WindowFlags_NoScrollbar() | reaper.ImGui_WindowFlags_NoResize()
        | reaper.ImGui_WindowFlags_TopMost() | reaper.ImGui_WindowFlags_NoDecoration()
    local settings_width = 350 --og_window_width - 80
    local settings_height = 175 --og_window_height * 0.7
    local settings_x = window_x + window_width - 102
    reaper.ImGui_SetNextWindowSize(ctx, settings_width, settings_height, reaper.ImGui_Cond_Once())
    reaper.ImGui_SetNextWindowPos(ctx, settings_x, window_y + topbar_height + 5) --, reaper.ImGui_Cond_Appearing())
    --reaper.ImGui_SetNextWindowPos(ctx, window_x + (window_width - settings_width) * 0.5, window_y + 10, reaper.ImGui_Cond_Appearing())
    local settings_visible, settings_open = reaper.ImGui_Begin(ctx, "##settings_window", true, settings_flags)
    if settings_visible then
        reaper.ImGui_Text(ctx, "SETTINGS")
        reaper.ImGui_Separator(ctx)

        local one_changed = false

        changed, Settings.close_on_open.value = reaper.ImGui_Checkbox(ctx, Settings.close_on_open.name, Settings.close_on_open.value)
        if changed then one_changed = true end
        reaper.ImGui_SetItemTooltip(ctx, Settings.close_on_open.description)

        changed, Settings.display_full_path.value = reaper.ImGui_Checkbox(ctx, Settings.display_full_path.name, Settings.display_full_path.value)
        if changed then one_changed = true end
        reaper.ImGui_SetItemTooltip(ctx, Settings.display_full_path.description)

        changed, Settings.close_on_escape.value = reaper.ImGui_Checkbox(ctx, Settings.close_on_escape.name, Settings.close_on_escape.value)
        if changed then one_changed = true end
        reaper.ImGui_SetItemTooltip(ctx, Settings.close_on_escape.description)

        changed, Settings.show_path_hovered.value = reaper.ImGui_Checkbox(ctx, Settings.show_path_hovered.name, Settings.show_path_hovered.value)
        if changed then one_changed = true end
        reaper.ImGui_SetItemTooltip(ctx, Settings.show_path_hovered.description)

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
    reaper.ImGui_PushFont(ctx, arial_font, font_size)
    -- Begin
    visible, open = reaper.ImGui_Begin(ctx, window_name, true, window_flags)
    window_x, window_y = reaper.ImGui_GetWindowPos(ctx)
    window_width, window_height = reaper.ImGui_GetWindowSize(ctx)

    global_spacing = reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing())

    if visible then
        TopBarDisplay()

        ElementsDisplay()

        if show_settings then ElementsSettings() end

        if Settings.close_on_escape.value then
            if reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_Escape()) or KEYS.CheckShortcutPressed(shortcut) then open = false end
        end

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
