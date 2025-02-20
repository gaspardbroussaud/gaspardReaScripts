--@noindex
--@description Pattern generator user interface gui drop zone
--@author gaspard
--@about User interface drop zone used in gaspard_Pattern generator.lua script

local sample_window = {}

-- Global variables
local popup_name = ''

--Functions
local function GetNameNoExtension(name)
    name = name:gsub('%.wav$', '')
    name = name:gsub('%.mp3$', '')
    name = name:gsub('%.ogg$', '')
    return name
end

function sample_window.Show()
    reaper.ImGui_Text(ctx, 'DRUMPAD')
    local test = true
    if not test then
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(), 0xFFFFFFFF)

        reaper.ImGui_BeginGroup(ctx)
        reaper.ImGui_Text(ctx, "Yopla")
        if reaper.ImGui_Button(ctx, '>##1', button_size) then
            --System.PreviewReaSamplOmatic(System.samples[i].track)
        end
        reaper.ImGui_EndGroup(ctx)

        reaper.ImGui_SameLine(ctx)

        reaper.ImGui_BeginGroup(ctx)
        reaper.ImGui_Text(ctx, "Yopla")
        if reaper.ImGui_Button(ctx, '>##2', button_size) then
            --System.PreviewReaSamplOmatic(System.samples[i].track)
        end
        reaper.ImGui_EndGroup(ctx)

        reaper.ImGui_PopStyleColor(ctx)
        return
    end

    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(), 0xFFFFFFFF)

    for i = 1, System.max_samples do
        local display_text = ''
        local name_double_clic = false
        local col_display = false
        if System.samples[i] and System.samples[i].track then
            display_text = System.samples[i].name
            col_display = true
        else
            System.samples[i] = {}
        end
        if col_display then reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ChildBg(), 0x574F8EAA) end
        if reaper.ImGui_BeginChild(ctx, 'sample_zone'..tostring(i), 85, 70, reaper.ImGui_ChildFlags_Border()) then
            reaper.ImGui_Text(ctx, tostring(display_text))
            -- On Double clic text
            if reaper.ImGui_IsItemHovered(ctx) and reaper.ImGui_IsMouseDoubleClicked(ctx, reaper.ImGui_MouseButton_Left()) and System.samples[i].track then
                reaper.ImGui_OpenPopup(ctx, 'popupnameupdate')
                popup_name = System.samples[i].name
                name_double_clic = true
            end
            if reaper.ImGui_BeginPopup(ctx, 'popupnameupdate') then
                w, h = reaper.ImGui_GetWindowSize(ctx)
                reaper.ImGui_Text(ctx, 'Track name:')
                changed, popup_name = reaper.ImGui_InputText(ctx, '##popupinputtext', popup_name)
                local flags = reaper.ImGui_TableColumnFlags_WidthStretch() | reaper.ImGui_TableFlags_SizingStretchSame()
                if reaper.ImGui_BeginTable(ctx, 'tablepopup', 3, flags) then
                    reaper.ImGui_TableNextRow(ctx)
                    reaper.ImGui_TableNextColumn(ctx)
                    reaper.ImGui_TableNextColumn(ctx)
                    if reaper.ImGui_Button(ctx, 'CANCEL', -1) then
                        reaper.ImGui_CloseCurrentPopup(ctx)
                    end
                    reaper.ImGui_TableNextColumn(ctx)
                    if reaper.ImGui_Button(ctx, 'APPLY', -1) then
                        System.samples[i].name = popup_name
                        reaper.GetSetMediaTrackInfo_String(System.samples[i].track, 'P_NAME', System.samples[i].name, true)
                        reaper.ImGui_CloseCurrentPopup(ctx)
                    end
                    reaper.ImGui_EndTable(ctx)
                end
                reaper.ImGui_EndPopup(ctx)
            end

            if col_display then
                local x, y = reaper.ImGui_GetContentRegionAvail(ctx)
                local button_size = 15
                reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) + (x - button_size) * 0.5)
                reaper.ImGui_SetCursorPosY(ctx, reaper.ImGui_GetCursorPosY(ctx) + y - 24)
                if reaper.ImGui_Button(ctx, '>##'..tostring(i), button_size) then
                    System.PreviewReaSamplOmatic(System.samples[i].track)
                end
            end


            reaper.ImGui_SetCursorPosX(ctx, 0)
            reaper.ImGui_SetCursorPosY(ctx, 0)
            reaper.ImGui_SetNextItemAllowOverlap(ctx)
            reaper.ImGui_InvisibleButton(ctx, 'drag_button_'..tostring(i), 25, 25)
            if reaper.ImGui_IsItemHovered(ctx) then reaper.ShowConsoleMsg('Invisible: '..tostring(i)..'\n') end

            reaper.ImGui_EndChild(ctx)
        end
        if col_display then reaper.ImGui_PopStyleColor(ctx) end

        if reaper.ImGui_BeginDragDropSource(ctx, reaper.ImGui_DragDropFlags_SourceAllowNullID()) then
            reaper.ImGui_SetDragDropPayload(ctx, 'SWAP_CHILD', i)
            reaper.ImGui_Text(ctx, 'Dragging Child ' .. tostring(i))
            reaper.ImGui_EndDragDropSource(ctx)
        end

        -- On Double clic
        if reaper.ImGui_IsItemHovered(ctx) and reaper.ImGui_IsMouseDoubleClicked(ctx, reaper.ImGui_MouseButton_Left()) and System.samples[i].track and not name_double_clic then
            local fx_index = reaper.TrackFX_GetByName(System.samples[i].track, System.samples[i].name, false)
            if fx_index then reaper.TrackFX_Show(System.samples[i].track, fx_index, 3) end -- Open fx in floating window
        end

        if reaper.ImGui_BeginDragDropTarget(ctx) then
            local retval, data_count = reaper.ImGui_AcceptDragDropPayloadFiles(ctx)
            if retval then
                if data_count > 1 then
                    reaper.MB('Insert only one file at a time. Will use first of selection.', 'WARNING', 0)
                end
                local skip = false
                local _, filepath = reaper.ImGui_GetDragDropPayloadFile(ctx, 0)
                local filename = filepath:match('([^\\/]+)$')
                local file_exist = false
                file_exist, filepath = System.CheckFileInDirectory(filepath, filename)
                if not file_exist and filepath then retval, filepath = System.CopyFileToProjectDirectory(filename, filepath) end
                if not filepath then skip = true end

                if not skip then
                    local name = GetNameNoExtension(filename)

                    local add = true
                    if System.samples[i] and System.samples[i].track then add = false end

                    if add then
                        System.samples[i] = {name = name, path = filepath, track = nil}
                        local track = System.InsertSampleTrack(name, filepath, i)
                        if track then
                            System.samples[i].track = track
                        else
                            System.samples[i] = {}
                        end
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
