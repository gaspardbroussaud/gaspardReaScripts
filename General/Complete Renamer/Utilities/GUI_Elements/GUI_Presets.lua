--@noindex
--@description Complete renamer user interface gui presets
--@author gaspard
--@about User interface presets used in gaspard_Complete renamer.lua script

local presets_window = {}

local selected_preset = nil
local preset_search = ""

local function ResetVariables()
    preset_search = ""
    show_presets = false
    selected_preset = nil
    for _, preset in ipairs(System.presets) do
        preset.selected = false
    end
    System.focus_main_window = true
end

local function PresetExists(name)
    local lower = name:lower()
    for _, preset in ipairs(System.presets) do
        if preset.name:lower() == lower then return true end
    end
    return false
end

function presets_window.Show()
    local presets_flags = ImGui.WindowFlags_NoCollapse | ImGui.WindowFlags_NoScrollbar | ImGui.WindowFlags_NoResize
    local presets_width = 360
    local presets_height = 300
    ImGui.SetNextWindowSize(ctx, presets_width, presets_height, ImGui.Cond_Once)
    ImGui.SetNextWindowPos(ctx, window_x + (window_width - presets_width) * 0.5, window_y + 10, ImGui.Cond_Appearing)
    local presets_visible, presets_open = ImGui.Begin(ctx, 'PRESETS', true, presets_flags)
    if presets_visible then
        ImGui.Text(ctx, "Name:")
        ImGui.SameLine(ctx)
        ImGui.SetNextItemWidth(ctx, -1)
        _, preset_search = ImGui.InputText(ctx, "##inputtext_search", preset_search)
        ImGui.SetItemTooltip(ctx, "Enter preset name to search or to save new.\nIf a preset exists with this name, it will be erased on SAVE.")

        if ImGui.BeginChild(ctx, "child_presets_window", presets_width - 16, presets_height - 100, ImGui.ChildFlags_Borders) then
            if ImGui.BeginListBox(ctx, "##listbox_presets", -1, -1) then
                local search = preset_search:lower()
                for i, preset in ipairs(System.presets) do
                    if search == "" or preset.name:lower():find(search, 1, true) then
                        if ImGui.Selectable(ctx, preset.name .. "##" .. tostring(i), preset == selected_preset, ImGui.SelectableFlags_AllowDoubleClick) then
                            selected_preset = preset
                            -- On double click: import preset (replace rules)
                            if ImGui.IsMouseDoubleClicked(ctx, ImGui.MouseButton_Left) then
                                System.ImportPresetReplaceRuleset(preset)
                                ResetVariables()
                            end
                        end
                    elseif preset == selected_preset then
                        selected_preset = nil
                    end
                end
                ImGui.EndListBox(ctx)
            end
            ImGui.EndChild(ctx)
        end

        -- SAVE
        local name_valid = preset_search:match("%S") ~= nil
        local disable = not name_valid or #System.ruleset == 0
        if disable then ImGui.BeginDisabled(ctx) end
        ImGui.SetCursorPosY(ctx, presets_height - 35)
        local save_label = (name_valid and PresetExists(preset_search)) and "OVERWRITE" or "SAVE"
        if ImGui.Button(ctx, save_label .. "##presets_save", 80) then
            System.SavePreset(preset_search, System.ruleset)
            System.ScanPresetFiles()
            ResetVariables()
        end
        if disable then ImGui.EndDisabled(ctx) end
        ImGui.SameLine(ctx)

        -- REMOVE / IMPORT / ADD need a selected preset
        disable = selected_preset == nil
        if disable then ImGui.BeginDisabled(ctx) end

        ImGui.SetCursorPosY(ctx, presets_height - 35)
        if ImGui.Button(ctx, "REMOVE##presets_remove", 80) then
            System.RemovePreset(selected_preset)
            selected_preset = nil
            System.ScanPresetFiles()
        end

        ImGui.SameLine(ctx)
        ImGui.SetCursorPosX(ctx, presets_width - 175)
        ImGui.SetCursorPosY(ctx, presets_height - 35)
        if ImGui.Button(ctx, "IMPORT##presets_import", 80) then
            System.ImportPresetReplaceRuleset(selected_preset)
            ResetVariables()
        end
        ImGui.SetItemTooltip(ctx, "Replace current rules with the preset.")

        ImGui.SameLine(ctx)
        ImGui.SetCursorPosY(ctx, presets_height - 35)
        if ImGui.Button(ctx, "ADD##presets_add", 80) then
            System.AddPresetToRuleset(selected_preset)
            ResetVariables()
        end
        ImGui.SetItemTooltip(ctx, "Add preset rules after current rules.")

        if disable then ImGui.EndDisabled(ctx) end

        ImGui.End(ctx)
    end

    if not presets_open then
        ResetVariables()
    end
end

return presets_window
