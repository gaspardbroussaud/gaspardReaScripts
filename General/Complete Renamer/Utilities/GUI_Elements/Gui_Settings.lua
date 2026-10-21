--@noindex
--@description Complete renamer user interface gui settings
--@author gaspard
--@about User interface settings used in gaspard_Complete renamer.lua script

local settings_window = {}

local temp_values = {}
local settings_one_changed = false

-- Get Settings on show settings window
function settings_window.GetSettings()
    settings_one_changed = false
    temp_values = {}
    for _, key in ipairs(Settings.order) do
        temp_values[key] = Settings[key].value
    end
end

local function SetSettings()
    for _, key in ipairs(Settings.order) do
        Settings[key].value = temp_values[key]
    end
    System.SaveSettings()
end

-- Gui Settings Elements
function settings_window.Show()
    local settings_flags = ImGui.WindowFlags_NoCollapse | ImGui.WindowFlags_NoScrollbar | ImGui.WindowFlags_NoResize
    local settings_width = 210
    local settings_height = 200
    ImGui.SetNextWindowSize(ctx, settings_width, settings_height, ImGui.Cond_Once)
    ImGui.SetNextWindowPos(ctx, window_x + (window_width - settings_width) * 0.5, window_y + 10, ImGui.Cond_Appearing)

    local settings_visible, settings_open = ImGui.Begin(ctx, 'SETTINGS', true, settings_flags)
    if settings_visible then
        if ImGui.BeginChild(ctx, "child_settings_window", settings_width - 16, settings_height - 74, ImGui.ChildFlags_Borders) then
            for _, key in ipairs(Settings.order) do
                local setting = Settings[key]
                ImGui.Text(ctx, setting.name .. ":")
                ImGui.SameLine(ctx)
                local changed
                changed, temp_values[key] = ImGui.Checkbox(ctx, "##settings_" .. key, temp_values[key] == true)
                ImGui.SetItemTooltip(ctx, setting.description)
                if changed then settings_one_changed = true end
            end
            ImGui.EndChild(ctx)
        end

        ImGui.SetCursorPosX(ctx, settings_width - 80)
        ImGui.SetCursorPosY(ctx, settings_height - 35)
        local disable = not settings_one_changed
        if disable then ImGui.BeginDisabled(ctx) end
        if ImGui.Button(ctx, "APPLY##settings_apply", 70) then
            SetSettings()
            settings_one_changed = false
        end
        if disable then ImGui.EndDisabled(ctx) end

        ImGui.End(ctx)
    end

    if not settings_open then
        settings_one_changed = false
        show_settings = false
        System.focus_main_window = true
    end
end

return settings_window
