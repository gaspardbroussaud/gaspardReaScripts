-- @noindex
-- @description Complete renamer user interface gui rule popup
-- @author gaspard
-- @about User interface rule popup used in gaspard_Complete renamer.lua script

local rules_popup = {}

local empty_rule_config = {
    insert = {insert_text = "", position = "start"},
    replace = {search_text = "", replace_text = ""},
    remove = {search_text = ""}
}
local empty_rule = {state = true, type = "insert", selected = false, config = empty_rule_config}
local ruleset = {
    {state = true, type = "insert", selected = false, config = {
        insert = {insert_text = "sfx_", position = "start"},
        replace = {search_text = "", replace_text = ""},
        remove = {search_text = ""}
    }},
    {state = true, type = "replace", selected = false, config = {
        insert = {insert_text = "sfx_", position = "start"},
        replace = {search_text = "MIDI", replace_text = "Not placed"},
        remove = {search_text = ""}
    }},
    {state = true, type = "remove", selected = false, config = {
        insert = {insert_text = "", position = "start"},
        replace = {search_text = "", replace_text = ""},
        remove = {search_text = "MIDI"}
    }}
}
local rule_popup_state = false
local rule_popup_focus = false
local rule_popup = {}
local rule_last_selected = nil
local rule_types = {
    {type = "insert", selected = false},
    {type = "replace", selected = false},
    {type = "remove", selected = false}
}

-- Popup config visuals
local function PopupRulesConfigVisuals()
    local function PopupRuleInsert()
        reaper.ImGui_Text(ctx, "INSERT")
        reaper.ImGui_Text(ctx, "Insert:")
        reaper.ImGui_SameLine(ctx)
        reaper.ImGui_PushItemWidth(ctx, -1)
        _, rule_popup.config.insert.insert_text = reaper.ImGui_InputText(ctx, "##input_text_rule_insert", rule_popup.config.insert.insert_text)
        reaper.ImGui_Dummy(ctx, 1, 5)
        reaper.ImGui_Text(ctx, "Position:")
        reaper.ImGui_RadioButton(ctx, "From start##radio_strat_rule_insert", true)
        reaper.ImGui_RadioButton(ctx, "From end##radio_end_rule_insert", true)
    end
    local function PopupRuleReplace()
        reaper.ImGui_Text(ctx, "REPLACE")
        reaper.ImGui_Text(ctx, rule_popup.config.replace.search_text)
        reaper.ImGui_Text(ctx, rule_popup.config.replace.replace_text)
    end
    local function PopupRuleRemove()
        reaper.ImGui_Text(ctx, "REMOVE")
        reaper.ImGui_Text(ctx, rule_popup.config.remove.search_text)
    end
    if rule_popup.type == "insert" then  PopupRuleInsert()
    elseif rule_popup.type == "replace" then PopupRuleReplace()
    elseif rule_popup.type == "remove" then PopupRuleRemove() end
end

-- GUI rules top bar
local function PopupTopBarVisuals()
    if reaper.ImGui_Button(ctx, "Add##button_add_rule", 100) then
        rule_popup = {type = "empty"}
        rule_popup_state = true
    end

    reaper.ImGui_SameLine(ctx)

    if reaper.ImGui_Button(ctx, "Remove##button_remove_rule", 100) then
        for i, rule in ipairs(ruleset) do
            if rule.selected then table.remove(ruleset, i) end
            if rule_popup == rule then
                rule_popup = nil
                rule_popup_state = false
                rule_popup_focus = false
                rule_last_selected = nil
            end
        end
    end
end

-- GUI drag rules
local function VisualRulesDrag()
    if reaper.ImGui_BeginTable(ctx, "table_rules", 3, reaper.ImGui_TableFlags_SizingFixedFit()) then
        for i, rule in ipairs(ruleset) do
            reaper.ImGui_TableNextRow(ctx)

            reaper.ImGui_TableNextColumn(ctx)
            reaper.ImGui_PushID(ctx, i)
            _, rule.state = reaper.ImGui_Checkbox(ctx, "##checkbox"..tostring(rule.config), rule.state)
            reaper.ImGui_SameLine(ctx)
            changed, rule.selected = reaper.ImGui_Selectable(ctx, tostring(i).."##selectable"..tostring(rule.config), rule.selected, reaper.ImGui_SelectableFlags_SpanAllColumns())
            if changed then
                if not reaper.ImGui_IsKeyDown(ctx, reaper.ImGui_Key_LeftCtrl()) then
                    if reaper.ImGui_IsKeyDown(ctx, reaper.ImGui_Key_LeftShift()) then
                        if rule_last_selected then
                            System.SelectFromOneToTheOther(ruleset, rule_last_selected, i)
                        end
                    else
                        for j, sub_rule in ipairs(ruleset) do
                            if sub_rule.selected and i~= j then sub_rule.selected = false end
                        end
                    end
                end
                rule_last_selected = i
            end
            -- On Double clic
            if reaper.ImGui_IsItemHovered(ctx) and reaper.ImGui_IsMouseDoubleClicked(ctx, reaper.ImGui_MouseButton_Left()) then
                rule.selected = true
                rule_popup = rule
                rule_popup_state = true
                rule_popup_focus = true
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
            reaper.ImGui_Text(ctx, rule.type)

            reaper.ImGui_TableNextColumn(ctx)
            reaper.ImGui_Text(ctx, tostring(rule.config))
        end
        reaper.ImGui_EndTable(ctx)
    end
end

-- GUI Rule popup elements
local function VisualRulePopupElements(width, height)
    local child_width = width - 10
    local child_height = height - 75
    if reaper.ImGui_BeginChild(ctx, "child_rule_popup", child_width, child_height, reaper.ImGui_ChildFlags_Border()) then
        if reaper.ImGui_BeginListBox(ctx, "##listbox_rule_popup_types", 100, child_height - 30) then
            for i, rule_type in ipairs(rule_types) do
                changed, rule_type.selected = reaper.ImGui_Selectable(ctx, rule_type.type.."##sel_rule_type"..tostring(rule_type), rule_type.selected)
                if changed then
                    rule_type.selected = true
                    for j = 1, #rule_types do
                        if rule_types[j].selected and j ~= i then rule_types[j].selected = false end
                    end
                    for _, type in ipairs(rule_popup.config) do
                        type.selected = false
                    end
                    rule_popup.config[rule_type.type].selected = true
                    rule_popup.type = rule_type.type
                end
            end
            reaper.ImGui_EndListBox(ctx)
        end
        reaper.ImGui_SameLine(ctx)
        if reaper.ImGui_BeginChild(ctx, "child_rule_config") then
            PopupRulesConfigVisuals()

            reaper.ImGui_EndChild(ctx)
        end
        reaper.ImGui_EndChild(ctx)
    end

    reaper.ImGui_SetCursorPosY(ctx, height - 35)
    if reaper.ImGui_Button(ctx, "Add##button_rule_popup_add", 100) then rule_popup_state = false end

    reaper.ImGui_SetCursorPosX(ctx, width - 110)
    reaper.ImGui_SetCursorPosY(ctx, height - 35)
    if reaper.ImGui_Button(ctx, "Close##button_rule_popup_close", 100) then rule_popup_state = false end
end

-- GUI Rule popup window
local function VisualRulePopup()
    -- Set Rule popup window visibility and settings
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_WindowBg(), 0x151515FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBgActive(), 0x222222FF)
    local rule_flags = reaper.ImGui_WindowFlags_NoCollapse() | reaper.ImGui_WindowFlags_NoScrollbar() | reaper.ImGui_WindowFlags_NoResize() | reaper.ImGui_WindowFlags_TopMost()
    if rule_popup_focus then
        reaper.ImGui_SetNextWindowFocus(ctx)
        rule_popup_focus = false
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
        rule_popup_state = false
    end

    if not rule_open then
        rule_popup_state = false
    end
    reaper.ImGui_PopStyleColor(ctx, 2)
end

function rules_popup.ShowVisuals()
    PopupTopBarVisuals()
    VisualRulesDrag()
    if rule_popup_state then VisualRulePopup() end
end

return rules_popup