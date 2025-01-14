-- @noindex
-- @description Complete renamer user interface gui rules
-- @author gaspard
-- @about User interface rules used in gaspard_Complete renamer.lua script

local rules = {}

local rules_popup = require('Utilities/GUI_Elements/Gui_Rules_Popup')

local ruleset = {}
local rule_types = {}
rule_types.insert = {text = "Text to insert", from_start = true, from_end = false}
rule_types.replace = {search_text = "sfx_", replace_text = "amb_"}
rule_types.case = {capitalize_every_word = true, all_lower_case = false, all_upper_case = false}
local empty_rule = {version = "1.0.0", state = true, type_selected = "insert", config = rule_types, selected = false}

local selected_rule = nil
local selected_index = -1
local rule_popup_open = false
local last_selected_rule = nil
local popup_type = true

-- GUI rules top bar
local function RulesButtons()
    if reaper.ImGui_Button(ctx, "Add##button_add_rule", 100) then
        --[[ruleset = System.LoadRuleFile(ruleset, empty_rule, rule_default_path)
        selected_rule = ruleset[#ruleset]--]]
        selected_rule = System.LoadEmptyRule(empty_rule, rule_default_path)
        rule_popup_open = true
        popup_type = true
        selected_index = -1
        rules_popup.SetPopupVariables(selected_rule, selected_index, popup_type)
    end

    reaper.ImGui_SameLine(ctx)

    if reaper.ImGui_Button(ctx, "Remove##button_remove_rule", 100) then
        for i, rule in ipairs(ruleset) do
            if rule.selected then table.remove(ruleset, i) end
            if selected_rule == rule then
                selected_rule = nil
                rule_popup_open = false
                last_selected_rule = nil
            end
        end
    end
end

-- GUI drag rules
local function RulesDrag()
    if reaper.ImGui_BeginTable(ctx, "table_rules", 3, reaper.ImGui_TableFlags_SizingFixedFit()) then
        for i, rule in ipairs(ruleset) do
            local rule_id = tostring(i)..tostring(rule.config)
            reaper.ImGui_TableNextRow(ctx)

            reaper.ImGui_TableNextColumn(ctx)
            reaper.ImGui_PushID(ctx, i)
            _, rule.state = reaper.ImGui_Checkbox(ctx, "##checkbox"..rule_id, rule.state)
            reaper.ImGui_SameLine(ctx)
            local selectable_label = tostring(i).."##selectable"..rule_id
            changed, rule.selected = reaper.ImGui_Selectable(ctx, selectable_label, rule.selected, reaper.ImGui_SelectableFlags_SpanAllColumns())
            if changed then
                rule.selected = true
                if not reaper.ImGui_IsKeyDown(ctx, reaper.ImGui_Key_LeftCtrl()) then
                    if reaper.ImGui_IsKeyDown(ctx, reaper.ImGui_Key_LeftShift()) then
                        if last_selected_rule then
                            System.SelectFromOneToTheOther(ruleset, last_selected_rule, i)
                        end
                    else
                        for j, sub_rule in ipairs(ruleset) do
                            if sub_rule.selected and i ~= j then sub_rule.selected = false end
                        end
                    end
                else
                    rule.selected = false
                end
                last_selected_rule = i
            end

            -- On Double clic
            if reaper.ImGui_IsItemHovered(ctx) and reaper.ImGui_IsMouseDoubleClicked(ctx, reaper.ImGui_MouseButton_Left()) then
                rule.selected = true
                selected_rule = rule
                rule_popup_open = true
                popup_type = false
                selected_index = i
                rules_popup.SetPopupVariables(selected_rule, selected_index, popup_type)
            end

            if reaper.ImGui_BeginDragDropSource(ctx) then
                reaper.ImGui_SetDragDropPayload(ctx, "rule_payload", i)
                payload_i = i
                reaper.ImGui_EndDragDropSource(ctx)
            end
            if reaper.ImGui_BeginDragDropTarget(ctx) then
                local retval, payload = reaper.ImGui_AcceptDragDropPayload(ctx, "rule_payload")
                if retval and payload then
                    System.RepositionInTable(ruleset, payload_i, i)
                end
                reaper.ImGui_EndDragDropTarget(ctx)
            end
            reaper.ImGui_PopID(ctx)

            reaper.ImGui_TableNextColumn(ctx)
            reaper.ImGui_Text(ctx, rule.type_selected)

            reaper.ImGui_TableNextColumn(ctx)
            reaper.ImGui_Text(ctx, tostring(rule))
        end
        reaper.ImGui_EndTable(ctx)
    end
end

function rules.Show()
    RulesButtons()
    RulesDrag()
    rule_popup_open, ruleset = rules_popup.Show(rule_popup_open, ruleset)
end

return rules
