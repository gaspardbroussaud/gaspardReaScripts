--@noindex
--@description Complete renamer user interface gui userdata
--@author gaspard
--@about User interface userdata window used in gaspard_Complete renamer.lua script

local userdata_window = {}

local last_userdata_selected = nil

local function SetUserdataStateExtState(userdata, key)
    local script_ext = 'gaspard_CompleteRenamer'
    if userdata.selected then
        for _, tree_key in ipairs(System.global_datas.order) do
            if System.global_datas[tree_key]["data"] then
                for _, data in pairs(System.global_datas[tree_key]["data"]) do
                    if data.selected then
                        if tree_key == "items" then
                            reaper.GetSetMediaItemInfo_String(data.id, "P_EXT:"..script_ext..":State", tostring(userdata.state), true)
                        elseif tree_key == "tracks" then
                            reaper.GetSetMediaTrackInfo_String(data.id, "P_EXT:"..script_ext..":State", tostring(userdata.state), true)
                        elseif tree_key == "markers" then
                            reaper.SetProjExtState(project_id, tostring(data.id), script_ext.."_State", tostring(userdata.state))
                        elseif tree_key == "regions" then
                            reaper.SetProjExtState(project_id, tostring(data.id), script_ext.."_State", tostring(userdata.state))
                        end
                    end
                end
            end
        end
    else
        if key == "items" then
            reaper.GetSetMediaItemInfo_String(userdata.id, "P_EXT:"..script_ext..":State", tostring(userdata.state), true)
        elseif key == "tracks" then
            reaper.GetSetMediaTrackInfo_String(userdata.id, "P_EXT:"..script_ext..":State", tostring(userdata.state), true)
        elseif key == "markers" then
            reaper.SetProjExtState(project_id, tostring(userdata.id), script_ext.."_State", tostring(userdata.state))
        elseif key == "regions" then
            reaper.SetProjExtState(project_id, tostring(userdata.id), script_ext.."_State", tostring(userdata.state))
        end
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
                    if System.global_datas[key]["show"] then
                        if userdata.id == first.userdata.id then
                            can_select = true
                        end

                        if can_select then
                            userdata.selected = true
                            System.SetUserdataSelectedExtState(userdata, key)
                            if Settings.link_selection.value then System.SelectUserdataInProject(userdata, key) end
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
                changed, System.global_datas[key].state = reaper.ImGui_Checkbox(ctx, "##checkbox_tree_"..tostring(key), System.global_datas[key].state)
                if changed then
                    reaper.SetProjExtState(project_id, 'gaspard_CompleteRenamer', key.."_State", tostring(System.global_datas[key].state))
                    System.one_renamed = false
                    System.last_selected_area = "userdata"
                end
                reaper.ImGui_SameLine(ctx)
                System.global_datas[key]["show"] = reaper.ImGui_TreeNode(ctx, System.global_datas[key]["display"].."##index"..tostring(index), tree_flags)
                local changed = reaper.ImGui_IsItemToggledOpen(ctx)
                if changed then
                    System.one_renamed = false
                    System.last_selected_area = "userdata"
                end
                if System.global_datas[key]["show"] then
                    local table_flags = reaper.ImGui_TableFlags_BordersInnerV() | reaper.ImGui_TableColumnFlags_WidthFixed() | reaper.ImGui_TableFlags_Resizable()
                    if reaper.ImGui_BeginTable(ctx, "table_"..key, 3, table_flags) then
                        local column_flags = reaper.ImGui_TableColumnFlags_WidthFixed() | reaper.ImGui_TableFlags_SizingFixedFit() | reaper.ImGui_TableColumnFlags_NoResize()
                        reaper.ImGui_TableSetupColumn(ctx, "col_checkbox", column_flags, 30)
                        reaper.ImGui_TableSetupColumn(ctx, "col_original_name")
                        reaper.ImGui_TableSetupColumn(ctx, "col_replaced_name")
                        for i, userdata in pairs(System.global_datas[key]["data"]) do
                            local show_userdata = System.global_datas[key].show
                            if show_userdata then
                                reaper.ImGui_TableNextRow(ctx)
                                reaper.ImGui_TableNextColumn(ctx)
                                local disabled = not System.global_datas[key].state
                                if disabled then reaper.ImGui_BeginDisabled(ctx) end
                                changed, userdata.state = reaper.ImGui_Checkbox(ctx, "##checkbox_state"..tostring(i), userdata.state) --State checkbox
                                if changed and System.global_datas[key].state then
                                    SetUserdataStateExtState(userdata, key)
                                    System.one_renamed = false
                                    System.last_selected_area = "userdata"
                                end
                                if disabled then reaper.ImGui_EndDisabled(ctx) end
                                reaper.ImGui_TableNextColumn(ctx)
                                local label = "##selectable"..key..tostring(userdata.id)..userdata.name
                                changed, userdata.selected = reaper.ImGui_Selectable(ctx, userdata.name..label, userdata.selected, reaper.ImGui_SelectableFlags_SpanAllColumns())
                                if changed then
                                    if not System.Ctrl and not System.Shift then
                                        for _, sub_key in ipairs(System.global_datas.order) do
                                            if System.global_datas[sub_key]["data"] then
                                                for _, sub_data in pairs(System.global_datas[sub_key]["data"]) do
                                                    sub_data.selected = sub_data == userdata
                                                    System.SetUserdataSelectedExtState(sub_data, sub_key)
                                                    if Settings.link_selection.value then
                                                        System.SelectUserdataInProject(sub_data, sub_key)
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
                                        System.SelectUserdataInProject(userdata, key)
                                        reaper.UpdateArrange()
                                    end
                                    if userdata.selected then
                                        last_userdata_selected = {userdata = userdata, index = selection_index}
                                    else
                                        last_userdata_selected = nil
                                    end
                                    System.last_selected_area = "userdata"
                                    System.SetUserdataSelectedExtState(userdata, key)
                                end

                                reaper.ImGui_TableNextColumn(ctx)
                                local can_apply = System.global_datas[key].state and userdata.state
                                local replaced_text = nil
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
    System.GetUserdatas()
    DisplayUserdata()
end

return userdata_window
