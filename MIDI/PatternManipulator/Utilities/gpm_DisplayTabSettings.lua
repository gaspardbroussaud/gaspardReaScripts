--@noindex

local tab_settings = {}

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

        -- ADSR
        reaper.ImGui_Text(ctx, "ADSR default values:")
        reaper.ImGui_SameLine(ctx)
        local item_width = 50
        if reaper.ImGui_BeginTable(ctx, "table_settings_adsr", 4, reaper.ImGui_TableFlags_None(), (item_width + 8) * 4) then
            reaper.ImGui_TableNextRow(ctx)
            reaper.ImGui_TableNextColumn(ctx)
            reaper.ImGui_PushItemWidth(ctx, item_width)
            changed, Settings.attack_amount.value = reaper.ImGui_DragDouble(ctx, "##drag_attack", Settings.attack_amount.value, 0.1, 0, 2000, "%.1f")
            reaper.ImGui_SetItemTooltip(ctx, Settings.attack_amount.description)
            if changed then one_changed = true end

            reaper.ImGui_TableNextColumn(ctx)
            reaper.ImGui_PushItemWidth(ctx, item_width)
            changed, Settings.decay_amount.value = reaper.ImGui_DragDouble(ctx, "##drag_decay", Settings.decay_amount.value, 0.1, 10, 15000, "%.1f")
            reaper.ImGui_SetItemTooltip(ctx, Settings.decay_amount.description)
            if changed then one_changed = true end

            reaper.ImGui_TableNextColumn(ctx)
            reaper.ImGui_PushItemWidth(ctx, item_width)
            changed, Settings.sustain_amount.value = reaper.ImGui_DragDouble(ctx, "##drag_sustain", Settings.sustain_amount.value, 0.1, -120, 12, "%.1f")
            reaper.ImGui_SetItemTooltip(ctx, Settings.sustain_amount.description)
            if changed then one_changed = true end

            reaper.ImGui_TableNextColumn(ctx)
            reaper.ImGui_PushItemWidth(ctx, item_width)
            changed, Settings.release_amount.value = reaper.ImGui_DragDouble(ctx, "##drag_release", Settings.release_amount.value, 0.1, 0, 2000, "%.1f")
            reaper.ImGui_SetItemTooltip(ctx, Settings.release_amount.description)
            if changed then one_changed = true end

            reaper.ImGui_TableNextRow(ctx)
            reaper.ImGui_TableNextColumn(ctx)
            local text_w = reaper.ImGui_CalcTextSize(ctx, "A")
            reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + (item_width - text_w) * 0.5)
            reaper.ImGui_Text(ctx, "A")

            reaper.ImGui_TableNextColumn(ctx)
            text_w = reaper.ImGui_CalcTextSize(ctx, "D")
            reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + (item_width - text_w) * 0.5)
            reaper.ImGui_Text(ctx, "D")

            reaper.ImGui_TableNextColumn(ctx)
            text_w = reaper.ImGui_CalcTextSize(ctx, "S")
            reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + (item_width - text_w) * 0.5)
            reaper.ImGui_Text(ctx, "S")

            reaper.ImGui_TableNextColumn(ctx)
            text_w = reaper.ImGui_CalcTextSize(ctx, "R")
            reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + (item_width - text_w) * 0.5)
            reaper.ImGui_Text(ctx, "R")

            reaper.ImGui_EndTable(ctx)
        end

        -- Pattern paths
        reaper.ImGui_Text(ctx, Settings.pattern_folder_paths.name..":")
        reaper.ImGui_SameLine(ctx)
        reaper.ImGui_PushItemWidth(ctx, 100)
        changed, multiline_concat = reaper.ImGui_InputTextMultiline(ctx, "input_paths", table.concat(Settings.pattern_folder_paths.value, "\n"), -1)
        reaper.ImGui_SetItemTooltip(ctx, Settings.pattern_folder_paths.description)
        if changed then
            one_changed = true
            Settings.pattern_folder_paths.value = {}
            for line in multiline_concat:gmatch("[^\n]+") do
                table.insert(Settings.pattern_folder_paths.value, line)
            end
        end

        reaper.ImGui_EndChild(ctx)
    end

    if one_changed then gson.SaveJSON(settings_path, Settings) end
end

return tab_settings
