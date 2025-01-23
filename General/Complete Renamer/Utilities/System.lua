--@noindex
--@description Complete renamer functions
--@author gaspard
--@about All functions used in gaspard_Complete renamer.lua script

local System = {}

local project_name = reaper.GetProjectName(0)
local project_id, project_path = reaper.EnumProjects(-1)
local script_ext = 'gaspard_CompleteRenamer'

System.focus_main_window = false
System.Shift = false
System.Ctrl = false

System.global_datas = {}
System.ruleset = {}
System.presets = {}
System.one_renamed = false
System.last_selected_area = "userdata"

-- Init Settings from file
function System.InitSettings()
    local settings_version = "1.0"
    default_settings = {
        version = settings_version,
        order = {"link_selection", "tree_start_open"},
        alphabetical_order = {
            value = false,
            name = "Alphabetical order",
            description = "Sort userdata alphabetically.\nEach data type separated."
        },
        link_selection = {
            value = false,
            name = "Link selection",
            description = "Link data selection between project and GUI."
        },
        tree_start_open = {
            value = false,
            name = "Trees open on start",
            description = "Trees for userdata types start opened on script launch."
        },
        clean_rpp = {
            value = false,
            name = "Clean project file",
            description = "Clean project file (.rpp) on exit tool.\nSelection data between session is lost."
        }
    }
    Settings = gson.LoadJSON(settings_path, default_settings)
    if settings_version ~= Settings.version then
        reaper.MB("Settings are erased due to update in file.\nPlease excuse this behaviour.\nThis won't happen once released.", "WARNING", 0)
        Settings = gson.SaveJSON(settings_path, default_settings)
        Settings = gson.LoadJSON(settings_path, Settings)
    end
end

function System.SavePreset(name, preset)
    gson.SaveJSON(presets_path.."/"..name:gsub("%.json$", "")..".json", preset)
end

function System.ImportPresetReplaceRuleset(preset)
    System.ruleset = {}
    System.ruleset = gson.LoadJSON(preset.path)
end

function System.AddPresetToRuleset(preset)
    local preset_set = gson.LoadJSON(preset.path)
    for _, rule in ipairs(preset_set) do
        table.insert(System.ruleset, rule)
    end
end

function System.ScanPresetFiles()
    local files = {}
    local index = 0
    local file = reaper.EnumerateFiles(presets_path, index)

    while file do
        if file:match("%.json$") then
            table.insert(files, {path = presets_path.."/"..file, name = file:gsub("%.json$", ""), selected = false})
        end
        index = index + 1
        file = reaper.EnumerateFiles(presets_path, index)
    end

    System.presets = files
end

-- Get all items from project in table
local function GetItemsFromProject()
    local items = {}
    --local changed_items = {}
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
            local selected = false
            if Settings.link_selection.value then
                selected = reaper.IsMediaItemSelected(item_id)
            else
                _, selected = reaper.GetSetMediaItemInfo_String(item_id, "P_EXT:"..script_ext..":Selected", "", false)
                if selected == nil or selected == '' then
                    reaper.GetSetMediaItemInfo_String(item_id, "P_EXT:"..script_ext..":Selected", "false", true)
                end
                selected = selected == "true"
            end
            local state = true
            _, state = reaper.GetSetMediaItemInfo_String(item_id, "P_EXT:"..script_ext..":State", "", false)
            if state == nil or state == '' then
                reaper.GetSetMediaItemInfo_String(item_id, "P_EXT:"..script_ext..":State", "true", true)
            end
            state = state == "true"

            table.insert(items, {id = item_id, name = item_name, selected = selected, state = state})
        end

        if Settings.alphabetical_order.value then
            table.sort(items, function(a, b)
                return a.name < b.name
            end)
        end
    else
        return nil
    end

    return items
end

-- Get all tracks from project in table
local function GetTracksFromProject()
    local tracks = {}
    --local changed_tracks = {}
    local track_count = reaper.CountTracks(0)
    if track_count > 0 then
        for i = 1, track_count do
            local track_id = reaper.GetTrack(0, i - 1)
            local _, track_name = reaper.GetTrackName(track_id)
            if tostring(track_name):match("^Track %d+$") then track_name = "" end
            local selected = false
            if Settings.link_selection.value then
                selected = reaper.IsTrackSelected(track_id)
            else
                _, selected = reaper.GetSetMediaTrackInfo_String(track_id, "P_EXT:"..script_ext..":Selected", "", false)
                if selected == nil or selected == '' then
                    reaper.GetSetMediaTrackInfo_String(track_id, "P_EXT:"..script_ext..":Selected", "false", true)
                end
                selected = selected == "true"
            end
            local state = true
            _, state = reaper.GetSetMediaTrackInfo_String(track_id, "P_EXT:"..script_ext..":State", "", false)
            if state == nil or state == '' then
                reaper.GetSetMediaTrackInfo_String(track_id, "P_EXT:"..script_ext..":State", "true", true)
            end
            state = state == "true"

            table.insert(tracks, {id = track_id, name = track_name, selected = selected, state = state})
        end

        if Settings.alphabetical_order.value then
            table.sort(tracks, function(a, b)
                return a.name < b.name
            end)
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
    local _, marker_count, region_count = reaper.CountProjectMarkers(project_id)
    for i = 0, marker_count + region_count - 1 do
        local _, markrgn_id = reaper.GetSetProjectInfo_String(project_id, "MARKER_GUID:"..i, "", false)

        local _, isrgn, _, _, name, _ = reaper.EnumProjectMarkers2(0, i)

        local selected = false
        local extstate, val = reaper.GetProjExtState(project_id, tostring(markrgn_id), script_ext.."_Selected")
        if extstate == 1 then
            selected = val == "true"
        else
            reaper.SetProjExtState(project_id, tostring(markrgn_id), script_ext.."_Selected", "false")
        end

        local state = true
        extstate, val = reaper.GetProjExtState(project_id, tostring(markrgn_id), script_ext.."_State")
        if extstate == 1 then
            state = val == "true"
        else
            reaper.SetProjExtState(project_id, tostring(markrgn_id), script_ext.."_State", "true")
        end

        if isrgn then
            table.insert(regions, {id = markrgn_id, name = name, selected = selected, state = state})
        else
            table.insert(markers, {id = markrgn_id, name = name, selected = selected, state = state})
        end
    end

    if #markers <= 0 then markers = nil end
    if #regions <= 0 then regions = nil end

    if Settings.alphabetical_order.value then
        if markers and #markers > 0 then
            table.sort(markers, function(a, b)
                return a.name < b.name
            end)
        end

        if regions and #regions > 0 then
            table.sort(regions, function(a, b)
                return a.name < b.name
            end)
        end
    end

    return markers, regions
end

local function GetKeyState(key)
    local state = true
    local extstate, val = reaper.GetProjExtState(project_id, script_ext, key.."_State")
    if extstate == 1 then
        state = val == "true"
    else
        reaper.SetProjExtState(project_id, script_ext, key.."_State", "true")
    end
    return state
end

-- Get all userdatas for all types
function System.GetUserdatas()
    local items = {display = "Items", show = true, state = GetKeyState("items"), data = GetItemsFromProject()}
    local tracks = {display = "Tracks", show = true, state = GetKeyState("tracks"),  data = GetTracksFromProject()}
    local table_markers, table_regions = GetMarkersRegionsFromProject()
    local markers = {display = "Markers", show = true, state = GetKeyState("markers"), data = table_markers}
    local regions = {display = "Regions", show = true, state = GetKeyState("regions"), data = table_regions}
    local order = {"items", "tracks", "markers", "regions"}
    System.global_datas = {order = order, items = items, tracks = tracks, markers = markers, regions = regions}
end

-- Clean extstate from project .rpp file
function System.CleanExtState(current)
    local index = 0
    while true do
        local id_project, optional_projfn = reaper.EnumProjects(index)
        if current then id_project = project_id end
        if not id_project then return end
        local item_count = reaper.CountMediaItems(id_project)
        for i = 0, item_count - 1 do
            reaper.GetSetMediaItemInfo_String(reaper.GetMediaItem(id_project, i), "P_EXT:"..script_ext..":Selected", "", true)
            reaper.GetSetMediaItemInfo_String(reaper.GetMediaItem(id_project, i), "P_EXT:"..script_ext..":State", "", true)
        end
        local track_count = reaper.CountTracks(id_project)
        for i = 0, track_count - 1 do
            reaper.GetSetMediaTrackInfo_String(reaper.GetTrack(id_project, i), "P_EXT:"..script_ext..":Selected", "", true)
            reaper.GetSetMediaTrackInfo_String(reaper.GetTrack(id_project, i), "P_EXT:"..script_ext..":State", "", true)
        end
        local _, marker_count, region_count = reaper.CountProjectMarkers(id_project)
        for i = 0, marker_count + region_count - 1 do
            local _, markrgn_id = reaper.GetSetProjectInfo_String(id_project, "MARKER_GUID:"..i, "", false)
            reaper.SetProjExtState(id_project, tostring(markrgn_id), script_ext.."_Selected", "")
            reaper.SetProjExtState(id_project, tostring(markrgn_id), script_ext.."_State", "")
        end
        if current then return end
        index = index + 1
    end
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
---@param tab table Table to go through
---@param one number Index of first object
---@param other number Index of last object 
function System.SelectFromOneToTheOther(tab, one, other)
    local first = tab[one]
    local last = tab[other]
    if one > other then
        first = tab[other]
        last = tab[one]
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

-- Check current focused project
local function ProjectChange()
    local temp_project_id, temp_project_path = reaper.EnumProjects(-1)
    if project_path ~= temp_project_path or project_id ~= temp_project_id or project_name ~= reaper.GetProjectName(0) then
        return true
    else
        return false
    end
end

-- Update userdatas when changing Reaper project
function System.ProjectUpdates()
    if ProjectChange() then
        project_name = reaper.GetProjectName(0)
        project_id, project_path = reaper.EnumProjects(-1)
    end
end

function System.SetUserdataSelectedExtState(userdata, key)
    if key == "items" then
        reaper.GetSetMediaItemInfo_String(userdata.id, "P_EXT:"..script_ext..":Selected", tostring(userdata.selected), true)
    elseif key == "tracks" then
        reaper.GetSetMediaTrackInfo_String(userdata.id, "P_EXT:"..script_ext..":Selected", tostring(userdata.selected), true)
    elseif key == "markers" then
        reaper.SetProjExtState(project_id, tostring(userdata.id), script_ext.."_Selected", tostring(userdata.selected))
    elseif key == "regions" then
        reaper.SetProjExtState(project_id, tostring(userdata.id), script_ext.."_Selected", tostring(userdata.selected))
    end
end

function System.SelectUserdataInProject(userdata, key)
    if key == "items" then
        reaper.SetMediaItemSelected(userdata.id, userdata.selected)
    elseif key == "tracks" then
        reaper.SetTrackSelected(userdata.id, userdata.selected)
    end
end

function System.KeyboardHold()
    System.Shift = reaper.ImGui_IsKeyDown(ctx, reaper.ImGui_Key_LeftShift())
    System.Ctrl = reaper.ImGui_IsKeyDown(ctx, reaper.ImGui_Key_LeftCtrl())
    if System.Ctrl and reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_A()) then
        if #System.ruleset < 1 then System.last_selected_area = "userdata" end
        if #System.global_datas.items.data < 1 and #System.global_datas.tracks.data < 1 and #System.global_datas.markers.data < 1 and #System.global_datas.regions.data < 1 then
            System.last_selected_area = "rule"
        end
        if System.last_selected_area == "rule" then
            for _, rule in ipairs(System.ruleset) do
                rule.selected = true
            end
        end
        if System.last_selected_area == "userdata" then
            for _, key in ipairs(System.global_datas.order) do
                if System.global_datas[key]["data"] then
                    for _, userdata in pairs(System.global_datas[key]["data"]) do
                        if System.global_datas[key]["show"] then
                            userdata.selected = true
                            System.SetUserdataSelectedExtState(userdata, key)
                            if Settings.link_selection.value then System.SelectUserdataInProject(userdata, key) end
                        end
                    end
                end
            end
        end
    end
    if reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_Escape()) then
        if System.last_selected_area == "rule" then
            System.ClearTableSelection(System.ruleset)
        elseif System.last_selected_area == "userdata" then
            System.ClearUserdataSelection()
        end
    end
end

-- Clear data selection in GUI and project
function System.ClearUserdataSelection()
    if System.global_datas.order then
        for _, key in ipairs(System.global_datas.order) do
            if System.global_datas[key]["data"] then
                for _, userdata in pairs(System.global_datas[key]["data"]) do
                    userdata.selected = false
                    System.SetUserdataSelectedExtState(userdata, key)
                    if Settings.link_selection.value then
                        if key == "items" then
                            reaper.SetMediaItemSelected(userdata.id, userdata.selected)
                        elseif key == "tracks" then
                            reaper.SetTrackSelected(userdata.id, userdata.selected)
                        end
                    end
                end
            end
        end
        reaper.UpdateArrange()
    end
end

-- Clear element.selected from a given table
function System.ClearTableSelection(tab)
    for _, element in ipairs(tab) do
        element.selected = false
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
    return str:gsub("(%w)(%w*)", function(first, rest)
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
                    local can_apply = System.global_datas[key].state and userdata.state
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
                                local _, index = reaper.GetSetProjectInfo_String(project_id, "MARKER_INDEX_FROM_GUID:"..tostring(userdata.id), "", false)
                                reaper.SetProjectMarker(index, false, userdata.pos, userdata.rgnend, userdata.name)
                            elseif key == "regions" then
                                local _, index = reaper.GetSetProjectInfo_String(project_id, "MARKER_INDEX_FROM_GUID:"..tostring(userdata.id), "", false)
                                reaper.SetProjectMarker(index, true, userdata.pos, userdata.rgnend, userdata.name)
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
