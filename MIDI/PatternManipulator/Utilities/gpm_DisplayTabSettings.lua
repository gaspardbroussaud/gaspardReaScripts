--@noindex
--@description Pattern manipulator utility Display tab settings
--@author gaspard
--@about Pattern manipulator utility

local tab_settings = {}

local item_width = 80

function tab_settings.Show()
    local one_changed = false

    if reaper.ImGui_BeginChild(ctx, 'child_piano_roll', -1, -1, reaper.ImGui_ChildFlags_None()) then
        local changed = false
        -- Project based parent
        reaper.ImGui_Text(ctx, Settings.project_based_parent.name..":")
        reaper.ImGui_SameLine(ctx)
        changed, Settings.project_based_parent.value = reaper.ImGui_Checkbox(ctx, "##project_based_parent", Settings.project_based_parent.value)
        reaper.ImGui_SetItemTooltip(ctx, Settings.project_based_parent.description)
        if changed then one_changed = true end
        local parent_track = gpmsys_samples.GetParentFromSelectedTrack()
        local disabled = not parent_track
        reaper.ImGui_SameLine(ctx)
        if disabled then reaper.ImGui_BeginDisabled(ctx) end
        if reaper.ImGui_Button(ctx, " Set selected sample track parent as project parent ") then
            gpmsys.SetTrackToExtState(parent_track, extname_global, extkey_parent_track)
        end
        if disabled then reaper.ImGui_EndDisabled(ctx) end

        -- Obey note offs
        reaper.ImGui_Text(ctx, Settings.obey_note_off.name..":")
        reaper.ImGui_SameLine(ctx)
        changed, Settings.obey_note_off.value = reaper.ImGui_Checkbox(ctx, "##obey_note_off", Settings.obey_note_off.value)
        reaper.ImGui_SetItemTooltip(ctx, Settings.obey_note_off.description)
        if changed then one_changed = true end

        -- Note nomenclature
        reaper.ImGui_Text(ctx, Settings.note_nomenclature.name..":")
        reaper.ImGui_SameLine(ctx)
        if reaper.ImGui_BeginCombo(ctx, "##combo_note_nomenclature", Settings.note_nomenclature.value[Settings.note_nomenclature.selected_index]) then
            for i = 1, #Settings.note_nomenclature.value do
                if reaper.ImGui_Selectable(ctx, Settings.note_nomenclature.value[i], Settings.note_nomenclature.selected_index == i) then
                    Settings.note_nomenclature.selected_index = i
                    one_changed = true
                end
            end
            reaper.ImGui_EndCombo(ctx)
        end
        reaper.ImGui_SetItemTooltip(ctx, Settings.obey_note_off.description)

        -- ADSR
        reaper.ImGui_Text(ctx, "ADSR default values:")

        reaper.ImGui_SameLine(ctx)
        local Adsr_x = reaper.ImGui_GetCursorPosX(ctx)
        reaper.ImGui_PushItemWidth(ctx, item_width)
        changed, Settings.attack_amount.value = reaper.ImGui_DragDouble(ctx, "##drag_attack", Settings.attack_amount.value, 0.01, 0, 2000, "%.2f ms")
        if reaper.ImGui_IsItemActive(ctx) then shortcut_activated = false end
        reaper.ImGui_SetItemTooltip(ctx, Settings.attack_amount.description)
        if changed then one_changed = true end

        reaper.ImGui_SameLine(ctx)
        local aDsr_x = reaper.ImGui_GetCursorPosX(ctx)
        reaper.ImGui_PushItemWidth(ctx, item_width)
        changed, Settings.decay_amount.value = reaper.ImGui_DragDouble(ctx, "##drag_decay", Settings.decay_amount.value, 1, 10, 15000, "%.0f ms")
        if reaper.ImGui_IsItemActive(ctx) then shortcut_activated = false end
        reaper.ImGui_SetItemTooltip(ctx, Settings.decay_amount.description)
        if changed then one_changed = true end

        reaper.ImGui_SameLine(ctx)
        local adSr_x = reaper.ImGui_GetCursorPosX(ctx)
        reaper.ImGui_PushItemWidth(ctx, item_width)
        local sign = Settings.sustain_amount.value >= 0 and "+" or ""
        changed, Settings.sustain_amount.value = reaper.ImGui_DragDouble(ctx, "##drag_sustain", Settings.sustain_amount.value, 0.1, -120, 12, sign.."%.1f dB")
        if reaper.ImGui_IsItemActive(ctx) then shortcut_activated = false end
        reaper.ImGui_SetItemTooltip(ctx, Settings.sustain_amount.description)
        if changed then one_changed = true end

        reaper.ImGui_SameLine(ctx)
        local adsR_x = reaper.ImGui_GetCursorPosX(ctx)
        reaper.ImGui_PushItemWidth(ctx, item_width)
        changed, Settings.release_amount.value = reaper.ImGui_DragDouble(ctx, "##drag_release", Settings.release_amount.value, 1, 0, 2000, "%.0f ms")
        if reaper.ImGui_IsItemActive(ctx) then shortcut_activated = false end
        reaper.ImGui_SetItemTooltip(ctx, Settings.release_amount.description)
        if changed then one_changed = true end

        reaper.ImGui_SetCursorPosX(ctx, Adsr_x)
        local text_w = reaper.ImGui_CalcTextSize(ctx, "A")
        reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + (item_width - text_w) * 0.5)
        reaper.ImGui_Text(ctx, "A")

        reaper.ImGui_SameLine(ctx)
        reaper.ImGui_SetCursorPosX(ctx, aDsr_x)
        text_w = reaper.ImGui_CalcTextSize(ctx, "D")
        reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + (item_width - text_w) * 0.5)
        reaper.ImGui_Text(ctx, "D")

        reaper.ImGui_SameLine(ctx)
        reaper.ImGui_SetCursorPosX(ctx, adSr_x)
        text_w = reaper.ImGui_CalcTextSize(ctx, "S")
        reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + (item_width - text_w) * 0.5)
        reaper.ImGui_Text(ctx, "S")

        reaper.ImGui_SameLine(ctx)
        reaper.ImGui_SetCursorPosX(ctx, adsR_x)
        text_w = reaper.ImGui_CalcTextSize(ctx, "R")
        reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + (item_width - text_w) * 0.5)
        reaper.ImGui_Text(ctx, "R")

        -- Pattern paths
        reaper.ImGui_Text(ctx, Settings.pattern_folder_paths.name..":")
        reaper.ImGui_SetItemTooltip(ctx, Settings.pattern_folder_paths.description)

        reaper.ImGui_SameLine(ctx)
        local button_w = reaper.ImGui_CalcTextSize(ctx, "Add pattern path")
        if reaper.ImGui_Button(ctx, "Add pattern path", button_w) then
            if added then
                one_changed = true
                gpmsys_patterns.ScanPatternFiles()
            end
        end

        reaper.ImGui_SameLine(ctx)
        local disable = not Settings.pattern_folder_paths.list[1]
        if disable then reaper.ImGui_BeginDisabled(ctx) end
        local button_x, button_y = reaper.ImGui_GetCursorScreenPos(ctx)
        local avail_x = reaper.ImGui_GetContentRegionAvail(ctx)
        reaper.ImGui_SetCursorScreenPos(ctx, button_x + avail_x - 140 - 2, button_y)
        if reaper.ImGui_Button(ctx, "Force pattern scan", 140) then
            gpmsys_patterns.ScanPatternFiles()
        end
        reaper.ImGui_SetItemTooltip(ctx, "Force pattern scan (automatic rescan on paths update).")
        if disable then reaper.ImGui_EndDisabled(ctx) end

        if reaper.ImGui_BeginListBox(ctx, "##pattern_paths", -1, (select(2, reaper.ImGui_CalcTextSize(ctx, "A")) * 2) * #Settings.pattern_folder_paths.list) then
            local max_width = reaper.ImGui_GetContentRegionAvail(ctx) - (reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding()) * 4)
            for i, pattern in ipairs(Settings.pattern_folder_paths.list) do
                local display = tostring(pattern)
                if reaper.ImGui_CalcTextSize(ctx, display) > max_width then
                    local ellipsis = "..."
                    local left, right = 1, #display
                    local left_str, right_str = "", ""

                    while left < right do
                        left_str = display:sub(1, left)
                        right_str = display:sub(right)

                        local test_str = left_str .. ellipsis .. right_str
                        local w = reaper.ImGui_CalcTextSize(ctx, test_str)
                        if w > max_width then
                            break
                        end

                        left = left + 1
                        right = right - 1
                    end

                    display = left_str .. ellipsis .. right_str
                end
                reaper.ImGui_Text(ctx, display)
                reaper.ImGui_SetItemTooltip(ctx, tostring(pattern))
            end
            reaper.ImGui_EndListBox(ctx)
        end
        if changed and 1 > 2 then
            one_changed = true
            gpmsys_patterns.ScanPatternFiles()
        end

        reaper.ImGui_EndChild(ctx)
    end

    if one_changed then gson.SaveJSON(settings_path, Settings) end
end

return tab_settings
