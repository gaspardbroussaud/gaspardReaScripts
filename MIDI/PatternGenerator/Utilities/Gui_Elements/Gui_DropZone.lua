--@noindex
--@description Pattern generator user interface gui drop zone
--@author gaspard
--@about User interface drop zone used in gaspard_Pattern generator.lua script

local drop_window = {}

local drop_zone_count = 9

function drop_window.Show()
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(), 0xFFFFFFFF)

    if reaper.ImGui_BeginTable(ctx, "table_drop_zones", drop_zone_count) then
        reaper.ImGui_TableNextRow(ctx)
        for i = 1, drop_zone_count do
            reaper.ImGui_TableNextColumn(ctx)
            if reaper.ImGui_BeginChild(ctx, "child_element"..tostring(i), -1, -1, reaper.ImGui_ChildFlags_Border()) then
                local display_text = ""
                local col_display = false
                if System.objects[i] then
                    display_text = System.objects[i].name
                    col_display = true
                end
                if col_display then reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ChildBg(), 0x574F8EAA) end
                if reaper.ImGui_BeginChild(ctx, "drop_zone"..tostring(i), -1, 70, reaper.ImGui_ChildFlags_Border()) then
                    reaper.ImGui_Text(ctx, tostring(display_text))
                    if col_display then
                        if reaper.ImGui_Button(ctx, ">##"..tostring(i)) then
                            reaper.MB("Play: "..display_text.." on index "..tostring(i), "INFO", 0)
                        end
                    end
                    reaper.ImGui_EndChild(ctx)
                end
                if col_display then reaper.ImGui_PopStyleColor(ctx) end

                if reaper.ImGui_BeginDragDropTarget(ctx) then
                    local retval, data_count = reaper.ImGui_AcceptDragDropPayloadFiles(ctx)
                    if retval then
                        if data_count > 1 then
                            reaper.MB("Insert only one file at a time. Will use first of selection.", "WARNING", 0)
                        end
                        local _, filepath = reaper.ImGui_GetDragDropPayloadFile(ctx, 0)
                        local filename = filepath:match("([^\\/]+)$")
                        filepath = System.CopyFileToProjectDirectory(filename, filepath)
                        table.insert(System.objects, {name = filename, path = filepath})
                        table.insert(System.selected_pattern, 0)
                        System.CreateObjectTrack(System.objects[#System.objects], #System.objects)
                    end
                    reaper.ImGui_EndDragDropTarget(ctx)
                end

                if col_display and #System.patterns > 0 then
                    changed = false
                    local selected = System.selected_pattern[i]
                    reaper.ImGui_PushItemWidth(ctx, -1)
                    if reaper.ImGui_BeginCombo(ctx, "##combo_patterns"..tostring(i), System.patterns[selected]) then
                        for j, pattern in ipairs(System.patterns) do
                            local is_selected = (j == selected)
                            if reaper.ImGui_Selectable(ctx, pattern, is_selected) then
                                System.selected_pattern[i] = j
                                changed = true
                            end
                            if is_selected then
                                reaper.ImGui_SetItemDefaultFocus(ctx)
                            end
                        end
                        reaper.ImGui_EndCombo(ctx)
                    end
                    if changed then
                        reaper.MB("Combo "..display_text.." at index "..tostring(i).." updated.", "INFO", 0)
                    end
                end
                reaper.ImGui_EndChild(ctx)
            end

            --[[if i % 3 ~= 0 then
                reaper.ImGui_SameLine(ctx)
            end]]
        end
        reaper.ImGui_EndTable(ctx)
    end

    reaper.ImGui_PopStyleColor(ctx)
end

return drop_window
