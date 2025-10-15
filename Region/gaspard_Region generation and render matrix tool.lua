-- @description Region generation and render matrix Tool
-- @author gaspard
-- @version 1.0.12
-- @changelog
--  - Fix json utilities loading
-- @about
--  - Retrives clusters of selected items depending on selected tracks.
--  - How to use:
--    1. Select all items to render (script will auto detect clusters: overlaping on same track or tracks in same track folder, depending on track selection).
--    2. Select tracks to use as render matrix (will be used for region's names too).

-- INIT VARIABLES
local render_tracks = {}
local render_tracks_name = {}
local render_folders = {}

-- Get Settings -------------------
local json_file_path = reaper.GetResourcePath().."/Scripts/Gaspard ReaScripts/JSON"
package.path = package.path .. ";" .. json_file_path .. "/?.lua"
local gson = require("json_utilities_lib")
local json_version = "1.0.6"
if not gson.version or gson.version_less(gson.version, json_version) then
    reaper.MB('Please update gaspard "json_utilities_lib" to version ' .. json_version .. ' or higher.', "ERROR", 0)
    return
end

local _, name, sec, cmd, _, _, _ = reaper.get_action_context()
local action_name = string.match(name, "gaspard_(.-)%.lua")

local settings_path = debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]]..'/gaspard_'..action_name..'_settings.json'
local settings_version = "1.0.1"
local default_settings = {
    version = settings_version,
    order = {"color_regions_with_track_color", "region_naming_parent_cascade", "exclude_character"},
    color_regions_with_track_color = {
        value = true,
        name = "Track color for region",
        description = " Color generated regions with corresponding region render track color."
    },
    region_naming_parent_cascade = {
        value = false,
        name = "Region name from folder cascade",
        description = "Use cascading track folders to name regions."
    },
    exclude_character = {
        value = "--",
        name = "Exclude characters",
        description = "Name or part of name with this string on its left will be excluded from final naming."
    }
}

Settings = gson.LoadJSON(settings_path, default_settings)
if not Settings.version or settings_version ~= Settings.version then
    local keys = {}
    Settings = gson.CompleteUpdate(settings_path, Settings, default_settings, keys)
end
-----------------------------------

-- UTILITY FUNCTIONS
-- MESSAGE BOX ON ERROR
---@param message string
local function MessageBox(message)
    reaper.MB(tostring(message), "Message box", 0)
end

-- SORT VALUES FUNCTION
local function SortOnValue(t,...)
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
local function GetParentTrackMatch(track, target)
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

---comment
---@param track any
---@return string name
-- GET TOP PARENT TRACK
local function GetConcatenatedParentNames(track)
    local _, name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
    if Settings.exclude_character.value and Settings.exclude_character.value ~= "" then
        name = name:match("^(.-)" .. Settings.exclude_character.value:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])","%%%1")) or name
    end
    while true do
        local parent = reaper.GetParentTrack(track)
        if parent then
            track = parent
            local _, parent_name = reaper.GetSetMediaTrackInfo_String(parent, "P_NAME", "", false)
            if Settings.exclude_character.value and Settings.exclude_character.value ~= "" then
                parent_name = parent_name:match("^(.-)" .. Settings.exclude_character.value:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])","%%%1")) or parent_name
            end

            if parent_name ~= "" then
                name = parent_name.."_"..name
            end
        else
            return name
        end
    end
end

-- GET REGION NAME WITH TWO METHODS
local function GetRegionNaming(track)
    local track_name = ""
    if Settings.region_naming_parent_cascade.value then
        track_name = GetConcatenatedParentNames(track)
    else
        _, track_name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
        if Settings.exclude_character.value and Settings.exclude_character.value ~= "" then
            track_name = track_name:match("^(.-)" .. Settings.exclude_character.value:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])","%%%1")) or track_name
        end
        if track_name == "" then
            track_name = "Track "..tostring(reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")):sub(1, -3)
        end
    end
    return track_name
end

-- SYSTEM FUNCTIONS
-- GET SELECTED TRACKS TAB
local function GetSelectedTracksTab()
    local track_count = reaper.CountSelectedTracks(0)
    render_tracks = {}
    render_tracks_name = {}
    render_folders = {}

    if track_count ~= 0 then
        for i = 0, track_count - 1 do
            local track = reaper.GetSelectedTrack(0, i)
            table.insert(render_tracks, track)
            table.insert(render_folders, {})
            table.insert(render_tracks_name, GetRegionNaming(track))
        end
    else
        MessageBox("Please select at least one track that contains selected items.")
    end
end

-- FIND CLUSTER BY FOLDERS
local function FindClusters(folder, region_name, render_track)
    local first_start = folder[1].start
    local prev_end = first_start + reaper.GetMediaItemInfo_Value(folder[1].item, "D_LENGTH")
    local last_end = prev_end
    local index = 0

    for i = 1, #folder do
        local cur_start = reaper.GetMediaItemInfo_Value(folder[i].item, "D_POSITION")
        local cur_end = cur_start + reaper.GetMediaItemInfo_Value(folder[i].item, "D_LENGTH")
        local suffix = "_"
        if index < 9 then suffix = "_0" end

        if prev_end + 0.000001 < cur_start then
            index = index + 1

            local track_color = 0
            if Settings.color_regions_with_track_color.value then track_color = reaper.GetMediaTrackInfo_Value(render_track, "I_CUSTOMCOLOR") end
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
                if index > 9 then suffix = "_" end
                display = region_name..suffix..tostring(index)
            end

            local track_color = 0
            if Settings.color_regions_with_track_color.value then track_color = reaper.GetMediaTrackInfo_Value(render_track, "I_CUSTOMCOLOR") end
            local region_index = reaper.AddProjectMarker2(0, true, first_start, last_end, display, -1, track_color)
            reaper.SetRegionRenderMatrix(0, region_index, render_track, 1)
        end

        if prev_end < cur_end then
            prev_end = cur_end
        end
    end
end

-- SORT ITEMS BY FOLDERS IN TIMELINE ORDER
local function SortItemsInTimelineOrder()
    for i = 1, #render_folders do
        SortOnValue(render_folders[i], "start")
    end

    for i = 1, #render_folders do
        if #render_folders[i] ~= 0 then
            FindClusters(render_folders[i], render_tracks_name[i], render_tracks[i])
        end
    end
end

-- GET ALL ITEMS FROM PROJECT AND ASIGN TO PARENT TABLE
local function GetItemsFromProject()
    local item_count = reaper.CountSelectedMediaItems(0)
    if item_count ~= 0 then
        -- Get all selected tracks
        GetSelectedTracksTab()

        for i = 0, item_count - 1 do
            local cur_item = reaper.GetSelectedMediaItem(0, i)
            local cur_start = reaper.GetMediaItemInfo_Value(cur_item, "D_POSITION")
            local cur_track = reaper.GetMediaItemTrack(cur_item)

            for j = 1, #render_tracks do
                if cur_track == render_tracks[j] or GetParentTrackMatch(cur_track, render_tracks[j]) then
                    table.insert(render_folders[j], { item = cur_item, start = cur_start })
                end
            end
        end

        -- Sort items in parent tables
        SortItemsInTimelineOrder()
    else
        MessageBox("Please select at least one item along with its corresponding track and/or parent track.")
    end
end

-- MAIN SCRIPT EXECUTION
reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(-1)

GetItemsFromProject()

reaper.PreventUIRefresh(1)
reaper.Undo_EndBlock("Create region for clusters of selected items by selected tracks", -1)
reaper.UpdateArrange()
