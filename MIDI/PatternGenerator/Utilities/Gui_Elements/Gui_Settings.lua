--@noindex
--@description Pattern generator user interface gui settings
--@author gaspard
--@about User interface settings used in gaspard_Pattern generator.lua script

local settings_window = {}

local function StringToTable(inputString)
    local result = {}
    for line in inputString:gmatch("[^\r\n]+") do
        if line:match("%S") then
            table.insert(result, line)
        end
    end
    return result
end

local function TableToString(inputTable)
    return table.concat(inputTable, "\n")
end

-- Get Settings on show settings window (text buffer for multiline paths input)
function settings_window.GetSettings()
    pattern_folder_paths = TableToString(Settings.pattern_folder_paths.value)
end

-- Gui Settings Elements (GaspaReaLauncher style: under top bar, right aligned, changes saved immediately)
function settings_window.Show()
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

    local changed
    changed, Settings.obey_note_off.value = reaper.ImGui_Checkbox(ctx, Settings.obey_note_off.name .. "##settings_obey_note_off", Settings.obey_note_off.value)
    reaper.ImGui_SetItemTooltip(ctx, Settings.obey_note_off.description)
    if changed then gson.SaveJSON(settings_path, Settings) end

    changed, Settings.release.value = reaper.ImGui_Checkbox(ctx, Settings.release.name .. "##settings_release", Settings.release.value)
    reaper.ImGui_SetItemTooltip(ctx, Settings.release.description)
    if changed then gson.SaveJSON(settings_path, Settings) end

    reaper.ImGui_PushItemWidth(ctx, 60)
    _, Settings.release_amount.value = reaper.ImGui_DragDouble(ctx, Settings.release_amount.name .. '##settings_release_amount', Settings.release_amount.value, 1, 0, math.huge, '%.1f')
    reaper.ImGui_PopItemWidth(ctx)
    reaper.ImGui_SetItemTooltip(ctx, Settings.release_amount.description)
    if reaper.ImGui_IsItemDeactivatedAfterEdit(ctx) then gson.SaveJSON(settings_path, Settings) end

    reaper.ImGui_Text(ctx, Settings.pattern_folder_paths.name .. ":")
    if not pattern_folder_paths then settings_window.GetSettings() end
    _, pattern_folder_paths = reaper.ImGui_InputTextMultiline(ctx, '##multiline_paths', pattern_folder_paths, 330, 120)
    reaper.ImGui_SetItemTooltip(ctx, Settings.pattern_folder_paths.description)
    if reaper.ImGui_IsItemDeactivatedAfterEdit(ctx) then
        Settings.pattern_folder_paths.value = StringToTable(pattern_folder_paths)
        gson.SaveJSON(settings_path, Settings)
        System.ScanPatternFiles()
    end

    reaper.ImGui_End(ctx)
end

return settings_window
