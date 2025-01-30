--@noindex
--@description Pattern generator user interface gui drop zone
--@author gaspard
--@about User interface drop zone used in gaspard_Pattern generator.lua script

local drop_window = {}

local drop_zone_count = 9

function drop_window.Show()
    reaper.ImGui_Text(ctx, "Drop files here:")
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(), 0xFFFFFFFF)

    for i = 1, drop_zone_count do
        local display_text = ""
        local col_display = false
        if System.objects[i] then
            display_text = System.objects[i].name
            col_display = true
        end
        if col_display then reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ChildBg(), 0x574F8EAA) end
        if reaper.ImGui_BeginChild(ctx, "drop_zone"..tostring(i), 100, 70, reaper.ImGui_ChildFlags_Border()) then
            reaper.ImGui_Text(ctx, tostring(display_text))
            if display_text and display_text ~= "" then
                if reaper.ImGui_Button(ctx, ">##"..tostring(i)) then
                    reaper.ShowConsoleMsg("Play: "..display_text.." on "..tostring(i).."\n")
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
                System.CreateObjectTrack(System.objects[#System.objects], #System.objects)
            end
            reaper.ImGui_EndDragDropTarget(ctx)
        end

        if i % 3 ~= 0 then
            reaper.ImGui_SameLine(ctx)
        end
    end

    reaper.ImGui_PopStyleColor(ctx)
end

return drop_window
