--@noindex
--@description Complete renamer user interface gui settings
--@author gaspard
--@about User interface settings used in gaspard_Complete renamer.lua script

local settings_window = {}

local PANEL_FLAGS = ImGui.WindowFlags_NoCollapse | ImGui.WindowFlags_NoScrollbar | ImGui.WindowFlags_NoResize
    | ImGui.WindowFlags_TopMost | ImGui.WindowFlags_NoDecoration | ImGui.WindowFlags_AlwaysAutoResize

-- Called when the settings panel opens
function settings_window.GetSettings()
end

-- Settings panel (GaspaReaLauncher style: changes are saved immediately)
function settings_window.Show()
    local x, y = Gui_PanelPosition()
    ImGui.SetNextWindowPos(ctx, x, y, ImGui.Cond_Always, 1, 0)
    local settings_visible = ImGui.Begin(ctx, "##settings_window", true, PANEL_FLAGS)
    if settings_visible then
        ImGui.Text(ctx, "SETTINGS")
        ImGui.Separator(ctx)

        local one_changed = false
        for _, key in ipairs(Settings.order) do
            local setting = Settings[key]
            local changed
            changed, setting.value = ImGui.Checkbox(ctx, setting.name .. "##settings_" .. key, setting.value == true)
            if changed then one_changed = true end
            ImGui.SetItemTooltip(ctx, setting.description)
        end
        if one_changed then System.SaveSettings() end

        ImGui.End(ctx)
    else
        show_settings = false
    end
end

return settings_window
