--@noindex
--@description ImGui Template
--@author gaspard
--@version 1.1.0
--@changelog
--  - GaspaReaLauncher GUI style (GUI_STYLE / GUI_SYS libraries, icon top bar, floating settings panel)
--@about
--  ### Title
--  - All infos for user

-- Load Utilities
dofile(reaper.GetResourcePath() .. '/Scripts/ReaTeam Extensions/API/imgui.lua')('0.10.0.1')

-- gaspard libraries: JSON, GUI style and GUI system (icon buttons)
local json_file_path = reaper.GetResourcePath() .. '/Scripts/Gaspard ReaScripts/JSON'
package.path = package.path .. ';' .. json_file_path .. '/?.lua'
gson = require('json_utilities_lib')
GUI_STYLE = dofile(reaper.GetResourcePath() .. "/Scripts/Gaspard ReaScripts/Libraries/GUI_STYLE.lua")
GUI_SYS = dofile(reaper.GetResourcePath() .. "/Scripts/Gaspard ReaScripts/Libraries/GUI_SYS.lua")

-- Toggle button state in Reaper
function SetButtonState(set)
    local _, name, sec, cmd, _, _, _ = reaper.get_action_context()
    action_name = string.match(name, "gaspard_(.-)%.lua") or "ImGui Template"
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

-- Settings saved in json next to the script
function InitSettings()
    settings_path = debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]] .. 'gaspard_' .. action_name .. '_settings.json'
    local default_settings = {
        version = "0.0.1",
        order = {"example_bool"},
        example_bool = {
            value = false,
            name = "Example setting",
            description = "Tooltip description."
        }
    }
    Settings = gson.LoadJSON(settings_path, default_settings)
    if not Settings.version or Settings.version ~= default_settings.version then
        Settings = gson.CompleteUpdate(settings_path, Settings, default_settings, {})
    end
end

-- All initial variable for script and GUI
function InitialVariables()
    version = GetScriptVersion()
    -- All script variables
    og_window_width = 300
    og_window_height = 235
    min_width, min_height = 300, 150
    window_width = og_window_width
    window_height = og_window_height
    window_x, window_y = 0, 0
    topbar_height = 30
    font_size = 16
    icon_size = 22
    window_name = "TEMPLATE IMGUI"
    project_name = reaper.GetProjectName(0)
    project_path = reaper.GetProjectPath()
    project_id, _ = reaper.EnumProjects(-1)
    no_scrollbar_flags = reaper.ImGui_WindowFlags_NoScrollWithMouse() | reaper.ImGui_WindowFlags_NoScrollbar()
    show_settings = false
end

-- GUI Initialize function
function Gui_Init()
    InitialVariables()
    ctx = reaper.ImGui_CreateContext('gaspard_imgui_template_ctx')
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
    local child_main_x, child_main_y = reaper.ImGui_GetContentRegionAvail(ctx)
    if reaper.ImGui_BeginChild(ctx, "child_example_elements", child_main_x, child_main_y) then
        reaper.ImGui_Text(ctx, "Text example")

        reaper.ImGui_SameLine(ctx)

        reaper.ImGui_TextDisabled(ctx, "(?)")

        if reaper.ImGui_IsItemHovered(ctx, reaper.ImGui_HoveredFlags_Stationary()) then
            reaper.ImGui_SetTooltip(ctx, "Tooltip example.")
        end

        reaper.ImGui_Dummy(ctx, 10, 10)

        reaper.ImGui_Text(ctx, tostring(current_time))

        reaper.ImGui_EndChild(ctx)
    end
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
        if type(setting.value) == "boolean" then
            local changed
            changed, setting.value = reaper.ImGui_Checkbox(ctx, setting.name .. "##setting_" .. key, setting.value)
            if changed then one_changed = true end
            reaper.ImGui_SetItemTooltip(ctx, setting.description)
        end
    end
    if one_changed then gson.SaveJSON(settings_path, Settings) end

    reaper.ImGui_End(ctx)
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

-- GUI function for all elements
function Gui_Loop()
    Gui_PushTheme()
    -- Window Settings
    local window_flags = reaper.ImGui_WindowFlags_NoCollapse() | reaper.ImGui_WindowFlags_NoTitleBar() | no_scrollbar_flags
    reaper.ImGui_SetNextWindowSize(ctx, window_width, window_height, reaper.ImGui_Cond_Once())
    reaper.ImGui_SetNextWindowSizeConstraints(ctx, min_width, min_height, math.huge, math.huge)
    -- Font
    reaper.ImGui_PushFont(ctx, font, font_size)
    -- Begin
    visible, open = reaper.ImGui_Begin(ctx, window_name, true, window_flags)
    window_x, window_y = reaper.ImGui_GetWindowPos(ctx)
    window_width, window_height = reaper.ImGui_GetWindowSize(ctx)

    current_time = reaper.ImGui_GetTime(ctx)

    if visible then
        -- Top bar elements
        Gui_TopBar()

        -- Settings panel
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

-- Main script execution
SetButtonState(1)
InitSettings()
Gui_Init()
Gui_Loop()
reaper.atexit(SetButtonState)

-- TEMPLATE CODE FOR IMPORT
--[[
GUI_STYLE = dofile(reaper.GetResourcePath() .. "/Scripts/Gaspard ReaScripts/Libraries/GUI_STYLE.lua")
GUI_SYS = dofile(reaper.GetResourcePath() .. "/Scripts/Gaspard ReaScripts/Libraries/GUI_SYS.lua")

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
]]
