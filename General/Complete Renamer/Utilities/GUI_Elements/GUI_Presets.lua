--@noindex
--@description Complete renamer user interface gui presets
--@author gaspard
--@about User interface presets used in gaspard_Complete renamer.lua script

local presets_window = {}

local presets_one_changed = false
local selected_preset = nil
local preset_search = ""

local function ResetVariables()
    preset_search = ""
    presets_one_changed = false
    show_presets = false
    selected_preset = nil
    for _, preset in ipairs(System.presets) do
        preset.selected = false
    end
    System.focus_main_window = true
end

function presets_window.Show()
    -- Set Presets Window visibility and settings
    local presets_flags = reaper.ImGui_WindowFlags_NoCollapse() | reaper.ImGui_WindowFlags_NoScrollbar() | reaper.ImGui_WindowFlags_NoResize()
    local presets_width = 300
    local presets_height = 300
    reaper.ImGui_SetNextWindowSize(ctx, presets_width, presets_height, reaper.ImGui_Cond_Once())
    reaper.ImGui_SetNextWindowPos(ctx, window_x + (window_width - presets_width) * 0.5, window_y + 10, reaper.ImGui_Cond_Appearing())
    local presets_visible, presets_open  = reaper.ImGui_Begin(ctx, 'PRESETS', true, presets_flags)
    if presets_visible then
        reaper.ImGui_Text(ctx, "Search:")
        reaper.ImGui_SameLine(ctx)
        reaper.ImGui_PushItemWidth(ctx, -1)
        _, preset_search = reaper.ImGui_InputText(ctx, "##inputtext_search", preset_search)
        if reaper.ImGui_BeginChild(ctx, "child_presets_window", presets_width - 16, presets_height - 100, reaper.ImGui_ChildFlags_Border()) then
            if reaper.ImGui_BeginListBox(ctx, "##listbox_presets", -1, -1) then
                for i, preset in ipairs(System.presets) do
                    if preset_search == "" or preset.name:lower():find(preset_search:lower(), 1, true) then
                        changed, preset.selected = reaper.ImGui_Selectable(ctx, preset.name.."##"..tostring(i), preset.selected, reaper.ImGui_SelectableFlags_SpanAllColumns())
                        if changed then
                            presets_one_changed = false
                            if preset.selected then selected_preset = preset end
                        end

                        -- On Double clic
                        if reaper.ImGui_IsItemHovered(ctx) and reaper.ImGui_IsMouseDoubleClicked(ctx, reaper.ImGui_MouseButton_Left()) then
                            System.ImportPresetReplaceRuleset(preset)
                            ResetVariables()
                        end
                    else
                        preset.selected = false
                        if preset == selected_preset then selected_preset = nil end
                    end
                end
                reaper.ImGui_EndListBox(ctx)
            end
            reaper.ImGui_EndChild(ctx)
        end

        reaper.ImGui_SetCursorPosY(ctx, presets_height - 35)
        local disable = preset_search == ""
        if not disable and #System.ruleset == 0 then disable = true end
        if disable then reaper.ImGui_BeginDisabled(ctx) end
        if reaper.ImGui_Button(ctx, "SAVE##presets_save", 70) then
            System.SavePreset(preset_search, System.ruleset)
            ResetVariables()
        end
        if disable then reaper.ImGui_EndDisabled(ctx) end
        reaper.ImGui_SameLine(ctx)

        reaper.ImGui_SetCursorPosX(ctx, presets_width - 160)
        reaper.ImGui_SetCursorPosY(ctx, presets_height - 35)
        if not presets_one_changed then
            for _, preset in ipairs(System.presets) do
                if preset.selected then
                    presets_one_changed = true
                    break
                end
            end
        end
        disable = not presets_one_changed
        if not disable and not selected_preset then disable = true end
        if disable then reaper.ImGui_BeginDisabled(ctx) end
        if reaper.ImGui_Button(ctx, "IMPORT##presets_import", 70) then
            System.ImportPresetReplaceRuleset(selected_preset)
            ResetVariables()
        end
        reaper.ImGui_SameLine(ctx)
        reaper.ImGui_SetCursorPosY(ctx, presets_height - 35)
        if reaper.ImGui_Button(ctx, "ADD##presets_add", 70) then
            System.AddPresetToRuleset(selected_preset)
            ResetVariables()
        end
        if disable then reaper.ImGui_EndDisabled(ctx) end

        reaper.ImGui_End(ctx)
    else
        show_presets = false
    end

    if not presets_open then
        ResetVariables()
    end
end

return presets_window
