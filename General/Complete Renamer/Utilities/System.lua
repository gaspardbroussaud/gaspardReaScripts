-- @noindex
-- @description Complete renamer functions
-- @author gaspard
-- @about All functions used in gaspard_Complete renamer.lua script

local System = {}

local project_name = reaper.GetProjectName(0)
local project_path = reaper.GetProjectPath()
local project_id, _ = reaper.EnumProjects(-1)

-- Init Settings from file
function System.InitSettings()
    Settings = {}
    Settings = gson.LoadJSON(settings_path, Settings)
end

-- Check current focused project
local function ProjectChange()
    if project_name ~= reaper.GetProjectName(0) or project_path ~= reaper.GetProjectPath() then
        project_name = reaper.GetProjectName(0)
        project_path = reaper.GetProjectPath()
        project_id, _ = reaper.EnumProjects(-1)
        return true
    else
        return false
    end
end

-- Get all items from project in table
local function GetItemsFromProject()
    local items = {}
    if replace_items then
        local item_count = reaper.CountMediaItems(0)
        if item_count > 0 then
            for i = 0, item_count - 1 do
                local item_id = reaper.GetMediaItem(0, i)
                local _, item_name = reaper.GetSetMediaItemTakeInfo_String(reaper.GetTake(item_id, 0), "P_NAME", "", false)
                local selected = reaper.IsMediaItemSelected(item_id)
                table.insert(items, { id = item_id, name = item_name, selected = selected })
            end
        else
            return nil
        end
    else
        return nil
    end
    return items
end

-- Get all tracks from project in table
local function GetTracksFromProject()
    local tracks = {}
    if replace_tracks then
        local track_count = reaper.CountTracks(0)
        if track_count > 0 then
            for i = 0, track_count - 1 do
                local track_id = reaper.GetTrack(0, i)
                local _, track_name = reaper.GetTrackName(track_id)
                if tostring(track_name):match("^Track %d+$") then track_name = "" end
                local selected = reaper.IsTrackSelected(track_id)
                table.insert(tracks, { id = track_id, name = track_name, selected = selected })
            end
        else
            return nil
        end
    else
        return nil
    end
    return tracks
end

-- Get all markers from project in table
local function GetMarkersRegionsFromProject()
    local markers = {}
    local regions = {}
    if replace_markers or replace_regions then
        local _, marker_count, region_count = reaper.CountProjectMarkers(0)
        for i = 0, marker_count + region_count - 1 do
            local _, isrgn, pos, rgnend, name, idx = reaper.EnumProjectMarkers2(0, i)
            if isrgn then
                if replace_regions then table.insert(regions, { pos = pos, rgnend = rgnend, id = idx, name = name, selected = false }) end
            else
                if replace_markers then table.insert(markers, {  pos = pos, rgnend = rgnend, id = idx, name = name, selected = false }) end
            end
        end
    end
    if #markers <= 0 then markers = nil end
    if #regions <= 0 then regions = nil end
    return markers, regions
end

-- Reposition an item to another index in a given table
function System.RepositionInTable(table_update, from_index, to_index)
    if from_index == to_index then return table_update end

    local item = table_update[from_index]
    table.remove(table_update, from_index)
    table.insert(table_update, to_index, item)

    return table_update
end

-- Select from one item index to another regardless of direction
function System.SelectFromOneToTheOther(tab, one, other)
    local first = tab[one]
    local last = tab[other]
    if one > other then
        first = other
        last = one
    end
    local can_select = false

    for i, element in ipairs(tab) do
        if element == first then
            can_select = true
        end

        if can_select then
            element.selected = true
        end

        if element == last then
            can_select = false
        end
    end
end

-- Clear element.selected from a given table
function System.ClearTableSelection(tab)
    for _, element in ipairs(tab) do
        element.selected = false
    end
end

-- Get all userdatas for all types
function System.GetUserdatas()
    local items = {display = "Items", show = replace_items, data = GetItemsFromProject()}
    local tracks = {display = "Tracks", show = replace_tracks, data = GetTracksFromProject()}
    local table_markers, table_regions = GetMarkersRegionsFromProject()
    local markers = {display = "Markers", show = replace_markers, data = table_markers}
    local regions = {display = "Regions", show = replace_regions, data = table_regions}
    local order = {"items", "tracks", "markers", "regions"}
    global_datas = {order = order, items = items, tracks = tracks, markers = markers, regions = regions}
end

function System.ProjectUpdates()
    if ProjectChange() then System.GetUserdatas() end
end

-- Clear data selection in GUI and project
function System.ClearUserdataSelection()
    if global_datas.order then
        for _, key in ipairs(global_datas.order) do
            if global_datas[key]["data"] then
                for _, userdata in pairs(global_datas[key]["data"]) do
                    userdata.selected = false
                    if key == "items" then reaper.SetMediaItemSelected(userdata.id, userdata.selected)
                    elseif key == "tracks" then reaper.SetTrackSelected(userdata.id, userdata.selected) end
                end
            end
        end
        reaper.UpdateArrange()
    end
end

return System