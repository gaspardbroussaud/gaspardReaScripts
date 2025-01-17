-- @noindex
-- @description Complete renamer user interface gui userdata
-- @author gaspard
-- @about User interface userdata window used in gaspard_Complete renamer.lua script

local userdata_window = {}

local last_userdata_selected = nil

local function SelectUserdataInProject(userdata, key)
    if key == "items" then
        reaper.SetMediaItemSelected(userdata.id, userdata.selected)
    elseif key == "tracks" then
        reaper.SetTrackSelected(userdata.id, userdata.selected)
    end
end

local function SelectFromOneToTheOther(one, other)
    if System.global_datas.order then
        local first = one
        local last = other
        if one.index > other.index then
            first = other
            last = one
        end
        local can_select = false
        for _, key in ipairs(System.global_datas.order) do
            if System.global_datas[key]["data"] then
                for _, userdata in pairs(System.global_datas[key]["data"]) do
                    if System.global_datas[key]["state"] then
                        if userdata.id == first.userdata.id then
                            can_select = true
                        end

                        if can_select then
                            userdata.selected = true
                            if Settings.link_selection.value then SelectUserdataInProject(userdata, key) end
                        end

                        if userdata.id == last.userdata.id then
                            can_select = false
                        end
                    end
                end
            end
        end
        if Settings.link_selection.value then reaper.UpdateArrange() end
    end
end

-- Display found and renamed Reaper userdata
local function DisplayUserdata()
    local selection_index = 0
    if System.global_datas.order then
        local tree_flags = reaper.ImGui_TreeNodeFlags_SpanAllColumns() | reaper.ImGui_TreeNodeFlags_Framed()
        if Settings.tree_start_open.value then tree_flags = tree_flags | reaper.ImGui_TreeNodeFlags_DefaultOpen() end
        for index, key in ipairs(System.global_datas.order) do
            if System.global_datas[key]["data"] then
                if reaper.ImGui_TreeNode(ctx, System.global_datas[key]["display"].."##index"..tostring(index), tree_flags) then
                    System.global_datas[key]["state"] = true
                    if reaper.ImGui_BeginTable(ctx, "table_"..key, 2, reaper.ImGui_TableFlags_BordersInnerV()) then
                        for i, userdata in pairs(System.global_datas[key]["data"]) do
                            local show_userdata = true
                            if show_userdata then
                                reaper.ImGui_TableNextRow(ctx)
                                reaper.ImGui_TableNextColumn(ctx)
                                local label = "##selectable"..key..tostring(userdata.id)..userdata.name
                                changed, userdata.selected = reaper.ImGui_Selectable(ctx, userdata.name..label, userdata.selected, reaper.ImGui_SelectableFlags_SpanAllColumns())
                                if changed then
                                    if not System.Ctrl and not System.Shift then
                                        for _, sub_key in ipairs(System.global_datas.order) do
                                            if System.global_datas[sub_key]["data"] then
                                                for _, sub_data in pairs(System.global_datas[sub_key]["data"]) do
                                                    sub_data.selected = sub_data == userdata
                                                    if Settings.link_selection.value then
                                                        SelectUserdataInProject(sub_data, sub_key)
                                                    end
                                                end
                                            end
                                        end
                                        userdata.selected = true
                                    end
                                    if System.Shift then
                                        if last_userdata_selected and userdata.selected and last_userdata_selected.userdata ~= userdata then
                                            SelectFromOneToTheOther(last_userdata_selected, {userdata = userdata, index = selection_index})
                                        end
                                    end

                                    if Settings.link_selection.value then
                                        SelectUserdataInProject(userdata, key)
                                        reaper.UpdateArrange()
                                    end
                                    if userdata.selected then
                                        last_userdata_selected = {userdata = userdata, index = selection_index}
                                    else
                                        last_userdata_selected = nil
                                    end
                                end

                                reaper.ImGui_TableNextColumn(ctx)
                                local can_apply = true
                                local replaced_text = nil
                                if selection_based and not userdata.selected then can_apply = false end
                                if can_apply then
                                    replaced_text = System.GetReplacedName(userdata.name)
                                    if replaced_text and replaced_text ~= userdata.name then System.one_renamed = true end
                                end

                                if reaper.ImGui_IsItemHovered(ctx, reaper.ImGui_HoveredFlags_Stationary()) then
                                    local text = userdata.name.." -> "
                                    if replaced_text and replaced_text ~= userdata.name then text = text..replaced_text end
                                    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(), 0xFFFFFFFF)
                                    reaper.ImGui_SetTooltip(ctx, text)
                                    reaper.ImGui_PopStyleColor(ctx)
                                end

                                if replaced_text and userdata.name ~= replaced_text then
                                    reaper.ImGui_Text(ctx, replaced_text)
                                end
                            end
                            selection_index = selection_index + 1
                        end

                        reaper.ImGui_EndTable(ctx)
                    end
                    reaper.ImGui_TreePop(ctx)
                end
            end
        end
    end
end

-- GUI Userdatas
function userdata_window.ShowVisuals()
    --reaper.ImGui_Text(ctx, "USERDATA")
    System.GetUserdatas()
    DisplayUserdata()
end

-- Gui checkboxes
function userdata_window.ShowCheckboxes()
end

return userdata_window
