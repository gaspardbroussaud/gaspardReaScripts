-- @noindex
-- @description Complete renamer user interface gui rules
-- @author gaspard
-- @about User interface rules used in gaspard_Complete renamer.lua script

local rules = {}

local rules_popup = require('Utilities/GUI_Elements/Gui_Rules_Popup')

local rule_types = {}
rule_types.insert = {text = "", from_start = true, from_end = false}
rule_types.replace = {search_text = "", replace_text = ""}
rule_types.case = {selected = 0, capitalize_every_word = 0, all_lower_case = 1, all_upper_case = 2, first_letter_capital = 3}
local empty_rule = {version = "1.0.0", state = true, type_selected = "insert", config = rule_types, selected = false}

local selected_rule = nil
local selected_index = -1
local rule_popup_open = false
local last_selected_rule = nil
local popup_type = true

local function GetRuleDisplayText(rule)
    local text = ""
    if rule.type_selected == "insert" then
        text = '"'..rule.config.insert.text..'"'
        if rule.config.insert.from_start then
            text = text..' from start'
            if rule.config.insert.from_end then
                text = text..' and from end'
            end
        elseif rule.config.insert.from_end then
            text = text..' from end'
        end
    end
    if rule.type_selected == "replace" then
        text = '"'..rule.config.replace.search_text..'" with "'..rule.config.replace.replace_text..'"'
    end
    if rule.type_selected == "case" then
        for key, _ in pairs(rule.config.case) do
            if key ~= "selected" and rule.config.case[key] == rule.config.case.selected then
                key = key:gsub("_", " ")
                key = key:gsub("^(%l)", string.upper)
                text = key
                break
            end
        end
    end
    return text
end

-- GUI rules top bar
local function RulesButtons()
    if reaper.ImGui_Button(ctx, "Add##button_add_rule", 100) then
        selected_rule = System.LoadEmptyRule(empty_rule, rule_default_path)
        rule_popup_open = true
        popup_type = true
        selected_index = -1
        rules_popup.SetPopupVariables(selected_rule, selected_index, popup_type)
    end

    reaper.ImGui_SameLine(ctx)

    local disable = true
    for _, rule in ipairs(System.ruleset) do
        if rule.selected then
            disable = false
            break
        end
    end
    if disable then reaper.ImGui_BeginDisabled(ctx) end
    if reaper.ImGui_Button(ctx, "Remove##button_remove_rule", 100) then
        if System.ruleset then
            local remove_table = {}
            for i, rule in ipairs(System.ruleset) do
                if rule.selected then
                    --table.remove(System.ruleset, i)
                    remove_table[rule] = true
                    System.one_renamed = false
                end
                if selected_rule == rule then
                    selected_rule = nil
                    rule_popup_open = false
                    last_selected_rule = nil
                end
            end
            local i = 1
            while i <= #System.ruleset do
                if remove_table[System.ruleset[i]] then
                    table.remove(System.ruleset, i)
                else
                    i = i + 1
                end
            end
        end
    end
    if disable then reaper.ImGui_EndDisabled(ctx) end
end

-- GUI drag rules
local function RulesDrag()
    if reaper.ImGui_BeginTable(ctx, "table_rules", 3, reaper.ImGui_TableFlags_SizingFixedFit()) then
        for i, rule in ipairs(System.ruleset) do
            local rule_id = tostring(i)..tostring(rule.config)
            reaper.ImGui_TableNextRow(ctx)

            reaper.ImGui_TableNextColumn(ctx)
            reaper.ImGui_PushID(ctx, i)
            changed, rule.state = reaper.ImGui_Checkbox(ctx, "##checkbox"..rule_id, rule.state)
            if changed then System.one_renamed = false end
            reaper.ImGui_SameLine(ctx)
            local selectable_label = tostring(i).."##selectable"..rule_id
            changed, rule.selected = reaper.ImGui_Selectable(ctx, selectable_label, rule.selected, reaper.ImGui_SelectableFlags_SpanAllColumns())
            if changed then
                if not System.Ctrl then
                    if System.Shift then
                        if last_selected_rule and last_selected_rule ~= i then
                            System.SelectFromOneToTheOther(System.ruleset, last_selected_rule, i)
                        end
                    else
                        rule.selected = true
                        for j, sub_rule in ipairs(System.ruleset) do
                            if sub_rule.selected and i ~= j then sub_rule.selected = false end
                        end
                    end
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
                    System.RepositionInTable(System.ruleset, payload_i, i)
                end
                reaper.ImGui_EndDragDropTarget(ctx)
            end
            reaper.ImGui_PopID(ctx)

            reaper.ImGui_TableNextColumn(ctx)
            local type_display = rule.type_selected:gsub("^(%l)", string.upper)
            reaper.ImGui_Text(ctx, type_display)

            reaper.ImGui_TableNextColumn(ctx)
            local rule_display = GetRuleDisplayText(rule)
            reaper.ImGui_Text(ctx, rule_display)
        end
        reaper.ImGui_EndTable(ctx)
    end
end

function rules.Show()
    RulesButtons()
    RulesDrag()
    rule_popup_open, System.ruleset = rules_popup.Show(rule_popup_open, System.ruleset)
end

return rules
