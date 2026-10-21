--@noindex
--@description Complete renamer user interface gui presets
--@author gaspard
--@about User interface presets used in gaspard_Complete renamer.lua script

local presets_window = {}

local selected_preset = nil
local preset_search = ""
local PRESETS_WIDTH, PRESETS_HEIGHT = 360, 330
local PANEL_FLAGS = ImGui.WindowFlags_NoCollapse | ImGui.WindowFlags_NoScrollbar | ImGui.WindowFlags_NoResize
    | ImGui.WindowFlags_TopMost | ImGui.WindowFlags_NoDecoration

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

-- Presets panel (GaspaReaLauncher style)
function presets_window.Show()
    local x, y = Gui_PanelPosition()
    ImGui.SetNextWindowSize(ctx, PRESETS_WIDTH, PRESETS_HEIGHT, ImGui.Cond_Always)
    ImGui.SetNextWindowPos(ctx, x, y, ImGui.Cond_Always, 1, 0)
    local presets_visible = ImGui.Begin(ctx, '##presets_window', true, PANEL_FLAGS)
    if not presets_visible then
        show_presets = false
        return
    end

    ImGui.Text(ctx, "PRESETS")
    ImGui.Separator(ctx)

    ImGui.Text(ctx, "Name:")
    ImGui.SameLine(ctx)
    ImGui.SetNextItemWidth(ctx, -1)
    _, preset_search = ImGui.InputText(ctx, "##inputtext_search", preset_search)
    ImGui.SetItemTooltip(ctx, "Enter preset name to search or to save new.\nIf a preset exists with this name, it will be erased on SAVE.")

    if ImGui.BeginListBox(ctx, "##listbox_presets", -1, PRESETS_HEIGHT - 125) then
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

    local button_w = (PRESETS_WIDTH - 16 - 3 * 8) / 4
    ImGui.SetCursorPosY(ctx, PRESETS_HEIGHT - 35)

    -- SAVE
    local name_valid = preset_search:match("%S") ~= nil
    local disable = not name_valid or #System.ruleset == 0
    if disable then ImGui.BeginDisabled(ctx) end
    local save_label = (name_valid and PresetExists(preset_search)) and "OVERWRITE" or "SAVE"
    if ImGui.Button(ctx, save_label .. "##presets_save", button_w) then
        System.SavePreset(preset_search, System.ruleset)
        System.ScanPresetFiles()
        ResetVariables()
    end
    if disable then ImGui.EndDisabled(ctx) end

    -- REMOVE / IMPORT / ADD need a selected preset
    disable = selected_preset == nil
    if disable then ImGui.BeginDisabled(ctx) end

    ImGui.SameLine(ctx)
    if ImGui.Button(ctx, "REMOVE##presets_remove", button_w) then
        System.RemovePreset(selected_preset)
        selected_preset = nil
        System.ScanPresetFiles()
    end

    ImGui.SameLine(ctx)
    if ImGui.Button(ctx, "IMPORT##presets_import", button_w) then
        System.ImportPresetReplaceRuleset(selected_preset)
        ResetVariables()
    end
    ImGui.SetItemTooltip(ctx, "Replace current rules with the preset.")

    ImGui.SameLine(ctx)
    if ImGui.Button(ctx, "ADD##presets_add", button_w) then
        System.AddPresetToRuleset(selected_preset)
        ResetVariables()
    end
    ImGui.SetItemTooltip(ctx, "Add preset rules after current rules.")

    if disable then ImGui.EndDisabled(ctx) end

    ImGui.End(ctx)
end

return presets_window
