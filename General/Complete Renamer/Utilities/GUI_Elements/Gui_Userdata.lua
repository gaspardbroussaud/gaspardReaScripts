-- @noindex
-- @description Complete renamer user interface gui userdata
-- @author gaspard
-- @about User interface userdata window used in gaspard_Complete renamer.lua script

local userdata_window = {}

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
                    local show_userdata = true
                    if show_userdata then
                        if userdata == first.userdata then
                            can_select = true
                        end

                        if can_select then
                            userdata.selected = true
                            if key == "items" then reaper.SetMediaItemSelected(userdata.id, userdata.selected)
                            elseif key == "tracks" then reaper.SetTrackSelected(userdata.id, userdata.selected) end
                        end

                        if userdata == last.userdata then
                            can_select = false
                        end
                    end
                end
            end
        end
        reaper.UpdateArrange()
    end
end

-- Display found and renamed Reaper userdata
local function DisplayUserdata()
    if System.global_datas.order then
        local tree_flags = reaper.ImGui_TreeNodeFlags_SpanAllColumns() | reaper.ImGui_TreeNodeFlags_Framed()
        if Settings.tree_start_open.value then tree_flags = tree_flags | reaper.ImGui_TreeNodeFlags_DefaultOpen() end
        local selection_index = 0
        for index, key in ipairs(System.global_datas.order) do
            if System.global_datas[key]["data"] then
                if reaper.ImGui_TreeNode(ctx, System.global_datas[key]["display"].."##index"..tostring(index), tree_flags) then
                    if reaper.ImGui_BeginTable(ctx, "table_"..key, 2, reaper.ImGui_TableFlags_BordersInnerV()) then
                        for _, userdata in pairs(System.global_datas[key]["data"]) do
                            local show_userdata = true
                            if show_userdata then
                                reaper.ImGui_TableNextRow(ctx)
                                reaper.ImGui_TableNextColumn(ctx)
                                local label = "##selectable"..key..tostring(userdata.id)..userdata.name
                                changed, userdata.selected = reaper.ImGui_Selectable(ctx, userdata.name..label, userdata.selected, reaper.ImGui_SelectableFlags_SpanAllColumns())
                                if changed then
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
    reaper.ImGui_Text(ctx, "USERDATA")
    System.GetUserdatas()
    DisplayUserdata()
end

return userdata_window