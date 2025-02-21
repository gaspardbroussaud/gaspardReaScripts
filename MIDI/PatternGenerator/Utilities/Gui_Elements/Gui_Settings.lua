--@noindex
--@description Pattern generator user interface gui settings
--@author gaspard
--@about User interface settings used in gaspard_Pattern generator.lua script

local settings_window = {}

local function SetSettings()
    Settings.obey_note_off.value = obey_note_off
    Settings.release.value = release
    Settings.release_amount.value = release_amount
end

-- Get Settings on show settings window
function settings_window.GetSettings()
    settings_one_changed = false
    obey_note_off = Settings.obey_note_off.value
    release = Settings.release.value
    release_amount = Settings.release_amount.value
end

-- Gui Settings Elements
function settings_window.Show()
    -- Set Settings Window visibility and settings
    local settings_flags = reaper.ImGui_WindowFlags_NoCollapse() | reaper.ImGui_WindowFlags_NoScrollbar() | reaper.ImGui_WindowFlags_NoResize()
    local settings_width = 250
    local settings_height = 190
    reaper.ImGui_SetNextWindowSize(ctx, settings_width, settings_height, reaper.ImGui_Cond_Once())
    reaper.ImGui_SetNextWindowPos(ctx, window_x + (window_width - settings_width) * 0.5, window_y + 10, reaper.ImGui_Cond_Appearing())

    local settings_visible, settings_open  = reaper.ImGui_Begin(ctx, 'SETTINGS', true, settings_flags)
    if settings_visible then
        if reaper.ImGui_BeginChild(ctx, "child_settings_window", settings_width - 16, settings_height - 74, reaper.ImGui_ChildFlags_Border()) then
            reaper.ImGui_Text(ctx, Settings.obey_note_off.name..":")
            reaper.ImGui_SameLine(ctx)
            changed, obey_note_off = reaper.ImGui_Checkbox(ctx, "##settings_obey_note_off", obey_note_off)
            reaper.ImGui_SetItemTooltip(ctx, Settings.obey_note_off.description)
            if changed then settings_one_changed = true end

            reaper.ImGui_Text(ctx, Settings.release.name..":")
            reaper.ImGui_SameLine(ctx)
            changed, release = reaper.ImGui_Checkbox(ctx, "##settings_release", release)
            reaper.ImGui_SetItemTooltip(ctx, Settings.release.description)
            if changed then settings_one_changed = true end

            reaper.ImGui_Text(ctx, Settings.release_amount.name..":")
            reaper.ImGui_SameLine(ctx)
            reaper.ImGui_PushItemWidth(ctx, 60)
            changed, release_amount = reaper.ImGui_DragDouble(ctx, '##settings_release_amount', release_amount, 1, 0, math.huge, '%.0f')
            reaper.ImGui_SetItemTooltip(ctx, Settings.release_amount.description)
            if changed then settings_one_changed = true end

            reaper.ImGui_EndChild(ctx)
        end

        reaper.ImGui_SetCursorPosX(ctx, settings_width - 80)
        reaper.ImGui_SetCursorPosY(ctx, settings_height - 35)
        local disable = not settings_one_changed
        if disable then reaper.ImGui_BeginDisabled(ctx) end
        if reaper.ImGui_Button(ctx, "Apply##settings_apply", 70) then
            SetSettings()
            gson.SaveJSON(settings_path, Settings)
            settings_one_changed = false
        end
        if disable then reaper.ImGui_EndDisabled(ctx) end

        reaper.ImGui_End(ctx)
    else
        show_settings = false
    end

    if not settings_open then
        settings_one_changed = false
        show_settings = false
        System.focus_main_window = true
    end
end

return settings_window
