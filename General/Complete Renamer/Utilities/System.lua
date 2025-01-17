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
System.one_renamed = false

-- Init Settings from file
function System.InitSettings()
    local settings_version = "0.0.1b"
    default_settings = {
        version = settings_version,
        order = {"link_selection", "tree_start_open"},
        link_selection = {
            value = false,
            name = "Link selection",
            description = "Link data selection between project and GUI."
        },
        tree_start_open = {
            value = false,
            name = "Trees open on start",
            description = "Trees for userdata types start opened on script launch."
        }
    }
    Settings = gson.LoadJSON(settings_path, default_settings)
    if settings_version ~= Settings.version then
        reaper.MB("Settings are erased due to update in file.\nPlease excuse this behaviour.\nThis won't happen once released.", "WARNING", 0)
        Settings = gson.SaveJSON(settings_path, default_settings)
        Settings = gson.LoadJSON(settings_path, Settings)
    end
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
    local changed_items = {}
    local item_count = reaper.CountMediaItems(0)
    if item_count > 0 then
        for i = 1, item_count do
            local item_id = reaper.GetMediaItem(0, i - 1)
            local take = reaper.GetTake(item_id, 0)
            local item_name = ""
            if take then
                _, item_name = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
            else
                _, item_name = reaper.GetSetMediaItemInfo_String(item_id, "P_NOTES", "", false)
            end
            local selected = Settings.link_selection.value and reaper.IsMediaItemSelected(item_id) or false

            if not Settings.link_selection.value and System.global_datas.items then
                if System.global_datas.items.data[i] and item_id == System.global_datas.items.data[i].id then
                    selected = System.global_datas.items.data[i].selected
                else
                    table.insert(changed_items, {index = i, id = item_id})
                end
            end

            table.insert(items, {id = item_id, name = item_name, selected = selected})
        end
    else
        return nil
    end

    if not Settings.link_selection.value and items and changed_items and System.global_datas.items then
        for _, changed_item in ipairs(changed_items) do
            for _, data in ipairs(System.global_datas.items.data) do
                if data.id == changed_item.id then
                    items[changed_item.index].selected = data.selected
                    break
                end
            end
        end
    end

    return items
end

-- Get all tracks from project in table
local function GetTracksFromProject()
    local tracks = {}
    local changed_tracks = {}
    local track_count = reaper.CountTracks(0)
    if track_count > 0 then
        for i = 1, track_count do
            local track_id = reaper.GetTrack(0, i - 1)
            local _, track_name = reaper.GetTrackName(track_id)
            if tostring(track_name):match("^Track %d+$") then track_name = "" end
            local selected = Settings.link_selection.value and reaper.IsTrackSelected(track_id) or false

            if not Settings.link_selection.value and System.global_datas.tracks then
                if System.global_datas.tracks.data[i] and track_id == System.global_datas.tracks.data[i].id then
                    selected = System.global_datas.tracks.data[i].selected
                else
                    table.insert(changed_tracks, {index = i, id = track_id})
                end
            end

            table.insert(tracks, {id = track_id, name = track_name, selected = selected})
        end
    else
        return nil
    end

    if not Settings.link_selection.value and tracks and changed_tracks and System.global_datas.tracks then
        for _, changed_track in ipairs(changed_tracks) do
            for _, data in ipairs(System.global_datas.tracks.data) do
                if data.id == changed_track.id then
                    tracks[changed_track.index].selected = data.selected
                    break
                end
            end
        end
    end

    return tracks
end

-- Get all markers from project in table
local function GetMarkersRegionsFromProject()
    local markers = {}
    local changed_markers = {}
    local regions = {}
    local changed_regions = {}
    local _, marker_count, region_count = reaper.CountProjectMarkers(0)
    local marker_index = 0
    local region_index = 0
    for i = 1, marker_count + region_count do
        local _, isrgn, pos, rgnend, name, markrgnid = reaper.EnumProjectMarkers2(0, i - 1)
        local selected = false
        if isrgn then
            region_index = region_index + 1
            if System.global_datas.regions then
                if System.global_datas.regions.data[region_index] and markrgnid == System.global_datas.regions.data[region_index].id then
                    selected = System.global_datas.regions.data[region_index].selected
                else
                    table.insert(changed_regions, {index = region_index, id = markrgnid})
                end
            end
            table.insert(regions, {pos = pos, rgnend = rgnend, id = markrgnid, name = name, selected = selected})
        else
            marker_index = marker_index + 1
            if System.global_datas.markers then
                if System.global_datas.markers.data[marker_index] and markrgnid == System.global_datas.markers.data[marker_index].id then
                    selected = System.global_datas.markers.data[marker_index].selected
                else
                    table.insert(changed_markers, {index = marker_index, id = markrgnid})
                end
            end
            table.insert(markers, {pos = pos, rgnend = rgnend, id = markrgnid, name = name, selected = selected})
        end
    end
    if #markers <= 0 then markers = nil end
    if #regions <= 0 then regions = nil end

    if markers and changed_markers and System.global_datas.markers then
        for _, changed_marker in ipairs(changed_markers) do
            for _, data in ipairs(System.global_datas.markers.data) do
                if data.id == changed_marker.id then
                    markers[changed_marker.index].selected = data.selected
                    break
                end
            end
        end
    end
    if regions and changed_regions and System.global_datas.regions then
        for i, changed_region in ipairs(changed_regions) do
            for _, data in ipairs(System.global_datas.regions.data) do
                if data.id == changed_region.id then
                    regions[changed_region.index].selected = data.selected
                    break
                end
            end
        end
    end

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
    return str:gsub("(%w)(%w*)"--[["(%a)([%w_]*)"]], function(first, rest)
        return first:upper() .. rest:lower()
    end)
end

local function EscapePattern(str)
    return str:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
end

-- Get replaced name using ruleset
function System.GetReplacedName(name)
    local should_apply = false
    for _, rule in ipairs(System.ruleset) do
        if rule.state then
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
                local search = EscapePattern(rule.config.replace.search_text)
                if string.find(name, search) then
                    name = string.gsub(name, search, rule.config.replace.replace_text)
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
                    name = string.lower(name)
                    name = name:gsub("^(%l)", string.upper)
                end
                should_apply = true
            end
        end
    end
    if should_apply then
        return name
    else
        return nil
    end
end

-- Apply name replacement
function System.ApplyReplacedNames()
    reaper.PreventUIRefresh(-1)
    reaper.Undo_BeginBlock()

    if System.global_datas.order then
        for _, key in ipairs(System.global_datas.order) do
            if System.global_datas[key]["data"] then
                for _, userdata in pairs(System.global_datas[key]["data"]) do
                    local can_apply = true
                    if can_apply then
                        local replaced_name = System.GetReplacedName(userdata.name)
                        if replaced_name and replaced_name ~= userdata.name then
                            userdata.name = replaced_name
                            if key == "items" then
                                local take = reaper.GetTake(userdata.id, 0)
                                if take then
                                    reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", userdata.name, true)
                                else
                                    reaper.GetSetMediaItemInfo_String(userdata.id, "P_NOTES", userdata.name, true)
                                end
                            elseif key == "tracks" then
                                reaper.GetSetMediaTrackInfo_String(userdata.id, "P_NAME", userdata.name, true)
                            elseif key == "markers" then
                                reaper.SetProjectMarker(userdata.id, false, userdata.pos, userdata.rgnend, userdata.name)
                            elseif key == "regions" then
                                reaper.SetProjectMarker(userdata.id, true, userdata.pos, userdata.rgnend, userdata.name)
                            end
                        end
                    end
                end
            end
        end
    end

    reaper.Undo_EndBlock("Complete renamer: name replaced.", -1)
    reaper.PreventUIRefresh(1)
    reaper.UpdateArrange()
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

return System
