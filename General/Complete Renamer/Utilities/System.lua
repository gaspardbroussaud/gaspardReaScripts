-- @noindex
-- @description Complete renamer functions
-- @author gaspard
-- @about All functions used in gaspard_Complete renamer.lua script

local System = {}

local project_name = reaper.GetProjectName(0)
local project_path = reaper.GetProjectPath()
local project_id, _ = reaper.EnumProjects(-1)
System.Shift = false
System.Ctrl = false

System.global_datas = {}
System.ruleset = {}

-- Init Settings from file
function System.InitSettings()
    Settings = {
        order = {"tree_start_open"},
        tree_start_open = {
            value = false,
            name = "Trees open on start",
            description = "Trees for userdata types start opened on script launch."
        }
    }
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
    return items
end

-- Get all tracks from project in table
local function GetTracksFromProject()
    local tracks = {}
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
    return tracks
end

-- Get all markers from project in table
local function GetMarkersRegionsFromProject()
    local markers = {}
    local regions = {}
    local _, marker_count, region_count = reaper.CountProjectMarkers(0)
    for i = 0, marker_count + region_count - 1 do
        local _, isrgn, pos, rgnend, name, idx = reaper.EnumProjectMarkers2(0, i)
        if isrgn then
            if replace_regions then table.insert(regions, { pos = pos, rgnend = rgnend, id = idx, name = name, selected = false }) end
        else
            if replace_markers then table.insert(markers, {  pos = pos, rgnend = rgnend, id = idx, name = name, selected = false }) end
        end
    end
    if #markers <= 0 then markers = nil end
    if #regions <= 0 then regions = nil end
    return markers, regions
end

-- Get all userdatas for all types
function System.GetUserdatas()
    local items = {display = "Items", data = GetItemsFromProject()}
    local tracks = {display = "Tracks", data = GetTracksFromProject()}
    local table_markers, table_regions = GetMarkersRegionsFromProject()
    local markers = {display = "Markers", data = table_markers}
    local regions = {display = "Regions", data = table_regions}
    local order = {"items", "tracks", "markers", "regions"}
    System.global_datas = {order = order, items = items, tracks = tracks, markers = markers, regions = regions}
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

-- Update userdatas when changing Reaper project
function System.ProjectUpdates()
    if ProjectChange() then System.GetUserdatas() end
end

function System.KeyboardHold()
    System.Shift = reaper.ImGui_IsKeyDown(ctx, reaper.ImGui_Key_LeftShift())
    System.Ctrl = reaper.ImGui_IsKeyDown(ctx, reaper.ImGui_Key_LeftCtrl())
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

-- Add rule using default config
function System.LoadEmptyRule(default_rule, rule_path)
    empty_rule = gson.LoadJSON(rule_path, default_rule)
    if empty_rule.version and empty_rule.version ~= default_rule.version then
        os.remove(rule_path)
        gson.SaveJSON(rule_path, default_rule)
        empty_rule = default_rule
    end
    return empty_rule
end

local function CapitalizeWords(str)
    return str:gsub("(%a)([%w_]*)", function(first, rest)
        return first:upper() .. rest:lower()
    end)
end

-- Get replaced name using ruleset
function System.GetReplacedName(name)
    local should_apply = false
    for _, rule in ipairs(System.ruleset) do
        if rule.type_selected == "insert" then
            if rule.config.insert.from_start then
                name = rule.config.insert.text..name
                should_apply = true
            end
            if rule.config.insert.from_end then
                name = name..rule.config.insert.text
                should_apply = true
            end
        end
        if rule.type_selected == "replace" then
            if string.find(name, rule.config.replace.search_text) then
                name = string.gsub(name, rule.config.replace.search_text, rule.config.replace.replace_text)
                should_apply = true
            end
        end
        if rule.type_selected == "case" then
            if rule.config.case.selected == 0 then
                name = CapitalizeWords(name)
            elseif rule.config.case.selected == 1 then
                name = string.lower(name)
            elseif rule.config.case.selected == 2 then
                name = string.upper(name)
            elseif rule.config.case.selected == 3 then
                name = name:gsub("^(%l)", string.upper)
            end
            should_apply = true
        end
    end
    if should_apply then
        return name
    else
        return ""
    end
end

-- Copy table
function System.TableCopy(origin)
    local origin_type = type(origin)
    local copy
    if origin_type == 'table' then
        copy = {}
        for key, value in next, origin, nil do
            copy[System.TableCopy(key)] = System.TableCopy(value)
        end
        setmetatable(copy, System.TableCopy(getmetatable(origin)))
    else
        copy = origin
    end
    return copy
end

-- Debug
function System.Debug(message)
    reaper.ShowConsoleMsg(tostring(message))
end

return System