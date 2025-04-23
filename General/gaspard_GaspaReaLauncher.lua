--@noindex
--@description Pattern Manipulator
--@author gaspard
--@version 0.0.1b
--@changelog
--  Initial commit
--@about
--  # Gaspard Reaper Launcher
--  Reaper Launcher for projects.

--#region SCRIPT INIT -------------------------------------------------
-----------------------------------------------------------------------
-----------------------------------------------------------------------
-- Toggle button state in Reaper
local action_name = ""
local version = "0.0"
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

local Settings = {
    close_on_open = {
        value = true,
        name = "Close on project open",
        description = "Close launcher window on project open."
    },
    search_type = {
        value = "Newest",
        name = "Search order type",
        description = "Search order alphabetically, by order, by date..."
    },
    default_open_style = {
        value = "new_tab",
        name = "Default project openning style",
        description = "Open project in current tab or in new tab as default behaviour."
    }
}

--#endregion

--#region GUI VARIABLES -----------------------------------------------
-----------------------------------------------------------------------
-----------------------------------------------------------------------
-- Window variables
local og_window_width = 850
local og_window_height = 300
local min_width, min_height = 500, 201
local max_width, max_height = 1000, 400
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

-- Get GUI style from file
local gui_style_settings_path = reaper.GetResourcePath().."/Scripts/Gaspard ReaScripts/GUI/GUI_Style_Settings.lua"
local style = dofile(gui_style_settings_path)
local style_vars = style.vars
local style_colors = style.colors
--#endregion

--region SCRIPT ELEMENTS ----------------------------------------------
-----------------------------------------------------------------------
-----------------------------------------------------------------------

--local once = true

local project_list = {}
local project_search = ""
local search_types = {"A-Z", "Newest", "Oldest"}

local current_right_clic_project = nil
local project_already_selected = false

local function SetSortingToType(type, tab)
    if type == "A-Z" then
        table.sort(tab, function(a, b)
            return a.name:lower() < b.name:lower()
        end)
    elseif type == "Newest" then
        table.sort(project_list, function(a, b)
            return a.date < b.date
        end)
    elseif type == "Oldest" then
        table.sort(project_list, function(a, b)
            return a.date > b.date
        end)
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
        local retval, _, _, modifiedTime, _, _, _, _, _, _, _, _ = reaper.JS_File_Stat(path)
        if retval ~= 0 then modifiedTime = "" end
        project_list[i] = {exists = cur_exists, name = cur_name, selected = false, path = path, date = modifiedTime, stared = false}
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

local function System_Loop()
    CTRL = reaper.ImGui_IsKeyDown(ctx, reaper.ImGui_Key_LeftCtrl()) or reaper.ImGui_IsKeyDown(ctx, reaper.ImGui_Key_RightCtrl())
    SHIFT = reaper.ImGui_IsKeyDown(ctx, reaper.ImGui_Key_LeftShift()) or reaper.ImGui_IsKeyDown(ctx, reaper.ImGui_Key_RightShift())

    --[[if math.floor(reaper.ImGui_GetTime(ctx) % 5) == 0 then
        if not once then
            GetRecentProjects()
            once = true
        end
    else
        once = false
    end]]
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

        local spacing_x_2 = reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing()) * 2
        local quit_w = 10 + spacing_x_2
        local y_pos = 0
        reaper.ImGui_SetCursorPos(ctx, child_width - quit_w - spacing_x_2, y_pos)
        reaper.ImGui_SetCursorPosY(ctx, y_pos)
        if reaper.ImGui_Button(ctx, 'X##quit_button', quit_w) then
            open = false
        end

        reaper.ImGui_PopStyleVar(ctx, 1)
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

local function draw_filled_star(draw_list, cx, cy, outer_r, inner_r, color)
    local points = {}
    local num_points = 5
    local angle_step = math.pi / num_points
    local start_angle = -math.pi / 2

    -- Generate 10 points (outer + inner alternating)
    for i = 0, num_points * 2 - 1 do
        local angle = start_angle + i * angle_step
        local r = (i % 2 == 0) and outer_r or inner_r
        local x = cx + math.cos(angle) * r
        local y = cy + math.sin(angle) * r
        points[i + 1] = {x = x, y = y}
    end

    -- Draw filled triangles for each outer star point
    for i = 1, #points do
        local a = points[i]
        local b = points[(i % #points) + 1]
        reaper.ImGui_DrawList_AddTriangleFilled(draw_list, cx, cy, a.x, a.y, b.x, b.y, color)
    end
end

-- All GUI elements
local function ElementsDisplay()
    -- Search bar
    reaper.ImGui_Text(ctx, "Search:")

    reaper.ImGui_SameLine(ctx)

    reaper.ImGui_PushItemWidth(ctx, -1 - 85)
    changed, project_search = reaper.ImGui_InputText(ctx, "##search_bar", project_search)

    reaper.ImGui_SameLine(ctx)

    reaper.ImGui_PushItemWidth(ctx, -1)
    if reaper.ImGui_BeginCombo(ctx, "##sort_search", Settings.search_type.value) then
        for _, type in ipairs(search_types) do
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
                --changed, project.stared = reaper.ImGui_Checkbox(ctx, "##star_"..tostring(i), project.stared)
                local cx, cy = reaper.ImGui_GetCursorScreenPos(ctx)
                local button_size = 15
                if reaper.ImGui_InvisibleButton(ctx, "##star_"..tostring(i), button_size, button_size) then
                    project.stared = not project.stared
                end
                local hovered = reaper.ImGui_IsItemHovered(ctx)
                local activated = reaper.ImGui_IsItemActivated(ctx)

                reaper.ImGui_SameLine(ctx)

                -- Selectable line
                if not project.exists then reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), 0xFF0000A1) end
                changed, project.selected = reaper.ImGui_Selectable(ctx, project.name, project.selected)
                if not project.exists then reaper.ImGui_PopStyleColor(ctx) end
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
                        if project.exists then
                            if project.selected then
                                project_already_selected = true
                            else
                                project.selected = true
                            end
                            popup_x, popup_y = reaper.ImGui_GetMousePos(ctx)
                            mouse_right_clic_popup = true
                            current_right_clic_project = project
                        else
                            reaper.MB("No file found at path:\n"..project.path, "GASPARD REAPER LAUNCHER ERROR", 0)
                        end
                    end

                    if reaper.ImGui_IsMouseDoubleClicked(ctx, reaper.ImGui_MouseButton_Left()) then
                        for _, j_project in ipairs(project_list) do
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
                        end
                    end
                end

                local outer_r, inner_r = 7, 3.5
                local color = activated and 0xFFFFFFFF or hovered and 0xFFFFFFF1 or project.stared and 0xFFFFFFFF or 0xAAAAAAFF
                draw_filled_star(draw_list, cx + (button_size / 2), cy + (button_size / 1.5), outer_r, inner_r, color)
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
            for _, j_project in ipairs(project_list) do
                if j_project.selected then
                    if j_project.exists then
                        LoadInCurrentTab(j_project.path)
                    else
                        reaper.MB("No file found at path:\n"..j_project.path, "GASPARD REAPER LAUNCHER ERROR", 0)
                        j_project.selected = false
                    end
                end
            end
            if Settings.close_on_open.value then open = false end
        end

        reaper.ImGui_Selectable(ctx, "Load in new tab", false)
        if reaper.ImGui_IsItemActivated(ctx) then
            for _, j_project in ipairs(project_list) do
                if j_project.selected then
                    if j_project.exists then
                        LoadInNewTab(j_project.path)
                    else
                        reaper.MB("No file found at path:\n"..j_project.path, "GASPARD REAPER LAUNCHER ERROR", 0)
                        j_project.selected = false
                    end
                end
            end
            if Settings.close_on_open.value then open = false end
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
