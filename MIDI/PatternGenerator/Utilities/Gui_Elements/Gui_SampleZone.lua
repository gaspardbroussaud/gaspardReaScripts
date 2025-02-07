--@noindex
--@description Pattern generator user interface gui drop zone
--@author gaspard
--@about User interface drop zone used in gaspard_Pattern generator.lua script

local sample_window = {}

local sample_zone_count = 9

function sample_window.Show()
    reaper.ImGui_Text(ctx, "DRUMPAD")
    local test = true
    if not test then return end

    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(), 0xFFFFFFFF)

    --[[if reaper.ImGui_BeginTable(ctx, "table_samples", sample_zone_count, reaper.ImGui_TableFlags_None(), -1, -1) then
        reaper.ImGui_TableNextRow(ctx)
        reaper.ImGui_TableNextColumn(ctx)]]
        for i = 1, sample_zone_count do
            --if reaper.ImGui_BeginChild(ctx, "child_element"..tostring(i), -1, -1, reaper.ImGui_ChildFlags_Border()) then
                local display_text = ""
                local col_display = false
                if System.samples[i] then
                    display_text = System.samples[i].name
                    col_display = true
                end
                if col_display then reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ChildBg(), 0x574F8EAA) end
                if reaper.ImGui_BeginChild(ctx, "sample_zone"..tostring(i), 85, 70, reaper.ImGui_ChildFlags_Border()) then
                    reaper.ImGui_Text(ctx, tostring(display_text))
                    if col_display then
                        local x, y = reaper.ImGui_GetContentRegionAvail(ctx)
                        local button_size = 15
                        reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + (x - button_size) * 0.5)
                        reaper.ImGui_SetCursorPosY(ctx, reaper.ImGui_GetCursorPosY(ctx) + y - 24)
                        if reaper.ImGui_Button(ctx, ">##"..tostring(i), button_size) then
                            System.PreviewReaSamplOmatic(System.samples[i].track)
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
                        local skip = false
                        for _, sample in ipairs(System.samples) do
                            if filename == sample.name then
                                skip = true
                                break
                            end
                        end
                        if not skip then
                            local add = true
                            filepath = System.CopyFileToProjectDirectory(filename, filepath)
                            for _, cur_path in ipairs(System.samples) do
                                if cur_path == filepath then
                                    add = false
                                    break
                                end
                            end

                            if add then
                                local name, path, track = System.CreateSampleTrack(filename:gsub("%.wav$", "") , filepath, #System.samples + 1)
                                --System.samples[#System.samples], #System.samples)
                                table.insert(System.samples, {name = name, path = path, track = track})
                                table.insert(System.selected_pattern, 0)
                            end
                        end
                    end
                    reaper.ImGui_EndDragDropTarget(ctx)
                end

                --[[
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
                ]]
                --reaper.ImGui_EndChild(ctx)
            --end

            if i % 3 ~= 0 then
                reaper.ImGui_SameLine(ctx)
            end
            --[[if i % 3 ~= 0 then
                reaper.ImGui_TableNextColumn(ctx)
            else
                reaper.ImGui_TableNextRow(ctx)
                reaper.ImGui_TableNextColumn(ctx)
            end]]
        end
        --[[reaper.ImGui_EndTable(ctx)
    end]]

    reaper.ImGui_PopStyleColor(ctx)
end

return sample_window
