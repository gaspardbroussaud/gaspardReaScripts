--@noindex
--@description Complete renamer user interface gui rule popup
--@author gaspard
--@about User interface rule popup used in gaspard_Complete renamer.lua script

local rules_popup = {}

local popup_open = false
local focused = true
local popup_rule = {}
local editing_rule = nil -- reference to the rule being edited (nil = new rule)
local ruleset = {}
local RULE_TYPES = {"insert", "replace", "case"}

-- Popup config visuals
local function PopupRuleInsert()
    local config = popup_rule.config.insert
    ImGui.Text(ctx, "INSERT")
    ImGui.Text(ctx, "Insert:")
    ImGui.SameLine(ctx)
    ImGui.SetNextItemWidth(ctx, -1)
    _, config.text = ImGui.InputText(ctx, "##input_text_rule_insert", config.text)
    ImGui.Dummy(ctx, 1, 5)
    ImGui.Text(ctx, "From start:")
    ImGui.SameLine(ctx)
    _, config.from_start = ImGui.Checkbox(ctx, "##checkbox_from_start", config.from_start)
    ImGui.Text(ctx, "From end:")
    ImGui.SameLine(ctx)
    _, config.from_end = ImGui.Checkbox(ctx, "##checkbox_from_end", config.from_end)
end

local function PopupRuleReplace()
    local config = popup_rule.config.replace
    ImGui.Text(ctx, "REPLACE")
    ImGui.Text(ctx, "Search:")
    ImGui.SameLine(ctx)
    ImGui.SetNextItemWidth(ctx, -1)
    _, config.search_text = ImGui.InputText(ctx, "##replace_search_text", config.search_text)
    ImGui.Text(ctx, "Replace:")
    ImGui.SameLine(ctx)
    ImGui.SetNextItemWidth(ctx, -1)
    _, config.replace_text = ImGui.InputText(ctx, "##replace_replace_text", config.replace_text)
    ImGui.Dummy(ctx, 1, 5)
    ImGui.TextDisabled(ctx, "Case sensitive, every occurrence is replaced.")
end

local function PopupRuleCase()
    local config = popup_rule.config.case
    ImGui.Text(ctx, "CASE")
    for _, option in ipairs(System.CASE_OPTIONS) do
        if ImGui.RadioButton(ctx, option.display, config.selected == option.value) then
            config.selected = option.value
        end
    end
end

local function Gui_PopupRulesConfig()
    if popup_rule.type_selected == "insert" then PopupRuleInsert()
    elseif popup_rule.type_selected == "replace" then PopupRuleReplace()
    elseif popup_rule.type_selected == "case" then PopupRuleCase() end
end

local function ClosePopup()
    popup_open = false
    editing_rule = nil
    System.focus_main_window = true
end

local function SaveRule()
    local new_rule = System.NormalizeRule(System.TableCopy(popup_rule))
    local replaced = false
    if editing_rule then
        for i, rule in ipairs(ruleset) do
            if rule == editing_rule then
                new_rule.selected = rule.selected
                ruleset[i] = new_rule
                replaced = true
                break
            end
        end
    end
    if not replaced then table.insert(ruleset, new_rule) end
    System.last_selected_area = "rule"
end

-- GUI Rule popup elements
local function VisualRulePopupElements(width, height)
    local child_width = width - 10
    local child_height = height - 75
    if ImGui.BeginChild(ctx, "child_rule_popup", child_width, child_height, ImGui.ChildFlags_Borders) then
        if ImGui.BeginListBox(ctx, "##listbox_rule_popup_types", 100, child_height - 16) then
            for _, rule_type in ipairs(RULE_TYPES) do
                local display = rule_type:gsub("^%l", string.upper)
                if ImGui.Selectable(ctx, display .. "##sel_rule_type_" .. rule_type, popup_rule.type_selected == rule_type) then
                    popup_rule.type_selected = rule_type
                end
            end
            ImGui.EndListBox(ctx)
        end
        ImGui.SameLine(ctx)
        if ImGui.BeginChild(ctx, "child_rule_config") then
            Gui_PopupRulesConfig()
            ImGui.EndChild(ctx)
        end
        ImGui.EndChild(ctx)
    end

    local button_text = editing_rule and "SAVE" or "ADD"
    ImGui.SetCursorPosY(ctx, height - 35)
    if ImGui.Button(ctx, button_text .. "##button_rule_popup_add_save", 310) then
        SaveRule()
        ClosePopup()
    end

    ImGui.SetCursorPosX(ctx, width - 118)
    ImGui.SetCursorPosY(ctx, height - 35)
    if ImGui.Button(ctx, "CLOSE##button_rule_popup_close", 110) then
        ClosePopup()
    end
end

-- GUI Rule popup window
local function VisualRulePopup()
    ImGui.PushStyleColor(ctx, ImGui.Col_WindowBg, 0x151515FF)
    ImGui.PushStyleColor(ctx, ImGui.Col_TitleBgActive, 0x222222FF)
    local rule_flags = ImGui.WindowFlags_NoCollapse | ImGui.WindowFlags_NoScrollbar | ImGui.WindowFlags_NoResize | ImGui.WindowFlags_TopMost
    if focused then
        ImGui.SetNextWindowFocus(ctx)
        focused = false
    end
    local rule_popup_width = 450
    local rule_popup_height = 300
    ImGui.SetNextWindowSize(ctx, rule_popup_width, rule_popup_height, ImGui.Cond_Once)
    ImGui.SetNextWindowPos(ctx, window_x + (window_width - rule_popup_width) * 0.5, window_y + (window_height - rule_popup_height) * 0.5, ImGui.Cond_Appearing)

    local rule_visible, rule_open = ImGui.Begin(ctx, 'RULE', true, rule_flags)
    if rule_visible then
        -- Enter validates, Escape closes (only when not typing)
        if ImGui.IsWindowFocused(ctx, ImGui.FocusedFlags_RootAndChildWindows) then
            if ImGui.IsKeyPressed(ctx, ImGui.Key_Escape, false) then
                ClosePopup()
            elseif ImGui.IsKeyPressed(ctx, ImGui.Key_Enter, false) or ImGui.IsKeyPressed(ctx, ImGui.Key_KeypadEnter, false) then
                SaveRule()
                ClosePopup()
            end
        end
        if popup_open then VisualRulePopupElements(rule_popup_width, rule_popup_height) end
        ImGui.End(ctx)
    end

    if not rule_open then ClosePopup() end
    ImGui.PopStyleColor(ctx, 2)
end

function rules_popup.Show(rule_popup_open, set_of_rules)
    ruleset = set_of_rules
    popup_open = rule_popup_open
    if popup_open then VisualRulePopup() end
    if not popup_open then focused = true end
    return popup_open, ruleset
end

---@param rule_source table Rule used to fill the popup (copied)
---@param rule_reference table|nil Rule being edited in the ruleset (nil to add a new rule)
function rules_popup.SetPopupVariables(rule_source, rule_reference)
    popup_rule = System.NormalizeRule(System.TableCopy(rule_source))
    editing_rule = rule_reference
end

function rules_popup.IsEditing(rule)
    return editing_rule ~= nil and editing_rule == rule
end

return rules_popup
