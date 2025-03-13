--@noindex

local tab_settings = {}

function tab_settings.Show()
    local changed = false
    -- Project based parent
    reaper.ImGui_Text(ctx, Settings.project_based_parent.name..":")
    reaper.ImGui_SameLine(ctx)
    changed, Settings.project_based_parent.value = reaper.ImGui_Checkbox(ctx, "##project_based_parent", Settings.project_based_parent.value)
    reaper.ImGui_SetItemTooltip(ctx, Settings.project_based_parent.description)
    local parent_track = gpmsys_samples.GetParentFromSelectedTrack()
    local disabled = not parent_track
    if disabled then reaper.ImGui_BeginDisabled(ctx) end
    if reaper.ImGui_Button(ctx, "Set selected sample track parent as project parent") then
        gpmsys.SetTrackToExtState(parent_track, extname_global, extkey_parent_track)
    end
    if disabled then reaper.ImGui_EndDisabled(ctx) end

    -- Obey note offs
    reaper.ImGui_Text(ctx, Settings.obey_note_off.name..":")
    reaper.ImGui_SameLine(ctx)
    changed, Settings.obey_note_off.value = reaper.ImGui_Checkbox(ctx, "##obey_note_off", Settings.obey_note_off.value)
    reaper.ImGui_SetItemTooltip(ctx, Settings.obey_note_off.description)

    -- ADSR
    reaper.ImGui_Text(ctx, "ADSR default values:")
    -- Attack
    reaper.ImGui_Text(ctx, Settings.attack_amount.name..":")
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_PushItemWidth(ctx, 100)
    changed, Settings.attack_amount.value = reaper.ImGui_DragDouble(ctx, "##attack_amount", Settings.attack_amount.value, 0.1, 0, 2000, "%0.1f")
    reaper.ImGui_SetItemTooltip(ctx, Settings.attack_amount.description)
    -- Decay
    reaper.ImGui_Text(ctx, Settings.decay_amount.name..":")
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_PushItemWidth(ctx, 100)
    changed, Settings.decay_amount.value = reaper.ImGui_DragDouble(ctx, "##decay_amount", Settings.decay_amount.value, 0.1, 10, 15000, "%0.1f")
    reaper.ImGui_SetItemTooltip(ctx, Settings.decay_amount.description)
    -- Sustain
    reaper.ImGui_Text(ctx, Settings.sustain_amount.name..":")
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_PushItemWidth(ctx, 100)
    changed, Settings.sustain_amount.value = reaper.ImGui_DragDouble(ctx, "##sustain_amount", Settings.sustain_amount.value, 0.1, -120, 12, "%0.1f")
    reaper.ImGui_SetItemTooltip(ctx, Settings.sustain_amount.description)
    -- Release
    reaper.ImGui_Text(ctx, Settings.release_amount.name..":")
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_PushItemWidth(ctx, 100)
    changed, Settings.release_amount.value = reaper.ImGui_DragDouble(ctx, "##release_amount", Settings.release_amount.value, 0.1, 0, 2000, "%0.1f")
    reaper.ImGui_SetItemTooltip(ctx, Settings.release_amount.description)

    -- Pattern paths
    reaper.ImGui_Text(ctx, Settings.pattern_folder_paths.name..":")
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_PushItemWidth(ctx, 100)
    changed, Settings.pattern_folder_paths.value[1] = reaper.ImGui_InputTextMultiline(ctx, "input_paths", Settings.pattern_folder_paths.value[1], -1)
    reaper.ImGui_SetItemTooltip(ctx, Settings.pattern_folder_paths.description)
end

return tab_settings
