-- @description Region generation and render matrix Tool
-- @author gaspard
-- @version 1.0.3
-- @changelog
--  • Added region colors based on their corresponding render track colors.
-- @about
--  Retrieves all selected items, identifies clusters where the selected tracks serve as parents, and uses these clusters as the region's name and render matrix.
--  To use: select items to detect clusters and the tracks through which to render.

-- USER SETTINGS ----------
local color_regions = true
---------------------------

-- UTILITY FUNCTIONS
-- MESSAGE BOX ON ERROR
---@param message string
function Utility_MessageBox(message)
    reaper.MB(tostring(message), "Message box", 0)
end

-- SORT VALUES FUNCTION
function Utility_SortOnValue(t,...)
    local a = {...}
    table.sort(t, function (u,v)
        for i in pairs(a) do
            if u[a[i]] > v[a[i]] then return false end
            if u[a[i]] < v[a[i]] then return true end
        end
        return false
    end)
end

-- GET PARENT TRACK MATCH FOR TRACK VISIBILITY
---@param track any
---@param target any
---@return boolean is_in_target
function Utility_GetParentTrackMatch(track, target)
    while true do
        local parent = reaper.GetParentTrack(track)
        if parent then
            if parent ~= target then
                track = parent
            else
                return true
            end
        else
            return false
        end
    end
end

-- SYSTEM FUNCTIONS
-- GET SELECTED TRACKS TAB
function System_GetSelectedTracksTab()
    track_count = reaper.CountSelectedTracks(0)
    render_tracks = {}
    render_tracks_name = {}
    render_folders = {}

    if track_count ~= 0 then
        for i = 0, track_count - 1 do
            local track = reaper.GetSelectedTrack(0, i)
            table.insert(render_tracks, track)
            table.insert(render_folders, {})

            local _, track_name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
            if track_name == "" then
                track_name = "Track "..tostring(reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER"))
            end
            table.insert(render_tracks_name, track_name)
        end
    else
        Utility_MessageBox("Please select at least one track that contains selected items.")
    end
end

-- GET ALL ITEMS FROM PROJECT AND ASIGN TO PARENT TABLE
function System_GetItemsFromProject()
    item_count = reaper.CountSelectedMediaItems(0)
    if item_count ~= 0 then
        -- Get all selected tracks
        System_GetSelectedTracksTab()

        for i = 0, item_count - 1 do
            local cur_item = reaper.GetSelectedMediaItem(0, i)
            local cur_start = reaper.GetMediaItemInfo_Value(cur_item, "D_POSITION")
            local cur_track = reaper.GetMediaItemTrack(cur_item)
            --local cur_track_id = reaper.GetMediaTrackInfo_Value(cur_track, "IP_TRACKNUMBER")

            for j = 1, #render_tracks do
                if cur_track == render_tracks[j] or Utility_GetParentTrackMatch(cur_track, render_tracks[j]) then
                    table.insert(render_folders[j], { item = cur_item, start = cur_start })
                end
            end
        end

        -- Sort items in parent tables
        System_SortItemsInTimelineOrder()
    else
        Utility_MessageBox("Please select at least one item along with its corresponding track and/or parent track.")
    end
end

-- SORT ITEMS BY FOLDERS IN TIMELINE ORDER
function System_SortItemsInTimelineOrder()
    for i = 1, #render_folders do
        Utility_SortOnValue(render_folders[i], "start")
    end

    for i = 1, #render_folders do
        if #render_folders[i] ~= 0 then
            System_FindClusters(render_folders[i], render_tracks_name[i], render_tracks[i])
        end
    end
end

-- FIND CLUSTER BY FOLDERS
function System_FindClusters(folder, region_name, render_track)
    local first_start = folder[1].start
    local prev_end = first_start + reaper.GetMediaItemInfo_Value(folder[1].item, "D_LENGTH")
    local last_end = prev_end
    local index = 0

    for i = 1, #folder do
        local cur_start = reaper.GetMediaItemInfo_Value(folder[i].item, "D_POSITION")
        local cur_end = cur_start + reaper.GetMediaItemInfo_Value(folder[i].item, "D_LENGTH")
        local suffix = "_"
        if index < 10 then suffix = "_0" end

        if prev_end + 0.000001 < cur_start then
            index = index + 1

            local track_color = 0
            if color_regions then track_color = reaper.GetMediaTrackInfo_Value(render_track, "I_CUSTOMCOLOR") end
            local region_index = reaper.AddProjectMarker2(0, true, first_start, prev_end, region_name..suffix..tostring(index), -1, track_color)
            reaper.SetRegionRenderMatrix(0, region_index, render_track, 1)
            first_start = cur_start
        end

        if i == #folder then
            if prev_end > cur_end then
                last_end = prev_end
            else
                last_end = cur_end
            end

            local display = region_name
            if index ~= 0 then
                index = index + 1
                display = region_name..suffix..tostring(index)
            end

            local track_color = 0
            if color_regions then track_color = reaper.GetMediaTrackInfo_Value(render_track, "I_CUSTOMCOLOR") end
            local region_index = reaper.AddProjectMarker2(0, true, first_start, last_end, display, -1, track_color)
            reaper.SetRegionRenderMatrix(0, region_index, render_track, 1)
        end

        if prev_end < cur_end then
            prev_end = cur_end
        end
    end
end

-- MAIN SCRIPT EXECUTION
reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(-1)

System_GetItemsFromProject()

reaper.PreventUIRefresh(1)
reaper.Undo_EndBlock("Create region for clusters of selected items by selected tracks", -1)
reaper.UpdateArrange()
