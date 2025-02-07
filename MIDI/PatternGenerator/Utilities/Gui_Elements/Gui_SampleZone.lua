--@noindex
--@description Pattern generator user interface gui drop zone
--@author gaspard
--@about User interface drop zone used in gaspard_Pattern generator.lua script

local sample_window = {}

local function GetNameNoExtension(name)
    name = name:gsub("%.wav$", "")
    name = name:gsub("%.mp3$", "")
    name = name:gsub("%.ogg$", "")
    return name
end

function sample_window.Show()
    reaper.ImGui_Text(ctx, "DRUMPAD")
    local test = true
    if not test then return end

    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(), 0xFFFFFFFF)

    for i = 1, System.max_samples do
        local display_text = ""
        local col_display = false
        if System.samples[i] and System.samples[i].track then
            display_text = System.samples[i].name
            col_display = true
        else
            System.samples[i] = {}
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

                    local name = GetNameNoExtension(filename)
                    if add then
                        --local index = reaper.CountTracks(0) 
                        --local index = loaded_samples_count > #System.samples and #System.samples + 1 or i
                        name, path, track = System.CreateSampleTrack(name, filepath, i)
                        System.samples[i] = {name = name, path = path, track = track}
                        --table.insert(System.samples, {name = name, path = path, track = track})
                    else
                        local existing_track = System.samples[i].track
                        System.samples[i] = {name = name, path = filepath, track = existing_track}
                        System.ReplaceSample(i)
                    end
                end
            end
            reaper.ImGui_EndDragDropTarget(ctx)
        end

        if i % 3 ~= 0 then
            reaper.ImGui_SameLine(ctx)
        end
    end

    reaper.ImGui_PopStyleColor(ctx)
end

return sample_window
