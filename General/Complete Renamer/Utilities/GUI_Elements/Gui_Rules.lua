--@noindex
--@description Complete renamer user interface gui rules
--@author gaspard
--@about User interface rules used in gaspard_Complete renamer.lua script

local rules = {}

local rules_popup = require('Utilities/GUI_Elements/Gui_Rules_Popup')

local rule_types = {}
rule_types.insert = {text = "", from_start = true, from_end = false}
rule_types.replace = {search_text = "", replace_text = ""}
rule_types.case = {selected = 0, capitalize_every_word = 0, all_lower_case = 1, all_upper_case = 2, first_letter_capital = 3}
local empty_rule = {version = "1.0", state = true, type_selected = "insert", config = rule_types, selected = false}

local rule_popup_open = false
local last_selected_rule = nil
local PAYLOAD_TYPE = "gaspard_complete_renamer_rule"

local CASE_DISPLAY = {}
for _, option in ipairs(System.CASE_OPTIONS) do CASE_DISPLAY[option.value] = option.display end

local function GetRuleDisplayText(rule)
    local config = rule.config
    if rule.type_selected == "insert" then
        local text = '"' .. config.insert.text .. '"'
        if config.insert.from_start and config.insert.from_end then
            text = text .. ' from start and from end'
        elseif config.insert.from_start then
            text = text .. ' from start'
        elseif config.insert.from_end then
            text = text .. ' from end'
        else
            text = text .. ' (no position selected)'
        end
        return text
    elseif rule.type_selected == "replace" then
        return '"' .. config.replace.search_text .. '" with "' .. config.replace.replace_text .. '"'
    elseif rule.type_selected == "case" then
        return CASE_DISPLAY[config.case.selected] or ""
    end
    return ""
end

local function RemoveSelectedRules()
    local i = 1
    while i <= #System.ruleset do
        local rule = System.ruleset[i]
        if rule.selected then
            if rules_popup.IsEditing(rule) then rule_popup_open = false end
            table.remove(System.ruleset, i)
        else
            i = i + 1
        end
    end
    last_selected_rule = nil
end

local function AnyRuleSelected()
    for _, rule in ipairs(System.ruleset) do
        if rule.selected then return true end
    end
    return false
end

-- GUI rules top bar
local function RulesButtons()
    if ImGui.Button(ctx, "ADD##button_add_rule", 100) then
        rule_popup_open = true
        rules_popup.SetPopupVariables(System.LoadEmptyRule(empty_rule, rule_default_path), nil)
    end

    ImGui.SameLine(ctx)

    local disable = not AnyRuleSelected()
    if disable then ImGui.BeginDisabled(ctx) end
    if ImGui.Button(ctx, "REMOVE##button_remove_rule", 100) then
        RemoveSelectedRules()
    end
    if disable then ImGui.EndDisabled(ctx) end
    ImGui.SetItemTooltip(ctx, "Remove selected rules (Delete key)")
end

-- GUI drag rules
local function RulesDrag()
    local drop_from, drop_to = nil, nil
    if ImGui.BeginTable(ctx, "table_rules", 3, ImGui.TableFlags_SizingFixedFit) then
        for i, rule in ipairs(System.ruleset) do
            ImGui.TableNextRow(ctx)
            ImGui.PushID(ctx, i)

            ImGui.TableNextColumn(ctx)
            local changed
            changed, rule.state = ImGui.Checkbox(ctx, "##checkbox", rule.state)
            if changed then
                System.last_selected_area = "rule"
            end
            ImGui.SameLine(ctx)
            if ImGui.Selectable(ctx, tostring(i) .. "##selectable", rule.selected, ImGui.SelectableFlags_SpanAllColumns | ImGui.SelectableFlags_AllowDoubleClick) then
                if System.Shift and last_selected_rule then
                    if not System.Ctrl then System.ClearTableSelection(System.ruleset) end
                    System.SelectFromOneToTheOther(System.ruleset, last_selected_rule, i)
                elseif System.Ctrl then
                    rule.selected = not rule.selected
                    last_selected_rule = i
                else
                    System.ClearTableSelection(System.ruleset)
                    rule.selected = true
                    last_selected_rule = i
                end
                System.last_selected_area = "rule"

                -- On double click: edit rule
                if ImGui.IsMouseDoubleClicked(ctx, ImGui.MouseButton_Left) then
                    rule.selected = true
                    rule_popup_open = true
                    rules_popup.SetPopupVariables(rule, rule)
                end
            end

            if ImGui.BeginDragDropSource(ctx) then
                ImGui.SetDragDropPayload(ctx, PAYLOAD_TYPE, tostring(i))
                ImGui.Text(ctx, tostring(i) .. ". " .. rule.type_selected)
                ImGui.EndDragDropSource(ctx)
            end
            if ImGui.BeginDragDropTarget(ctx) then
                local retval, payload = ImGui.AcceptDragDropPayload(ctx, PAYLOAD_TYPE)
                if retval and payload then
                    drop_from, drop_to = tonumber(payload), i
                end
                ImGui.EndDragDropTarget(ctx)
            end

            ImGui.TableNextColumn(ctx)
            ImGui.Text(ctx, (rule.type_selected:gsub("^%l", string.upper)))

            ImGui.TableNextColumn(ctx)
            ImGui.Text(ctx, GetRuleDisplayText(rule))

            ImGui.PopID(ctx)
        end
        ImGui.EndTable(ctx)
    end

    -- Reorder after the loop so the table is not modified while iterating
    if drop_from and drop_to then
        System.RepositionInTable(System.ruleset, drop_from, drop_to)
        last_selected_rule = nil
    end
end

local function RulesShortcuts()
    if System.last_selected_area ~= "rule" then return end
    if not ImGui.IsWindowFocused(ctx, ImGui.FocusedFlags_RootAndChildWindows) or ImGui.IsAnyItemActive(ctx) then return end
    if ImGui.IsKeyPressed(ctx, ImGui.Key_Delete, false) and AnyRuleSelected() then
        RemoveSelectedRules()
    end
end

function rules.Show()
    RulesShortcuts()
    RulesButtons()
    RulesDrag()
    rule_popup_open, System.ruleset = rules_popup.Show(rule_popup_open, System.ruleset)
end

return rules
