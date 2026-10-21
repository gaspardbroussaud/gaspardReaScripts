--@noindex
--@description Complete renamer user interface gui userdata
--@author gaspard
--@about User interface userdata window used in gaspard_Complete renamer.lua script

local userdata_window = {}

local last_clicked_index = nil -- anchor (global index) for shift selection
local clippers = {}
local EMPTY_NAME = "(no name)"
local MUTED_COLOR = 0x9A9A9AFF

-- One list clipper per data type (recreated if garbage collected by ReaImGui)
local function GetClipper(key)
    local clipper = clippers[key]
    if not ImGui.ValidatePtr(clipper, 'ImGui_ListClipper*') then
        clipper = ImGui.CreateListClipper(ctx)
        clippers[key] = clipper
    end
    return clipper
end

local function OnUserdataClicked(userdata, key)
    System.last_selected_area = "userdata"
    if System.Shift and last_clicked_index then
        if not System.Ctrl then System.ClearUserdataSelection() end
        System.SelectUserdataRange(last_clicked_index, userdata.index)
        return
    end
    if System.Ctrl then
        System.SetUserdataSelected(userdata, key, not userdata.selected)
    else
        System.ClearUserdataSelection(userdata)
        System.SetUserdataSelected(userdata, key, true)
    end
    last_clicked_index = userdata.selected and userdata.index or nil
    System.FlushSelection()
end

local function DrawRow(key, category, userdata, row)
    ImGui.TableNextRow(ctx)
    ImGui.PushID(ctx, row)

    -- State checkbox
    ImGui.TableNextColumn(ctx)
    local disabled = not category.state
    if disabled then ImGui.BeginDisabled(ctx) end
    local changed, state = ImGui.Checkbox(ctx, "##checkbox_state", userdata.state)
    if changed then
        -- Toggling a selected element toggles every selected element
        if userdata.selected then System.SetSelectedUserdatasState(state)
        else System.SetUserdataState(userdata, key, state) end
        System.last_selected_area = "userdata"
    end
    if disabled then ImGui.EndDisabled(ctx) end

    -- Original name
    ImGui.TableNextColumn(ctx)
    local is_empty = userdata.name == ""
    if is_empty then ImGui.PushStyleColor(ctx, ImGui.Col_Text, MUTED_COLOR) end
    local label = (is_empty and EMPTY_NAME or userdata.name) .. "##selectable"
    if ImGui.Selectable(ctx, label, userdata.selected, ImGui.SelectableFlags_SpanAllColumns) then
        OnUserdataClicked(userdata, key)
    end
    if is_empty then ImGui.PopStyleColor(ctx) end

    local can_apply = category.state and userdata.state
    local replaced_text = can_apply and userdata.preview or nil

    if ImGui.IsItemHovered(ctx, ImGui.HoveredFlags_Stationary) then
        local text = userdata.name .. " -> " .. (replaced_text or "")
        if userdata.number and userdata.number >= 0 then
            text = category.display:sub(1, -2) .. " " .. userdata.number .. ": " .. text
        end
        ImGui.SetTooltip(ctx, text)
    end

    -- Replaced name
    ImGui.TableNextColumn(ctx)
    if replaced_text then
        if replaced_text == "" then
            ImGui.TextColored(ctx, MUTED_COLOR, EMPTY_NAME)
        else
            ImGui.Text(ctx, replaced_text)
        end
    end

    ImGui.PopID(ctx)
end

local function DrawCategory(index, key, tree_flags)
    local category = System.global_datas[key]
    local data = category.data
    if #data == 0 then
        category.show = false
        return
    end

    ImGui.PushID(ctx, key)
    local changed, state = ImGui.Checkbox(ctx, "##checkbox_tree", category.state)
    if changed then
        System.SetCategoryState(key, state)
        System.last_selected_area = "userdata"
    end
    ImGui.SameLine(ctx)
    category.show = ImGui.TreeNode(ctx, ("%s (%d)###tree%d"):format(category.display, #data, index), tree_flags)
    if ImGui.IsItemToggledOpen(ctx) then
        System.last_selected_area = "userdata"
    end

    if category.show then
        local table_flags = ImGui.TableFlags_BordersInnerV | ImGui.TableFlags_Resizable
        if ImGui.BeginTable(ctx, "table_" .. key, 3, table_flags) then
            ImGui.TableSetupColumn(ctx, "col_checkbox", ImGui.TableColumnFlags_WidthFixed | ImGui.TableColumnFlags_NoResize, 30)
            ImGui.TableSetupColumn(ctx, "col_original_name", ImGui.TableColumnFlags_WidthStretch)
            ImGui.TableSetupColumn(ctx, "col_replaced_name", ImGui.TableColumnFlags_WidthStretch)

            -- Only visible rows are drawn
            local clipper = GetClipper(key)
            ImGui.ListClipper_Begin(clipper, #data)
            while ImGui.ListClipper_Step(clipper) do
                local display_start, display_end = ImGui.ListClipper_GetDisplayRange(clipper)
                for row = display_start + 1, display_end do
                    DrawRow(key, category, data[row], row)
                end
            end

            ImGui.EndTable(ctx)
        end
        ImGui.TreePop(ctx)
    end
    ImGui.PopID(ctx)
end

-- Display found and renamed Reaper userdata
local function DisplayUserdata()
    if System.IsEmpty() then
        ImGui.TextColored(ctx, MUTED_COLOR, "No items, tracks, markers or regions in this project.")
        return
    end
    local tree_flags = ImGui.TreeNodeFlags_SpanAllColumns | ImGui.TreeNodeFlags_Framed
    if Settings.tree_start_open.value then tree_flags = tree_flags | ImGui.TreeNodeFlags_DefaultOpen end
    for index, key in ipairs(System.global_datas.order) do
        DrawCategory(index, key, tree_flags)
    end
    System.FlushSelection()
end

-- GUI Userdatas
function userdata_window.ShowVisuals()
    DisplayUserdata()
end

return userdata_window
