--@description Master settings
--@author gaspard
--@version 1.1.12
--@changelog
--  - GaspaReaLauncher GUI style (icon top bar, floating settings panel)
--@about
--  ### Master settings
--  All settings for all gaspard's scripts
--  How to:
--      - Choose a script (type or scroll)
--      - Set your settings
--      - Apply changes

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

-- Init system variables
function InitSystemVariables()
    local json_file_path = reaper.GetResourcePath().."/Scripts/Gaspard ReaScripts/JSON"
    package.path = package.path .. ";" .. json_file_path .. "/?.lua"
    gson = require("json_utilities_lib")
end

-- Get script version with ReaPack (fallback: @version of this file)
function GetOwnScriptVersion()
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

-- Recursive function to get all .json settings files from Scripts folder
function ListLuaFilesRecursive(directory, files, files_path)
    files = files or {}
    files_path = files_path or {}

    local file_index, dir_index = 0, 0
    local file = reaper.EnumerateFiles(directory, file_index)
    local subdir = reaper.EnumerateSubdirectories(directory, dir_index)

    -- Look for file in current folder
    while file do
        if file:match("%_settings.json$") and file:match("^gaspard_") then
            table.insert(files_path, directory .. "/" .. file)
            file = string.gsub(file, "%_settings.json$", ".lua")
            table.insert(files, file)
        end
        file_index = file_index + 1
        file = reaper.EnumerateFiles(directory, file_index)
    end

    -- Go through folders
    while subdir do
        ListLuaFilesRecursive(directory .. "/" .. subdir, files, files_path)
        dir_index = dir_index + 1
        subdir = reaper.EnumerateSubdirectories(directory, dir_index)
    end

    return files, files_path
end

-- Get all script folders
function GetScriptFiles()
    local folder_path = reaper.GetResourcePath() .. "/Scripts/Gaspard ReaScripts"
    local json_files, json_path = ListLuaFilesRecursive(folder_path)
    local scripts_list = {}

    for i = 1, #json_files do
        table.insert(scripts_list, { name = json_files[i], path = json_path[i], selected = false })
        table.insert(hover_start_time, 0)
    end

    table.sort(scripts_list, function(a, b)
        return a.name < b.name
    end)

    return scripts_list
end

-- All initial variable for script and GUI
function InitialVariables()
    InitSystemVariables()
    -- Get script version with Reapack (fallback: file @version)
    version = GetOwnScriptVersion()
    -- All script variables
    script_version = ""
    og_window_width = 500
    og_window_height = 400
    min_width, min_height = 320, 250
    max_width, max_height = 1920, 1080
    window_width, window_height = og_window_width, og_window_height
    window_x, window_y = 0, 0
    topbar_height = 30
    font_size = 16
    icon_size = 22
    window_name = "MASTER SETTINGS"
    project_name = reaper.GetProjectName(0)
    project_path = reaper.GetProjectPath()
    project_id, _ = reaper.EnumProjects(-1)
    Settings = {}
    hover_start_time = {}
    scripts = GetScriptFiles()
    script_name = ""
    was_opened = false
    input_active = false
    no_scrollbar_flags = reaper.ImGui_WindowFlags_NoScrollWithMouse() | reaper.ImGui_WindowFlags_NoScrollbar()
    show_more = false
end

-- Split input text in multiple words (space between in orginial text)
function SplitIntoWords(text)
    local words = {}
    for word in text:gmatch("%S+") do
        table.insert(words, word)
    end
    return words
end

-- Check for word matches in script names with input text
function MatchesAllWords(words, text)
    for _, word in ipairs(words) do
        if not text:lower():find(word:lower(), 1, true) then
            return false
        end
    end
    return true
end

-- Remove empty lines from a string
function RemoveMultilineEmptyLines(text)
    local result = {}
    for line in text:gmatch("([^\n]*)\n?") do
        if line:match("%S") then table.insert(result, line) end
    end
    return table.concat(result, "\n")
end

-- Close input popup and reset script name
function CloseInputPopup()
    open_popup = false
    if script_name == "" then
        for i = 1, #scripts do
            if scripts[i].selected then script_name = scripts[i].name end
        end
    end
end

-- Get selected script installed version
function GetScriptVersion(script_path)
    script_path = script_path:gsub("\\", "/")
    script_path = script_path:gsub(".json", ".lua")
    script_path = script_path:gsub("_settings", "")
    script_path = script_path:gsub("Utilities/", "")
    script_version = ""
    local pkg = reaper.ReaPack_GetOwner and reaper.ReaPack_GetOwner(script_path)
    if pkg then
        script_version = tostring(select(7, reaper.ReaPack_GetEntryInfo(pkg)))
        reaper.ReaPack_FreeEntry(pkg)
    end
    if script_version == "nil" then script_version = "" end
    if script_version ~= "" then script_version = "v"..script_version end
    return tostring(script_version)
end

-- Tooltip with stationary delay
function ShowTooltipWithDelay(i, text, delay)
    if hover_start_time[i] == 0 and reaper.ImGui_IsItemHovered(ctx, reaper.ImGui_HoveredFlags_Stationary()) then
        hover_start_time[i] = current_time
    elseif reaper.ImGui_IsItemHovered(ctx, reaper.ImGui_HoveredFlags_Stationary()) then
        if (current_time - hover_start_time[i]) >= delay then
            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(), 0xCCFFFFFF)
            reaper.ImGui_SetTooltip(ctx, text)
            reaper.ImGui_PopStyleColor(ctx)
        end
    else
        hover_start_time[i] = 0
    end
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
    table.insert(menu, {icon = 'GEAR', hint = 'More (manage settings files)', font = icon_font, size = icon_size, right_click = false})
    table.insert(menu, {icon = 'REFRESH_ARROW', hint = 'Refresh', font = icon_font, size = icon_size, right_click = false})
    local rv, button = GUI_SYS.IconButtonRight(ctx, menu, window_width)
    if rv then
        if button == 'QUIT' then
            open = false
        elseif button == 'GEAR' then
            open_popup = false
            show_more = not show_more
        elseif button == 'REFRESH_ARROW' then
            local current_script_path = script_path
            scripts = GetScriptFiles()
            local script_found = false
            for i, script in ipairs(scripts) do
                if script.path == current_script_path then
                    script_found = true
                end
            end
            if not script_found then
                script_name = ""
                script_path = nil
                script_selected = false
                one_changed = false
                open_popup = false
            end
        end
    end
    reaper.ImGui_EndGroup(ctx)

    -- Close input popup if clic on topbar
    if open_popup and reaper.ImGui_IsItemHovered(ctx) and reaper.ImGui_IsMouseClicked(ctx, reaper.ImGui_MouseButton_Left()) then
        CloseInputPopup()
    end
end

-- Gui Elements
function Gui_Elements()
    local child_main_x = window_width - 20
    local _, avail_y = reaper.ImGui_GetContentRegionAvail(ctx)
    local child_main_y = avail_y - 10
    reaper.ImGui_Indent(ctx, 2) -- 10px margin without SetCursorPos (needs no trailing item)
    if reaper.ImGui_BeginChild(ctx, "child_main_elements", child_main_x, child_main_y, reaper.ImGui_ChildFlags_Borders(), no_scrollbar_flags) then
        reaper.ImGui_PushItemWidth(ctx, -1)
        -- Input search text
        if was_opened then
            script_name = ""
            reaper.ImGui_SetKeyboardFocusHere(ctx)
            was_opened = false
            open_popup = true
        end
        changed, script_name = reaper.ImGui_InputText(ctx, "##input_script_name", script_name)
        input_active = reaper.ImGui_IsItemActive(ctx)

        if reaper.ImGui_IsItemActivated(ctx) and #scripts > 0 and not open_popup then
            was_opened = true
            reaper.ImGui_SetKeyboardFocusHere(ctx)
        end

        if reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_Escape()) then
            CloseInputPopup()
        end
        local pos_x, pos_y = reaper.ImGui_GetWindowPos(ctx)
        pos_x = pos_x + reaper.ImGui_GetCursorPosX(ctx)
        pos_y = pos_y + reaper.ImGui_GetCursorPosY(ctx)

        if open_popup then
            local rect_w, _ = reaper.ImGui_GetItemRectSize(ctx)
            local rect_h = #scripts * 24 + 22 * 0.35
            if rect_h < 3 * 24 + 22 * 0.35 then rect_h = 3 * 24 + 22 * 0.35 end
            if rect_h > 6 * 24 + 22 * 0.35 then rect_h = 6 * 24 + 22 * 0.35 end
            reaper.ImGui_SetNextWindowPos(ctx, pos_x, pos_y)
            reaper.ImGui_SetNextWindowSize(ctx, rect_w, rect_h)
            if reaper.ImGui_Begin(ctx, "##popup_search_script", true, reaper.ImGui_WindowFlags_NoFocusOnAppearing() | reaper.ImGui_WindowFlags_NoDecoration()) then
                if reaper.ImGui_BeginListBox(ctx, "##listbox_scripts", rect_w - 15, rect_h - 16) then
                    -- Split text input into words
                    local input_words = SplitIntoWords(script_name)

                    for i = 1, #scripts do
                        -- Filter scripts with name input (not starts with)
                        if script_name == "" or MatchesAllWords(input_words, scripts[i].name) then --string.find(scripts[i].name, script_name, 1) then
                            -- Selectable in listbox for scripts
                            changed, scripts[i].selected = reaper.ImGui_Selectable(ctx, scripts[i].name.."##script_selectable_"..tostring(i), scripts[i].selected)
                            if changed then
                                scripts[i].selected = true
                                open_popup = false
                                for j = 1, #scripts do
                                    if scripts[j].selected and j ~= i then scripts[j].selected = false end
                                end
                                script_name = scripts[i].name
                                script_path = scripts[i].path
                                script_selected = true
                                one_changed = false
                                script_version = GetScriptVersion(script_path)
                                Settings = gson.LoadJSON(script_path)
                            end

                            ShowTooltipWithDelay(i, scripts[i].name, 0.75)
                        end
                    end
                    reaper.ImGui_EndListBox(ctx)
                end
                reaper.ImGui_End(ctx)
            end
        end

        local _, y = reaper.ImGui_GetContentRegionAvail(ctx)
        if reaper.ImGui_BeginChild(ctx, "child_script_settings", -1, y - 35) then
            -- Close input popup if clic focus on topbar 
            if reaper.ImGui_IsWindowFocused(ctx) and open_popup then
                CloseInputPopup()
            end
            if script_selected then
                reaper.ImGui_Dummy(ctx, 1, 10)

                reaper.ImGui_Text(ctx, "SETTINGS "..script_version)
                reaper.ImGui_Dummy(ctx, 1, 5)

                -- Go through in "order"
                for _, key in ipairs(Settings.order) do
                    if Settings[key] and not Settings[key]["ignore"] then
                        -- Display variable name
                        reaper.ImGui_Text(ctx, Settings[key]["name"]..":")
                        reaper.ImGui_SameLine(ctx)

                        local type_var = type(Settings[key]["value"])
                        -- Boolean display
                        if type_var == "boolean" then
                            changed, Settings[key]["value"] = reaper.ImGui_Checkbox(ctx, "##checkbox_"..key.."_value", Settings[key]["value"])
                            if changed then
                                if Settings[key]["dependencies"] then
                                    for dep_key, _ in pairs(Settings[key]["dependencies"]) do
                                        local key_to_check = Settings[key]["dependencies"][dep_key]["variable"]
                                        if Settings[key_to_check]["value"] ~= Settings[key]["dependencies"][dep_key]["value"] then
                                            if Settings[key]["dependencies"][dep_key]["self"] == Settings[key]["value"] then
                                                Settings[key_to_check]["value"] = Settings[key]["dependencies"][dep_key]["value"]
                                            end
                                        end
                                    end
                                end
                                if Settings[key]["influences"] then
                                    for dep_key, _ in pairs(Settings[key]["influences"]) do
                                        local key_to_check = Settings[key]["influences"][dep_key]["variable"]
                                        if Settings[key_to_check]["value"] ~= Settings[key]["influences"][dep_key]["value"] then
                                            if Settings[key]["influences"][dep_key]["self"] == Settings[key]["value"] then
                                                Settings[key_to_check]["value"] = Settings[key]["influences"][dep_key]["value"]
                                            end
                                        end
                                    end
                                end
                                one_changed = true
                            end
                            reaper.ImGui_SetItemTooltip(ctx, Settings[key]["description"])
                        -- String display
                        elseif type_var == "string" then
                            reaper.ImGui_PushItemWidth(ctx, -1)
                            local char_type = reaper.ImGui_InputTextFlags_None()
                            if Settings[key]["char_type"] then char_type = Settings[key]["char_type"] end
                            if Settings[key]["multiline"] then
                                if Settings[key]["multiline"]["remove_empty_lines"] then
                                    Settings[key]["value"] = RemoveMultilineEmptyLines(Settings[key]["value"])
                                end
                                changed, Settings[key]["value"] = reaper.ImGui_InputTextMultiline(ctx, "##inputtext_"..key, Settings[key]["value"], nil, nil, char_type)
                            else
                                changed, Settings[key]["value"] = reaper.ImGui_InputText(ctx, "##inputtext_"..key, Settings[key]["value"], char_type)
                            end
                            reaper.ImGui_SetItemTooltip(ctx, Settings[key]["description"])
                            reaper.ImGui_PopItemWidth(ctx)
                            if changed then one_changed = true end
                        -- Number display
                        elseif type_var == "number" then
                            local drag_min = -math.huge
                            local drag_max = math.huge
                            local drag_format = "%.2f"
                            if Settings[key]["min"] then drag_min = Settings[key]["min"] end
                            if Settings[key]["max"] then drag_max = Settings[key]["max"] end
                            if Settings[key]["format"] then drag_format = Settings[key]["format"] end
                            changed, Settings[key]["value"] = reaper.ImGui_DragDouble(ctx, "##drag_"..key, Settings[key]["value"], 0.1, drag_min, drag_max, drag_format)
                            if changed then one_changed = true end
                            reaper.ImGui_SetItemTooltip(ctx, Settings[key]["description"])
                        end
                    end
                end
            end
            reaper.ImGui_EndChild(ctx)
        end

        local button_x = 100
        local button_pos_y = child_main_y - 30
        local x, _ = reaper.ImGui_GetContentRegionAvail(ctx)
        if not one_changed then disable = true
        else disable = false end
        if disable then reaper.ImGui_BeginDisabled(ctx) end
        reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + x - button_x)
        reaper.ImGui_SetCursorPosY(ctx, button_pos_y)
        if reaper.ImGui_Button(ctx, "APPLY##apply_button", button_x) then
            gson.SaveJSON(script_path, Settings)
            one_changed = false
        end
        if disable then reaper.ImGui_EndDisabled(ctx) end

        reaper.ImGui_EndChild(ctx)
    end
    reaper.ImGui_Unindent(ctx, 2)
end

-- Gui settings
function Gui_More()
    -- Set Settings Window visibility and settings
    local more_flags = reaper.ImGui_WindowFlags_NoCollapse() | reaper.ImGui_WindowFlags_NoScrollbar() | reaper.ImGui_WindowFlags_NoResize()
    local more_width = og_window_width - 80
    local more_height = og_window_height * 0.7
    reaper.ImGui_SetNextWindowSize(ctx, more_width, more_height, reaper.ImGui_Cond_Once())
    reaper.ImGui_SetNextWindowPos(ctx, window_x + (window_width - more_width) * 0.5, window_y + 10, reaper.ImGui_Cond_Appearing())

    local more_visible, more_open  = reaper.ImGui_Begin(ctx, 'MORE', true, more_flags)
    if more_visible then
        local scripts_more = scripts
        reaper.ImGui_PushItemWidth(ctx, -1 - 65)
        changed, script_name_more = reaper.ImGui_InputText(ctx, "##input_script_name_more", script_name_more)
        local rect_w, _ = reaper.ImGui_GetItemRectSize(ctx)
        rect_w = rect_w + 65
        local rect_h = 7 * 24 + 22 * 0.35

        reaper.ImGui_SameLine(ctx)
        if reaper.ImGui_Button(ctx, 'Refresh##refresh_button') then
            local current_script_path = script_path
            scripts = GetScriptFiles()
            local script_found = false
            for i, script in ipairs(scripts) do
                if script.path == current_script_path then
                    script_found = true
                end
            end
            if not script_found then
                script_name = ""
                script_path = nil
                script_selected = false
                one_changed = false
            end
        end

        if reaper.ImGui_BeginChild(ctx, "##child_scripts_delete", rect_w, rect_h, reaper.ImGui_ChildFlags_Borders()) then
            -- Split text input into words
            local input_words = SplitIntoWords(script_name_more)

            for i = 1, #scripts_more do
                -- Filter scripts with name input (not starts with)
                if script_name_more == "" or MatchesAllWords(input_words, scripts_more[i].name) then
                    -- Selectable for scripts in more window
                    local last_state = scripts_more[i].selected
                    changed, scripts_more[i].selected = reaper.ImGui_Selectable(ctx, scripts_more[i].name.."##script_more_selectable_"..tostring(i), scripts_more[i].selected)
                    if changed then
                        if not reaper.ImGui_IsKeyDown(ctx, reaper.ImGui_Key_LeftCtrl()) then
                            for j = 1, #scripts_more do
                                if scripts_more[j].selected and j ~= i then scripts_more[j].selected = false end
                            end
                        else
                            if last_state and not scripts_more[i].selected then scripts_more[i].selected = true end
                        end
                    end
                end
            end
            reaper.ImGui_EndChild(ctx)
        end

        reaper.ImGui_Dummy(ctx, 1, 4)

        reaper.ImGui_SetCursorPosX(ctx, more_width - 110)
        if reaper.ImGui_Button(ctx, "DELETE##more_delete_button", 100) then
            for i, script in ipairs(scripts_more) do
                if script.selected then
                    if script.path == script_path then
                        script_name = ""
                        script_selected = false
                        one_changed = false
                        open_popup = false
                    end
                    os.remove(script.path)
                    scripts = GetScriptFiles()
                end
            end
            --[[scripts = GetScriptFiles()
            for i = 1, #scripts do
                os.remove(scripts[i].path)
            end
            scripts = GetScriptFiles()
            script_name = ""
            script_selected = false
            one_changed = false]]
        end

        reaper.ImGui_End(ctx)
    else
        show_more = false
    end

    if not more_open then
        show_more = false
    end
end

-- GUI function for all elements
function Gui_Loop()
    Gui_PushTheme()
    -- Window Settings
    local window_flags = reaper.ImGui_WindowFlags_NoCollapse() | reaper.ImGui_WindowFlags_NoTitleBar() | reaper.ImGui_WindowFlags_NoScrollWithMouse()
    reaper.ImGui_SetNextWindowSize(ctx, window_width, window_height, reaper.ImGui_Cond_Once())
    reaper.ImGui_SetNextWindowSizeConstraints(ctx, min_width, min_height, max_width, max_height)
    -- Font
    reaper.ImGui_PushFont(ctx, font, font_size)
    -- Begin
    visible, open = reaper.ImGui_Begin(ctx, window_name, true, window_flags)
    window_x, window_y = reaper.ImGui_GetWindowPos(ctx)
    temp_win_width, temp_win_height = window_width, window_height
    window_width, window_height = reaper.ImGui_GetWindowSize(ctx)
    if window_width ~= temp_win_width or window_height ~= temp_win_height then
        CloseInputPopup()
    end

    current_time = reaper.ImGui_GetTime(ctx)

    if visible then
        -- Top bar elements
        Gui_TopBar()

        -- Gui more elements
        if show_more then
            Gui_More()
        end

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

-- Main script execution
SetButtonState(1)
Gui_Init()
Gui_Loop()
reaper.atexit(SetButtonState)
