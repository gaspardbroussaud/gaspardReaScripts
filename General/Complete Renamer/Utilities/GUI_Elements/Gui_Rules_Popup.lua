-- @noindex
-- @description Complete renamer user interface gui rule popup
-- @author gaspard
-- @about User interface rule popup used in gaspard_Complete renamer.lua script

local rules_popup = {}

local popup_type = false
local popup_open = false
local focused = true
local selected_rule = {}
local popup_rule = {}
local selected_index = -1
local rule_types = {
    {type = "insert", selected = true},
    {type = "replace", selected = false},
    {type = "case", selected = false}
}

-- Popup config visuals
local function Gui_PopupRulesConfig()
    local function PopupRuleInsert()
        reaper.ImGui_Text(ctx, "INSERT")
        reaper.ImGui_Text(ctx, "Insert:")
        reaper.ImGui_SameLine(ctx)
        reaper.ImGui_PushItemWidth(ctx, -1)
        _, popup_rule.config.insert.text = reaper.ImGui_InputText(ctx, "##input_text_rule_insert", popup_rule.config.insert.text)
        reaper.ImGui_Dummy(ctx, 1, 5)
        reaper.ImGui_Text(ctx, "From start:")
        reaper.ImGui_SameLine(ctx)
        changed, popup_rule.config.insert.from_start = reaper.ImGui_Checkbox(ctx, "##checkbox_from_start", popup_rule.config.insert.from_start)
        reaper.ImGui_Text(ctx, "From end:")
        reaper.ImGui_SameLine(ctx)
        changed, popup_rule.config.insert.from_end = reaper.ImGui_Checkbox(ctx, "##checkbox_from_end", popup_rule.config.insert.from_end)
    end
    local function PopupRuleReplace()
        reaper.ImGui_Text(ctx, "REPLACE")
        reaper.ImGui_Text(ctx, "Search:")
        reaper.ImGui_SameLine(ctx)
        reaper.ImGui_PushItemWidth(ctx, -1)
        _, popup_rule.config.replace.search_text = reaper.ImGui_InputText(ctx, "##replace_search_text", popup_rule.config.replace.search_text)
        reaper.ImGui_Text(ctx, "Replace:")
        reaper.ImGui_SameLine(ctx)
        reaper.ImGui_PushItemWidth(ctx, -1)
        _, popup_rule.config.replace.replace_text = reaper.ImGui_InputText(ctx, "##replace_replace_text", popup_rule.config.replace.replace_text)
    end
    local function PopupRuleRemove()
        reaper.ImGui_Text(ctx, "CASE")
        if reaper.ImGui_RadioButton(ctx, "Capitalize Every Words", popup_rule.config.case.selected == popup_rule.config.case.capitalize_every_word) then
            popup_rule.config.case.selected = 0
        end
        if reaper.ImGui_RadioButton(ctx, "all lower case", popup_rule.config.case.selected == popup_rule.config.case.all_lower_case) then
            popup_rule.config.case.selected = 1
        end
        if reaper.ImGui_RadioButton(ctx, "ALL UPPER CASE", popup_rule.config.case.selected == popup_rule.config.case.all_upper_case) then
            popup_rule.config.case.selected = 2
        end
        if reaper.ImGui_RadioButton(ctx, "First letter capital", popup_rule.config.case.selected == popup_rule.config.case.first_letter_capital) then
            popup_rule.config.case.selected = 3
        end
    end
    if popup_rule.type_selected == "insert" then  PopupRuleInsert()
    elseif popup_rule.type_selected == "replace" then PopupRuleReplace()
    elseif popup_rule.type_selected == "case" then PopupRuleRemove() end
end

-- GUI Rule popup elements
local function VisualRulePopupElements(width, height)
    local child_width = width - 10
    local child_height = height - 75
    if reaper.ImGui_BeginChild(ctx, "child_rule_popup", child_width, child_height, reaper.ImGui_ChildFlags_Border()) then
        if reaper.ImGui_BeginListBox(ctx, "##listbox_rule_popup_types", 100, child_height - 16) then
            for i, rule_type in ipairs(rule_types) do
                rule_type.selected = popup_rule.type_selected == rule_type.type
                local type_display = rule_type.type:gsub("^(%l)", string.upper)
                changed, rule_type.selected = reaper.ImGui_Selectable(ctx, type_display.."##sel_rule_type"..tostring(rule_type), rule_type.selected)
                if changed then
                    rule_type.selected = true
                    for j = 1, #rule_types do
                        if rule_types[j].selected and j ~= i then rule_types[j].selected = false end
                    end
                    popup_rule.type_selected = rule_type.type
                end
            end
            reaper.ImGui_EndListBox(ctx)
        end
        reaper.ImGui_SameLine(ctx)
        if reaper.ImGui_BeginChild(ctx, "child_rule_config") then
            Gui_PopupRulesConfig()

            reaper.ImGui_EndChild(ctx)
        end
        reaper.ImGui_EndChild(ctx)
    end

    local button_text = popup_type and "ADD" or "SAVE"
    reaper.ImGui_SetCursorPosY(ctx, height - 35)
    if reaper.ImGui_Button(ctx, button_text.."##button_rule_popup_add_save", 100) then
        popup_open = false
        if popup_type then
            table.insert(ruleset, System.TableCopy(popup_rule))
        else
            ruleset[selected_index] = System.TableCopy(popup_rule)
        end
        System.one_renamed = false
    end

    reaper.ImGui_SetCursorPosX(ctx, width - 110)
    reaper.ImGui_SetCursorPosY(ctx, height - 35)
    if reaper.ImGui_Button(ctx, "CLOSE##button_rule_popup_close", 100) then
        popup_open = false
        popup_rule = selected_rule
    end
end

-- GUI Rule popup window
local function VisualRulePopup()
    -- Set Rule popup window visibility and settings
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_WindowBg(), 0x151515FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBgActive(), 0x222222FF)
    local rule_flags = reaper.ImGui_WindowFlags_NoCollapse() | reaper.ImGui_WindowFlags_NoScrollbar() | reaper.ImGui_WindowFlags_NoResize() | reaper.ImGui_WindowFlags_TopMost()
    if focused then
        reaper.ImGui_SetNextWindowFocus(ctx)
        focused = false
    end
    local rule_popup_width = 450
    local rule_popup_height = 300
    reaper.ImGui_SetNextWindowSize(ctx, rule_popup_width, rule_popup_height, reaper.ImGui_Cond_Once())
    reaper.ImGui_SetNextWindowPos(ctx, window_x + (window_width - rule_popup_width) * 0.5, window_y + (window_height - rule_popup_height) * 0.5, reaper.ImGui_Cond_Appearing())

    local rule_visible, rule_open  = reaper.ImGui_Begin(ctx, 'RULE', true, rule_flags)

    if rule_visible then
        VisualRulePopupElements(rule_popup_width, rule_popup_height)

        reaper.ImGui_End(ctx)
    else
        popup_open = false
    end

    if not rule_open then
        popup_open = false
    end
    reaper.ImGui_PopStyleColor(ctx, 2)
end

function rules_popup.Show(rule_popup_open, set_of_rules)
    ruleset = set_of_rules
    popup_open = rule_popup_open
    if popup_open then VisualRulePopup() end
    if not popup_open then focused = true end
    return popup_open, ruleset
end

function rules_popup.SetPopupVariables(rule_selected, index_selected, type)
    popup_rule = System.TableCopy(rule_selected)
    selected_index = index_selected
    popup_type = type
end

return rules_popup
