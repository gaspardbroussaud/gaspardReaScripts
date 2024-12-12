--@description Master settings
--@author gaspard
--@version 1.0.4
--@changelog
--  - Bugfix
--@about
--  ### Master settings
--  All settings for all gaspard's scripts
--  How to:
--      - Choose a script (type or scroll)
--      - Set your settings
--      - Apply changes

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

    --Settings = gson.LoadJSON(scripts[i].path)
end

-- Get GUI style from file
function GetGuiStylesFromFile()
    local gui_style_settings_path = reaper.GetResourcePath().."/Scripts/Gaspard ReaScripts/GUI/GUI_Style_Settings.lua"
    local style = dofile(gui_style_settings_path)
    style_vars = style.vars
    style_colors = style.colors
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
    end

    return scripts_list
end

-- All initial variable for script and GUI
function InitialVariables()
    InitSystemVariables()
    GetGuiStylesFromFile()
    version = "1.0"
    window_width = 500
    window_height = 400
    topbar_height = 30
    font_size = 16
    window_name = "MASTER SETTINGS"
    project_name = reaper.GetProjectName(0)
    project_path = reaper.GetProjectPath()
    project_id, _ = reaper.EnumProjects(-1)
    Settings = {}
    scripts = GetScriptFiles()
    script_name = ""
    was_opened = false
    input_active = false
    no_scrollbar_flags = reaper.ImGui_WindowFlags_NoScrollWithMouse() | reaper.ImGui_WindowFlags_NoScrollbar()
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

-- GUI Initialize function
function Gui_Init()
    InitialVariables()
    ctx = reaper.ImGui_CreateContext('random_play_context')
    font = reaper.ImGui_CreateFont('sans-serif', font_size)
    small_font = reaper.ImGui_CreateFont('sans-serif', font_size * 0.75, reaper.ImGui_FontFlags_Italic())
    reaper.ImGui_Attach(ctx, font)
    reaper.ImGui_Attach(ctx, small_font)
end

-- GUI Top Bar
function Gui_TopBar()
    -- GUI Menu Bar
    if reaper.ImGui_BeginChild(ctx, "child_top_bar", window_width, topbar_height, reaper.ImGui_ChildFlags_None(), no_scrollbar_flags) then
        -- Close input popup if clic focus on topbar 
        if reaper.ImGui_IsWindowFocused(ctx) and open_popup then
            CloseInputPopup()
        end

        reaper.ImGui_Text(ctx, window_name)

        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(), 5, 0)

        reaper.ImGui_SameLine(ctx)

        local w, _ = reaper.ImGui_CalcTextSize(ctx, "X")
        reaper.ImGui_SetCursorPos(ctx, reaper.ImGui_GetWindowWidth(ctx) - w - 30, 0)

        if reaper.ImGui_BeginChild(ctx, "child_top_bar_buttons", w + 30, 22, reaper.ImGui_ChildFlags_None(), no_scrollbar_flags) then
            reaper.ImGui_Dummy(ctx, 3, 1)
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
    local child_main_x = window_width - 20
    local child_main_y = window_height - topbar_height - (font_size * 0.75) - 30
    reaper.ImGui_SetCursorPosX(ctx, 10)
    if reaper.ImGui_BeginChild(ctx, "child_main_elements", child_main_x, child_main_y, reaper.ImGui_ChildFlags_Border(), no_scrollbar_flags) then
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
            if rect_h < 1 * 24 + 22 * 0.35 then rect_h = 1 * 24 + 22 * 0.35 end
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
                                Settings = gson.LoadJSON(script_path)
                            end
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

                reaper.ImGui_Text(ctx, "SETTINGS")
                reaper.ImGui_Dummy(ctx, 1, 5)

                -- Go through in "order"
                for _, key in ipairs(Settings.order) do
                    if Settings[key] then
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
                            if Settings[key]["multiline"] then
                                if Settings[key]["multiline"]["remove_empty_lines"] then
                                    Settings[key]["value"] = RemoveMultilineEmptyLines(Settings[key]["value"])
                                end
                                changed, Settings[key]["value"] = reaper.ImGui_InputTextMultiline(ctx, "##inputtext_"..key.."_value", Settings[key]["value"], nil, nil, Settings[key]["char_type"])
                            else
                                changed, Settings[key]["value"] = reaper.ImGui_InputText(ctx, "##inputtext_"..key.."_value", Settings[key]["value"], Settings[key]["char_type"])
                            end
                            reaper.ImGui_SetItemTooltip(ctx, Settings[key]["description"])
                            reaper.ImGui_PopItemWidth(ctx)
                            if changed then one_changed = true end
                        -- Number display
                        elseif type_var == "number" then
                            changed, Settings[key]["value"] = reaper.ImGui_DragDouble(ctx, "##drag_"..key.."_value", Settings[key]["value"], 0.1, Settings[key]["min"], Settings[key]["max"], Settings[key]["format"])
                            if changed then one_changed = true end
                            reaper.ImGui_SetItemTooltip(ctx, Settings[key]["description"])
                        end
                    end
                end
            end
            reaper.ImGui_EndChild(ctx)
        end

        local x, _ = reaper.ImGui_GetContentRegionAvail(ctx)
        local button_x = 100
        if not one_changed then disable = true
        else disable = false end
        if disable then reaper.ImGui_BeginDisabled(ctx) end
        reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + x - button_x)
        if reaper.ImGui_Button(ctx, "APPLY##apply_button", button_x) then
            gson.SaveJSON(script_path, Settings)
            one_changed = false
        end
        if disable then reaper.ImGui_EndDisabled(ctx) end

        reaper.ImGui_EndChild(ctx)
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
    local window_flags = reaper.ImGui_WindowFlags_NoCollapse() | reaper.ImGui_WindowFlags_NoTitleBar() | reaper.ImGui_WindowFlags_NoScrollWithMouse()
    reaper.ImGui_SetNextWindowSize(ctx, window_width, window_height, reaper.ImGui_Cond_Once())
    -- Font
    reaper.ImGui_PushFont(ctx, font)
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

-- Main script execution
SetButtonState(1)
Gui_Init()
Gui_Loop()
reaper.atexit(SetButtonState)